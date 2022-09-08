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

%ifndef WINDOW_INC_DEFINED
%define WINDOW_INC_DEFINED
; -----------------------------------------------------------------------------
; Adjust the window to its maximum size. Does not move cursor.
; MACRO: WindowMax 0
; REGS:  ax
; -----------------------------------------------------------------------------
%macro WindowMax_INTERNAL 0

SECTION_PROC

WindowMax_PROC:
	RegsPreserve		ax
	mov			ax, [Video_ScreenMax]
	mov			[Video_WindMax], ax
	xor			ax, ax
	mov			[Video_WindMin], ax
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro WindowMax 0

	PROC_REQUIRE 		WindowMax

	call 			WindowMax_PROC

%endmacro
; -----------------------------------------------------------------------------
; Set the window size. Moves cursor to top/left in window.
; MACRO: Window 2 or 4
; INPUT:
;	%1 = Window MinXY (prefers ax)
;	%2 = Window MaxXY (prefers dx)
; REGS:  ax, cx, dx
; -----------------------------------------------------------------------------
%macro Window_INTERNAL 0

SECTION_PROC

Window_PROC:
	%ifdef DOSCRT_Range_Check
		RegsPreserve	cx
		mov		cx, [Video_ScreenMax]
	%%TryAgain:
		cmp		ah, dh
		jbe		%%NoSwapY
		xchg		ah, dh
	%%NoSwapY:
		cmp		al, dl
		jbe		%%NoSwapX
		xchg		al, dl
	%%NoSwapX:
	%%OkayY1:
		cmp		dl, cl
		jbe		%%OkayX2
		mov		dl, cl
		jmp		%%TryAgain
	%%OkayX2:
		cmp		dh, dh
		jbe		%%OkayY2
		mov		dh, ch
		jmp		%%TryAgain
	%%OkayY2:
		RegsRestore	cx
	%endif

	RegsPreserve 		bx
	mov			[Video_WindMin], ax
	mov			[Video_WindMax], dx
	mov			dx, ax
	mov			ah, 0x02
	mov			bh, [Video_Page]
	int			0x10
	RegsRestore 		bx

	ret

__?SECT?__

%endmacro

%imacro Window 1-2

	PROC_REQUIRE Window

	RegsPreserve 		ax, dx
	%if %0 = 1
		%ifidni %1, maximum

		%elifidni %1, max

		%else
			%error Invalid window dimension or option parameter
		%endif
		xor		ax, ax
		mov		dx, [Video_ScreenMax]
	%else
		movndef	     		ax, %1, dx, %2
	%endif
	call			Window_PROC
	RegsRestore  		ax, dx

%endmacro
; -----------------------------------------------------------------------------
; Move cursor to new position within window
; MACRO: GotoXY 1-2
; INPUT: %1 - XY (prefers ax)
;        or
; 	 %1 - X (prefers al), %2 - Y (prefers ah)
; REGS:  ax, bx, dx
; -----------------------------------------------------------------------------
%macro GotoXY_INTERNAL 0

SECTION_PROC

GotoXY_PROC:
	RegsPreserve		ax, bx, dx
	mov			dx, [Video_WindMin]
	%ifdef DOSCRT_Range_Check
		mov		bx, [Video_WindMax]
		sub		bx, dx
		cmp		al, bl
		jbe		%%OkayX
		mov		al, bl
	%%OkayX:
		cmp		ah, bh
		jbe		%%OkayY
		mov		ah, bh
	%%OkayY:
	%endif
	add			dx, ax
	mov			bh, [Video_Page]
	mov			ah, 0x02
	int			0x10
	RegsRestore		ax, bx, dx
	ret

__?SECT?__

%endmacro

