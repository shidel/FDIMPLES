@echo off

SET APP=FDIMPLES
cd SOURCE\%APP%
call build.bat
cd ..\..

deltree /Y bin %APP%.ZIP >NUL
mkdir bin >NUL
move SOURCE\%APP%\%APP%.EXE BIN\ >NUL
upx -9 BIN\%APP%.EXE
rem del SOURCE\%APP%\*.TPU
rem del SOURCE\%APP%\*.OBJ

zip -9 -k -r %APP%.ZIP BIN DOC
cd SOURCE\%APP%
zip -u -9 -k -r ..\..\%APP%.ZIP NLS APPINFO
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
