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

{$M 50000,102400,102400} (* Memory: Largest Stack, 100K Minimum / Maximum *)

{$I QCRT.DEF}
program Test;

uses QCrtNM, QDos, QStrings;

const
    Frame : TPoint = (X:5; Y:4);
    Grps : TPoint = (X:18; Y:8);
    NoScroll = 1;
    ALLPackages = '..\FDI\SETTINGS\PKG_ALL.LST';
    BASEPackages = '..\FDI\SETTINGS\PKG_BASE.LST';
{    ALLPackages = 'FDPLALL.LST';
    BASEPackages = 'FDPLBASE.LST'; }


type
    PItem = ^TItem;
    TItem = record
        Prev, Next, Items : PItem;
        Name : Str12;
        State : integer;
        Title : PString;
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
begin
    Defaults := nil;
    FileMode := 0; { not needed }
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
end;

function CheckDefault(S : String) : boolean;
var
    P : PText;
begin
    CheckDefault := false;
    P := Defaults;
    while assigned(P) do begin
        if PtrStr(P^.Str) = S then begin
            CheckDefault := true;
            exit;
        end;
        P := P^.Next;
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

procedure Init;
var
   S : TSearchRec;
   P, J : PItem;
   CS, NS : integer;
begin
    ReadDefaults;
    F := ValueOf('TFF', White);
    H := ValueOf('TFH', LightGreen);
    B := ValueOf('TFB', Red);
    C := ValueOf('TFC', $1e);
    Tab := 0;
    GroupLast := nil;
    GroupFirst := nil;
    FindFirst(GetEnv('FMEDIA') + '\*.*', faAnyFile, S);
    while DosError = 0 do begin
        if (S.Attr and faDirectory = faDirectory) and (S.Name <> '.') and
        (S.Name <> '..') then begin
            P := New(PItem);
            P^.Name := S.Name;
            P^.Prev := GroupLast;
            P^.Items := nil;
            P^.Next := nil;
            P^.Title := nil;
            P^.State := 0;
            if not Assigned(GroupFirst) then
                GroupFirst := P
            else
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
        if (P^.Name = 'BASE') and CheckDefault('BASE\WELCOME') then begin
            J := New(PItem);
            J^.Name := 'WELCOME';
            J^.Items := nil;
            J^.Next := nil;
            J^.Title := nil;
            J^.State := 1;
            PackageFirst := J;
            PackageLast := J;
        end;
        FindFirst(GetEnv('FMEDIA') + '\' + P^.NAME + '\*.ZIP', faAnyFile, S);

        while DosError = 0 do begin
            if (S.Attr and faDirectory <> faDirectory) and (S.Name <> '.') then begin
                J := New(PItem);
                J^.Name := Copy(S.Name, 1, Length(S.Name) - 4);
                J^.Prev := PackageLast;
                J^.Items := nil;
                J^.Next := nil;
                J^.Title := nil;
                J^.State := 0;
                if CheckDefault(Ucase(P^.Name) + '\' + Ucase(J^.Name)) then begin
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
        if CS = 0 then
            P^.State := 0
        else begin
            if NS = 0 then
                P^.State := 1
            else
                P^.State := 2;
        end;
        J := P;
        P := P^.Next;
        if Assigned(PackageFirst) then begin
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
    GroupTop := GroupFirst;
    GroupBottom := nil;
    Package := nil;
    PackageFirst := nil;
    PackageTop := nil;
    PackageLast := nil;
    PackageBottom := nil;
end;

procedure DrawPackage;
var
    Y : integer;
begin
    TextColor(F);
    TextBackground(B);
    Window (Frame.X + 2, Frame.Y + Grps.Y + 2, Lo(ScreenMax) - Frame.X, Hi(ScreenMax)- Frame.Y + 1);
    ClrScr;
    if Tab = 2 then
        TextAttr := C;
    if assigned(Package) then
        Write(RSpace(' ' + Package^.Name + ' - No information', Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));

    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
end;

procedure DrawFiles;
var
    P : PItem;
    Y : integer;
begin
    TextColor(F);
    TextBackground(B);
    Window (Frame.X + 4 + Grps.X - NoScroll, Frame.Y + 1, Lo(ScreenMax) - Frame.X, Frame.Y + Grps.Y);
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
        Write(' ');
        if P <> Package then TextColor(DarkGray);
        Write('[');
        if P <> Package then TextColor(Yellow);
        case P^.State of
            1 : Write('X');
            2 : Write('+');
        else
            Write(#32);
        end;
        if P <> Package then TextColor(DarkGray);
        Write(']');
        if P <> Package then TextColor(F);
        Write(RSpace(' ' + P^.Name, Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
        PackageBottom := P;
        P := P^.Next;
        Inc(Y);
    end;
    TextColor(F);
    TextBackground(B);
    while (Y <= Grps.Y) do begin
        Write(RSpace('', Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
        Inc(Y);
    end;
    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    DrawPackage;
end;

procedure DrawGroups;
var
    P : PItem;
    Y : integer;
begin
    TextColor(F);
    TextBackground(B + 1);
    Window (Frame.X + 2, Frame.Y + 1, Frame.X + 2 - NoScroll + Grps.X, Frame.Y + Grps.Y);
    { ClrScr; }
    P := GroupTop;
    Y := 1;
    GroupBottom := nil;
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
        Write(' ');
        if P <> Group then TextColor(DarkGray);
        Write('[');
        if P <> Group then TextColor(Yellow);
        case P^.State of
            1 : Write('X');
            2 : Write('+');
        else
            Write(#32);
        end;
        if P <> Group then TextColor(DarkGray);
        Write(']');
        if P <> Group then TextColor(F);
        Write(RSpace(' ' + P^.Name, Lo(WindMax) - Lo(WindMin) - WhereX + 1 + NoScroll));
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
    Write( CSpace('OK', 10));
    GotoXY (WhereX + 5, WhereY);
    TextColor(F);
    TextBackground(B);
    if Tab = 4 then
        TextAttr := C;
    Write( CSpace('Cancel', 10));
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

procedure GroupToggle;
var
    P : PItem;
begin
    if not Assigned(Group) then exit;
    Inc(Group^.State);
    if Group^.State > 1 then Group^.State := 0;
    P := Group^.Items;
    while assigned(P) do begin
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
    Assign(F, GetEnv('TEMP') + '\FDIMPLES.LST');
    Rewrite(F);
    P := GroupFirst;
    while assigned(P) do begin
        J := P^.Items;
        while assigned(J) do begin
            if J^.State <> 0 then
                WriteLn(F, lcase(P^.Name + '\' + J^.Name));
            J := J^.Next;
        end;
        P := P^.Next;
    end;
    Close(F);
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
        if LTab <> Tab then begin
            DrawGroups;
            DrawButtons;
            LTab := Tab;
        end;
        Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
        ClearEvent(E);
        While E.What = evNothing do GetEvent(E);
        if E.What and evKeyDown = evKeyDown then
            case E.KeyCode of
                $03 : Halt(200); { CTRL-C }
                $001b : Halt(1); { Esacpe }
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
                        MakeList;
                        Quit := True;
                    end;
                    4: Halt(1); { Canceled }
                end;
                $0009 : begin
                    if Tab >= 4 then
                        Tab := 0
                    else
                        Inc(Tab);
                end;
                $0F00 : begin
                    if Tab <= 0 then
                        Tab := 4
                    else
                        Dec(Tab);
                end;
{                else
                    writeln(HexStr(E.KeyCode)); }
            end;
    until Quit;
end;

begin
    CheckScroll := False;
    CheckCursor := False;
    Init;
    DrawSelector;
   { WriteLn(MaxAvail); }
    Main;
end.