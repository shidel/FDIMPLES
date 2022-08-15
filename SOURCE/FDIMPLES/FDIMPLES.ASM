; FreeDOS Installer (FDI) - My Package List Editor Software

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

use16

cpu 8086

org 0x100

SECTION .text

%include "FEATURES.INC"		; Default DEFINES for library options

%idefine Preserve_Registers	; Macros preserve all registers when possible
; %undef Preserve_Registers	; Macros preserve all registers when possible
%undef DOSCRT_Range_Check	; Prevent out of bounds coordinate settings
%undef Support_BIOS_Timer	; Use high precision int15 timer if possible
%undef Support_Direct_Video	; Direct video addressing
; %undef Support_Mouse		; Mouse support
%undef Video_MCGA		; Check for MCGA support
%undef Video_VGA		; Check for VGA support
%undef Video_VESA		; Check for SuperVGA support

%include "DOSLIBS.INC"		; One INC to include them all.

	; TextMode		0x37
	; jnc			DisplayStuff
	; WriteLn			'Text mode change error'
	; Terminate		1

; DisplayStuff:
;	ClrScr
;	mov			[Video_WindMaxX], byte 0x10
;	mov			[Video_Attr], byte 0x1f
;	ClrScr
;	mov			cx, 20
;.PrintNext:
;	push			cx
;.PrintChars:
;	push			cx
;	WriteChar		'A'
;	pop			cx
;	loop			.PrintChars
;	WriteChar		0x09, 'B', 0x0d, 0x0a
;	Delay			50
;	pop			cx
;	loop			.PrintNext
;	WriteChar		0x09, 'B', 0x0d, 0x0a


Finished:
	Terminate		0

	Include_LIB_Functions	; Include functions called by macros
;	Include_LIB_Functions	; Include functions called by macros
