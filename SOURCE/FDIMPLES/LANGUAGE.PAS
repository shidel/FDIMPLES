{
    Copyright 2018 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit Language;

interface

    uses QDos, QStrings, FileIO;

    var
        Lang : String;

    type
        PGroupID = ^TGroupID;
        TGroupID = record
            ID : Str12;
            Title : PString;
            Next : PGroupID;
        end;

    const
        nlsCode                    = 0;
        nlsInvalidParam            = 1;
        nlsPleaseStandby           = 2;
        nlsStandby                 = 3;
        nlsPressAKey               = 4;
        nlsGroup                   = 5;
        nlsPackageMediaNotFound    = 6;
        nlsOnlyInstalledShown      = 7;
        nlsNoFDINST                = 8;
        nlsNoTemp                  = 9;
        nlsInfoUnknown             = 10;
        nlsInfoInstalled           = 11;
        nlsInfoNoInfo              = 12;
        nlsInfoLocked              = 13;
        nlsPackage                 = 14;
        nlsBarPackage              = nlsPackage;
        nlsBarNotFound             = 15;
        nlsPendingChanges          = 16;
        nlsRemoveChange            = 17;
        nlsInstallChange           = 18;
        nlsNoChanges               = 19;
        nlsTotalChanges            = 20;
        nlsInfoByte                = 22;
        nlsInfoKByte               = 24;
        nlsInfoMByte               = 26;
        nlsInfoFile                = 28;
        nlsInfoSourceFile          = 30;
        nlsIncludeRemovals         = 32;
        nlsLoadCustom              = 33;
        nlsSaveCustom              = 34;
        nlsButtonOK                = 35;
        nlsButtonCancel            = 36;
        nlsTitle                   = 37;
        nlsVersion                 = 38;
        nlsUsage                   = 39;
        nlsOptions                 = 40;

        nlsHelp                    = 50;

        nlsEnd                     = 90;

        nlsPackageGroup            = 100;

    function PluralNLS (I : LongInt; Index : Integer) : String;
    function NLS(Index:integer): String;

    function GetGroup(ID : String) : String;

implementation

var
    OldExitProc : pointer;
    NLSData : array[nlsCode..nlsEnd] of PString;
    Groups : PGroupID;

{$I FDIMPLES.INC}

function NLS(Index:integer): String;
begin
    NLS := PtrStr(NLSData[Index]);
end;

function PluralNLS (I : LongInt; Index : Integer) : String;
begin
    PluralNLS := WhichStr(I = 1, NLS(Index), NLS(Index+1));
end;

procedure SetGroup(ID, Title : String);
var
    P : PGroupID;
begin
    P := Groups;
    while Assigned(P) do begin
        if P^.ID = ID then begin
            FreeStr(P^.Title);
            P^.Title := StrPtr(Title);
            Exit;
        end;
        P := P^.Next;
    end;
    P := New(PGroupID);
    P^.ID := ID;
    P^.Title := StrPtr(Title);
    P^.Next := Groups;
    Groups := P;
end;

function GetGroup(ID : String) : String;
var
    P : PGroupID;
begin
    P := Groups;
    while Assigned(P) do begin
        if P^.ID = ID then begin
            GetGroup := PtrStr(P^.Title);
            Exit;
        end;
        P := P^.Next;
    end;
    GetGroup := '';
end;


procedure ProcessNLS(S : String);
var
    I : integer;
    V : String;
begin
    if (S = '') or (Pos(S[1], '0123456789') < 1) then exit;
    I := StrInt(Copy(S, 1, Pos(':', S)- 1));
    V := Copy(S, Pos(':', S) + 1, Length(S));
    if I = nlsPackageGroup then
        SetGroup(UCase(Copy(V, 1, Pos('=', V) - 1)), Copy(V, Pos('=', V) + 1, Length(V)))
    else
    if (I < nlsCode) or (I > nlsEnd) then Exit; {Probably should die with error}
    FreeStr(NLSData[I]);
    NLSData[I] := StrPtr(V);
end;

procedure ReadNLS(AFileName : String);
var
    F : File;
    S : String;
    C : integer;
    X : ^Char;
begin
    {WriteLn('Source: ' + AFileName);}
    if AFileName <> '' then begin
        FileMode := 0;
        Assign(F, AFileName);
        Reset(F, 1);
        repeat
            C := UnixRead(F, S);
            if (C <> -1) then begin
                if (Pos('db ' + #$27, S) = 1) then
                    ProcessNLS(Copy(S, 5, LastPos(#$27, S ) - 5))
                else
                    ProcessNLS(S);
            end;
        until C = -1;
        Close(F);
    end else begin
        X := @NLSInternal;
        while X^ <> #0 do begin
            S := '';
            while X^ <> #0 do begin
                S := S + X^;
                X := Ptr(Seg(X^), Ofs(X^)+1);
            end;
            ProcessNLS(S);
            X := Ptr(Seg(X^), Ofs(X^)+1);
        end;
    end
end;

procedure Final; far;
var
    P : PGroupID;
begin
    ExitProc := OldExitProc;
    while Assigned(Groups) do begin
        P := Groups^.Next;
        FreeStr(Groups^.Title);
        Dispose(Groups);
        Groups := P;
    end;
end;

procedure Init;
var
    I : integer;
    S : String;
begin
    Lang := UCase(GetEnv('LANG'));
    if Lang = '' then Lang := 'EN';
    Groups := nil;
    OldExitProc := ExitProc;
    ExitProc := @Final;
    for I := nlsCode to nlsEnd do
        NLSData[I] := nil;
    ReadNLS('');
    S := Copy(GetExeName, 1, LastPos('.', GetExeName));
    if FileExists(GetExePath + S + Lang) then
        ReadNLS(GetExePath + S + Lang)
    else
    if FileExists(TailDelim(GetEnv('NLSPATH')) + S + Lang) then
        ReadNLS(TailDelim(GetEnv('NLSPATH')) + S + Lang)
    else
    if FileExists(GetExePath + S + 'EN') then
        ReadNLS(GetExePath + S + 'EN')
    else
    if FileExists(TailDelim(GetEnv('NLSPATH')) + S + 'EN') then
        ReadNLS(TailDelim(GetEnv('NLSPATH')) + S + 'EN');
end;

begin
    Init;
end.