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
; Send individual characters to standard output device
; MACRO:  StdOutChar 1-*
; INPUT:  %1+ = Characters (prefers dl)
; OUTPUT: none
; -----------------------------------------------------------------------------
%imacro StdOutChar 1-*
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
; Send CRLF to standard output device
; MACRO:  StdOutCRLF 0-1
; INPUT:  %1 = Number of CRLF to output device (default 1, prefers cx)
; OUTPUT: none
; -----------------------------------------------------------------------------
%imacro StdOutCRLF 0-1	1

[section .procs]

%ifndef StdOutCRLF_PROC_DEFINED
	%define StdOutCRLF_PROC_DEFINED

	StdOutCRLF_PROC:
		pushm		dx, ax
		mov		ah, 0x02
		mov		dl, 13
		int		0x21
		mov		dl, 10
		int		0x21
		popm		dx, ax
		ret
%endif

__?SECT?__

	%ifnidni %1, 1
		push		cx
		movndef		cx, %1
		%%Loopy:
			call		StdOutCRLF_PROC
			loop		%%Loopy
		pop		cx
	%else
		call		StdOutCRLF_PROC
	%endif
%endmacro
; -----------------------------------------------------------------------------
; Send ASCIIz string to standard output device
; MACRO:  StdOutStr 1-*
; INPUT:  ASCIIz string(s) sent to STDOUT (prefers si)
; OUTPUT: none
; -----------------------------------------------------------------------------
%imacro StdOutStr_INTERNAL 1


[section .procs]
; NASM will combine and place all .procs sections after the .text section

%ifndef StdOutStr_PROC_DEFINED
	%idefine StdOutStr_PROC_DEFINED

	StdOutStr_PROC:
		pushm		ax, dx
		mov		ah, 0x02
		cld
	%%DisplayMessage:
		mov		dl, [si]
		test		dl, dl
		jnz 		%%DisplayChar
		popm		ax, dx
		ret
	%%DisplayChar:
		inc		si
		int		0x21
		jmp		%%DisplayMessage
%endif

	%ifstr %1
	[section .data]

		%%str:
			db 		%1
			db 		0
	%endif

	__?SECT?__

		%ifstr %1
			movndef		si, %%str
		%else
			mov		si, %1
		%endif
		call		StdOutStr_PROC
%endmacro

%imacro StdOutStr 1-*
	%rep  %0
		push		si
		StdOutStr_INTERNAL %1
		pop		si
	%rotate 1
	%endrep
%endmacro
; -----------------------------------------------------------------------------
; Send byte as HEX to standard output device
; MACRO:  StdOutHexByte 1-*
; INPUT:  %1+ = byte to print (prefers al)
; OUTPUT: none
; -----------------------------------------------------------------------------
%imacro StdOutHexByte 1-*

[section .procs]

%ifndef StdOutHexByte_PROC_DEFINED
	%define StdOutHexByte_PROC_DEFINED

	StdOutHexByte_PROC:
		pushm		dx, cx, ax

		mov		cx, 0x0204	; ch = count, cl = bit rotate
		mov		ah, ch		; mov ah, 0x02
	%%Loopy:
		ror		al, cl		; rotate first to do high bits
		mov		dl, al
		and		dl, 0x0f
		add		dl, 0x30	; make numbers ascii numbers
		cmp		dl, 0x39
		jbe		%%Display	; <= to asciii 9
		add		dl, 0x27	; make value ascii letter

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
; Send word as HEX to standard output device
; MACRO:  StdOutHexWord 1-*
; INPUT:  %1+ = word to print (prefers ax)
; OUTPUT: none
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
