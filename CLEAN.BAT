@echo off

SET APP=FDIMPLES

deltree /y bin nls doc *.zip >nul

cd SOURCE\%APP%
call clean.bat
cd ..\..
