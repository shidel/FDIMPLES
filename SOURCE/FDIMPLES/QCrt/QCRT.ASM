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

%idefine QCrt 9.1

%ifndef TargetOS
    %idefine TargetOS DOS
%endif

%ifndef TargetCPU
    %idefine TargetCPU 8086
%endif

%ifndef QDefines
	%include "QDEFINES.INC"
%endif

; Internal Data Segment
section Section_DATA

VideoPtr:
VideoOfs:
	DW 0
VideoSeg:
	DW 0
VideoPage:
	DB 0
DoubleWide:
	DB 0
UserFont:
	DB 0
CurrentXY:
CurrentX:
	DB 0
CurrentY:
	DB 0
CurrentCursor:
	DW 0
FirstMode:
	DW 0
FirstCursor:
	DW 0
FirstAttr:
	DB 0
DelayData:
	DW 0

%ifdef EnableMouse
    MouseMask:
        DW 0
    MouseHandler:
        DW 0, 0
    MouseLastState:
        DW 0, 0, 0 ; Button State, X, Y
    MouseFrozen:
        DB 0
    MouseCheckState:
        DW 0, 0, 0
    MouseShowLevel:
        DW 0
    MouseHiddenFlag:
        DW 0
    MouseButtonTrack:
        times 16 DW 0
    MouseDoubleFlag:
        DB 0

%endif

%ifidn __OUTPUT_FORMAT__, obj

section Section_SHARED

	extern CheckBreak 		; : boolean;	{ Enable Ctrl-Break }
	extern CheckEOF 		; : boolean;	{ Enable Ctrl-Z }
	extern DirectVideo		; : boolean;	{ Enable direct video addressing }
	extern CheckSnow 		; : boolean;	{ Enable snow filtering }
	extern LastMode 		; : word;		{ Current text mode }
	extern TextAttr 		; : byte;		{ Current text attribute }
	extern WindMin 			; : word;		{ Window upper left coordinates }
	extern WindMax 			; : word;		{ Window lower right coordinates }
	extern Check101Key		; : boolean; 	{ If 101-Key Keyboard is present }
	extern CheckScroll		; : boolean;	{ false causes window wrapping }
	extern UserFontHeight   ; : byte;		{ Height of user defined font }
	extern UserFontPtr      ; : pointer;	{ pointer to user defined font }
	extern TabWidth			; : byte;		{ Spaces per tab }
	extern ScreenMax		; : word;		{ Screen lower right coordinates }

    %ifdef EnableMouse
        extern MouseButtons     ; : integer;    { Number of buttons, 0 if no mouse }
        extern MouseVisible     ; : boolean;    { Visible state of mouse }
        extern MouseCellX       ; : word;       { Value to slow down movement }
        extern MouseCellY       ; : word;       { Value to slow down movement }
        extern MouseClickSpeed  ; : word;       { Mouse double click speed }
        extern MouseHomeX       ; : integer;    { X Home position of mouse }
        extern MouseHomeY       ; : integer;    { Y Home position of mouse }
    %endif

    extern IdleCPU        ; : boolean;      { Idle CPU during Idle Process }
    extern IdleProc       ; : pointer;      { Idle procedure chain }

%else
	CheckBreak: 	DB FALSE
	CheckEOF: 		DB FALSE
	DirectVideo:	DB FALSE
	CheckSnow:		DB FALSE
	LastMode:		DW 0
	TextAttr:		DB 0
	WindMin:		DW 0
	WindMax:		DW 0
	ScreenMax:		DW 0
	Check101Key:	DB FALSE
	CheckScroll:	DB FALSE
	UserFontHeight:	DB 0
	UserFontPtr:	DD 0
	TabWidth:		DB 0
    %ifdef EnableMouse
        MouseButtons    DB 0
        MouseVisible    DB FALSE
        MouseCellX      DW 0
        MouseCellY      DW 0
        MouseClickSpeed DW 0
        MouseHomeX      DB 0
        MouseHomeY      DB 0
    %endif

%endif

section Section_CODE

; ------------------- Internal Functions; Don't call them directly !!!!

%ifdef EnableMouse
    ; Mouse Interrupt Handler Needs to be able to find program data segment
    MouseDS:
        dw 0
%endif

%imacro PreWriteXY 0
    %ifdef EnableMouse
        pushf
        cli
        push    ax
        push    bx
        mov     ax, [CurrentXY]
        mov     bl, [MouseLastState + 2]
        mov     bh, [MouseLastState + 4]
        cmp     ax, bx
        jne     %%Safe
        mov     [MouseHiddenFlag], byte TRUE
        call    MouseHidePointer
    %%Safe:
        pop     bx
        pop     ax
        popf
    %endif
%endmacro

%imacro PreWrite 0
    %ifdef EnableMouse
        pushf
        cli
        push    ax
        mov     [MouseHiddenFlag], byte TRUE
        call    MouseHidePointer
        pop     ax
        popf
    %endif
%endmacro

%imacro PostWriteXY 0
    %ifdef EnableMouse
        pushf
        cli
        push    ax
        mov     al, [MouseHiddenFlag]
        mov     [MouseHiddenFlag], byte FALSE
        cmp     al, TRUE
        jne     %%Safe
        call    MouseShowPointer
    %%Safe:
        pop     ax
        popf
     %endif
%endmacro

%imacro PostWrite 0
    %ifdef EnableMouse
        pushf
        cli
        push    ax
        mov     al, [MouseHiddenFlag]
        mov     [MouseHiddenFlag], byte FALSE
        cmp     al, TRUE
        call    MouseShowPointer
    %%Safe:
        pop     ax
        popf
    %endif
%endmacro

; Internal Crt Variable Data Initialization, called at any video mode change

