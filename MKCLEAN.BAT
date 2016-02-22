@echo off

rem Make and Clean bin directory
if exist BIN\NUL del BIN\*.*
if exist BIN\NUL rmdir BIN

rem Clean up previous builds if needed.
if exist SOURCE\QCRT.OBJ del SOURCE\*.OBJ
if exist SOURCE\QCRT.TPU del SOURCE\*.TPU
