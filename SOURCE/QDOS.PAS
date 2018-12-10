{ Copyright 1990-2018 Jerome Shidel }

(*

	This project and related files are subject to either the terms
	specified in the included LICENSE.TXT file or the GNU GPLv2.0.

*)

unit QDos; { QuickCrt Dos Tools }
{$I QCRT.DEF}

{$DEFINE DOS500}
{$DEFINE DOS400}
{$DEFINE DOS330}
{$DEFINE DOS320}
{$DEFINE DOS310}
{$DEFINE DOS300}
{$DEFINE DOS200}

interface

  const
  { Dos version required for unit functions }
	Dos200 = $0002;
	Dos300 = $0003;
	Dos310 = $0A03;
	Dos320 = $1403;
	Dos330 = $1E03;
	Dos400 = $0004;
	Dos500 = $0005;
	DosXXX = $FFFF;
	ReqDosVersion =
	  {$IFDEF Dos400} Dos400; {$ELSE}
	  {$IFDEF Dos330} Dos330; {$ELSE}
	  {$IFDEF Dos320} Dos320; {$ELSE}
	  {$IFDEF Dos310} Dos310; {$ELSE}
	  {$IFDEF Dos300} Dos300; {$ELSE}
	  {$IFDEF Dos200} Dos200; {$ELSE}
	  Dos500;
	  {$ENDIF} {$ENDIF} {$ENDIF} {$ENDIF} {$ENDIF} {$ENDIF}

  { Disk drive constants }
	drDefault = 0;
	drCurrent = drDefault;
	drA = 1;  drB = 2;	drC = 3;  drD = 4;	drE = 5;  drF = 6;	drG = 7;

  { Offset for DOS Date Time Functions }
	DosYear = 1980;

  { File and Path Delimiter }
    Delimiter = '\';

  { File attributes constants }
	faReadOnly	 = $01;
	faHidden	 = $02;
	faSystem	 = $04;
	faVolumeID	 = $08;
	faDirectory	 = $10;
	faArchive	 = $20;
	faAnyFile	 = $3F;

  type
	{Typed and untyped files}
	TFileRec = record
	  Handle: Word;
	  Mode: Word;
	  RecSize: Word;
	  Private: array[1..26] of Byte;
	  UserData: array[1..16] of Byte;
	  Name: array[0..79] of Char;
	end;

  {Textfile record}
	PTextBuf = ^TTextBuf;
	TTextBuf = array[0..127] of Char;
	TTextRec = record
	  Handle: Word;
	  Mode: Word;
	  BufSize: Word;
	  Private: Word;
	  BufPos: Word;
	  BufEnd: Word;
	  BufPtr: PTextBuf;
	  OpenFunc: Pointer;
	  InOutFunc: Pointer;
	  FlushFunc: Pointer;
	  CloseFunc: Pointer;
	  UserData: array[1..16] of Byte;
	  Name: array[0..79] of Char;
	  Buffer: TTextBuf;
	end;

	PSearchRec = ^TSearchRec;
	TSearchRec = record
		Reserved : array[0..20] of byte;
		Attr : byte;
		Time : LongInt;
		Size : LongInt;
		Name : String[12];
	end;

	PDateTime = ^TDateTime;
	TDateTime = record
		Year,
		Month,
		Day,
		Hour,
		Min,
		Sec : Word;
	end;

	{ Program Segment Prefix Block }
	PPSPBlock = ^TPSPBlock;
	TPSPBlock = record
	  Int20:			   word;
	  MemTop:			   word;
	  DosReservedArea01:   byte;
	  DosDispatcher:	   byte; {if not com then Segavail and #2 belong}
	  SegAvail:			   word; {to DosDispatcher }
	  DosDispatcher2:	   word;
	  TerminateAddress:	   pointer;
	  ControlBreak:		   pointer;
	  CriticalError:	   pointer;
	  DosReservedArea02:   array[0..21] of byte;
	  EnvSeg:			   word;
	  DosReservedArea03:   array[0..45] of byte;
	  FormatedParamArea01: array[0..15] of byte;
	  FormatedParamArea02: array[0..19] of byte;
	  Params:			   string[127];
	end;

	PParamBlock = ^TParamBlock;
	TParamBlock = record
		EnvSeg : word;
		CmdLn : pointer;
		FCB1, FCB2 : pointer;
		Params : String;
	end;

  var
	DosError : integer;

  function	DosVersion : word;
  function	DosVersionStr ( AVersion : word ) : string;

  { Redirection }
  function IsRedirectedInput : boolean;
  function IsRedirectedOutput : boolean;

  { Character I/O }
  function StdInReady : boolean;
  function StdInChr : char;
  procedure StdOutChr( AChr : char );
  function StdInOutChr : char;
  procedure StdOutStr( const Adr );
  function StdAuxInChar : char;
  procedure StdAuxOutChr( AChr : char );
  procedure StdPrnOutChr( AChr : char );

  { Handle oriented I/O }
  procedure GetFAttr(var F; var Attr: Word);
  procedure SetFAttr(var F; Attr: Word);
  procedure GetFTime(var F; var Time : LongInt);
  procedure SetFTime(var F; Time : LongInt);

  { Date/Time }
  procedure GetDate(var Year, Month, Day{$IFDEF DOS300}, DayOfWeek{$ENDIF}: Word);
  function SetDate(Year, Month, Day: Word) : boolean;
  procedure GetTime(var Hour, Minute, Second, Sec100: Word);
  function SetTime(Hour, Minute, Second, Sec100: Word) : boolean;

  { Disk functions }
  { If a files size has changed it should be closed before flush. }
  procedure FlushAllFileBuffers;
  function GetCurDisk : byte;
  procedure SetCurDisk ( ADrive: byte );
{$IFDEF Dos400}
  function BootDrive : byte;
{$ENDIF}
{$IFDEF Dos300}
  function LastDrive : byte;
{$ENDIF}
  function Diskettes : byte; { BiosFn }
{$IFDEF Dos300}
  function IsValidDrive ( ADrive : byte ) : boolean;
  function IsRemovable ( ADrive : byte ) : boolean;
{$ENDIF}
{$IFDEF Dos310}
  function IsRemote ( ADrive : byte ) : boolean;
{$ENDIF}
  function IsCDROM ( ADrive : byte ) : boolean;
{$IFDEF Dos320}
  function GetLogical ( ADrive : byte ) : byte;
  function SetLogical ( ADrive : byte ) : byte;
{$ENDIF}
{$IFDEF Dos400}
  function GetDiskSerial(ADrive: byte) : longInt;
  procedure SetDiskSerial(ADrive: byte; ASerial : longInt);
{$ENDIF}
  function GetDeviceInfoWord(Handle : word) : word;
  function DiskFatID( ADrive: byte ) : byte;
  function DiskClusters( ADrive: byte ) : word;
  function DiskSectors( ADrive: byte ) : byte;
  function DiskSectorSize( ADrive: byte ) : word;
  function DiskSize( ADrive: byte ) : longint;
  function DiskFree( ADrive: byte ) : longint;
  procedure SetVerify(Verify: Boolean);

  { Dos Ctrl-Break checking level }
  function GetBreak : boolean;
  procedure SetBreak ( Break : boolean );

  { Interrupts }
  procedure GetIntVec(IntNo: Byte; var Vector: Pointer);
  procedure SetIntVec(IntNo: Byte; Vector: Pointer);

  { Execute Programs }
  procedure SwapIntVecs;
  procedure Exec(Command, Params : String);

  { Directory Stuff}
  procedure FindFirst(PathName : String; Attr : Word; var SearchRec : TSearchRec );
  procedure FindNext(var SearchRec : TSearchRec);

  { Other Functions }
  function PathOf(AFileName : String) : String;

  function GetExeName : string;
  function GetExeBase : string;
  function GetExePath : string;
  function DriveLetters : string;

  { Expands a file or dir name to full path }
  function FileExpand(AFileName : String) : String;
  function FilePath(AFileName : String) : String;
  function FileExtension(AFileName : String) : String;

  { Returns 0, if the dir exists or was able to be created. Or
  non-zero error code }
  function MakeDir ( ADir : String ) : integer;

  { Uses FindFirst to test if File/Dir Exists }
  function FileExists ( AFileName : String ) : boolean;
  function DirExists ( AFileName : String ) : boolean;
  function Exists ( AFileName : String ) : boolean;

  function Dir(ADirName : String) : String;

  function GetEnv(AKey : String): String;
  function GetEnvCount: integer;
  function GetEnvParam(AIndex : integer): String;

  procedure PackTime(DateTime : TDateTime; var Value : LongInt);
  procedure UnPackTime(Value : LongInt; var DateTime : TDateTime);

  function NoTailDelim(APath : String) : String;
  function TailDelim(APath : String) : String;

  function GetLanguage : String;
  function SwitchChar : char;

implementation

uses QStrings;

  const
	erNone = 0;
	erInvalid_Drive_Number = 15;
  { uses QErrors; }

  function DosVersion : word; assembler;
	asm
	  MOV  AH, 30h
	  INT  21h
	end;

  function DosVersionStr ( AVersion : word ) : String;
	var
	  Major, Minor : String[2];
	  OEM : String;
	begin
	  OEM := 'DOS';
	  case Hi(AVersion) of
		0..$FF : begin
		  Str ( Lo(AVersion), Major );
		  Str ( Hi(AVersion), Minor );
		  while Length(Minor) < 2 do Minor := '0' + Minor;
		end;
	  else
		Major := 'X';
		Minor := 'xx';
	  end;
	  DosVersionStr := OEM + ' ' + Major + '.' + Minor;
	end;

  { Redirection }
  function GetDeviceInfoWord(Handle : word) : word; assembler;
	asm
	  MOV  AX, 4400h
	  MOV  BX, Handle
	  INT  21h
	  JNC  @OK
	  XOR  DX, DX
	  JMP  @Done
	@OK:
	  XOR  AX, AX
	@Done:
	  MOV  DosError, AX
	  MOV  AX, DX
	end;

  function IsRedirectedInput : boolean;
	begin
	  IsRedirectedInput	 := (GetDeviceInfoWord(0) and $80 <> $80) and (DosError = 0);
	end;

  function IsRedirectedOutput : boolean;
	begin
	  IsRedirectedOutput := (GetDeviceInfoWord(1) and $80 <> $80) and (DosError = 0);
	end;



  { Character I/O }
  function StdInReady : boolean; assembler;
  { Returns True if character is ready }
	asm
	  MOV  AH, 0Bh
	  INT  21h
	  MOV  CL, False
	  CMP  AL, 0
	  JE   @1
	  MOV  CL, True
	@1:
	  MOV  AL, CL
	end;

  function StdInChr : char; assembler;
  { Reads (waits for) character }
	asm
	  MOV  AH, 08h
	  INT  21h
	end;

  procedure StdOutChr( AChr : char ); assembler;
	asm
	  MOV  AH, 02h
	  MOV  DL, AChr
	  INT  21h
	end;

  function StdInOutChr : char; assembler;
  { Reads (waits for) character }
	asm
	  MOV  AH, 01h
	  INT  21h
	end;

  procedure StdOutStr( const Adr ); assembler;
  { String must end with '$' }
	asm
	  PUSH DS
	  MOV  AH, 09h
	  LDS  DX, Adr
	  INT  21h
	  POP  DS
	end;

  function StdAuxInChar : char; assembler;
  { Reads (waits for) character }
	asm
	  MOV  AH, 03h
	  INT  21h
	end;

  procedure StdAuxOutChr( AChr : char ); assembler;
	asm
	  MOV  AH, 04h
	  MOV  DL, AChr
	  INT  21h
	end;

  procedure StdPrnOutChr( AChr : char ); assembler;
	asm
	  MOV  AH, 05h
	  MOV  DL, AChr
	  INT  21h
	end;

  { Handle oriented I/O }
  procedure GetFAttr(var F; var Attr: Word); assembler;
	asm
	  PUSH DS
	  MOV  AX, 4300h
	  LDS  DX, F
	  ADD  DX, OFFSET TFileRec.Name
	  INT  21h
	  POP  DS
	  JC   @1
	  XOR  AX, AX
	@1:
	  MOV  DosError, AX
	  LES  DI, Attr
	  MOV  ES:[DI], CX
	end;

  procedure SetFAttr(var F; Attr: Word); assembler;
	asm
	  PUSH DS
	  MOV  AX, 4301h
	  MOV  CX, Attr
	  LDS  DX, F
	  ADD  DX, OFFSET TFileRec.Name
	  INT  21h
	  POP  DS
	  JC   @1
	  XOR  AX, AX
	@1:
	  MOV  DosError, AX
	end;

  procedure GetFTime(var F; var Time : LongInt); assembler;
	asm
	  PUSH DS
	  MOV  AX, 5700h
	  LDS  BX, F
	  MOV  BX, DS:[BX]
	  INT  21h
	  POP  DS
	  JC   @1
	  XOR  AX, AX
	@1:
	  MOV  DosError, AX
	  LES  DI, Time
	  MOV  ES:[DI], CX
	  MOV  ES:[DI + 2], DX
	end;

  procedure SetFTime(var F; Time : LongInt); assembler;
	asm
	  PUSH DS
	  MOV  AX, 5701h
	  LES  DI, Time
	  MOV  CX, ES:[DI]
	  MOV  DX, ES:[DI + 2]
	  LDS  BX, F
	  MOV  BX, DS:[BX]
	  INT  21h
	  POP  DS
	  JC   @1
	  XOR  AX, AX
	@1:
	  MOV  DosError, AX
	end;

  { Date/Time }
  procedure GetDate(var Year, Month, Day {$IFDEF Dos300}, DayOfWeek {$ENDIF}: Word); assembler;
	asm
	  MOV  AH, 2Ah
	  INT  21h
	  LES  DI, Year
	  MOV  ES:[DI], CX
	  XOR  AH, AH
	  {$IFDEF Dos300}
	  LES  DI, DayOfWeek
	  STOSW
	  {$ENDIF}
	  LES  DI, Month
	  MOV  AL, DH
	  STOSW
	  LES  DI, Day
	  MOV  AL, DL
	  STOSW
	end;

  function SetDate(Year, Month, Day: Word) : boolean; assembler;
	asm
	  MOV  CX, Year
	  MOV  AX, Month
	  MOV  DX, Day
	  MOV  DH, AL
	  MOV  AH, 2Bh
	  INT  21h
	  MOV  CL, True
	  CMP  AL, 0
	  JE   @1
	  MOV  CL, False
	@1:
	  MOV  AL, CL
	end;

  procedure GetTime(var Hour, Minute, Second, Sec100: Word); assembler;
	asm
	  MOV  AH, 2Ch
	  INT  21h
	  XOR  AH, AH
	  MOV  AL, CH
	  LES  DI, Hour
	  STOSW
	  MOV  AL, CL
	  LES  DI, Minute
	  STOSW
	  MOV  AL, DH
	  LES  DI, Second
	  STOSW
	  MOV  AL, DL
	  LES  DI, Sec100
	  STOSW
	end;

  function SetTime(Hour, Minute, Second, Sec100: Word) : boolean; assembler;
	asm
	  MOV  AX, Hour
	  MOV  CH, AL
	  MOV  AX, Minute
	  MOV  CL, AL
	  MOV  AX, Second
	  MOV  DH, AL
	  MOV  AX, Sec100
	  MOV  DL, AL
	  MOV  AH, 2Dh
	  INT  21h
	  MOV  CL, True
	  CMP  AL, 0
	  JE   @1
	  MOV  CL, False
	@1:
	  MOV  AL, CL
	end;


  { Disk functions }
  procedure FlushAllFileBuffers; assembler;
  { if a files size has changed it should be closed First }
	asm
	  MOV  AH, 0Dh
	  INT  21h
	end;

  function GetCurDisk : byte; assembler;
	asm
	  MOV  AH, 19h
	  INT  21h
	  INC  AL
	end;

  procedure SetCurDisk ( ADrive : byte ); assembler;
	asm
	  MOV  DL, ADrive
	  CMP  DL, drDefault
	  JNE  @1
	  MOV  AH, 0Eh
	  DEC  DL
	  INT  21h
	@1:
	end;

{$IFDEF Dos400}
  function BootDrive : byte; assembler;
	asm
	  MOV  AX, 3305h
	  INT  21h
	  MOV  AL, DL
	end;
{$ENDIF}
{$IFDEF Dos300}
  function LastDrive : byte; assembler;
	asm
	  MOV  AH, 19h
	  INT  21h
	  MOV  DL, AL
	  MOV  AH, 0Eh
	  INT  21h
	end;
{$ENDIF}
  function Diskettes : byte; assembler;
	asm
	  INT  11h
	  TEST AL, 01h
	  JZ   @@NoDrives
	  XOR  AH, AH
	  AND  AL, 0C0h
	  MOV  CL, 06h
	  SHR  AX, CL
	  INC  AX
	  JMP  @@Done
	@@NoDrives:
	  XOR  AX, AX
	@@Done:
	end;


{$IFDEF Dos300}
  function IsValidDrive ( ADrive : byte ) : boolean; assembler;
	asm
	  MOV  DosError, erInvalid_Drive_Number
	  MOV  AX, 4408h
	  MOV  BL, ADrive
	  INT  21h
	  MOV  CL, False
	  CMP  AX, 01h
	  JG   @@NotValid
	  MOV  DosError, erNone
	  MOV  CL, True
	@@NotValid:
	  MOV  AL, CL
	end;

  function IsRemovable ( ADrive : byte ) : boolean; assembler;
	asm
	  MOV  AX, 4408h
	  MOV  BL, ADrive
	  INT  21h
	  MOV  CL, False
	  CMP  AX, 0
	  JNE  @@SetRemovable
	  MOV  CL, True
	@@SetRemovable:
	  CMP  AX, 1
	  JG   @@Error
	  XOR  AX, AX
	@@Error:
	  MOV  DosError, AX
	  MOV  AL, CL
	end;
{$ENDIF}
{$IFDEF Dos310}
  function IsRemote ( ADrive : byte ) : Boolean; assembler;
	asm
	  MOV  AX, 4409h
	  MOV  BL, ADrive
	  INT  21h
	  MOV  CL, False
	  TEST DX, 1000h
	  JZ   @@SetRemote
	  MOV  CL, True
	@@SetRemote:
	  MOV  AL, CL
	  MOV  DosError, erNone
	end;
{$ENDIF}

  function IsCDROM ( ADrive : byte ) : boolean; assembler;
	asm
	  MOV  DosError, erNone
	  MOV  AX, 1500h
	  XOR  BX, BX
	  INT  2Fh
	  MOV  DL, False
	  CMP  BX, 0
	  JE   @@Done { CDROM Multiplex not installed }
	  XOR  AH, AH
	  MOV  AL, ADrive
	  INC  CX
	  DEC  BX
	  CMP  AX, CX
	  JL   @@Done { Less then First CD }
	  ADD  CX, BX
	  CMP  AX, CX
	  JG   @@Done { Greater then Last CD }
	  MOV  DL, True
	@@Done:
	  MOV  AL, DL
	end;

{$IFDEF Dos320}
  function GetLogical ( ADrive : byte ) : byte; assembler;
	asm
	  MOV  AX, 440Eh
	  MOV  BL, ADrive
	  INT  21h
	  JC   @@Error
	  CMP  AL, 00h
	  JNE  @@ReturnDrive
	  MOV  AX, 000Fh { invalid drive number }
	@@Error:
	  XOR  CL, CL
	  JMP  @@Done
	@@ReturnDrive:
	  MOV  CL, AL
	  XOR  AX, AX
	@@Done:
	  MOV  DosError, AX
	  MOV  AL, CL
	end;

  function SetLogical ( ADrive : byte ) : byte; assembler;
	asm
	  MOV  AX, 440Fh
	  MOV  BL, ADrive
	  INT  21h
	  JC   @@Error
	  CMP  AL, 00h
	  JNE  @@ReturnDrive
	  MOV  AX, 000Fh { invalid drive number }
	@@Error:
	  XOR  CL, CL
	  JMP  @@Done
	@@ReturnDrive:
	  MOV  CL, AL
	  XOR  AX, AX
	@@Done:
	  MOV  DosError, AX
	  MOV  AL, CL
	end;
{$ENDIF}
  type
	InfoBuffer = record
	  InfoLevel	 : word; {should be zero}
	  Serial	 : LongInt;
	  VolLabel	 : array [0..10] of char;
	  FileSystem : array [0..7] of char;
	end;

  function GetInfoBuffer(ADrive: Byte; var Buf : InfoBuffer ): integer; assembler;
	asm
	  MOV  AH, 69h
	  MOV  AL, 00h
	  MOV  BL, ADrive
	  PUSH DS
	  LDS  DX, Buf
	  INT  21h
	  POP  DS
	  JC   @@Error
	  XOR  AX, AX
	@@Error:
	end;

  function SetInfoBuffer(ADrive: Byte; var Buf : InfoBuffer) : integer; assembler;
	asm
	  MOV  AH, 69h
	  MOV  AL, 01h
	  MOV  BL, ADrive
	  PUSH DS
	  LDS  DX, Buf
	  INT  21h
	  POP  DS
	  JC   @@Error
	  XOR  AX, AX
	@@Error:
	end;

  function GetDiskSerial(ADrive: byte) : longInt;
	var
	  TBuf : InfoBuffer;
	begin
	  DosError := GetInfoBuffer( ADrive, TBuf );
	  GetDiskSerial := TBuf.Serial;
	end;

  procedure SetDiskSerial(ADrive: byte; ASerial : LongInt);
	var
	  TBuf	 : InfoBuffer;
	begin
	  GetInfoBuffer( ADrive, TBuf );
	  TBuf.Serial := ASerial;
	  if DosError = erNone then
		DosError := SetInfoBuffer ( ADrive, TBuf );
	end;

  function DiskFatID( ADrive: byte ) : byte; assembler;
	asm
	  PUSH DS
	  MOV  AH, 1Ch
	  MOV  DL, ADrive
	  INT  21h
	  MOV  AL, [BX]
	  POP  DS
	end;

  function DiskClusters( ADrive: byte ) : word; assembler;
	asm
	  PUSH DS
	  MOV  AH, 1Ch
	  MOV  DL, ADrive
	  INT  21h
	  MOV  AX, DX
	  POP  DS
	end;

  function DiskSectors( ADrive: byte ) : byte; assembler;
	asm
	  PUSH DS
	  MOV  AH, 1Ch
	  MOV  DL, ADrive
	  INT  21h
	  POP  DS
	end;


  function DiskSectorSize( ADrive: byte ) : word; assembler;
	asm
	  PUSH DS
	  MOV  AH, 1Ch
	  MOV  DL, ADrive
	  INT  21h
	  MOV  AX, CX
	  POP  DS
	end;

  function DiskSize( ADrive: byte ) : longint; assembler;
	asm
	  PUSH DS
	  MOV  AH, 36h
	  MOV  DL, ADrive
	  INT  21h
	  CMP  AX, 0FFFFh
	  JE   @1
	  MOV  BX, DX
	  MUL  CX
	  MUL  BX
	  JMP  @2
	@1:
	  MOV  DX, -1
	@2:
	  POP  DS
	end;

  function DiskFree( ADrive: byte ) : longint; assembler;
	asm
	  PUSH DS
	  MOV  AH, 36h
	  MOV  DL, ADrive
	  INT  21h
	  CMP  AX, 0FFFFh
	  JE   @1
	  MUL  CX
	  MUL  BX
	  JMP  @2
	@1:
	  MOV  DX, -1
	@2:
	  POP  DS
	end;

  procedure SetVerify(Verify: Boolean); assembler;
	asm
	  MOV  AH, 2Eh
	  MOV  AL, 0
	  MOV  CL, Verify
	  CMP  CL, False
	  JE   @1
	  MOV  AL, 1
	@1:
	  INT  21h
	end;

  function GetBreak : boolean; assembler;
	asm
	  MOV  AX, 3300h
	  INT  21h
	  MOV  AL, True
	  CMP  DL, 1
	  JE   @1
	  MOV  AL, False
	@1:
	end;

  procedure SetBreak ( Break : boolean ); assembler;
	asm
	  MOV  AX, 3301h
	  MOV  DL, 1
	  MOV  CL, Break
	  CMP  CL, True
	  JE   @1
	  MOV  DL, 0
	@1:
	  INT  21h
	end;
  { Interrupts }
  procedure SetIntVec(IntNo: Byte; Vector: Pointer); assembler;
	asm
	  PUSH DS
	  MOV  AH, 25h
	  MOV  AL, IntNo
	  LDS  DX, Vector
	  INT  21h
	  POP  DS
	end;

  procedure GetIntVec(IntNo: Byte; var Vector: Pointer); assembler;
	asm
	  MOV  AH, 35h
	  MOV  AL, IntNo
	  INT  21h
	  MOV  AX, ES
	  LES  DI, Vector
	  MOV  ES:[DI], BX
	  MOV  ES:[DI + 2], AX
	end;

  const
	IntVecTable : array [0..19] of byte = (
		$00, $02, $09, $1B, $21, $23, $24, $34, $35, $36,
		$37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $75
	);

  var
	SavedIntVec : array [Low(IntVecTable)..High(IntVecTable)] of pointer;

  { Execute Programs }
  procedure SaveIntVecs;
  var
	Index : integer;
  begin
	for Index := low(IntVecTable) to high(IntVecTable) do
		GetIntVec(IntVecTable[Index], SavedIntVec[Index]);
  end;

  procedure SwapIntVecs;
  var
	Index : integer;
	Temp : pointer;
  begin
	for Index := low(IntVecTable) to high(IntVecTable) do
		begin
			GetIntVec(IntVecTable[Index], Temp);
			if Temp <> SavedIntVec[Index] then
				begin
					SetIntVec(IntVecTable[Index], SavedIntVec[Index]);
					SavedIntVec[Index] := Temp;
				end;
		end;
  end;


  procedure DoExec(AFunc : Byte; const Command, Params); assembler;
  asm
	{ Save Registers }
	PUSH SI
	PUSH DI
	PUSH ES
	PUSH DS

	{ Save SS:SP }
	MOV DI, OFFSET @@SaveRegs
	MOV CS:[DI], SP
	MOV CS:[DI+2], SS

	MOV AL, AFunc
	LES BX, DWORD PTR Params
	LDS DX, DWORD PTR Command
	INC DX

	MOV AH, $4B
	INT 21h
	JC @@Returned
	MOV AX, BX
	JMP @@NoError
@@SaveRegs:
	DD 0h
@@NoError:
	XOR	 AX, AX
@@Returned:
	{ Restore SS:SP }
	MOV DI, OFFSET @@SaveRegs
	MOV SP, CS:[DI]
	MOV SS, CS:[DI+2]

	{ Restore Registers }
	POP	 DS
	POP	 ES
	POP	 DI
	POP	 SI
	MOV	 DosError, AX
	XOR	 AX, AX
  end;

  procedure Exec(Command, Params : String);
  var
   P : TParamBlock;
  begin
	if Length(Command) > 254 then
		Command[Length(Command)] := #0
	else
		Command := Command + #0;
	P.FCB1 := nil;
	P.FCB2 := nil;
	P.EnvSeg := 0;
	P.CmdLn := @P.Params;
	P.Params := Params + #$0d + #0;
	DoExec ($00, Command, P); { Load and Exec }
	(*
	DoExec ($03, Command[1], PSP); { Load Only }
	DoExec ($04, Command[1], PSP); { Load and Spawn }
	*)
  end;


  { Directory Stuff}
  procedure FindFirst(PathName : String; Attr : Word; var SearchRec : TSearchRec );
  begin
	PathName := PathName + #0;
	asm
		MOV		AH, 1Ah
		PUSH	DS
		LDS		DX, SearchRec
		INT		21h
		POP		DS
		MOV		CX, attr
		PUSH	DS
		LEA		DX, PathName
		INC		DX
		PUSH	ES
		POP		DS
		MOV		AH, 4Eh
		INT		21h
		JC		@NotFound
		POP		DS

		{ Make into Pascal String }
		MOV		CX, 12
		MOV		AH, CL
		LES		DI, SearchRec
		ADD		DI, 30 + 12
	@Looped:
		CMP		CL, 0
		JE		@SetLen
		MOV		AL, ES:[DI - 1]
		MOV		ES:[DI], AL
		DEC		CL
		DEC		DI
		CMP		AL, 0
		JNE		@Looped
		MOV		AH, CL
		JMP		@Looped
	@SetLen:
		LES		DI, SearchRec
		MOV		ES:[DI + 30], AH
		MOV		DosError, 0
		JMP		@Done
	@NotFound:
		XOR		AL, AL
		LES		DI, SearchRec
		MOV		ES:[DI + 30], AL
		POP		DS
		MOV		DosError, 12h
	@Done:
	end;
  end;

  procedure FindNext(var SearchRec : TSearchRec);
  begin
	asm
		MOV		AH, 4Fh
		PUSH	DS
		LDS		DX, SearchRec
		INT		21h
		JC		@NotFound
		POP		DS

		{ Make into Pascal String }
		MOV		CX, 12
		MOV		AH, CL
		LES		DI, SearchRec
		ADD		DI, 30 + 12
	@Looped:
		CMP		CL, 0
		JE		@SetLen
		MOV		AL, ES:[DI - 1]
		MOV		ES:[DI], AL
		DEC		CL
		DEC		DI
		CMP		AL, 0
		JNE		@Looped
		MOV		AH, CL
		JMP		@Looped
	@SetLen:
		LES		DI, SearchRec
		MOV		ES:[DI + 30], AH
		MOV		DosError, 0
		JMP		@Done
	@NotFound:
		XOR		AL, AL
		LES		DI, SearchRec
		MOV		ES:[DI + 30], AL
		POP		DS
		MOV		DosError, 12h
	@Done:
	end;
  end;

  { Other Functions }
  function PathOf(AFileName : String) : String;
  begin
	PathOf := Trim(UCase(Copy(AFileName, 1, LastPos(Delimiter, AFileName))));
  end;

  function GetExeName : string;
  var
	P : integer;
  begin
	P:= LastPos(Delimiter, ParamStr(0));
	if P = 0 then
		GetEXEName := ''
	else
		GetExeName := Copy(ParamStr(0), P + 1, Length(ParamStr(0)) - P);
  end;

  function GetExeBase : string;
  var
	T : String;
	P : integer;
  begin
	T := GetExeName;
	P := LastPos('.', T);
	if P = 0 then
		GetExeBase := ''
	else
		GetExeBase := Copy(T, 1, P - 1);
  end;

  function GetExePath : string;
  begin
	GetExePath := Copy(ParamStr(0), 1, LastPos(Delimiter, ParamStr(0)));
  end;

  function FileExpand(AFileName : String) : String;
  var
	Temp, S : String;
	I : integer;
  begin
	if AFileName = '' then begin
		GetDir(0, AFileName);
	end else begin
		if (AFileName[1] = Delimiter) then begin
			AFileName := Chr(GetCurDisk + 64) + ':' + AFileName;
		end else
		if (Length(AFileName) > 2) and (AFileName[2] <> ':') then begin
			GetDir(0, Temp);
			AFileName := TailDelim(Temp) + AFileName;
		end else
		if ((Length(AFileName) > 3) and (AFileName[3] <> Delimiter)) or
		((Length(AFileName) = 2) and (AFileName[2] = ':')) then begin
			Temp := UCase(AFileName[1]);
			GetDir(Ord(Temp[1]) - 64, Temp);
			AFileName := TailDelim(Temp) + Copy(AFileName, 3, Length(AFileName));
		end;
		Temp := UCase(AFileName);
		AFileName := '';
		while Temp <> '' do begin
			I := Pos(Delimiter, Temp);
			if I > 0 then begin
				S := Copy(Temp, 1, I - 1);
				Temp := Copy(Temp, I + 1, Length(Temp));
			end else begin
				S := Temp;
				Temp := '';
			end;
			if S = '.' then begin
				{ ignore }
			end else
			if S = '..' then begin
				I := LastPos(Delimiter, AFileName);
				if (I > 0) then
					AFileName := Copy(AFileName, 1, I - 1);
			end else
			if Length(AFileName) > 0 then
				AFileName := TailDelim(AFileName) + S
			else
				AFileName := S;
		end;
	  end;
	FileExpand := AFileName;
  end;

  function Exists ( AFileName : String ) : boolean;
  var
	Search : TSearchRec;
  begin
{	FindFirst(FileExpand(AFileName), faAnyFile, Search); }
	FindFirst(AFileName, faAnyFile, Search);
	Exists := (DosError = 0);
  end;

  function FileExists ( AFileName : String ) : boolean;
  var
	Search : TSearchRec;
  begin
{	FindFirst(FileExpand(AFileName), faAnyFile, Search);}
	FindFirst(FileExpand(AFileName), faAnyFile, Search);
	FileExists := (DosError = 0) and (Search.Attr and faDirectory <> faDirectory);
  end;

  function DirExists ( AFileName : String ) : boolean;
  var
	Search : TSearchRec;
  begin
{    FindFirst(Dir(AFileName) + '*.*', faAnyFile, Search); }
    FindFirst(TailDelim(AFileName) + '*.*', faAnyFile, Search);
	DirExists := (DosError = 0) and (Search.Attr and faDirectory = faDirectory);
  end;

  function MakeDir(ADir : String) : integer;
  var
	Work, S : String;
	I : Integer;
  begin
	MakeDir := erNone;
	ADir := Dir(ADir);
	Work := '';
	while ADir <> '' do begin
		I := Pos(Delimiter, ADir);
		if I > 0 then begin
			S := Copy(ADir, 1, I - 1);
			ADir := Copy(ADir, I + 1, Length(ADir));
		end else begin
			S := ADir;
			ADir := '';
		end;
		If Length(Work) > 0 then
			Work := Work + Delimiter + S
		else
			Work := S;
		if Not DirExists(Work) then begin
			MkDir(Work);
			I := IOResult;
			if I <> 0 then begin
				MakeDir := I;
				Exit;
			end;
		end;
	end;
  end;

function Dir(ADirName : String) : String;
begin
	ADirName := FileExpand(ADirName);
	if (ADirName[Length(ADirName)] <> Delimiter) then
		Dir := ADirName + Delimiter
	else
		Dir := ADirName;
end;

function DriveLetters : String;
var
	I : integer;
	S : String[26];
begin
	S := '';
	for I := 1 to 26 do begin
		if IsValidDrive(I) then begin
			if IsRemovable(I) or IsCDROM(I) or IsRemote(I) then
				S := S + Char(96 + I)
			else
				S := S + Char(64 + I);
		end;
	end;
	DriveLetters := S;
end;

  function BINByte ( B : Byte ) : Str8; assembler;
	asm
	  LES DI, @Result
	  MOV AL, 8
	  MOV ES:[DI], AL
	  MOV CX, 8
	  MOV AL, B
	@@1:
	  INC DI
	  MOV AH, '1'
	  CMP AL, $80
	  JAE @@2
	  MOV AH, '0'
	@@2:
	  MOV ES:[DI], AH
	  SHL AL, 1
	  DEC CX
	  JNZ @@1
	end;

function GetEnvCount: integer; assembler;
asm
		PUSH DS
		MOV	 DS, PrefixSeg
		MOV	 DI, 0
		MOV	 DS, [$2C]
		XOR	 CX, CX
   @ReadLoop:
		MOV	 AL, [DI]
		CMP	 AL, 0
		JE	 @ReadDone
		INC	 CX
	@ReadString:
		MOV	 AL, [DI]
		INC	 DI
		CMP	 AL, 0
		JNE	 @ReadString
		JMP @ReadLoop
	@ReadDone:
	@Done:
		MOV	 AX, CX
		POP	 DS
end;

function GetEnvParam(AIndex : integer): String; assembler;
asm
		PUSH DS
		PUSH ES
		MOV	 DX, AIndex
		LES	 BX, @Result
		PUSH BX
		MOV	 DS, PrefixSeg
		MOV	 DI, 0
		MOV	 DS, [$2C]
		XOR	 CX, CX
		XOR	 AH, AH
		CMP	 DX, 0
		JE	 @ReadDone
   @ReadLoop:
		MOV	 AL, [DI]
		CMP	 AL, 0
		JE	 @ReadDone
		INC	 CX
		CMP	 CX, DX
		JE	 @ReadString
	@ReadSkip:
		MOV	 AL, [DI]
		INC	 DI
		CMP	 AL, 0
		JNE	 @ReadSkip
		JMP	 @ReadLoop
	@ReadString:
		MOV	 AL, [DI]
		INC	 DI
		CMP	 AL, 0
		JE	 @ReadDone
		INC AH
		INC BX
		MOV	 ES:[BX], AL
		CMP	 AH, $FF
		JE	 @ReadDone
		JMP	 @ReadString
	@ReadDone:
		POP	 BX
		MOV	 ES:[BX], AH
		POP	 ES
		POP	 DS
end;

function GetEnv(AKey : String): String;
var
	I : integer;
	S : String;
begin
	GetEnv:='';
	AKey := AKey + '=';
	for I := 1 to GetEnvCount do begin
		S := GetEnvParam(I);
		if Pos(AKey, S) = 1 then begin
			GetEnv := Copy(S, Length(AKey) + 1, Length(S));
			Break;
		end;
	end;
end;

procedure PackTime(DateTime : TDateTime; var Value : LongInt); assembler;
asm
	XOR CX, CX
	XOR DX, DX
	PUSH DS
	LDS BX, DateTime
	{ Year }
	MOV	 DX, [BX]
	SUB	 DX, DosYear
	PUSH AX
	PUSH CX
	MOV	 CL, 9
	MOV	 AX, DX
	SHL	 AX, CL
	MOV	 DX, AX
	POP	 CX
	POP	 AX
	ADD	 BX, 2
	{ MONTH }
	MOV	 AX, [BX]
	AND	 AX, 1111b
	PUSH CX
	MOV	 CL, 5
	SHL	 AX, CL
	POP	 CX
	OR	 DX, AX
	ADD	 BX, 2
	{ DAY }
	MOV	 AX, [BX]
	AND	 AX, 11111b
	OR	 DX, AX
	ADD	 BX, 2
	{ Hour }
	MOV	 CX, [BX]
	PUSH CX
	PUSH AX
	XCHG AX, CX
	MOV	 CL, 5
	SHL	 AX, CL
	XCHG AX, CX
	POP	 AX
	POP	 CX
	ADD	 BX, 2
	{ Min }
	MOV	 AX, [BX]
	AND	 AX, 111111b
	PUSH CX
	MOV	 CL, 5
	SHL	 AX, CL
	POP	 CX
	OR	 CX, AX
	ADD	 BX, 2
	{ Sec }
	MOV	 AX, [BX]
	AND	 AX, 11111b
	OR	 CX, AX

	LDS BX, Value
	MOV DS:[BX], CX
	MOV DS:[BX + 2], DX
	POP DS
end;

procedure UnPackTime(Value : LongInt; var DateTime : TDateTime); assembler;
asm
	LES CX, Value
	PUSH ES
	POP	 DX

	PUSH DS
	LDS BX, DateTime
	{ Year }
	MOV AX, DX
	PUSH CX
	MOV CL, 9
	SHR AX, CL
	POP CX
	ADD AX, DosYear
	MOV DS:[BX], AX
	{ Month }
	ADD BX, 2
	MOV AX, DX
	PUSH CX
	MOV CL, 5
	SHR AX, CL
	POP CX
	AND AX, 1111b
	MOV DS:[BX], AX
	{ Day }
	ADD BX, 2
	AND DX, 11111b
	MOV DS:[BX], DX
	{ Hour }
	ADD BX, 2
	MOV AX, CX
	PUSH CX
	MOV CX, 11
	SHR AX, CL
	POP CX
	MOV DS:[BX], AX
	{ Min }
	ADD BX, 2
	MOV AX, CX
	PUSH CX
	MOV CX, 5
	SHR AX, CL
	POP CX
	AND AX, 111111b
	MOV DS:[BX], AX
	{ Sec }
	ADD BX, 2
	AND CX, 11111b
	MOV DS:[BX], CX

	POP DS
end;

{Dos FCB Fn 0F,10,11,12,13,14,15,16,17,1A,21,22,23,24,27,28,29,2F }
{Dos Country Fn 38 }
{Dos DIR Fn 39, 3A, 3B }
{Dos File I/O Fn 3C,3D,3E,3F,40,41,42,45,46,47 }
{Dos Memory Fn 48,49,4A }
{Dos Fn 06,07,0A,0C,1B,26,31,32,34,37,44(00,01,02,03,04,05,06,07,0A,0B,0C,0D),
  4B,4C,4D,4E,4F,54,56,57,59,5A,5B,5C,5E,5F,62,65,66,67,68,6C ommitted. }

  procedure InitUnit;
	begin
	  DosError := 0;

	  { if Unknown assume its ok and exit procedure }
	  if ( DosVersion = DosXXX ) then exit;

	  { check dos version }
	  if (Lo(DosVersion) < Lo(ReqDosVersion)) or
	  ((Lo(DosVersion) = Lo(ReqDosVersion)) and
	  (Hi(DosVersion) < Hi(ReqDosVersion))) then
		begin
		  WriteLn ( 'This program requires ', DosVersionStr(ReqDosVersion), '+. Your version ',
		  'says it is ',  DosVersionStr(DosVersion) );
		  Halt(1);
		end;
		SaveIntVecs;
	end;

function FileExtension(AFileName : String) : String;
var
	I : integer;
begin
	I := LastPos('.', AFilename);
	if (I < Length(AFileName) - 3) or (I < 1) then
		FileExtension := ''
	else
		FileExtension := UCase(Copy(AFileName, I + 1, 3));
end;

function FilePath(AFileName : String) : String;
var
	I : integer;
begin
	I := LastPos('\', AFilename);
	if (I < 1) then
		FilePath := ''
	else
		FilePath := UCase(Copy(AFileName, 1, I));
end;

function NoTailDelim(APath : String) : String;
begin
	if (Length(APath) > 0) and (APath[Length(APath)] <> Delimiter) then
		NoTailDelim := APath
	else
		NoTailDelim := Copy(APath, 1, Length(APath) -1 );
end;

function TailDelim(APath : String) : String;
begin
	if (Length(APath) > 0) and (APath[Length(APath)] = Delimiter) then
		TailDelim := APath
	else
		TailDelim := APath + Delimiter;
end;

function GetLanguage : String;
var
  R : String[12];
begin
    R := UCase(GetEnv('LANG'));
    if R = '' then
        GetLanguage := 'EN'
    else
        GetLanguage := R;
end;

function SwitchChar : char;
var
  R : String[12];
begin
    R := GetEnv('SWITCHCHAR');
    if R = '' then
        SwitchChar := '/'
    else
        SwitchChar := R[1];
end;

begin
  InitUnit;
end.
