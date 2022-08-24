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
; Internal vertical window scroller. The screen write macros use this to scroll
; the screen. It would be pointless to include the DOSCrt macros without using
; the write macros. So, this is always present when DOSCRT is used.
; MACRO: ScrollWindowUpDown_INTERNAL 0
; ON CALL:
;	ah = BIOS or DirectVideo function (6=Up, 7=down)
;	al= 0 is entire window, 1 from current line only.
; REGS: bx, cx, dx. Always destroys ax.
; -----------------------------------------------------------------------------
%imacro ScrollWindowUpDown_INTERNAL 0

SECTION_PROC

ScrollWindowUpDown_PROC:

ScrollWindowUpDown_PROC_BIOS:
	%ifdef Support_Direct_Video
		pushm			es, di, si
	%endif
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
	mov			bh, [Video_Attr]
	mov			dx, [Video_WindMax]
	PreWriteMouse		cx, dx

	%ifdef BIOS_AND_DIRECT_VIDEO
		test 	[Video_Options], byte vcbDirect
		jz	%%ScrollWindow_PROC_BIOS
		jmp	%%ScrollWindow_PROC_DIRECT
	%endif

	%ifdef Support_BIOS_Video
%%ScrollWindow_PROC_BIOS:
		%ifdef DOS_BUG_FIXES
			; See -- https://fd.lod.bz/rbil/interrup/video/1006.html#130
			pushm		ds, bp
		%endif
		mov			al, 0x01	; Scroll 1 line
		int			0x10
		%ifdef DOS_BUG_FIXES
			popm		ds, bp
		%endif
	%endif

	%ifdef BIOS_AND_DIRECT_VIDEO
		jmp			%%PerformScrollDone
	%endif

	%ifdef Support_Direct_Video
%%ScrollWindow_PROC_DIRECT:
		cld
		mov			bx, dx
		add			bx, 0x0101
		sub			bx, cx
		mov			dl, cl
		push			ax
		cmp			ah, 0x07
		je			%%DirectDown
		Calc_Video_Pointer	cx
		mov			si, di
		add			si, ax
		jmp			%%DirectScroll
	%%DirectDown:
		Calc_Video_Pointer	dx
		mov			si, di
		sub			si, ax

	%%DirectScroll:
		mov			dx, ax
		pop			ax	; still need direction
		xor			ch, ch
		mov			cl, bh
		xor			bh, bh
	%%DirectRowLoop:
		dec			cx
		jz			%%DirectFill
		pushm			cx, si, di, ax
		mov			cx, bx
	%%DirectLineLoop:
		es lodsw
		stosw
		loop			%%DirectLineLoop
		popm			cx, si, di, ax
		cmp			ah, 0x07
		je			%%DirectDec
		add			si, dx
		add			di, dx
		jmp			%%DirectRowLoop
	%%DirectDec:
		sub			si, dx
		sub			di, dx
		jmp			%%DirectRowLoop

	%%DirectFill:
		mov			cx, bx
		mov			ah, [Video_Attr]
		mov			al, 0x20
		rep stosw
	%endif

%%PerformScrollDone:
	PostWriteMouse
	RegsRestore		bx, cx, dx
	%ifdef Support_Direct_Video
		popm			es, di, si
	%endif
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
; Internal horizontal window scroller.
; MACRO: ScrollWindowLeftRight_INTERNAL 0
; ON CALL:
;	ah = BIOS or DirectVideo function (6=Up, 7=down)
;	al= 0 is entire window, 1 from current line only.
; REGS: bx, cx, dx. Always destroys ax.
; -----------------------------------------------------------------------------
%imacro ScrollWindowLeftRight_INTERNAL 0

SECTION_PROC

ScrollWindowLeftRight_PROC:

