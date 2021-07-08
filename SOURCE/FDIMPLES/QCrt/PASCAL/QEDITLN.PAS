{
Copyright 1990-2016, Jerome Shidel.

This project and related files are subject to the terms of the Mozilla Public License,
v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at
http://mozilla.org/MPL/2.0/.
}

{$I QCRT.DEF}
unit QEDITLN; { version 9.0x }

interface

uses QCrt, QEvents, QStrings;

var
    InsertMode: boolean;    { Insert/Overtype mode switch }

{ Text input functions }
  function EditLn ( var Dest : String; First : boolean;
    MaxLen, MaxWide : Byte; var Event : TEvent) : boolean;

implementation

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
    InsertMode := True;
end.
