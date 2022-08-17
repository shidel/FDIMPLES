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

%include "FEATURES.INC"		; Default DEFINES for library and options

%undef Preserve_Registers	; Macros preserve all registers when possible
%undef DOSCRT_Range_Check	; Prevent out of bounds coordinate settings
%undef Support_BIOS_Timer	; Use high precision int15 timer if possible
%undef Support_Direct_Video	; Direct video addressing
; %undef Support_Mouse		; Include Mouse support
%undef Video_MCGA		; Check for MCGA support
%undef Video_VGA		; Check for VGA support
%undef Video_VESA		; Check for SuperVGA support

%include "DOSLIBS.INC"		; One INC to include them all. Some INCS have
				; initialization routines. Calls to those
				; routines gets inserted automatically. For
				; example DOSCRT requires preparation. If those
				; are not needed, you can save some bytes by
				; including only the required LIBS directly.


	Window			max
	SetCursor		small
	mov			ax, [Mouse_Button_Count]
	test			ax, ax
	jnz			MouseFound
 	WriteStr		'Mouse not present!'
 	WriteCRLF
	jmp			Finished
MouseFound:
	WriteHexByte		al
 	WriteStr		' button mouse found!'
 	WriteCRLF

Main:
	TextColor		clYellow
 	WriteStr		'Hello world!'
	TextColor		original
 	WriteCRLF
 	WriteHexWord		[Mouse_DivX]
 	WriteCRLF
 	WriteHexWord		[Mouse_DivY]
 	WriteCRLF
WaitKeyPress:
	GotoXY			0x0101
	WriteHexWord 		[Mouse_Position_X]
	WriteChar		'/'
	WriteHexWord		[Mouse_Position_Y]
	WriteChar		':'
	mov			al, [Mouse_Button_State]
	add			al, 'A'
	WriteChar		al
	NotKeyPressed		WaitKeyPress
PurgeKeyPress:
	ReadKey			ax
	KeyPressed		PurgeKeyPress
	GotoXY			[Video_ScreenMax]
Finished:
;	VideoResetSettings
	Terminate		0 ; Automatically includes used LIB functions

; 	Include_LIB_Functions	; Include any additional LIB functions