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
; Restores video settings, to original mode, page, and cursor if needed.
; Registers AX, BX, CX, DX, ES, DI are not preserved. Should probably call
; before exit. Automatically, calls ProbeVideoSettings to update data.
; MACRO:  ResetVideoSettings 0
; INPUT:  none
; -----------------------------------------------------------------------------
%imacro ResetVideoSettings 0

%ifndef ResetVideoSettings_PROC_DEFINED
	%idefine ResetVideoSettings_PROC_DEFINED

[section .procs]


ResetVideoSettings_PROC:
	mov			ax, 0x0040
	push 			ax
	pop			es
	mov			bh, [es:0x0049]
	mov			al, [Initial_Video_Mode]
	cmp			bh, al
	je			%%ResetPage
	; mov			ah, 0x00
	int			0x10
%%ResetPage:
	mov			ah, [es:0x0062]
	mov			al, [Initial_Video_Page]
	cmp			ah, al
	je			%%ResetCursor
	; mov			[Video_Page], al
	mov			ah, 0x05
	int			0x10
%%ResetCursor:
	mov			ax, [es:0x0060]
	mov			cx, [Initial_Video_Cursor]
	cmp			ax, cx
	je			%%Done
	; mov			[Video_Cursor], cx
	mov			ah, 0x01
	int			0x10
%%Done:
	mov			al, [Initial_Video_Attr]
	mov			[Video_Attr], al
	; Must call directly, otherwise NASM will embed the macro's code here
	; Instead of later (where we want it)
	call			ProbeVideoCard_PROC
	ret

%endif

__?SECT?__

	call 			ResetVideoSettings_PROC

%endmacro
