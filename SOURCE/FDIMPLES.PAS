{
    Copyright 2016 Jerome Shidel
    Released Under GPL v2.0 License.
}


{
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
        FDPLALL.LST is list of ALL package install files.

    On exit,

        errorlevel 200, for aborted (CTRL+C)
        errorlevel 1, cancelled. (like Escape)
        errorlevel 0, ok, and %TEMP%\FDIMPLES.LST contains package list.
}

{$M 50000,51200,204800} (* Memory: Largest Stack, 100K Minimum / Maximum *)

{$I QCRT.DEF}
program Test;

{$DEFINE USEBAT}

uses QDos, QCrtNM, QStrings;

{$I VERSION.INC}

const
    AppName = 'FDIMPLES';
    AppTitle = 'FreeDOS Installer - My Package List Editor Software';
    Installed = 'Installed!'; {Always sorted first -- has only title, no name}
    ALLPackages = 'FDPLALL.LST';
    BASEPackages = 'FDPLBASE.LST';
    LoMem = 10240;
    NoScroll = 1;
    MinTicks = 7;

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
        First, Locked, Tested : boolean;
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
        Status, StatusHot : byte;
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
    StartCursor : word;
    Theme : TTheme;
    CheckMark : TChecks;
    RunMode : TModes;
    FileList : boolean;
    AutoUpdate : boolean;
    UpdateOn : boolean;
    TickCount : Longint;
    LastTick : LongInt;
    Startup : boolean;
    Comments : boolean;
    ListDir : string;
    TimerTick    : LongInt absolute $0040:$006c;  { Timer tick counter }

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

procedure StandBy;
const
    Ticks : string[4] = '/-\|';
    Speed = 2;
var
    WMin, WMax, X, Y, A : integer;
begin
    if RunMode = rmFDI then exit;
    if LastTick = TimerTick then exit;
    LastTick := TimerTick;
    Inc(TickCount);
    if (TickCount < MinTicks) and (not Startup) then exit;
    if Startup then begin
        if TickCount < 2 then exit;
        if TickCount > 2 then GotoXY(WhereX -1, WhereY);
        FWrite(Ticks[((TickCount - 2) div Speed) mod Length(Ticks) + 1]);
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
            FWrite(' Standby');
            ClrEol;
        end;
        GotoXY(10, Hi(WindMax));
        FWrite(Ticks[((TickCount - MinTicks) div Speed) mod Length(Ticks) + 1]);
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
    CheckCursor := True;
    CheckScroll := True;
    ClrScr;
    SetCursor(StartCursor);
end;

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

function UnixRead(var F : File; var S : String) : integer;
var
    P : longInt;
    N : boolean;
    C, D, O : integer;