InitCrtData:
	mov		[WindMin], word 0x0000

	; set current video text mode data
	MemByte 0x0040, 0x0049
	mov		bl, al
	MemByte 0x0040, 0x0085
	mov		bh, al
	mov		al, [DoubleWide]
	cmp		al, TRUE
	jne		.NotDouble
	or		bh, 0x80
.NotDouble:

	mov		al, [UserFont]
	cmp		al, TRUE
	jne		.NotUserFont
	or		bh, 0x40
.NotUserFont:
	mov		[LastMode], bx

	; figure out screen dimensions
	MemWord 0x0040, 0x004A
	dec		ax
	mov		ah, al
	MemByte 0x0040, 0x0084
	xchg	al, ah
	mov		[ScreenMax], ax
	mov		[WindMax], ax

	MemByte	0x0040, 0x0062
	mov		[VideoPage], al

	; get cursor position and shape
	call	ReadCursor

	; detect direct video memory address
	MemWord 0x0040, 0x004E
	mov		[VideoOfs], ax
	mov		[VideoSeg], word 0xB800
	mov		[DirectVideo], byte FALSE
	mov		ax, [LastMode]
	and		ax, 0x00FF
	cmp		ax, 0x07
	jne		.NotMono
	mov		[VideoSeg], word 0xB000
.NotMono:
	cmp		ax, 0x03
	jg		.NoDirectVideo
	%ifdef DVSupport
		%warning Direct Video Not Yet Implemented
		mov		[DirectVideo], byte TRUE
	%elifdef DirectVideoOnly
		%warning Compiling without BIOS Video Support
	%elifdef BiosVideoOnly
		%warning Compiling without Direct Video Support
	%else
		%fatal Neither Direct or BIOS level video support active.
	%endif
.NoDirectVideo:
ret

; internal read cursor data
ReadCursor:
	mov		ah, 0x03
    mov		bh, [VideoPage]
    int		0x10
    mov		[CurrentCursor], cx
	mov		[CurrentX], dl
	mov		[CurrentY], dh
ret

; Internal Actual procedure that moves the cursor
MoveCursorActual:
	mov 	ah, 0x02
	mov		bx, [WindMin]
	mov		dl, [CurrentX]
	mov		dh, [CurrentY]
	add		dl, bl
	add		dh, bh
    mov		bh, [VideoPage]
    int		0x10
ret

; Internal Post write cursor movement
MoveCursorNow:
	mov		ah, [DirectVideo]
	cmp		ah, TRUE
	jne		MoveCursorActual
	mov		ax, [CurrentCursor]
	cmp		ax, 0x2000
	jne		MoveCursorActual
ret

; internal cursor movement to CurrentX, CurrentY
MoveCursorMaybe:
	mov		ah, [DirectVideo]
	cmp		ah, TRUE
	jne		MoveCursorActual
ret

; internal next character movement
MoveCursorNext:
	mov		bx, [WindMin]
	mov		dx, [WindMax]
	mov		al, [CurrentX]
	inc		al
	mov		[CurrentX], al
	mov		ah, [CurrentY]
	add		al, bl
	cmp		al, dl
	jle		.InsideWindow
	mov		al, 0x00
	mov		[CurrentX], al
	inc		ah
	mov		[CurrentY], ah
	add		ah, bh
	cmp		ah, dh
	jle		.InsideWindow
	mov		ah, 0x00
	mov		[CurrentY], ah
	mov		ah, [CheckScroll]
	cmp		ah, FALSE
	je		.InsideWindow
	sub		dh, bh
	mov		[CurrentY], dh
	xcall   LineFeed
.InsideWindow:
	call	MoveCursorMaybe
ret

; internal Write Character to Screen
WriteRawCrtChar:
	pushy   ax, bx, cx, dx
    PreWriteXY

	%ifdef DVSupport
		mov		ah, [DirectVideo]
		cmp		ah, TRUE
		jne		.BiosMode
		pushy	es, si
		mov		ah, [TextAttr]
		push	ax
		xCalcScreenPtr
		pop		ax
		es mov	[SI+BX], AX
		poppy	si, es
		jmp		.Done
	.BiosMode:
	%endif
	%ifdef BVSupport
		mov		ah, 0x09
		mov		bh, [VideoPage]
		mov		bl, [TextAttr]
		mov		cx, 0x0001
		int		0x10
	%endif

.Done:
    PostWriteXY
    call	MoveCursorNext
	poppy	dx, cx, bx, ax
ret

; internal Font setting routine
SetFontMode:
	mov		[DoubleWide], byte FALSE
	mov		[UserFont], byte FALSE

	mov		cx, ax
	cmp		ch, 0
	je		.Done

	mov		bl, 0
	mov		ah, 0x11
	mov		al, 0x12
	cmp		ch, 0x08
	je		.LoadROMFont
	mov		al, 0x11
	cmp		ch, 0x0E
	je		.LoadROMFont
	mov		al, 0x14
	cmp		ch, 0x10
	je		.LoadROMFont

	test	ch, 0x40
	jz		.Done
	mov		[UserFont], byte TRUE
	test	ch, 0x80
	jz		.NotDoubleWide
	mov		[DoubleWide], byte TRUE
.NotDoubleWide:
	; set user font
	push	bp
	push	es
	mov		ax, 0x1110
	mov		bl, 0x00
	mov		cx, 0x00FF
	mov		dx, 0x0000
	mov		bh, [UserFontHeight]
	les		bp, [UserFontPtr]
	int		0x10
	pop		es
	pop		bp

	%ifdef DoubleFonts
		; here will be code to set other half of double wide user font.
		%fatal "Double Wide Fonts have not been implemented"
	%endif
	jmp		.Done

.LoadROMFont:
	int		0x10
	jmp		.Done

