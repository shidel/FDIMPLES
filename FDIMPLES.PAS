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

{$I QCRT.DEF}
program Test;

uses QCrt, QDos, QStrings;

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

procedure Init;
begin
end;

procedure DrawSelector;
begin

    Window(1,2,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    TextColor(ValueOf('TSF', Gray));
    TextBackground(ValueOf('TSB', Black));
    TextChar := Char(ValueOf('TSC', $B0));
    ClrScr;
    TextChar := #32;
    TextColor(ValueOf('TFF', White));
    TextBackground(ValueOf('TFB', Red));
    Window(5, 4, Lo(ScreenMax) - 3, Hi(ScreenMax) - 2);
    ClrScr;
    Window(1,1,Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
    if Pos('SHADOW', StrOf('TFS', 'double shadow')) > 0 then
        DrawShadow(5, 4, Lo(ScreenMax) - 3, Hi(ScreenMax) -2, bsDoubleWide);
    if Pos('SINGLE', StrOf('TFS', 'double shadow')) > 0 then
        DrawBox(6, 4, Lo(ScreenMax) - 4, Hi(ScreenMax) -2, bxSingle);
    if Pos('DOUBLE', StrOf('TFS', 'double shadow')) > 0 then
        DrawBox(6, 4, Lo(ScreenMax) - 4, Hi(ScreenMax) -2, bxDouble);
end;

begin
    Init;
    DrawSelector;
end.