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

const
    LoMem = 10240;
    AppName = 'FDIMPLES';
    AppVersion = '0.6.0';
    AppTitle = 'FreeDOS Installer - My Package List Editor Software';
    Frame : TPoint = (X:5; Y:4);
    Grps : TPoint = (X:18; Y:8);
    Installed = 'Installed!'; {Always sorted first -- has only title, no name}
    NoScroll = 1;
{    ALLPackages = '..\FDI\SETTINGS\PKG_ALL.LST';
    BASEPackages = '..\FDI\SETTINGS\PKG_BASE.LST'; }
    ALLPackages = 'FDPLALL.LST';
    BASEPackages = 'FDPLBASE.LST';

type
    PItem = ^TItem;
    TItem = record
        Prev, Next, Items : PItem;
        Name : Str12;
        State : integer;
        Title : PString;
        First : boolean;
    end;
    PText = ^TText;
    TText = record
        Next : PText;
        Str : PString;
    end;

var
    Tab : integer;
    Defaults : PText;
    Group, GroupFirst, GroupTop, GroupBottom, GroupLast,
    Package, PackageFirst, PackageTop, PackageBottom, PackageLast : PItem;
    F, B, C, H : integer;
    FMedia : String;
    FDIMode : boolean;
    StartCursor : word;

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

procedure ReadDefaults;
var
    F : Text;
    S : String;
    L, P : PText;
    D : TSearchRec;
begin
    Defaults := nil;
    FileMode := 0; { not needed }
    if FDIMode then begin
        if FileExists(ALLPackages) then
            Assign(F, ALLPackages)
        else if FileExists(BASEPackages) then
            Assign(F, BASEPackages)
        else exit;
        Reset(F);
        L := nil;
        while Not EOF(F) do begin
            ReadLn(F, S);
            S := Trim(Ucase(S));
            if S[1] = ';' then S := '';
            if S <> '' then begin
                P := New(PText);
                P^.Next := nil;
                P^.Str := StrPtr(S);
                if assigned(L) then
                    L^.Next := P
                else
                    Defaults := P;
                L := P;
            end;
        end;
        Close(F);
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
begin
    if (not FDIMode) then exit;

    if not assigned(P) then exit;

    if not (P^.Name = B) then exit;

    if (not CheckDefault(TailDelim(B) + N)) then exit;

    J := New(PItem);
    J^.Name := N;
    J^.Items := nil;
    J^.Next := nil;
    J^.Prev := nil;
    J^.Title := nil;
    J^.First := true;
    J^.State := 1;
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
    Others^.State := 1;
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
            J := New(PItem);
            J^.Name := Copy(PtrStr(I^.Str), 2, 13);
            J^.Items := nil;
            J^.Next := Others^.Items;
            J^.Prev := nil;
            J^.Title := nil;
            J^.First := true;
            J^.State := 1;
            if assigned(Others^.Items) then
                Others^.Items^.Prev := J;
            Others^.Items := J;
        end;
        I := I^.Next;
    end;
end;

function FreeSomeMem : boolean;
begin
    FreeSomeMem := False;
end;

procedure AddLine(var P : PItem; S : String; NewLine : boolean);
{ Later add line appending }
var
    N, L, H : PItem;
    W, M : integer;
begin
    if MaxAvail < loMem then if not FreeSomeMem then exit;
    N := New(PItem);
    N^.Next := nil;
    N^.Prev := nil;
    N^.Name := '';
    W := Lo(ScreenMax) - Frame.X * 2 - 3;
    if Length(S) > W then begin
        M := LastPos(' ', copy(S, 1, W));
        if M > 0 then W := M;
        N^.Title := StrPtr(copy(S, 1, W));
        Delete(S, 1, W);
    end else begin
        N^.Title := StrPtr(S);
        S := '';
    end;
    if not assigned(P^.Items) then
        P^.Items := N
    else begin
        L := P^.Items;
        while Assigned(L) do begin
            H := L;
            L := L^.Next;
        end;
        H^.Next := N;
        N^.Prev := H;
    end;
    if S <> '' then AddLine(P, S, NewLine);
end;

