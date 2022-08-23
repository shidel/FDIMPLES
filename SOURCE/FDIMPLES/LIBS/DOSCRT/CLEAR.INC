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

%ifndef CLEAR_INC_DEFINED
%define CLEAR_INC_DEFINED
; -----------------------------------------------------------------------------
; Clear the current window
; MACRO: ClrScr 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------

%imacro ClrScr_INTERNAL 0

SECTION_PROC

ClrScr_PROC:
	RegsPreserve		ax, bx, cx, dx
	mov			cx, [Video_WindMin]
	mov			dx, [Video_WindMax]
Clear_Region_PROC:
	mov			bh, [Video_Attr]

	PreWriteMouse		cx, dx

%ifdef BIOS_AND_DIRECT_VIDEO
	test 	[Video_Options], byte vcbDirect
	jz	ClrScr_PROC_BIOS
	jmp	ClrScr_PROC_DIRECT
%endif

%ifdef Support_BIOS_Video
ClrScr_PROC_BIOS:
	mov			ax, 0x0600	; Scroll Up 0 lines
	%ifdef DOS_BUG_FIXES
		; See -- https://fd.lod.bz/rbil/interrup/video/1006.html#130
		pushm		ds, bp
	%endif
	int			0x10
	%ifdef DOS_BUG_FIXES
		popm		ds, bp
	%endif
%endif

%ifdef BIOS_AND_DIRECT_VIDEO
	jmp			%%Done
%endif

%ifdef Support_Direct_Video

ClrScr_PROC_DIRECT:
	pushm 			es, di
	mov			bl, 0x20
	Calc_Video_Pointer	cx  ; es:di=video ptr, ax is now bytes per line
	xchg			ax, bx	    ; ax=char/attr, bx=bytes/line

	sub			dx, cx
	add			dx, 0x0101 ; dl=column count, dh=row count

	cld
%%ClearRow:
	pushm			di, dx
%%ClearLine:
	stosw
	dec			dl
	jnz			%%ClearLine
	popm			di, dx
	add			di, bx
	dec			dh
	jnz			%%ClearRow

	popm			es, di
%endif

%%Done:
	PostWriteMouse
	mov			ah, 0x02	; Set Cursor Pos Window 0:0
	mov			bh, [Video_Page]
	mov			dx, cx
	int			0x10
	RegsRestore		ax, bx, cx, dx
	ret

__?SECT?__

%endmacro

%imacro ClrScr 0

	PROC_REQUIRE ClrScr

	call 			ClrScr_PROC

%endmacro
; -----------------------------------------------------------------------------
; Clear the remaining portion of the current line
; MACRO: ClrEOL 0
; REGS: ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro ClrEOL_INTERNAL 0

SECTION_PROC

ClrEOL_PROC:
	RegsPreserve		ax, bx, cx, dx
	%ifdef DOS_BUG_FIXES
		; See -- https://fd.lod.bz/rbil/interrup/video/1003.html#122
	%endif
	mov			ah, 0x03		; Get Cursor Pos & Size
	mov			bh, [Video_Page]
	int			0x10
	mov			cx, dx
	mov			bh, [Video_Attr]
	mov			dx, [Video_WindMax]
	mov			dh, ch
	jmp			Clear_Region_PROC

__?SECT?__

%endmacro

%imacro ClrEOL 0

	PROC_REQUIRE ClrScr
	PROC_REQUIRE ClrEOL

	call 			ClrEOL_PROC

%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE ClrScr
	PROC_PROVIDE ClrEOL
%endif
