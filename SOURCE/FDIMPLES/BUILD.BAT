@echo off

if "%1" == "" goto buildlist

if exist %1.COM del %1.COM >nul
nasm %1.ASM -ILIBS/ -fbin -O9 -o %1.COM
if not exist %1.COM goto end

if not exist ..\..\BIN\NUL mkdir ..\..\BIN

if not exist ..\..\BIN\%1.COM goto NoOld

dir ..\..\BIN\%1.COM

:NoOld
copy /y %1.COM ..\..\BIN\ >NUL
dir ..\..\BIN\%1.COM
goto end

:buildlist

CALL %0 FDIMPLES

:end