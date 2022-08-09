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


%include "NASMEXT.INC"
%include "DOSSYS.INC"
%include "DOSCRT.INC"

	mov	ax, 0x0000
ProbeModes:
	pushm	ax
	int	0x10
	popm	ax
	xor	dl, dl
	mov	bl, [es:0x0049]
	cmp	al, bl
	jne	.NextMode
	inc	dl
.NextMode:
	xor	bh, bh
	mov	bl, al
	mov	[TEMP_BUFFER_0x80 + bx], dl
	inc	al
	cmp	al, 0x7f
	jbe	ProbeModes

	mov	al, 0x54
	int	0x10

	ProbeVideoCard

	xor 	ah, ah
	mov	al, [Initial_Video_Mode]
	int	0x10

	StdOutStr		'Video Card: '
	StdOutHexByte		[Video_Card]
	StdOutCRLF
	StdOutStr		'Video Mode: '
	StdOutHexByte		[Video_Mode]
	StdOutCRLF
	StdOutStr		'Video Modes: '
	xor			bx, bx
	mov			cx, 0x80
PrintModes:
	mov			al, [TEMP_BUFFER_0x80 + bx]
	test			al, al
	jz			.ModeFalse
	StdOutHexByte		bl
	StdOutChar		' '
.ModeFalse:
	inc			bx
	loop			PrintModes
	StdOutCRLF
	StdOutStr		'Video Page Address: '
	StdOutHexWord		[Video_Segment]
	StdOutChar		':'
	StdOutHexWord		[Video_Offset]
	StdOutCRLF
	StdOutStr		'Video Regen: '
	StdOutHexWord		[Video_Regen]
	StdOutCRLF
	StdOutStr		'Video Display: '
	StdOutHexByte		[Video_Columns]
	StdOutStr		' x '
	StdOutHexByte		[Video_Rows]
	StdOutCRLF

	Terminate		0, 'No Error'

	TempBuffer 		0x80