ScrollWindowLeftRight_PROC_BIOS:
	%ifdef Support_Direct_Video
		pushm			es, di, si
	%endif
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
	mov			bh, [Video_Attr]
	mov			dx, [Video_WindMax]
	PreWriteMouse		cx, dx

	%ifdef BIOS_AND_DIRECT_VIDEO
		test 	[Video_Options], byte vcbDirect
		jz	%%ScrollWindow_PROC_BIOS
		jmp	%%ScrollWindow_PROC_DIRECT
	%endif

	%ifdef Support_BIOS_Video
%%ScrollWindow_PROC_BIOS:
		%ifdef DOS_BUG_FIXES
			; See -- https://fd.lod.bz/rbil/interrup/video/1006.html#130
			pushm		ds, bp
		%endif
		mov			al, 0x01	; Scroll 1 line
		int			0x10
		%ifdef DOS_BUG_FIXES
			popm		ds, bp
		%endif
	%endif

	%ifdef BIOS_AND_DIRECT_VIDEO
		jmp			%%PerformScrollDone
	%endif

	%ifdef Support_Direct_Video
%%ScrollWindow_PROC_DIRECT:
		cld
		mov			bx, dx
		add			bx, 0x0101
		sub			bx, cx
		mov			dl, cl
		push			ax
		cmp			ah, 0x07
		je			%%DirectDown
		Calc_Video_Pointer	cx
		mov			si, di
		add			si, ax
		jmp			%%DirectScroll
	%%DirectDown:
		Calc_Video_Pointer	dx
		mov			si, di
		sub			si, ax

	%%DirectScroll:
		mov			dx, ax
		pop			ax	; still need direction
		xor			ch, ch
		mov			cl, bh
		xor			bh, bh
	%%DirectRowLoop:
		dec			cx
		jz			%%DirectFill
		pushm			cx, si, di, ax
		mov			cx, bx
	%%DirectLineLoop:
		es lodsw
		stosw
		loop			%%DirectLineLoop
		popm			cx, si, di, ax
		cmp			ah, 0x07
		je			%%DirectDec
		add			si, dx
		add			di, dx
		jmp			%%DirectRowLoop
	%%DirectDec:
		sub			si, dx
		sub			di, dx
		jmp			%%DirectRowLoop

	%%DirectFill:
		mov			cx, bx
		mov			ah, [Video_Attr]
		mov			al, 0x20
		rep stosw
	%endif

%%PerformScrollDone:
	PostWriteMouse
	RegsRestore		bx, cx, dx
	%ifdef Support_Direct_Video
		popm			es, di, si
	%endif
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

SECTION_PROC

DelLine_PROC:
	RegsPreserve		ax
	mov			ax, 0x0601
	call			ScrollWindowUpDown_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro DelLine 0

	PROC_REQUIRE 		ScrollWindowUpDown
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

SECTION_PROC

InsLine_PROC:
	RegsPreserve		ax
	mov			ax, 0x0701
	call			ScrollWindowUpDown_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro InsLine 0

	PROC_REQUIRE 		ScrollWindowUpDown
	PROC_REQUIRE		InsLine

	call 			InsLine_PROC

%endmacro
; -----------------------------------------------------------------------------
; Delete the current column and add fresh one on the right side of the window
; MACRO: DelColumn 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro DelColumn_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowLeftRight

SECTION_PROC

DelColumn_PROC:
	RegsPreserve		ax
	mov			ax, 0x0601
	call			ScrollWindowLeftRight_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro DelColumn 0

	PROC_REQUIRE 		ScrollWindowLeftRight
	PROC_REQUIRE 		DelColumn

	call 			DelColumn_PROC

%endmacro
; -----------------------------------------------------------------------------
; Insert a blank column at the current location
; MACRO: InsColumn 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro InsColumn_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowLeftRight

SECTION_PROC

InsColumn_PROC:
	RegsPreserve		ax
	mov			ax, 0x0701
	call			ScrollWindowLeftRight_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro InsColumn 0

	PROC_REQUIRE 		ScrollWindowLeftRight
	PROC_REQUIRE		InsColumn

	call 			InsColumn_PROC

