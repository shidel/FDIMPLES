{
    Copyright 2019 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit QCrt; { QuickCrt 9, Crt Video Unit }

{$D-,I-,S-,F+}

interface

const
    { CRT modes }
    BW40          = 0;      { 40x25 B/W on Color adapter }
    CO40          = 1;      { 40x25 Color on Color adapter }
    BW80          = 2;      { 80x25 B/W on Color adapter }
    CO80          = 3;      { 80x25 Color on Color adapter }
    Mono          = 7;      { 80x25 on Monochrome adapter }
    Font8x8       = $0800;  { Add-in for 8x8 ROM font }
    Font8x14      = $0E00;  { Add-in for 8x14 ROM font, EGA and VGA }
    Font8x16      = $1000;  { Add-in for 8x16 ROM font, VGA only }
    FontUser      = $4000;  { Add-in for User defined font, VGA only }
    FontDouble    = $8000;  { Add-in for special font width doubling mode.
                              Note: When enabled, Blink and Intensity
                              background colors are disabled. }

    { Mode constants for 3.0 compatibility }
    C40           = CO40;
    C80           = CO80;

    { Foreground and background color constants }
    Black         = 0;
    Blue          = 1;
    Green         = 2;
    Cyan          = 3;
    Red           = 4;
    Magenta       = 5;
    Brown         = 6;
    LightGray     = 7;

    { Foreground color constants }
    DarkGray      = 8;
    LightBlue     = 9;
    LightGreen    = 10;
    LightCyan     = 11;
    LightRed      = 12;
    LightMagenta  = 13;
    Yellow        = 14;
    White         = 15;

  { Add-in for blinking and intense background constants }
    Blink         = $80;
    Intensity     = Blink;

  { TTL Monochrome attributes constants }
    Underline               = $01;
    Normal                  = $07;
    BrightUnderline         = $09;
    Bold                    = $0F;
    Reverse                 = $70;
    BlinkingUnderline       = $81;
    BlinkingNormal          = $87;
    BlinkingBrightUnderline = $89;
    BlinkingBold            = $8F;

  { One-Color composite attributes constants }
  { Normal                  = $07; }
    GrayOnBlack             = $08;
  { Bold                    = $0F; }
  { Reverse                 = $70; }
    GrayOnWhite             = $78;
    WhiteOnWhite            = $7F;
  { BlinkingNormal          = $87; }
  { BlinkingBold            = $8F; }

var
    CheckBreak  : boolean;  { Enable Ctrl-Break }
    CheckEOF    : boolean;  { Enable Ctrl-Z }
    DirectVideo : boolean;  { Enable direct video addressing }
    CheckSnow   : boolean;  { Enable snow filtering }
    LastMode    : word;     { Current text mode }
    TextAttr    : byte;     { Current text attribute }
    WindMin     : word;     { Window upper left coordinates }
    WindMax     : word;     { Window lower right coordinates }

    { Additional global variables }
    Check101Key : boolean;  { True when a 101-key keyboard is present }
    CheckScroll : boolean;  { Default true, characters written to last position
                              in a window, cause the window to scroll }
    UserFontHeight : byte;  { Height in scan lines of user defined font }
    UserFontPtr    : Pointer; { Pointer to user font }
    TabWidth       : byte;  { Spaces per Tab Character }
    ScreenMax      : word;  { Screen Lower right coordinates }

    {$IFDEF EnableMouse}
    MouseButtons     : integer;    { Number of buttons, 0 if no mouse }
    MouseVisible     : boolean;    { Visible state of mouse }
    MouseCellX       : word;       { Value to slow down movement }
    MouseCellY       : word;       { Value to slow down movement }
    MouseClickSpeed  : word;       { Mouse double click speed }
    MouseHomeX       : integer;    { X Home position of mouse }
    MouseHomeY       : integer;    { Y Home position of mouse }
    {$ENDIF}


{ Standard procedures and functions }
procedure AssignCrt(var F : text);
function KeyPressed : boolean;
function ReadKey : char;
procedure TextMode(Mode : word);
procedure Window(X1, Y1, X2, Y2 : byte);
procedure GotoXY(X, Y : byte);
function WhereX: byte;
function WhereY: byte;
procedure ClrScr;
procedure ClrEol;
procedure InsLine;
procedure DelLine;
procedure TextColor(Color : byte);
procedure TextBackground(Color : byte);
procedure LowVideo;
procedure HighVideo;
procedure NormVideo;
procedure Delay(MS : word);
procedure Sound(Hz : word);
procedure NoSound;

{ Additional procedures and functions }

function KeyPressedEnhanced : boolean;
{ Enhanced 101-key keyboard version }

function ReadKeyEnhanced : word;
{ Enhanced 101-key keyboard version }

procedure CarriageReturn;
{ preform a CarriageReturn }

procedure LineFeed;
{ preform a LineFeed }

procedure BackSpace;
{ preform a BackSpace }

procedure Tab;
{ preform a Tab }

procedure InsChar;
procedure DelChar;
procedure InsColumn;
procedure DelColumn;

procedure ScrollUp(Rows : byte);
procedure ScrollDown(Rows : byte);
procedure ScrollLeft(Columns : byte);
procedure ScrollRight(Columns : byte);

procedure WriteRawPStr(S : String);
{ Ultra fast write Pascal String to screen, special characters are shown. }
procedure WriteRawZStr(S : pointer);
{ Ultra fast write ASCIIZ String to screen, special characters are shown. }

procedure HideCursor;
procedure InsertCursor;
procedure NormalCursor;
procedure SmallCursor;
procedure HalfCursor;
procedure FullCursor;

procedure SetCursor(Shape : Word);

{$IFDEF EnableMouse}
procedure MouseShow;
procedure MouseHide;

procedure MouseGotoXY(X, Y : byte);

function MouseWhereX : byte;
function MouseWhereY : byte;

function MouseMove: boolean;
function MouseClick : boolean;
function MouseDoubleClick : boolean;
function ReadMouse : integer;

{$ENDIF}

implementation

var
    OldExitProc : Pointer;

const
    { internal file mode constants }
    fmClosed           = $D7B0;
    fmInput            = $D7B1;
    fmOutput           = $D7B2;
    fmInOut            = $D7B3;

{ System Read & Write IO Redirection }
type
    PTextBuf = ^TTextBuf;
    TTextBuf = array [0..127] of char;
    TTextName = array [0..79] of char;
    TTextRec = record
      Handle    : word;
      Mode      : word;
      BufSize   : word;
      Private   : word;
      BufPos    : word;
      BufEnd    : word;
      BufPtr    : PTextBuf;
      OpenFunc  : function (var F) : integer;
      InOutFunc : function (var F) : integer;
      FlushFunc : function (var F) : integer;
      CloseFunc : function (var F) : integer;
      UserData  : array [1..16] of byte;
      Name      : TTextName;
      Buffer    : TTextBuf;
    end;

function ReadCRT(var BufPtr : PTextBuf; Size : word) : word;
begin
    ReadCRT := 0;
end;

function InOutCRT(var F) : integer;
var
    I  : word;
begin
    with TTextRec(F) do
    case Mode of
        $D7B1 : begin {fmInput}
             BufEnd := ReadCRT(BufPtr, BufSize);
             BufPos := 0;
        end;
        $D7B2 : begin {fmOutput}
            I := BufEnd;
            while I < BufPos do begin
                case byte(BufPtr^[I]) of
                    $0A : LineFeed;
                    $0D : CarriageReturn;
                    $08 : BackSpace;
                else
                    WriteRawPStr(BufPtr^[I])
                end;
                Inc(I);
                if I >= BufSize then I := 0;
            end;
            BufPos := 0;
        end; { * }
    end;
    InOutCrt := 0;
end;

function FlushCRT(var F) : integer;
var
    Ignored : integer;
begin
    case TTextRec(F).Mode of
        fmOutput : Ignored := InOutCrt(F);
        fmInput : begin
            TTextRec(F).BufEnd := 0;
            TTextRec(F).BufPos := 0;
        end;
    end;
    FlushCrt := 0;
end;

function CloseCRT(var F) : integer;
begin
    TTextRec(F).Mode := fmClosed;
    CloseCrt := 0;
end;

function OpenCRT(var F) : integer;
begin
    with TTextRec(F) do
        begin
            if Mode = fmInOut then
                Mode := fmOutput;
        end;
    OpenCrt := 0;
end;

procedure AssignCrt(var F : text);
const
    CrtNameID : array [0..4] of char = ('C', 'R', 'T', #0, #0);
begin
    with TTextRec(F) do begin
        Handle      := $FFFF;
        Mode        := fmClosed;
        BufSize     := Sizeof(Buffer);
        BufPtr      := @Buffer;
        OpenFunc    := OpenCrt;
        InOutFunc   := InOutCrt;
        FlushFunc   := FlushCrt;
        CloseFunc   := CloseCrt;
        Move(CrtNameID, Name, Sizeof(Name));
    end;
end;

{ External Assembly Routines }

{$L QCRT.OBJ}

function InitCrt : boolean; external;
procedure DoneCrt; external;
function KeyPressed : boolean; external;
function ReadKey : char; external;
function KeyPressedEnhanced : boolean; external;
function ReadKeyEnhanced : word; external;
procedure TextMode(Mode : word); external;
procedure Window(X1, Y1, X2, Y2 : byte); external;
procedure GotoXY(X, Y : byte); external;
function WhereX: byte; external;
function WhereY: byte; external;
procedure ClrScr; external;
procedure ClrEol; external;
procedure InsLine; external;
procedure DelLine; external;
procedure InsChar; external;
procedure DelChar; external;
procedure TextColor(Color : byte); external;
procedure TextBackground(Color : byte); external;
procedure LowVideo; external;
procedure HighVideo; external;
procedure NormVideo; external;
procedure Delay(MS : Word); external;
procedure Sound(Hz : Word); external;
procedure NoSound; external;
procedure WriteRawPStr(S : String); external;
procedure WriteRawZStr(S : pointer); external;
procedure CarriageReturn; external;
procedure LineFeed; external;
procedure BackSpace; external;
procedure Tab; external;
procedure HideCursor; external;
procedure InsertCursor; external;
procedure NormalCursor; external;
procedure SmallCursor; external;
procedure HalfCursor; external;
procedure FullCursor; external;
procedure ScrollUp(Rows : byte); external;
procedure ScrollDown(Rows : byte); external;
procedure ScrollLeft(Columns : byte); external;
procedure ScrollRight(Columns : byte); external;
procedure SetCursor(Shape : Word); external;
procedure InsColumn; external;
procedure DelColumn; external;

{$IFDEF EnableMouse}
procedure MouseShow; external;
procedure MouseHide; external;
procedure MouseGotoXY(X, Y : byte); external;
function MouseWhereX : byte; external;
function MouseWhereY : byte; external;
function MouseMove: boolean; external;
function MouseClick : boolean; external;
function MouseDoubleClick : boolean; external;
function ReadMouse : integer; external;

{$ENDIF}

{ initialization & finalization routines }
procedure UnitFinal;
begin
    ExitProc := OldExitProc;
    Assign(Output, '');
    Assign(Input, '');
    ReWrite(Output);
    Reset(Input);
    DoneCrt;
end;

procedure UnitInit;
begin
    if not InitCrt then Halt(10); { Internal Error }
    OldExitProc := ExitProc;
    ExitProc := @UnitFinal;
    AssignCrt(Output);
    Rewrite(Output);
{   AssignCRT(Input);
    Reset(Input); }
end;

begin
    UnitInit;
end.
