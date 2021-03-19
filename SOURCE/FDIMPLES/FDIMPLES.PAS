{
    Copyright 2019 Jerome Shidel
    Released Under GPL v2.0 License.
}

{

    Program information and behaviour when running within FDI during the
    installation of FreeDOS is different then running in stand alone mode.
    Some notes on behaviour during this time.

    On Startup, useful environment variables:

        OS_NAME     = Operating system platform name for installation.
        OS_VERSION  = Operating system release number.
        FDRIVE      = Destination Drive for installation.
        FTARGET     = Destination %DOSDIR% for installation.
        FMEDIA      = root of source package tree.
        OSRC        = if it is "y", then sources will be installed.
        FADV        = this will be "y", running in advanced mode or FDIMPLES is
                    not executed.
        TEMP        = Small ramdisk temporary path.
        LANG        = User's target language.

        See THEMEADV.BAT for a list of Advanced mode theme settings.

    Other known information.

        Current working directory = FDI files.

        FDPLBASE.LST is list of BASE only package install files.
        FDPLFULL.LST is list of ALL package install files.

    On exit,

        errorlevel 200, for aborted (CTRL+C)
        errorlevel 1, cancelled. (like Escape)
        errorlevel 0, ok, and %TEMP%\FDIMPLES.LST contains package list.
}

{ Original Prior to 0.9.8 Memory Settings }
{ M 50000,51200,204800} (* Memory: Largest Stack, 100K Minimum / Maximum *)
{ Post 0.9.7 Memory settings }
{ M 32768,51200,102400}

{ Post 0.9.16 Memory settings }
{$M 16384,51200,128000}

{$I QCRT.DEF}

{$DEFINE USEBAT}
program Test;

uses QDos, QCrt, QBoxes, QEvents, QEditLn, QStrings, Language, FileIO;

{$I VERSION.INC}

const
    { App Name and Title are not in translation system.
      Nor, should they be translated into any other language. }
    AppName = 'FDIMPLES';
    AppTitle = 'FreeDOS Installer - My Package List Editor Software';
    ALLPackages = 'FDPLFULL.LST';
    BASEPackages = 'FDPLBASE.LST';
    LoMem = 5120;
    NoScroll = 1;
    MinTicks = 7;

    StatSpeed = 18 * 3;
    TickerMod = 3;
    TickGrpLag = 2;
    TickPkgLag = 4;
    IdleWait = 18 * 4;

type
    TStates = (psNone, psPartial, psFull, psUpgrade, psReplace);
    TModes = (rmFDI, rmStandAlone, rmList, rmConfig);
    TChecks = array [TStates] of Char;
    TCheckColors = array [TStates] of byte;
    PItem = ^TItem;
    TItem = record
        Prev, Next, Items : PItem;
        Name : Str12;
        State, Original : TStates;
        Title, IVersion, MVersion : PString;
        First, Locked, Tested, Skipped : boolean;
    end;
    PText = ^TText;
    TText = record
        Next : PText;
        Str : PString;
    end;
    TTheme = record
        Frame, Grps : TPoint;
        Border:byte;
        Fore, Back, Choose, Hot : Byte;
        FillAttr : Byte;
        FillChar : Char;
        Double, Shadow : boolean;
        Title, TitleHot : byte;
        Status, StatusHot, StatusErr : byte;
        Brace : byte;
        Text, TextHot : byte;
        Name, NameHot : byte;
        Author, AuthorHot : byte;
        Bar, BarHot : byte;
        StandBy : byte;
        Checks : TCheckColors;
        Inst, Remv : byte;
    end;

var
    Tab : integer;
    Defaults : PText;
    Group, GroupFirst, GroupTop, GroupBottom, GroupLast,
    Package, PackageFirst, PackageTop, PackageBottom, PackageLast : PItem;
    LineTop, LineBottom : PItem;
    FMedia : String;
    Theme : TTheme;
    CheckMark : TChecks;
    RunMode : TModes;
    FileList : boolean;
    AutoUpdate : boolean;
    UpdateOn : boolean;
    TickCount, StatCount : Longint;
    LastTick, StatTick : LongInt;
    Startup : boolean;
    Comments : boolean;
    ListDir : string;
    PackageInfo : string;
    TimerTick    : LongInt absolute $0040:$006c;  { Timer tick counter }
    TickerA, TickerB : integer;
    IdleTick, IdleCount : LongInt;
    PackageManager : string;
    CGroup, CPackage : PItem;

    StatPhase : integer;

    {$IFDEF DEBUG}
    LOGFILE : Text;
    {$ENDIF}

