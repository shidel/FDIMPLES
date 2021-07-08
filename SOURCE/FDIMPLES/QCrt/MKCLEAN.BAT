@echo off

rem Make and Clean bin directory
if exist BIN\DEMO_000.COM del BIN\*.COM
if exist BIN\DEMO_004.EXE del BIN\*.EXE
if exist BIN\DEMO_005.EXE del BIN\*.EXE
if exist BIN\QCRT.TPU del BIN\*.TPU
if exist BIN\NUL rmdir BIN

rem Clean up previous builds if needed.
if exist PASCAL\QCRT.OBJ del PASCAL\*.OBJ
if exist PASCAL\QCRT.TPU del PASCAL\*.TPU
rem if exist DEMOS\QCRT.TPU del PASCAL\*.TPU
