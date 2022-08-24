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

%ifndef CURSOR_INC_DEFINED
%define CURSOR_INC_DEFINED
; -----------------------------------------------------------------------------
; Return the current cursor shape
; MACRO:  GetCursor 1
; OUTPUT: %1 = Cursor Shape (prefers cx)
; REGS:   ax, bx, cx, dx
; -----------------------------------------------------------------------------
%imacro GetCursor_INTERNAL 0

SECTION_PROC

GetCursor_PROC:
	RegsPreserve		ax, bx, dx
	mov			bh, [Video_Page]
	mov			ah, 0x03		; Get cursor shape/pos
	int			0x10
	RegsRestore		ax, bx, dx
	ret

__?SECT?__

%endmacro

%imacro GetCursor 1

	PROC_REQUIRE 		GetCursor

	%ifnidni %1, cx
		RegsPreserve 	cx
	%endif
	call 			GetCursor_PROC
	%ifnidni %1, cx
		movndef		%1, cx
		RegsRestore 	cx
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Set the current cursor shape
; MACRO:  SetCursor 1
; INPUT:  %1 = Cursor Shape (prefers cx) (accepts: original, small, half, full)
;	  Also, it uses HIDE, SHOW with counters. 2 hides will need 2 shows.
;	  Like the cursor itself, the counters are reset on mode changes.
; REGS:   ax, cx
; -----------------------------------------------------------------------------
%imacro SetCursor_INTERNAL 0

SECTION_PROC

SetCursor_PROC:
	RegsPreserve		ax
SetCursor_PROC1:
	mov			[Video_Cursor], cx
	cmp			[Video_Cursor_State], word 0x0000
	jl			SetCursor_PROC3
SetCursor_PROC2:
	mov			ah, 0x01		; Set cursor shape
	int			0x10
SetCursor_PROC3:
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro SetCursorShow_INTERNAL 0

SECTION_PROC

SetCursorShow_PROC:
	RegsPreserve  		ax
	inc			word [Video_Cursor_State]
	cmp			[Video_Cursor_State], word 0x0000
	jne			SetCursor_PROC3
	mov			cx, [Video_Cursor]
	jmp			SetCursor_PROC2

__?SECT?__

%endmacro

%imacro SetCursorHide_INTERNAL 0

SECTION_PROC

SetCursorHide_PROC:
	RegsPreserve  		ax
	dec			word [Video_Cursor_State]
	cmp			[Video_Cursor_State], word -1
	jne			SetCursor_PROC3
	mov			cx, 0x2000
	jmp			SetCursor_PROC2

__?SECT?__

%endmacro

%imacro SetCursorSmall_INTERNAL 0

SECTION_PROC

SetCursorSmall_PROC:
	RegsPreserve		ax
	push			es
	mov			ax, 0x0040
	push			ax
	pop			es
	mov			cx, [es:0x0085]
	pop			es
	mov			ch, cl
	sub			ch, 2
	jmp			SetCursor_PROC1
	; RegsRestore		ax
	; ret

__?SECT?__

%endmacro

%imacro SetCursorHalf_INTERNAL 0

SECTION_PROC

SetCursorHalf_PROC:
	RegsPreserve		ax
	push			es
	mov			ax, 0x0040
	push			ax
	pop			es
	mov			ax, [es:0x0085]
	pop			es
	mov			ah, al
	shr			ah, 1
	mov			cx, ax
	jmp			SetCursor_PROC1
	; RegsRestore		ax
	; ret

__?SECT?__

%endmacro

%imacro SetCursorFull_INTERNAL 0

SECTION_PROC

SetCursorFull_PROC:
	RegsPreserve		ax
	push			es
	mov			ax, 0x0040
	push			ax
	pop			es
	mov			cx, [es:0x0085]
	pop			es
	xor			ch, ch
	jmp			SetCursor_PROC1
	; RegsRestore		ax
	; ret

__?SECT?__

%endmacro

%imacro SetCursor 1

	PROC_REQUIRE 		SetCursor

	%ifnidni %1, cx
		RegsPreserve 	cx
		%ifidni %1, original
			mov		cx, [Initial_Video_Cursor]
			call 		SetCursor_PROC
		%elifidni %1, invisible
			mov		cx, 0x2000
			call 		SetCursor_PROC
		%elifidni %1, small
			PROC_REQUIRE 	SetCursorSmall
			call		SetCursorSmall_PROC
		%elifidni %1, half
			PROC_REQUIRE 	SetCursorHalf
			call		SetCursorHalf_PROC
		%elifidni %1, full
			PROC_REQUIRE 	SetCursorFull
			call		SetCursorFull_PROC
		%elifidni %1, hide
			PROC_REQUIRE 	SetCursorHide
			call		SetCursorHide_PROC
		%elifidni %1, show
			PROC_REQUIRE 	SetCursorShow
			call		SetCursorShow_PROC
		%else
			movndef	cx, 	%1
			call 		SetCursor_PROC
		%endif
		RegsRestore 	cx
	%else
		call 		SetCursor_PROC
	%endif

%endmacro

%idefine Cursor SetCursor
; *****************************************************************************
%else
	PROC_PROVIDE GetCursor
	PROC_PROVIDE SetCursor
	PROC_PROVIDE SetCursorSmall
	PROC_PROVIDE SetCursorHalf
	PROC_PROVIDE SetCursorFull
	PROC_PROVIDE SetCursorShow
	PROC_PROVIDE SetCursorHide
%endif
