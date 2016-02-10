@echo off

rem Make and Clean bin directory
if exist FDIMPLES.EXE del FDIMPLES.EXE
if exist BIN\NUL del BIN\*.*
if exist BIN\NUL rmdir BIN

rem Clean up previous builds if needed.
if exist QCRT.OBJ del *.OBJ
if exist QCRT.TPU del *.TPU
