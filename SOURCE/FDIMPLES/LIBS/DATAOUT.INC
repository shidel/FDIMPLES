; Internal data processing output routines for DOS
; Similar (but a little different) to a Pascal DOS unit.

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

; -----------------------------------------------------------------------------
%include "FEATURES.INC"
%include "NASMEXT.INC"
; -----------------------------------------------------------------------------
%ifndef DATAOUT_INC_DEFINED
%define DATAOUT_INC_DEFINED
; -----------------------------------------------------------------------------
%macro DATAOUT_PROC 3

SECTION_PROC

%3 %+ _PROC:
	push			di
	mov			di, WRITER_ %+ %1 %+_PROC
	call			DATAOUT_ %+ %2 %+ _PROC
	pop			di
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro USES_WRITER 3

	PROC_REQUIRE		WRITER_ %+ %1
	PROC_REQUIRE		DATAOUT_ %+ %2
	PROC_REQUIRE		%3

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_CHAR_INTERNAL 0
; This proc is really pointless
SECTION_PROC

DATAOUT_CHAR_PROC:
	; dl = character
	call	di
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_CR_INTERNAL 0

SECTION_PROC

DATAOUT_CR_PROC:
	push	dx
	mov	dl, CR
	call	di
	pop	dx
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_LF_INTERNAL 0

SECTION_PROC

DATAOUT_LF_PROC:
	push	dx
	mov	dl, LF
	call	di
	pop	dx
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_CRLF_INTERNAL 0

SECTION_PROC

DATAOUT_CRLF_PROC:
	push	dx
	mov	dl, CR
	call	di
	mov	dl, LF
	call	di
	pop	dx
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_STR_ES_INTERNAL 0

SECTION_PROC

DATAOUT_STR_ES_PROC:
	RegsPreserve		ax, dx
	cld
%%DisplayMessage:
	es lodsb
	test			al, al
	jz 			%%NoDisplayChar
	mov			dl, al
	call			di
	jmp			%%DisplayMessage
%%NoDisplayChar:
	RegsRestore		ax, dx
	ret

__?SECT?__

%endmacro

%macro DATAOUT_STR_DS_INTERNAL 0

SECTION_PROC

DATAOUT_STR_DS_PROC:
	push		es
	push		ds
	pop		es
	call		DATAOUT_STR_ES_PROC
	pop		es
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_HEXBYTE_INTERNAL 0

SECTION_PROC

DATAOUT_HEXBYTE_PROC:
	; al = byte to output
	RegsPreserve		dx, cx
	push			ax

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
	push			ax
	call			di
	pop			ax
	dec			ch
	jnz			%%Loopy
	pop			ax
	RegsRestore		dx, cx
	ret

__?SECT?__

%endmacro

; -----------------------------------------------------------------------------
%macro DATAOUT_HEXWORD_INTERNAL 0

	PROC_REQUIRE DATAOUT_HEXBYTE

SECTION_PROC

DATAOUT_HEXWORD_PROC:
	; ax = word to output
	push	ax
	mov	al, ah
	call	DATAOUT_HEXBYTE_PROC
	pop	ax
	call	DATAOUT_HEXBYTE_PROC
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_HEXDWORD_INTERNAL 0

	PROC_REQUIRE DATAOUT_HEXBYTE
	PROC_REQUIRE DATAOUT_HEXWORD

SECTION_PROC

DATAOUT_HEXDWORD_PROC:
	; ax = word to output
	xchg	dx, ax
	call	DATAOUT_HEXWORD_PROC
	xchg	dx, ax
	call	DATAOUT_HEXWORD_PROC
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_UINTBYTE_INTERNAL 0

	PROC_REQUIRE DATAOUT_UINTDWORD

SECTION_PROC

DATAOUT_UINTBYTE_PROC:
	; al = unsigned byte to output
	pushm	ax, dx
	xor	ah, ah
	xor	dx, dx
	call	DATAOUT_UINTDWORD_PROC
	popm	ax, dx
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_UINTWORD_INTERNAL 0

	PROC_REQUIRE DATAOUT_UINTDWORD

SECTION_PROC

DATAOUT_UINTWORD_PROC:
	; ax = unsigned word to output
	push	dx
	xor	dx, dx
	call	DATAOUT_UINTDWORD_PROC
	pop	dx
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro DATAOUT_UINTDWORD_INTERNAL 0

SECTION_PROC

DATAOUT_UINTDWORD_PROC:
	; dx:ax = unsigned dword to output
	; works by repeatedly dividing the dx:ax pair by 10 and placing the
	; remainder onto the stack. then the remainders are played back in the
	; reverse order the division was performed. The technique works well
	; for integers of any bit size. I'll probably add a Int64 (or variable
	; size) bin integer math library for 8086 at some point to better show
	; methods of displaying and doing basic math on really big integers. :-)
	pushm	ax, bx, cx, dx, si
	mov	cx, 0x000a
	push	cx
	mov	si, ax
	mov	bx, dx
%%Dividing:
	xor	dx, dx
	xchg	ax, bx
	div	cx
	xchg	ax, bx
	xchg	ax, si
	div	cx
	mov	si, ax
	push	dx
	or	ax, bx
	jnz	%%Dividing
%%Displaying:
	pop	dx
	cmp	dx, cx
	je	%%Finished
	add	dl, 0x30
	call	di		; display digit
	jmp	%%Displaying
%%Finished:
	popm	ax, bx, cx, dx, si
	ret

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%else
; -----------------------------------------------------------------------------
	PROC_PROVIDE 	DATAOUT_CHAR
	PROC_PROVIDE 	DATAOUT_CR
	PROC_PROVIDE 	DATAOUT_LF
	PROC_PROVIDE 	DATAOUT_CRLF
	PROC_PROVIDE 	DATAOUT_STR_ES
	PROC_PROVIDE 	DATAOUT_STR_DS
	PROC_PROVIDE 	DATAOUT_HEXBYTE
	PROC_PROVIDE 	DATAOUT_HEXWORD
	PROC_PROVIDE 	DATAOUT_HEXDWORD
	PROC_PROVIDE 	DATAOUT_UINTBYTE
	PROC_PROVIDE 	DATAOUT_UINTWORD
	PROC_PROVIDE 	DATAOUT_UINTDWORD
%endif