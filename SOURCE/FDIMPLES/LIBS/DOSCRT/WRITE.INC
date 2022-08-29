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
%macro PutChar_INTERNAL 0

SECTION_PROC

PutChar_PROC:

; %ifdef BIOS_AND_DIRECT_VIDEO
;	test 	[Video_Options], byte vcbDirect
;	jnz	PutChar_PROC_DIRECT
;%endif


%ifdef Support_BIOS_Video
PutChar_PROC_BIOS:
	pushm			cx, bx
	mov			bl, ah		; write char/attr
	mov			ah, 0x02	; move cursor to xy
	int			0x10		; dx=xy, bh=page
	mov			ah, 0x09
	mov			cx, 0x0001
	int			0x10
	popm			cx, bx
	ret
%endif

;%ifdef Support_Direct_Video
; PutChar_PROC_DIRECT:
;	pushm			es, di
;	push			ax
;	Calc_Video_Pointer	dx
;	pop			ax
;	mov			[es:di], ax
;	popm			es, di
;	ret
;%endif

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro WriteChar_INTERNAL 0
; AL = character to display

SECTION_PROC

WriteChar_PROC:

; al = character to display
	RegsPreserve		bx, cx, dx
	; push ax,  see - https://fd.lod.bz/rbil/interrup/video/1003.html
	push			ax			; Some BIOS clear AX
	mov			ah, 0x03		; Get Cursor Pos & Size
	mov			bx,[Video_PageAttr]
	int			0x10
	pop			ax
	test			[Video_Options], byte vcbCtrlChar
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

%ifdef BIOS_AND_DIRECT_VIDEO
	test 	[Video_Options], byte vcbDirect
	jz	DisplayChar_PROC_BIOS
	jmp	DisplayChar_PROC_DIRECT
%endif

%ifdef Support_BIOS_Video
DisplayChar_PROC_BIOS:
	mov			ah, 0x09		; Write the Char/Attr
	; mov			al, "Character"		; already set
	; mov			bh, [Video_Page]	; already set
	; mov			bl, [Video_Attr]	; already set
	mov			cx, 0x0001		; Char count
	int			0x10
%endif

%ifdef BIOS_AND_DIRECT_VIDEO
	jmp			%%DisplayCharDone
%endif

%ifdef Support_Direct_Video
DisplayChar_PROC_DIRECT:
	pushm			es, di
	mov			ah, bl
	push			ax
	Calc_Video_Pointer	dx ; es:di=video ptr, ax is now bytes per line
	pop			ax
	mov			[es:di], ax
	popm			es, di
%endif

%%DisplayCharDone:
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
	regpush			bx
	mov			ax, 0x0600
	call			ScrollWindowUpDown_PROC
	regpop			bx
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
; Write individual characters to display
; MACRO:  WriteChar 1-*
; INPUT:  %1+ = Characters (prefers al)
; REG: 	  ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro WriteChar 1-*

	PROC_REQUIRE WriteChar

	RegsPreserve		ax
	%rep  %0
		movndef		al, %1
		call 		WriteChar_PROC
	%rotate 1
	%endrep
	RegsRestore		ax
%endmacro
; -----------------------------------------------------------------------------
; Write CRLF to display
; MACRO:  WriteCRLF 0-1
; INPUT:  %1 = Number of CRLF to output device (default 1, prefers cx)
; REG: 	  ax, bx, cx, dx
; -----------------------------------------------------------------------------
%macro WriteCRLF_INTERNAL 0

	PROC_REQUIRE WriteChar

SECTION_PROC

WriteCRLF_PROC:
	RegsPreserve		ax
	mov			al, CR
	call			WriteChar_PROC
	mov			al, LF
	call			WriteChar_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%macro WriteCR_INTERNAL 0

	PROC_REQUIRE WriteChar

SECTION_PROC

WriteCR_PROC:
	RegsPreserve		ax
	mov			al, CR
	call			WriteChar_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%macro WriteLF_INTERNAL 0

	PROC_REQUIRE WriteChar

SECTION_PROC

