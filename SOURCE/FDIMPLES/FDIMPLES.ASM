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

%undef Preserve_Registers	; Preserve all registers in most macros
; %undef DOS_BUG_FIXES		; Include some fixes for various DOS and BIOS
%undef DOSCRT_Range_Check	; Prevent out of bounds coordinate settings
%undef Support_BIOS_Timer	; Try to use high precision int15 timer
%undef Support_Direct_Video	; Direct video addressing support
; %undef Support_Mouse		; Mouse support
%undef Video_MCGA		; MCGA check/support
%undef Video_VGA		; VGA check/support
%undef Video_VESA		; SuperVGA check/support

%include "DOSLIBS.INC"		; One INC to include them all. Some INCS have
				; initialization routines. Calls to those
				; routines gets inserted automatically. For
				; example DOSCRT requires preparation. If those
				; are not needed, you can save some bytes by
				; including only the required LIBS directly.

%if 0 = 0
;	TextMode		tmCO80
	ClrScr
;	Window			max
;	SetCursor		small
	mov			ax, [Mouse_Button_Count]
	test			ax, ax
	jnz			MouseFound
 	WriteStr		'Mouse not present!'
 	WriteCRLF
	jmp			Finished
MouseFound:
	push			ax
	TextColor		clYellow
 	WriteStr		'Hello world!'
	TextColor		original
 	WriteCRLF
 	pop			ax
	WriteHexByte		al
 	WriteStr		' button mouse found.'
 	WriteCRLF
	MouseShow

MainLoop:
	GotoXY			0x0300
	WriteHexByte 		[Mouse_Position_X]
	WriteChar		'/'
	WriteHexByte		[Mouse_Position_Y]
	WriteChar		':'
	mov			al, [Mouse_Button_State]
	add			al, '0'
	WriteChar		al
	KeyPressed		CheckKeyPress
	jmp			MainLoop

CheckKeyPress:
	; Just purge and exit
	ReadKey			ax
	KeyPressed		CheckKeyPress

	WriteCRLF		2
	TextColor		clCyan
	WriteStr		'good bye.'
	WriteCRLF

%endif

Finished:
;	VideoResetSettings
	Terminate		0 ; Automatically includes used LIB functions

; 	Include_LIB_Functions	; Include any additional LIB functions