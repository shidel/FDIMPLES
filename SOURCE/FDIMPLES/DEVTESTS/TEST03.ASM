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

%include "FEATURES.INC"		; Default DEFINES & options for library macros

; %undef Preserve_Registers
; %undef DOS_BUG_FIXES
%undef DOSCRT_Range_Check
%undef Support_BIOS_Timer
; %undef Support_BIOS_Video
; %undef Support_Direct_Video
%undef Support_Mouse
%undef Video_MCGA
%undef Video_VGA
%undef Video_VESA

%include "DOSLIBS.INC"		; One INC to include them all. Some INCS have
				; initialization routines. Some calls for those
				; routines gets inserted automatically. For
				; example DOSCRT requires preparation. If those
				; are not needed, you can save some bytes by
				; including only the required LIBS directly.


	; TextMode	0x54

	mov		cx, 5
MakeBoxes:
	mov		al, cl
	TextBackground	al
	not		al
	TextColor	al
	ClrScr
	push		cx
	mov		cx, [Video_WindMin]
	mov		dx, [Video_WindMax]
	WriteHexWord	cx
	WriteChar	'/'
	WriteHexWord	dx
	add		cx, 0x0102
	sub		dx, 0x0102
	Window		cx, dx
	pop		cx
	loop		MakeBoxes

	WriteStr	'Message will scroll down, up, right then left', CRLF
	TextBackground	clRed
	mov		cx, 10
	push		cx
ScrollDown:
	Delay 		100
	ScrollWindow	Down
	loop		ScrollDown
	PopPush		cx
	TextBackground	clGreen
ScrollUp:
	Delay 		100
	ScrollWindow	Up
	loop		ScrollUp
	PopPush		cx
	TextBackground	clCyan
ScrollRight:
	Delay 		100
	ScrollWindow	Right
	loop		ScrollRight
	PopPush		cx
	TextBackground	clMagenta
ScrollLeft:
	Delay 		100
	ScrollWindow	Left
	loop		ScrollLeft
	pop		cx

Finished:
	VideoResetSettings
	Terminate		0 ; Automatically includes used LIB functions

	; Include_LIB_Functions

