{
    Copyright 2019 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit QXMS; { QuickCrt 9.x, XMS Unit }

{$I QCRT.DEF}


interface

    function XMS_Avail : boolean;

implementation

var
    OldExitProc : Pointer;

{$L QXMS.OBJ}

function XMS_Avail : boolean; external;

{ initialization & finalization routines }

procedure DoneQXMS; external;

procedure UnitFinal;
begin
    ExitProc := OldExitProc;
    DoneQXMS;
end;

function InitQXMS : boolean; external;

procedure UnitInit;
begin
    if not InitQXMS then Halt(10); { Internal Error }
    OldExitProc := ExitProc;
    ExitProc := @UnitFinal;
end;

begin
    UnitInit;
end.
