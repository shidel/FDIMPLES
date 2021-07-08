{
    Copyright 2019 Jerome Shidel
    Released Under GPL v2.0 License.
}

{ This code really needs optimized. Someday maybe.
  Also, recent changes to support Windows, Unix, Old Macintosh Line-endings
  is largely untested and may be buggy. }

unit QFiles; { QuickCrt 9.x, Files Unit }

{$I QCRT.DEF}

interface

uses QClass, QDOS;

  const
    { File status flags }
    flInvalid  = $0000; { Is Not Valid }
    flAssigned = $0001; { IsAssigned }
    flOpened   = $0002; { IsOpen }
    flFlush    = $0004; { Needs Flushed }
    flErase    = $0008; { Erase when disposed (not advised) }
    flError    = $0010; { Is Error Code }
    flRead     = $0020; { File can be read }
    flWrite    = $0040; { File can be written }
    flRandom   = $0060; { File can be read or written }
    flModified = $0080; { File has been modified since opened }

    { SetIOResult return commands }
    fcOK       = $00;
    fcIgnore   = $01;
    fcRetry    = $02;
    fcAbort    = $03;

    { Possible Error Codes, Excluding DOS & IO error codes }
	erNone								   = 0;
	erFile_Access_Denied                   = 5;
	erFile_Not_Assigned                    = 102;
	erFile_Not_Open                        = 103;
	erFile_Not_Open_For_Input              = 104;
	erFile_Not_Open_For_Output             = 105;
    erDevice_Write_Fault                   = 160;
	erDevice_Read_Fault                    = 161;

  type
    PAbstractFile = ^TAbstractFile;
    TAbstractFile = object (TObject)
	public { protected }
	public
        Ptr    : LongInt;
        Flags  : word;
        Name   : String;
        Result : integer;
        StrictLines : boolean;
      constructor Create(AOwner : PObject);
      destructor  Destroy; virtual;
      function  GetClassName : String; virtual;
      procedure Assign( AFileName : String ); virtual;
      procedure BlockRead(const ABuf; ACount: Word; var AResult: Word); virtual;
      procedure BlockWrite(const ABuf; ACount: Word; var AResult: Word); virtual;
      procedure Close; virtual;
      procedure Erase; virtual;
      function  FileSize: Longint; virtual;
      procedure Flush; virtual;
      procedure Rename( ANewName : String ); virtual;
      procedure Reset; virtual;
      procedure Rewrite; virtual;
      procedure Seek(AFilePos: Longint); virtual;
      procedure Truncate; virtual;
      function  SetIOResult ( AIOResult : integer ) : byte; virtual;
      procedure SetFileMode; virtual;
    { the following procedures/functions should not need to be overridden }
      procedure Append;
      procedure Copy(var AFile : PAbstractFile; ACount: LongInt);
      function  Sof: Boolean;
      function  Eof: Boolean;
      function  FilePos: Longint;
      function  IOResult: Integer;
      function  SeekSof: Boolean;
      function  SeekEof: Boolean;
      procedure SetMode ( AFlags : word );
      function Modified : boolean;
    { Should never, ever need overridden (they all call BlockRead) }
      procedure Insert(ACount : longint);
      procedure Delete(ACount : longint);
      procedure ReadRecord    (const AAdr; ASize : word);
      procedure WriteRecord   (const AAdr; ASize : word);
      procedure ReadChar      (const AChr );
      procedure WriteChar     (const AChr );
      procedure ReadBoolean   (const ABoolean);
      procedure WriteBoolean  (const ABoolean);
      procedure ReadByteBool  (const AByteBool);
      procedure WriteByteBool (const AByteBool);
      procedure ReadWordBool  (const AWordBool);
      procedure WriteWordBool (const AWordBool);
      procedure ReadLongBool  (const ALongBool);
      procedure WriteLongBool (const ALongBool);
      procedure ReadByte      (const AByte);
      procedure WriteByte     (const AByte);
      procedure ReadWord      (const AWord);
      procedure WriteWord     (const AWord);
      procedure ReadShortInt  (const AShortInt);
      procedure WriteShortInt (const AShortInt);
      procedure ReadInteger   (const AInteger);
      procedure WriteInteger  (const AInteger);
      procedure ReadLongInt   (const ALongInt);
      procedure WriteLongInt  (const ALongInt);
      procedure ReadReal      (const AReal);
      procedure WriteReal     (const AReal);
      procedure ReadSingle    (const ASingle);
      procedure WriteSingle   (const ASingle);
      procedure ReadDouble    (const ADouble);
      procedure WriteDouble   (const ADouble);
      procedure ReadComp      (const AComp);
      procedure WriteComp     (const AComp);
      procedure ReadExtended  (const AExtended);
      procedure WriteExtended (const AExtended);
      procedure ReadString  (const AString; AStrSize : word);
      procedure WriteString (const AString; AStrSize : word);
      function  GetString   : String;
      procedure PutString   (const AString);
    { Text files }
      function  Soln: boolean;
      function  Eoln: Boolean;
      function  SeekSoln: boolean;
      function  SeekEoln: Boolean;
      function  SeekLn ( ANumber : LongInt ) : boolean;
      function  Read  ( const AStr; AMax : word ) : boolean; { true if reached eol}
      procedure Write ( const AStr );
      function  ReadLn  ( const AStr; AMax : word ) : boolean; { false if line is truncated }
      procedure WriteLn ( const AStr );
      function  LengthLn : word;
      procedure InsertLn ( ALen : word );
      procedure DeleteLn;
      procedure ResizeLn ( ALen : word );
    end;

    PDiskFile = ^TDiskFile;
    TDiskFile = object( TAbstractFile )
	public { protected }
	public
        FRec : File;
      constructor Create(AOwner : PObject);
      destructor  Destroy; virtual;
      function  GetClassName : String; virtual;
      procedure Assign( AFileName : String ); virtual;
      procedure BlockRead(const ABuf; ACount: Word; var AResult: Word); virtual;
      procedure BlockWrite(const ABuf; ACount: Word; var AResult: Word); virtual;
      procedure Close; virtual;
      procedure Erase; virtual;
      function FileSize: Longint; virtual;
      procedure Flush; virtual;
      procedure Rename( ANewName : String ); virtual;
      procedure Reset; virtual;
      procedure Rewrite; virtual;
      procedure Seek(AFilePos: Longint); virtual;
      procedure Truncate; virtual;
      function GetName : String; virtual;
    end;

