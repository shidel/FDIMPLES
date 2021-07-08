; Copyright 2019 Jerome Shidel
; Released Under GPL v2.0 License.

org 100h

%define TargetCPU 8086      ; default is 286+
%define BiosVideoOnly       ; default is Direct and Bios modes

%include "QCRT.ASM"

mov			bx, HelloWorld
pushcall 	WriteStr, ds, bx
terminate   0

HelloWorld:     DB "Hello,",9,"World! (Demo #0)",CRLF,0
