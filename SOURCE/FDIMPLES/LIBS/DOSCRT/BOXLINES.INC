; BSD 3-Clause License
; Copyright (c) 2022, Jerome Shidel
; All rights reserved.

; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:

; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.

; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.

; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.

; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

; NASM 2.15.05, or later

%ifndef BOXLINES_INC_DEFINED
%define BOXLINES_INC_DEFINED
; -----------------------------------------------------------------------------

%macro BoxLineData_INTERNAL 0

SECTION_DATA

BoxLineData_DATA:

.Horizontal:
	db 0xc4	; single horz
		db 0xb3 ; single vert
		db 0xc3, 0xc5, 0xb4 ; connect vert left, center right
		db 0xba ; double vert
		db 0xc7, 0xd7, 0xb6 ; connect vert left, center right
	db 0xcd ; double horz
		db 0xb3 ; single vert
		db 0xc6, 0xd8, 0xb5 ; connect vert left, center right
		db 0xba ; double vert
		db 0xcc, 0xce, 0xb9 ; connect vert left, center right
.Vertical:
	db 0xb3 ; single vert
		db 0xc4 ; horz single
		db 0xc2, 0xc5, 0xc1 ; connect horz single, top, center, bottom
		db 0xcd ; horz double
		db 0xd1, 0xd8, 0xcf ; connect horz double top, center, bottom
	db 0xba ; double vert
		db 0xc4 ; horz single
		db 0xd2, 0xd7, 0xd0 ; connect horz single, top, center, bottom
		db 0xcd ; horz double
		db 0xcb, 0xce, 0xca ; connect horz double top, center, bottom

__?SECT?__

%endmacro

%macro BoxFrameData_INTERNAL 0

SECTION_DATA

BoxFrameData_DATA:

.HSVS:
	db 0xda, 0xc4, 0xbf, 0xb3, 0xc0, 0xc4, 0xd9
.HSVD:
	db 0xd6, 0xc4, 0xb7, 0xba, 0xd3, 0xc4, 0xbd
.HDVS:
	db 0xd5, 0xcd, 0xb8, 0xb3, 0xd4, 0xcd, 0xbe
.HDVD:
	db 0xc9, 0xcd, 0xbb, 0xba, 0xc8, 0xcd, 0xbc

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
; Display a horizontal line
; MACRO:  DrawLine 3
; INPUT:  %1 = XY, %2 = Count, %3 = Options (Prefers AX, DX, CX)
; OUTPUT: none
; REGS:	  ax, bx, cx, dx
; -----------------------------------------------------------------------------
%macro DrawLine_INTERNAL 0


SECTION_PROC

DrawLine_PROC:
	mov		ch, cl
	mov		cl, dl
	pushm		si, di
	xor		di, di
	RegsPreserve	bx
	pushm		ax, cx
	mov		bh, [Video_Page]
	mov		ah, 0x03
	int		0x10			; get cursor position
	popm		ax, cx
	push		dx			; save cursor position

	mov		dx, ax			; requested start xy position
	add		dx, [Video_WindMin]	; offset to screen xy position
	mov		bl, [Video_Attr]

	mov		si, BoxLineData_DATA.Horizontal
	test		ch, lnVertical
	jz		%%NotVerticalChars
	mov		si, BoxLineData_DATA.Vertical
%%NotVerticalChars:
	test		ch, lnDouble		; either double horz/vert
	jz		%%NotDoubleLine
	add		si, 9
%%NotDoubleLine:

	mov		bh, [Video_Page]

	%ifdef Support_Mouse

		push	cx
		inc	cl
		test	ch, lnVertical
		jnz	%%NotIsVertical
		mov	ch, dh
		add	cl, dl
		jmp	%%MaybeHideMouse
	%%NotIsVertical:
		mov	ch, cl
		mov	cl, dl
		add	ch, dh
	%%MaybeHideMouse:
		PreWriteMouse	dx, cx
		pop	cx
	%endif

%%DoDrawing:
	test		cl, cl
	jz		%%DoneDrawing
	dec		cl

	mov		ah, 0x02
	int		0x10			; move cursor to xy position
	mov		al, [si]
	test		ch, lnNoConnect
	jnz		%%NoConnect

	push		bx			; save page/textattr
	push		ax
	mov		ah, 0x08
	int		0x10			; fetch char/attr at xy position
	mov		bl, al
	pop		ax
	mov		ah, bl			; ah is now char at position
	xor		bx, bx
	cmp		ah, [si + 1]
	jne		%%SecondTest
	mov		bx, 2
	jmp		%%ChangeChar
%%SecondTest:
	cmp		ah, [si + 5]
	jne		%%NoChangeChar
	mov		bx, 6
%%ChangeChar:
	test		di, di			; is it the first char
	jz		%%ChangeCharDone
	inc		bx
	test		cl, cl			; is it the last char
	jnz		%%ChangeCharDone
	inc		bx
%%ChangeCharDone:
	mov		al, [si+bx]
%%NoChangeChar:
	pop		bx			; restore page/textattr