.Done:
ret

%ifdef EnableMouse

SwapMouseHandler:
    mov     ax, [MouseButtons]
    cmp     ax, 0x0000
    je      .NoMouse
    push    es

    mov     dx, [MouseHandler+2]
    push    dx
    pop     es
    mov     dx, [MouseHandler]
    mov     cx, [MouseMask]

    mov     ax, 0x0014
    int     0x33

    mov     [MouseMask], cx
    mov     [MouseHandler], dx
    push    es
    pop     dx
    mov     [MouseHandler+2], dx

    pop     es
.NoMouse:
ret

MouseEventHandler:
    ;    AX = Event Flag
    ;    BX = Button State
    ;    CX = X coor
    ;    DX = Y Coor
    ;    SI = X Movement
    ;    DI = Y Movement
    ;    DS = Mouse Driver Data Segment

    pushf
    cli
    push    ds
    push    es

    %ifidn  TargetCPU, 8086
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    bp
    %else
        pusha
    %endif
    mov     bp, sp

    mov     ax, [CS:MouseDS]
    push    ax
    pop     ds

    push bx

    ; Mouse Y
    mov     ax, dx
    xor     dx, dx
    mov     bx, [MouseCellY]
    div     bx
    push    ax

    ; Mouse X
    mov     ax, cx
    xor     dx, dx
    mov     bx, [MouseCellX]
    div     bx
    mov     cx, ax
    pop     dx
    pop     bx

    mov     ax, [MouseLastState + 2]
    cmp     ax, cx
    jne     .Changes
    mov     ax, [MouseLastState + 4]
    cmp     ax, dx
    jne     .Changes
    mov     ax, [MouseLastState]
    cmp     ax, bx
    je      .NoChange
.Changes:

    ; Update Software Mouse Position
    mov     [MouseLastState], bx
    mov     [MouseLastState + 2], cx
    mov     [MouseLastState + 4], dx

    mov     al, [MouseFrozen]
    cmp     al, TRUE
    je      .Frozen

    mov     ax, [MouseCheckState]
    cmp     ax, bx
    je      .NoFreeze
    mov     [MouseFrozen], byte TRUE
    mov     [MouseCheckState + 2], cx
    mov     [MouseCheckState + 4], dx
.NoFreeze:
    mov     [MouseCheckState], bx

.Frozen:

.NoChange:
    mov     sp, bp
    %ifidn  TargetCPU, 8086
        pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
    %else
        popa
    %endif

    pop     es
    pop     ds
    popf
retf

MouseHidePointer:
    pushf
    cli
    mov     ax, [MouseButtons]
    cmp     ax, 0x0000
    je      MouseSetVisible
    mov     ax, [MouseShowLevel]
    dec     ax
    mov     [MouseShowLevel], ax
    cmp     ax, 0
    jne     MouseSetVisible
    mov     ax, 0x0002
    int     0x33
    jmp     MouseSetVisible

MouseShowPointer:
    pushf
    cli
    mov     ax, [MouseButtons]
    cmp     ax, 0x0000
    je      MouseSetVisible
    mov     ax, [MouseShowLevel]
    inc     ax
    mov     [MouseShowLevel], ax
    cmp     ax, 1
    jne     MouseSetVisible
    mov     ax, 0x0001
    int     0x33
    jmp     MouseSetVisible

MouseSetVisible:
    mov     ax, [MouseShowLevel]
    cmp     ax, 0
    jg      .SetVisible
    mov     [MouseVisible], byte FALSE
    popf
    ret
.SetVisible:
    mov     [MouseVisible], byte TRUE
    popf
    ret

MouseSetPosition:
    pushf
    cli
    mov     ax, [MouseLastState + 2]
    mov     cx, [MouseCellX]
    mul     cx
    mov     cx, ax
    mov     ax, [MouseLastState + 4]
    mov     dx, [MouseCellY]
    mul     dx
    mov     dx, ax
    mov     ax, 0x0004
    int     0x33
    popf
    ret

MouseHome:
    pushf
    cli
    mov     ax, [MouseHomeX]
    mov     [MouseLastState + 2], ax
    mov     ax, [MouseHomeY]
    mov     [MouseLastState + 4], ax
    call    MouseSetPosition
    xor     ax, ax
    mov     [MouseLastState], ax
    popf
    ret

MouseInit:
    pushf
    cli
    push    cs
    pop     ax
    mov     [MouseHandler + 2], ax
    mov     ax, MouseEventHandler
    mov     [MouseHandler], ax
    mov     ax, 01111111b
    mov     [MouseMask], ax
    jmp     MouseActivate
MouseReset:
    mov     ax, [MouseButtons]
    cmp     ax, 0x0000
    jne      .MousePresent
    popf
    ret
.MousePresent:
    call    SwapMouseHandler
MouseActivate:
    mov     ax, [MouseButtons]
    cmp     ax, 0x0000
    je      .NoMouse
    mov     ax, 0x0000
    int     0x33
    mov     [MouseFrozen], byte FALSE
    mov     [MouseDoubleFlag], byte FALSE
    mov     [MouseClickSpeed], word 0x0010
    mov     [MouseVisible], byte FALSE
    mov     [MouseShowLevel], word 0
    mov     [MouseCellX], word 0x0008
    ; Check for 40 Column Display
    mov     ax, [LastMode]
    cmp     al, 0x01
    ja      .NormalWidth
    ;mov     ax, 0x0010
    ;mov     [MouseCellX], ax
    mov     ax, 0x08
    mov     dx, 40 ; Decimal Column max
    mul     dx
    mov     dx, ax
    dec     dx
    xor     cx, cx ; Minimum Column
    mov     ax, 0x0007
    int     0x33
