; Copyright 2019 Jerome Shidel
; Released Under GPL v2.0 License.

; QCrt 9.1

; For DOS, Nasm and Pascal 16-bit edition.

; This assembly language library uses the pascal calling convention. All calls
; are far calls. Data parameters passed to procedure and functions are pushed
; onto the stack in reverse order and are popped automatically by the function
; or procedure on their return. Simple function return values are usually set
; in AL, AX or in the DX:AX pair. DS, SS, SP, BP are preserved. However, the
; state of all other registers are not guaranteed. So, if calling this library
; from a language other than Pascal, such as from more assembly code, you must
; take care of preserving any registers and values you wish to retain yourself!

%idefine QCrt 9.1 - QStrings

%ifndef TargetOS
    %idefine TargetOS DOS
%endif

%ifndef TargetCPU
    %idefine TargetCPU 8086
%endif

%ifndef QDefines
	%include "QDEFINES.INC"
%endif

%ifidni __OUTPUT_FORMAT__, bin
    jmp SkipOverQStrings
%endif

; Internal Data Segment
section Section_DATA

%ifidn __OUTPUT_FORMAT__, obj

section Section_SHARED

%else

%endif

section Section_CODE

; ------------------- Internal Functions; Don't call them directly !!!!

; ------------------- Exported Functions
xfunction InitQStrings, boolean
    mov         al, TRUE
xret

xprocedure DoneQStrings
xret

SkipOverQStrings:
%ifidni __OUTPUT_FORMAT__, bin
	%warning Auto-initialize QuickDOS routines.
	pushcall InitQStrings
%endif