{
    Copyright 2018 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit Language;

interface

    uses QDos, QStrings, FileIO;

    type
        BooleanStrings = record
            TrueStr : PString;
            FalseStr : PString;
        end;

    const
        nlsCode                    = 0;
        nlsInvalidParam            = 1;
        nlsPleaseStandby           = 2;
        nlsStandby                 = 3;
        nlsPressAKey               = 4;
        nlsInstalledOnly           = 5;
        nlsPackageMediaNotFound    = 6;
        nlsOnlyInstalledShown      = 7;
        nlsNoFDINST                = 8;
        nlsNoTemp                  = 9;
        nlsInfoUnknown             = 10;
        nlsInfoInstalled           = 11;
        nlsInfoNoInfo              = 12;
        nlsInfoLocked              = 13;
        nlsBarPackage              = 14;
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
        nlsEnd                     = nlsButtonCancel;

    function PluralNLS (I : LongInt; Index : Integer) : String;
    function NLS(Index:integer): String;

implementation

var
    NLSData : array[nlsCode..nlsEnd] of PString;

function NLS(Index:integer): String;
begin
    NLS := PtrStr(NLSData[Index]);
end;

function PluralNLS (I : LongInt; Index : Integer) : String;
begin
    PluralNLS := WhichStr(I = 1, NLS(Index), NLS(Index+1));
end;

procedure ProcessNLS(S : String);
var
    I : integer;
    V : String;
begin
    if (S = '') or (Pos(S[1], '0123456789') < 1) then exit;
    I := StrInt(Copy(S, 1, Pos(':', S)- 1));
    V := Copy(S, Pos(':', S) + 1, Length(S));
    if (I < nlsCode) or (I > nlsEnd) then Exit; {Probably should die with error}
    FreeStr(NLSData[I]);
    NLSData[I] := StrPtr(V);
end;

procedure ReadNLS(AFileName : String);
var
    F : File;
    S : String;
    C : integer;
begin
    {WriteLn('Source: ' + AFileName);}
    if AFileName <> '' then begin
        FileMode := 0;
        Assign(F, AFileName);
        Reset(F, 1);
        repeat
            C := UnixRead(F, S);
            if (C <> -1) then
                ProcessNLS(S);
        until C = -1;
        Close(F);
    end
end;

procedure Init;
var
    I : integer;
    S : String;
begin
    for I := nlsCode to nlsEnd do
        NLSData[I] := nil;
    ReadNLS('');
    S := Copy(GetExeName, 1, LastPos('.', GetExeName));
    if FileExists(GetExePath + S + GetLanguage) then
        ReadNLS(GetExePath + S + GetLanguage)
    else
    if FileExists(TailDelim(GetEnv('NLSPATH')) + S + GetLanguage) then
        ReadNLS(TailDelim(GetEnv('NLSPATH')) + S + GetLanguage)
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