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

%ifndef TEXTMODE_INC_DEFINED
%define TEXTMODE_INC_DEFINED
; -----------------------------------------------------------------------------
; Probes video hardware for card type and current settings. It needs called
; prior to any other DOSCRT macros. However, it can be called multiple times.
; For example, after mode changes. Warning: If VESA is enabled, the macro will
; use a shared temporary buffer in the BSS.
; Registers AX, BX, CX, DX, ES, DI are not preserved.
; MACRO:  ProbeVideoCard 0
; INPUT:  none
; OUTPUT: undefined, sets data in BSS.
; -----------------------------------------------------------------------------
%imacro ProbeVideoCard 0

%ifndef ProbeVideoCard_PROC_DEFINED
	%idefine ProbeVideoCard_PROC_DEFINED

[section .procs]

ProbeVideoCard_PROC:
; Assume at least monochrome MDA
	%ifdef Support_Direct_Video
		mov		[Video_Segment], word 0xb000
	%endif
	mov			[Video_Card], byte Video_MDA

; If color assume at least CGA
	mov			ax, 0x0040
	push 			ax
	pop			es
	mov			al, [es:0x0084]
	mov			[Video_MaxY], al
	mov			ax, [es:0x004a]
	dec			ax
	mov			[Video_MaxX], al
	%ifdef Support_Direct_Video
		mov		ax, [es:0x004c]
		mov		[Video_Regen], ax
		mov		ax, [es:0x004e]
		mov		[Video_Offset], ax
	%endif
	mov			ax, [es:0x0060]
	mov			[Video_Cursor], ax

	mov			al, [es:0x0049]
	mov			[Video_Mode], al
	mov			bh, [es:0x0062]
	mov			[Video_Page], bh
	mov			ah, 0x08
	int			0x10
	mov			[Video_Attr], ah

	mov			ax, [es:0x0063]
	cmp			ax, 0x3d4
	jne			%%ProbeHardware
	%ifdef Support_Direct_Video
		mov		[Video_Segment], word 0xb800
	%endif
	mov			[Video_Card], byte Video_CGA

%%ProbeHardware:

%ifdef Video_VESA
%%ProbeVESA:
; Video BIOS - Get VESA SuperVGA information
; Returns AL=0x4f, if function is supported. AH=0x00 for success.
; Requires SuperVGA.
	push			cs
	pop			es
	mov			di, TEMP_BUFFER_256
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
	mov			al, 0x0018
	mov			[Video_MaxY], al
	jmp			%%Done
%%Identified:
	mov			[Video_Card], dl

%%Done:
	ret


[section .bss]

Video_Card:	resb		1
Video_Options:	resb 		1

%ifdef Support_Direct_Video
	Video_Regen:		resw		1
	Video_Offset:		resw		1
	Video_Segment:		resw		1
%endif

Video_ScreenMax:
Video_MaxX:		resb		1
Video_MaxY:		resb		1

Video_WindMin:
Video_WindMinX:		resb		1
Video_WindMinY:		resb		1

Video_WindMax:
Video_WindMaxX:		resb		1
Video_WindMaxY:		resb		1

Video_Tab:
Video_HTab:		resb		1
Video_VTab:		resb		1

; Initial state of these variables are created by InitialVideoSettings
Video_Cursor:		resw		1
Video_PageAttr:
Video_Attr:		resb		1
Video_Page:		resb		1
Video_Mode:		resb		1

%ifdef Video_VESA
	TempBuffer 256
%endif

%endif

__?SECT?__

	call 			ProbeVideoCard_PROC

%endmacro
; -----------------------------------------------------------------------------
; Probes for current video settings. It needs called prior to any other DOSCRT
; macros. It should really be called only once at startup. That is normally
; handled by DOSCRT.INC.
; Registers AX, BX, CX, DX, ES, DI are not preserved.
; MACRO:  InitialVideoSettings 0
; INPUT:  none
; OUTPUT: undefined, sets data in BSS.
; -----------------------------------------------------------------------------
%imacro InitialVideoSettings 0