const
    psBase = psFull;
    psAll = psUpgrade;
    psExtra = psReplace;
    NormalCheckMarks : TChecks = (#$20, '+', 'X', 'U', 'R');
    ListCheckMarks   : TChecks = (#$20, '+', 'B', 'A', 'e');
    ThemeRed  : TTheme = (
        Frame:(X:5; Y:4);
        Grps:(X:18; Y:8);
        Border:$4F;
        Fore:White;
        Back:Red;
        Choose:$1e;
        Hot:LightGreen;
        FillAttr:$07;
        FillChar:#$B0;
        Double:True;
        Shadow:True;
        Title:$4f;
        TitleHot:$4e;
        Status:$47;
        StatusHot:$4f;
        StatusErr:$4e;
        Brace:$08;
        Text:$07;
        TextHot:$0F;
        Name:$02;
        NameHot:$0A;
        Author:$03;
        AuthorHot:$0B;
        Bar:$06;
        BarHot:$0e;
        StandBy:$1c;
        Checks:($07, $0F, $0F, $0E, $0E);
        Inst:$4F;
        Remv:$4E
    );
    ThemeBlue : TTheme = (
        Frame:(X:1; Y:2);
        Grps:(X:18; Y:8);
        Border:$1F;
        Fore:White;
        Back:Blue;
        Choose:$71;
        Hot:LightGreen;
        FillAttr:$07;
        FillChar:#$B0;
        Double:False;
        Shadow:False;
        Title:$70;
        TitleHot:$74;
        Status:$08;
        StatusHot:$07;
        StatusErr:$0c;
        Brace:$08;
        Text:$07;
        TextHot:$0F;
        Name:$02;
        NameHot:$0A;
        Author:$03;
        AuthorHot:$0B;
        Bar:$06;
        BarHot:$0e;
        StandBy:$0e;
        Checks:($07, $0F, $0E, $0B, $0C);
        Inst:$1A;
        Remv:$4E
    );

procedure SetCritical(AGroup, APackage : PItem);
begin
    CGroup := AGroup;
    CPackage := APackage;
end;

procedure ResetIdler;
begin
    IdleTick := TimerTick;
    IdleCount:= 0;
end;

procedure Idler;
begin
    if IdleCount > IdleWait then
        Idle
    else if IdleTick <> TimerTick then begin
        IdleTick := TimerTick;
        Inc(IdleCount);
    end;
end;

procedure StandBy;
const
    Ticks : string[4] = '/-\|';
    Speed = 2;
var
    WMin, WMax, X, Y, A : integer;
begin
    ResetIdler;
    if RunMode = rmFDI then exit;
    if LastTick = TimerTick then exit;
    LastTick := TimerTick;
    Inc(TickCount);
    if (TickCount < MinTicks) and (not Startup) then exit;
    if Startup then begin
        if TickCount < 2 then exit;
        if TickCount > 2 then GotoXY(WhereX -1, WhereY);
        WriteRawPStr(Ticks[((TickCount - 2) div Speed) mod Length(Ticks) + 1]);
    end else begin
        WMin := WindMin;
        WMax := WindMax;
        X := WhereX;
        Y := WhereY;
        A := TextAttr;

        Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
        gotoXY(1,Hi(WindMax));
        TextAttr := Theme.StandBy;
        if TickCount = MinTicks then begin
            WriteRawPStr(' ' + NLS(nlsStandby));
            ClrEol;
        end;
        GotoXY(Length(NLS(nlsStandby)) + 3, Hi(WindMax));
        WriteRawPStr(Ticks[((TickCount - MinTicks) div Speed) mod Length(Ticks) + 1]);
        WindMin := WMin;
        WindMax := WMax;
        GotoXY(X, Y);
        TextAttr := A;
    end;
end;

function FDIMode : boolean;
begin
    FDIMode := RunMode = rmFDI;
end;

procedure CleanUp;
begin
    if FDIMode then exit;
    TextAttr := 7;
    window(1,1,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
(*    CheckCursor := True; *)
    CheckScroll := True;
    ClrScr;
    NormalCursor;
end;

{$IFDEF DEBUG}
procedure Log(AMsg : String);
begin
    Assign(LOGFILE, 'FDIMPLES.LOG');
    Append(LOGFILE);
    WriteLn(LOGFILE, AMsg);
    Close(LOGFILE);
end;
{$ENDIF}

function ValueOf(S:String; D : integer) : Integer;
const
    Colors : array [0..15] of String[14] = (
    'BLACK', 'BLUE', 'GREEN', 'CYAN', 'RED',
    'MAGENTA', 'BROWN', 'GRAY', 'DARKGRAY',
    'LIGHTBLUE', 'LIGHTGREEN', 'LIGHTCYAN',
    'LIGHTRED', 'LIGHTMAGENTA', 'YELLOW',
    'WHITE' );
var
    I : integer;
begin
    S := Ucase(Trim(GetEnv(S)));
    if S = '' then
        ValueOf := D
    else begin
        if Copy(S, 1,2) = '0X' then
          S := '$' + Copy(S, 3, Length(S));
        for I := 0 to 15 do
            if S = Colors[I] then begin
                ValueOf := I;
                S := ''
            end;
        if S <> '' then
            ValueOf := StrInt(S);
    end;
end;

function StrOf(S : String; D : string) : string;
begin
    S := Trim(UCase(GetEnv(S)));
    if S = '' then S := Ucase(D);
    StrOf := S;
end;

procedure SetTheme;
begin
    if FDIMode then begin
        Theme := ThemeRed;
        Theme.Fore      := ValueOf('TFF', Theme.Fore);
        Theme.Back      := ValueOf('TFB', Theme.Back);
        Theme.Border    := Theme.Fore or Theme.Back shl 4;
        Theme.Choose    := ValueOf('TFC', Theme.Choose);
        Theme.Hot       := ValueOf('TFH', Theme.Hot);
        Theme.FillAttr  := ValueOf('TSF', Theme.FillAttr and $0F) +
            ValueOf('TSB', Theme.FillAttr shr 4 ) shl 4;
        Theme.FillChar  :=  Char(ValueOf('TSC', Ord(Theme.FillChar)));
        Theme.Double    := Pos('DOUBLE', StrOf('TFS', 'double shadow')) > 0;
        Theme.Shadow    := Pos('SHADOW', StrOf('TFS', 'double shadow')) > 0;
    end else
        Theme := ThemeBlue;
end;

function NewPItem(const AName: String; const AState : TStates) : PItem;
var
    P : PItem;
begin
    P := New(PItem);
    with P^ do begin
        Name := AName;
        State := AState;
        Prev := nil;
        Next := nil;
        Items := nil;
        Title := nil;
        IVersion := nil;
        MVersion := nil;
        First := True;
        Locked := False;
        Tested := False;
        Skipped := False;
    end;
    NewPItem := P;
end;

function LockPackage(AName : String) : boolean;
begin
    LockPackage := (RunMode = rmStandAlone) and (
        (AName = 'FDNPKG') or
        (AName = 'FDIMPLES')
    );
end;

procedure ReadListFile(Name : string; Prefix : String);
var
    F : File;
    S : String;
    P : PText;
    C : integer;
begin
    if not FileExists(Name) then exit;
    FileMode := 0;
    Assign(F, Name);
    Reset(F,1);
    repeat
        C := UnixRead(F, S);
        S := Trim(Ucase(S));
        if S[1] = ';' then S := '';
        if S <> '' then begin
            P := New(PText);
            P^.Next := Defaults;
            P^.Str := StrPtr(Prefix + S);
            Defaults := P;
        end;
        while C = 0 do C := UnixRead(F, S);
    until C = -1;
    Close(F);
end;

procedure ReadDefaults;
var
    S : String;
    L, P : PText;
    D : TSearchRec;
begin
    Defaults := nil;
    if RunMode = rmFDI then begin
        if FileExists(ALLPackages) then
            ReadListFile(ALLPackages, '')
        else if FileExists(BASEPackages) then
            ReadListFile(BASEPackages, '')
        else exit;
    end else if (RunMode = rmList) or (RunMode = rmConfig) then begin
        if RunMode = rmConfig then begin
            ReadListFile(ListDir + 'FDPLFULL.LST',  'A* ');
            ReadListFile(ListDir + 'FDPLBASE.LST', 'B* ');
        end else begin
            ReadListFile(ListDir + 'PKG_XTRA.LST', 'E* ');
            ReadListFile(ListDir + 'PKG_FULL.LST',  'A* ');
            ReadListFile(ListDir + 'PKG_BASE.LST', 'B* ');
        end;
    end else begin
        { Installed LST files }
        S := Trim(UCase(TailDelim(GetEnv('DOSDIR'))));
        if (S = '') then exit;
        FindFirst(S + TailDelim('PACKAGES') + '*.LST', faAnyFile, D);
        L := nil;
        while DosError = 0 do begin
            if (D.Attr and faDirectory <> faDirectory) then begin
                P := New(PText);
                P^.Next := nil;
                P^.Str := StrPtr(PathDelim + copy(D.Name, 1, length(D.Name) - 4));
                {$IFDEF DEBUG}
                Log('Installed LST File: ' + PathDelim + copy(D.Name, 1, length(D.Name) - 4));
                {$ENDIF}
                if Assigned(L) then
                    L^.Next := P
                else
                    Defaults := P;
                L := P;
            end;
            FindNext(D);
        end;
    end;
end;

function GetPkgState(S : String) : TStates;
var
    P : PText;
    T : String;
    V : TStates;
begin
    V := psNone;
    P := Defaults;
    while Assigned(P) and (V = psNone) do begin
        T := PtrStr(P^.Str);
        if Copy(T, 2, Length(T)) = '* ' + S then begin
            case T[1] of
                'B' : V := psBase;
                'A' : V := psAll;
                'E' : V := psExtra;
            end;
        end else
            P := P^.Next;
    end;
    GetPkgState := V;
end;

function CheckDefault(S : String) : boolean;
var
    P : PText;
begin
    CheckDefault := false;
    P := Defaults;
    if FDIMode then begin
        while Assigned(P) do begin
            if PtrStr(P^.Str) = S then begin
                CheckDefault := true;
                exit;
            end;
            P := P^.Next;
        end;
    end else begin
        while Assigned(P) do begin
            if PtrStr(P^.Str) = Copy(S, Pos(PathDelim, S), Length(S)) then begin
                CheckDefault := true;
                exit;
            end;
            P := P^.Next;
        end;
    end;
end;

procedure SortList(var First, Last : PItem);
var
    P, N, L : PItem;
begin
    P := First;
    L := nil;
    while Assigned(P) do begin
        N := P^.Next;
        P^.Next := nil;
        P^.Prev := nil;
        if Assigned(L) then begin
            while Assigned(L^.Prev) and (P^.NAME < L^.NAME) do
                L := L^.Prev;
            while Assigned(L^.Next) and (P^.NAME > L^.NAME) do
                L := L^.Next;
            if P^.Name < L^.Name then begin
                P^.Next := L;
                P^.Prev := L^.Prev;
                if Assigned(L^.Prev) then
                    L^.Prev^.Next := P;
                L^.Prev := P;
            end else begin
                P^.Prev := L;
                P^.Next := L^.Next;
                if Assigned(L^.Next) then
                    L^.Next^.Prev := P;
                L^.Next := P;
            end;
        end;
        L := P;
        P := N;
    end;
    First := L;
    While Assigned(First^.Prev) do First := First^.Prev;
    Last := L;
    While Assigned(Last^.Next) do Last := Last^.Next;
end;

procedure AddCustomItems(P : PItem; B, N : String);
var
  J : PItem;
  F : boolean;
  FN : String;
begin
    if (RunMode <> rmFDI) then exit;

    if not Assigned(P) then exit;

    if not (P^.Name = B) then exit;

    FN := TailDelim(GetEnv('FINSP')) + 'PACKAGES';
    if not DirExists(FN) then exit;
    if not FileExists(TailDelim(FN) + TailDelim(B) + N + '.ZIP') then exit;

    if (not CheckDefault(TailDelim(B) + N)) then exit;

    J := NewPItem(N, psFull);
    if not Assigned(PackageFirst) then begin
        PackageFirst := J;
        PackageLast := J;
    end;
end;

procedure AddInstalled(var Others : PItem);
var
    S : boolean;
    P, J : PItem;
    I : PText;
begin
    I := Defaults;
    Others^.State := psFull;
    while Assigned(I) do begin
        S := True;
        P := GroupFirst;
        while S and Assigned(P) do begin
            J := P^.Items;
            while S and Assigned(J) do begin
                S := '\' + J^.Name <> PtrStr(I^.Str);
                J := J^.Next;
            end;
            P := P^.Next;
        end;
        if S then begin
            J := NewPItem(Copy(PtrStr(I^.Str), 2, 13), psFull);
            J^.Next := Others^.Items;
            if Assigned(Others^.Items) then
                Others^.Items^.Prev := J;
            Others^.Items := J;
        end;
        I := I^.Next;
    end;
end;

procedure ClearPackage(var Pkg : PItem);
var
    P, N : PItem;
begin
    P := Pkg^.Items;
    While Assigned(P) do begin
        N := P^.Next;
        FreeStr(P^.Title);
        Dispose(P);
        P := N;
        StandBy;
    end;
    Pkg^.First := true;
    Pkg^.Items := nil;
    Pkg^.Skipped := False;
end;

function FreeSomeMem(Factor : Longint) : boolean;
var
    Flag : boolean;
    G, P, PN : PItem;

begin
    G := GroupFirst;
    Flag := False;
    while Assigned(G) and (not Flag) do begin
        P := G^.Items;
        while Assigned(P) and (Not Flag) do begin
            if P <> Package then
                ClearPackage(P);
            Flag := (MaxAvail > LoMem * Factor);
            P := P^.Next;
        end;
        G := G^.Next;
    end;
    FreeSomeMem := (MaxAvail > LoMem * 2);
end;

function MemCheck(size : integer) : boolean;
begin
    if (MaxAvail < Size * 2) or (MemAvail < LoMem) then begin
        FreeSomeMem(10);
        MemCheck := (MaxAvail > Size * 2);
    end else
        MemCheck := True;
end;

procedure AddLine(var P : PItem; S : String; NewLine : boolean);
var
    L, N : PItem;
    W, M, X : integer;
    T : String;
begin
    if not MemCheck(Sizeof(PItem) + Sizeof(String)) then exit;
    L := P^.Items;
    if not Assigned(L) then begin
        L := NewPItem('', psNone);
        P^.Items := L;
    end else begin
        while Assigned(L^.Next) do L := L^.Next;
    end;

    W := Lo(ScreenMax) - Theme.Frame.X * 2 - 3;
    while S <> '' do begin
        T := PtrStr(L^.Title);
        M := W - Length(T);

        if ((LastPos(' ', copy(S, 1, M)) = 0) and (T <> '')) or (M < 1) then begin
            N := NewPItem('', psNone);
            L^.Next := N;
            N^.Prev := L;
            L := N;
        end else begin
            FreeStr(L^.Title);
            if Length(S) < M then
                X := M
            else begin
                X := LastPos(' ', copy(S, 1, M));
                if X = 0 then X := M;
            end;
            L^.Title := StrPtr(T + copy(S, 1, X));
            Delete(S, 1, X);
        end;
    end;

    if NewLine then begin
        N := NewPItem('', psNone);
        L^.Next := N;
        N^.Prev := L;
        L := N;
    end;
end;

procedure CacheGroup(var AGroup : PItem);
var
    Name, Ver, Desc, MD5 : String;
    F : File;
    B : String;
    C : integer;
    X : PItem;
    L : String;
begin
    if not MemCheck(LoMem) then exit;

    if not AGroup^.First then exit;

    AGroup^.First := False;
    if Lang = 'EN' then
        Name := FMedia + TailDelim(AGroup^.Name) + 'INDEX.LST'
    else
        Name := FMedia + TailDelim(AGroup^.Name) + 'INDEX.' + Lang;

    if not FileExists(Name) then exit;

    Assign(F, Name);
    FileMode := 0;
    Reset(F, 1);
    repeat
        SetCritical(AGroup, nil);
        if not MemCheck(LoMem) then exit;
        C := UnixRead(F, B);
        if (C >= 0) and (Trim(B) <> '') then begin
            Name := Trim(PullStr(#$09, B));
            Ver := Trim(PullStr(#$09, B));
            Desc := Trim(PullStr(#$09, B));
            MD5 := Trim(PullStr(#$09, B));
            if (Ucase(Name) = 'FD-REPOV1') and (AGroup^.Title = nil) then begin
                AGroup^.Title := StrPtr(WCase(Desc));
            end;
            X := AGroup^.Items;
            while Assigned(X) do begin
                if (UCase(Name) = UCase(X^.Name)) and (not Assigned(X^.Items)) then begin
                    if Not Assigned(X^.Title) then
                        { X^.Title := StrPtr(Copy(Desc, 1, Lo(ScreenMax) - Theme.Frame.X * 2 - Theme.Grps.X - 16)); }
                        X^.Title := StrPtr(Desc);
                    if Not Assigned(X^.MVersion) then
                        X^.MVersion := StrPtr(Ver);
                    if not Assigned(X^.Items) then begin
                        AddLine(X, Name + ' (' + Ver + ')', True);
                        AddLine(X, '', True);
                        AddLine(X, Desc, C <> 0);
                        while (C = 0) do begin
                            C := UnixRead(F, B);
                            AddLine(X, B, C <> 0);
                        end;
                    end;
                    X := nil;
                end else
                    X := X^.Next;
            end;
        end;
    until (C = -1);
    Close(F);
end;

procedure TryLSM(LSM : string; All : boolean);
var
    F : File;
    S : String;
    C, Pass, LPass, LastLine : integer;
    V : longint;
    Flag, TMode, Appending, HasSummary, HasLang : boolean;
    Title, Version,
    Author, License, X : String;
    M : Integer;
    ISize, IFiles, SSize, SFIles : String;

    procedure Ignore;
    begin
        TMode := False;
    end;

    function Trade(var V : string; S1, S2 : string) : boolean;
    var
        P : integer;
    begin
        P := Pos(ucase(S1), uCase(V));
        if P > 0 then begin
            Delete(V, P, Length(S1));
            Insert(S2, V,  P);
        end;
        Trade := P <> 0;
    end;

    procedure IgnoreEmail(var V : String);
    begin
        TMode := False;
        while Trade(V, #$27, '') do;
        while Trade(V, #$60, '') do;
        while Trade(V, '"', '') do;
        while Trade(V, '  ', ' ') do;
        if Trade(V, ' -at- ', '@') then exit;
        if Trade(V, ' _at_ ', '@') then exit;
        if Trade(V, '-at-', '@') then exit;
        if Trade(V, '_at_', '@') then exit;
        if Trade(V, ' (#) ', '@') then exit;
        if Trade(V, '(#)', '@') then exit;
    end;

    procedure IgnoreVersion;
    begin
        TMode := False;
{        if FileExtension(LSM) = 'TXT' then begin }
        if PathOf(LSM) = TailDelim(PackageInfo) then begin
            FreeStr(Package^.MVersion);
            Package^.MVersion := StrPtr(Trim(Version));
        end else begin
            FreeStr(Package^.IVersion);
            Package^.IVersion := StrPtr(Trim(Version));
        end;
    end;

    procedure IgnoreSummary;
    begin
        HasSummary := True;
        if Pass = 1 then begin
            S := X;
            TMode := true;
            Appending := true;
        end;
    end;

    function Match(T : string; var V : string) : boolean;
    begin
        T := Ucase(Trim(T)) + ':';
        if Pos(T, Ucase(Trim(S))) <> 1 then
            Match := False
        else begin
            Match := True;
            Appending := False;
            V := LTrim(Copy(LTrim(S), Length(T) + 1, Length(S)));
            if V = '-' then V := '';
        end;
    end;

    procedure AddText(var P : PItem; S : String; NewLine : Boolean);
    begin
        if (S = '') and NewLine then
            Inc(LastLine)
        else
            LastLine := 0;
        if (LastLine > 2) then exit;
        AddLine(P, S, NewLine);
    end;

begin

    LPass := 0;
    LastLine := 0;
    Title := NLS(nlsInfoUnknown);
    Version := Title;
    Author := '';
    License := '';
    ISize := '';
    IFiles := '';
    SSize := '';
    SFiles := '';
    HasLang := True;
    While LPass < 2 do begin
        Inc(LPass);
        X := Copy(LSM, 1, LastPos('.', LSM)) + Lang;
        HasLang := FileExists(X);
        if LPass = 1 then begin
            X := LSM;
            if HasLang then
                FreeStr(Package^.Title);
        end;
        {$IFDEF DEBUG}
            Log('TryLSM: ' + X);
        {$ENDIF}
        if not FileExists(X) then Continue;
        if LPass = 1 then
            ClearPackage(Package);
        Assign(F, X);
        FileMode := 0;
        Reset(F, 1);
        Pass := 0;
        Appending := False;
        HasSummary := False;
        While Pass < 2 do begin
            {$IFDEF DEBUG}
            Log('PASS: ' + IntStr(Pass));
            {$ENDIF}
            Flag := False;
            TMode := False;
            Seek(F, 0);
            repeat
                C := UnixRead(F, S);
                if Trim(Ucase(S)) = 'END' then begin
                    C := -1;
                    TMode := False;
                end else
                if Trim(Ucase(S)) = 'BEGIN3' then begin
                    Flag := True;
                    TMode := False;
                end else
                if Match('TITLE', Title) then Ignore else
                if Match('Version', Version) then IgnoreVersion else
                if Match('Author', Author) then IgnoreEmail(Author) else
                if Match('copying-policy', License) then Ignore else
                if Match('copying_policy', License) then Ignore else
                if Match('Total-size', ISize) then Ignore else
                if Match('Total-files', IFiles) then Ignore else
                if Match('Source-size', SSize) then Ignore else
                if Match('Source-files', SFiles) then Ignore else

                if Match('Maintained-by', X) then Ignore else
                if Match('entered-date', X) then Ignore else
                if Match('Platforms', X) then Ignore else
                if Match('keywords', X) then Ignore else
                if Match('Primary-site', X) then Ignore else
                if Match('Alternate-site', X) then Ignore else
                if Match('Changes', X) then Ignore else

                if HasLang and (LPass = 1) then begin
                    TMode := False;
                    {FreeStr(Package^.Title);}
                end else

                if Match('Summary', X) then IgnoreSummary else

                if Flag and (C > -1) and (S <> '') and (Pass = 1) then begin
                    if Match('description', X) then begin
                        { AddText(Package, IntStr(LPass) + ':' +IntStr(Pass) + '- ' + PtrStr(Package^.Title), True); }
                        if (PtrStr(Package^.Title) = '') then
{                            Package^.Title := StrPtr(Copy(X, 1, Lo(ScreenMax) - Theme.Frame.X * 2 - Theme.Grps.X - 16)); }
                             Package^.Title := StrPtr(X);
                        S := X;
                        TMode := not HasSummary;
                        Appending := true;
                    end else if (Copy(S, 1, 2) = '  ') then
                        S := LTrim(S)
                    else begin
                        if Appending then AddText(Package, '', True);
                    end;
                end;
                repeat
                    if TMode then AddText(Package, S, Not Appending);
                    if (C = 0) then
                        C := UnixRead(F, S)
                    else
                        S := '';
                until (C <> 0) and (S = '');
            until C = -1;
            if HasLang and (LPass = 1) then begin
               Inc(Pass);
               Continue;
            end;
            if Appending then AddText(Package, '', True);
            if Pass = 0 then begin
               if (Not FDIMode) and Assigned(Package^.IVersion) and Assigned(Package^.MVersion) and
                (Ucase(PtrStr(Package^.IVersion)) <> Ucase(PtrStr(Package^.MVersion))) then
                    AddText(Package, Title + ' (' + PtrStr(Package^.MVersion)  + ', ' +
                    PtrStr(Package^.IVersion) + ' ' + NLS(nlsInfoInstalled) + ')', True)
                else
                    AddText(Package, Title + ' (' + Version + ')', True);
                if Author <> '' then
                    AddText(Package, Author, True);
                if License <> '' then
                    AddText(Package, License, True);
                AddText(Package, '', True);
            end;
            if (Pass = 1) and (PtrStr(Package^.Title) = '') then
                Package^.Title := StrPtr(Copy(Title, 1, Lo(ScreenMax) - Theme.Frame.X * 2 - Theme.Grps.X - 16));
            if (Pass = 1) and (ISize <> '') then begin
                AddText(Package, '', True);
                X := '';
                { if not FDIMODE then begin }
                    if IFiles <> '' then begin
                        V := StrInt(IFiles) - StrInt(SFiles);
                        X := Comma(IntStr(V)) + ' ' + PluralNLS(V, nlsInfoFile) + ' (';
                    end;
                    V := StrInt(trim(ISize)) - StrInt(trim(SSize));
                    M := nlsInfoByte;
                    if V > 10239 then begin
                        M := nlsInfoKByte;
                        V := V div 1024;
                        if V > 5119 then begin
                            M := nlsInfoMByte;
                            V := V div 1024;
                        end;
                    end;
                    X := X + Comma(IntStr(V)) + ' ' + PluralNLS(V, M) + ')';
                    if (SFIles <> '') and ((not FDIMode) or (ucase(GetEnv('OSRC')) <> 'N')) then begin
                        X := X  + '; ';
                        V := StrInt(SFiles);
                        X := X + Comma(IntStr(V)) + ' ' + PluralNLS(V, nlsInfoSourceFile) + ' (';
                        V := StrInt(trim(SSize));
                        M := nlsInfoByte;
                        if V > 10239 then begin
                            M := nlsInfoKByte;
                            V := V div 1024;
                            if V > 5119 then begin
                                M := nlsInfoMByte;
                                V := V div 1024;
                            end;
                        end;
                        X := X + Comma(IntStr(V)) + ' ' + PluralNLS(V, M) + ')';
                    end;
                AddText(Package, '', True);
                if Package^.Locked then begin
                    if X <> '' then X := X + ', ';
                    X := X + NLS(nlsInfoLocked);
                end;
                AddText(Package, X { + ':' + IFiles + '/' + ISize + ',' + SFiles + '/' + SSize }, True);
            end;

            Inc(Pass);
        end;
        Close(F)
    end;

end;

function TryLST(LST : string; All : boolean) : integer;
var
    F : File;
    S : String;
    C, X : integer;
    Flag : boolean;
begin
    {$IFDEF DEBUG}
    Log('TryLST: ' + LST);
    {$ENDIF}
    TryLST := 0;
    if not FileExists(LST) then exit;
    Assign(F, LST);
    FileMode := 0;
    Reset(F, 1);
    Flag := True;
    X := 0;
    repeat
        C := UnixRead(F, S);
        if Trim(Ucase(S)) = 'END' then
            Flag := True
        else
        if Trim(Ucase(S)) = 'BEGIN3' then
            Flag := False
        else
        if Flag and (C > -1) and (S<>'') then begin
            if X = 0 then
                AddLine(Package, ' ' + ChrStr(#$c4, Lo(ScreenMax) - Theme.Frame.X * 2 - 5), true);
            AddLine(Package, lcase(S), C <> 0);
            Inc(X);
        end
    until (C = -1) or Keypressed;
    Close(F);
    if Keypressed then begin
        Package^.Skipped := true;
        ResetIdler;
    end;
    TryLST := X;
end;

procedure SearchForData(All:boolean);
var
     FN : String;
begin
    if Group^.Name = '' then begin
        TryLSM(TailDelim(GetEnv('DOSDIR')) + TailDelim('APPINFO') + Package^.Name + '.LSM', All);
        if (All and Assigned(Package^.Items)) and FileList then
            TryLST(TailDelim(GetEnv('DOSDIR')) + TailDelim('PACKAGES') + Package^.Name + '.LST', All);
    end else begin
        if (not Assigned(Package^.IVersion)) and (not FDIMode) then
            TryLSM(TailDelim(GetEnv('DOSDIR')) + TailDelim('APPINFO') + Package^.Name + '.LSM', false);
{        FN := TailDelim(PackageInfo) + Package^.Name + '.TXT'; }
        FN := TailDelim(PackageInfo) + Package^.Name + '.LSM';
        TryLSM(FN, All);
        if (All and Assigned(Package^.Items)) and FileList then begin
            if TryLST(FN, All) = 0 then
                TryLST(TailDelim(PackageInfo) + Package^.Name + '.LST', All);
        end
    end;
end;

function IsMediaDrive(S : String) : boolean;
begin
    IsMediaDrive := False;
    S := TailDelim(S);
    if DirExists(S) and
    FileExists(TailDelim(S + 'BASE') + 'COMMAND.ZIP') or
    FileExists(TailDelim(S + 'BASE') + 'KERNEL.ZIP') then begin
        FMedia := S;
        IsMediaDrive := True;
    end;
end;

function ReadCfg : string;
var
  F : text;
  T : String;
begin
    ReadCfg := '';
    if not FileExists(TailDelim(GetExePath) + GetExeBase + '.DAT') then exit;
    assign(F, TailDelim(GetExePath) + GetExeBase + '.DAT');
    FileMode := 0;
    Reset(F);
    while Not eof(F) do begin
        ReadLn(F, T);
        T := Trim(T);
        if T <> '' then ReadCfg := T;
    end;
    Close(F);
end;

procedure VerifyGroupState;
var
    P : PItem;
    NS, FS, US, RS, ES : integer;
begin
    P := Group^.Items;
    NS := 0;
    FS := 0;
    US := 0;
    RS := 0;
    ES := 0;
    while Assigned(P) do begin
         case P^.State of
            psNone    : Inc(NS);
            psFull    : Inc(FS);
            psUpgrade : Inc(US);
            psReplace : Inc(RS);
            psExtra   : Inc(ES);
         end;
        P := P^.Next;
    end;
    if (FS = 0) and (US = 0) and (RS = 0) and (ES = 0) then
        Group^.State := psNone
    else if (NS = 0) and (US = 0) and (RS = 0) and (ES = 0) then
        Group^.State := psFull
    else if (NS = 0) and (FS = 0) and (RS = 0) and (ES = 0) then
        Group^.State := psUpgrade
    else if (NS = 0) and (FS = 0) and (US = 0) and (ES = 0) then
        Group^.State := psReplace
    else if (NS = 0) and (FS = 0) and (RS = 0) and (US = 0) then
        Group^.State := psExtra
    else
        Group^.State := psPartial;
end;

procedure CacheGroupInitial;
begin
    if Assigned(Group) and (Group^.First) then begin
        CacheGroup(Group);
        Package := Group^.Items;
        while Assigned(Package) do begin
            if Not Assigned(Package^.Items) then
                SearchForData(False);
            Package := Package^.Next;
        end;
{        VerifyGroupState; }
    end;
end;

procedure Init;
var
   S : TSearchRec;
   P, J, Others : PItem;
   CS : integer;
   T, M : String;
   PlsWait:String;

begin
    PackageManager := 'FDINST.EXE';
    T := GetEnv('PATH') + ';' + TailDelim(GetEnv('DOSDIR')) + 'BIN';
    while T <> '' do begin
        M := PullStr(';', T);
        if FileExists(TailDelim(M) + PackageManager) then begin
            PackageManager := TailDelim(M) + PackageManager;
            T := '';
        end;
    end;

    StatPhase := -1;

    PackageInfo := '';
    PlsWait := NLS(nlsPleaseStandby);
    if Trim(GetEnv('FMEDIA')) <> '' then begin
        FMedia := TailDelim(Dir(Trim(GetEnv('FMEDIA'))));
    end;

    if not FDIMode then begin
        if (FMedia <> '') and (not DirExists(FMedia)) then FMedia := '';
        if Not FileExists(PackageManager) then begin
            WriteLn(NLS(nlsNoFDINST));
            Halt(100);
        end;
        if (GetEnv('TEMP') = '') or (not DirExists(GetEnv('TEMP'))) then begin
            WriteLn(NLS(nlsNoTemp));
            Halt(2);
        end;
        HideCursor;
        WriteRawPStr(PlsWait);
        M := ucase(trim(ReadCfg));
        GetDir(0, T);
        if (FMEDIA = '') and (M <> '') then IsMediaDrive(Copy(T,1,2) + M);
        if FMEDIA = '' then IsMediaDrive(Copy(T,1,3));
        if FMEDIA = '' then IsMediaDrive(Copy(T,1,3) + 'PACKAGES');
        if FMEDIA = '' then IsMediaDrive(Copy(T,1,3) + 'FDSETUP\PACKAGES');
        if FMEDIA = '' then IsMediaDrive(T);

        if FMedia = '' then
            for CS := 0 to 24 do begin
            if (M <> '') and IsMediaDrive(Chr(CS + 67) + ':' + M) then Break;
            if IsMediaDrive(Chr(CS + 67) + ':\') then Break;
            if IsMediaDrive(Chr(CS + 67) + ':\PACKAGES') then Break;
            if IsMediaDrive(Chr(CS + 67) + ':\FDSETUP\PACKAGES') then Break;
        end;
    end else begin
    if FMedia = '' then
        FMedia := Dir('\');
    end;

    PackageInfo := TailDelim(FMEDIA) + TailDelim('..') + NoTailDelim('PKGINFO');
    while (Copy(PackageInfo, 3, 3) = '\..') do Delete(PackageInfo, 3, 3);
    if not DirExists(PackageInfo) then begin
        PackageInfo := TailDelim(FMEDIA) + TailDelim('..') + NoTailDelim('PKG_INFO');
        while (Copy(PackageInfo, 3, 3) = '\..') do Delete(PackageInfo, 3, 3);
    end;
    if not DirExists(PackageInfo) then begin
        PackageInfo := TailDelim(FMEDIA) + TailDelim('..') + NoTailDelim('PKG-INFO');
        while (Copy(PackageInfo, 3, 3) = '\..') do Delete(PackageInfo, 3, 3);
    end;

    if (not FDIMode) and (FMedia = '') then begin
        GotoXY (1, WhereY);
        WriteLn(NLS(nlsPackageMediaNotFound));
        WriteRawPStr(PlsWait);
    end;

    ReadDefaults;
    Tab := 0;
    Group := nil;
    Others := NewPItem('', psFull);
    GroupFirst := Others;
    GroupLast := GroupFirst;

{ No Longer needed Startup sets all group names for language. }

{    with GroupFirst^ do begin
        Title := StrPtr(NLS(nlsInstalledOnly));
    end;
}

    FindFirst(FMedia + '*.*', faAnyFile, S);
    while DosError = 0 do begin
        if (S.Attr and faDirectory = faDirectory) and (S.Name <> '.') and
        (S.Name <> '..') then begin
            P := NewPItem(S.Name, psNone);
            P^.Prev := GroupLast;
            GroupLast^.Next := P;
            GroupLast := P;
        end;
        FindNext(S);
    end;

    SortList(GroupFirst, GroupLast);
    P := GroupFirst;
    while Assigned(P) do begin
        PackageFirst := nil;
        PackageLast := nil;

        {
        AddCustomItems(P, 'BASE', 'WELCOME');
        AddCustomItems(P, 'UTIL', 'V8POWER');
        }

        if P^.NAME <> '' then begin
            StandBy;
            FindFirst(FMedia + TailDelim(P^.NAME) + '*.ZIP', faAnyFile, S);

            while DosError = 0 do begin
                if (S.Attr and (faDirectory or faSystem or faHidden) = 0) and
                (S.Name <> '.') then begin
                    J := NewPItem(Copy(S.Name, 1, Length(S.Name) - 4), psNone);
                    J^.Locked := LockPackage(J^.Name);
                    J^.Prev := PackageLast;
                    if (RunMode = rmList) or (RunMode = rmConfig) then begin
                        J^.State := GetPkgState(Ucase(TailDelim(P^.Name)) + Ucase(J^.Name));
                    end else
                    if CheckDefault(Ucase(TailDelim(P^.Name)) + Ucase(J^.Name)) then begin
                        J^.State := psFull;
                    end;
                    if not Assigned(PackageFirst) then
                        PackageFirst := J
                    else
                        PackageLast^.Next := J;
                    PackageLast := J;
                end;
                FindNext(S);
            end;
        end;
        P^.Items := PackageFirst;
        P := P^.Next;
    end;

    if (RunMode = rmStandAlone) then
        AddInstalled(Others);

    P := GroupFirst;
    while Assigned(P) do begin
        J := P;
        P := P^.Next;
        PackageFirst := J^.Items;
        if Assigned(PackageFirst) then begin
            PackageLast := PackageFirst;
            while Assigned(PackageLast^.Next) do
                PackageLast := PackageLast^.Next;
            SortList(PackageFirst, PackageLast);
            J^.Items := PackageFirst;
        end else begin
            if Assigned(J^.Prev) then
                J^.Prev^.Next := J^.Next
            else
                GroupFirst := J^.Next;
            if Assigned(J^.Next) then
                J^.Next^.Prev := J^.Prev
            else
                GroupLast := J^.Prev;
            Dispose(J);
        end;
    end;

    Group := GroupFirst;

    While Assigned(Group) do begin
        VerifyGroupState;
        Group := Group^.Next;
    end;

    Group := GroupFirst;

    CacheGroupInitial;

    GroupTop := GroupFirst;
    GroupBottom := nil;
    Package := nil;
    PackageFirst := nil;
    PackageTop := nil;
    PackageLast := nil;
    PackageBottom := nil;
    LineTop := nil;
    LineBottom := nil;
end;

procedure FetchData;
begin
    SearchForData(true);
    if Not Assigned(Package^.Items) then begin
        Group^.First := True;
        FreeSomeMem(20);
        CacheGroup(Group);
    end;
    Package^.First := False;
end;

function ChangeGroupTitles : integer;
var
    P : PItem;
    S : String;
    X : integer;
begin
    P := Group;
    X := 8;
    while Assigned(P) do begin
        S := GetGroup(P^.Name);
        if Length(S) > X then
            X := Length(S);
        if S <> '' then begin
            FreeStr(P^.Title);
            P^.Title := StrPtr(S);
        end;
        P := P^.Next;
    end;
    ChangeGroupTitles := X;
end;

procedure DrawPackage;
var
    Y : integer;
    P : PItem;
    D : PText;
    T : boolean;
begin
    TextColor(Theme.Fore);
    TextBackground(Theme.Back);
    if Tab = 2 then begin
        TextColor(Theme.TextHot);
    end else begin
        TextColor(Theme.Text);
    end;
    Window (Theme.Frame.X + 2, Theme.Frame.Y + Theme.Grps.Y + 2,
    Lo(ScreenMax) - Theme.Frame.X, Hi(ScreenMax)- Theme.Frame.Y + 1);
    LineBottom := nil;
    if Assigned(Package) then begin
        if (Package^.First) or (not Assigned(Package^.Items)) then begin
            FetchData;
        end;

        if not Assigned(Package^.Items) then begin
            if not Package^.Skipped then
                WriteRawPStr(RSpace(' ' + Package^.Name + ' - ' + NLS(nlsInfoNoInfo),
            Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
            ClrEol;
        end else begin
            P := Package^.Items;
            Y := 1;
            if Assigned(LineTop) then P := LineTop;
            LineTop := P;
            T := False;
            if Assigned(P) then begin
                if (P^.Prev = Package^.Items) then T := True;
                if Assigned(P^.Prev) and (P^.Prev^.Prev = Package^.Items) then T := True;
            end;
            while Assigned(P) and (Y <= Hi(WindMax) - Hi(WindMin) + 1)  do begin
                if PtrStr(P^.Title) = '' then T := False;
                if P = Package^.Items then begin
                    T := True;
                    TextColor(Theme.NameHot);
                    if Tab <> 2 then TextColor(Theme.Name);
                end else if T then begin
                    TextColor(Theme.AuthorHot);
                    if Tab <> 2 then TextColor(Theme.Author);
                end else begin
                    TextColor(Theme.TextHot);
                    if Tab <> 2 then TextColor(Theme.Text);
                end;
                if Pos(ChrStr(#$c4, 10), PtrStr(P^.Title)) > 0 then begin
                    Window (Theme.Frame.X + 2, Theme.Frame.Y + Theme.Grps.Y + 2,
                    Lo(ScreenMax) - Theme.Frame.X + 1, Hi(ScreenMax)- Theme.Frame.Y + 1);
                    if Tab <> 2 then TextColor(Theme.Bar) else TextColor(Theme.BarHot);
                    GotoXY(2,Y);
                    DrawLine(1, Y, Lo(WindMax) - Lo(WindMin), lnSingle or lnHorizontal);
                    Window (Theme.Frame.X + 2, Theme.Frame.Y + Theme.Grps.Y + 2,
                    Lo(ScreenMax) - Theme.Frame.X, Hi(ScreenMax)- Theme.Frame.Y + 1);
                    GotoXY(1,Y);
                end else begin
                    GotoXY(1,Y);
                    WriteRawPStr(#32 + PtrStr(P^.Title));
                    ClrEol;
                end;
                Inc(Y);
                LineBottom := P;
                P := P^.Next;
            end;
        end;
    end;
    while WhereY < (Hi(WindMax) - Hi(WindMin) + 1) do begin
        GotoXY(1,WhereY + 1);
        ClrEol;
    end;
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
end;

procedure DrawFiles;
var
    P : PItem;
    Y : integer;
    S : String;
begin
    TextColor(Theme.Fore);
    TextBackground(Theme.Back);
    Window (Theme.Frame.X + 4 + Theme.Grps.X - NoScroll, Theme.Frame.Y + 1,
    Lo(ScreenMax) - Theme.Frame.X, Theme.Frame.Y + Theme.Grps.Y);
    if not Assigned(Group) then exit;
    { ClrScr; }
    if not Assigned(PackageFirst) then begin
        Package := Group^.Items;
        PackageFirst := Package;
        PackageTop := Package;
        PackageLast := Package;
        while Assigned(PackageLast^.Next) do
            PackageLast := PackageLast^.Next;
    end;
    P := PackageTop;
    PackageBottom := nil;
    Y := 1;
    while Assigned(P) and (Y <= Theme.Grps.Y) do begin
        GotoXY(1,Y);
        TextBackground(Theme.Back);
        if P <> Package then
            TextColor(Theme.Fore)
        else begin
            if Tab <> 1 then
                TextColor(Theme.Hot)
            else
                TextAttr := Theme.Choose;
        end;
        WriteRawPStr(' ');
        if P <> Package then TextColor(Theme.Brace);
        WriteRawPStr('[');
        if P <> Package then TextColor(Theme.Checks[P^.State]);
        WriteRawPStr(CheckMark[P^.State]);
        if P <> Package then TextColor(Theme.Brace);
        WriteRawPStr(']');
        if P <> Package then
            TextColor(Theme.Fore)
        else begin
            if Tab <> 1 then
                TextColor(Theme.Hot)
            else
                TextAttr := Theme.Choose;
        end;
        S := P^.Name;
        if Assigned(P^.Title) then
            S := Trim(Copy(RSpace(P^.Name, 9) + ' ' + PtrStr(P^.Title), 1,
            Lo(WindMax) - Lo(WindMin) - WhereX + NoScroll));
        WriteRawPStr(RSpace(' ' + S, Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
        PackageBottom := P;
        P := P^.Next;
        Inc(Y);
    end;
    TextColor(Theme.Fore);
    TextBackground(Theme.Back);
    while (Y <= Theme.Grps.Y) do begin
        WriteRawPStr(RSpace('', Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
        Inc(Y);
    end;
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    LineTop := nil;
    LineBottom := nil;
    DrawPackage;
end;

procedure DrawGroups;
var
    P : PItem;
    Y : integer;
    S : String;
begin
    TextColor(Theme.Fore);
    TextBackground(Theme.Back + 1);
    Window (Theme.Frame.X + 2, Theme.Frame.Y + 1, Theme.Frame.X + 2 - NoScroll + Theme.Grps.X,
    Theme.Frame.Y + Theme.Grps.Y);
    { ClrScr; }
    P := GroupTop;
    Y := 1;
    GroupBottom := nil;
    if Assigned(Group) and (Group^.First) then CacheGroup(Group);
    while Assigned(P) and (Y <= Theme.Grps.Y) do begin
        GotoXY(1,Y);
        TextBackground(Theme.Back);
        if P <> Group then
            TextColor(Theme.Fore)
        else begin
            if Tab <> 0 then
                TextColor(Theme.Hot)
            else
                TextAttr := Theme.Choose;
        end;
        WriteRawPStr(' ');
        if P <> Group then TextColor(Theme.Brace);
        WriteRawPStr('[');
        if P <> Group then TextColor(Theme.Checks[P^.State]);
        WriteRawPStr(CheckMark[P^.State]);
        if P <> Group then TextColor(Theme.Brace);
        WriteRawPStr(']');
        if P <> Group then TextColor(Theme.Fore);
        S := P^.Name;
        if Assigned(P^.Title) then S := PtrStr(P^.Title);
        S := Trim(Copy(S , 1, Lo(WindMax) - Lo(WindMin) - WhereX + NoScroll));
        WriteRawPStr(RSpace(' ' + S, Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
        GroupBottom := P;
        P := P^.Next;
        Inc(Y);
    end;
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    DrawFiles;
end;

procedure DrawOKCancel(TabPos, TabFirst, HotAttr : integer );
var
    W, A : integer;
begin
    W := Length(NLS(nlsButtonOK));
    if W < Length(NLS(nlsButtonCancel)) then
        W := Length(NLS(nlsButtonCancel));
    W := W + 4;
    Gotoxy (WhereX - W * 2 , WhereY);
    A := TextAttr;
    if TabPos = TabFirst then
        TextAttr := HotAttr;
    WriteRawPStr( CSpace(NLS(nlsButtonOK), W));
    GotoXY (WhereX + 5, WhereY);
    TextAttr := A;
    if TabPos = TabFirst + 1 then
        TextAttr := HotAttr;
    WriteRawPStr( CSpace(NLS(nlsButtonCancel), W));
    TextAttr := A;
end;

procedure DrawButtons;
begin
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    Gotoxy (Lo(ScreenMax) - Theme.Frame.X - 5, Hi(ScreenMax)- Theme.Frame.Y + 1);
    TextColor(Theme.Fore);
    TextBackground(Theme.Back);
    DrawOKCancel(Tab, 3, Theme.Choose);
end;

procedure DrawMainBox;
begin
    { Back Drop }
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    TextAttr := Theme.FillAttr;
    (*TextChar := Theme.FillChar; *)
    ClrScr;
    { Window Box }
    (*TextChar := #32; *)
    TextAttr := Theme.Border;
    Window(Theme.Frame.X, Theme.Frame.Y, Lo(ScreenMax) + 2 - Theme.Frame.X, Hi(ScreenMax) + 2 - Theme.Frame.Y);
    ClrScr;
    Window(1,1,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    if Theme.Double then
        DrawBox(Theme.Frame.X + 1, Theme.Frame.Y, Lo(ScreenMax) + 1 - Theme.Frame.X,
        Hi(ScreenMax) + 2 - Theme.Frame.Y, bxDouble);
    if not Theme.Double then
        DrawBox(Theme.Frame.X + 1, Theme.Frame.Y, Lo(ScreenMax) + 1 - Theme.Frame.X,
        Hi(ScreenMax) + 2 - Theme.Frame.Y, bxSingle);
end;

procedure DrawSelector;
begin
    DrawMainBox;
    DrawLine(Theme.Frame.X + 1, Theme.Frame.Y + Theme.Grps.Y + 1, Lo(ScreenMax) - Theme.Frame.X * 2 + 1,
    lnSingle or lnHorizontal);
    DrawLine(Theme.Frame.X + Theme.Grps.X + 3 - NoScroll, Theme.Frame.Y, Theme.Grps.Y + 2,
    lnSingle or lnVertical);
    if Theme.Shadow then
        DrawShadow(Theme.Frame.X + 1, Theme.Frame.Y, Lo(ScreenMax) + 2 - Theme.Frame.X,
        Hi(ScreenMax) + 2 - Theme.Frame.Y, bsDoubleWide);
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
end;

procedure DrawTitle;
begin
    if FDIMode then exit;
    Window(1, 1, Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    TextAttr := Theme.Title;
    GotoXY(1,1);
    ClrEol;
    GotoXY(40 - (Length(AppTitle + ' ' + AppVersion + ' ()' + AppName ) div 2), 1);
    WriteRawPStr(AppTitle + ' ');
    TextAttr := Theme.TitleHot;
    WriteRawPStr(AppVersion);
    TextAttr := Theme.Title;
    WriteRawPStr(' (' + AppName + ')');
end;

procedure StatusPhaseZero;
begin
    if Lo(ScreenMax) >= 79 then begin
        if MaxAvail < LoMem then TextAttr := Theme.StatusHot;
        WriteRawPStr(' ' + IntStr(MaxAvail));
        TextAttr := Theme.Status;
        WriteRawPStr('/');
        if MemAvail < LoMem then TextAttr := Theme.StatusHot;
        WriteRawPStr(IntStr(MemAvail)+ ' ');
        TextAttr := Theme.Status;
    end;
    if Not Assigned(Group) then begin
        WriteRawPStr(NoTailDelim(FMedia));
    end else begin
        if Group^.Name <> '' then begin
            WriteRawPStr(Copy(TailDelim(FMedia) + TailDelim(Group^.Name), 1, Lo(ScreenMax) + 1 - WhereX));
            if Assigned(Package) then
                WriteRawPStr(Copy(Package^.Name + '.ZIP', 1, Lo(ScreenMax) + 1 - WhereX));
        end else if FMedia = '' then begin
            TextAttr := Theme.StatusErr;
            WriteRawPStr(NLS(nlsPackageMediaNotFound));
            TextAttr := Theme.StatusHot;
            WriteRawPStr(' ' + NLS(nlsOnlyInstalledShown) );
            TextAttr := Theme.Status;
        end else begin
            if Assigned(Package) then begin
                WriteRawPStr( NLS(nlsBarPackage) + ' ');
                TextAttr := Theme.StatusHot;
                WriteRawPStr(Package^.Name);
                TextAttr := Theme.Status;
                WriteRawPStr(Copy(' ' + NLS(nlsBarNotFound) + ' ', 1, Lo(ScreenMax) + 1 - WhereX) );
                TextAttr := Theme.StatusHot;
                WriteRawPStr(Copy(NoTailDelim(FMedia), 1, Lo(ScreenMax) + 1 - WhereX));
                TextAttr := Theme.Status;
            end;
        end;
    end;
end;

procedure StatusPhaseOne;
begin
    WriteRawPStr(' ' + NLS(nlsGroup) + ' ');
    TextAttr:=Theme.StatusHot;
    WriteRawPStr(Copy(PtrStr(Group^.Title), TickerA, Lo(ScreenMax) + 1 - WhereX));

end;

procedure StatusPhaseTwo;
var
    X : integer;
begin
    WriteRawPStr(' ' + NLS(nlsPackage) + ' ');
    TextAttr:=Theme.StatusHot;
    X := Lo(ScreenMax) + 1 - WhereX;
    WriteRawPStr(Copy(PtrStr(Package^.Title), TickerB, X));
    if (X < Length(PtrStr(Package^.Title))) or (TickerB <> 1) then begin
        if TickerB > Length(PtrStr(Package^.Title)) then
            X := TickerB - Length(PtrStr(Package^.Title))
        else
            X := 1;
        WriteRawPStr(Copy(' | ' + PtrStr(Package^.Title), X, Lo(ScreenMax) + 1 - WhereX));
        Inc(TickerB);
        if TickerB > Length(PtrStr(Package^.Title)) + 3 then
            TickerB := 1;
    end;
end;

procedure DrawStatus(ATab : integer);
var
    Max : Integer;
begin
    if FDIMode then Exit;

    { Standby Tick Reset }
    LastTick := TimerTick;
    TickCount := 0;
    if (ATab <> -1)  then begin
        StatPhase := ATab;
        StatCount := 0;
        TickerA := 1;
        TickerB := 1;
        StatTick := TimerTick;
    end else if StatTick = TimerTick then
        exit
    else begin
        StatTick := TimerTick;
        Inc(StatCount);
        Max := StatSpeed;
        case StatPhase of
                0: if TickerA <> 1 then Max := Max * TickGrpLag;
                1: if TickerB <> 1 then Max := Max * TickPkgLag;
        end;
        if StatCount < Max then begin
            if StatCount mod TickerMod <> 0 then exit;
            case StatPhase of
                0: if TickerA = 1 then Exit;
                1: if TickerB = 1 then Exit;
            else
                Exit
            end;
        end else begin
            StatCount:=0;
            Inc(StatPhase);
            if StatPhase > 2 then StatPhase := 0;
        end;
    end;

    if (StatPhase = 0) and (not Assigned(Group)) then StatPhase:=2;
    if (StatPhase = 1) and (not Assigned(Package)) then StatPhase:=2;

    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    gotoXY(1,Hi(WindMax));
    TextAttr := Theme.Status;

    case StatPhase of
        0:StatusPhaseOne;
        1:StatusPhaseTwo;
    else
        StatusPhaseZero;
    end;

    if StatPhase > 2 then StatPhase := 0;

    ClrEol;
end;

procedure GroupToggle;
var
    P : PItem;
begin
    if not Assigned(Group) then exit;
    if (RunMode = rmList) or (RunMode = rmConfig) then begin
        case Group^.State of
            psNone : Group^.State := psBase;
            psBase : Group^.State := psAll;
            psAll  : begin
                if RunMode = rmConfig then
                    Group^.State := psNone
                else
                    Group^.State := psExtra;
            end
        else
            Group^.State := psNone;
        end;
    end else begin
        if Group^.State = psFull then
            Group^.State := psNone
        else
            Group^.State := psFull;
    end;
    P := Group^.Items;
    while Assigned(P) do begin
        StandBy;
        if (Group^.State <> psNone) or (not P^.Locked) then
            P^.State := Group^.State;
        P := P^.Next;
    end;
    VerifyGroupState;
    DrawGroups;
end;

procedure FileToggle;
begin
    if not Assigned(Package) then exit;
    if (RunMode = rmList) or (RunMode = rmConfig) then begin
        case Package^.State of
            psNone : Package^.State := psBase;
            psBase : Package^.State := psAll;
            psAll  : begin
                if RunMode = rmConfig then
                    Package^.State := psNone
                else
                    Package^.State := psExtra;
            end
        else
            Package^.State := psNone;
        end;
    end else
    if (not Package^.Locked) then begin
        if Package^.State = psNone then
            Package^.State := psFull
        else if (Package^.State = psFull) and
        Assigned(Package^.IVersion) and Assigned(Package^.MVersion) and
        (Ucase(PtrStr(Package^.IVersion)) <> UCase(PtrStr(Package^.MVersion))) and
        (RunMode = rmStandAlone) then begin
            if (UCase(PtrStr(Package^.IVersion)) < UCase(PtrStr(Package^.MVersion))) then
                Package^.State := psUpgrade
            else
                Package^.State := psReplace
        end else
            Package^.State := psNone;
    end;
    VerifyGroupState;
    DrawGroups;
end;

procedure UpdateToggle(All : boolean);
var
    P, G : PItem;
begin
    UpdateOn := not UpdateOn;
    G := Group;
    P := Package;
    if All then Group := GroupFirst;
    while Assigned(Group) do begin
        Package := Group^.Items;
        while Assigned(Package) do begin
            StandBy;
            if Package^.Tested = False then SearchForData(false);
            Package^.Tested := True;
            if Assigned(Package^.IVersion) and Assigned(Package^.MVersion) and
            (Package^.State <> psReplace) and (Package^.Locked = false) and
            (Ucase(PtrStr(Package^.IVersion)) <> UCase(PtrStr(Package^.MVersion))) then
                case UpdateOn of
                    False : Package^.State := psFull;
                    True : begin
                        if (Ucase(PtrStr(Package^.IVersion)) < UCase(PtrStr(Package^.MVersion))) then
                            Package^.State := psUpgrade
                        else
                            Package^.State := psFull;
                    end;
                end;
            Package := Package^.Next;
        end;
        VerifyGroupState;
        if All then
            Group := Group^.Next
        else
            Group := nil;
    end;
    Group := G;
    Package := P;
    DrawGroups;
end;

procedure GroupUp(T:integer);
begin
    While (T > 0) and (Group <> GroupFirst) do begin
        Dec(T);
        if GroupTop = Group then begin
            GroupTop := GroupTop^.Prev;
            GroupBottom := GroupBottom^.Prev;
        end;
        Group := Group^.Prev;
    end;
    PackageFirst := nil;
    DrawGroups;
end;

procedure GroupDown(T:integer);
begin
    While (T > 0) and (Group <> GroupLast) do begin
        Dec(T);
        if GroupBottom = Group then begin
            GroupTop := GroupTop^.Next;
            GroupBottom := GroupBottom^.Next;
        end;
        Group := Group^.Next;
    end;
    CacheGroupInitial;
    PackageFirst := nil;
    DrawGroups;
end;

procedure FileUp(T:integer);
begin
    While (T > 0) and (Package <> PackageFirst) do begin
        Dec(T);
        if PackageTop = Package then begin
            PackageTop := PackageTop^.Prev;
            PackageBottom := PackageBottom^.Prev;
        end;
        Package := Package^.Prev;
    end;
    DrawFiles;
end;

procedure FileDown(T:integer);
begin
    While (T > 0) and (Package <> PackageLast) do begin
        Dec(T);
        if PackageBottom = Package then begin
            PackageTop := PackageTop^.Next;
            PackageBottom := PackageBottom^.Next;
        end;
        Package := Package^.Next;
    end;
    DrawFiles;
end;

procedure TextUp(T:integer);
begin
    if not Assigned(LineTop) then exit;
    While (T > 0) and Assigned(LineTop^.Prev) do begin
        Dec(T);
        LineTop := LineTop^.Prev;
    end;
    DrawPackage;
end;

procedure TextDown(T:integer);
begin
    if not Assigned(LineBottom) then exit;
    While (T > 0) and Assigned(LineBottom^.Next) do begin
        Dec(T);
        LineTop := LineTop^.Next;
        LineBottom := LineBottom^.Next;
    end;
    DrawPackage;
end;

procedure MakeList(Name : string; State : TStates; Additional : boolean);
var
    P, J : PItem;
    F : Text;
    S : String;
begin
    FileMode := 2;
    Assign(F, Name);
    if FileExists(Name) and Additional and (State <> psBase) then
        Append(F)
    else
        Rewrite(F);
    if Additional then begin
        if (State = psBase) then begin
            WriteLn(F, '; FreeDOS Installer Package List File');
        end;
        WriteLn(F);
        case State of
            psBase  : WriteLn(F, '; BASE Packages');
            psAll   : WriteLn(F, '; ALL Packages');
            psExtra : WriteLn(F, '; EXTRA Packages');
        end;
        WriteLn(F);
    end;
    P := GroupFirst;
    while Assigned(P) do begin
        J := P^.Items;
        while Assigned(J) do begin
            if J^.State = State then begin
                if Comments and (PtrStr(J^.Title) <> '') then begin
                    WriteLn(F, '; ', RSpace(J^.NAME, 12), #32,
                    RSpace(Copy(PtrStr(J^.MVersion),1,20), 20), #32,
                    PtrStr(J^.Title));
                end;
                WriteLn(F, lcase(P^.Name + PathDelim + J^.Name));
                if Comments and (PtrStr(J^.Title) <> '') then begin
                    WriteLn(F);
                end;
            end;
            J := J^.Next;
        end;
        P := P^.Next;
    end;
    Close(F);
end;

procedure WriteCustomList(Name : string; Removals : boolean);
var
    P, J : PItem;
    F : Text;
    S : String;
begin
    FileMode := 2;
    Assign(F, Name);
    if FileExists(Name) and (Removals) then
        Append(F)
    else begin
        Rewrite(F);
        WriteLn(F, '; FDIMPLES Package List Customization File');
    end;
    WriteLn(F);
    if Removals then
        WriteLn(F, '; Package Removals')
    else
        WriteLn(F, '; Package Additions');
    WriteLn(F);
    P := GroupFirst;
    while Assigned(P) do begin
        J := P^.Items;
        while Assigned(J) do begin
            StandBy;
            if (J^.State <> J^.Original) and
            (((J^.State = psNone) and Removals) or
            ((J^.State <> psNone) and (not Removals))) then begin
                if Comments and (PtrStr(J^.Title) <> '') then begin
                    WriteLn(F, '; ', RSpace(J^.NAME, 12), #32,
                    RSpace(Copy(PtrStr(J^.MVersion),1,20), 20), #32,
                    PtrStr(J^.Title));
                end;
                if J^.State = psNone then S := '-' else S := '+';
                WriteLn(F, S + ' ' + lcase(P^.Name + PathDelim + J^.Name));
                if Comments then begin
                    WriteLn(F);
                end;
            end;
            J := J^.Next;
        end;
        P := P^.Next;
    end;
    Close(F);
end;

procedure ReadCustomList(Name : string; Removals : boolean);
var
    P, G : PItem;
    F : File;
    S : String;
    C : integer;
    X : boolean;

begin
    FileMode := 2;
    Assign(F, Name);
    if not FileExists(Name) then exit;
    P := Package;
    G := Group;
    FileMode := 0;
    Reset(F, 1);
    repeat
        C := UnixRead(F, S);
        S := Trim(UCase(S));
        if (Length(S) > 2) and ((S[1] = '-') or (S[1] = '+')) then begin
            X := S[1] = '+';
            Delete(S,1,1);
            if Pos('\', S) > 0 then
                Delete(S, 1, LastPos('\', S));
            S := Trim(S);
            Group := GroupFirst;
            while Assigned(Group) do begin
                Package := Group^.Items;
                while Assigned(Package) do begin
                    StandBy;
                    if (Ucase(Package^.Name) = S) and (not Package^.Locked) then begin
                        if Package^.Tested = False then SearchForData(false);
                        Package^.Tested := True;
                        if X then begin
                            if Assigned(Package^.IVersion) and Assigned(Package^.MVersion) and
                            (Ucase(PtrStr(Package^.IVersion)) <> UCase(PtrStr(Package^.MVersion))) and
                            (RunMode = rmStandAlone) then begin
                                if (UCase(PtrStr(Package^.IVersion)) < UCase(PtrStr(Package^.MVersion))) then
                                    Package^.State := psUpgrade
                                else
                                    Package^.State := psReplace
                            end else
                                Package^.State := psFull;
                        end else if Removals then
                            Package^.State := psNone;
                    end;
                    Package := Package^.Next;
                end;
                Group := Group^.Next;
            end;
        end;
    until C = -1;
    Group := G;
    Package := P;
    Close(F);
    VerifyGroupState;
end;

procedure MakeFDIList;
begin
    MakeList(TailDelim(GetEnv('TEMP')) + 'FDIMPLES.LST', psFull, False);
    CleanUp;
end;

procedure MakeLists;
begin
    if RunMode = rmConfig then begin
        MakeList(ListDir + 'FDPLBASE.LST', psBase, True);
        MakeList(ListDir + 'FDPLFULL.LST', psBase, True);
        MakeList(ListDir + 'FDPLFULL.LST', psAll, True);
    end else begin
        MakeList('PKG_BASE.LST', psBase, True);
        MakeList('PKG_FULL.LST', psBase, True);
        MakeList('PKG_FULL.LST', psAll, True);
        MakeList('PKG_XTRA.LST', psBase, True);
        MakeList('PKG_XTRA.LST', psAll, True);
        MakeList('PKG_XTRA.LST', psExtra, True);
    end;
    CleanUp;
end;

procedure RunList;
var
    P, J : PItem;
    S : String;
    C : boolean;
    {$IFDEF USEBAT}
    T : Text;
    {$ENDIF}
begin
    CleanUp;
    {$IFDEF USEBAT}
        Assign(T, TailDelim(GetEnv('TEMP')) +'FDINST.BAT');
        rewrite(T);
        WriteLn(T, '@ECHO OFF');
        WriteLn(T, PackageManager + ' %1 %2 %3 %4 %5 %6 %7 %8 %9');
        Close(T);
    {$ENDIF}
    P := GroupFirst;
    while Assigned(P) do begin
        J := P^.Items;
        while Assigned(J) do begin
            C := { FileExists(TailDelim(GetEnv('DOSDIR')) + TailDelim('APPINFO') + J^.Name + '.LSM') or }
                FileExists(TailDelim(GetEnv('DOSDIR')) + TailDelim('PACKAGES') + J^.Name + '.LST');
            if (J^.State = psNone) or (J^.State = psUpgrade) or (J^.State = psReplace) then begin
                if C then begin
                    TextAttr := $4F;
                    WriteRawPStr ('remove ' + J^.Name);
                    ClrEOl;
                    TextAttr := $07;
                    WriteLn('');
                    SwapIntVecs;
                    {$IFDEF USEBAT}
                        Exec(GetEnv('COMSPEC'), SwitchChar + 'C ' + TailDelim(GetEnv('TEMP')) +'FDINST.BAT remove ' + J^.Name);
                    {$ELSE}
                        Exec(PackageManager, 'remove ' + J^.Name);
                    {$ENDIF}
                    SwapIntVecs;
                    (* InitQCrt; *)
                    if DosError <> 0 then begin
                        WriteLn('Aborted.');
                        Halt(100);
                    end;
                end;
                C := False;
            end;
            if (J^.State = psFull) or (J^.State = psUpgrade) or (J^.State = psReplace) then begin
                if not C then begin
                    TextAttr := $1F;
                    WriteRawPStr('install ' + lcase(TailDelim(FMedia) + TailDelim(P^.Name) + J^.Name + '.zip'));
                    ClrEOl;
                    TextAttr := $07;
                    WriteLn('');
                    SwapIntVecs;
                    {$IFDEF USEBAT}
                        Exec(GetEnv('COMSPEC'), SwitchChar + 'C ' + TailDelim(GetEnv('TEMP')) +'FDINST.BAT install ' +
                        TailDelim(FMedia) + TailDelim(P^.Name) + J^.Name + '.zip');
                    {$ELSE}
                        Exec(PackageManager, 'install ' +
                        TailDelim(FMedia) + TailDelim(P^.Name) + J^.Name + '.zip');
                    {$ENDIF}
                    SwapIntVecs;
                    (* InitQCrt; *)
                    if DosError <> 0 then begin
                        WriteLn('Aborted.');
                        Halt(100);
                    end;
                end;
            end;
            J := J^.Next;
        end;
        P := P^.Next;
    end;
    {$IFDEF USEBAT}
        Assign(T, TailDelim(GetEnv('TEMP')) +'FDINST.BAT');
        Erase(T);
    {$ENDIF}
end;

var
    HelpStart, HelpLine, HelpLast : integer;
    HelpMore, HelpCmd : boolean;

procedure HelpWriteLn(S2 : String);
var
    S3 : String;
    W, N, A : integer;
begin
    repeat
        W := Lo(WindMax) - Lo(WindMin);
        if Length(S2) > W then begin
            N := LastPos(' ', Copy(S2, 1, W));
            if N > 1 then W := N;
        end;
        S3 := Copy(S2, 1, W);
        Delete(S2, 1, W);
        HelpMore := (HelpLine - HelpStart > Hi(WindMax) - Hi(WindMin));
        if HelpCmd or ((HelpLine >= HelpStart) and (not HelpMore)) then begin
            if not HelpCmd then GotoXY(1,HelpLine - HelpStart + 1);
            if HelpCmd and HelpMore then begin
                HelpLine := 1;
                A := TextAttr;
                TextAttr := $0A;
                WriteRawPStr(NLS(nlsPressAKey));
                TextAttr := A;
                Idler;
                While KeyPressed do ReadKey;
                ResetIdler;
                GotoXY(1, WhereY);
            end;
            WriteRawPStr(S3);
            ClrEol;
            if HelpCmd then WriteLn('');
        end;
        Inc(HelpLine);
    until S2 = '';
end;

procedure HelpOption(S1, S2 : String);
var
    S3 : String;
    W, N : integer;
begin
    while S2 <> '' do begin
        W := Lo(WindMax) - Lo(WindMin) - 21;
        if Length(S2) > W then begin
            N := LastPos(' ', Copy(S2, 1, W));
            if N > 1 then W := N;
        end;
        S3 := Copy(S2, 1, W);
        Delete(S2, 1, W);
        HelpWriteLn(ChrStr(#$20, 4) + RSpace(S1, 16) + #$20 + S3);
        S1 := '';
    end;
end;

procedure HelpNotice;
begin
    HelpWriteLn(NLS(nlsHelp));
    HelpWriteLn(NLS(nlsHelp + 1));
    HelpWriteLn('');
    HelpWriteLn(NLS(nlsHelp + 2));
    HelpWriteLn('');
end;

procedure HelpSwitches;
begin
    if FDIMode then exit;
    HelpWriteLn(NLS(nlsUsage) + ' '+ GetExeBase + ' ' + NLS(nlsOptions));
    HelpWriteLn('');
    HelpOption (SwitchChar + 'HELP,' + SwitchChar + '?',  NLS(nlsHelp + 3));
    HelpOption (SwitchChar + '[NO]FILES',  NLS(nlsHelp + 4));
    HelpOption (SwitchChar + '[NO]UPDATE', NLS(nlsHelp + 5));
    HelpWriteLn('');
    HelpOption (SwitchChar + 'LISTS',    NLS(nlsHelp + 6));
    HelpOption (SwitchChar + 'CONFIG',   NLS(nlsHelp + 7));
    HelpWriteLn('');
    HelpOption (SwitchChar + 'IDLE',   NLS(nlsHelp + 20));
    HelpWriteLn('');
end;

procedure HelpKeyboard;
begin
    HelpWriteLn(NLS(nlsHelp + 8));
    HelpWriteLn('');
    HelpOption ('SPACE,ENTER', NLS(nlsHelp + 9));
    HelpOption ('TAB,LEFT,RIGHT', NLS(nlsHelp + 10));
    HelpOption ('UP,DOWN',  NLS(nlsHelp + 11));
    HelpOption ('ESC',  NLS(nlsHelp + 12));
    if not HelpCmd then HelpWriteLn('');
    HelpOption ('h,H,F1', NLS(nlsHelp + 13));
    HelpWriteLn('');
    if RunMode = rmStandAlone then begin
        HelpOption ('u', NLS(nlsHelp + 14));
        HelpOption ('U', NLS(nlsHelp + 15));
        HelpWriteLn('');
    end;
    if (RunMode = rmStandAlone) or FDIMode then
        HelpOption ('v,V', NLS(nlsHelp + 16));
    HelpOption ('c,C', NLS(nlsHelp + 17));
    HelpWriteLn('');
    if (RunMode = rmStandAlone) or FDIMode then begin
        HelpOption ('w,W', NLS(nlsHelp + 18));
        HelpOption ('r,R', NLS(nlsHelp + 19));
        HelpWriteLn('');
    end;
end;

procedure HelpReset;
begin
    HelpMore := False;
    HelpCmd := False;
    HelpStart := 0;
    HelpLine := 0;
    HelpLast := -1;
end;

procedure CommandLineHelp;
begin
    HelpReset;
    Inc(HelpLine);
    HelpCmd := True;
    HelpWriteLn(AppTitle + ' (' + AppName + '), version ' + AppVersion);
    HelpNotice;
    HelpSwitches;
    HelpKeyboard;
    Halt(0);
end;

procedure Redraw;
begin
    DrawTitle;
    DrawSelector;
    PurgeEvents;
    DrawGroups;
    DrawButtons;
end;

procedure Help;
var
    E : TEvent;
    Quit : boolean;
begin
    PurgeEvents;
    DrawTitle;
    DrawMainBox;
    Window (Theme.Frame.X + 2, Theme.Frame.Y + 1,
    Lo(ScreenMax) - Theme.Frame.X, Hi(ScreenMax) - Theme.Frame.Y + 1);
    HelpReset;
    Quit := False;
    repeat
        HelpLine := 0;
        HelpNotice;
        HelpSwitches;
        HelpKeyboard;
        ClearEvent(E);
        ResetIdler;
        While E.What = evNothing do begin
            Idler;
            GetEvent(E);
        end;
        ResetIdler;
        if E.What and evKeyDown = evKeyDown then
            case E.KeyCode of
                $001b : Quit := True;
                $4800 : begin if HelpStart > 0 then
                    Dec(HelpStart) else PurgeEvents;
                end;
                $5000 : begin if HelpMore then
                    Inc(HelpStart) else PurgeEvents;
                end;
            else
                Quit := True;
            end;
    until Quit;
    Redraw;
end;

procedure ShowPending;
var
    E : TEvent;
    Quit : boolean;
    P, J : PItem;
    C : boolean;
    M : integer;
begin
    PurgeEvents;
    DrawTitle;
    DrawMainBox;
    Window (Theme.Frame.X + 2, Theme.Frame.Y + 1,
    Lo(ScreenMax) - Theme.Frame.X, Hi(ScreenMax) - Theme.Frame.Y + 1);
    HelpReset;
    Quit := False;
    repeat
        HelpLine := 0;
        HelpMore := false;
        P := GroupFirst;
        TextColor(Theme.Fore);
        TextBackground(Theme.Back);
        HelpWriteLn( NLS(nlsPendingChanges) + ' ');
        HelpWriteLn('');
        M := 0;
        while Assigned(P) and (not HelpMore) do begin
            J := P^.Items;
            while Assigned(J) do begin
                if J^.State <> J^.Original then begin
                    C := { FileExists(TailDelim(GetEnv('DOSDIR')) + TailDelim('APPINFO') + J^.Name + '.LSM') or }
                        FileExists(TailDelim(GetEnv('DOSDIR')) + TailDelim('PACKAGES') + J^.Name + '.LST');
                    if (J^.State = psNone) or (J^.State = psUpgrade) or (J^.State = psReplace) then begin
                        if C then begin
                            TextAttr := Theme.Remv;
                            HelpWriteLn (' ' + NLS(nlsRemoveChange) + ' ' + J^.Name);
                            Inc(M);
                        end;
                        C := False;
                    end;
                    if (J^.State = psFull) or (J^.State = psUpgrade) or (J^.State = psReplace) then begin
                        if not C then begin
                            TextAttr := Theme.Inst;
                            HelpWriteLn(' ' + NLS(nlsInstallChange) + ' ' + lcase(TailDelim(FMedia) +
                                TailDelim(P^.Name) + J^.Name + '.zip'));
                            Inc(M);
                        end;
                    end;
                end;
                J := J^.Next;
            end;
            P := P^.Next;
        end;
        TextColor(Theme.Fore);
        TextBackground(Theme.Back);
        if M = 0 then HelpWriteLn(NLS(nlsNoChanges)) else begin
            HelpWriteLn('');
            HelpWriteLn(IntStr(M) + PluralNLS(M, nlsTotalChanges) + '.');
        end;
        HelpWriteLn('');
        ClearEvent(E);
        ResetIdler;
        While E.What = evNothing do begin
            Idler;
            GetEvent(E);
        end;
        ResetIdler;
        if E.What and evKeyDown = evKeyDown then
            case E.KeyCode of
                $001b : Quit := True;
                $4800 : begin if HelpStart > 0 then
                    Dec(HelpStart) else PurgeEvents;

                end;
                $5000 : begin if HelpMore then
                    Inc(HelpStart) else PurgeEvents;
                end;
            else
                Quit := True;

            end;
    until Quit;
    Redraw;
end;

var
    CustomFile : String;
    CustomRemovals : boolean;


procedure DrawFileBox(Title : String; Extra : integer);
var
    Mid : integer;
    Height : integer;
begin
    Height := 8 + Extra;
    TextAttr := $70;
    Mid := (Hi(ScreenMax) + 1) div 2;
    Window (Theme.Frame.X + 5, Mid - Height div 2,
        Lo(ScreenMax) - Theme.Frame.X - 5, Mid + Height div 2);
    ClrScr;
    Window (1, 1, Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    DrawBox(Theme.Frame.X + 6, Mid - Height div 2,
        Lo(ScreenMax) - Theme.Frame.X - 6, Mid + Height div 2, bxSingle);
    DrawShadow(Theme.Frame.X + 5, Mid - Height div 2,
        Lo(ScreenMax) - Theme.Frame.X - 5, Mid + Height div 2, bsDoubleWide);
    Window (Theme.Frame.X + 7, Mid - Height div 2 + 2,
        Lo(ScreenMax) - Theme.Frame.X - 7, Mid + Height div 2);
    WriteLn(' ' + Title);
end;

function EditCustomFile : word;
var
    Cursor  : Word;
    ESize   : word;
    TempStr : String;
    Event   : TEvent;
    Wide    : byte;
    X, Y    : Byte;
    I       : word;
begin
    EditCustomFile := 0;
    GotoXY(1, 3);
    TextAttr := $1F;
    if ESize > Sizeof(TempStr) then
    ESize := Sizeof(TempStr) - 1;
    TempStr := CustomFile;
    Wide := lo(WindMax) - lo(WindMin) + 1;

    if Not EditLn(TempStr, True, ESize, Wide, Event) then
        repeat
            if Event.What = evKeyDown then case Event.KeyCode of
                $001b, $0009, $0f00 : begin
                    EditCustomFile := Event.KeyCode;
                    Break;
                end;
            end;
        until EditLn(TempStr, False, ESize, Wide, Event);

    HideCursor;
    CustomFile := TempStr;
    TextAttr := $71;
    GotoXY(1, 3);
    WriteRawPStr(' ' + Copy(CustomFile, 1, GetMaxX - 1));
    ClrEol;
end;

procedure DrawBoxParts(Saving : boolean; Focus : integer);
var
    WMin, WMax : word;
begin
    WMin := WindMin;
    WMax := WindMax;
    TextAttr := $71;
    GotoXY(2, 3);
    WriteRawPStr(Copy(CustomFile, 1, GetMaxX - 1));
    GotoXY(1, 4);
    WriteLn('');
    if Focus = 1 then TextAttr := $1F else TextAttr := $70;
    WriteLn(' [' + WhichStr(CustomRemovals, ' ', 'X') + '] ' + NLS(nlsIncludeRemovals) + ' ');
{
    if Saving then begin
    end else begin
    end;
}
    Window(0,0,GetMaxX, GetMaxY);
    GotoXY(lo(WMax) - 3, Hi(WMax) + 2);
    TextAttr := $70;
    DrawOKCancel(Focus, 2, $1f);
    Window(lo(WMin) + 1, hi(WMin) + 1, lo(WMax) + 1, hi(WMax) + 1);
end;

function RunFileBox(Saving : boolean) : boolean;
var
    E : TEvent;
    Quit : boolean;
    Focus : integer;
    EF : word;
begin
    RunFileBox := False;
    Focus := 0;
    Quit := False;
    repeat
        DrawBoxParts(Saving, Focus);
        if Focus = 0 then begin
            repeat
                EF := EditCustomFile
            until EF <> 0;
        end else
            EF := 0;
        if EF = 0 then begin
            ClearEvent(E);
            ResetIdler;
            While E.What = evNothing do begin
                Idler;
                GetEvent(E);
            end;
            ResetIdler;
        end else begin
            E.What := evKeyDown;
            E.KeyCode := EF;
        end;
        if E.What and evKeyDown = evKeyDown then
            case E.KeyCode of
                $000d, $0020 : case Focus of
                    1 : CustomRemovals := not CustomRemovals;
                    2 : begin
                        RunFileBox := True;
                        Quit := True;
                    end;
                    3 : Quit := True;
                end;
                $001b : Quit := True;
                $0009 : begin
                   if Focus < 3 then
                        Inc(Focus)
                    else
                        Focus := 0;
                end;
                $0F00 : begin
                   if Focus > 0 then
                        Dec(Focus)
                    else
                        Focus := 3;
                end;
            else
                Focus := 0;
            end;
    until Quit;
end;

procedure LoadCustom;
begin
    DrawFileBox(NLS(nlsLoadCustom), 0);
    if RunFileBox(false) then
    ReadCustomList(CustomFile, CustomRemovals);
    Redraw;
end;

procedure SaveCustom;
begin
    DrawFileBox(NLS(nlsSaveCustom), 0);
    if RunFileBox(true) then begin
        WriteCustomList(CustomFile, false);
        if CustomRemovals then WriteCustomList(CustomFile, true);
    end;
    Redraw;
end;

procedure ClearChanges;
var
    P, G : PItem;
begin
    G := Group;
    P := Package;
    Group := GroupFirst;
    while Assigned(Group) do begin
        Package := Group^.Items;
        while Assigned(Package) do begin
            StandBy;
            Package^.State := Package^.Original;
            Package := Package^.Next;
        end;
        VerifyGroupState;
        Group := Group^.Next;
    end;
    Group := G;
    Package := P;
    DrawGroups;
end;

procedure GetDefaults;
var
    P, G : PItem;
begin
    G := Group;
    P := Package;
    Group := GroupFirst;
    while Assigned(Group) do begin
        Package := Group^.Items;
        while Assigned(Package) do begin
            StandBy;
            Package^.Original := Package^.State;
            Package := Package^.Next;
        end;
        Group := Group^.Next;
    end;
    Group := G;
    Package := P;
end;

procedure Main;
var
    E : TEvent;
    LTab : integer;
    Quit : boolean;
    S : String;
    I : integer;
    Attempt : boolean;
begin
    SetCritical(nil,nil);
    {$IFDEF DEBUG}
    Assign(LOGFILE, 'FDIMPLES.LOG');
    Rewrite(LOGFILE);
    Close(LOGFILE);
    Log('Begin');
    {$ENDIF}

    StandByProc := StandBy;

    GetDir(0, CustomFile);
    CustomFile := TailDelim(CustomFile) + 'PACKAGES.LST';
    CustomRemovals := False;

    if DirExists('FDI\SETTINGS\') then
        ListDir := 'FDI\SETTINGS\'
    else  if DirExists('\FDI\SETTINGS\') then
        ListDir := '\FDI\SETTINGS\'
    else
        ListDir := '';

    TickCount := 0;
    StartUp := True;
    FileList := True;
    CheckMark := NormalCheckMarks;
    RunMode := rmStandAlone;
    AutoUpdate := False;
    Comments := False;
    I := 1;
    while I <= ParamCount do begin
        S := Ucase(ParamStr(I));
        if (S = SwitchChar + 'HELP') or (S = SwitchChar + '?') then
            CommandLineHelp
        else if (S = SwitchChar + 'IDLE') then
            IdleCPU := True
        else if (S = SwitchChar + 'LISTS') then begin
            RunMode := rmList;
            FileList := True;
            CheckMark := ListCheckMarks;
        end else if (S = SwitchChar + 'CONFIG') then begin
            RunMode := rmConfig;
            FileList := True;
            CheckMark := ListCheckMarks;
            if DirExists('\FDSETUP\SETUP\') then
                ListDir := '\FDSETUP\SETUP\'
            else
                ListDir := '';
        end else if S = SwitchChar + 'FDI' then begin
            RunMode := rmFDI;
            Comments := False;
            FileList := True;
            AutoUpdate := False;
            CheckMark := NormalCheckMarks;
        end else if S = SwitchChar + 'NOFILES' then
            FileList := False
        else if S = SwitchChar + 'FILES' then
            FileList := True
        else if S = SwitchChar + 'NOUPDATE' then
            AutoUpdate := False
        else if S = SwitchChar + 'UPDATE' then
            AutoUpdate := True
        else begin
            WriteLn(NLS(nlsInvalidParam) + ' "' + ParamStr(I) + '"');
            Halt(100);
        end;
        inc(I);
    end;
    UpdateOn := false;
    SetTheme;
    Init;
{
    WriteLn;
    WriteLn(FMEDIA);
    WriteLn(PackageInfo, ', ',
     DirExists(PackageInfo), ', ',
      FileExists(TailDelim(PackageInfo) + 'command.txt'));
    ReadKey;
}
    if AutoUpdate then UpdateToggle(True);
    StartUp := False;
    CheckScroll := False;
    (* CheckCursor := False; *)

    { Make group column a little wider if possible up to 1/3 main window }
    I := ChangeGroupTitles + 6;
    if I > (Lo(ScreenMax) - Theme.Frame.X * 2 + 1) div 3 then
        I := (Lo(ScreenMax) - Theme.Frame.X * 2 + 1) div 3;
    if I > Theme.Grps.X then
        Theme.Grps.X := I;

    DrawTitle;
    DrawSelector;
    LTab := -1;
    Quit := False;
    PurgeEvents;
    GetDefaults;
    repeat
        if Group = nil then Tab := 4;
        if LTab <> Tab then begin
            DrawGroups;
            DrawButtons;
            LTab := Tab;
        end;
        DrawStatus(Tab);
        ClearEvent(E);
        Attempt := True;
        ResetIdler;
        While (E.What = evNothing) do begin
            Idler;
            GetEvent(E);
            if (E.What = evNothing) and Assigned(Package) and Package^.Skipped and Attempt then begin
                SearchForData(True);
                if not Package^.Skipped then begin
                    DrawGroups;
                    DrawButtons;
                    DrawStatus(Tab);
                end;
                Attempt := False;
            end;
            if (E.What = evNothing) then
                DrawStatus(-1);
        end;
        ResetIdler;
        if E.What and evKeyDown = evKeyDown then
            case E.KeyCode of
                $0003 : begin
                    CleanUp;
                    Halt(200); { CTRL-C }
                end;
                $001b : begin
                    CleanUp;
                    Halt(1); { Esacpe }
                end;
                $0048, $0068, $3B00 : begin
                    Help; { h, H, F1 }
                end;
                $0056, $0076 : case RunMode of
                    rmStandAlone, rmFDI : ShowPending;
                end;
                $0052, $0072 : case RunMode of
                    rmStandAlone, rmFDI : LoadCustom;
                end;
                $0057, $0077 : case RunMode of
                    rmStandAlone, rmFDI : SaveCustom;
                end;
                $0043, $0063 : ClearChanges;
                $4800 : case Tab of
                    0: GroupUp(1);
                    1: FileUp(1);
                    2: TextUp(1);
                end;
                $4900 : case Tab of
                    0: GroupUp(Theme.Grps.Y - 1);
                    1: FileUp(Theme.Grps.Y - 1);
                    2: TextUp(Hi(ScreenMax)- Theme.Frame.Y * 2 - Theme.Grps.Y - 1);
                end;
                $5000 : case Tab of
                    0: GroupDown(1);
                    1: FileDown(1);
                    2: TextDown(1);
                end;
                $5100 : case Tab of
                    0: GroupDown(Theme.Grps.Y - 1);
                    1: FileDown(Theme.Grps.Y - 1);
                    2: TextDown(Hi(ScreenMax)- Theme.Frame.Y * 2 - Theme.Grps.Y - 1);
                end;
                $0020, $000A, $000D : case Tab of
                    0: GroupToggle;
                    1, 2 : FileToggle;
                    3: begin
                        if RunMode = rmFDI then
                            MakeFDIList
                        else if RunMode = rmStandAlone then
                            RunList
                        else
                            MakeLists;
                        Quit := True;
                    end;
                    4: begin
                        CleanUp;
                        Halt(1); { Canceled }
                    end;
                end;
                $0009, $4d00 : begin
                    if Tab >= 4 then
                        Tab := 0
                    else
                        Inc(Tab);
                end;
                $0F00, $4b00 : begin
                    if Tab <= 0 then
                        Tab := 4
                    else
                        Dec(Tab);
                end;
                $0055, $0075 : if RunMode = rmStandAlone then begin {u/U}
                    UpdateToggle(E.KeyCode = $0055);
                end;
{
                else
                    GotoXY(1, Hi(WindMax) - 1);
                    WriteRawPStr(HexStr(E.KeyCode));
                    ClrEol;
}
            end;
    until Quit;
    {$IFDEF DEBUG}
    Log('End');
    {$ENDIF}
end;

begin
    Main;
end.