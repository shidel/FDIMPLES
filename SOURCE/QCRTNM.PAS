{
Copyright 1990-2016, Jerome Shidel.

This project and related files are subject to the terms of the Mozilla Public License,
v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at
http://mozilla.org/MPL/2.0/.
}

{$I QCRT.DEF}
unit QCRTNM; { version 9.0x }

interface

uses QCrt, QStrings;

const
  { Box Constants }
    bxSingle     = $00; { Single Side/Single Top }
    bxDouble     = $03; { Double Side/Double Top }
    bxDoubleSide = $01; { Double Side/Single Top }
    bxDoubleTop  = $02; { Double Top/Single Side }

  { Box Shadow Styles }
    bsSingleWide = $00; { one character wide }
    bsDoubleWide = $01; { two characters wide }

  { Line Constants }
    lnSingle     = $00;
    lnDouble     = $01;
    lnVertical   = $02;
    lnHorizontal = $00;
    lnNoEnds     = $04;
    lnNoCenter   = $08;

  { Event Constants }
    evNothing   = $0000; { Event already handled }
    evKeyDown   = $0010; { Key pressed }
    evKeyboard  = $0010; { Keyboard event }
    evCommand   = $0100; { Command event }
    evBroadcast = $0200; { Broadcast event }
    evSystem    = $0400; { System Event }
    evMessage   = $FF00; { Message (command, broadcast, or user-defined) event }

  { Predefined Event Commands }
    cmNone          = $0000;
    cmClearedEvent  = $0001;
    cmMakeSysReq    = $0002;
    cmBreakSysReq   = $0003;
    cmPrintScreen   = $0004;
    cmBreak         = $0005;
    cmQuit          = $0006;
    cmHelp          = $0007;

  { Keyboard Shift Key Status Flags }
    RightSHift = $0001;
    LeftShift  = $0002;
    EitherCtrl = $0004;
    EitherAlt  = $0008;
    ScrollLock = $0010;
    NumsLock   = $0020;
    CapsLock   = $0040;
    InsertLock = $0080;
    LeftCtrl   = $0100;
    LeftAlt    = $0200;
    SysDown    = $0400;
    PauseFlag  = $0800;
    ScrollDown = $1000;
    NumsDown   = $2000;
    CapsDown   = $4000;
    InsertDown = $8000;

var
    InsertMode: boolean;    { Insert/Overtype mode switch }

  type
    TPoint = record
      X : byte;
      Y : byte;
    end;

    TEvent = record
      What: Word;
      case Word of
        evNothing: ();
        evKeyDown: (
          ShiftCode : word;
          case Integer of
            0: (KeyCode: Word);
            1: (CharCode: Char;
                ScanCode: Byte));
        evMessage: (
          Command: Word;
          case Word of
            0: (InfoPtr: Pointer);
            1: (InfoLong: Longint);
            2: (InfoWord: Word);
            3: (InfoInt: Integer);
            4: (InfoByte: Byte);
            5: (InfoChar: Char));
    end;

{ Box and Line Functions }
  procedure DrawBox ( X1, Y1, X2, Y2, Style : byte );
  { Draws a box.  Does not move Cursor. }
  procedure DrawShadow ( X1, Y1, X2, Y2, Style : byte );
  { Draws a shadow for a box.  Does not move Cursor. }
  procedure DrawLine ( X1, Y1, Len, Style : byte );
  { Draws a line.  Does not move the Cursor. }

{ Event Functions }
  procedure PurgeEvents;
  procedure ClearEvent(var Event : TEvent);
  procedure GetEvent(var Event : TEvent);
  function  PutEvent(var Event : TEvent) : boolean;

{ Text input functions }
  function EditLn ( var Dest : String; First : boolean;
    MaxLen, MaxWide : Byte; var Event : TEvent) : boolean;

  function GetMaxX : integer;
  function GetMaxY : integer;

implementation

  const
    KeyBufSize         = 16;
    CommandBufSize     = 128;

