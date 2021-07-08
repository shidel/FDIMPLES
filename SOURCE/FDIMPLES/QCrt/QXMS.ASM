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

%idefine QCrt 9.1 - QXMS

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
    jmp SkipOverQXMS
%endif

; Internal Data Segment
section Section_DATA

    XMS_Is_Avail:
        db  FALSE
    XMS_Driver:
        dw  0, 0

%ifidn __OUTPUT_FORMAT__, obj

section Section_SHARED

%else

%endif

section Section_CODE

; ------------------- Internal Functions; Don't call them directly !!!!
Set_XMS_Data:
    mov         ax, 0x4300
    int         0x2f
    mov         bl, FALSE
    cmp         al, 0x80
    jne         .NoXMS
    push        es
    mov         ax, 4310h
    int         0x2f
    mov         [XMS_Driver], bx
    mov         [XMS_Driver + 2], es
    pop         es
    mov         bl, TRUE
.NoXMS:
    mov         [XMS_Is_Avail], bl
ret

; ------------------- Exported Functions
xfunction XMS_Avail, boolean
    mov         al, [XMS_Is_Avail]
xret

xfunction InitQXMS, boolean
    call        Set_XMS_Data
    mov         al, TRUE
xret

xprocedure DoneQXMS
xret


SkipOverQXMS:
%ifidni __OUTPUT_FORMAT__, bin
	%warning Auto-initialize QuickDOS routines.
	pushcall InitQXMS
%endif