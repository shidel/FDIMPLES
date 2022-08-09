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
; Probes for current video settings. It needs called prior to any other DOSCRT
; macros. It should really be called only once at startup. That is normally
; handled by DOSCRT.INC.
; Registers AX, BX, CX, DX, ES, DI are not preserved.
; MACRO:  InitialVideoSettings 0
; INPUT:  none
; OUTPUT: undefined, sets data in BSS.
; -----------------------------------------------------------------------------
%imacro InitialVideoSettings 0

%ifndef InitialVideoSettings_PROC_DEFINED
	%idefine InitialVideoSettings_PROC_DEFINED

[section .procs]

InitialVideoSettings_PROC:
	mov			ax, 0x0040
	push 			ax
	pop			es
	mov			ax, [es:0x0060]
	mov			[Initial_Video_Cursor], ax
	mov			al, [es:0x0049]
	mov			[Initial_Video_Mode], al
	mov			al, [es:0x0062]
	mov			[Initial_Video_Page], al
	ret

[section .bss]

Initial_Video_Mode:	resb		1
Initial_Video_Page:	resb		1
Initial_Video_Cursor:	resw		1

%endif

__?SECT?__

	call 			InitialVideoSettings_PROC

%endmacro