{$F+}
(* Internal Event Buffer Handler *)
  type
    PEvents = ^TEvents;
    TEvents = array[1..$FFFF div Sizeof(TEvent)] of TEvent;
    EventBuf = object
         Buf   : PEvents;
         Head,
         Tail,
         Max,
         Count : word;
      procedure Init( ABuf : PEvents; AMax : word );
      procedure Done;
      procedure Purge;
      function  UsedSpace : word;
      function  FreeSpace : word;
      function  GetEvent(var Event : TEvent) : boolean;
      function  PutEvent(var Event : TEvent) : boolean;
    end;

  procedure EventBuf.Init( ABuf : PEvents; AMax : word );
    begin
      Buf := ABuf;
      Max := AMax;
      Purge;
    end;

  procedure EventBuf.Done;
    begin
      Purge;
    end;

  procedure EventBuf.Purge;
    begin
      Head  := 1;
      Tail  := 1;
      Count := 0;
    end;

  function  EventBuf.UsedSpace : word;
    begin
      UsedSpace := Count;
    end;

  function  EventBuf.FreeSpace : word;
    begin
      FreeSPace := Max - Count;
    end;

  function  EventBuf.GetEvent(var Event : TEvent) : boolean;
    begin
      if UsedSpace > 0 then
        begin
          Event := Buf^[Head];
          Inc(Head);
          Inc(Count);
          if Head > Max then Head := 1;
          GetEvent := True;
        end
      else
        GetEvent := False;
    end;

  function  EventBuf.PutEvent(var Event : TEvent) : boolean;
    begin
      if FreeSpace > 0 then
        begin
          Buf^[Tail] := Event;
          Inc(Tail);
          Dec(Count);
          if Tail > Max then Tail := 1;
          PutEvent := True;
        end
      else
        PutEvent := False;
    end;

type
    BoxStr = Array[0..6] of Char;
    LineStr = String[41];


  const
    BoxData : array[bxSingle..bxDouble] of BoxStr = (
       'Ú¿ÀÙÄ³', {bxSingle}
       'Ö·Ó½Äº', {bxDoubleSide}
       'Õ¸Ô¾Í³', {bxDoubleTop}
       'É»È¼Íº'  {bxDouble}
    );
    LineData : record
      Current : LineStr;
      Style: array[lnSingle..lnDouble,boolean,(Top, Middle, Bottom)] of LineStr;
    end = (
      Current:'ÍÄº³ÉË»ÌÎ¹ÈÊ¼ÖÒ·Ç×¶ÓÐ½ÕÑ¸ÆØµÔÏ¾ÚÂ¿ÃÅ´ÀÁÙ';
      Style:(

      ( { Single Line }
        ( { Horizontal }
          'ÄÄÇÃÖÒÒÇ××ÓÐÐÖÒÒÇ××ÓÐÐÚÂÂÃÅÅÀÁÁÚÂÂÃÅÅÀÁÁÄ', { Left }
          'ÄÄ×ÅÒÒÒ×××ÐÐÐÒÒÒ×××ÐÐÐÂÂÂÅÅÅÁÁÁÂÂÂÅÅÅÁÁÁÄ', { Middle }
          'ÄÄ¶´ÒÒ·××¶ÐÐ½ÒÒ·××¶ÐÐ½ÂÂ¿ÅÅ´ÁÁÙÂÂ¿ÅÅ´ÁÁÙÄ'  { Right }),
        ( { Vertical }
          'ÑÂ³³ÕÑ¸ÆØµÆØµÚÂ¿ÃÅ´ÃÅ´ÕÑ¸ÆØµÆØµÚÂ¿ÃÅ´ÃÅ´³', { Top }
          'ØÅ³³ÆØµÆØµÆØµÃÅ´ÃÅ´ÃÅ´ÆØµÆØµÆØµÃÅ´ÃÅ´ÃÅ´³', { Middle }
          'ÏÁ³³ÆØµÆØµÔÏ¾ÃÅ´ÃÅ´ÀÁÙÆØµÆØµÔÏ¾ÃÅ´ÃÅ´ÀÁÙ³'  { Bottom })),
      ( { Double Line }
        ( { Horizontal }
          'ÍÍÌÆÉËËÌÎÎÈÊÊÉËËÌÎÎÈÊÊÕÑÑÆØØÔÏÏÕÑÑÆØØÔÏÏÍ', { Left }
          'ÍÍÎØËËËÎÎÎÊÊÊËËËÎÎÎÊÊÊÑÑÑØØØÏÏÏÑÑÑØØØÏÏÏÍ', { Middle }
          'ÍÍ¹µËË»ÎÎ¹ÊÊ¼ËË»ÎÎ¹ÊÊ¼ÑÑ¸ØØµÏÏ¾ÑÑ¸ØØµÏÏ¾Í'  { Right }),
        ( { Vertical }
          'ËÒººÉË»ÌÎ¹ÌÎ¹ÖÒ·Ç×¶Ç×¶ÉË»ÌÎ¹ÌÎ¹ÖÒ·Ç×¶Ç×¶º', { Top }
          'Î×ººÌÎ¹ÌÎ¹ÌÎ¹Ç×¶Ç×¶Ç×¶ÌÎ¹ÌÎ¹ÌÎ¹Ç×¶Ç×¶Ç×¶º', { Middle }
          'ÊÐººÌÎ¹ÌÎ¹ÈÊ¼Ç×¶Ç×¶ÓÐ½ÌÎ¹ÌÎ¹ÈÊ¼Ç×¶Ç×¶ÓÐ½º'  { Bottom }))
      )
    );

  var
    KeyBuffer     : array[1..KeyBufSize] of TEvent;
    CommandBuffer : array[1..CommandBufSize] of TEvent;
    KeyBuf        : EventBuf;
    CommandBuf    : EventBuf;



