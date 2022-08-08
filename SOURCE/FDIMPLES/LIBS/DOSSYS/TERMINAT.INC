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
; Terminate Program
; MACRO:  Terminate 1-2+
; INPUT:
; 	%1  = DOS Exit Code (prefers al)
; 	%2+ = Any message sent to STDOUT at exit
; OUTPUT:
; 	None: Does not return
; -----------------------------------------------------------------------------
%imacro Terminate 1-2+

%if %0 != 1

	[section .procs]
	; NASM will combine and place all .procs sections after the .text section

	%ifndef Terminate_PROC_DEFINED
		%idefine Terminate_PROC_DEFINED

		Terminate_PROC:
			push		ax
			test		si, si
			jz		%%ProgramExit	; if si = 0, no message
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
	; NASM will combine and place all .data sections after the .procs section

		; if more than 1 param, store the rest as a string in the data section
		%%str:
			db 		%2
			db 		0
%endif

__?SECT?__
; Switch back to the section prior to the macro. should be .text. but, maybe
; not.

%if %0 = 1
	%ifnum %1
		mov		ax, 0x4c00 + %1
	%else
		mov		ah, 0x4c
		movndef		al, %1
	%endif
	int		0x21
%else
	movndef 	al, %1		; exit code
	mov		si, %%str	; message in data section
	jmp		Terminate_PROC
%endif

%endmacro
