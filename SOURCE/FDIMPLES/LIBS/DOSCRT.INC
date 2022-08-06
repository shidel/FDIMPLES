; CRT for DOS v1.0

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

%idefine Video_MDA 	0
%idefine Video_CGA 	1
%idefine Video_EGA 	2
%idefine Video_MCGA 	3
%idefine Video_VGA 	4

; -----------------------------------------------------------------------------
%imacro ProbeVideoCard 0

[section .procs]

%ifndef ProbeVideoCard_PROC_DEFINED
	%idefine ProbeVideoCard_PROC_DEFINED

ProbeVideoCard_PROC:
; Assume at least monochrome MDA
	mov			[Video_Segment], word 0xb000
	mov			[Video_Card], word Video_MDA

; If color assume at least CGA
	mov			ax, 0x0040
	push 			ax
	pop			es
	mov			ax, [es:0x004a]
	mov			[Video_Columns], ax
	mov			ax, [es:0x0084]
	inc			ax
	mov			[Video_Rows], ax

	mov			ax, [es:0x0063]
	cmp			ax, 0x3d4
	jne			%%ProbeVGA
	mov			[Video_Segment], word 0xb800
	mov			[Video_Card], word Video_CGA

%%ProbeVGA:
; Video BIOS - Video Refresh Control, Enable video refresh
; Returns AL=0x12, if function is supported. Requires VGA or better.
	mov			ax, 0x1200
	mov			bl, 0x36
	int			0x10
	mov			dx, Video_VGA
	cmp			al, 0x12
	je			%%Identified

%%ProbeMCGA:
; Video BIOS - Video Addressing, Enable CPU video addressing
; Returns AL=0x12, if function is supported. Requires MCGA/VGA or better.

	mov			ax, 0x1200
	mov			bl, 0x32
	int			0x10
	mov			dx, Video_MCGA
	cmp			al, 0x12
	je			%%Identified

%%ProbeEGA:
; Video BIOS - Get EGA Info. (AL does not need set, but will clear it anyway)
; If BH is unchanged on return, then EGA or later is not present.
	mov			ax, 0x1200
	mov			bx, 0xff10
	int			0x10
	mov			dx, Video_EGA
	cmp			bh, 0xff
	jne			%%Identified

; Not better than CGA
	mov			ax, 0x0019
	mov			[Video_Rows], ax

	ret

%%Identified:
	mov			[Video_Card], dx
	ret
%endif

[section .bss]

Video_Card:	resw		0
Video_Segment:	resw		0
Video_Rows:	resw		0
Video_Columns:	resw		0

__?SECT?__

	call 			ProbeVideoCard_PROC

%endmacro

; -----------------------------------------------------------------------------

	ProbeVideoCard