.NormalWidth:
    mov     [MouseCellY], word 0x0008
    xor     ax, ax
    mov     al, [ScreenMax]
    shr     ax, 1
    mov     [MouseHomeX], ax
    mov     al, [ScreenMax+1]
    shr     ax, 1
    mov     [MouseHomeY], ax

    call    SwapMouseHandler
    call    MouseHome
    call    MouseShowPointer
.NoMouse:
    popf
    ret

%endif

; ------------------------------- QCrt Interface Functions and Procedures

; function InitQCrt : boolean; external;
xfunction InitQCrt, boolean
	mov 	[IdleCPU], byte FALSE
	mov 	[IdleProc], word 0x0000
	mov 	[IdleProc + 2], word 0x0000
	mov 	[CheckBreak], byte FALSE
	mov 	[CheckScroll], byte TRUE
	mov 	[DoubleWide], byte FALSE
	mov 	[UserFont], byte FALSE
	mov		[CheckSnow], byte FALSE
	mov		[CheckEOF], byte FALSE
	mov		[Check101Key], byte FALSE
	mov		[TabWidth], byte 0x08

	%ifdef EnableMouse
        push    ds
        pop     ax
        mov     [cs:MouseDS], ax

        mov     [MouseButtons], word 0x0000
        mov     [MouseVisible], byte FALSE
        mov     [MouseShowLevel], word 0
        mov     [MouseClickSpeed], word 0x0002

        ; first test valid Mouse Interrupt Vector
        push    es
        push    di
        mov     ax, 0x0033
        mov     cx, 0x0004
        mul     cx
        mov     di, cx
        xor     cx, cx
        mov     ax, [es:di + 2]
        mov     bx, [es:di]
        cmp     ax, cx
        jne     .MouseIRQTest
        cmp     bx, cx
        je      .MouseFailed
    .MouseIRQTest:
        push    ax
        pop     es
        mov     al, [es:bx]
        cmp     al, 0xcf
        jne     .MouseCheck
    .MouseFailed:
        pop     di
        pop     es
        jmp     .NoMousePresent
    .MouseCheck:
        pop     di
        pop     es
        xor     ax, ax
        int     0x33
        cmp     ax, 0xffff
        jne     .NoMousePresent
        mov     ax, 0x0002
        cmp     bx, 0xffff
        je      .MousePresent
        mov     ax, bx
        cmp     bx, 0x0000
        jne     .MousePresent
        mov     ax, 0x0001
    .MousePresent:
        mov     [MouseButtons], ax
    .NoMousePresent:

    %endif

	; Read ega 814 font and set as default user font
	%ifdef DirectVideoOnly
		%warning "Default UserFontPtr set to Nil"
		xor		ax, ax
		mov		[UserFontHeight], al
		mov		[UserFontPtr], ax
		mov		[UserFontPtr + 2], ax
	%else
		mov		[UserFontHeight], byte 0x0E
		mov		ax, 0x1130
		mov		bh, 0x02
		push 	es
		push 	bp
		int		0x10
		mov		[UserFontPtr], bp
		mov		[UserFontPtr + 2], es
		pop		bp
		pop		es
	%endif
	; test for 101 Key keyboard support
	MemByte	0x0040, 0x0096
	test	al, 0x10
	jz 		.Not101Key
	mov		[Check101Key], byte TRUE
.Not101Key:

	call	InitCrtData
	mov		ax, [LastMode]
	mov		[FirstMode], ax

	mov		ax, [CurrentCursor]
	mov		[FirstCursor], ax

	mov		[TextAttr], byte 0x07
	mov		al, [TextAttr]
	mov		[FirstAttr], al

    %ifdef EnableMouse
        call    MouseInit
    %endif

	mov		ax, TRUE
	cmp		ax, TRUE
xret

; procedure DoneQCrt;
xprocedure DoneQCrt
    %ifdef EnableMouse
        mov     ax, [MouseButtons]
        cmp     ax, 0x0000
        je      .NoMouse
        call    MouseHidePointer
        call    SwapMouseHandler
        xor     ax, ax
        mov     [MouseButtons], ax
        ; mov     ax, 0x0000
        int     0x33
    .NoMouse:
    %endif

	mov		al, [FirstAttr]
	mov		[TextAttr], al
	mov		ax, [FirstMode]
	mov		bx, [LastMode]
	cmp		ax, bx
	je		.ValidMode
	pushcall TextMode, ax
.ValidMode:
	mov		ax, [FirstCursor]
	mov		bx, [CurrentCursor]
	cmp		ax, bx
	je		.ValidCursor
	pushcall SetCursor, ax
.ValidCursor:
	mov		[DirectVideo], byte FALSE
	call  	MoveCursorNow
	pushcall NoSound
xret

; function KeyPressed : boolean; external;
xfunction KeyPressed, boolean
	mov  	ah, 0x01
	int  	0x16
	mov  	al, FALSE
	jz   	.Done
	mov  	al, TRUE
.Done:
	xor		ah, ah
	cmp		al, TRUE
xret

; function ReadKey : char; external;
xfunction ReadKey, char
	mov  	ah, 0x00
	int  	0x16
	xor 	ah, ah
xret

; function KeyPressedEnhanced : boolean; external;
xfunction KeyPressedEnhanced, boolean
	mov  	ah, 0x11
	int  	0x16
	mov  	al, FALSE
	jz   	.Done
	mov  	al, TRUE
.Done:
	xor		ah, ah
	cmp		al, TRUE
xret

; function ReadKeyEnhanced : word; external;
xfunction ReadKeyEnhanced, word
	mov  	ah, 0x10
	int  	0x16
	cmp  	al, 0x00
	je   	.Done
	cmp  	al, 0xE0
	je   	.ClearLow
	mov  	ah, 0x00
	jmp  	.Done
