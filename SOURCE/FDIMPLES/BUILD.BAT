@echo off

del FDIMPLES.COM >nul
nasm "FDIMPLES.ASM" -Ilibs/ -fbin -O9 -o "FDIMPLES.COM"
if not exist FDIMPLES.COM goto end

if not exist ..\..\BIN\NUL mkdir ..\..\BIN

if not exist ..\..\BIN\FDIMPLES.COM goto NoOld

dir ..\..\BIN\FDIMPLES.COM

:NoOld
copy /y FDIMPLES.COM ..\..\BIN\ >NUL
dir ..\..\BIN\FDIMPLES.COM

:end