%endmacro
; -----------------------------------------------------------------------------
; Scrolls the window up
; MACRO: ScrollWindowUp 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro ScrollWindowUp_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowUpDown

SECTION_PROC

ScrollWindowUp_PROC:
	RegsPreserve		ax
	mov			ax, 0x0600
	call			ScrollWindowUpDown_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro ScrollWindowUp 0

	PROC_REQUIRE 		ScrollWindowUpDown
	PROC_REQUIRE 		ScrollWindowUp

	call 			ScrollWindowUp_PROC

%endmacro
; -----------------------------------------------------------------------------
; Scrolls the window down
; MACRO: ScrollWindowDown 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro ScrollWindowDown_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowUpDown

SECTION_PROC

ScrollWindowDown_PROC:
	RegsPreserve		ax
	mov			ax, 0x0700
	call			ScrollWindowUpDown_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro ScrollWindowDown 0

	PROC_REQUIRE 		ScrollWindowUpDown
	PROC_REQUIRE 		ScrollWindowDown

	call 			ScrollWindowDown_PROC

%endmacro
; -----------------------------------------------------------------------------
; Scrolls the window left
; MACRO: ScrollWindowLeft 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro ScrollWindowLeft_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowLeftRight

SECTION_PROC

ScrollWindowLeft_PROC:
	RegsPreserve		ax
	mov			ax, 0x0600
	call			ScrollWindowLeftRight_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro ScrollWindowLeft 0

	PROC_REQUIRE 		ScrollWindowLeftRight
	PROC_REQUIRE 		ScrollWindowLeft

	call 			ScrollWindowLeft_PROC

%endmacro
; -----------------------------------------------------------------------------
; Scrolls the window right
; MACRO: ScrollWindowRight 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro ScrollWindowRight_INTERNAL 0

	PROC_REQUIRE 		ScrollWindowLeftRight

SECTION_PROC

ScrollWindowRight_PROC:
	RegsPreserve		ax
	mov			ax, 0x0700
	call			ScrollWindowLeftRight_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro ScrollWindowRight 0

	PROC_REQUIRE 		ScrollWindowLeftRight
	PROC_REQUIRE 		ScrollWindowRight

	call 			ScrollWindowRight_PROC

%endmacro
; -----------------------------------------------------------------------------
; Scrolls the window some direction
; MACRO: ScrollWindow 1
; INPUT: %1 = up, down, left or right
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro ScrollWindow 1

	%ifidni %1, Down
		PROC_REQUIRE 		ScrollWindowUpDown
		PROC_REQUIRE 		ScrollWindowDown
		call 			ScrollWindowDown_PROC
	%elifidni %1, Up
		PROC_REQUIRE 		ScrollWindowUpDown
		PROC_REQUIRE 		ScrollWindowUp
		call 			ScrollWindowUp_PROC
	%elifidni %1, Right
		PROC_REQUIRE 		ScrollWindowLeftRight
		PROC_REQUIRE 		ScrollWindowRight
		call 			ScrollWindowRight_PROC
	%elifidni %1, Left
		PROC_REQUIRE 		ScrollWindowLeftRight
		PROC_REQUIRE 		ScrollWindowLeft
		call 			ScrollWindowLeft_PROC
	%else
		%error 'ScrollWindow expects Up, Down, Left or Right'
	%endif

%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE ScrollWindowUpDown
	PROC_PROVIDE ScrollWindowLeftRight
	PROC_PROVIDE DelLine
	PROC_PROVIDE InsLine
	PROC_PROVIDE DelColumn
	PROC_PROVIDE InsColumn
	PROC_PROVIDE ScrollWindowUp
	PROC_PROVIDE ScrollWindowDown
	PROC_PROVIDE ScrollWindowLeft
	PROC_PROVIDE ScrollWindowRight
%endif