.ClearLow:
	mov		al, 0x00
.Done:
xret

; procedure TextMode(Mode : integer); external;
xprocedure TextMode, 2
	mov 	ax, [STACKBP + 0]
	push	ax
	xor		ah, ah
	int		0x10
	pop		ax
	call	SetFontMode
	call 	InitCrtData
	%ifdef EnableMouse
	    call MouseReset
	%endif
xret

; procedure Window(X1, Y1, X2, Y2 : byte); external;
xprocedure Window, 8
	mov		al, [STACKBP + 6]
	mov		ah, [STACKBP + 4]
	mov		dl, [STACKBP + 2]
	mov		dh, [STACKBP + 0]
	mov		bx, [ScreenMax]
	dec		al
	dec		ah
	dec		dl
	dec		dh
	cmp 	al, dl
	jg		.Invalid
	cmp 	ah, dh
	jg		.Invalid
	cmp		dl, bl
	jg		.Invalid
	cmp		dh, bh
	jg		.Invalid
	mov		[WindMin], ax
	mov		[WindMax], dx
	mov		ax, 0x01
	push 	ax
	push	ax
	xcall GotoXY
.Invalid:
xret

; procedure GotoXY(X, Y : byte); external;
xprocedure GotoXY, 4
	mov		al, [STACKBP + 2]
	mov		ah, [STACKBP + 0]
	dec		al
	dec		ah
	; bounds checking
	mov		bx, [WindMax]
	mov		cx, [WindMin]
	sub		bh, ch
	sub		bl, cl
	inc		bl
	inc		bh
.BadX:
	cmp		al, bl
	jl	 	.BadY
	sub		al, bl
	jmp		.BadX
.BadY:
	cmp		ah, bh
	jl	 	.AllGood
	sub		ah, bh
	jmp		.BadY
.AllGood:
	mov		[CurrentX], al
	mov		[CurrentY], ah

.Done:
	call 	MoveCursorNow

xret

; function WhereX: byte; external;
xfunction WhereX, byte
	mov 	al, [CurrentX]
	inc		al
	xor		ah, ah
xret

; function WhereY: byte; external;
xfunction WhereY, byte
	mov 	al, [CurrentY]
	inc		al
	xor		ah, ah
xret

; procedure TextColor(Color : byte); external;
xprocedure TextColor, 2
	mov		al, [TextAttr]
	and		al, 0xF0
	mov		ah, [STACKBP + 0]
	and		ah, 0x0F
	or		al, ah
	mov		[TextAttr], al
xret

; procedure TextBackground(Color : byte); external;
xprocedure TextBackground, 2
	mov		al, [TextAttr]
	and		al, 0x0F
	mov		ah, [STACKBP + 0]
	and		ah, 0x0F
	%ifidn TargetCPU, 8086
		mov		cl, 4
		shl		ah, cl
	%else
		shl		ah, 4
	%endif
	or		al, ah
	mov		[TextAttr], al
xret

; procedure LowVideo; external;
xprocedure LowVideo
	mov		al, [TextAttr]
	and		al, 0xF7
	mov		[TextAttr], al
xret

; procedure HighVideo; external;
xprocedure HighVideo
	mov		al, [TextAttr]
	or		al, 0x08
	mov		[TextAttr], al
xret

; procedure NormVideo; external;
xprocedure NormVideo
	mov		al, [FirstAttr]
	mov		[TextAttr], al
xret

; procedure Delay(MS : Word); external;
xprocedure Delay, 2
	mov  	dx, [STACKBP + 0]
	cmp		dx, 0x0000
	je		.NoDelay
	%ifidn TargetCPU, 8086
		; internal delay routine based on timer ticks
		%warning "8086 compatible timer in use!"
			mov		ax, dx
			xor  	dx, dx
			mov  	cx, 55
			div  	cx
			cmp		dx, 23
			jl		.NoRoundUp
			inc		ax
		.NoRoundUp:
			cmp		ax, 0
			je		.Done
			mov		cx, ax
			mov  	dx, 0x0040
			mov		es, dx
			mov		di, 0x006C
		.Loop:
			mov		dx, [ES:DI]
		.Wait:
			mov		ax, [ES:DI]
			cmp		dx, ax
			je		.Wait
			loop	.Loop
		.Done:
	%else
		; %warning "Interrupt based precision timer in use (requires 286+)."
			push	dx
			mov  	ax, 0x8301
			int  	0x15
			mov  	ax, 0x8300
			mov  	[DelayData], al
			pop		dx
			mov  	cx, dx
			shl  	dx, 0x0a
			shr  	cx, 0x06
			push	ds
			pop		es
			mov		bx, DelayData
			int  	0x15
		.Loop:
			mov  	al, [DelayData]
			test 	al, 0x80
			jz   	.Loop
	%endif
	.NoDelay:
xret

; procedure Sound(Hz : Word); external;
xprocedure Sound, 2
	mov  	cx, [STACKBP + 0]
	cmp		cx, 0x0012
	jle  	.NoSound
	mov		dx, 0x0012
	mov		ax, 0x34DC
	div		cx
	jmp  	.DoSound
.NoSound:
	xor		ax, ax
.DoSound:
	push	ax
	mov 	al, 10110110b
	mov 	dx, 0x0043
	out 	dx, al
	mov 	dx, 0x0042
	pop		ax
	out		dx, al
	mov		al, ah
	out		dx, al
	mov		dx, 0x0061
	in		al, dx
	mov		al, 0x03
	out		dx, al
xret

; procedure NoSound; external;
xprocedure NoSound
	MOV  DX, 0x0061
	IN   AL, DX
	AND  AL, 11111101b
	OUT  DX, AL
	MOV  AL, 10110110b
	MOV  DX, 0x0043
	OUT  DX, AL
	MOV  DX, 0x0042
	MOV  AL, 0
	OUT  DX, AL
	OUT  DX, AL