(* Unit shutdown procedure *)
  procedure DoneVideoUnit; far;
    begin
      CommandBuf.Done;
      KeyBuf.Done;
    end;

(* Unit initialization procedure *)
  procedure InitQCRTUnit;
    var
      P : Pointer;
    begin
      InsertMode    := True;
      KeyBuf.Init    (@KeyBuffer, KeyBufSize);
      CommandBuf.Init(@KeyBuffer, KeyBufSize);
    end;

function FReadChar : char;
begin
    FReadChar := #32;
end;

function FReadCharAttr : word;
begin
    FReadCharAttr := $0732;
end;


{ Box and line functions }
  procedure DrawBox ( X1, Y1, X2, Y2, Style : byte );
    var
      CursorX, CursorY : byte;
      RangeX,  RangeY  : byte;
      I                : byte;
    begin
      RangeX := GetMaxX;
      RangeY := GetMaxY;
      if (X1 > RangeX) or (Y1 > RangeY) then Exit;
      CursorX := WhereX;
      CursorY := WhereY;
      { Draw Top }
      GotoXY( X1, Y1 );
      Write(BoxData[Style][0] );
      for I := X1 + 1 to X2 - 1 do
        if I > RangeX then Break else
          Write( BoxData[Style][4] );
      if (X2 <= RangeX) and (X1 <> X2) then
        Write( BoxData[Style][1] );
      { Draw Sides }
      for I := Y1 + 1 to Y2 - 1 do
        if I > RangeY then Break else
          begin
            GotoXY ( X1, I );
            Write(BoxData[Style][5]);
            if (X2 <= RangeX) and (X1 <> X2) then
              begin
                GotoXY ( X2, I );
                Write(BoxData[Style][5]);
              end;
          end;
      { Draw Bottom }
      if (Y2 <= RangeY) and (Y2 <> Y1) then
        begin
          GotoXY( X1, Y2 );
          Write(BoxData[Style][2] );
          for I := X1 + 1 to X2 - 1 do
            if I > RangeX then Break else
              Write( BoxData[Style][4] );
          if (X2 <= RangeX) and (X1 <> X2) then
            Write( BoxData[Style][3] );
        end;
      GotoXY ( CursorX, CursorY );
    end;

  procedure DrawShadow ( X1, Y1, X2, Y2, Style : byte );
    var
      CursorX, CursorY : byte;
      RangeX,  RangeY  : byte;
      C                : Char;
      Attr             : byte;
      I                : byte;
    begin
      RangeX := GetMaxX;
      RangeY := GetMaxY;
      Inc(X1,1);
      Inc(Y1,1);
      Inc(X2,1);
      Inc(Y2,1);
      if Style and bsDoubleWide = bsDoubleWide then
        Inc(X1, 1);
      if (X1 > RangeX) or (Y1 > RangeY) then Exit;
      CursorX  := WhereX;
      CursorY  := WhereY;
      Attr     := TextAttr;
      TextAttr := $08;
      { Draw Sides }
      if (X2 <= RangeX) and (X1 <> X2) then
        for I := Y1 to Y2 do
          if I > RangeY then Break else
            begin
              GotoXY ( X2, I );
              C := FReadChar;
              GotoXY ( X2, I );
              WriteRawPStr( C );
              if (X2 + 1 <= RangeX) and (Style and bsDoubleWide = bsDoubleWide) then
                begin
                  C := FReadChar;
                  GotoXY ( X2 + 1, I );
                  WriteRawPStr( C );
                end;
            end;
      { Draw Bottom }
      if (Y2 <= RangeY) and (Y2 <> Y1) then
        for I := X1 to X2 - 1 do
          if I > RangeX then Break else
            begin
              GotoXY ( I, Y2 );
              C := FReadChar;
              GotoXY ( I, Y2 );
              WriteRawPStr( C );
            end;
      TextAttr := Attr;
      GotoXY ( CursorX, CursorY );
    end;

  procedure DrawLine ( X1, Y1, Len, Style : byte );
    var
      CursorX, CursorY : byte;
      RangeX,  RangeY  : byte;
      I,       TPos    : byte;
    begin
      CursorX := WhereX;
      CursorY := WhereY;
      RangeX  := GetMaxX;
      RangeY  := GetMaxY;
      Dec(Len);
      TPos := 41;
      Case Style and lnVertical = lnVertical of
        False : begin
          for I := X1 + 1 to X1 + Len - 1 do
            if I > RangeX then Break else
              begin
                GotoXY (I, Y1);
                WriteRawPStr ( LineData.Style[Style and lnDouble, False, Middle][TPos]);
              end;
        end;
        True : begin
          for I := Y1 + 1 to Y1 + Len - 1 do
            if I > RangeY then Break else
              begin
                GotoXY ( X1, I );
                WriteRawPStr ( LineData.Style[Style and lnDouble, True, Middle][TPos]);
              end;
        end;
      end;
      GotoXY ( CursorX, CursorY );
    end;

