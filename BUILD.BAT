@echo off

if not "%1" == "" goto %1

SET APP=FDIMPLES
set FDNLS=..\FD-NLS

if exist %FDNLS%\%APP%\NLS\%APP%.EN goto Build

echo Unable to locate translations. Please checkout the latest FD-NLS and update
echo the FDNLS=%FDNLS% setting to point to the FD-NLS project files.
goto End

:CopyNLS
if not exist %FDNLS%\%APP%\%2\%APP%.%2 goto End
xcopy /y %FDNLS%\%APP%\%2\%APP%.%2 NLS
goto End

:Build
deltree /Y bin nls doc %APP%.ZIP >NUL

cd SOURCE\%APP%
call build.bat
if errorlevel 1 goto BuildError
cd ..\..
goto MakeArchive

:BuildError
cd ..\..
goto Die

:MakeArchive
mkdir bin >NUL
mkdir nls >NUL
mkdir doc
mkdir doc\%APP%

move SOURCE\%APP%\%APP%.EXE BIN\ >NUL
upx --8086 BIN\%APP%.EXE
rem del SOURCE\%APP%\*.TPU
rem del SOURCE\%APP%\*.OBJ


xcopy /y %FDNLS%\%APP%\NLS\%APP%.* NLS
veach /a+ /d %FDNLS%\%APP%\*.* /x %0 CopyNLS *

xcopy /y LICENSE doc\%APP%
xcopy /y README.MD doc\%APP%

cd SOURCE\%APP%
call clean.bat
cd ..\..

zip -9 -k -r %APP%.ZIP BIN DOC NLS
cd SOURCE\%APP%
zip -u -9 -k -r ..\..\%APP%.ZIP APPINFO
cd ..\..

rem zip -u -9 -k -r %APP%.ZIP SOURCE\%APP%\CONTRIB
rem zip -u -9 -k -r %APP%.ZIP %FDNLS%\%APP%

zip -u -9 -k %APP%.ZIP SOURCE\%APP%\*.*
zip -u -9 -k %APP%.ZIP SOURCE\%APP%\QCRT\*.BAT
zip -u -9 -k %APP%.ZIP SOURCE\%APP%\QCRT\*.ASM
zip -u -9 -k %APP%.ZIP SOURCE\%APP%\QCRT\*.INC
zip -u -9 -k %APP%.ZIP SOURCE\%APP%\QCRT\*.MD
zip -u -9 -k %APP%.ZIP SOURCE\%APP%\QCRT\*.
zip -u -9 -k %APP%.ZIP SOURCE\%APP%\QCRT\DEMOS\*.*
zip -u -9 -k %APP%.ZIP SOURCE\%APP%\QCRT\PASCAL\*.BAT
zip -u -9 -k %APP%.ZIP SOURCE\%APP%\QCRT\PASCAL\*.PAS
zip -u -9 -k %APP%.ZIP SOURCE\%APP%\QCRT\PASCAL\*.DEF

dir bin %APP%.zip | grep -i %APP% | grep -iv Directory
goto end
:Die
verrlvl 1

:End