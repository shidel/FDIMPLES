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

; Disable default library code features we don't need or want
%include "FEATURES.INC"
%idefine Preserve_Registers	; Macros preserve all registers when possible
%undef DOSCRT_Range_Check	; Prevent out of bounds coordinate settings
%undef Support_BIOS_Timer	; Use high precision int15 timer if possible
%undef Support_Direct_Video	; Direct video addressing
%undef Support_Mouse		; Mouse support
%undef Video_MCGA		; Check for MCGA support
%undef Video_VGA		; Check for VGA support
%undef Video_VESA		; Check for SuperVGA support

%include "DOSSYS.INC"
%include "DOSCRT.INC"

	TextMode		0x55
	jnc			DisplayStuff
	StdOutStr		'Text mode change error'
	jmp			Finished

DisplayStuff:
	StdOutHexByte		[Video_Mode]
	StdOutCRLF

	mov			cx, 0x06
Boxes:
	push			cx
	mov			ax, [Video_WindMin]
	add			ax, 0x0101
	mov			dx, [Video_WindMax]
	sub			dx, 0x0101
	push			ax
	Window			ax, dx
	pop			ax
	TextBackground 		ah
	ClrScr
	TextColor		original
	GotoXY			0x0001
	StdOutHexWord 		[Video_WindMin]
	StdOutChar		'/'
	StdOutHexWord 		[Video_WindMax]
	Delay 			150
	StdOutChar		'+'
	TextBackground		4
	ClrEOL
	StdOutCRLF
	Delay 			150
	pop			cx
	loop			Boxes

	; WindowMax
	xor			cl, cl
	mov			ch, [Video_WindMaxY]
	sub			ch, [Video_WindMinY]
	push			cx
	GotoXY			cx
	StdOutStr		'Test message-'
	pop			cx
	StdOutHexWord		cx
	GotoXY			0x0100
	TextBackground		1
	mov			cx, 4
DelSome:
	push			cx
	Delay			200
	DelLine
	pop			cx
	loop			DelSome
	TextBackground		2
	mov			cx, 4
InsSome:
	push			cx
	Delay			200
	InsLine
	pop			cx
	loop			InsSome


	jmp			WaitLoop

WaitLoop:
	NotKeypressed		WaitLoop
	ReadKey			ax
	push			ax
	StdOutHexWord		ax
	StdOutCRLF
	pop			ax
	cmp			ax, 0x03
	je			Finished
	cmp			ax, 0x1b
	je			Finished
	mov			cl, 2
	shl			ax, cl
	Sound			ax
	jmp			WaitLoop

Finished:
	NoSound
	ResetVideoSettings

	Terminate		0
