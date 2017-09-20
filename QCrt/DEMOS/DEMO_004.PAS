{
    Copyright 2016 Jerome Shidel
    Released Under GPL v2.0 License.
}

program Test;

uses QCrt;

    var
        Ticks : longint absolute $0040:$006c;

    procedure Demo(DV : boolean);
    var
        B : LongInt;
        M, I : integer;
        S : String;
    begin
        DirectVideo := DV;
        WriteLn('Hello, World! (Demo #4, DirectVideo:', DirectVideo, ')');
        WriteLn('Press a key to continue.');
        while not Keypressed do;
        ReadKey;
        WriteLn('Write 20,000 numbers');
        delay(1000);
        B := Ticks;
        while B = Ticks do;
        B := Ticks;
        for I := 0 to 20000 do begin
            Str(I, S);
            WriteRawPStr('Write number #' + S + ' ');
        end;
        WriteLn;
        WriteLn('Elapsed time about ', ((Ticks - B) / 18.2):1:2, ' seconds');
        Delay(2000);
        M := (Hi(WindMax) + 1) div 2;
        for I := 0 to M do begin
            TextBackground((I + 1) and $07);
            Window(1 + I, 1 + I, Lo(ScreenMax) + 1 - I, Hi(ScreenMax) + 1 - I);
            ClrScr;
            Write('Square #', I + 1);
            Sound(500 - (M - I + 1) * 32);
            Delay(500 - (M - I + 1) * 32);
        end;
        NoSound;
        Window(4, 4, Lo(ScreenMax) - 2, Hi(ScreenMax) - 2);
        TextAttr := $4F;
        for I := 1 to Hi(WindMax) - Hi(WindMin) do begin
            ScrollDown(1);
            ScrollRight(2);
            Delay(100);
        end;
        TextAttr := $07;
        Window(1, 1, Lo(ScreenMax) + 1, Hi(ScreenMax) + 1);
        ClrScr;
        Delay(500);
    end;

begin
    Demo(False);
    Demo(True);
end.