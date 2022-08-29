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
%undef Support_BIOS_Video
; %undef Support_Direct_Video
; %undef Support_Mouse
%undef Video_MCGA
%undef Video_VGA
%undef Video_VESA

%include "DOSLIBS.INC"		; One INC to include them all. Some INCS have
				; initialization routines. Some calls for those
				; routines gets inserted automatically. For
				; example DOSCRT requires preparation. If those
				; are not needed, you can save some bytes by
				; including only the required LIBS directly.



	ClrScr
	WriteStr	'Box Test'
	ClrEOL

	TextColor	clGreen
	mov		dx, 0x0202
	mov 		ax, lnSingle
	call		BoxTest
	mov		dx, 0x022a
	mov 		ax, lnDoubleHorz
	call		BoxTest
	mov		dx, 0x0d02
	mov 		ax, lnDoubleVert
	call		BoxTest
	mov		dx, 0x0d2a
	mov 		ax, lnDouble
	call		BoxTest

Finished:
	GotoXY		0, 23
	TextAttr	0x07
	WriteCRLF
	; VideoResetSettings

	Terminate		0 ; Automatically includes used LIB functions

BoxTest:
	mov		cx, dx
	add		cx, 0x0822
	DrawBox		dx, cx, ax
	;TextColor	clCyan
	mov		bx, dx
	add		bl, 0x3
	DrawLine	bx, 0x09, lnVertical + lnSingle
	add		bl, 2
	DrawLine	bx, 0x09, lnVertical + lnDouble
	dec		bh
	add		bl, 4
	DrawLine	bx, 0x0b, lnVertical + lnSingle
	add		bl, 2
	DrawLine	bx, 0x0b, lnVertical + lnDouble
	;TextColor	clMagenta
	mov		bx, dx
	add		bh, 0x1
	DrawLine	bx, 0x23, lnHorizontal + lnSingle
	add		bh, 2
	DrawLine	bx, 0x23, lnHorizontal + lnDouble
	dec		bl
	add		bh, 2
	DrawLine	bx, 0x25, lnHorizontal + lnSingle
	add		bh, 1
	DrawLine	bx, 0x25, lnHorizontal + lnDouble

	ret

	Include_LIB_Functions
