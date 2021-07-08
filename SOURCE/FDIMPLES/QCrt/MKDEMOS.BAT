@echo off

set OPTIONS=
set EXIT_CODE=

set TPV=TP70
set ASM=NASM
set TPC=TPC
if exist %DOSDIR%\LINKS\%ASM%.BAT set ASM=call %ASM%
if exist %DOSDIR%\LINKS\%TPC%.BAT set TPC=call %TPC%

call MKCLEAN.BAT
if not exist BIN mkdir BIN

goto MouseTests
rem Make First Dos Demo
%ASM% -IDEMOS\ DEMOS\DEMO_000.ASM -fbin -O9 -o BIN\DEMO_000.COM
%ASM% -IDEMOS\ DEMOS\DEMO_001.ASM -fbin -O9 -o BIN\DEMO_001.COM
%ASM% -IDEMOS\ DEMOS\DEMO_002.ASM -fbin -O9 -o BIN\DEMO_002.COM
%ASM% DEMOS\DEMO_003.ASM -fbin -O9 -o BIN\DEMO_003.COM
:SkipCOMs

:TPRetry
rem Make TurboPascal 7.0 Dos Demo
cd pascal
call mkunits.bat
cd ..
if not %EXIT_CODE%" == "" goto TPError
%TPC% /OPASCAL /UPASCAL /EBIN DEMOS\DEMO_004.PAS
if not exist BIN\DEMO_004.EXE goto TPFailed

rem Mouse Support
:MouseTests
SET OPTIONS=/DEnableMouse
cd pascal
call mkunits.bat
cd ..
if not "%EXIT_CODE%" == "" goto TPError
%TPC% /OPASCAL /UPASCAL /EBIN %OPTIONS% DEMOS\DEMO_005.PAS
goto DEMOS

:TPFailed
if "%TPV%" == "TP55" goto TPError
set TPV=TP55
goto TPRetry

:DEMOS
goto DONE

:TPError
echo unable to create turbo pascal libraries.
goto Done

:DONE
set ASM=
set TPC=
set TPV=
set EXIT_CODE=
set OPTIONS=