WriteLF_PROC:
	RegsPreserve		ax
	mov			al, LF
	call			WriteChar_PROC
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro WriteCRLF 0-1 1

	PROC_REQUIRE 		WriteCRLF

	%ifnidni %1, 1
		RegsPreserve	cx
		movndef		cx, %1
		%%Loopy:
			regpush cx
			call	WriteCRLF_PROC
			regpop  cx
			loop	%%Loopy
		RegsRestore	cx
	%else
		call		WriteCRLF_PROC
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Send ASCIIz string to display. When passed a memory reference, like a
; register or number, it will use the ES segment (like [ES:?]). When passed
; a hard string (like 'HELLO'), it will be stored in the DATA segment
; and it will automatically adjust ES to DS and back again.
; MACRO:  WriteStr 1-*
; INPUT:  ASCIIz string(s) to sent to display (prefers si)
; REGS:   ax, bx, cx, dx, si
; -----------------------------------------------------------------------------
%macro WriteStr_INTERNAL 0

	PROC_REQUIRE WriteChar

SECTION_PROC

WriteStr_PROC:
	RegsPreserve		ax
	cld
%%DisplayMessage:
	es lodsb
	test			al, al
	jz 			%%NoDisplayChar
	call			WriteChar_PROC
	jmp			%%DisplayMessage
%%NoDisplayChar:
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%macro WriteStrDS_INTERNAL 0

WriteStrDS_PROC:
	push		es
	push		ds
	pop		es
	call		WriteStr_PROC
	pop		es
	ret
%endmacro

%macro WriteStr_SUBMAC 1

	PROC_REQUIRE WriteStrDS
	PROC_REQUIRE WriteChar
	PROC_REQUIRE WriteStr

SECTION_DATA

	%ifstr %1

	%%str:
		db		%1
		db		0
	%endif

__?SECT?__

	RegsPreserve		si
	%ifstr %1
		movndef		si, %%str
		call		WriteStrDS_PROC
	%else
		movndef		si, %1
		call		WriteStr_PROC
	%endif
	RegsRestore		si

%endmacro

%imacro WriteStr 1-*

	PROC_REQUIRE WriteCR
	PROC_REQUIRE WriteLF

	%rep  %0
		%ifidni %1, CR
			call	WriteCR_PROC
		%elifidni %1, LF
			call	WriteLF_PROC
		%else
			WriteStr_SUBMAC %1
		%endif
	%rotate 1
	%endrep
%endmacro
; -----------------------------------------------------------------------------
; Send byte as HEX to display
; MACRO:  WriteHexByte 1-*
; INPUT:  %1+ = byte to display (prefers al)
; REGS:   ax, bx, cx, dx
; -----------------------------------------------------------------------------
%macro WriteHexByte_INTERNAL 0

	PROC_REQUIRE WriteChar

SECTION_PROC

WriteHexByte_PROC:
	RegsPreserve		dx, cx

	mov			cx, 0x0204	; ch = count, cl = bit rotate
	mov			ah, ch		; mov ah, 0x02
%%Loopy:
	ror			al, cl		; rotate first to do high bits
	mov			dl, al
	and			dl, 0x0f
	add			dl, 0x30	; make numbers ascii numbers
	cmp			dl, 0x39
	jbe			%%Display	; <= to asciii 9
	add			dl, 0x27	; make value ascii letter

%%Display:
	regpush			cx
	push			ax
	mov			al, dl
	call			WriteChar_PROC
	pop			ax
	regpop			cx
	dec			ch
	jnz			%%Loopy

	RegsRestore		dx, cx

	ret

__?SECT?__

%endmacro

%imacro WriteHexByte 1-*

	PROC_REQUIRE WriteHexByte

	%rep  %0
		%ifnidni %1, al
			RegsPreserve 	ax
			mov	al, %1
		%endif
		call		WriteHexByte_PROC
		%ifnidni %1, al
			RegsRestore 	ax
		%endif
	%rotate 1
	%endrep

%endmacro
; -----------------------------------------------------------------------------
; Send word as HEX to display
; MACRO:  WriteHexWord 1-*
; INPUT:  %1+ = word to display (prefers ax)
; REGS:   ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro WriteHexWord 1-*
	%rep  %0
		%ifnidni %1, ax
			RegsPreserve	ax
			mov	ax, %1
		%endif
		regpush		ax
		WriteHexByte	ah
		regpop		ax
		WriteHexByte	al
		%ifnidni %1, ax
			RegsRestore	ax
		%endif
	%rotate 1
	%endrep
%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE		PutChar
	PROC_PROVIDE		WriteChar
	PROC_PROVIDE		WriteCRLF
	PROC_PROVIDE		WriteCR
	PROC_PROVIDE		WriteLF
	PROC_PROVIDE		WriteStr
	PROC_PROVIDE		WriteStrDS
	PROC_PROVIDE		WriteHexByte
%endif