xret

; procedure WriteRawZStr(const S); external;
xprocedure WriteRawZStr, 4
	mov		bx, [STACKBP + 0]
	mov		si, bx
	mov		bx, [STACKBP + 2]
	mov		es, bx
	xor		ch, ch
	cld
.WriteLoop:
	es 		lodsb
	cmp		al, 0x00
	je		.Done
	call	WriteRawCrtChar
	jmp		.WriteLoop
.Done:
	call	MoveCursorNow
xret

%ifdef ASMTools
	xprocedure WriteStr, 4
		mov		bx, [STACKBP + 0]
		mov		si, bx
		mov		bx, [STACKBP + 2]
		mov		es, bx
		xor		ch, ch
		cld
	.WriteLoop:
		es 			lodsb
		cmp			al, 0x00
		je			.Done
		cmp			al, 0x0d
		je			.Return
		cmp			al, 0x0a
		je			.LineFeed
		cmp			al, 0x08
		je			.BackSpace
		cmp			al, 0x09
		je			.HTab
		cmp			al, 0x0b
		je			.VTab
		cmp			al, 0x0c
		je			.FormFeed
		cmp			al, 0x07
		je			.Bell
		cmp			al, 0x7F
		je			.Delete
		cmp			al, 0x20
		jl			.NoChar
		call		WriteRawCrtChar
		jmp			.WriteLoop
	.Return:
		pushcall	CarriageReturn
		jmp			.WriteLoop
	.LineFeed:
		pushcall 	LineFeed
		jmp			.WriteLoop
	.BackSpace:
		pushcall	BackSpace
		jmp			.WriteLoop
	.HTab:
		pushcall	Tab
		jmp			.WriteLoop
	.VTab:
	.FormFeed:
	.Bell:
	.Delete:
	.NoChar:
		jmp			.WriteLoop
	.Done:
		call	MoveCursorNow
	xret

	xprocedure WriteInt, 2
		mov		ax, [STACKBP + 0]
        mov  	bx, 0x000A
        mov		cx, 0x0001
	.DoneYet:
		cmp		ax, bx
		jge		.TooBig
		push	ax
	.JustRight:
		pop		ax
		add		ax, 0x0030
        call	WriteRawCrtChar
        loop	.JustRight
		jmp		.Done
	.TooBig:
		inc		cx
		xor 	dx, dx
		div		bx
		push	dx
		jmp		.DoneYet
      .Done:
		call	MoveCursorNow
	xret
%else
	; procedure WriteRawPStr(S : String); external;
	xprocedure WriteRawPStr, 4
		mov		bx, [STACKBP + 0]
		mov		si, bx
		mov		bx, [STACKBP + 2]
		mov		es, bx
		xor		ch, ch
		mov		cl, [es:si]
		inc		si
		cmp		cx, 0x00
		je		.Done
		cld
	.WriteLoop:
		es 		lodsb
		call	WriteRawCrtChar
		loop	.WriteLoop
	.Done:
		call	MoveCursorNow
	xret
%endif

; procedure CarriageReturn; external;
xprocedure CarriageReturn
	mov		al, 0x00
	mov		[CurrentX], al
	call	MoveCursorNow
xret

; procedure LineFeed; external;
xprocedure LineFeed
	mov		bx, [WindMin]
	mov		dx, [WindMax]
	mov		al, [CurrentY]
	inc		al
	mov		ah, al
	add		ah, bh
	cmp		ah, dh
	jle		.InsideWindow
	dec		al
	push	ax
	mov		ax, 1
	push	ax
	xcall 	ScrollUp
	pop		ax
.InsideWindow:
	mov		[CurrentY], al
	call	MoveCursorNow
xret

; procedure BackSpace; external;
xprocedure BackSpace
	mov		al, [CurrentX]
	cmp		al, 0x00
	je		.Ignore
	dec		al
	mov		[CurrentX], al
	call	MoveCursorNow
.Ignore:
xret

; procedure Tab; external;
xprocedure Tab
	xor		ch, ch
	mov		cl, [TabWidth]
	cmp		cl, 1
	jl		.Done
	je		.MoveLoop
	xor		ax, ax
	xor		dx, dx
	mov		al, [CurrentX]
	inc		al
	div		cl
	mov		cl, [TabWidth]
	sub		cl, ah
	jcxz	.Done
.MoveLoop:
	mov		al, 0x20
	call	WriteRawCrtChar
	; Call	MoveCursorMaybe
	loop	.MoveLoop
.Done:
xret

; procedure SetCursor( Shape : word ); external;
xprocedure SetCursor, 2
    mov		ah, 0x01
	mov		cx, [STACKBP + 0]
    int		0x10
	call	ReadCursor
xret

; procedure HideCursor; external;
xprocedure HideCursor
	mov		ax, 0x2000
	push 	ax
	xcall   SetCursor
xret

; procedure InsertCursor; external;
xprocedure InsertCursor
	xcall FullCursor
xret

; procedure NormalCursor; external;
xprocedure NormalCursor
	mov		ax, [FirstCursor]
	push 	ax
	xcall SetCursor
xret

; procedure SmallCursor; external;
xprocedure SmallCursor
	MemByte 0x0040, 0x0085
	mov		ah, al
	sub     ah, 2
	push 	ax
	xcall SetCursor
xret

; procedure HalfCursor; external;
xprocedure HalfCursor
	MemByte 0x0040, 0x0085
	mov		ah, al
	shr		ah, 1
	push 	ax
	xcall SetCursor
xret

; procedure FullCursor; external;
xprocedure FullCursor
	MemByte 0x0040, 0x0085
	mov		ah, 0
	push 	ax
	xcall SetCursor