procedure CacheGroup(var AGroup : PItem);
var
    Name, Ver, Desc, MD5 : String;
    P : Longint;
    F : File;
    C, D : integer;
    B : String;
    X : PItem;

    procedure ReadFile;
    begin
        P := FilePos(F);
        BlockRead(F, B[1], Sizeof(B) - 1, C);
        B[0] := chr(C);
        repeat
            D := Pos(#$0d, B);
            if D > 0 then Delete (B, D, 1);
        until D = 0;
        D := Pos(#$0a, B);
        if (D <> 0) and (D <= Ord(B[0])) then B[0] := Chr(D - 1);
        Seek(F, P + 1 + Ord(B[0]))
    end;

begin
    if MaxAvail < LoMem then if not FreeSomeMem then exit;

    if not AGroup^.First then exit;

    AGroup^.First := False;
    Name := FMedia + TailDelim(AGroup^.Name) + 'INDEX.LST';
    if not FileExists(Name) then exit;

    FileMode := 0;
    Assign(F, Name);
    Reset(F, 1);
    repeat
        ReadFile;
        if Trim(B) <> '' then begin
            Name := Trim(PullStr(#$09, B));
            Ver := Trim(PullStr(#$09, B));
            Desc := Trim(PullStr(#$09, B));
            MD5 := Trim(PullStr(#$09, B));
            if Ucase(Name) = 'FD-REPOV1' then begin
                AGroup^.Title := StrPtr(WCase(Desc));
            end;
            X := AGroup^.Items;
            while assigned(X) do begin
                if UCase(Name) = UCase(X^.Name) then begin
                    X^.Title := StrPtr(Copy(Desc, 1, Lo(ScreenMax) - Frame.X * 2 - Grps.X - 16));
                    AddLine(X, Name + ' (' + ver + ')', True);
                    AddLine(X, '', True);
                    AddLine(X, Desc, D <> 0);
                    while (C <> 0) and (D = 0) do begin
                        ReadFile;
                        AddLine(X, B, D <> 0);
                    end;
                    X := nil;
                end else
                    X := X^.Next;
            end;
        end;
    until (C = 0);
    Close(F);
end;

function IsMediaDrive(S : String) : boolean;
begin
    IsMediaDrive := False;
    S := TailDelim(S);
    if DirExists(S) and
    FileExists(TailDelim(S + 'BASE') + 'COMMAND.ZIP') and
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
    reset(F);
    while Not eof(F) do begin
        ReadLn(F, T);
        T := Trim(T);
        if T <> '' then ReadCfg := T;
    end;
    Close(F);
end;

procedure Init;
var
   S : TSearchRec;
   P, J, Others : PItem;
   CS, NS : integer;
   T, M : String;

begin
    if Trim(GetEnv('FMEDIA')) <> '' then begin
        FMedia := TailDelim(Dir(Trim(GetEnv('FMEDIA'))));
    end;

    FDIMode := Ucase(ParamStr(1)) = '/FDI';
    if not FDIMode then begin
        if (FMedia <> '') and (not DirExists(FMedia)) then FMedia := '';
        if Not FileExists(TailDelim(GetEnv('DOSDIR')) + 'BIN\FDINST.EXE') then begin
            WriteLn('unable to located package manager FDINST.');
            Halt(100);
        end;
        if (GetEnv('TEMP') = '') or (not DirExists(GetEnv('TEMP'))) then begin
            WriteLn('TEMP environment variable is not set.');
            Halt(2);
        end;
        StartCursor := GetCursor;
        HideCursor;
        Write('Please standby...');
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
    F := ValueOf('TFF', White);
    H := ValueOf('TFH', LightGreen);
    B := ValueOf('TFB', Red);
    C := ValueOf('TFC', $1e);
    Tab := 0;
    Group := nil;
    Others := New(PItem);
    GroupFirst := Others;
    GroupLast := GroupFirst;
    with GroupFirst^ do begin
        Name := '';
        Items := nil;
        Prev := nil;
        Next := nil;
        First := True;
        State := 1;
        Title := StrPtr(Installed);
    end;
    FindFirst(FMedia + '*.*', faAnyFile, S);
    while DosError = 0 do begin
        if (S.Attr and faDirectory = faDirectory) and (S.Name <> '.') and
        (S.Name <> '..') then begin
            P := New(PItem);
            P^.Name := S.Name;
            P^.Prev := GroupLast;
            P^.Items := nil;
            P^.Next := nil;
            P^.Title := nil;
            P^.First := True;
            P^.State := 0;
            GroupLast^.Next := P;
            GroupLast := P;
        end;
        FindNext(S);
    end;

    SortList(GroupFirst, GroupLast);
    P := GroupFirst;
    while Assigned(P) do begin
        CS := 0;
        NS := 0;
        PackageFirst := nil;
        PackageLast := nil;

        AddCustomItems(P, 'BASE', 'WELCOME');
        AddCustomItems(P, 'UTIL', 'V8POWER');

        if P^.NAME <> '' then begin
            FindFirst(FMedia + TailDelim(P^.NAME) + '*.ZIP', faAnyFile, S);

            while DosError = 0 do begin
                if (S.Attr and (faDirectory or faSystem or faHidden) = 0) and
                (S.Name <> '.') and ((S.Name <> 'V8POWER.ZIP') or (Not FDIMode)) then begin
                    J := New(PItem);
                    J^.Name := Copy(S.Name, 1, Length(S.Name) - 4);
                    J^.Prev := PackageLast;
                    J^.Items := nil;
                    J^.Next := nil;
                    J^.Title := nil;
                    J^.First := True;
                    J^.State := 0;
                    if CheckDefault(Ucase(TailDelim(P^.Name)) + Ucase(J^.Name)) then begin
                        J^.State := 1;
                        inc(CS);
                    end else
                        inc(NS);
                    if not Assigned(PackageFirst) then
                        PackageFirst := J
                    else
                        PackageLast^.Next := J;
                    PackageLast := J;
                end;
                FindNext(S);
            end;
        end;
        if CS = 0 then
            P^.State := 0
        else begin
            if NS = 0 then
                P^.State := 1
            else
                P^.State := 2;
        end;
        P^.Items := PackageFirst;
        P := P^.Next;
    end;

    if (not FDIMode) then
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
    if not FDIMode then begin
        GotoXY(1,WhereY);
        ClrEol;
    end;
end;

procedure FetchData;
begin
end;

procedure DrawPackage;
var
    Y : integer;
    P : PItem;
    D : PText;
begin
    TextColor(F);
    TextBackground(B);
    TextColor(F);
    if Tab = 2 then
        TextAttr := C;
    Window (Frame.X + 2, Frame.Y + Grps.Y + 2, Lo(ScreenMax) - Frame.X, Hi(ScreenMax)- Frame.Y + 1);
    ClrScr;
    if assigned(Package) then begin
        if not assigned(Package^.Items) then
            FWrite(RSpace(' ' + Package^.Name + ' - No information',
            Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll))
        else begin
            if Package^.First then begin
                FetchData;
            end;
            P := Package^.Items;
            Y := 1;
            while Assigned(P) and (Y <= Hi(WindMax) - Hi(WindMin) + 1)  do begin
                GotoXY(2,Y);
                if Tab <> 2 then begin
                    if Y = 1 then TextColor(H) else TextColor(F);
                end;
                FWrite(PtrStr(P^.Title));
                Inc(Y);
                P := P^.Next;
            end;
        end;
    end;
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
end;

procedure DrawFiles;
var
    P : PItem;
    Y : integer;
    S : String;
begin
    TextColor(F);
    TextBackground(B);
    Window (Frame.X + 4 + Grps.X - NoScroll, Frame.Y + 1, Lo(ScreenMax) - Frame.X, Frame.Y + Grps.Y);
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
    while Assigned(P) and (Y <= Grps.Y) do begin
        GotoXY(1,Y);
        TextBackground(B);
        if P <> Package then
            TextColor(F)
        else begin
            if Tab <> 1 then
                TextColor(H)
            else
                TextAttr := C;
        end;
        FWrite(' ');
        if P <> Package then TextColor(DarkGray);
        FWrite('[');
        if P <> Package then TextColor(Yellow);
        case P^.State of
            1 : FWrite('X');
            2 : FWrite('+');
        else
            FWrite(#32);
        end;
        if P <> Package then TextColor(DarkGray);
        FWrite(']');
        if P <> Package then TextColor(F);
        S := P^.Name;
        if assigned(P^.Title) then
            S := Trim(Copy(RSpace(P^.Name, 9) + ' ' + PtrStr(P^.Title), 1,
            Lo(WindMax) - Lo(WindMin) - WhereX + NoScroll));
        FWrite(RSpace(' ' + S, Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
        PackageBottom := P;
        P := P^.Next;
        Inc(Y);
    end;
    TextColor(F);
    TextBackground(B);
    while (Y <= Grps.Y) do begin
        FWrite(RSpace('', Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
        Inc(Y);
    end;
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    DrawPackage;
end;

procedure DrawGroups;
var
    P : PItem;
    Y : integer;
    S : String;
begin
    TextColor(F);
    TextBackground(B + 1);
    Window (Frame.X + 2, Frame.Y + 1, Frame.X + 2 - NoScroll + Grps.X, Frame.Y + Grps.Y);
    { ClrScr; }
    P := GroupTop;
    Y := 1;
    GroupBottom := nil;
    if Assigned(Group) and (Group^.First) then CacheGroup(Group);
    while Assigned(P) and (Y <= Grps.Y) do begin
        GotoXY(1,Y);
        TextBackground(B);
        if P <> Group then
            TextColor(F)
        else begin
            if Tab <> 0 then
                TextColor(H)
            else
                TextAttr := C;
        end;
        FWrite(' ');
        if P <> Group then TextColor(DarkGray);
        FWrite('[');
        if P <> Group then TextColor(Yellow);
        case P^.State of
            1 : FWrite('X');
            2 : FWrite('+');
        else
            FWrite(#32);
        end;
        if P <> Group then TextColor(DarkGray);
        FWrite(']');
        if P <> Group then TextColor(F);
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
    Gotoxy (Lo(ScreenMax) - Frame.X - 25, Hi(ScreenMax)- Frame.Y + 1);
    TextColor(F);
    TextBackground(B);
    if Tab = 3 then
        TextAttr := C;
    FWrite( CSpace('OK', 10));
    GotoXY (WhereX + 5, WhereY);
    TextColor(F);
    TextBackground(B);
    if Tab = 4 then
        TextAttr := C;
    FWrite( CSpace('Cancel', 10));
end;

procedure DrawSelector;
begin
    { Back Drop }
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    TextColor(ValueOf('TSF', LightGray));
    TextBackground(ValueOf('TSB', Black));
    TextChar := Char(ValueOf('TSC', $B0));
    ClrScr;
    { Window Box }
    TextChar := #32;
    TextColor(F);
    TextBackground(B);
    Window(Frame.X, Frame.Y, Lo(ScreenMax) + 2 - Frame.X, Hi(ScreenMax) + 2 - Frame.Y);
    ClrScr;
    Window(1,1,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    if Pos('DOUBLE', StrOf('TFS', 'double shadow')) > 0 then
        DrawBox(Frame.X + 1, Frame.Y, Lo(ScreenMax) + 1 - Frame.X, Hi(ScreenMax) + 2 - Frame.Y, bxDouble);
    if Pos('DOUBLE', StrOf('TFS', 'double shadow')) = 0 then
        DrawBox(Frame.X + 1, Frame.Y, Lo(ScreenMax) + 1 - Frame.X, Hi(ScreenMax) + 2 - Frame.Y, bxSingle);
    DrawLine(Frame.X + 1, Frame.Y + Grps.Y + 1, Lo(ScreenMax) - Frame.X * 2 + 1, lnSingle or lnHorizontal);
    DrawLine(Frame.X + Grps.X + 3 - NoScroll, Frame.Y, Grps.Y + 2, lnSingle or lnVertical);
    if Pos('SHADOW', StrOf('TFS', 'double shadow')) > 0 then
        DrawShadow(Frame.X + 1, Frame.Y, Lo(ScreenMax) + 2 - Frame.X, Hi(ScreenMax) + 2 - Frame.Y, bsDoubleWide);
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
end;

procedure DrawTitle;
begin
    if FDIMode then exit;
    TextAttr := $4F;
    GotoXY(1,1);
    ClrEol;
    GotoXY(40 - (Length(AppTitle + ' ' + AppVersion + ' ()' + AppName ) div 2), 1);
    FWrite(AppTitle + ' ');
    TextAttr := $4E;
    FWrite(AppVersion);
    TextAttr := $4F;
    FWrite(' (' + AppName + ')');
end;

procedure GroupToggle;
var
    P : PItem;
begin
    if not Assigned(Group) then exit;
    Inc(Group^.State);
    if Group^.State > 1 then Group^.State := 0;
    P := Group^.Items;
    while assigned(P) do begin
{        if (Group^.State <> 0) or ((P^.Name <> 'FDNPKG') and (P^.NAME <> 'FDIMPLES')) then }
            P^.State := Group^.State;
        P := P^.Next;
    end;
    DrawGroups;
end;

procedure FileToggle;
var
    P : PItem;
    NS, CS : integer;
begin
    if not assigned(Package) then exit;
    Inc(Package^.State);
    if Package^.State > 1 then Package^.State := 0;
    P := Group^.Items;
    NS := 0;
    CS := 0;
    while assigned(P) do begin
         if P^.State > 0 then begin
            inc(CS);
         end else
            inc(NS);
        P := P^.Next;
    end;
    if CS = 0 then
        Group^.State := 0
    else begin
        if NS = 0 then
            Group^.State := 1
        else
            Group^.State := 2;
    end;
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
end;

procedure TextDown(T:integer);
begin
end;

procedure MakeList;
var
    P, J : PItem;
    F : Text;
    S : String;
begin
    FileMode := 2;
    Assign(F, TailDelim(GetEnv('TEMP')) + 'FDIMPLES.LST');
    Rewrite(F);
    P := GroupFirst;
    while assigned(P) do begin
        J := P^.Items;
        while assigned(J) do begin
            if J^.State <> 0 then
                WriteLn(F, lcase(P^.Name + Delimiter + J^.Name));
            J := J^.Next;
        end;
        P := P^.Next;
    end;
    Close(F);
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
            if J^.State = 0 then begin
                if C then begin
                    TextAttr := $4F;
                    write ('remove ', J^.Name);
                    ClrEOl;
                    TextAttr := $07;
                    WriteLn;
                    SwapIntVecs;
                    {$IFDEF USEBAT}

                        Exec(GetEnv('COMSPEC'),'/C ' + TailDelim(GetEnv('TEMP')) +'FDINST.BAT remove ' + J^.Name);
                    {$ELSE}
                        Exec(TailDelim(GetEnv('DOSDIR')) + 'BIN\FDINST.EXE', 'remove ' + J^.Name);
                    {$ENDIF}
                    SwapIntVecs;
                    InitQCrt;
                    if DosError <> 0 then begin
                        WriteLn('Aborted.');
                        Halt(100);
                    end;
                end;
            end else begin
                if not C then begin
                    TextAttr := $1F;
                    write('install ', lcase(TailDelim(FMedia) + TailDelim(P^.Name) + J^.Name + '.zip'));
                    ClrEOl;
                    TextAttr := $07;
                    WriteLn;
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

procedure Main;
var
    E : TEvent;
    LTab : integer;
    Quit : boolean;
begin
    LTab := -1;
    Quit := False;
    PurgeEvents;
    repeat
        if Group = nil then Tab := 4;
        if LTab <> Tab then begin
            DrawGroups;
            DrawButtons;
            LTab := Tab;
        end;
        Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
        if not FDIMode then begin
            gotoXY(1,Hi(WindMax));
            TextAttr := $47;
            Write(' ', MaxAvail, '/', MemAvail, ' ');
            if Not Assigned(Group) then begin
                Write(NoTailDelim(FMedia));
            end else begin
                if Group^.Name <> '' then begin
                    Write(TailDelim(FMedia), TailDelim(Group^.Name));
                    if Assigned(Package) then Write(Package^.Name, '.ZIP');
                end else begin
                    if Assigned(Package) then Write( 'Package ', Package^.Name,
                    ' not found under ', NoTailDelim(FMedia));
                end;
            end;
            ClrEol;
        end;
        ClearEvent(E);
        While E.What = evNothing do GetEvent(E);
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
                $4800 : case Tab of
                    0: GroupUp(1);
                    1: FileUp(1);
                    2: TextUp(1);
                end;
                $4900 : case Tab of
                    0: GroupUp(Grps.Y - 1);
                    1: FileUp(Grps.Y - 1);
                    2: TextUp(Grps.Y - 1);
                end;
                $5000 : case Tab of
                    0: GroupDown(1);
                    1: FileDown(1);
                    2: TextDown(1);
                end;
                $5100 : case Tab of
                    0: GroupDown(Grps.Y - 1);
                    1: FileDown(Grps.Y - 1);
                    2: TextDown(Grps.Y - 1);
                end;
                $0020, $000A, $000D : case Tab of
                    0: GroupToggle;
                    1, 2 : FileToggle;
                    3: begin
                        if FDIMode then
                            MakeList
                        else
                            RunList;
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
{                else
                    GotoXY(1, Hi(WindMax) - 1);
                    write(HexStr(E.KeyCode));
                    ClrEol; }
            end;
    until Quit;
end;

begin
    CheckScroll := False;
    CheckCursor := False;
    Init;
    DrawTitle;
    DrawSelector;
    Main;
end.