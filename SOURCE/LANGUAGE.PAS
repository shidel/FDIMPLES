{
    Copyright 2018 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit Language;

interface

    type
        BooleanStrings = record
            TrueStr : String;
            FalseStr : String;
        end;

        NLSType = record
            Code                    : String[12];
            InvalidParam            : String[20];
            PleaseStandby           : String[40];
            Standby                 : String[20];
            PressAKey               : String[40];
            InstalledOnly           : String[12];
            PackageMediaNotFound    : String[40];
            OnlyInstalledShown      : String[40];
            NoFDINST                : String[80];
            NoTemp                  : String[80];
            InfoUnknown             : String[20];
            InfoInstalled           : String[20];
            InfoByte                : BooleanStrings;
            InfoKByte               : BooleanStrings;
            InfoMByte               : BooleanStrings;
            InfoFile                : BooleanStrings;
            InfoSourceFile          : BooleanStrings;
            InfoNoInfo              : String[40];
            InfoLocked              : String[20];
            BarPackage              : String[20];
            BarNotFound             : String[40];
            PendingChanges          : String[40];
            RemoveChange            : String[20];
            InstallChange           : String[20];
            NoChanges               : String[40];
            TotalChanges            : BooleanStrings;
            IncludeRemovals         : String[40];
            LoadCustom              : String[60];
            SaveCustom              : String[60];
            ButtonOK                : String[20];
            ButtonCancel            : String[20];
        end;

    var
        NLS : NLSType;

    function PluralNLS (I : LongInt; Strs : BooleanStrings) : String;

implementation

uses QDos, QStrings;

const
    English : NLSType = (
        Code                    : 'EN';
        InvalidParam            : 'invalid parameter';
        PleaseStandby           : 'Please standby...';
        Standby                 : 'Standby';
        PressAKey               : 'Press a key...';
        InstalledOnly           : 'Installed!';
        PackageMediaNotFound    : 'Package media not found!';
        OnlyInstalledShown      : 'Only installed packages are shown.';
        NoFDINST                : 'unable to locate package manager FDINST.';
        NoTemp                  : 'TEMP environment variable is not set.';
        InfoUnknown             : 'unknown';
        InfoInstalled           : 'installed';
        InfoByte                : (TrueStr:'bytes'; FalseStr:'byte');
        InfoKByte               : (TrueStr:'Kbytes'; FalseStr:'Kbyte');
        InfoMByte               : (TrueStr:'Mbytes'; FalseStr:'Mbyte');
        InfoFile                : (TrueStr:'files'; FalseStr:'file');
        InfoSourceFile          : (TrueStr:'source files'; FalseStr:'source file');
        InfoNoInfo              : 'No information';
        InfoLocked              : 'LOCKED';
        BarPackage              : 'Package';
        BarNotFound             : 'not found under';
        PendingChanges          : 'Pending package changes:';
        RemoveChange            : 'remove';
        InstallChange           : 'install';
        NoChanges               : 'No Changes.';
        TotalChanges            : (TrueStr:'changes'; FalseStr:'change');
        IncludeRemovals         : 'Include package removals.';
        LoadCustom              : 'Load package list customizations:';
        SaveCustom              : 'Save package list customizations:';
        ButtonOK                : 'OK';
        ButtonCancel            : 'Cancel'
    );

    German : NLSType = (
        { Google Translate }
        Code                    : 'DE';
        InvalidParam            : 'ungÅltiger parameter';
        PleaseStandby           : 'Bitte stehen Sie bereit...';
        Standby                 : 'Bereithalten';
        PressAKey               : 'drÅcke eine taste...';
        InstalledOnly           : 'Eingerichtet!';
        PackageMediaNotFound    : 'Paketmedium wurde nicht gefunden!';
        OnlyInstalledShown      : 'Es werden nur installierte Pakete angezeigt.';
        NoFDINST                : 'Paket-Manager FDINST kann nicht gefunden werden.';
        NoTemp                  : 'TEMP-Umgebungsvariable ist nicht festgelegt.';
        InfoUnknown             : 'unbekannte';
        InfoInstalled           : 'eingerichtet';
        InfoByte                : (TrueStr:'bDatenbytes'; FalseStr:'Datenbyte');
        InfoKByte               : (TrueStr:'Kbytes Daten'; FalseStr:'Kbyte Daten');
        InfoMByte               : (TrueStr:'Mbytes Daten'; FalseStr:'Mbyte Daten');
        InfoFile                : (TrueStr:'Programmdateien'; FalseStr:'Programmdatei');
        InfoSourceFile          : (TrueStr:'Quelldaten'; FalseStr:'Quelldatei');
        InfoNoInfo              : 'Keine Information';
        InfoLocked              : 'gesperrt';
        BarPackage              : 'Paket';
        BarNotFound             : 'wurde nicht unter';
        PendingChanges          : 'Ausstehende PaketÑnderungen:';
        RemoveChange            : 'lîschen';
        InstallChange           : 'Installieren';
        NoChanges               : 'Keine énderungen.';
        TotalChanges            : (TrueStr:'énderungen'; FalseStr:'Ñndern');
        IncludeRemovals         : 'Paketentnahmen einschlie·en.';
        LoadCustom              : 'Paketlisten-Anpassungen laden:';
        SaveCustom              : 'Speichern von Paketlistenanpassungen:';
        ButtonOK                : 'ausfÅhren';
        ButtonCancel            : 'stornieren'
    );


function PluralNLS (I : LongInt; Strs : BooleanStrings) : String;
begin
    PluralNLS := WhichStr(I = 1, Strs.TrueStr, Strs.FalseStr);
end;

procedure Init;
begin
    FillChar(NLS, Sizeof(NLS), #0);
    NLS.Code := GetLanguage;
    if NLS.Code = 'DE' then
        NLS := German
    else
        NLS := English;
end;

begin
    Init;

end.