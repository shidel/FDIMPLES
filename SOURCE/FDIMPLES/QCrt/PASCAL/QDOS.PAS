{
    Copyright 2019 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit QDOS; { QuickCrt 9.x, DOS Unit, Requires MS-DOS 5.00 or better }

{$I QCRT.DEF}

interface

const
  { Offset for DOS Date Time Functions }
    DosYear = 1980;

  { File attributes constants }
    faReadOnly   = $01;
    faHidden     = $02;
    faSystem     = $04;
    faVolumeID   = $08;
    faDirectory  = $10;
    faArchive    = $20;
    faAnyFile    = $3F;

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
      Int20: 			   word;
      MemTop:              word;
      DosReservedArea01:   byte;
      DosDispatcher:       byte; {if not com then Segavail and #2 belong}
      SegAvail:            word; {to DosDispatcher }
      DosDispatcher2:      word;
      TerminateAddress:    pointer;
      ControlBreak:        pointer;
      CriticalError:       pointer;
      DosReservedArea02:   array[0..21] of byte;
      EnvSeg:              word;
      DosReservedArea03:   array[0..45] of byte;
      FormatedParamArea01: array[0..15] of byte;
      FormatedParamArea02: array[0..19] of byte;
      Params:         	   string[127];
    end;

    PParamBlock = ^TParamBlock;
    TParamBlock = record
    	EnvSeg : word;
    	CmdLn : pointer;
    	FCB1, FCB2 : pointer;
    	Params : String;
    end;

var
    PathDelim   : Char;
    SwitchChar  : Char;
    DosError    : integer;
    WildCard    : String[3];

function DosVersion : word;

function StdInReady : boolean;

{ Character I/O }
{
    These functions should be avoided. DOS StdIn has issues in some virtual
    machines and DOS platforms. But mostly, doing Std I/O this way is really
    really really slow.
}
function StdInChr : char;
procedure StdOutChr( AChr : char );
function StdInOutChr : char;
procedure StdOutStr( const Adr ); { String must end in $ }
function StdAuxInChar : char;
procedure StdAuxOutChr( AChr : char );
procedure StdPrnOutChr( AChr : char );

{ Handle oriented I/O Stuff}
function GetDeviceInfoWord(Handle : word) : word;
procedure GetFAttr(var F; var Attr: Word);
procedure SetFAttr(var F; Attr: Word);
procedure GetFTime(var F; var Time : LongInt);
procedure SetFTime(var F; Time : LongInt);
procedure GetFSize(var F; var Size : LongInt);

{ Redirection }
function IsRedirectedInput : boolean;
function IsRedirectedOutput : boolean;

{ Date/Time }
procedure GetDate(var Year, Month, Day, DayOfWeek: Word);
function SetDate(Year, Month, Day: Word) : boolean;
procedure GetTime(var Hour, Minute, Second, Sec100: Word);
function SetTime(Hour, Minute, Second, Sec100: Word) : boolean;

{ Disk functions }
{ If a files size has changed it should be closed before flush. }
procedure FlushAllFileBuffers;
function GetCurDisk : byte;
procedure SetCurDisk ( ADrive: byte );
function BootDrive : byte;                          { Mostly Useless }
function LastDrive : byte;                          { Mostly Useless }
function Diskettes : byte; { BiosFn }
function IsValidDrive ( ADrive : byte ) : boolean;
function IsRemovable ( ADrive : byte ) : boolean;
function IsRemote ( ADrive : byte ) : boolean;
function IsCDROM ( ADrive : byte ) : boolean;       { Does not work on FreeDOS }
function GetLogical ( ADrive : byte ) : byte;
function SetLogical ( ADrive : byte ) : byte;
function GetDiskSerial(ADrive: byte) : longInt;
procedure SetDiskSerial(ADrive: byte; ASerial : longInt);
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
function BaseNameOf(AFileName : String) : String;
function ExtensionOf(AFileName : String) : String;

function DriveLetters : string;

{ Expands a file or dir name to full path }
function FileExpand(AFileName : String) : String;

function FileExtension(AFileName : String) : String;

{ Returns 0, if the dir exists or was able to be created. Or non-zero error }
function MakeDir ( ADir : String ) : integer;

{ Uses FindFirst to test if File/Dir Exists }
function FileExists ( AFileName : String ) : boolean;
function DirExists ( AFileName : String ) : boolean;
function Exists ( AFileName : String ) : boolean;

function Dir(ADirName : String) : String;

procedure PackTime(DateTime : TDateTime; var Value : LongInt);
procedure UnPackTime(Value : LongInt; var DateTime : TDateTime);

function NoTailDelim(APath : String) : String;
function TailDelim(APath : String) : String;

function GetExeName : String;
function GetExeBase : String;
function GetExePath : String;

function GetEnv(const Key : String) : String;
function GetEnvCount: integer;
function GetEnvParam(AIndex : integer): String;

function DiskReady(ADrive : byte):boolean;

implementation

uses
    QASCIIZ, QStrings;

{$L QDOS.OBJ}

function DiskReady(ADrive : byte):boolean; assembler;
{ Technically, disk change is a BIOS function present starting 1/10/1986,
really should only be used with floppy disks }
asm
  MOV   AL, ADrive
  CMP   AL, 26
  JA    @0
  CMP   AL, 0
  JNE   @1
@0:
  MOV   AH, 19h
  INT   21h
  INC   AL
@1:
  DEC   AL
  CMP   AL, 2
  JB    @2
  ADD   AL, 7Eh
@2:
  MOV   DL, AL
  MOV   AH, 16h
  INT   13h
  JC    @4
@3:
  MOV   AL, TRUE
  JMP   @5
@4:
  MOV   AL, FALSE
@5:
end;

function DosVersion : word; assembler;
asm
  MOV  AH, 30h
  INT  21h
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

procedure GetFSize(var F; var Size : LongInt);
var
    M : word;
begin
    { M := FileMode;
    FileMode := 0; }
    Reset(File(F), 1);
    DosError := IOResult;
    if DosError = 0 then begin
        Size := FileSize(File(F));
        DosError := IOResult;
        Close(File(F));
        if DosError = 0 then
            DosError := IOResult;
    end;
    if DOSError <> 0 then
        Size := -1;
    { FileMode := M; }
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

function IsRedirectedInput : boolean;
begin
  IsRedirectedInput  := (GetDeviceInfoWord(0) and $80 <> $80) and (DosError = 0);
end;

function IsRedirectedOutput : boolean;
begin
  IsRedirectedOutput := (GetDeviceInfoWord(1) and $80 <> $80) and (DosError = 0);
end;

{ Date/Time }
procedure GetDate(var Year, Month, Day, DayOfWeek: Word); assembler;
{ Day of Week is only returned in DOS 3.00 or better }
asm
  MOV  AH, 2Ah
  INT  21h
  LES  DI, Year
  MOV  ES:[DI], CX
  XOR  AH, AH
  LES  DI, DayOfWeek
  STOSW
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
  { DOSBox Bug Fix }
@1:
  CMP   AL, 24
  JBE   @2
  SUB   AL, 24
  JMP   @1
@2:
  { End Fix }
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
      CMP  DL, 0        { Default Drive }
      JNE  @1
      MOV  AH, 0Eh
      DEC  DL
      INT  21h
    @1:
    end;

  function BootDrive : byte; assembler;
    asm
      MOV  AX, 3305h
      INT  21h
      MOV  AL, DL
    end;

  function LastDrive : byte; assembler;
    asm
      MOV  AH, 19h
      INT  21h
      MOV  DL, AL
      MOV  AH, 0Eh
      INT  21h
    end;

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

  function IsValidDrive ( ADrive : byte ) : boolean; assembler;
    asm
      MOV  DosError, 15 { erInvalid_Drive_Number }
      MOV  AX, 4408h
      MOV  BL, ADrive
      INT  21h
      MOV  CL, False
      CMP  AX, 01h
      JG   @@NotValid
      MOV  DosError, 0 { No Error }
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
      MOV  DosError, 0 { No Error }
    end;

  function IsCDROM ( ADrive : byte ) : boolean; assembler;
    asm
      MOV  DosError, 0 { No Error }
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

type
InfoBuffer = record
  InfoLevel  : word; {should be zero}
  Serial     : LongInt;
  VolLabel   : array [0..10] of char;
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
  TBuf   : InfoBuffer;
begin
  GetInfoBuffer( ADrive, TBuf );
  TBuf.Serial := ASerial;
  if DosError = 0 { No Error } then
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
    XOR  AX, AX
@@Returned:
	{ Restore SS:SP }
	MOV DI, OFFSET @@SaveRegs
	MOV SP, CS:[DI]
	MOV SS, CS:[DI+2]

	{ Restore Registers }
	POP  DS
	POP  ES
	POP  DI
	POP  SI
    MOV  DosError, AX
    XOR  AX, AX
end;

procedure Exec(Command, Params : String);
var
    P : TParamBlock;
begin
    if Length(Command) > 254 then
        Command[Length(Command)] := #0
    else
        Command := Command + #0;
    P.EnvSeg := 0;
    P.CmdLn := @P.Params;
    P.Params := Params + #$0d;
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
        PUSH 	DS
        LDS		DX, SearchRec
        INT     21h
        POP		DS
        MOV     CX, attr
        PUSH 	DS
        LEA     DX, PathName
        INC		DX
        PUSH 	ES
        POP		DS
        MOV     AH, 4Eh
        INT     21h
        JC      @NotFound
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
        MOV 	DosError, 0
        JMP 	@Done
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
        MOV     AH, 4Fh
        PUSH 	DS
        LDS		DX, SearchRec
        INT     21h
        JC      @NotFound
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
        MOV 	DosError, 0
        JMP 	@Done
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
    PathOf := Trim(UCase(Copy(AFileName, 1, LastPos(PathDelim, AFileName))));
end;

function BaseNameOf(AFileName : String) : String;
begin
    AFileName := Trim(UCase(Copy(AFileName, LastPos(PathDelim, AFileName) + 1, Length(AFileName))));
    if LastPos('.', AFilename) > 0 then
        BaseNameOf := Copy(AFileName, 1, LastPos('.', AFilename) -1 )
    else
        BaseNameOf := AFileName;
end;

function ExtensionOf(AFileName : String) : String;
begin
    AFileName := Trim(UCase(Copy(AFileName, LastPos(PathDelim, AFileName) + 1, Length(AFileName))));
    if LastPos('.', AFilename) > 0 then
        ExtensionOf := Copy(AFileName, LastPos('.', AFilename) + 1, Length(AFileName) )
    else
        ExtensionOf := '';
end;

function FileExpand(AFileName : String) : String;
var
Temp, S : String;
I : integer;
begin
if AFileName = '' then begin
    GetDir(0, AFileName);
end else begin
    if (AFileName[1] = PathDelim) then begin
        AFileName := Chr(GetCurDisk + 64) + ':' + AFileName;
    end else
    if (Length(AFileName) > 2) and (AFileName[2] <> ':') then begin
        GetDir(0, Temp);
        AFileName := TailDelim(Temp) + AFileName;
    end else
    if ((Length(AFileName) > 3) and (AFileName[3] <> PathDelim)) or
    ((Length(AFileName) = 2) and (AFileName[2] = ':')) then begin
        Temp := UCase(AFileName[1]);
        GetDir(Ord(Temp[1]) - 64, Temp);
        AFileName := TailDelim(Temp) + Copy(AFileName, 3, Length(AFileName));
    end;
    Temp := UCase(AFileName);
    AFileName := '';
    while Temp <> '' do begin
        I := Pos(PathDelim, Temp);
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
            I := LastPos(PathDelim, AFileName);
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
    X : integer;
begin
    X := DosError;
    FindFirst(FileExpand(AFileName), faAnyFile, Search);
    Exists := (DosError = 0);
    DosError := X;
end;

function FileExists ( AFileName : String ) : boolean;
var
    Search : TSearchRec;
    X : integer;
begin
    X := DosError;
    FindFirst(FileExpand(AFileName), faAnyFile, Search);
    FileExists := (DosError = 0) and (Search.Attr and faDirectory <> faDirectory);
    DosError := X;
end;

function DirExists ( AFileName : String ) : boolean;
var
    Search : TSearchRec;
    X : integer;
begin
    X := DosError;
    FindFirst(TailDelim(AFileName) + WildCard, faAnyFile, Search);
    DirExists := (DosError = 0);
    DosError := X;
end;

function MakeDir(ADir : String) : integer;
begin
    MakeDir := 0;
    ADir := NoTailDelim(ADir);
    if DirExists(ADir) then Exit;
    DosError := MakeDir(PathOf(ADir));
    if DosError = 0 then begin
        MkDir(ADir);
        DosError := IOResult;
    end;
    MakeDir := DosError;
end;

function Dir(ADirName : String) : String;
begin
  	ADirName := TailDelim(FileExpand(ADirName));
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

procedure PackTime(DateTime : TDateTime; var Value : LongInt); assembler;
asm
	XOR CX, CX
	XOR DX, DX
	PUSH DS
	LDS BX, DateTime
	{ Year }
	MOV	 DX, [BX]
	SUB  DX, DosYear
	{$IFOPT G+}
        SHL  DX, 9
	{$ELSE}
        PUSH AX
        PUSH CX
        MOV  AX, DX
        MOV  CL, 9
        SHL  AX, CL
        MOV  DX, AX
        POP  CX
        POP  AX
	{$ENDIF}
	ADD  BX, 2
	{ MONTH }
	MOV	 AX, [BX]
	AND  AX, 1111b
	{$IFOPT G+}
        SHL  AX, 5
	{$ELSE}
        PUSH CX
        MOV  CL, 5
        SHL  AX, CL
        POP  CX
	{$ENDIF}
	OR	 DX, AX
	ADD  BX, 2
	{ DAY }
	MOV	 AX, [BX]
	AND  AX, 11111b
	OR	 DX, AX
	ADD  BX, 2
	{ Hour }
	MOV	 CX, [BX]
	{$IFOPT G+}
        SHL  CX, 11
	{$ELSE}
        PUSH AX
        MOV  AX, CX
        MOV  CL, 11
        SHL  AX, CL
        MOV  CX, AX
        POP  AX
	{$ENDIF}
	ADD  BX, 2
	{ Min }
	MOV	 AX, [BX]
	AND  AX, 111111b
	{$IFOPT G+}
        SHL  AX, 5
	{$ELSE}
        PUSH CX
        MOV  CL, 5
        SHL  AX, CL
        POP  CX
	{$ENDIF}
	OR	 CX, AX
	ADD  BX, 2
	{ Sec }
	MOV	 AX, [BX]
	AND  AX, 11111b
	OR	 CX, AX

	LDS	BX, Value
	MOV	DS:[BX], CX
	MOV	DS:[BX + 2], DX
	POP DS
end;

procedure UnPackTime(Value : LongInt; var DateTime : TDateTime); assembler;
asm
	LES CX, Value
	PUSH ES
	POP  DX

	PUSH DS
	LDS BX, DateTime
	{ Year }
	MOV AX, DX
	{$IFOPT G+}
        SHR AX, 9
	{$ELSE}
	    PUSH CX
	    MOV  CL, 9
	    SHR  AX, CL
	    POP  CX
	{$ENDIF}
	ADD AX, DosYear
	MOV DS:[BX], AX
	{ Month }
	ADD BX, 2
	MOV AX, DX
	{$IFOPT G+}
        SHR AX, 5
	{$ELSE}
	    PUSH CX
	    MOV  CL, 5
	    SHR  AX, CL
	    POP  CX
	{$ENDIF}
	AND	AX, 1111b
	MOV DS:[BX], AX
	{ Day }
	ADD BX, 2
	AND DX, 11111b
	MOV DS:[BX], DX
	{ Hour }
	ADD BX, 2
	MOV AX, CX
	{$IFOPT G+}
        SHR AX, 11
	{$ELSE}
	    PUSH CX
	    MOV  CL, 11
	    SHR  AX, CL
	    POP  CX
	{$ENDIF}
	MOV DS:[BX], AX
	{ Min }
	ADD BX, 2
	MOV AX, CX
	{$IFOPT G+}
        SHR AX, 5
	{$ELSE}
	    PUSH CX
	    MOV  CL, 5
	    SHR  AX, CL
	    POP  CX
	{$ENDIF}
	AND	AX, 111111b
	MOV DS:[BX], AX
	{ Sec }
	ADD BX, 2
	AND	CX, 11111b
	MOV DS:[BX], CX

	POP DS
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

function NoTailDelim(APath : String) : String;
begin
	if (Length(APath) > 0) and (APath[Length(APath)] <> PathDelim) then
		NoTailDelim := APath
	else
		NoTailDelim := Copy(APath, 1, Length(APath) -1 );
end;

function TailDelim(APath : String) : String;
begin
	if (Length(APath) > 0) and (APath[Length(APath)] = PathDelim) then
		TailDelim := APath
	else
		TailDelim := APath + PathDelim;
end;

function GetExeName : String;
var
    P : integer;
    R : String;
begin
    R := ParamStr(0);
    P := Length(R);
    while (R[P] <> PathDelim) and (P > 0) do Dec(P);
    GetExeName := Copy(R, P + 1, Length(R));
end;

function GetExeBase : String;
var
    P : integer;
    R : String;
begin
    R := GetExeName;
    while (R[Length(R)] <> '.' ) and (Length(R) > 1) do Dec(R[0]);
    Dec(R[0]);
    GetExeBase := R;
end;

function GetExePath : String;
var
    P : integer;
    R : String;
begin
    R := ParamStr(0);
    while (R[Length(R)] <> PathDelim ) and (Length(R) > 1) do Dec(R[0]);
    Dec(R[0]);
    GetExePath := R;
end;

function GetEnvCount: integer; assembler;
asm
    PUSH DS
    MOV  DS, PrefixSeg
    MOV  DI, 0
    MOV  DS, [$2C]
    XOR  CX, CX
@ReadLoop:
    MOV	 AL, [DI]
    CMP	 AL, 0
    JE	 @ReadDone
    INC  CX
@ReadString:
    MOV	 AL, [DI]
    INC  DI
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
    MOV  DX, AIndex
    LES  BX, @Result
    PUSH BX
    MOV  DS, PrefixSeg
    MOV  DI, 0
    MOV  DS, [$2C]
    XOR  CX, CX
    XOR  AH, AH
    CMP  DX, 0
    JE   @ReadDone
@ReadLoop:
    MOV	 AL, [DI]
    CMP	 AL, 0
    JE	 @ReadDone
    INC  CX
    CMP  CX, DX
    JE	 @ReadString
@ReadSkip:
    MOV	 AL, [DI]
    INC  DI
    CMP	 AL, 0
    JNE	 @ReadSkip
    JMP  @ReadLoop
@ReadString:
    MOV	 AL, [DI]
    INC  DI
    CMP	 AL, 0
    JE	 @ReadDone
    INC	AH
    INC BX
    MOV  ES:[BX], AL
    CMP	 AH, $FF
    JE	 @ReadDone
    JMP  @ReadString
@ReadDone:
    POP  BX
    MOV  ES:[BX], AH
    POP  ES
    POP	 DS
end;

function GetEnv(const Key : String) : String;
begin
    GetEnv := KeyValueOnly(LookupASCIIZ(Ptr(MemW[PrefixSeg:$002c],0), Key));
end;

{ initialization & finalization routines }

function InitQDOS(PrefixSeg : word) : boolean; external;

procedure UnitInit;
var
    S : String;
begin
    SaveIntVecs;
    if not InitQDOS(PrefixSeg) then Halt(10); { Internal Error }

    PathDelim := '\';
    WildCard := '*.*';

    S := GetEnv('SWITCHCHAR');
    if S = '' then
        SwitchChar := '/'
    else
        SwitchChar := S[1];
end;

begin
    UnitInit;
end.