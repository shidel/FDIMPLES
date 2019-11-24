; Copyright 2016 Jerome Shidel
; Released Under GPL v2.0 License.

; QCrt 9.0 Nasm Defines, Constants and Macros File

; User Configuration Defines

; %idefine Target8086           ; Uncomment to target original PC XT.
; %idefine BiosVideoOnly        ; Uncomment to remove Direct Video Support
; %idefine DirectVideoOnly      ; Uncomment to remove BIOS Video Support
; %idefine SaveAllRegs          ; Uncomment to preserve all but return
                                ; registers in procedure and function calls
; %idefine TurboPascal55        ; Only for TP 5.5 Objs, not for TP 7.0 or
                                ; anything else!!

; %idefine DoubleFonts          ; Not yet implemented

; %idefine EnableMouse          ; Enable Mouse Support
; %idefine DisableMouse         ; Disable Mouse Support (default)

; Now for all the self configuring stuff.

%idefine QDefines

%ifndef TargetOS
    %idefine TargetOS DOS
%endif

%ifndef TargetCPU
    %idefine TargetCPU 286
%endif

%ifidni TargetCPU, 8086
	use16
%endif

%ifidni TargetCPU, 186
	use16
%endif

%ifidni TargetCPU, 286
	use16
%endif

%ifdef TP55
    %idefine TurboPascal55
%endif

%ifdef TP70
    %idefine TurboPascal70
%endif

%ifdef TurboPascal70
    %undef TurboPascal55
%endif

%ifndef EnableMouse
    %idefine DisableMouse
%endif

%ifdef EnableMouse
    %warning "Mouse support is enabled."
%endif

; Configuring One's Self A Little Bit
%ifidni __OUTPUT_FORMAT__, obj
    %idefine FarCalls
%else
    %undef TurboPascal55
    %warning "Binary COM file creation mode."
    %ifdef SaveAllRegs
        %warning "All none return value registers are preserved."
    %else
        %warning "Only the DS, SS, SP and BP registers are preserved!"
    %endif
    ; This really should not be in the defines file. But, oh well
    ; we will just stick it in here anyway.
    %idefine    ASMTools
    jmp SkipOverQCrt
%endif

%ifidn TargetCPU, 8086
    cpu 8086
    %warning Attempting to generate 8086 compatible code.
%endif

%ifdef FarCalls
    %idefine XCALL  CALL FAR
    %idefine STACKBP  BP + 6
%else
    %idefine XCALL  CALL
    %idefine STACKBP  BP + 4
%endif

%idefine DVSupport
%idefine BVSupport

%ifdef DirectVideoOnly
    %undef BVSupport
%endif

%ifdef BiosVideoOnly
    %undef DVSupport
%endif

%ifdef TurboPascal55
    %warning Forcing Turbo Pascal version 5.5 compatibility.
    %define Section_DATA DATA
    %define Section_SHARED BSS
    %define Section_CODE CODE
%else
    %define Section_DATA _DATA
    %define Section_SHARED _BSS
    %define Section_CODE _TEXT
%endif

%ifdef ASMTools
        %idefine    CRLF 0x0d,0x0a
%endif

; Constants

%idefine FALSE  00h
%idefine TRUE   01h

; Macros

%imacro MemByte 2
    push    es
    push    bx
    mov     bx, %1
    mov     es, bx
    mov     bx, %2
    mov     al, [ES:BX]
    pop     bx
    pop     es
%endmacro

%imacro MemWord 2
    push    es
    push    bx
    mov     bx, %1
    mov     es, bx
    mov     bx, %2
    mov     ax, [ES:BX]
    pop     bx
    pop     es
%endmacro

%imacro pushy 1-*
  %rep  %0
        push    %1
  %rotate 1
  %endrep
%endmacro

%imacro poppy 1-*
  %rep  %0
        pop    %1
  %rotate 1
  %endrep
%endmacro

