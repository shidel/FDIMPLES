@echo off

SET APP=FDIMPLES

deltree /Y bin nls doc %APP%.ZIP >NUL

cd SOURCE\%APP%
call build.bat
cd ..\..

mkdir bin >NUL
move SOURCE\%APP%\%APP%.EXE BIN\ >NUL
upx -9 BIN\%APP%.EXE
rem del SOURCE\%APP%\*.TPU
rem del SOURCE\%APP%\*.OBJ

mkdir nls
xcopy /y SOURCE\%APP%\NLS\*.* NLS
xcopy /y SOURCE\%APP%\CONTRIB\NLS\*.* NLS

mkdir doc
xcopy /y LICENSE doc
xcopy /y README.MD doc

zip -9 -k -r %APP%.ZIP BIN DOC NLS
cd SOURCE\%APP%
zip -u -9 -k -r ..\..\%APP%.ZIP APPINFO
cd ..\..

zip -u -9 -k -r %APP%.ZIP SOURCE\%APP%\CONTRIB
zip -u -9 -k -r %APP%.ZIP SOURCE\%APP%\NLS

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
