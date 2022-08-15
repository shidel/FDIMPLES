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

%ifndef TEXTATTR_INC_DEFINED
%define TEXTATTR_INC_DEFINED
; -----------------------------------------------------------------------------
; Set the foreground color for text writes
; MACRO:  TextColor 1
; INPUT:  %1 = 4-bit color (prefers al), original returns it to Initial Setting
; OUTPUT: none
; REGS:   ax
; -----------------------------------------------------------------------------
%imacro TextColor_RESET 0

%ifndef TextColor_RESET_PROC_DEFINED
	%idefine TextColor_RESET_PROC_DEFINED

[section .procs]

TextColor_RESET_PROC:
	RegsPreserve		ax
	mov			al, [Initial_Video_Attr]
	and			al, 0x0f
	and			[Video_Attr], byte 0xf0
	or			[Video_Attr], al
	RegsRestore		ax
	ret

%endif

__?SECT?__

	call	TextColor_RESET_PROC

%endmacro

%imacro TextColor 1

%ifndef TextColor_PROC_DEFINED
	%idefine TextColor_PROC_DEFINED

[section .procs]

TextColor_PROC:
	RegsPreserve		ax
	and			al, 0x0f
	mov			ah, [Video_Attr]
	and			ah, 0xf0
	or			al, ah
	mov			[Video_Attr], al
	RegsRestore		ax
	ret
%endif

__?SECT?__

%ifidni %1, original
	TextColor_RESET
%else
	%ifnidni %1, al
		RegsPreserve	ax
		mov		al, %1
	%endif
	call 			TextColor_PROC
	%ifnidni %1, al
		RegsRestore	ax
	%endif
%endif

%endmacro
; -----------------------------------------------------------------------------
; Set the background color for text writes
; MACRO:  TextBackground 1
; INPUT:  %1 = 3-bit color (prefers al), original returns it to Initial Setting
; OUTPUT: none
; REGS:   ax, cx
; -----------------------------------------------------------------------------
%imacro TextBackground_RESET 0

%ifndef TextBackground_RESET_PROC_DEFINED
	%idefine TextBackground_RESET_PROC_DEFINED

[section .procs]

TextBackground_RESET_PROC:
	RegsPreserve		ax
	mov			al, [Initial_Video_Attr]
	and			al, 0xf0
	and			[Video_Attr], byte 0x0f
	or			[Video_Attr], al
	RegsRestore		ax
	ret

%endif

__?SECT?__

	call			TextBackground_RESET_PROC

%endmacro

%imacro TextBackground 1

%ifndef TextBackground_PROC_DEFINED
	%idefine TextBackground_PROC_DEFINED

[section .procs]

TextBackground_PROC:
	RegsPreserve		ax, cx
	mov			cl, 0x04
	and			al, 0x07
	shl			al, cl
	mov			ah, [Video_Attr]
	and			ah, 0x8f
	or			al, ah
	mov			[Video_Attr], al
	RegsRestore		ax, cx
	ret

%endif

__?SECT?__

%ifidni %1, original
	TextBackground_RESET
%else
	%ifnidni %1, al
		RegsPreserve	ax
		mov		al, %1
	%endif
	call 			TextBackground_PROC
	%ifnidni %1, al
		RegsRestore	ax
	%endif
%endif

%endmacro
; -----------------------------------------------------------------------------
; Set both foreground and background color.
; MACRO:  TextAttr 1
; INPUT:  %1 = 8-bit color (prefers al), original returns it to Initial Setting
; OUTPUT: none
; REGS:   ax
; -----------------------------------------------------------------------------
%imacro TextAttr 1

%ifndef TextAttr_PROC_DEFINED
	%idefine TextAttr_PROC_DEFINED

[section .procs]

TextAttr_RESET_PROC:
	RegsPreserve		ax
	mov			al, [Initial_Video_Attr]
	mov			[Video_Attr], al
	RegsRestore		ax
	ret

%endif
__?SECT?__

	%ifidni %1, original
		call		TextAttr_RESET_PROC
	%elifnum %1
		mov		[Video_Attr], byte %1
	%else
		mov		[Video_Attr], %1
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Clear foreground text color intensity bit
; MACRO:  LowVideo 0
; INPUT:  none
; OUTPUT: none
; REGS:   none
; -----------------------------------------------------------------------------
%imacro LowVideo 0

	and			[Video_Attr], byte 11110111b

%endmacro
; -----------------------------------------------------------------------------
; Set foreground text color intensity bit
; MACRO:  HighVideo 0
; INPUT:  none
; OUTPUT: none
; REGS:   none
; -----------------------------------------------------------------------------
%imacro HighVideo 0

	or			[Video_Attr], byte 00001000b

%endmacro
; -----------------------------------------------------------------------------
; Restore foreground intensity bit to last/original video Initial Setting
; MACRO:  NormVideo 0
; INPUT:  none
; OUTPUT: none
; REGS:   none
; -----------------------------------------------------------------------------
%imacro NormVideo 0

%ifndef NormVideo_PROC_DEFINED
	%idefine NormVideo_PROC_DEFINED
[section .procs]

NormVideo_PROC:
	push			ax
	mov			al, [Initial_Video_Attr]
	and			al, 00001000b
	and			[Video_Attr], byte 11110111b
	or			[Video_Attr], al
	pop			ax
	ret

%endif

__?SECT?__

	call			NormVideo_PROC

%endmacro
; *****************************************************************************
%else
%endif