%%NoConnect:
	inc		di
	push		cx
	mov		ah, 0x09
	mov		cx, 0x0001
	int		0x10			; pu line/box char on screen
	pop		cx
	cmp		dh, [Video_WindMaxY]
	ja		%%OutOfBounds
	cmp		dx, [Video_WindMaxX]
	ja		%%OutOfBounds
	test		ch, lnVertical
	jz		%%NotVerticalMove
	inc		dh
	jmp		%%DoDrawing
%%NotVerticalMove:
	inc		dl
	jmp		%%DoDrawing

%%OutOfBounds:
%%DoneDrawing:

	pop		dx
	mov		ah, 0x02
	int		0x10			; restore cursor position

	%ifdef Support_Mouse
		PostWriteMouse
	%endif
	RegsRestore	bx
	popm		si, di
	ret


__?SECT?__

%endmacro

%imacro DrawLine 3

	; PROC_REQUIRE		WriteHexByte
	; PROC_REQUIRE		WriteHexWord

	PROC_REQUIRE 		PutChar
	PROC_REQUIRE		BoxLineData
	PROC_REQUIRE		DrawLine

	RegsPreserve		ax, cx, dx
	movndef			ax, %1, dx, %2, cx, %3
	call 			DrawLine_PROC
	RegsRestore		ax, cx, dx


%endmacro
; -----------------------------------------------------------------------------
; Display a Box
; MACRO:  DrawBox 3
; INPUT:  %1 = MinXY, %2 = MaxXY, %3 = Options (Prefers AX, DX, CX)
; OUTPUT: none
; REGS:	  ax, bx, cx, dx
; -----------------------------------------------------------------------------
%macro DrawBox_INTERNAL 0


SECTION_PROC

DrawBox_PROC:
	pushm		si, di
	RegsPreserve	bx

	mov		si, BoxFrameData_DATA.HSVS
	test		cx, lnDouble
	jz		%%FrameSet
	mov		si, BoxFrameData_DATA.HDVD
	cmp		cx, lnDoubleVert
	ja		%%FrameSet
	mov		si, BoxFrameData_DATA.HDVS
	jb		%%FrameSet
	mov		si, BoxFrameData_DATA.HSVD
%%FrameSet:

	add		dx, 0x0101
	sub		dx, ax
	mov		cx, dx
	add		ax, [Video_WindMin]
	mov		dx, ax			; dx = real xy, cx = wide/high

	%ifdef Support_Mouse
		push		cx
		add		cx, dx
		PreWriteMouse 	dx, cx
		pop		cx
	%endif

	pushm		dx, cx
	mov		bh, [Video_Page]
	mov		ah, 0x03
	int		0x10			; get cursor position
	mov		ax, dx
	popm		dx, cx
	push		ax			; save cursor position for later

	mov		ah, [Video_Attr]
	cld
%%DrawTop:
	call		%%DrawHorz
	lodsb
%%DrawSides:
	dec		ch
	cmp		ch, 1
	jna		%%DrawBottom
	inc		dh
	push		dx
	call		%%DrawChar
	add		dl, cl
	dec		dl
	call		%%DrawChar
	pop		dx

	jmp		%%DrawSides
%%DrawBottom:
	dec		ch
	jnz		%%DrawDone
	inc		dh
	call		%%DrawHorz
	jmp		%%DrawDone

%%DrawHorz:
	pushm		cx, dx
	lodsb
	call		%%DrawChar
	inc		dl
	dec		cl
	lodsb
%%DrawHorzLoop:
	cmp		cl, 1
	jna		%%DrawHorzEnd
	call		%%DrawChar
	inc		dl
	dec		cl
	jmp		%%DrawHorzLoop
%%DrawHorzEnd:
	lodsb
	cmp		cl, 1
	jne		%%DrawHorzLoopDone
	call		%%DrawChar
%%DrawHorzLoopDone:
	popm		cx, dx
	ret
%%DrawChar:
	cmp		dl, [Video_WindMaxX]
	ja		%%OutOfBounds
	cmp		dh, [Video_WindMaxY]
	ja		%%OutOfBounds
	push		ax
	call		PutChar_PROC
	pop		ax
%%OutOfBounds:
	ret
%%DrawDone:

	pop		dx
	mov		ah, 0x02
	int		0x10			; restore cursor position
	%ifdef Support_Mouse
		PostWriteMouse
	%endif
	RegsRestore	bx
	popm		si, di
	ret

__?SECT?__

%endmacro

%imacro DrawBox 3

	; PROC_REQUIRE		WriteHexByte
	; PROC_REQUIRE		WriteHexWord

	PROC_REQUIRE 		PutChar
	PROC_REQUIRE		BoxFrameData
	PROC_REQUIRE		DrawBox

	RegsPreserve		ax, cx, dx
	movndef			ax, %1, dx, %2, cx, %3
	call 			DrawBox_PROC
	RegsRestore		ax, cx, dx


%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE		BoxLineData
	PROC_PROVIDE		BoxFrameData
	PROC_PROVIDE		DrawLine
	PROC_PROVIDE		DrawBox

%endif
