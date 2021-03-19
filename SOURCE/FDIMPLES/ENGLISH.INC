{ Embedded English language translation messages }
procedure BuiltInEnglish; assembler;
asm
  db '{',0
  db 'FDIMPLES Language Translation File',0
  db 'Note -- English translations are also built-in to the program. This file is not',0
  db 'required at runtime. However if it is present, settings in here will override',0
  db 'their built-in values.',0
  db '}',0
  db '0:EN',0
  db '1:invalid parameter',0
  db '2:Please standby...',0
  db '3:Standby',0
  db '4:Press a key...',0
  db '5:Group',0
  db '6:Package media not found!',0
  db '7:Only installed packages are shown.',0
  db '8:unable to locate package manager FDINST.',0
  db '9:TEMP environment variable is not set.',0
  db '10:unknown',0
  db '11:installed',0
  db '12:No information',0
  db '13:LOCKED',0
  db '14:Package',0
  db '15:not found under',0
  db '16:Pending package changes:',0
  db '17:remove',0
  db '18:install',0
  db '19:No Changes.',0
  db '{ Plural String Values }',0
  db '20:changes',0
  db '21:change',0
  db '22:bytes',0
  db '23:byte',0
  db '24:Kbytes',0
  db '25:Kbyte',0
  db '26:Mbytes',0
  db '27:Mbyte',0
  db '28:files',0
  db '29:file',0
  db '30:source files',0
  db '31:source file',0
  db '{ Basic Load and save stuff }',0
  db '32:Include package removals.',0
  db '33:Load package list customizations:',0
  db '34:Save package list customizations:',0
  db '{ Buttons }',0
  db '35:OK',0
  db '36:Cancel',0
  db '{ More Status Bar Text }',0
  db '39:Title',0
  db '38:version',0
  db '39:usage:',0
  db '40:[options]',0
  db '{ Help Messages and such }',0
  db '50:Released under the GNU General Public License, Version 2.0',0
  db '51:Copyright 2020 Jerome Shidel',0
  db '52:FDIMPLES provides an easy-to-use text user interface to the FDINST package manager command-line utility.',0
  db '53:Show this help screen.',0
  db '54:Show file list in package description.',0
  db '55:[DO NOT] Automatically select updatable packages.',0
  db '56:Create package list files for use with FDI build utility.',0
  db '57:Reconfigure FDI installer BASE and ALL package lists.',0
  db '58:User interface keyboard commands:',0
  db '59:Toggle selection.',0
  db '60:Change what section or button has focus.',0
  db '61:Move focus up or down an item, also Page Up/Down.',0
  db '62:Quit without making or saving changes.',0
  db '63:Display help screen.',0
  db '64:Toggle the status of all updatable packages in group.',0
  db '65:Toggle the status of all updatable packages.',0
  db '66:View pending changes.',0
  db '67:Clear all pending changes.',0
  db '68:Write a package list customization file that contains changes.',0
  db '69:Read a package list customization file and apply changes.',0
  db '{ Package ID's Are all 100 }',0
  db '100:=Installed!',0
  db '100:BASE=FreeDOS Base',0
  db '100:ARCHIVER=Archivers',0
  db '100:BOOT=Boot Tools',0
  db '100:DEVEL=Development',0
  db '100:EDIT=Editors',0
  db '100:EMULATOR=Emulators',0
  db '100:GAMES=Games',0
  db '100:GUI=Graphical Desktops',0
  db '100:NET=Networking',0
  db '100:SOUND=Sound Tools',0
  db '100:UNIXLIKE=Unix Like Tools',0
  db '100:UTIL=Utilities',0
  db '100:UNIX=Unix Like Tools',0
  db '100:OBSOLETE=Obsolete Packages',0
  db '100:APPS=Applications',0
  db '100:DRIVERS=Device Drivers',0
  db 0
end;
