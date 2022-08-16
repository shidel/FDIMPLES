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
; INPUT: %1 = Cursor Shape (prefers cx) (accepts: original, small, half, full)
; REGS:   ax, cx
; -----------------------------------------------------------------------------
%imacro SetCursor_INTERNAL 0

SECTION_PROC

SetCursor_PROC:
	RegsPreserve		ax
	mov			ah, 0x01		; Set cursor shape
	int			0x10
	RegsRestore		ax
	ret

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
	RegsRestore		ax
	ret

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
	RegsRestore		ax
	ret

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
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro SetCursor 1

	PROC_REQUIRE 		SetCursor

	%ifnidni %1, cx
		RegsPreserve 	cx
		%ifidni %1, original
			mov		cx, [Initial_Video_Cursor]
		%elifidni %1, invisible
			mov		cx, 0x2000
		%elifidni %1, small
			PROC_REQUIRE 	SetCursorSmall
			call		SetCursorSmall_PROC
		%elifidni %1, half
			PROC_REQUIRE 	SetCursorHalf
			call		SetCursorHalf_PROC
		%elifidni %1, full
			PROC_REQUIRE 	SetCursorFull
			call		SetCursorFull_PROC
		%else
			movndef		cx, %1
		%endif
	%endif
	call 			SetCursor_PROC
	%ifnidni %1, cx
		RegsRestore 	cx
	%endif

%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE GetCursor
	PROC_PROVIDE SetCursor
	PROC_PROVIDE SetCursorSmall
	PROC_PROVIDE SetCursorHalf
	PROC_PROVIDE SetCursorFull
%endif
