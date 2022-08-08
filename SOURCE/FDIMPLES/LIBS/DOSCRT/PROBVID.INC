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
; Probes video hardware for card type and current settings. It needs called
; prior to any other DOSCRT macros. However, it can be called multiple times.
; For example, after mode changes.
; Registers AX, BX, CX, DX, ES, DI are not preserved.
; MACRO:  ProbeVideoCard 0
; INPUT:  none
; OUTPUT: undefined, sets data in BSS.
; -----------------------------------------------------------------------------
%imacro ProbeVideoCard 0
; Probes video hardware for card type and current settings. It needs called
; prior to any other DOSCRT macros. However, it can be called multiple times.
; For example, after mode changes.

%ifndef ProbeVideoCard_PROC_DEFINED
	%idefine ProbeVideoCard_PROC_DEFINED

[section .procs]

ProbeVideoCard_PROC:
; Assume at least monochrome MDA
	mov			[Video_Segment], word 0xb000
	mov			[Video_Card], byte Video_MDA

; If color assume at least CGA
	mov			ax, 0x0040
	push 			ax
	pop			es
	mov			ax, [es:0x004a]
	mov			[Video_Columns], al
	mov			ax, [es:0x004c]
	mov			[Video_Page_Size], ax
	mov			ax, [es:0x004e]
	mov			[Video_Offset], ax

	mov			al, [es:0x0049]
	mov			[Video_Mode], al
	mov			al, [es:0x0062]
	mov			[Video_Page], al

	mov			al, [es:0x0084]
	inc			al
	mov			[Video_Rows], al

	mov			ax, [es:0x0063]
	cmp			ax, 0x3d4
	jne			%%ProbeHardware
	mov			[Video_Segment], word 0xb800
	mov			[Video_Card], byte Video_CGA

%%ProbeHardware:

%ifdef Video_VESA
%%ProbeVESA:
; Video BIOS - Get VESA SuperVGA information
; Returns AL=0x4f, if function is supported. AH=0x00 for success.
; Requires SuperVGA.
	push			cs
	pop			es
	mov			di, TEMP_256_BUFFER
	mov			ax, 0x4f00
	int			0x10
	mov			dl, Video_VESA
	cmp			ax, 0x004f
	je			%%Identified
%endif

%ifdef Video_VGA
%%ProbeVGA:
; Video BIOS - Video Refresh Control, Enable video refresh
; Returns AL=0x12, if function is supported. Requires VGA or better.
	mov			ax, 0x1200
	mov			bl, 0x36
	int			0x10
	mov			dl, Video_VGA
	cmp			al, 0x12
	je			%%Identified
%endif

%ifdef Video_MCGA
%%ProbeMCGA:
; Video BIOS - Video Addressing, Enable CPU video addressing
; Returns AL=0x12, if function is supported. Requires MCGA/VGA or better.

	mov			ax, 0x1200
	mov			bl, 0x32
	int			0x10
	mov			dl, Video_MCGA
	cmp			al, 0x12
	je			%%Identified
%endif

%ifdef Video_EGA
%%ProbeEGA:
; Video BIOS - Get EGA Info. (AL does not need set, but will clear it anyway)
; If BH is unchanged on return, then EGA or later is not present.
	mov			ax, 0x1200
	mov			bx, 0xff10
	int			0x10
	mov			dl, Video_EGA
	cmp			bh, 0xff
	jne			%%Identified
%endif

; Not better than CGA
	mov			al, 0x0019
	mov			[Video_Rows], al

	ret

%%Identified:
	mov			[Video_Card], dl
	ret


[section .bss]

Video_Card:		resb		1
Video_Mode:		resb		1
Video_Page:		resb		1
Video_Page_Size:	resw		1
Video_Offset:		resw		1
Video_Segment:		resw		1
Video_Columns:		resb		1
Video_Rows:		resb		1

%ifdef Video_VESA
	%ifndef TEMP_256_BUFFER_DEFINED
		%idefine TEMP_256_BUFFER_DEFINED
		TEMP_256_BUFFER:
			resb	256
	%endif
%endif

%endif

__?SECT?__

	call 			ProbeVideoCard_PROC

%endmacro
