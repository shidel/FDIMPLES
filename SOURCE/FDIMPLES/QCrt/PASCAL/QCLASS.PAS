{
    Copyright 2019 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit QClass; { QuickCrt 9.x, Class Unit }

{$I QCRT.DEF}

interface

type
    TObjectComparison = (ocLessThan, ocEqual, ocGreaterThan, ocNull);

    PObject = ^TObject;
    TObject = object
    private
        POwner : PObject;
    public
        constructor Create(AOwner : PObject);
        destructor Destroy; virtual;
        function GetClassName : String; virtual;
        function GetOwner : PObject;
        procedure SetOwner(AOwner : PObject);
        function Compare(AObject : PObject) : TObjectComparison; virtual;
        function Size : LongInt; virtual;
        procedure Clear; virtual;
    end;

    PPersistent = ^TPersistent;
    TPersistent = object (TObject)
        function GetClassName : String; virtual;
    end;

    TCreateFunction = function (AOwner : PObject) : PObject;


procedure RegisterObject(const AClassName : String; const ACreate : TCreateFunction);

function NewObject(AOwner:PObject) : PObject;
function NewPersistent(AOwner:PObject) : PObject;

implementation

constructor TObject.Create(AOwner : PObject);
begin
    POwner := AOwner;
end;

destructor TObject.Destroy;
begin
    Clear;
    POwner := nil;
end;

function TObject.GetClassName : String;
begin
    GetClassName := 'TObject';
end;

function TObject.GetOwner : PObject;
begin
    GetOwner := POwner;
end;

procedure TObject.SetOwner(AOwner : PObject);
begin
    POwner:= AOwner;
end;

function TObject.Compare(AObject : PObject) : TObjectComparison;
begin
    if not Assigned(AObject) then
        Compare := ocNull
    else if GetClassName <> AObject^.GetClassName then
        Compare := ocNull
    else
        Compare := ocEqual;
end;

function TObject.Size : LongInt;
begin
    Size := 0;
end;

procedure TObject.Clear;
begin
end;

function TPersistent.GetClassName : String;
begin
    GetClassName := 'TPersistent';
end;

procedure RegisterObject(const AClassName : String; const ACreate : TCreateFunction);
begin
end;

function NewObject(AOwner:PObject) : PObject;
begin
    NewObject := New(PObject, Create(AOwner));
end;

function NewPersistent(AOwner:PObject) : PObject;
begin
    NewPersistent := New(PPersistent, Create(AOwner));
end;

{ initialization & finalization routines }
begin
    RegisterObject('TObject', NewObject);
    RegisterObject('TPersistent', NewPersistent);
end.