xret

; -------- These functions require Direct and BIOS level versions ---------
; procedure ScrollUp(Rows :byte); external;
xprocedure ScrollUp, 2
    PreWrite
	mov		ah, 6
	mov		al, [STACKBP + 0]
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	int		0x10
	PostWrite
xret

; procedure ScrollDown(Rows :byte); external;
xprocedure ScrollDown, 2
    PreWrite
	mov		ah, 7
	mov		al, [STACKBP + 0]
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	int		0x10
	PostWrite
xret

; procedure ClrScr; external;
xprocedure ClrScr
    PreWrite
	mov		ax, 0x0600
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	int		0x10
	mov		ax, 1
	push 	ax
	push	ax
	xcall 	GotoXY
	PostWrite
xret

; procedure ClrEol; external;
xprocedure ClrEol
    PreWrite
	mov		ax, 0x0600
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dl, [CurrentX]
	mov		dh, [CurrentY]
	add		cl, dl
	add		ch, dh
	mov		dx, [WindMax]
	mov		dh, ch
	int		0x10
	PostWrite
xret

; procedure InsLine; external;
xprocedure InsLine
    PreWrite
	mov		ax, 0x0701
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	mov		bl, [CurrentY]
	add		ch, bl
	int		0x10
	PostWrite
xret

; procedure DelLine; external;
xprocedure DelLine
    PreWrite
	mov		ax, 0x0601
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	mov		bl, [CurrentY]
	add		ch, bl
	int		0x10
	PostWrite
xret

; procedure InsChar; external;
xprocedure InsChar
    PreWrite
	mov		dl, [CurrentX]
	push	dx
	mov		ax, [WindMin]
	mov		cx, [WindMax]
	sub		cl, al
	sub		cl, dl
	add		dl, cl
	xor		ch, ch
.InsLoop:
	dec		dl
	mov		[CurrentX], dl
	pushy	dx, cx
	call	MoveCursorActual
	mov		ah, 0x08
	mov		bh, [VideoPage]
	int 	0x10
	poppy	cx, dx
	pushy 	dx, cx, bx, ax
	inc		dl
	mov		[CurrentX], dl
	call	MoveCursorActual
	poppy	ax, bx
	mov		bl, ah
	mov		bh, [VideoPage]
	mov		cx, 0x0001
	mov		ah, 0x09
	int		0x10
	poppy	cx, dx
	loop	.InsLoop
	pop		dx
	mov		[CurrentX], dl
	call	MoveCursorActual
	mov		ax, 0x0920
	mov		bl, [TextAttr]
	mov		cx, 0x0001
	int		0x10
	PostWrite
xret

; procedure DelChar; external;
xprocedure DelChar
    PreWrite
	mov		al, [CurrentX]
	push 	ax
	mov		dx, [WindMin]
	mov		cx, [WindMax]
	sub		cl, dl
	sub		cl, al
	mov		dl, al
	xor		ch, ch
.InsLoop:
	inc		dl
	mov		[CurrentX], dl
	pushy	dx, cx
	call	MoveCursorMaybe
	mov		ah, 0x08
	mov		bh, [VideoPage]
	int 	0x10
	poppy	cx, dx
	pushy 	dx, cx, bx, ax
	dec		dl
	mov		[CurrentX], dl
	call	MoveCursorMaybe
	poppy	ax, bx
	mov		bl, ah
	mov		bh, [VideoPage]
	mov		cx, 0x0001
	mov		ah, 0x09
	int		0x10
	poppy	cx, dx
	loop	.InsLoop
	mov		[CurrentX], dl
	call	MoveCursorMaybe
	mov		ax, 0x0920
	mov		bl, [TextAttr]
	mov		cx, 0x0001
	int		0x10
	pop		ax
	mov		[CurrentX], al
	call	MoveCursorMaybe
	PostWrite
xret

; procedure InsColumn; external;
xprocedure InsColumn
    PreWrite
	mov		dh, [CurrentY]
	push 	dx
	mov		cx, [WindMax]
	mov		dx,	[WindMin]
	sub		ch, dh
	inc		ch
	mov		cl, ch
	xor		ch, ch
	xor		dl, dl
.LineLoop:
	mov		[CurrentY], dl
	inc		dl
	pushy	cx, dx
	xcall	InsChar
	poppy	dx, cx
	Loop	.LineLoop
	pop		dx
	mov		[CurrentY], dh
	call	MoveCursorMaybe
	PostWrite
xret

; procedure DelColumn; external;
xprocedure DelColumn
    PreWrite
	mov		dh, [CurrentY]
	push 	dx
	mov		cx, [WindMax]
	mov		dx,	[WindMin]
	sub		ch, dh
	inc		ch
	mov		cl, ch
	xor		ch, ch
	xor		dl, dl
.LineLoop:
	mov		[CurrentY], dl
	inc		dl
	pushy	cx, dx
	pushcall	DelChar
	poppy	dx, cx
	Loop	.LineLoop
	pop		dx
	mov		[CurrentY], dh
	call	MoveCursorMaybe
	PostWrite
xret

; procedure ScrollLeft(Columns :byte); external;
xprocedure ScrollLeft, 2
	mov		cl, [STACKBP + 0]
	xor		ch, ch
	mov		dl, [CurrentX]
	push	dx
	mov		[CurrentX], ch
.CountLoop:
	push	cx
	pushcall	DelColumn
	pop		cx
	loop 	.CountLoop
	pop		dx
	mov		[CurrentX], dl
xret

; procedure ScrollRight(Rows :byte); external;
xprocedure ScrollRight, 2
	mov		cl, [STACKBP + 0]
	xor		ch, ch
	mov		dl, [CurrentX]
	push	dx
	mov		[CurrentX], ch