%ifndef InitialVideoSettings_PROC_DEFINED
	%idefine InitialVideoSettings_PROC_DEFINED

[section .procs]

InitialVideoSettings_PROC:
	mov			ax, 0x0040
	push 			ax
	pop			es
	mov			ax, [es:0x0060]
	mov			[Initial_Video_Cursor], ax
	mov			al, [es:0x0049]
	mov			[Initial_Video_Mode], al
	mov			bh, [es:0x0062]
	mov			[Initial_Video_Page], bh
	mov			ah, 0x08
	int			0x10
	mov			[Initial_Video_Attr], ah
	ret

[section .bss]

Initial_Video_Cursor:	resw		1
Initial_Video_Attr:	resb		1
Initial_Video_Page:	resb		1
Initial_Video_Mode:	resb		1

%endif

__?SECT?__

	call 			InitialVideoSettings_PROC

%endmacro
; -----------------------------------------------------------------------------
; Changes video mode if needed.
; Registers are not preserved. Automatically calls ProbeVideoSettings to
; update data.
; MACRO:  TextMode 1
; INPUT:  %1 = video mode (prefers al), original returns it to Initial Setting
; OUTPUT: Carry Flag set if error occurred.
; -----------------------------------------------------------------------------
%imacro TextMode 1

%ifndef TextMode_PROC_DEFINED
	%idefine TextMode_PROC_DEFINED

[section .procs]

TextMode_PROC:
	PreWriteMouse
	mov			bx, 0x0040
	push 			bx
	pop			es
	mov			bh, [es:0x0049]
	cmp			bh, al
	je			%%NoModeChange
	xor			ah, ah
	pushm			ax, bx
	int			0x10
	; Must call directly, otherwise NASM may embed the macro's code here
	; Instead of later (where we want it)
	call			ProbeVideoCard_PROC
	call			WindowMax_PROC
	popm			ax, bx
	mov			bh, [es:0x0049]
	cmp			bh, al
	je			%%NoModeChange
	stc
	jmp			%%Done
%%NoModeChange:
	clc
%%Done:
	PostWriteMouse
	ret

%endif

__?SECT?__

	%ifidni %1, original
		mov		al, [Initial_Video_Mode]
	%else
		movndef		al, %1
	%endif
	call 			TextMode_PROC

%endmacro
; -----------------------------------------------------------------------------
; Restores video settings, to original mode, page, and cursor if needed.
; Registers are not preserved. Should probably call before exit. Automatically,
; calls ProbeVideoSettings to update data.
; MACRO:  ResetVideoSettings 0
; INPUT:  none
; OUTPUT: none
; -----------------------------------------------------------------------------
%imacro ResetVideoSettings 0

%ifndef ResetVideoSettings_PROC_DEFINED
	%idefine ResetVideoSettings_PROC_DEFINED

[section .procs]


ResetVideoSettings_PROC:
	TextMode		original
	mov			ah, [es:0x0062]
	mov			al, [Initial_Video_Page]
	cmp			ah, al
	je			%%ResetCursor
	; mov			[Video_Page], al
	mov			ah, 0x05
	int			0x10
%%ResetCursor:
	mov			ax, [es:0x0060]
	mov			cx, [Initial_Video_Cursor]
	cmp			ax, cx
	je			%%Done
	; mov			[Video_Cursor], cx
	mov			ah, 0x01
	int			0x10
%%Done:
	mov			al, [Initial_Video_Attr]
	mov			[Video_Attr], al
	; Must call directly, otherwise NASM may embed the macro's code here
	; Instead of later (where we want it)
	call			ProbeVideoCard_PROC
	ret

%endif

__?SECT?__

	call 			ResetVideoSettings_PROC

%endmacro
; *****************************************************************************
%else
%endif
