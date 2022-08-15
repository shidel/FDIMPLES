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

%ifndef INSDEL_INC_DEFINED
%define INSDEL_INC_DEFINED
; -----------------------------------------------------------------------------
; Internal Window scroller, always present with DOSCRT.
; MACRO: ScrollWindowProcs 0
; ON CALL:
;	ah = BIOS function (6=Up, 7=down)
;	al= 0 is entire window, 1 from current line.
; REGS: bx, cx, dx. Always destroys ax.
; -----------------------------------------------------------------------------
%imacro ScrollWindowUpDown_INTERNAL 0

[section .procs]

ScrollWindowUpDown_PROC:
	RegsPreserve		bx, cx, dx
	%ifdef DOS_BUG_FIXES
		; See -- https://fd.lod.bz/rbil/interrup/video/1003.html#122
	%endif
	push			ax
	cmp			al, 0x01
	jne			%%EntireWindow
	mov			ah, 0x03		; Get Cursor Pos & Size
	mov			bh, [Video_Page]
	int			0x10
	mov			ch, dh
	mov			cl, [Video_WindMinX]
	jmp			%%PerformScroll
%%EntireWindow:
	mov			cx, [Video_WindMin]
%%PerformScroll:
	pop			ax
	mov			al, 0x01		; Scroll 1 line
	mov			bh, [Video_Attr]
	mov			dx, [Video_WindMax]
	PreWriteMouse		cx, dx
	%ifdef DOS_BUG_FIXES
		; See -- https://fd.lod.bz/rbil/interrup/video/1006.html#130
		pushm		ds, bp
	%endif
	int			0x10
	%ifdef DOS_BUG_FIXES
		popm		ds, bp
	%endif
	PostWriteMouse
	RegsRestore		bx, cx, dx
	ret

__?SECT?__

%endmacro

; -----------------------------------------------------------------------------
; Delete the current line and add fresh one at the bottom of the window
; MACRO: DelLine 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro DelLine_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowUpDown

[section .procs]

DelLine_PROC:
	RegsPreserve		ax
	mov			ax, 0x0601
	call			ScrollWindowUpDown_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro DelLine 0

	PROC_REQUIRE 		DelLine

	call 			DelLine_PROC

%endmacro
; -----------------------------------------------------------------------------
; Insert a blank line at the current location
; MACRO: InsLine 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro InsLine_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowUpDown

[section .procs]

InsLine_PROC:
	RegsPreserve		ax
	mov			ax, 0x0701
	call			ScrollWindowUpDown_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro InsLine 0

	PROC_REQUIRE		InsLine

	call 			InsLine_PROC

%endmacro
; -----------------------------------------------------------------------------
; Scrolls the window up
; MACRO: WindowScrollUp 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro WindowScrollUp_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowUpDown

[section .procs]

WindowScrollUp_PROC:
	RegsPreserve		ax
	mov			ax, 0x0600
	call			ScrollWindowUpDown_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro WindowScrollUp 0

	PROC_REQUIRE 		WindowScrollUp

	call 			WindowScrollUp_PROC

%endmacro
; -----------------------------------------------------------------------------
; Scrolls the window down
; MACRO: WindowScrollDown 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro WindowScrollDown_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowUpDown

[section .procs]

WindowScrollDown_PROC:
	RegsPreserve		ax
	mov			ax, 0x0700
	call			ScrollWindowUpDown_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro WindowScrollDown 0

	PROC_REQUIRE 		WindowScrollDown

	call 			WindowScrollDown_PROC

%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE ScrollWindowUpDown
	PROC_PROVIDE DelLine
	PROC_PROVIDE InsLine
	PROC_PROVIDE ScrollWindowUp
	PROC_PROVIDE ScrollWindowDown
%endif
