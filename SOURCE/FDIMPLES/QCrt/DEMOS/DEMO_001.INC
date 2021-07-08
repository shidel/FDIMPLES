; Copyright 2015 Jerome Shidel
; All rights reserved.

%include "QCRT.ASM"

mov			bx, HelloWorld
pushcall 	WriteStr, ds, bx
mov			bx, PressAKey
pushcall 	WriteStr, ds, bx

WaitForKey:
	pushcall	KeyPressed
	jz			WaitForKey
pushcall	ReadKey

; Verbose way of setting AX, AX, BX, DX window to dimensions
; and CX to ( height - 1 ) / 2
mov			ax, 1
xor			dx, dx
mov			cx, dx
mov 		bx, [WindMax]
xchg		dl, bh
mov			cl, dl
inc			bx
inc			dx
shr			cl, 1
inc			cl

LoopColors:

	pushy 		ax, bx, dx, cx
	and			ax, 0x07
	pushcall	TextBackground, ax
	poppy		cx, dx, bx, ax
	pushy 		ax, bx, dx, cx, ax
	pushcall 	Window, ax, ax, bx, dx
	pushcall 	ClrScr
	mov			ax, SquareStr
	pushcall	WriteStr, DS, AX
	pop			ax
	pushcall	WriteInt, AX
	pop			cx
	push 		cx
	mov			dx, 500
	shl			cx, 1
	shl			cx, 1
	shl			cx, 1
	shl			cx, 1
	shl			cx, 1
	sub			dx, cx
	push		dx
	pushcall	Sound, dx
	pop			dx
	pushcall	Delay, dx
	poppy		cx, dx, bx, ax
	inc			ax
	dec			bx
	dec			dx
	loop		LoopColors

pushcall	NoSound

; A window that may be shifty
mov	 ax, 4
push ax
push ax
xor	 cx, cx
mov	 ax, [ScreenMax]
xchg cl, ah
sub	ax, 2
sub cx, 2
push ax
push cx
pushcall Window

; We are feeling a bit shifty
mov	ax, [WindMin]
mov	cx, [WindMax]
sub	ch, ah
mov	cl, ch
mov	ch, 0
inc	cl

mov		al, 0x4F
mov		[TextAttr], al

ShiftyLoop:
	push		cx
	%ifidni		TargetCPU, 8086
		mov			ax, 1
		pushcall	ScrollDown, ax
		mov			ax, 2
		pushcall	ScrollRight, ax
		mov			ax, 100
		pushcall	Delay, ax
	%else
		pushcall	ScrollDown, 1
		pushcall	ScrollRight, 2
		pushcall	Delay, 100
	%endif
	pop			cx
	loop		ShiftyLoop

xor cx, cx
mov	bx, [ScreenMax]
xchg cl, bh
inc	cx
inc bx
mov	ax, 0x0001
pushcall Window, ax, ax, bx, cx
mov	al, 0x07
mov	[TextAttr], al
pushcall ClrScr

; Minimal restoring of some stuff like TextMode and Cursor
; then exit to OS with no error code

Terminate 0

PressAKey: 		DB "Press a key to continue.",CRLF,0
SquareStr:		DB "Square #",0