%imacro GotoXY 1-2

	PROC_REQUIRE GotoXY

	%ifnidni %1, ax
		RegsPreserve	ax
	%endif

	%if %0 = 1
		movndef			ax, %1
	%else
		movndef			al, %1, ah, %2
	%endif

	call 			GotoXY_PROC

	%ifnidni %1, ax
		RegsRestore	ax
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Return the cursor position within window
; MACRO: WhereXY 1
; OUTPUT: %1 - XY (prefers dx)
; REGS:  ax, bx, cx, dx
; -----------------------------------------------------------------------------
%macro WhereXY_INTERNAL 0

SECTION_PROC

WhereXY_PROC:
	RegsPreserve		ax, bx, cx
	mov			bh, [Video_Page]
	mov			ah, 0x03		; Get cursor shape/pos
	int			0x10
	mov			ax, [Video_WindMin]
	; check if somehow cursor is outside of window
	%ifdef DOSCRT_Range_Check
		cmp		dl, al
		jnb		%%NotLessX
		mov		dl, al
	%%NotLessX:
		cmp		dh, ah
		jnb		%%NotLessY
		mov		dh, ah
	%%NotLessY:
		mov		cx, [Video_WindMax]
		cmp		dl, cl
		jna		%%NotMoreX
		mov		dl, cl
	%%NotMoreX:
		cmp		dh, ch
		jna		%%NotMoreY
		mov		dh, ch
	%%NotMoreY:
	%endif
	sub			dx, ax
	RegsRestore		ax, bx, cx
	ret

__?SECT?__

%endmacro

%imacro WhereXY 1

	PROC_REQUIRE WhereXY

	%ifnidni %1, dx
		RegsPreserve	dx
	%endif
	call 			WhereXY_PROC
	movndef			%1, dx
	%ifnidni %1, dx
		RegsRestore	dx
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Return the cursor column position within window
; MACRO: WhereX 1
; OUTPUT: %1 - X (prefers dl)
; REGS:  ax, bx, cx, dl
; -----------------------------------------------------------------------------
%macro WhereX_INTERNAL 0

SECTION_PROC

WhereX_PROC:
	RegsPreserve		ax
	push			dx
	call			WhereXY_PROC
	mov			al, dl
	pop			dx
	mov			dl, al
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro WhereX 1

	PROC_REQUIRE WhereX
	PROC_REQUIRE WhereXY

	%ifnidni %1, dx
		RegsPreserve	dx
	%endif
	call 			WhereX_PROC
	movndef			%1, dl
	%ifnidni %1, dx
		RegsRestore	dx
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Return the cursor row position within window
; MACRO: WhereY 1
; OUTPUT: %1 - Y (prefers dh)
; REGS:  ax, bx, cx, dh
; -----------------------------------------------------------------------------
%macro WhereY_INTERNAL 0

SECTION_PROC

WhereY_PROC:
	RegsPreserve		ax
	push			dx
	call			WhereXY_PROC
	mov			al, dh
	pop			dx
	mov			dh, al
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro WhereY 1

	PROC_REQUIRE WhereY
	PROC_REQUIRE WhereXY

	%ifnidni %1, dx
		RegsPreserve	dx
	%endif
	call 			WhereY_PROC
	movndef			%1, dh
	%ifnidni %1, dx
		RegsRestore	dx
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Move the cursor relative to it's current XY position
; MACRO: RelativeXY 2
; INPUT: %1 - X (prefers cx)
; INPUT: %2 - Y (prefers dx)
; REGS:  ax, bx, cx, dx
; -----------------------------------------------------------------------------
%macro RelativeXY_INTERNAL 0

SECTION_PROC

RelativeY_PROC:
	xor			cx, cx
	jmp			RelativeXY_PROC
RelativeX_PROC:
	xor			dx, dx
RelativeXY_PROC:
	RegsPreserve		ax, bx

	pushm			cx, dx
	call			WhereXY_PROC
	mov			al, dl
	mov			bl, dh
	xor			ah, ah
	mov			bh, ah
	popm			cx, dx
	add			ax, cx
	add			bx, dx
	mov			dl, al
	mov			dh, bl
	call			GotoXY_PROC

	RegsRestore		ax, bx
	ret

