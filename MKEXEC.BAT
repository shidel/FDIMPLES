@echo off

set TPV=TP70
set TPC=TPC
set ASM=NASM

if exist %DOSDIR%\LINKS\%TPC%.BAT set TPC=call %TPC%
if exist %DOSDIR%\LINKS\%ASM%.BAT set ASM=call %ASM%

call MKCLEAN.BAT

cd SOURCE
copy /Y ..\qcrt\pascal\*.PAS .
copy /Y ..\qcrt\*.ASM .
copy /Y ..\qcrt\*.INC .

:TPRetry
%ASM% QCRT.ASM -fobj -D%TPV% -O9 -o QCRT.OBJ
%TPC% /B FDIMPLES.PAS
if exist FDIMPLES.EXE goto Success
if "%TPV%" == "TP55" goto TPError
set TPV=TP55
goto TPRetry

:Success
if not exist ..\BIN\NUL mkdir ..\BIN>NUL
copy FDIMPLES.* ..\BIN\ >NUL
copy ..\CONTRIB\LANGUAGE\FDIMPLES.* ..\BIN\ >NUL
del ..\BIN\*.INC
del ..\BIN\*.PAS

dir ..\BIN\*.*

goto DONE


:TPError
echo unable to create turbo pascal libraries.
goto Done

:DONE
set TPC=
set TPV=
cd ..