%imacro pushcall 1-*
    %if %0 > 1
        %rep %0 - 1
            %rotate 1
            push    word %1
        %endrep
        %rotate 1
    %endif
    xcall %1
%endmacro

%imacro ReturnsNothing 0
    %ifdef SaveAllRegs
        %define     export_arg none
        pushf
        pushy   ax, dx, bx, cx, si, di, es
    %endif
%endmacro

%imacro ReturnsAX 0
    %ifdef SaveAllRegs
        %define     export_arg word
        pushy   dx, bx, cx, si, di, es
    %endif
%endmacro

%imacro ReturnsDXAX 0
    %ifdef SaveAllRegs
        %define     export_arg dword
        pushy   bx, cx, si, di, es
    %endif
%endmacro

%imacro RestoreRegisters 0
    %ifdef SaveAllRegs
        poppy es, di, si, cx, bx
        %ifidn export_arg, dword
            ; nothing to do here, move along
        %elifidn export_arg, word
            pop dx
        %elifidn export_arg, none
            poppy   dx, ax
            popf
        %endif
    %endif
%endmacro

%imacro xfunction 2-*
    global %1
    %1:
        %define export_name %1
        %if %0 = 3
            %define ret_pop %3
        %else
            %define ret_pop 0
        %endif
        ; %stacksize large  ; not using %arg
        push bp
        mov  bp, sp
        ; %ifdef FARCALLS   ; This would be needed if %arg worked
        ;    add bp, 2      ; inside macros, but it does not so
        ; %endif            ; we don't need it.
        %ifidni %2, word
            ReturnsAX
        %elifidni %2, byte
            ReturnsAX
        %elifidni %2, boolean
            ReturnsAX
        %elifidni %2, char
            ReturnsAX
        %elifidni %2, integer
            ReturnsAX
        %elifidni %2, dword
            ReturnsDXAX
        %elifidni %2, long
            ReturnsDXAX
        %elifidni %2, longint
            ReturnsDXAX
        %elifidni %2, pointer
            ReturnsDXAX
        %else
            ReturnsNothing
        %endif
%endmacro

%imacro xprocedure 1-* 0
    global %1
    %1:
        %define export_name %1
        %if %0 = 2
            %define ret_pop %2
        %else
            %define ret_pop 0
        %endif
        ; %stacksize large  ; not using %arg
        push bp
        mov  bp, sp
        ; %ifdef FARCALLS   ; This would be needed if %arg worked
        ;    add bp, 2      ; inside macros, but it does not so
        ; %endif            ; we don't need it.
        ReturnsNothing
%endmacro

%imacro xret 0-1
    %ifdef FarCalls
        %idefine xret_type   RETF
    %else
        %idefine xret_type   RET
    %endif
    RestoreRegisters
    pop bp
    %if %0 = 1
        %warning OVERRIDE export_name: ret %1
        xret_type %1
    %elif ret_pop = 0
        xret_type
    %else
        xret_type ret_pop
    %endif
    %undef xret_type
    %undef ret_pop
    %undef export_name
    %undef export_arg
%endmacro

; es:si is origin; cx is bytes per line, ax, bx, dx destroyed
%imacro xCalcScreenPtr 0
        ; cx bytes per line
        mov     cx, [ScreenMax]
        xor     ch, ch
        inc     cl
        shl     cx, 1
        ; true XY coordinate
        mov     dx, [WindMin]
        mov     bx, [CurrentXY]
        add     bl, dl          ; origin X is BL
        add     dh, bh          ; origin Y is DH
        xor     bh, bh          ; clear BH, now BX is X
        shl     bx, 1           ; times 2 Char/Attr
        xor     ah, ah          ; make AX, Y
        mov     al, dh
        mul     cx              ; Times Bytes per row
        add     bx, ax          ; add X offset
        les     si, [VideoPtr]
%endmacro

%imacro Terminate 0-1 0
        xcall DoneCrt
        MOV  AH, 4Ch
        MOV  AL, %1
        INT  21h
