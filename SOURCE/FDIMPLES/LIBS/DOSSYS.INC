; System for DOS v1.0

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
%imacro Terminate 1-2+
; Terminate Program
; INPUT:
; 	%1  = DOS Exit Code
; 	%2+ = Any message sent to STDOUT at exit
; OUTPUT:
; 	None: Does not return

[section .procs]

%ifndef Terminate_PROC_DEFINED
	%idefine Terminate_PROC_DEFINED

	Terminate_PROC:
		push		ax
		test		si, si
		jz		%%ProgramExit
		mov		ah, 0x02
		cld
	%%DisplayMessage:
		mov		dl, [si]
		test		dl, dl
		jz 		%%ProgramExit
		inc		si
		int		0x21
		jmp		%%DisplayMessage
	%%ProgramExit:
		pop		ax
		mov		ah, 0x4c
		int		0x21
%endif

[section .data]

%if %0 != 1
	%%str:
		db 		%2
		db 		0
	%%endstr:
%endif

__?SECT?__

%if %0 = 1
	xor		si, si
%else
	mov		si, %%str
%endif

	movndef 	al, %1
	jmp		Terminate_PROC
%endmacro

; -----------------------------------------------------------------------------
%imacro StdOutChar 1-*
; Send series of characters to standard output device
; INPUT:  Series of Characters
; OUTPUT: none
	pushm		ax, dx
	%ifnidni %0, 1
		mov		ah, 0x02
		%rep  %0
			movndef		dl, %1
			int    		0x21
		%rotate 1
		%endrep
	%else
		movndef 	dl, %1
		mov		ah, 0x02
		int 		0x21
	%endif
	popm		ax, dx
%endmacro

; -----------------------------------------------------------------------------
%imacro StdOutCRLF 0-1	1
; Send CRLF to standard output device
; INPUT:  %1 = Number of CRLF to output
; OUTPUT: none
	%ifnidni %1, 1
		push		cx
		movndef		cx, %1
		%%Loopy:
			StdOutChar 	13, 10
			loop		%%Loopy
		pop		cx
	%else
		pushm		dx, ax
		mov		ah, 0x02
		mov		dl, 13
		int		0x21
		mov		dl, 10
		int		0x21
		popm		dx, ax
	%endif
%endmacro
; -----------------------------------------------------------------------------
%imacro StdOutHexByte 1-*

[section .procs]

%ifndef StdOutHexByte_PROC_DEFINED
	%idefine StdOutHexByte_PROC_DEFINED

	StdOutHexByte_PROC:
		pushm		dx, cx, ax

		mov		cx, 0x0204
		mov		ah, ch
	%%Loopy:
		ror		al, cl
		mov		dl, al
		and		dl, 0x0f
		add		dl, 0x30
		cmp		dl, 0x39
		jbe		%%Display
		add		dl, 0x27

	%%Display:
		push		ax
		int		0x21
		pop		ax
		dec		ch
		jnz		%%Loopy

		popm		dx, cx, ax

		ret
%endif

__?SECT?__

	%rep  %0
		%ifnidni	%1, al
			push		ax
			mov		al, %1
		%endif
		call		StdOutHexByte_PROC
		%ifnidni	%1, al
			pop		ax
		%endif
	%rotate 1
	%endrep

%endmacro
; -----------------------------------------------------------------------------
%imacro StdOutHexWord 1-*
	%rep  %0
		%ifnidni	%1, ax
			push		ax
			mov		ax, %1
		%endif
		StdOutHexByte	ah
		StdOutHexByte	al
		%ifnidni	%1, ax
			pop		ax
		%endif
	%rotate 1
	%endrep
%endmacro
