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

%idefine QCrt 9.1 - QDOS

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
    jmp SkipOverQDOS
%endif

; Internal Data Segment
section Section_DATA

%ifidn __OUTPUT_FORMAT__, obj

    ProgramPrefixSeg:
        dw  0           ; Program prefix segment
    UnitDataSeg:
        dw  0           ; Data Segment

    %imacro PrefixSeg 1
        %ifidni %1, ax
            mov     ax, [ProgramPrefixSeg]
        %else
            push    ax
            mov     ax, [ProgramPrefixSeg]
            pop     ax
        %endif
    %endmacro

    %imacro DataSeg 1
        %ifidni %1, ax
            mov     ax, [UnitDataSeg]
        %else
            push    ax
            mov     ax, [UnitDataSeg]
            pop     ax
        %endif
    %endmacro

section Section_SHARED

%else

%endif

section Section_CODE

; ------------------- Internal Functions; Don't call them directly !!!!
%ifidni __OUTPUT_FORMAT__, bin
SearchEnvTable:
    pushy       ax, bx, di
    cld
    PrefixSeg   es
    mov         es, [es:0x2c]
    mov         si, 0x0000
    mov         bx, di
.Compare:
    mov         di, bx
.CompareLoop:
    mov         ah, [di]
    inc         di
    cmp         ah, 0x00
    je          .Maybe
    es          lodsb
    cmp         al, 0x00
    je          .NotFound
    cmp         al, ah
    je          .CompareLoop
.Mismatch:
    cmp         al, 0x00
    je          .Compare
    es          lodsb
    jmp         .Mismatch
.Maybe:
    es          lodsb
    cmp         al, 0x00
    je          .NotFound
    cmp         al, '='
    jne         .Mismatch
.Found:
    clc
    jmp         .Done
.NotFound:
    stc
.Done:
    poppy       di, bx, ax
    ret
%endif

; ------------------- Exported Functions


; function InitQDOS(PSP : word) : boolean; external;
xfunction InitQDOS, boolean, 2
	mov		    ax, [STACKBP + 0]
    mov         [ProgramPrefixSeg], ax
    mov         [UnitDataSeg], ds
    PrefixSeg     ax
    cmp         ax, 0x0000
    je          .Error

.AOkay:
    mov         al, TRUE
    jmp         .Done
.Error:
    mov         al, FALSE
.Done:
xret

xprocedure DoneQDOS
xret

SkipOverQDOS:
%ifidni __OUTPUT_FORMAT__, bin
	%warning Auto-initialize QuickDOS routines.
	pushcall InitQDOS
%endif