%endmacro

%imacro CommandLineParser 1
    cld
    xor         bx, bx
    mov         di, si
    xor         dh, dh
%%Loop:
    lodsb
    cmp         al, 0x0d
    je          %%Next
    cmp         al, 0x22
    je          %%Quote
    cmp         al, 0x27
    je          %%Quote
    cmp         al, 0x60
    je          %%Quote
    cmp         al, 0x20
    je          %%Next
    cmp         al, "/"
    je          %%Switch
    jmp         %%Loop
%%Quote:
    mov         ah, al
%%QuoteLoop:
    inc         dh
    lodsb
    cmp         al, 0x0d
    je          %%Error
    cmp         al, ah
    jne         %%QuoteLoop
    jmp         %%Loop
%%Next:
    mov         cx, si
    sub         cx, di
    cmp         cx, 1
    push        cx
    jle         %%Skip
    cmp         al, 0x0d
    jne         %%NotEnd
    dec         si
    dec         cx
%%NotEnd:
    push        si
    cmp         al, 0x20
    jne         %%NotSpace
    dec         si
    dec         cx
%%NotSpace:
    cmp         bx, 0
    jne         %%NotDefault
    mov         bx, [%1 + 2]
    xor         dl, dl
%%NotDefault:
    push        ax
    cmp         dh, 0
    je          %%NotQuoted
    inc         di
    dec         si
    sub         cx, 2
%%NotQuoted:
    call        bx
    xor         dh, dh
    pop         ax
    xor         bx, bx
    pop         si
%%Skip:
    pop         cx
    cmp         al, 0x0d
    je          %%Done
    cmp         al, 0x20
    jne         %%ResetBX
    cmp         cx, 1
    push        cx
    jle         %%KeepBX
%%ResetBX:
    xor         bx, bx
%%KeepBX:
    mov         di, si
    jmp         %%Loop
%%Switch:
    mov         di, si
    lodsb
    cmp         al, SwitchChar
    jl          %%Error
    cmp         al, 0x61
    jl          %%CaseOK
    cmp         al, 0x7a
    jg          %%CaseOK
    sub         al, 0x20
%%CaseOK:
    mov         bx, %1
%%Lookup:
    add         bx, 4
    mov         cx, [bx]
    cmp         cl, 0
    je          %%Error
    cmp         cl, al
    jne         %%Lookup
    mov         dx, [bx + 2]
    mov         bx, dx
    cmp         ch, 0
    jne         %%NeedsParam
    xor         cx, cx
    push        si
    mov         dl, al
    call        bx
    xor         dh, dh
    xor         bx,bx
    pop         si
    mov         di, si
    jmp         %%Loop
%%NeedsParam:
    xor         dh, dh
    mov         dl, al
    mov         di, si
    jmp         %%Loop
%%ErrorMsg:
    DB          "Error parsing command-line options.",CRLF,0
%%Error:
    WriteStr    %%ErrorMsg
    Terminate   1
%%Done:
    cmp         bx, 0
    jne         %%Error
%endmacro

; macro that shows command line switch and data, mostly for debuging the
; command line parser
%imacro CommandLineDebug 0
    push        cx
    push        dx
    mov         al, ' '
    WriteChar
    pop         dx
    cmp         dl, 0
    je          %%NoSwitch
    push        dx
    mov         al, SwitchChar
    WriteChar
    pop         dx
    mov         al, dl
    WriteChar
    pop         cx
    push        cx
    cmp         cx, 0
    jne         %%NoSwitch
    pop         cx
    ret
%%NoSwitch:
    mov         al, '('
    WriteChar
    pop         cx
    cmp         cx, 0
    je          %%NoText
%%Repeat:
    push        cx
    mov         al, [di]
    WriteChar
    pop         cx
    inc         di
    loop        %%Repeat
%%NoText:
    mov         al, ')'
    WriteChar
    ret
%endmacro
