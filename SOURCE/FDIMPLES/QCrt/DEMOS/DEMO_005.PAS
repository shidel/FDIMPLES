{
    Copyright 2016 Jerome Shidel
    Released Under GPL v2.0 License.
}

program Test;

uses QCrt;

    var
        Ticks : longint absolute $0040:$006c;
        Start : longint;

    procedure Intro;
    begin
        WriteLn('Hello, World! (Demo #5)');
        WriteLn('  Mouse Support:', MouseButtons > 0);
        WriteLn('  Mouse Buttons:', MouseButtons);
        WriteLn('  Mouse Visible:', MouseVisible);
        WriteLn;
        WriteLn('Press a key to continue.');
        while not Keypressed do begin
            if MouseClick or MouseMove then begin
                gotoXY(1, WhereY);
                Write(MouseWhereX, ':', MouseWhereY);
                Write(' - ');
                if MouseDoubleClick then
                    WriteLn('Double Click ', ReadMouse)
                else if MouseClick then
                    WriteLn('Single Click ', ReadMouse)
                else
                    WriteLn('Move');
            end;
        end;
        ReadKey;
        Start := Ticks;
    end;

    function Elapsed : real;
    begin
        Elapsed:=((Ticks - Start) / 18.2);
    end;

    procedure Demo;
    begin
        Intro;
        NoSound;
        { WriteLn('Elapsed: ', Elapsed:1:2);
        Delay(1000);}
        TextAttr := $07;
        Window(1, 1, Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
        ClrScr;
    end;

begin
    Demo;
{    TextMode(CO40);
    Demo;
    TextMode(CO80);
    Demo; }
end.