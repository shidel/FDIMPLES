@echo off

set TPV=TP70
set TPC=TPC
if exist %DOSDIR%\LINKS\%TPC%.BAT set TPC=call %TPC%

call MKCLEAN.BAT

cd SOURCE

:TPRetry
%TPC% /b FDIMPLES.PAS
if not exist FDIMPLES.EXE goto TPFailed

if not exist ..\BIN\NUL mkdir ..\BIN>NUL
copy FDIMPLES.EXE ..\BIN\ >NUL

dir ..\BIN\*.exe

goto DONE

:TPFailed
if "%TPV%" == "TP55" goto TPError
set TPV=TP55
goto TPRetry


:TPError
echo unable to create turbo pascal libraries.
goto Done

:DONE
set TPC=
set TPV=
cd ..