function NewAbstractFile(AOwner:PObject) : PObject;
function NewDiskFile(AOwner:PObject) : PObject;

implementation

  const
    CRLF : String[2] = #13#10;

  var
    Buf : array[0..511] of byte;

  function TAbstractFile.GetClassName : String;
  begin
     GetClassName := 'TAbstractFile';
  end;

  constructor TAbstractFile.Create(AOwner : PObject);
    begin
      inherited Create(AOwner);
      Ptr := 0;
      Name := '';
      StrictLines := False;
      Flags := flInvalid or flRandom;
      SetIOResult(erNone);
    end;

  destructor TAbstractFile.Destroy;
    begin
      if Flags and flOpened = flOpened then Close;
      if Flags and flErase = flErase then Erase;
    end;

  procedure TAbstractFile.Assign( AFileName : String );
    begin
      if (Flags and flOpened = flOpened) then
        SetIOResult(erFile_access_denied)
      else
        begin
          SetIOResult ( erNone );
          Name := AFileName;
          SetFileMode;
        end;
    end;

  procedure TAbstractFile.BlockRead(const ABuf; ACount: Word; var AResult: Word);
    begin
      AResult := 0;
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
      if (Flags and flOpened <> flOpened ) then
        SetIOResult(erFile_not_open)
      else
      if (Flags and flRead <> flRead) then
        SetIOResult(erFile_not_open_for_input)
      else
        SetIOResult ( erNone );
    end;

  procedure TAbstractFile.BlockWrite(const ABuf; ACount: Word; var AResult: Word);
    begin
      AResult := 0;
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
      if (Flags and flOpened <> flOpened) then
        SetIOResult(erFile_not_open)
      else
      if (Flags and flWrite <> flWrite) then
        SetIOResult(erFile_not_open_for_output)
      else
        SetIOResult ( erNone );
    end;

  procedure TAbstractFile.Close;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
      if (Flags and flOpened <> flOpened) then
        SetIOResult(erFile_not_open)
      else
        begin
          SetIOResult ( erNone );
          if Flags and flFlush = flFlush then Flush;
        end;
    end;

  procedure TAbstractFile.Erase;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
      if (Flags and flOpened = flOpened) then
        SetIOResult(erFile_access_denied)
      else
        SetIOResult ( erNone );
    end;

  function TAbstractFile.FilePos: Longint;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
      if (Flags and flOpened <> flOpened) then
        SetIOResult(erFile_not_open)
      else
        begin
          SetIOResult( erNone );
          FilePos := Ptr;
        end;
    end;

  function TAbstractFile.FileSize: Longint;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
      if (Flags and flOpened <> flOpened) then
        SetIOResult(erFile_not_open)
      else
        begin
          SetIOResult ( erNone );
          FileSize := 0;
        end;
    end;

  procedure TAbstractFile.Flush;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
      if (Flags and flOpened <> flOpened) then
        SetIOResult(erFile_not_open)
      else
      if (Flags and flWrite <> flWrite) then
        SetIOResult(erFile_not_open_for_output)
      else
        SetIOResult ( erNone );
    end;

  function TAbstractFile.IOResult: Integer;
    begin
      IOResult := Result;
      SetIOResult(erNone);
    end;

  function TAbstractFile.SetIOResult ( AIOResult : integer ) : byte;
    begin
      if AIOResult <> erNone then
        Flags := Flags or flError
      else
        Flags := Flags and (not flError);
      Result := AIOResult;
      case AIOResult of
        erNone : SetIOResult := fcOK;
      else
        SetIOResult := fcAbort;
        {$IFOPT I+}
        RunError(AIOResult);
        {$ENDIF}
      end;
    end;

  procedure TAbstractFile.Rename;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
        SetIOResult ( erNone );
    end;

  procedure TAbstractFile.Reset;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
        begin
          SetIOResult ( erNone );
          if (Flags and flOpened = flOpened) then
            Close;
          if (Flags and flError <> flError) then
            SetMode ( Flags or flRead );
        end;
    end;

  procedure TAbstractFile.Rewrite;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
        begin
          SetIOResult ( erNone );
          if (Flags and flOpened = flOpened) then
            Close;
          if (Flags and flError <> flError) then
            SetMode ( Flags or flWrite );
        end;
    end;

  procedure TAbstractFile.Seek(AFilePos: Longint);
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
      if (Flags and flOpened <> flOpened) then
        SetIOResult(erFile_not_open)
      else
        SetIOResult ( erNone );
    end;

  procedure TAbstractFile.Truncate;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
      if (Flags and flOpened <> flOpened) then
        SetIOResult(erFile_not_open)
      else
        SetIOResult ( erNone );
    end;

  procedure TAbstractFile.Append;
    begin
      if (Flags and flAssigned <> flAssigned) then
        SetIOResult(erFile_not_assigned)
      else
        begin
          SetIOResult ( erNone );
          if (Flags and flOpened = flOpened) then
            Close;
          if (Flags and flError <> flError) then
            SetMode ( Flags or flRandom );
        end;
    end;

  procedure TAbstractFile.Copy(var AFile : PAbstractFile; ACount: LongInt);
    var
      RCount, WCount : word;
    begin
      repeat
        BlockRead(Buf, Sizeof(Buf), RCount);
        if (Flags and flError <> flError) then
          AFile^.BlockWrite(Buf, RCount, WCount);
      until Eof or (Flags and flError = flError) or
        (AFile^.Flags and flError = flError) or (RCount <> Sizeof(Buf)) or
        (RCount <> WCount);
    end;

  function TAbstractFile.Sof: Boolean;
    begin
      Sof := (Ptr = 0 );
    end;

  function TAbstractFile.Eof: Boolean;
    begin
      Eof := (FileSize <= Ptr );
    end;

  function TAbstractFile.SeekSof: Boolean;
    begin
      Seek( 0 );
      SeekSof := Flags and flError <> flError;
    end;

  function TAbstractFile.SeekEof: Boolean;
    var
      tSize : LongInt;
    begin
      tSize := FileSize;
      if (Flags and flError <> flError) then
        Seek( tSize );
      SeekEof := Flags and flError <> flError;
    end;

  procedure TAbstractFile.SetMode ( AFlags : word );
    begin
      Flags := (Flags and (Not flRandom)) or AFlags;
      SetFileMode;
    end;

  procedure TAbstractFile.SetFileMode;
  var
    T : word;
  begin
    T := flInvalid;
    if Flags or flRead    = flRead then T := T or 1;
    if Flags or flWrite   = flWrite then T := T or 2;
    if Flags or flRandom  = flRandom then T := T or 3;
{    if Flags or flRandom  = flRandom then T := 0; }

    {$IFDEF UseFileMode}
    FileMode := (FileMode and (not 3)) or T;
    {$ENDIF}
  end;

  function TAbstractFile.Modified : boolean;
  begin
    Modified := Flags and flModified = flModified;
  end;

  procedure TAbstractFile.Insert(ACount : longint);
    var
      tSize,
      Count  : word;
      OldPtr : LongInt;
      CurPtr : LongInt;
    begin
      OldPtr := FilePos;
      if (Flags and flError = flError) or (ACount < 1) then Exit;
      CurPtr := FileSize;
      if (Flags and flError <> flError) then
        repeat
          tSize := Sizeof(Buf);
          if CurPtr - tSize < OldPtr then
            tSize := CurPtr - OldPtr;
          Dec(CurPtr, tSize);
          Seek(CurPtr);
          if (Flags and flError <> flError) then BlockRead(Buf, tSize, Count);
          if (Flags and flError <> flError) then Seek(CurPtr + ACount);
          if (Flags and flError <> flError) then BlockWrite(Buf, tSize, Count);
        until (CurPtr = OldPtr) or (Flags and flError = flError);
      if (Flags and flError <> flError) then Seek(OldPtr);
    end;

  procedure TAbstractFile.Delete(ACount : longint);
    var
      tSize,
      Count  : word;
      OldPtr : LongInt;
      CurPtr : LongInt;
      fSize  : LongInt;
    begin
      OldPtr := FilePos;
      if (Flags and flError = flError) or (ACount < 1) then Exit;
      fSize := FileSize;
      CurPtr := OldPtr + ACount;
      if (Flags and flError <> flError) then
        repeat
          tSize := Sizeof(Buf);
          if CurPtr + tSize > fSize then
            tSize := fSize - CurPtr;
          Seek(CurPtr);
          if (Flags and flError <> flError) then BlockRead(Buf, tSize, Count);
          if (Flags and flError <> flError) then Seek(CurPtr - ACount);
          if (Flags and flError <> flError) then BlockWrite(Buf, tSize, Count);
          Inc(CurPtr, tSize);
        until (CurPtr >= fSize) or (Flags and flError = flError);
      if (Flags and flError <> flError) then Truncate;
      if (Flags and flError <> flError) then Seek(OldPtr);
    end;

  procedure TAbstractFile.ReadRecord (const AAdr; ASize : word);
    var
      Count : word;
    begin
      BlockRead ( AAdr, ASize, Count );
      if (Flags and flError <> flError) and (Count <> ASize) then
        SetIOResult(erDevice_Read_Fault);
    end;

  procedure TAbstractFile.WriteRecord (const AAdr; ASize : word);
    var
      Count : word;
    begin
      BlockWrite ( AAdr, ASize, Count );
      if (Flags and flError <> flError) and (Count <> ASize) then
        SetIOResult(erDevice_Write_Fault);
    end;

  procedure TAbstractFile.ReadChar ( const AChr );
    begin
      ReadRecord(AChr, Sizeof(Char));
    end;

  procedure TAbstractFile.WriteChar ( const AChr );
    begin
      WriteRecord(AChr, Sizeof(Char));
    end;

  procedure TAbstractFile.ReadBoolean   (const ABoolean);
    begin
      ReadRecord(ABoolean, Sizeof(Boolean));
    end;

  procedure TAbstractFile.WriteBoolean  (const ABoolean);
    begin
      WriteRecord(ABoolean, Sizeof(Boolean));
    end;

  procedure TAbstractFile.ReadByteBool  (const AByteBool);
    begin
      ReadRecord(AByteBool, Sizeof(ByteBool));
    end;

  procedure TAbstractFile.WriteByteBool (const AByteBool);
    begin
      WriteRecord(AByteBool, Sizeof(ByteBool));
    end;

  procedure TAbstractFile.ReadWordBool  (const AWordBool);
    begin
      ReadRecord(AWordBool, Sizeof(WordBool));
    end;

  procedure TAbstractFile.WriteWordBool (const AWordBool);
    begin
      WriteRecord(AWordBool, Sizeof(WordBool));
    end;

  procedure TAbstractFile.ReadLongBool  (const ALongBool);
    begin
      ReadRecord(ALongBool, Sizeof(LongBool));
    end;

  procedure TAbstractFile.WriteLongBool (const ALongBool);
    begin
      WriteRecord(ALongBool, Sizeof(LongBool));
    end;

  procedure TAbstractFile.ReadByte      (const AByte);
    begin
      ReadRecord(AByte, Sizeof(Byte));
    end;

  procedure TAbstractFile.WriteByte     (const AByte);
    begin
      WriteRecord(AByte, Sizeof(Byte));
    end;

  procedure TAbstractFile.ReadWord      (const AWord);
    begin
      ReadRecord(AWord, Sizeof(Word));
    end;

  procedure TAbstractFile.WriteWord     (const AWord);
    begin
      WriteRecord(AWord, Sizeof(Word));
    end;

  procedure TAbstractFile.ReadShortInt  (const AShortInt);
    begin
      ReadRecord(AShortInt, Sizeof(ShortInt));
    end;

  procedure TAbstractFile.WriteShortInt (const AShortInt);
    begin
      WriteRecord(AShortInt, Sizeof(ShortInt));
    end;

  procedure TAbstractFile.ReadInteger   (const AInteger);
    begin
      ReadRecord(AInteger, Sizeof(Integer));
    end;

  procedure TAbstractFile.WriteInteger  (const AInteger);
    begin
      WriteRecord(AInteger, Sizeof(Integer));
    end;

  procedure TAbstractFile.ReadLongInt   (const ALongInt);
    begin
      ReadRecord(ALongInt, Sizeof(LongInt));
    end;

  procedure TAbstractFile.WriteLongInt  (const ALongInt);
    begin
      WriteRecord(ALongInt, Sizeof(LongInt));
    end;

  procedure TAbstractFile.ReadReal      (const AReal);
    begin
      ReadRecord(AReal, Sizeof(Real));
    end;

  procedure TAbstractFile.WriteReal     (const AReal);
    begin
      WriteRecord(AReal, Sizeof(Real));
    end;

  procedure TAbstractFile.ReadSingle    (const ASingle);
    begin
      ReadRecord(ASingle, Sizeof(Single));
    end;

  procedure TAbstractFile.WriteSingle   (const ASingle);
    begin
      WriteRecord(ASingle, Sizeof(Single));
    end;

  procedure TAbstractFile.ReadDouble    (const ADouble);
    begin
      ReadRecord(ADouble, Sizeof(Double));
    end;

  procedure TAbstractFile.WriteDouble   (const ADouble);
    begin
      WriteRecord(ADouble, Sizeof(Double));
    end;

  procedure TAbstractFile.ReadComp      (const AComp);
    begin
      ReadRecord(AComp, Sizeof(Comp));
    end;

  procedure TAbstractFile.WriteComp     (const AComp);
    begin
      WriteRecord(AComp, Sizeof(Comp));
    end;

  procedure TAbstractFile.ReadExtended  (const AExtended);
    begin
      ReadRecord(AExtended, Sizeof(Extended));
    end;

  procedure TAbstractFile.WriteExtended (const AExtended);
    begin
      WriteRecord(AExtended, Sizeof(Extended));
    end;

  procedure TAbstractFile.ReadString  (const AString; AStrSize : word);
    begin
      ReadRecord(AString, Sizeof(String));
    end;

  procedure TAbstractFile.WriteString (const AString; AStrSize : word);
    begin
      WriteRecord(AString, Sizeof(String));
    end;

  function TAbstractFile.GetString : String;
    var
      Str : String;
    begin
      ReadByte(Str[0]);
      if (Flags and flError <> flError) then
        ReadRecord(Str[1], Byte(Str[0]));
      if (Flags and flError <> flError) then
        GetString := Str
      else
        GetString := '';
    end;

  procedure TAbstractFile.PutString (const AString);
    begin
      WriteRecord(AString, Length(String(AString)) + 1);
    end;

  { Text files }
  function TAbstractFile.Soln: Boolean;
    var
      Test  : word;
      Count : word;
      P     : LongInt;
    begin
      Soln := False;
      P := FilePos;
      if (Flags and flError = flError) then Exit;
      if P = 0 then
        Soln := True
      else begin
        Seek(P - 1);
        if (Flags and flError <> flError) then
          BlockRead ( Test, Sizeof(Test), Count );
        Soln := (Count = 2) and (Test = $0A0D) and (Flags and flError <> flError);
        if not (Soln or StrictLines) then
          Soln := (Count > 0) and (Flags and flError <> flError) and
            ((Lo(Test) = $0A) or (Lo(Test) = $0D));
        Seek(P);
      end;
    end;

  function TAbstractFile.EoLn: Boolean;
    var
      Test  : word;
      Count : word;
      P     : LongInt;
    begin
      EoLn := False;
      if EOF then exit;
      P := FilePos;
      if (Flags and flError = flError) then Exit;
      BlockRead ( Test, Sizeof(Test), Count );
      Eoln := (Count = 2) and (Test = $0A0D) and (Flags and flError <> flError);
      if not (Eoln or StrictLines) then
        Eoln := (Count > 0) and (Flags and flError <> flError) and
          ((Hi(Test) = $0A) or (Hi(Test) = $0D));
      Seek(P);
    end;

  function TAbstractFile.SeekSoln: Boolean;
    var
      SLn : boolean;
    begin
      SetIOResult ( erNone );
      repeat
        SLn := Soln;
        if (Flags and flError <> flError) and (Not SLn) then
          Seek(Ptr - 1);
      until SLn or (Flags and flError = flError);
      SeekSoln := Soln;
    end;

  function TAbstractFile.SeekEoln: Boolean;
    var
      EndLn, EndF : boolean;
    begin
      SetIOResult ( erNone );
      repeat
        EndLn := Eoln;
        if (Flags and flError <> flError) then EndF  := Eof;
        if (Flags and flError <> flError) and (Not EndLn) and (Not EndF) then
          Seek(Ptr + 1);
      until EndLn or EndF or (Flags and flError = flError);
      SeekEoln := Eoln;
    end;