{ Event Functions }
  procedure PurgeEvents;
    begin
      CommandBuf.Purge;
      KeyBuf.Purge;
    end;

  procedure ClearEvent(var Event : TEvent);
    begin
      Event.What := evNothing;
      Event.Command := cmClearedEvent;
    end;

  procedure GetEvent(var Event : TEvent);
    var
        Temp : TEvent;
    begin
      ClearEvent(Event);
      while KeypressedEnhanced do begin
          ClearEvent(Temp);
          Temp.What := evKeyDown;
          Temp.ShiftCode := MemW[Seg0040:$0017];
          Temp.KeyCode := ReadKeyEnhanced;
          KeyBuf.PutEvent(Temp);
      end;

      if Not CommandBuf.GetEvent(Event) then
      if Not KeyBuf.GetEvent(Event)     then
        begin
        end;
    end;

  function PutEvent(var Event : TEvent) : boolean;
    begin
      PutEvent := CommandBuf.PutEvent(Event);
    end;

  function GetMaxX : integer;
  begin
    GetMaxX := Lo(WindMax) + 1;
  end;

  function GetMaxY : integer;
  begin
    GetMaxY := Hi(WindMax) + 1;
  end;

  function EditLn ( var Dest : String; First : boolean; MaxLen, MaxWide : Byte; var Event : TEvent) : boolean;
    const
      Source : String = '';
      OfsX   : byte = 0;
      CurX   : byte = 255;
    var
      OrgX,  OrgY : Byte;
      Cursor      : word;
      DoneFlag    : Boolean;

    procedure EditCursor;
      begin
        case InsertMode of
          True  : SmallCursor;
          False : HalfCursor;
        end;
      end;

    procedure DisplayStr;
      var
        TAttr : byte;
      begin
        TAttr := TextAttr;
        GotoXY ( OrgX, OrgY );
        if OfsX > 0 then
          WriteRawPStr(#17)
        else
          WriteRawPStr(#32);
        WriteRawPStr(RSpace(Copy(Dest, OfsX + 1, MaxWide - 2), MaxWide - 2));
        if OfsX + MaxWide - 2 < Length((Dest)) then
          WriteRawPStr(#16)
        else
          WriteRawPStr(#32);
        TextAttr := TAttr;
        GotoXY(OrgX + CurX, OrgY);
      end;

    function Left(Display : boolean) : boolean;
      begin
        if CurX + OfsX > 1 then
          begin
            Dec(CurX);
            if CurX < 1 then
            begin
              CurX := 1;
              Dec(OfsX);
            end;
          end;
        if Display then DisplayStr;
        Left := CurX + OfsX > 1;
      end;

    function Right(Display : boolean) : boolean;
      begin
        if CurX + OfsX <= Length(Dest) then
          begin
            Inc(CurX);
            if CurX > MaxWide - 2 then
              begin
                Dec(CurX);
                Inc(OfsX);
              end;
          end;
        if Display then DisplayStr;
        Right := CurX + OfsX <= Length(Dest);
      end;

    procedure Home;
      begin
        OfsX := 0;
        CurX := 1;
        DisplayStr;
      end;

    procedure EndLine;
      begin
        while (CurX + OfsX > Length(Dest)) and (CurX + OfsX > 1) do
          begin
            Dec(CurX);
            if CurX < 1 then
            begin
              CurX := 1;
              Dec(OfsX);
            end;
          end;
        while Right(False) do;
        DisplayStr;
      end;

    procedure LeftWord;
      begin
        if Dest = '' then
          Home
        else
          begin
            Left(False);
            While (CurX + OfsX > Length(Dest)) and Left(False) do;
            if Dest[CurX + OfsX] = #32 then
              while (Dest[CurX + OfsX] = #32) and Left(False) do;
            while (Dest[CurX + OfsX] <> #32) and Left(False) do;
            if CurX + OfsX > 1 then Right(False);
          end;
        DisplayStr;
      end;

    procedure RightWord;
      begin
        if Dest = '' then
          Home
        else
          begin
            if CurX + OfsX < MaxLen then
              begin
                if Dest[CurX + OfsX] = #32 then
                  while (Dest[CurX + OfsX] = #32) and Right(False) do
                else
                  while (Dest[CurX + OfsX] <> #32) and Right(False) do;
                if Dest[CurX + OfsX] = #32 then
                  while (Dest[CurX + OfsX] = #32) and Right(False) do;
              end;
          end;
        DisplayStr;
      end;

    procedure VerifyPosition;
      begin
        if (Dest = '')  or (OfsX + CurX - 1 > Length(Dest)) then
          begin
            CurX := 1;
            OfsX := 0;
            EndLine;
          end;
        DisplayStr;
      end;

    procedure HandleKeyboard;
      begin
        Case Event.KeyCode of
          $0009, { TAB }
          $0F00, { Shift-TAB }
          $001A, { CTRL-Z }
          $0003, { CTRL-C }
          $007F, { CTRL-BACKSPACE }
          $000A  { CTRL-ENTER } : DoneFlag := True;
          $0008 : if OfsX + CurX > 1 then begin
            Delete(Dest, OfsX + CurX - 1, 1);
            Left(True);
          end;
          $000D : begin { Enter }
            Home;
            DoneFlag := True;
          end;
          $001B : begin { Escape }
            Dest := Source;
            Home;
            DoneFlag := True;
          end;
          $4B00, $7300 : begin
            if Event.ShiftCode and EitherCtrl = EitherCtrl then
              LeftWord
            else
              Left(True);
          end;
          $4D00, $7400 : begin
            if Event.ShiftCode and EitherCtrl = EitherCtrl then
              RightWord
            else
              Right(True);
          end;
          $5200 : begin
            InsertMode := Not InsertMode;
            DisplayStr;
          end;
          $5300 : if OfsX + CurX <= MaxLen then begin
            Delete(Dest, OfsX + CurX, 1);
            DisplayStr;
          end;
          $4700 : Home;
          $4F00 : EndLine;
          $0000..$00FF : case InsertMode of
            True : if (Length(RTrim(Dest)) < MaxLen) and (CurX + OfsX <= MaxLen) then begin
              while Length(Dest) < CurX + OfsX - 1 do AddChar(Dest, #32);
              Insert(Event.CharCode, Dest, CurX + OfsX);
              Right(True);
            end;
            False : if (Length(RTrim(Dest)) <= MaxLen) and (CurX + OfsX <= MaxLen) then begin
              while Length(Dest) < CurX + OfsX do AddChar(Dest, #32);
              Dest[CurX + OfsX] := Event.CharCode;
              Right(True);
            end;
          end;
        else
          DoneFlag := True;
        end;
      end;

    begin
      OrgX := WhereX;
      OrgY := WhereY;
      if First then
        begin
          OfsX   := 0;
          CurX   := 1;
          Source := Dest;
          EndLine;
        end
      else
        VerifyPosition;

      repeat
        DoneFlag := False;
        EditCursor;
        GotoXY(OrgX + CurX, OrgY);
        repeat
          GetEvent(Event);
        until Event.What <> evNothing;
        HideCursor;
        if Event.What and evSystem <> evNothing then DoneFlag := True else
        if Event.What and evKeyDown = evKeyDown then HandleKeyboard;
      until DoneFlag;
      EditLn := (Event.What = evKeyDown) and (Event.KeyCode = $000D);
    end;

begin
  InitQCRTUnit;
end.
