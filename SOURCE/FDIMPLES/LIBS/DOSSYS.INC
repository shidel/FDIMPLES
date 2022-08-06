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
; %1  = DOS Exit Code
; %2+ = Any message sent to STDOUT at exit

[section .procs]

%ifndef TERMINATE_PROC_DEFINED
	%idefine TERMINATE_PROC_DEFINED

	TERMINATE_PROC:
		push	ax
		test	si, si
		jz		%%ProgramExit
		mov		ah, 0x02
		cld
	%%DisplayMessage:
		mov		dl, [si]
		test 	dl, dl
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
		db %2
		db 0
	%%endstr:
%endif

__?SECT?__

%if %0 = 1
	xor		si, si
%else
	mov		si, %%str
%endif

	movndef al, %1
	jmp		TERMINATE_PROC
%endmacro