.CountLoop:
	push	cx
	xcall	InsColumn
	pop		cx
	loop 	.CountLoop
	pop		dx
	mov		[CurrentX], dl
xret

; function  ReadCharAttr : word; external;
xprocedure ReadCharAttr, word
    PreWrite
	mov		ah, 0x02
	mov		bh, [VideoPage]
	mov		cx, [WindMin]
	mov		dl, [CurrentX]
	mov		dh, [CurrentY]
	add		dl, cl
	add		dh, ch
	int		0x10
	mov     ah, 0x08
	int     0x10
	PostWrite
xret

; procedure EOL; external;
xprocedure EOL
    PreWrite
	mov		bh, [VideoPage]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	mov		dh, [CurrentY]
	add		dh, ch
.Check:
    cmp     dl, cl
    jbe     .Done
	mov		ah, 0x02
	int		0x10
	mov     ah, 0x08
	int     0x10
	cmp     al, 0x20
	jne     .Found
	dec     dl
	jmp     .Check
.Found:
.Done:
    sub     dl, cl
	mov		[CurrentX], dl
	PostWrite
xret

; ----- Mouse procedures and functions

%ifdef EnableMouse

; procedure MouseHide; external;
xprocedure MouseHide
    call MouseHidePointer
xret

; procedure MouseHide; external;
xprocedure MouseShow
    call MouseShowPointer
xret

; procedure GotoXY(X, Y : byte); external;
xprocedure MouseGotoXY, 4
    pushf
    cli
	mov		al, [STACKBP + 2]
	mov		ah, [STACKBP + 0]
	dec		al
	dec		ah
	; bounds checking
	mov		bx, [WindMax]
	mov		cx, [WindMin]
	sub		bh, ch
	sub		bl, cl
	inc		bl
	inc		bh
.BadX:
	cmp		al, bl
	jl	 	.BadY
	sub		al, bl
	jmp		.BadX
.BadY:
	cmp		ah, bh
	jl	 	.AllGood
	sub		ah, bh
	jmp		.BadY
.AllGood:
    mov     bl, ah
    xor     ah, ah
    xor     bh, bh
	mov		[MouseLastState + 2], ax
	mov		[MouseLastState + 4], bx

.Done:
	call 	MouseSetPosition
	popf
xret

; function WhereX: byte; external;
xfunction MouseWhereX, byte
    pushf
    cli
    mov     ax, [MouseCheckState + 2]
    mov     bl, [MouseFrozen]
    cmp     bl, TRUE
    je      .Done
    mov     cx, [MouseLastState + 2]
    cmp     ax, cx
    je      .Done
    mov     ax, cx
    mov     [MouseCheckState + 2], ax
.Done:
    popf
xret

; function WhereY: byte; external;
xfunction MouseWhereY, byte
    pushf
    cli
    mov     ax, [MouseCheckState + 4]
    mov     bl, [MouseFrozen]
    cmp     bl, TRUE
    je      .Done
    mov     cx, [MouseLastState + 4]
    cmp     ax, cx
    je      .Done
    mov     ax, cx
    mov     [MouseCheckState + 4], ax
.Done:
    popf
xret

;function MouseMove: boolean; external;
xfunction MouseMove, byte
    pushf
    cli
    mov     al, [MouseFrozen]
    cmp     al, TRUE
    je      .NoChange
    mov     ax, [MouseCheckState + 2]
    mov     cx, [MouseLastState + 2]
    cmp     ax, cx
    jne     .Changed
    mov     bx, [MouseCheckState + 4]
    mov     dx, [MouseLastState + 4]
    cmp     bx, dx
    je      .NoChange
.Changed:
    mov     [MouseCheckState + 2], ax
    mov     [MouseCheckState + 4], bx
    mov     al, TRUE
    jmp     .Done
.NoChange:
    mov     al, FALSE
.Done:
    popf
xret

;function MouseClick : boolean; external;
xfunction MouseClick, byte
    mov  al, FALSE
    mov  ah, [MouseFrozen]
    cmp  ah, FALSE
    je   .Done
    mov  al, TRUE
.Done:
xret

;function MouseDoubleClick : boolean; external;
xfunction MouseDoubleClick, byte
    mov  al, FALSE
    mov  ah, [MouseFrozen]
    cmp  ah, FALSE
    je   .Done
    mov  al, [MouseDoubleFlag]
.Done:
xret

;function ReadMouse : integer; external;
xfunction ReadMouse, word
    pushf
    cli
    mov  ax, [MouseCheckState]
    mov  bx, [MouseLastState]
    cmp  ax, bx
    jne  .StayFrozen
    mov  [MouseFrozen], byte FALSE
    mov  [MouseDoubleFlag], byte FALSE
    jmp  .Done
 .StayFrozen:
    mov  [MouseFrozen], byte TRUE
    mov  cx, [MouseLastState + 2]
    mov  dx, [MouseLastState + 4]
    mov  [MouseCheckState], bx
    mov  [MouseCheckState + 2], cx
    mov  [MouseCheckState + 4], dx
.Done:
    popf
xret

%endif

xprocedure Idle
.IdleProcs:
    mov     ax, [IdleProc]
    cmp     ax, 0
    jne     .DoCall
    mov     ax, [IdleProc + 2]
    cmp     ax, 0
    je      .DoneProcs
.DoCall:
    call    far [IdleProc]
.DoneProcs:
    mov     AL, [IdleCPU]
    cmp     AL, FALSE
    je      .NoCPUHalt
    hlt
.NoCPUHalt:
xret

SkipOverQCrt:
%ifidni __OUTPUT_FORMAT__, bin
	%warning Auto-initialize QuickCrt routines.
	pushcall InitQCrt
%endif