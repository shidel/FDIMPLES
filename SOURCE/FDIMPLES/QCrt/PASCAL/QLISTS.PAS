{
    Copyright 2019 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit QLists; { QuickCrt 9.x, List Unit }

{$I QCRT.DEF}

interface

    uses QClass, QStrings;

    type
        PDataList = ^TDataList;
        PDataItem = ^TDataItem;
        TDataItem = object (TObject)
        private
            PPrevious, PNext : PDataItem;
            PPointer : Pointer;
        public
            constructor Create(AOwner : PObject; APointer :  Pointer);
            destructor Destroy; virtual;
            function  GetClassName : String; virtual;

            procedure Clear; virtual;

            function  GetPrevious : PDataItem;
            procedure SetPrevious (APrevious : PDataItem);
            function  GetNext : PDataItem;
            procedure SetNext (ANext : PDataItem);

            function GetPointer : Pointer;
            procedure SetPointer(APointer : Pointer);

        end;

        TDataList = object(TObject)
            private
                PFirst, PLast, PRecent : PDataItem;
                PSorted : boolean;
                PCount : longint;
            public
            constructor Create(AOwner : PObject);
            function GetClassName : String; virtual;

            procedure Clear; virtual;
            function Count : longInt;

            function  GetFirst : PDataItem;
            procedure SetFirst (AFirst : PDataItem);
            function  GetLast : PDataItem;
            procedure SetLast (ALast : PDataItem);

            function GetSorted : boolean;
            procedure SetSorted(ASorted : boolean); virtual;

            function Add(ADataItem : PDataItem) : PDataItem; virtual;
            function Append(ADataItem : PDataItem) : PDataItem; virtual;
            function Insert(ADataItem, ABeforeItem : PDataItem) : PDataItem; virtual;
            function Remove(ADataItem : PDataItem) : PDataItem; virtual;

        end;

        PStringItem = ^TStringItem;
        PStringList = ^TStringList;
        TStringItem = object(TDataItem)
            constructor Create(AOwner : PObject; AString : String);
            function GetClassName : String; virtual;
            function GetString : String;
            procedure SetString(AString : String);
            procedure Clear; virtual;
            function Compare(AObject : PObject) : TObjectComparison; virtual;
        end;

        TStringList = object(TDataList)
        end;

function NewDataItem(AOwner:PObject) : PObject;
function NewDataList(AOwner:PObject) : PObject;
function NewStringItem(AOwner:PObject) : PObject;
function NewStringList(AOwner:PObject) : PObject;

implementation

constructor TDataItem.Create(AOwner :PObject; APointer :  Pointer);
begin
    inherited Create(AOwner);
    PPrevious := nil;
    PNext := nil;
    PPointer := APointer;
end;

destructor TDataItem.Destroy;
begin
    if GetOwner <> nil then
        PDataList(GetOwner)^.Remove(@Self);
    inherited Destroy;
end;

function TDataItem.GetClassName : String;
begin
    GetClassName := 'TDataItem';
end;

procedure TDataItem.Clear;
begin
    PPointer := nil;
    inherited Clear;
end;

function TDataItem.GetPrevious : PDataItem;
begin
    GetPrevious := PPrevious;
end;

procedure TDataItem.SetPrevious (APrevious : PDataItem);
begin
    PPrevious := APrevious;
end;

function TDataItem.GetNext : PDataItem;
begin
    GetNext := PNext;
end;

procedure TDataItem.SetNext (ANext : PDataItem);
begin
    PNext := ANext;
end;

function TDataItem.GetPointer : Pointer;
begin
    GetPointer := PPointer;
end;

procedure TDataItem.SetPointer(APointer : Pointer);
begin
    PPointer := APointer;
end;

constructor TDataList.Create(AOwner :PObject);
begin
    inherited Create(AOwner);
    PFirst := nil;
    PLast := nil;
    PRecent := nil;
    PSorted := True;
    PCount := 0;
end;

function TDataList.GetClassName : String;
begin
    GetClassName := 'TDataList';
end;

procedure TDataList.Clear;
var
    P : PDataItem;
begin
    while Assigned(PFirst) do begin
        P := PFirst^.GetNext;
        P^.SetOwner(nil);
        Dispose(P, Destroy);
        PFirst := P;
    end;
    PLast := nil;
    PRecent := nil;
    PSorted := True;
    PCount := 0;
    inherited Clear;
end;

function TDataList.Count : longInt;
begin
    Count := PCount;
end;

function  TDataList.GetFirst : PDataItem;
begin
    GetFirst := PFirst;
end;

procedure TDataList.SetFirst (AFirst : PDataItem);
begin
    PFirst := AFirst;
end;

function  TDataList.GetLast : PDataItem;
begin
    GetLast := PLast;
end;

procedure TDataList.SetLast (ALast : PDataItem);
begin
    PLast := ALast;
end;

function TDataList.GetSorted : boolean;
begin
    GetSorted := PSorted;
end;

procedure TDataList.SetSorted(ASorted : boolean);
begin
    if (not Assigned(PFirst)) or (not ASorted) then
        PSorted := ASorted;
end;

function TDataList.Add(ADataItem : PDataItem) : PDataItem;
begin
    if (not PSorted) or (PFirst = nil) then
        ADataItem := Append(ADataItem)
    else begin
        while Assigned(PRecent) and (ADataItem^.Compare(PRecent) = ocLessThan) do
            PRecent := PRecent^.GetPrevious;
        if Assigned(PRecent) then begin
            while Assigned(PRecent) and (ADataItem^.Compare(PRecent) = ocGreaterThan) do
                PRecent := PRecent^.GetNext;
            if not Assigned(PRecent) then
                ADataItem := Append(ADataItem)
            else
                ADataItem := Insert(ADataItem, PRecent);
        end else
            ADataItem := Insert(ADataItem, PFirst)
    end;
    Add := ADataItem;
end;

function TDataList.Append(ADataItem : PDataItem) : PDataItem;
begin
    if Assigned(ADataItem) then begin
        if ADataItem^.Compare(PLast) = ocLessThan then PSorted := False;
        ADataItem^.SetOwner(PObject(@Self));
        ADataItem^.SetPrevious(PLast);
        if Assigned(PLast) then PLast^.SetNext(ADataItem);
        if not Assigned(PFirst) then PFirst := ADataItem;
        PLast := ADataItem;
        PRecent := ADataItem;
        Inc(PCount);
    end;
    Append := ADataItem;
end;

function TDataList.Insert(ADataItem, ABeforeItem : PDataItem) : PDataItem;
begin
    if Assigned(ADataItem) then begin
        if not Assigned(ABeforeItem) then
            ABeforeItem := PFirst;
        if not Assigned(PFirst) then
            ADataItem := Append(ADataItem)
        else begin
            if ADataItem^.Compare(ABeforeItem) = ocGreaterThan then
                PSorted := False;
            ADataItem^.SetOwner(PObject(@Self));
            ADataItem^.SetNext(ABeforeItem);
            ADataItem^.SetPrevious(ABeforeItem^.GetPrevious);
            ABeforeItem^.SetPrevious(ADataItem);
            if ADataItem^.GetPrevious = nil then
                PFirst := ADataItem
            else
                ADataItem^.GetPrevious^.SetNext(ADataItem);
            PRecent := ADataItem;
            Inc(PCount);
        end;
    end;
    Insert := ADataItem;
end;

function TDataList.Remove(ADataItem : PDataItem) : PDataItem;
begin
    if Assigned(ADataItem) then begin
        if PFirst = ADataItem then PFirst := ADataItem^.GetNext;
        if PLast = ADataItem then PLast := ADataItem^.GetPrevious;

        if ADataItem^.GetNext <> nil then
            ADataItem^.GetNext^.SetPrevious(ADataItem^.GetPrevious);
        if ADataItem^.GetPrevious <> nil then
            ADataItem^.GetPrevious^.SetNext(ADataItem^.GetNext);

        if PRecent = ADataItem then PRecent := PFirst;

        ADataItem^.SetPrevious(nil);
        ADataItem^.SetNext(nil);
        ADataItem^.SetOwner(nil);

        if (PFirst = nil) and (PLast = Nil) then PSorted := True;
        Dec(PCount);
    end;
    Remove:= ADataItem;
end;

constructor TStringItem.Create(AOwner : PObject; AString : String);
begin
    if AString = '' then
        inherited Create(AOwner, nil)
    else
        inherited Create(AOwner, StrPtr(AString));
end;

function TStringItem.GetClassName : String;
begin
    GetClassName := 'TStringItem';
end;

function TStringItem.GetString : String;
begin
    GetString := PtrStr(GetPointer);
end;

procedure TStringItem.SetString(AString : String);
var
    P : PString;
begin
    P := GetPointer;
    if Assigned(P) then FreeStr(P);
    SetPointer(StrPtr(AString));
end;

procedure TStringItem.Clear;
var
    P : PString;
begin
    P := GetPointer;
    if Assigned(P) then FreeStr(P);
    { SetPointer(nil); inherited Clears }
    inherited Clear;
end;

function TStringItem.Compare(AObject : PObject) : TObjectComparison;
var
    Result : TObjectComparison;
    P1, P2 : PString;
begin
    Result := inherited Compare(AObject);
    if Result = ocEqual then begin
        P1 := PString(GetPointer);
        P2 := PString(PDataItem(AObject)^.GetPointer);
        if P1^ < P2^ then
            Result := ocLessThan
        else
        if P1^ > P2^ then
            Result := ocGreaterThan;
    end;
    Compare := Result;
end;

function NewDataItem(AOwner:PObject) : PObject;
begin
    NewDataItem := New(PDataItem, Create(AOwner, nil));
end;

function NewDataList(AOwner:PObject) : PObject;
begin
    NewDataList := New(PDataList, Create(AOwner));
end;

function NewStringItem(AOwner:PObject) : PObject;
begin
    NewStringItem := New(PStringItem, Create(AOwner, ''));
end;

function NewStringList(AOwner:PObject) : PObject;
begin
    NewStringList := New(PStringList, Create(AOwner));
end;

{ initialization & finalization routines }

begin
    RegisterObject('TDataItem', NewDataItem);
    RegisterObject('TDataList', NewDataList);
    RegisterObject('TStringItem', NewStringItem);
    RegisterObject('TStringList', NewStringList);
end.
