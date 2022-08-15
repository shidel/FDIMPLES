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

%ifndef WRITE_INC_DEFINED
%define WRITE_INC_DEFINED
; -----------------------------------------------------------------------------
%imacro WriteChar_INTERNAL 0

[section .procs]

WriteChar_PROC:
	RegsPreserve		bx, cx, dx
	; push ax,  see - https://fd.lod.bz/rbil/interrup/video/1003.html
	push			ax			; Some BIOS clear AX
	mov			ah, 0x03		; Get Cursor Pos & Size
	mov			bx,[Video_PageAttr]
	int			0x10
	pop			ax
	test			[Video_Options], byte vcbControls
	jnz			%%DisplayChar
	cmp			al, 0x10
	jae			%%DisplayChar
	cmp			al, 0x0d
	je			%%ProcessCR
	cmp			al, 0x0a
	je			%%ProcessLF
	cmp			al, 0x09
	je			%%ProcessHT
	cmp			al, 0x08
	je			%%ProcessBS
	; cmp			al, 0x07 		; bell
	; cmp			al, 0x0b 		; vtab
	; cmp			al, 0x0c 		; form-feed
	jmp			%%DisplayChar
%%ProcessCR:			; Carriage Return
	mov			dl, [Video_WindMinX]
	jmp			%%PostDisplayChar
%%ProcessLF:			; Line Feed
	inc			dh
	jmp			%%PostDisplayChar
%%ProcessHT:			; Horizontal Tab
	push			dx
	mov			ax, dx
	sub			ax, [Video_WindMin]
	xor			ah, ah
	mov			cl, [Video_HTab]
	%ifdef DOSCRT_Range_Check
		test		cl, cl
		jnz		%%GoodTabValue
		mov		cl, 0x01
		%%GoodTabValue:
	%endif
	test			al, al
	jz			%%StartPosition
	dec			al
	%%StartPosition:
	dec			cl
	div			cl
	inc			al
	mul			cl
	mov			dx, ax
	pop			ax
	mov			dh, ah
	add			dx, [Video_WindMin]
	cmp			dl, [Video_WindMaxX]
	jbe			%%PostDisplayChar 	; check past edge
	mov			dl, [Video_WindMin]
	inc			dh
	jmp			%%PostDisplayChar
%%ProcessBS:			; Backspace
	cmp			dl, [Video_WindMinX]
	jbe			%%PostDisplayChar
	dec			dl
	jmp			%%PostDisplayChar
%%DisplayChar:
	PreWriteMouse		dx
	mov			ah, 0x09		; Write the Char/Attr
	; mov			al, "Character"		; already set
	; mov			bh, [Video_Page]	; already set
	; mov			bl, [Video_Attr]	; already set
	mov			cx, 0x0001		; Char count
	int			0x10
	PostWriteMouse
	inc			dl			; Move to next position
%%PostDisplayChar:
	mov			ax, [Video_WindMin]
	mov			cx, [Video_WindMax]
	cmp			dl, cl			; Past end of line
	jbe			%%NoAutoFeed
	mov			dl, al
	inc			dh
%%NoAutoFeed:
	cmp			dh, ch			; Past last row
	jbe			%%PositionOkay
	test			[Video_Options], byte vcbScroll
	jnz			%%ScrollUp
	mov			dh, ah			; Goto Top of Window
	jmp			%%PositionOkay
%%ScrollUp:
	dec			dh			; Cursor back up one
	push			dx			; save position
	mov			dx, cx			; WindMax
	mov			cx, ax			; WindMin
	xchg			bl, bh			; swap page/attr
	mov			ax, 0x0601		; Scroll up one line
	%ifdef DOS_BUG_FIXES
		; See -- https://fd.lod.bz/rbil/interrup/video/1006.html#130
		pushm		ds, bp
	%endif
	PreWriteMouse		cx, dx
	int			0x10
	%ifdef DOS_BUG_FIXES
		popm		ds, bp
	%endif
	PostWriteMouse
	xchg			bl, bh			; swap page/attr back
	pop			dx			; restore position
%%PositionOkay:
	mov			ah, 0x02		; Move Cursor
	; mov			bh, [Video_Page]	; already set
	; mov			dx, "Cursor position"
	int			0x10
	RegsRestore		bx, cx, dx
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
; Write individual raw characters to display
; MACRO:  WriteRawChar 1-*
; INPUT:  %1+ = Characters (prefers dl)
; OUTPUT: none
; -----------------------------------------------------------------------------
%imacro WriteChar 1-*

	PROC_REQUIRE		WriteChar

	RegsPreserve		ax
	%rep  %0
		movndef		al, %1
		call 		WriteChar_PROC
	%rotate 1
	%endrep
	RegsRestore		ax
%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE		WriteChar
%endif