{
    Copyright 2019 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit QEMS; { QuickCrt 9.x, EMS Unit }

{$I QCRT.DEF}

interface

implementation

var
    OldExitProc : Pointer;

{$L QEMS.OBJ}

{ initialization & finalization routines }

procedure DoneQEMS; external;

procedure UnitFinal;
begin
    ExitProc := OldExitProc;
    DoneQEMS;
end;

function InitQEMS : boolean; external;

procedure UnitInit;
begin
    if not InitQEMS then Halt(10); { Internal Error }
    {$IFDEF finalialization}
        OldExitProc := ExitProc;
        ExitProc := @UnitFinal;
    {$ENDIF}
end;

begin
    UnitInit;

end.