__?SECT?__

%endmacro

%imacro RelativeXY 2

	PROC_REQUIRE WhereXY
	PROC_REQUIRE GotoXY
	PROC_REQUIRE RelativeXY

	%ifnidni %1, cx
		RegsPreserve	cx
	%endif
	%ifnidni %2, dx
		RegsPreserve	dx
	%endif
	movndef			cx, %1, dx, %2
	call 			RelativeXY_PROC
	%ifnidni %2, dx
		RegsRestore	dx
	%endif
	%ifnidni %1, cx
		RegsRestore	cx
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Move the cursor relative to it's current X position
; MACRO: RelativeX 1
; INPUT: %1 - X (prefers cx)
; REGS:  ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro RelativeX 1

	PROC_REQUIRE WhereXY
	PROC_REQUIRE GotoXY
	PROC_REQUIRE RelativeXY

	RegsPreserve		dx
	%ifnidni %1, cx
		RegsPreserve	cx
	%endif
	movndef			cx, %1
	call 			RelativeX_PROC
	%ifnidni %1, cx
		RegsRestore	cx
	%endif
	RegsRestore		dx

%endmacro
; -----------------------------------------------------------------------------
; Move the cursor relative to it's current XY position
; MACRO: RelativeY 1
; INPUT: %1 - Y (prefers dx)
; REGS:  ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro RelativeY 1

	PROC_REQUIRE WhereXY
	PROC_REQUIRE GotoXY
	PROC_REQUIRE RelativeXY

	RegsPreserve		cx
	%ifnidni %1, dx
		RegsPreserve	dx
	%endif
	movndef			dx, %1
	call 			RelativeY_PROC
	%ifnidni %1, dx
		RegsRestore	dx
	%endif
	RegsRestore		cx

%endmacro
; -----------------------------------------------------------------------------
; Return current window minimum XY
; MACRO:  WindMin 1
; OUTPUT: %1 - XY (needs 16-bit register)
; REGS:  none
; -----------------------------------------------------------------------------
%imacro WindMin 1
	mov	%1, [Video_WindMin]
%endmacro
; -----------------------------------------------------------------------------
; Return current window minimum X
; MACRO:  WindMinX 1
; OUTPUT: %1 - X (needs 8-bit register)
; REGS:  none
; -----------------------------------------------------------------------------
%imacro WindMinX 1
	mov	%1, [Video_WindMinX]
%endmacro
; -----------------------------------------------------------------------------
; Return current window minimum Y
; MACRO:  WindMinY 1
; OUTPUT: %1 - Y (needs 8-bit register)
; REGS:  none
; -----------------------------------------------------------------------------
%imacro WindMinY 1
	mov	%1, [Video_WindMinY]
%endmacro
; -----------------------------------------------------------------------------
; Return current window maximum XY
; MACRO:  WindMax 1
; OUTPUT: %1 - XY (needs 16-bit register)
; REGS:  none
; -----------------------------------------------------------------------------
%imacro WindMax 1
	mov	%1, [Video_WindMax]
%endmacro
; -----------------------------------------------------------------------------
; Return current window maximum X
; MACRO:  WindMaxX 1
; OUTPUT: %1 - X (needs 8-bit register)
; REGS:  none
; -----------------------------------------------------------------------------
%imacro WindMaxX 1
	mov	%1, [Video_WindMaxX]
%endmacro
; -----------------------------------------------------------------------------
; Return current window maximum Y
; MACRO:  WindMaxY 1
; OUTPUT: %1 - Y (needs 8-bit register)
; REGS:  none
; -----------------------------------------------------------------------------
%imacro WindMaxY 1
	mov	%1, [Video_WindMaxY]
%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE WindowMax
	PROC_PROVIDE Window
	PROC_PROVIDE GotoXY
	PROC_PROVIDE WhereXY
	PROC_PROVIDE WhereX
	PROC_PROVIDE WhereY
	PROC_PROVIDE RelativeXY
%endif