begin
    Standby;
    P := FilePos(F);
    BlockRead(F, S[1], Sizeof(S) - 10, C);
    S[0] := chr(C);
    N := False;
    if C = 0 then
        UnixRead := -1
    else begin
        O := 0;
        D := Pos(#$0a, S);
        if (D <> 0) and (D <= Ord(S[0])) then begin
            S[0] := Chr(D - 1);
            Inc(O);
            N := true;
        end;
        D := Pos(#$0d, S);
        if (D <> 0) and (D <= Ord(S[0])) then begin
            S[0] := Chr(D - 1);
            Inc(O);
            N := true;
        end;
 {       D := 1;
        while (D <= Length(S)) and (S <> '') do begin
            if (Ord(S[D]) = $0a) or (Ord(S[D]) = $0d) then begin
                Delete (S, D, 1);
                Inc(O);
            end else Inc(D);
        end;}
        if N then
            UnixRead := 1
        else
            UnixRead := 0;
        Seek(F, P + Ord(S[0]) + O);
    end;
end;

procedure ReadListFile(Name : string; Prefix : String);
var
    F : File;
    S : String;
    P : PText;
    C : integer;
begin
    if not FileExists(Name) then exit;
    FileMode := 0; { not needed }
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
            ReadListFile(ListDir + 'FDPLALL.LST',  'A* ');
            ReadListFile(ListDir + 'FDPLBASE.LST', 'B* ');
        end else begin
            ReadListFile(ListDir + 'PKG_XTRA.LST', 'E* ');
            ReadListFile(ListDir + 'PKG_ALL.LST',  'A* ');
            ReadListFile(ListDir + 'PKG_BASE.LST', 'B* ');
        end;
    end else begin
        S := Trim(UCase(TailDelim(GetEnv('DOSDIR'))));
        if (S = '') then exit;
        FindFirst(S + TailDelim('PACKAGES') + '*.LST', faAnyFile, D);
        L := nil;
        while DosError = 0 do begin
            if (D.Attr and faDirectory <> faDirectory) then begin
                P := New(PText);
                P^.Next := nil;
                P^.Str := StrPtr(Delimiter + copy(D.Name, 1, length(D.Name) - 4));
                if assigned(L) then
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
    while assigned(P) and (V = psNone) do begin
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
        while assigned(P) do begin
            if PtrStr(P^.Str) = S then begin
                CheckDefault := true;
                exit;
            end;
            P := P^.Next;
        end;
    end else begin
        while assigned(P) do begin
            if PtrStr(P^.Str) = Copy(S, Pos(Delimiter, S), Length(S)) then begin
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
    while assigned(P) do begin
        N := P^.Next;
        P^.Next := nil;
        P^.Prev := nil;
        if assigned(L) then begin
            while assigned(L^.Prev) and (P^.NAME < L^.NAME) do
                L := L^.Prev;
            while assigned(L^.Next) and (P^.NAME > L^.NAME) do
                L := L^.Next;
            if P^.Name < L^.Name then begin
                P^.Next := L;
                P^.Prev := L^.Prev;
                if assigned(L^.Prev) then
                    L^.Prev^.Next := P;
                L^.Prev := P;
            end else begin
                P^.Prev := L;
                P^.Next := L^.Next;
                if assigned(L^.Next) then
                    L^.Next^.Prev := P;
                L^.Next := P;
            end;
        end;
        L := P;
        P := N;
    end;
    First := L;
    While assigned(First^.Prev) do First := First^.Prev;
    Last := L;
    While assigned(Last^.Next) do Last := Last^.Next;
end;

procedure AddCustomItems(P : PItem; B, N : String);
var
  J : PItem;
  F : boolean;
  FN : String;
begin
    if (RunMode <> rmFDI) then exit;

    if not assigned(P) then exit;

    if not (P^.Name = B) then exit;

    FN := TailDelim(GetEnv('FINSP')) + 'PACKAGES';
    if not DirExists(FN) then exit;
    if not FileExists(TailDelim(FN) + TailDelim(B) + N + '.ZIP') then exit;

    if (not CheckDefault(TailDelim(B) + N)) then exit;

    J := NewPItem(N, psFull);
    if not assigned(PackageFirst) then begin
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
        while S and assigned(P) do begin
            J := P^.Items;
            while S and assigned(J) do begin
                S := '\' + J^.Name <> PtrStr(I^.Str);
                J := J^.Next;
            end;
            P := P^.Next;
        end;
        if S then begin
            J := NewPItem(Copy(PtrStr(I^.Str), 2, 13), psFull);
            J^.Next := Others^.Items;
            if assigned(Others^.Items) then
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
    if not assigned(L) then begin
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

begin
    if not MemCheck(LoMem) then exit;

    if not AGroup^.First then exit;

    AGroup^.First := False;
    Name := FMedia + TailDelim(AGroup^.Name) + 'INDEX.LST';
    if not FileExists(Name) then exit;

    FileMode := 0;
    Assign(F, Name);
    Reset(F, 1);
    repeat
        C := UnixRead(F, B);
        if (C >= 0) and (Trim(B) <> '') then begin
            Name := Trim(PullStr(#$09, B));
            Ver := Trim(PullStr(#$09, B));
            Desc := Trim(PullStr(#$09, B));
            MD5 := Trim(PullStr(#$09, B));
            if Ucase(Name) = 'FD-REPOV1' then begin
                AGroup^.Title := StrPtr(WCase(Desc));
            end;
            X := AGroup^.Items;
            while assigned(X) do begin
                if (UCase(Name) = UCase(X^.Name)) and (not assigned(X^.Items)) then begin
                    if Not Assigned(X^.Title) then
                        X^.Title := StrPtr(Copy(Desc, 1, Lo(ScreenMax) - Theme.Frame.X * 2 - Theme.Grps.X - 16));
                    if Not Assigned(X^.MVersion) then
                        X^.MVersion := StrPtr(Ver);
                    if not assigned(X^.Items) then begin
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
    C, Pass : integer;
    V : longint;
    Flag, TMode, Appending : boolean;
    Title, Version, Desc,
    Author, License, X, M : String;
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
        if FileExtension(LSM) = 'TXT' then begin
            FreeStr(Package^.MVersion);
            Package^.MVersion := StrPtr(Trim(Version));
        end else begin
            FreeStr(Package^.IVersion);
            Package^.IVersion := StrPtr(Trim(Version));
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

begin
    if not FileExists(LSM) then exit;
    ClearPackage(Package);
    Assign(F, LSM);
    Reset(F, 1);
    Pass := 0;
    Title := 'unknown';
    Version := Title;
    Author := '';
    License := '';
    ISize := '';
    IFiles := '';
    SSize := '';
    SFiles := '';
    Appending := False;
    While Pass < 2 do begin
        Flag := False;
        TMode := False;
        Seek(F, 0);
        repeat
            C := UnixRead(F, S);
            if Trim(Ucase(S)) = 'END' then
                C := -1
            else
            if Trim(Ucase(S)) = 'BEGIN3' then
                Flag := True
            else
            if Match('TITLE', Title) then Ignore else
            if Match('Version', Version) then IgnoreVersion else
            if Match('Author', Author) then IgnoreEmail(Author) else
            if Match('copying-policy', License) then Ignore else
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

            if Flag and (C > -1) and (S <> '') and (Pass = 1) then begin
                if Match('description', Desc) then begin
                    if PtrStr(Package^.Title) = '' then
                        Package^.Title := StrPtr(Copy(Desc, 1, Lo(ScreenMax) - Theme.Frame.X * 2 - Theme.Grps.X - 16));
                    S := Desc;
                    TMode := true;
                    Appending := true;
                end else if (Copy(S, 1, 2) = '  ') then
                    S := LTrim(S)
                else begin
                    if Appending then AddLine(Package, '', True);
                end;
            end;
            repeat
                if TMode then AddLine(Package, S, Not Appending);
                if (C = 0) then
                    C := UnixRead(F, S)
                else
                    S := '';
            until (C <> 0) and (S = '');
        until C = -1;
        if Appending then AddLine(Package, '', True);
        if Pass = 0 then begin
           if (Not FDIMode) and Assigned(Package^.IVersion) and Assigned(Package^.MVersion) and
            (Ucase(PtrStr(Package^.IVersion)) <> Ucase(PtrStr(Package^.MVersion))) then
                AddLine(Package, Title + ' (' + PtrStr(Package^.MVersion)  + ', ' +
                PtrStr(Package^.IVersion) + ' installed)', True)
            else
                AddLine(Package, Title + ' (' + Version + ')', True);
            if Author <> '' then
                AddLine(Package, Author, True);
            if License <> '' then
                AddLine(Package, License, True);
            AddLine(Package, '', True);
        end;
        if (Pass = 1) and (PtrStr(Package^.Title) = '') then
            Package^.Title := StrPtr(Copy(Title, 1, Lo(ScreenMax) - Theme.Frame.X * 2 - Theme.Grps.X - 16));
        if (Pass = 1) and (ISize <> '') then begin
            AddLine(Package, '', True);
            X := '';
            { if not FDIMODE then begin }
                if IFiles <> '' then begin
                    V := StrInt(IFiles) - StrInt(SFiles);
                    X := Comma(IntStr(V)) + ' file' + PluralStr(V) + ' (';
                end;
                V := StrInt(trim(ISize)) - StrInt(trim(SSize));
                M := ' byte';
                if V > 10239 then begin
                    M := ' KByte';
                    V := V div 1024;
                    if V > 5119 then begin
                        M := ' MByte';
                        V := V div 1024;
                    end;
                end;
                X := X + Comma(IntStr(V)) + M + PluralStr(V) + ')';
                if (SFIles <> '') and ((not FDIMode) or (ucase(GetEnv('OSRC')) <> 'N')) then begin
                    X := X  + '; ';
                    V := StrInt(SFiles);
                    X := X + Comma(IntStr(V)) + ' source file' + PluralStr(V) + ' (';
                    V := StrInt(trim(SSize));
                    M := ' byte';
                    if V > 10239 then begin
                        M := ' KByte';
                        V := V div 1024;
                        if V > 5119 then begin
                            M := ' MByte';
                            V := V div 1024;
                        end;
                    end;
                    X := X + Comma(IntStr(V)) + M + PluralStr(V) + ')';
                end;
            AddLine(Package, '', True);
            if Package^.Locked then begin
                if X <> '' then X := X + ', ';
                X := X + 'LOCKED';
            end;
            AddLine(Package, X { + ':' + IFiles + '/' + ISize + ',' + SFiles + '/' + SSize }, True);
        end;

        Inc(Pass);
    end;
    Close(F)
end;

procedure TryLST(LST : string; All : boolean);
var
    F : File;
    S : String;
    C : integer;
    Flag : boolean;
begin
    if not FileExists(LST) then exit;
    AddLine(Package, ' ' + ChrStr(#$c4, Lo(ScreenMax) - Theme.Frame.X * 2 - 5), true);
    Assign(F, LST);
    Reset(F, 1);
    Flag := True;
    repeat
        C := UnixRead(F, S);
        if Trim(Ucase(S)) = 'END' then
            Flag := True
        else
        if Trim(Ucase(S)) = 'BEGIN3' then
            Flag := False
        else
        if Flag and (C > -1) and (S<>'') then
            AddLine(Package, lcase(S), C <> 0);
    until C = -1;
    Close(F)
end;

procedure SearchForData(All:boolean);
var
     FN : String;
begin
    if Group^.Name = '' then begin
        TryLSM(TailDelim(GetEnv('DOSDIR')) + TailDelim('APPINFO') + Package^.Name + '.LSM', All);
        if (All and assigned(Package^.Items)) and FileList then
            TryLST(TailDelim(GetEnv('DOSDIR')) + TailDelim('PACKAGES') + Package^.Name + '.LST', All);
    end else begin
        if (not assigned(Package^.IVersion)) and (not FDIMode) then
            TryLSM(TailDelim(GetEnv('DOSDIR')) + TailDelim('APPINFO') + Package^.Name + '.LSM', false);
        FN := TailDelim(FMEDIA) + TailDelim('..') + TailDelim('PKGINFO') + Package^.Name + '.TXT';
        while (Copy(FN, 3, 3) = '\..') do Delete(FN, 3, 3);
        TryLSM(FN, All);
        if (All and assigned(Package^.Items)) and FileList then
            TryLST(FN, All);
    end;
end;

function IsMediaDrive(S : String) : boolean;
begin
    IsMediaDrive := False;
    S := TailDelim(S);
    if DirExists(S) and
    FileExists(TailDelim(S + 'BASE') + 'COMMAND.ZIP') (* and
    FileExists(TailDelim(S + 'BASE') + 'KERNEL.ZIP') *) then begin
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
    reset(F);
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
    while assigned(P) do begin
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

procedure Init;
var
   S : TSearchRec;
   P, J, Others : PItem;
   CS : integer;
   T, M : String;

begin
    if Trim(GetEnv('FMEDIA')) <> '' then begin
        FMedia := TailDelim(Dir(Trim(GetEnv('FMEDIA'))));
    end;

    if not FDIMode then begin
        if (FMedia <> '') and (not DirExists(FMedia)) then FMedia := '';
        if Not FileExists(TailDelim(GetEnv('DOSDIR')) + 'BIN\FDINST.EXE') then begin
            FWriteLn('unable to located package manager FDINST.');
            Halt(100);
        end;
        if (GetEnv('TEMP') = '') or (not DirExists(GetEnv('TEMP'))) then begin
            FWriteLn('TEMP environment variable is not set.');
            Halt(2);
        end;
        StartCursor := GetCursor;
        HideCursor;
        FWrite('Please standby...');
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
    ReadDefaults;
    Tab := 0;
    Group := nil;
    Others := NewPItem('', psFull);
    GroupFirst := Others;
    GroupLast := GroupFirst;
    with GroupFirst^ do begin
        Title := StrPtr(Installed);
    end;
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

        AddCustomItems(P, 'BASE', 'WELCOME');
        AddCustomItems(P, 'UTIL', 'V8POWER');

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
            if assigned(J^.Prev) then
                J^.Prev^.Next := J^.Next
            else
                GroupFirst := J^.Next;
            if assigned(J^.Next) then
                J^.Next^.Prev := J^.Prev
            else
                GroupLast := J^.Prev;
            Dispose(J);
        end;
    end;

    Group := GroupFirst;
    While Assigned(Group) do begin
        CacheGroup(Group);
        Package := Group^.Items;
        while Assigned(Package) do begin
            if Not Assigned(Package^.Items) then
                SearchForData(False);
            Package := Package^.Next;
        end;
        VerifyGroupState;
        Group := Group^.Next;
    end;

    Group := GroupFirst;
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
    if Not assigned(Package^.Items) then begin
        Group^.First := True;
        FreeSomeMem(20);
        CacheGroup(Group);
    end;
    Package^.First := False;
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
    if assigned(Package) then begin
        if (Package^.First) or (not assigned(Package^.Items)) then begin
            FetchData;
        end;

        if not assigned(Package^.Items) then begin
            FWrite(RSpace(' ' + Package^.Name + ' - No information',
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
                if assigned(P^.Prev) and (P^.Prev^.Prev = Package^.Items) then T := True;
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
                    FWrite(#32 + PtrStr(P^.Title));
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
    if not assigned(PackageFirst) then begin
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
        FWrite(' ');
        if P <> Package then TextColor(Theme.Brace);
        FWrite('[');
        if P <> Package then TextColor(Theme.Checks[P^.State]);
        FWrite(CheckMark[P^.State]);
        if P <> Package then TextColor(Theme.Brace);
        FWrite(']');
        if P <> Package then
            TextColor(Theme.Fore)
        else begin
            if Tab <> 1 then
                TextColor(Theme.Hot)
            else
                TextAttr := Theme.Choose;
        end;
        S := P^.Name;
        if assigned(P^.Title) then
            S := Trim(Copy(RSpace(P^.Name, 9) + ' ' + PtrStr(P^.Title), 1,
            Lo(WindMax) - Lo(WindMin) - WhereX + NoScroll));
        FWrite(RSpace(' ' + S, Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
        PackageBottom := P;
        P := P^.Next;
        Inc(Y);
    end;
    TextColor(Theme.Fore);
    TextBackground(Theme.Back);
    while (Y <= Theme.Grps.Y) do begin
        FWrite(RSpace('', Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
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
        FWrite(' ');
        if P <> Group then TextColor(Theme.Brace);
        FWrite('[');
        if P <> Group then TextColor(Theme.Checks[P^.State]);
        FWrite(CheckMark[P^.State]);
        if P <> Group then TextColor(Theme.Brace);
        FWrite(']');
        if P <> Group then TextColor(Theme.Fore);
        S := P^.Name;
        if assigned(P^.Title) then S := PtrStr(P^.Title);
        S := Trim(Copy(S , 1, Lo(WindMax) - Lo(WindMin) - WhereX + NoScroll));
        FWrite(RSpace(' ' + S, Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
        GroupBottom := P;
        P := P^.Next;
        Inc(Y);
    end;
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    DrawFiles;
end;

procedure DrawButtons;
begin
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    Gotoxy (Lo(ScreenMax) - Theme.Frame.X - 25, Hi(ScreenMax)- Theme.Frame.Y + 1);
    TextColor(Theme.Fore);
    TextBackground(Theme.Back);
    if Tab = 3 then
        TextAttr := Theme.Choose;
    FWrite( CSpace('OK', 10));
    GotoXY (WhereX + 5, WhereY);
    TextColor(Theme.Fore);
    TextBackground(Theme.Back);
    if Tab = 4 then
        TextAttr := Theme.Choose;
    FWrite( CSpace('Cancel', 10));
end;

procedure DrawMainBox;
begin
    { Back Drop }
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    TextAttr := Theme.FillAttr;
    TextChar := Theme.FillChar;
    ClrScr;
    { Window Box }
    TextChar := #32;
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
    FWrite(AppTitle + ' ');
    TextAttr := Theme.TitleHot;
    FWrite(AppVersion);
    TextAttr := Theme.Title;
    FWrite(' (' + AppName + ')');
end;

procedure DrawStatus;
begin
    if FDIMode then Exit;
    LastTick := TimerTick;
    TickCount := 0;
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    gotoXY(1,Hi(WindMax));
    TextAttr := Theme.Status;
    if Lo(ScreenMax) >= 79 then begin
        if MaxAvail < LoMem then TextAttr := Theme.StatusHot;
        FWrite(' ' + IntStr(MaxAvail));
        TextAttr := Theme.Status;
        FWrite('/');
        if MemAvail < LoMem then TextAttr := Theme.StatusHot;
        FWrite(IntStr(MemAvail)+ ' ');
        TextAttr := Theme.Status;
    end;
    if Not Assigned(Group) then begin
        FWrite(NoTailDelim(FMedia));
    end else begin
        if Group^.Name <> '' then begin
            FWrite(Copy(TailDelim(FMedia) + TailDelim(Group^.Name), 1, Lo(ScreenMax) + 1 - WhereX));
            if Assigned(Package) then
                FWrite(Copy(Package^.Name + '.ZIP', 1, Lo(ScreenMax) + 1 - WhereX));
        end else begin
            if Assigned(Package) then begin
                FWrite( 'Package ');
                TextAttr := Theme.StatusHot;
                FWrite(Package^.Name);
                TextAttr := Theme.Status;
                FWrite(Copy(' not found under ', 1, Lo(ScreenMax) + 1 - WhereX) );
                TextAttr := Theme.StatusHot;
                FWrite(Copy(NoTailDelim(FMedia), 1, Lo(ScreenMax) + 1 - WhereX));
                TextAttr := Theme.Status;
            end;
        end;
    end;
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
    while assigned(P) do begin
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
    if not assigned(Package) then exit;
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
        assigned(Package^.IVersion) and assigned(Package^.MVersion) and
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
    While (T > 0) and assigned(LineTop^.Prev) do begin
        Dec(T);
        LineTop := LineTop^.Prev;
    end;
    DrawPackage;
end;

procedure TextDown(T:integer);
begin
    if not Assigned(LineBottom) then exit;
    While (T > 0) and assigned(LineBottom^.Next) do begin
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
    while assigned(P) do begin
        J := P^.Items;
        while assigned(J) do begin
            if J^.State = State then begin
                if Comments and (PtrStr(J^.Title) <> '') then begin
                    WriteLn(F, '; ', RSpace(J^.NAME, 12), #32,
                    RSpace(Copy(PtrStr(J^.MVersion),1,20), 20), #32,
                    PtrStr(J^.Title));
                end;
                WriteLn(F, lcase(P^.Name + Delimiter + J^.Name));
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

procedure MakeFDIList;
begin
    MakeList(TailDelim(GetEnv('TEMP')) + 'FDIMPLES.LST', psFull, False);
    CleanUp;
end;

procedure MakeLists;
begin
    if RunMode = rmConfig then begin
        MakeList(ListDir + 'FDPLBASE.LST', psBase, True);
        MakeList(ListDir + 'FDPLALL.LST', psBase, True);
        MakeList(ListDir + 'FDPLALL.LST', psAll, True);
    end else begin
        MakeList('PKG_BASE.LST', psBase, True);
        MakeList('PKG_ALL.LST', psBase, True);
        MakeList('PKG_ALL.LST', psAll, True);
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
        WriteLn(T, TailDelim(GetEnv('DOSDIR')) + 'BIN\FDINST.EXE %1 %2 %3 %4 %5 %6 %7 %8 %9');
        Close(T);
    {$ENDIF}
    P := GroupFirst;
    while assigned(P) do begin
        J := P^.Items;
        while assigned(J) do begin
            C := { FileExists(TailDelim(GetEnv('DOSDIR')) + TailDelim('APPINFO') + J^.Name + '.LSM') or }
                FileExists(TailDelim(GetEnv('DOSDIR')) + TailDelim('PACKAGES') + J^.Name + '.LST');
            if (J^.State = psNone) or (J^.State = psUpgrade) or (J^.State = psReplace) then begin
                if C then begin
                    TextAttr := $4F;
                    FWrite ('remove ' + J^.Name);
                    ClrEOl;
                    TextAttr := $07;
                    FWriteLn('');
                    SwapIntVecs;
                    {$IFDEF USEBAT}

                        Exec(GetEnv('COMSPEC'),'/C ' + TailDelim(GetEnv('TEMP')) +'FDINST.BAT remove ' + J^.Name);
                    {$ELSE}
                        Exec(TailDelim(GetEnv('DOSDIR')) + 'BIN\FDINST.EXE', 'remove ' + J^.Name);
                    {$ENDIF}
                    SwapIntVecs;
                    InitQCrt;
                    if DosError <> 0 then begin
                        FWriteLn('Aborted.');
                        Halt(100);
                    end;
                end;
                C := False;
            end;
            if (J^.State = psFull) or (J^.State = psUpgrade) or (J^.State = psReplace) then begin
                if not C then begin
                    TextAttr := $1F;
                    FWrite('install ' + lcase(TailDelim(FMedia) + TailDelim(P^.Name) + J^.Name + '.zip'));
                    ClrEOl;
                    TextAttr := $07;
                    FWriteLn('');
                    SwapIntVecs;
                    {$IFDEF USEBAT}
                        Exec(GetEnv('COMSPEC'), '/C ' + TailDelim(GetEnv('TEMP')) +'FDINST.BAT install ' +
                        TailDelim(FMedia) + TailDelim(P^.Name) + J^.Name + '.zip');
                    {$ELSE}
                        Exec(TailDelim(GetEnv('DOSDIR')) + 'BIN\FDINST.EXE', 'install ' +
                        TailDelim(FMedia) + TailDelim(P^.Name) + J^.Name + '.zip');
                    {$ENDIF}
                    SwapIntVecs;
                    InitQCrt;
                    if DosError <> 0 then begin
                        FWriteLn('Aborted.');
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
                FWrite('Press a key...');
                TextAttr := A;
                while not Keypressed do asm Hlt; end;
                While KeyPressed do ReadKey;
                GotoXY(1, WhereY);
            end;
            FWrite(S3);
            ClrEol;
            if HelpCmd then FWriteLn('');
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
    HelpWriteLn('Released under the GNU General Public License, Version 2.0');
    HelpWriteLn('Copyright 2016 Jerome Shidel');
    HelpWriteLn('');
    HelpWriteLn(AppName + ' provides an easy-to-use text user interface to ' +
        'the FDINST package manager command-line utility.');
    HelpWriteLn('');
end;

procedure HelpSwitches;
begin
    if FDIMode then exit;
    HelpWriteLn('usage: '+ GetExeBase + ' [options]');
    HelpWriteLn('');
    HelpOption ('/HELP,/?',  'Show this help screen.');
    HelpOption ('/[NO]FILES',  '[DO NOT] Show file list in package description.');
    HelpOption ('/[NO]UPDATE', '[DO NOT] Automatically select updatable packages.');
    HelpWriteLn('');
    HelpOption ('/LISTS',    'Create package list files for use with FDI build utility.');
    HelpOption ('/CONFIG',   'Reconfigure FDI installer BASE and ALL package lists.');
    HelpWriteLn('');
end;

procedure HelpKeyboard;
begin
    HelpWriteLn('User interface keyboard commands:');
    HelpWriteLn('');
    HelpOption ('SPACE,ENTER', 'Toggle selection.');
    HelpOption ('TAB,LEFT,RIGHT', 'Change what section or button has focus.');
    HelpOption ('UP,DOWN',  'Move focus up or down an item, also Page Up/Down.');
    HelpOption ('ESC',  'Quit without making or saving changes.');
    if not HelpCmd then HelpWriteLn('');
    HelpOption ('h,H,F1', 'Display help screen.');
    HelpWriteLn('');
    if RunMode = rmStandAlone then begin
        HelpOption ('u', 'Toggle the status of all updatable packages in group.');
        HelpOption ('U', 'Toggle the status of all updatable packages.');
        HelpWriteLn('');
        HelpOption ('v,V', 'View pending changes.');
    end;
    HelpOption ('c,C', 'Clear all pending changes.');
    HelpWriteLn('');
    if RunMode = rmStandAlone then begin
        HelpOption ('w,W', 'Write a custom package list.');
        HelpOption ('r,R', 'Read a custom package list.');
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
        While E.What = evNothing do begin
            asm HLT end;
            GetEvent(E);
        end;
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
        HelpWriteLn('Pending package changes: ');
        HelpWriteLn('');
        M := 0;
        while assigned(P) and (not HelpMore) do begin
            J := P^.Items;
            while assigned(J) do begin
                if J^.State <> J^.Original then begin
                    C := { FileExists(TailDelim(GetEnv('DOSDIR')) + TailDelim('APPINFO') + J^.Name + '.LSM') or }
                        FileExists(TailDelim(GetEnv('DOSDIR')) + TailDelim('PACKAGES') + J^.Name + '.LST');
                    if (J^.State = psNone) or (J^.State = psUpgrade) or (J^.State = psReplace) then begin
                        if C then begin
                            TextAttr := Theme.Remv;
                            HelpWriteLn (' remove ' + J^.Name);
                            Inc(M);
                        end;
                        C := False;
                    end;
                    if (J^.State = psFull) or (J^.State = psUpgrade) or (J^.State = psReplace) then begin
                        if not C then begin
                            TextAttr := Theme.Inst;
                            HelpWriteLn(' install ' + lcase(TailDelim(FMedia) + TailDelim(P^.Name) + J^.Name + '.zip'));
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
        if M = 0 then HelpWriteLn('No changes.') else begin
            HelpWriteLn('');
            if M = 1 then
                HelpWriteLn('1 change.')
            else
                HelpWriteLn(IntStr(M) + ' changes.');
        end;
        HelpWriteLn('');
        ClearEvent(E);
        While E.What = evNothing do begin
            asm HLT end;
            GetEvent(E);
        end;
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


procedure DrawFileBox(Title : String);
const
    Height = 12;
var
    Mid : integer;
begin
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
        Lo(ScreenMax) - Theme.Frame.X - 7, Mid + Height div 2 - 2);
    FWriteLn(' ' + Title);
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
    X := WhereX;
    Y := WhereY;
    Cursor  := GetCursor;
    HideCursor;
    TempStr := CustomFile;
    if CheckScroll then
        Wide := GetMaxX - X
    else
        Wide := GetMaxX - X + 1;
    if Not EditLn(TempStr, True, ESize, Wide, Event) then
        repeat
            if Event.What = evKeyDown then case Event.KeyCode of
                $001b, $0009, $0f00 : begin
                    EditCustomFile := Event.KeyCode;
                    Break;
                end;
            end;
            GotoXY ( X, Y );
        until EditLn(TempStr, False, ESize, Wide, Event);
    SetCursor ( Cursor );
    CustomFile := TempStr;
    TextAttr := $71;
    GotoXY(1, 3);
    FWrite(' ' + Copy(CustomFile, 1, GetMaxX - 1));
    ClrEol;
end;

procedure DrawBoxParts(Saving : boolean; Focus : integer);
begin
    TextAttr := $71;
    GotoXY(2, 3);
    FWrite(Copy(CustomFile, 1, GetMaxX - 1));
    GotoXY(1, 4);
    FWriteLn('');
    if Focus = 1 then TextAttr := $1F else TextAttr := $70;
    FWriteLn(' [' + WhichStr(CustomRemovals, ' ', 'X') + '] Include package removals. ');
    if Saving then begin
    end else begin
    end;
    GotoXY(GetMaxX div 2 - 5, GetMaxY);
    if Focus = 2 then TextAttr := $1F else TextAttr := $70;
    FWrite(CSpace('OK', 12));
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
            While E.What = evNothing do begin
                asm HLT end;
                GetEvent(E);
            end;
        end else begin
            E.What := evKeyDown;
            E.KeyCode := EF;
        end;
        if E.What and evKeyDown = evKeyDown then
            case E.KeyCode of
                $000d : if Focus = 2 then begin
                    RunFileBox := True;
                    Quit := True;
                end;
                $001b : Quit := True;
                $0009 : begin
                   if Focus < 2 then
                        Inc(Focus)
                    else
                        Focus := 0;
                end;
                $0F00 : begin
                   if Focus > 0 then
                        Dec(Focus)
                    else
                        Focus := 2;
                end;
            else
                Focus := 0;
            end;
    until Quit;
end;

procedure LoadCustom;
begin
    DrawFileBox('Load package list customizations:');
    RunFileBox(false);
    Redraw;
end;

procedure SaveCustom;
begin
    DrawFileBox('Save package list customizations:');
    RunFileBox(true);
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
begin
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
        if (S = '/HELP') or (S = '/?') then
            CommandLineHelp
        else if (S = '/LISTS') then begin
            RunMode := rmList;
            FileList := True;
            CheckMark := ListCheckMarks;
        end else if (S = '/CONFIG') then begin
            RunMode := rmConfig;
            FileList := True;
            CheckMark := ListCheckMarks;
            if DirExists('\FDSETUP\SETUP\') then
                ListDir := '\FDSETUP\SETUP\'
            else
                ListDir := '';
        end else if S = '/FDI' then begin
            RunMode := rmFDI;
            Comments := False;
            FileList := True;
            AutoUpdate := False;
            CheckMark := NormalCheckMarks;
        end else if S = '/NOFILES' then
            FileList := False
        else if S = '/FILES' then
            FileList := True
        else if S = '/NOUPDATE' then
            AutoUpdate := False
        else if S = '/UPDATE' then
            AutoUpdate := True
        else begin
            FWriteLn('invalid parameter "' + ParamStr(I) + '"');
            Halt(100);
        end;
        inc(I);
    end;
    UpdateOn := false;
    SetTheme;
    Init;
    if AutoUpdate then UpdateToggle(True);
    StartUp := False;
    CheckScroll := False;
    CheckCursor := False;
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
        DrawStatus;
        ClearEvent(E);
        While E.What = evNothing do begin
            asm HLT end;
            GetEvent(E);
        end;
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
                    rmStandAlone : ShowPending;
                end;
                $0052, $0072 : case RunMode of
                    rmStandAlone : LoadCustom;
                end;
                $0057, $0077 : case RunMode of
                    rmStandAlone : SaveCustom;
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
                    FWrite(HexStr(E.KeyCode));
                    ClrEol;
}
            end;
    until Quit;
end;

begin
    Main;
end.