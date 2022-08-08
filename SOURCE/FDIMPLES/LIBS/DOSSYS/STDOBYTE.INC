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
