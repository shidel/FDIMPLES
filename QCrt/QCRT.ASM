; Copyright 2017 Jerome Shidel
; Released Under GPL v2.0 License.

; QCrt 9.0.

; For DOS, Nasm and Pascal 16-bit edition.

; This assembly language library uses the pascal calling convention. All calls
; are far calls. Data parameters passed to procedure and functions are pushed
; onto the stack in reverse order and are popped automatically by the function
; or procedure on their return. Simple return values are usually set in AL, AX
; or in the DX:AX pair. DS, SS, SP, BP are preserved. However, the state of all
; other registers are not guaranteed. So, if calling this library from a
; language other than Pascal, such as from more assembly code, you must take
; care of preserving any registers and values you wish to retain yourself!

%idefine QCrt 9.0

%ifidni TargetOS, DOS
	use16
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

%endif

section Section_CODE

; ------------------- Internal Functions; Don't call them directly !!!!
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
	xcall LineFeed
.InsideWindow:
	call	MoveCursorMaybe
ret

; internal Write Character to Screen
WriteRawCrtChar:
	pushy   ax, bx, cx, dx
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

; ------------------------------- QCrt Interface Functions and Procedures

; function InitCrt : boolean; external;
xfunction InitCrt, boolean
	mov 	[CheckBreak], byte FALSE
	mov 	[CheckScroll], byte TRUE
	mov 	[DoubleWide], byte FALSE
	mov 	[UserFont], byte FALSE
	mov		[CheckSnow], byte FALSE
	mov		[CheckEOF], byte FALSE
	mov		[Check101Key], byte FALSE
	mov		[TabWidth], byte 0x08
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

	mov		ax, TRUE
	cmp		ax, TRUE
xret

; procedure DoneCrt;
xprocedure DoneCrt
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
	mov		ah, 6
	mov		al, [STACKBP + 0]
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	int		0x10
xret

; procedure ScrollDown(Rows :byte); external;
xprocedure ScrollDown, 2
	mov		ah, 7
	mov		al, [STACKBP + 0]
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	int		0x10
xret

; procedure ClrScr; external;
xprocedure ClrScr
	mov		ax, 0x0600
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	int		0x10
	mov		ax, 1
	push 	ax
	push	ax
	xcall 	GotoXY
xret

; procedure ClrEol; external;
xprocedure ClrEol
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
xret

; procedure InsLine; external;
xprocedure InsLine
	mov		ax, 0x0701
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	mov		bl, [CurrentY]
	add		ch, bl
	int		0x10
xret

; procedure DelLine; external;
xprocedure DelLine
	mov		ax, 0x0601
	mov		bh, [TextAttr]
	mov		cx, [WindMin]
	mov		dx, [WindMax]
	mov		bl, [CurrentY]
	add		ch, bl
	int		0x10
xret

; procedure InsChar; external;
xprocedure InsChar
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
xret

; procedure DelChar; external;
xprocedure DelChar
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
xret

; procedure InsColumn; external;
xprocedure InsColumn
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
xret

; procedure DelColumn; external;
xprocedure DelColumn
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

SkipOverQCrt:
%ifidni __OUTPUT_FORMAT__, bin
	%warning Auto-initialize QuickCrt routines.
	xcall InitCrt
%endif