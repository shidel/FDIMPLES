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