function TAbstractFile.Read ( const AStr; AMax : word ) : Boolean;
    var
      P, T : ^String;
      Max, Count : word;
      I : integer;
      L : LongInt;
    begin
       Read := False;
       P := @AStr;
       P^[0] := #0;
       T := @Buf;
       L := FilePos;
       if Max > 250 then Max := 250;
       if (AMax > 0) and (Flags and flError <> flError) then begin
			BlockRead(Buf[1], Max + 2, Count);   { Buffer is 512, Max String is 255 }
			if (Flags and flError <> flError) then
				begin
					Buf[0] := Count;
					I := Pos(#$0A#$0D, T^);
					if (I > 0) then begin
						Buf[0] := I - 1;
						Seek(L + I + 1);
						Read := True;
		   			end else if not StrictLines then begin
                        I := Pos(#$0D, T^);
                        if (I > 0) then begin
                            Buf[0] := I - 1;
                            Seek(L + I);
    						Read := True;
                        end;
                        I := Pos(#$0A, T^);
                        if (I > 0) then begin
                            Buf[0] := I - 1;
                            Seek(L + I);
    						Read := True;
                        end;
                    end;
                    if EOF then Read := True;
                    If Buf[0] > Max then
                        Buf[0] := Max;
					P^ := T^;
				end;
		end;
    end;

  procedure TAbstractFile.Write ( const AStr );
    begin
      WriteRecord(String(AStr)[1], Length(String(AStr)));
    end;

  function TAbstractFile.ReadLn ( const AStr; AMax : word ) : boolean;
    var
      Flag : boolean;
    begin
        Flag := Read(AStr, AMax);
        ReadLn := Flag;
        if not Flag then SeekEoln;
    end;

  procedure TAbstractFile.WriteLn ( const AStr );
    const
      CRLF : word = $0A0D;
    begin
      WriteRecord(String(AStr)[1], Length(String(AStr)));
      if Flags and flError <> flError then WriteWord ( CRLF );
    end;

  function TAbstractFile.LengthLn : word;
    var
      OPtr : longInt;
      SPtr : longInt;
      EPtr : longInt;
    begin
      LengthLn := 0;
      OPtr := FilePos;
      if (Flags and flError <> flError) then SeekSoln;
      if (Flags and flError <> flError) then SPtr := FilePos;
      if (Flags and flError <> flError) then SeekEoln;
      if (Flags and flError <> flError) then EPtr := FilePos;
      if (Flags and flError <> flError) then Seek(OPtr);
      if (Flags and flError <> flError) then LengthLn := EPtr - SPtr;
    end;

  procedure TAbstractFile.InsertLn ( ALen : word );
    var
      OPtr : longInt;
    begin
      SeekSoln;
      if (Flags and flError <> flError) then OPtr := FilePos;
      if (Flags and flError <> flError) then Insert(ALen + 2);
      if (Flags and flError <> flError) then Seek(OPtr + ALen);
      if (Flags and flError <> flError) then Write(CRLF);
      if (Flags and flError <> flError) then Seek(OPtr);
    end;

  procedure TAbstractFile.DeleteLn;
    var
      OLen : word;
      OPtr : LongInt;
    begin
      SeekSoln;
      if (Flags and flError <> flError) then OPtr := FilePos;
      if (Flags and flError <> flError) then OLen := LengthLn;
      if (Flags and flError <> flError) then Delete(OLen + 2);
      if (Flags and flError <> flError) then Seek(OPtr);
    end;

  procedure TAbstractFile.ResizeLn ( ALen : word );
    var
      OLen : word;
      OPtr : LongInt;
    begin
      OLen := LengthLn;
      if (Flags and flError <> flError) then
        begin
          if OLen < ALen then
            begin
              SeekSoln;
              if (Flags and flError <> flError) then OPtr := FilePos;
              if (Flags and flError <> flError) then Seek(OPtr + OLen);
              if (Flags and flError <> flError) then Insert(ALen - OLen);
              if (Flags and flError <> flError) then SeekSoln;
            end
          else
          if OLen > ALen then
            begin
              SeekSoln;
              if (Flags and flError <> flError) then OPtr := FilePos;
              if (Flags and flError <> flError) then Seek(OPtr + ALen);
              if (Flags and flError <> flError) then Delete(OLen - ALen);
              if (Flags and flError <> flError) then Seek(OPtr);
            end
          else
            SeekSoln;
        end;
    end;

  function TAbstractFile.SeekLn ( ANumber : LongInt ) : boolean;
    var
      I : LongInt;
      S : String[1];
    begin
      SeekSof;
      for I := 1 to ANumber - 1 do
        if (Flags and flError <> flError) then
          ReadLn ( S, 0 );
      SeekLn := (Flags and flError <> flError);
    end;

{ ------------ TDiskFile ------------ }

  function TDiskFile.GetClassName : String;
  begin
    GetClassName := 'TDiskFile';
  end;

  constructor TDiskFile.Create(AOwner : PObject);
    begin
      inherited Create(AOwner);
    end;

  destructor  TDiskFile.Destroy;
    begin
      inherited Destroy;
    end;

  procedure TDiskFile.Assign( AFileName : String );
    var
      Action : byte;
    begin
      inherited Assign(AFileName);
      if (Flags and flError <> flError) then
        begin
          repeat
            System.Assign(FRec, AFileName);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
          if (Action <> fcAbort) then
            Flags := Flags or flAssigned;
        end;
    end;

  procedure TDiskFile.BlockRead(const ABuf; ACount: Word; var AResult: Word);
    var
      P : Pointer;
      Action : byte;
    begin
      inherited BlockRead(ABuf, ACount, AResult);
      if (Flags and flError <> flError) then
        begin
          repeat
            P := @ABuf;
            System.BlockRead(FRec, P^, ACount, AResult);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
          if (Action <> fcAbort) then Inc(Ptr, AResult)
        end;
    end;

  procedure TDiskFile.BlockWrite(const ABuf; ACount: Word; var AResult: Word);
    var
      P : Pointer;
      Action : byte;
    begin
      inherited BlockWrite(ABuf, ACount, AResult);
      if (Flags and flError <> flError) then
        begin
          Flags := Flags or flModified;
          repeat
            P := @ABuf;
            System.BlockWrite(FRec, P^, ACount, AResult);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
          if (Action <> fcAbort) then Inc(Ptr, AResult);
        end;
    end;

  procedure TDiskFile.Close;
    var
      Action : byte;
    begin
      inherited Close;
      if (Flags and flError <> flError) then
        begin
          repeat
            System.Close(FRec);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
          if (Action <> fcAbort) then
            Flags := Flags and (Not flOpened);
          if (Action <> fcAbort) then Ptr := 0;
          Flags := Flags and (not flModified);
        end;
    end;

  procedure TDiskFile.Erase;
    var
      Action : byte;
    begin
      inherited Erase;
      if (Flags and flError <> flError) then
        begin
          repeat
            System.Erase(FRec);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
        end;
    end;

  function TDiskFile.FileSize: Longint;
    var
      Action : byte;
    begin
      inherited FileSize;
      if (Flags and flError <> flError) then
        begin
          repeat
            FileSize := System.FileSize(FRec);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
        end;
    end;

  procedure TDiskFile.Flush;
    begin
      inherited Flush;
      if (Flags and flError <> flError) then
        begin
          Flags := Flags and (Not flFlush);
        end;
    end;


  procedure TDiskFile.Rename( ANewName : String );
    var
      Action : byte;
    begin
      inherited Rename(ANewName);
      if (Flags and flError <> flError) then
        begin
          repeat
            System.Rename(FRec, ANewName);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
          if (Action <> fcAbort) then
            Name := ANewName;
        end;
    end;

  procedure TDiskFile.Reset;
    var
      Action : byte;
    begin
      inherited Reset;
      if (Flags and flError <> flError) then
        begin
          repeat
            System.Reset(FRec, 1);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
          if (Action <> fcAbort) then
            Flags := Flags or flOpened;
          if (Action <> fcAbort) then Ptr := 0;
        end;
    end;

  procedure TDiskFile.Rewrite;
    var
      Action : byte;
    begin
      inherited Rewrite;
      if (Flags and flError <> flError) then
        begin
          repeat
            System.Rewrite(FRec, 1);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
          if (Action <> fcAbort) then
            Flags := Flags or flOpened;
          if (Action <> fcAbort) then Ptr := 0;
          Flags := Flags or flModified;
        end;
    end;

  procedure TDiskFile.Seek(AFilePos: Longint);
    var
      Action : byte;
    begin
      inherited Seek(AFilePos);
      if (Flags and flError <> flError) then
        begin
          repeat
            System.Seek(FRec, AFilePos);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
          if (Action <> fcAbort) then
            Flags := Flags or flOpened;
          if (Action <> fcAbort) then Ptr := AFilePos;
        end;
    end;

  procedure TDiskFile.Truncate;
    var
      Action : byte;
    begin
      inherited Truncate;
      if (Flags and flError <> flError) then
        begin
          repeat
            System.Truncate(FRec);
            Action := SetIOResult(System.IOResult);
          until (Action <> fcRetry);
          if (Action <> fcAbort) then
            Flags := Flags or flOpened;
          Flags := Flags or flModified;
        end;
    end;

  function TDiskFile.GetName : String;
    var
      I : word;
      S : String;
    begin
      S := '';
      for I := 0 to 79 do
        if TFileRec(FRec).Name[I] = #0 then
          Break
        else
          S := S + (TFileRec(FRec).Name[I]);
      GetName := S;
    end;

function NewAbstractFile(AOwner:PObject) : PObject;
begin
    NewAbstractFile := New(PAbstractFile, Create(AOwner));
end;

function NewDiskFile(AOwner:PObject) : PObject;
begin
    NewDiskFile := New(PDiskFile, Create(AOwner));
end;

{ initialization & finalization routines }

begin
    RegisterObject('TAbstractFile', NewAbstractFile);
    RegisterObject('TDiskFile', NewDiskFile);
end.
