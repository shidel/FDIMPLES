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

%ifndef MOUSE_INC_DEFINED
%define MOUSE_INC_DEFINED
; -----------------------------------------------------------------------------
%imacro MouseDataReset_INTERNAL 0

SECTION_PROC

MouseDataReset_PROC:
	RegsPreserve		ax, bx, cx
	mov			[Mouse_Cursor_State], word -1
	mov			ax, Mouse_Buffer_Start
	mov			[Mouse_Buffer_Head], ax
	mov			[Mouse_Buffer_Tail], ax
	xor			ax, ax
	mov			[Mouse_Button_State], ax
	mov			cl, 1
	mov			[Mouse_MinX], ax
	mov			[Mouse_MinY], ax
	mov			al, [Video_MaxX]   ; Max number of Columns - 1
	mov			[Mouse_MaxX], ax
	xor			bh, bh
	mov			bl, 0x04
	cmp			al, 0x28
	jb			%%SetShrX
	mov			bl, 0x03
	cmp			al, 0x50
	jb			%%SetShrX
	mov			bl, 0x02
	cmp			al, 0x84
	jb			%%SetShrX	   ; Probably never set
	mov			bl, 0x01
%%SetShrX:
	mov			[Mouse_DivX], bx
	shr			ax, cl
	mov			[Mouse_Position_X], ax
	mov			al, [Video_MaxY]   ; Max number of Rows - 1
	mov			[Mouse_MaxY], ax
	mov			bl, 0x04
	cmp			al, 0x19
	jb			%%SetShrY
	mov			bl, 0x03
	cmp			al, 0x2b
	jb			%%SetShrY
	mov			bl, 0x02
	cmp			al, 0x32
	jb			%%SetShrY
	mov			bl, 0x01	   ; Probably never set
%%SetShrY:
	mov			[Mouse_DivY], bx
	shr			ax, cl
	mov			[Mouse_Position_Y], ax

	RegsRestore		ax, bx, cx
	ret

SECTION_BSS

Mouse_Button_Count:		resw 1
Mouse_Original_Mask:		resw 1
Mouse_Original_Handler:		resw 2

Mouse_DivX:			resw 1
Mouse_DivY:			resw 1

Mouse_MinX:			resw 1
Mouse_MinY:			resw 1

Mouse_MaxX:			resw 1
Mouse_MaxY:			resw 1

Mouse_Cursor_State:		resw 1
Mouse_CharAttr:			resw 1
Mouse_Button_State:		resw 1
Mouse_Position_X:		resw 1
Mouse_Position_Y:		resw 1

Mouse_Buffer_Head:		resw 1
Mouse_Buffer_Tail:		resw 1
Mouse_Buffer_Start:		resd 16
Mouse_Buffer_End:

__?SECT?__

%endmacro

%imacro MouseDataReset 0

%ifdef Support_Mouse

	PROC_REQUIRE		MouseDataReset

	call 			MouseDataReset_PROC

%endif

%endmacro

; -----------------------------------------------------------------------------
%imacro MouseInitialize_INTERNAL 0

SECTION_PROC

MouseInitialize_PROC:
	RegsPreserve		bx
	%ifdef DOS_BUG_FIXES
		; See -- https://fd.lod.bz/rbil/interrup/io_mouse/330000.html
	%endif
	xor			ax, ax
	int			0x33
	test			ax, ax
	jz			%%SetMouseStatus
	mov			ax, 0x0001		; other than two btns
	cmp			bx, ax
	jbe			%%SetMouseStatus
	inc			ax
	cmp			bx, 0xffff		; sometimes two buttons
	je			%%SetMouseStatus
	mov			ax, bx
%%SetMouseStatus:
	mov			[Mouse_Button_Count], ax
	test			ax, ax
	jz			%%CheckDone			; No mouse found
	; If mouse is present swap out original mouse handler
	RegsPreserve		cx, dx, es
	mov			cx, 0xffff
	push			cs
	pop			es
	mov			dx, MouseHandler_INTERRUPT
	mov			ax, 0x0014
	int			0x33
	mov			[Mouse_Original_Mask], cx
	mov			[Mouse_Original_Handler], dx
	mov			[Mouse_Original_Handler + 2], es
	RegsRestore		cx, dx, es
%%CheckDone:
	RegsRestore		bx
	ret

MouseHandler_INTERRUPT:
; On call
;        AX = Event Flag
;        BX = Button State
;        CX = X coor - ignored
;        DX = Y Coor - ignored
;        SI = X Movement
;        DI = Y Movement

	pushf
	cli
	pushm			ds, ax, cx, dx, si, di

	; Set our data segment
	push			cs
	pop			ds

	; Scale X movement
	xor			dx, dx
	mov			ax, si
	mov			cx, [Mouse_DivX]
	div			cx
	mov			si, ax

	; Scale Y movement
	xor			dx, dx
	mov			ax, di
	mov			cx, [Mouse_DivX]
	div			cx
	mov			di, ax

	; Validate New Mouse X position
	mov			cx, [Mouse_Position_X]
	add			cx, si
	cmp			cx, [Mouse_MinX]
	jge			%%NotLowX
	mov			cx, [Mouse_MinX]
	jmp			%%NotHighX
%%NotLowX:
	cmp			cx, [Mouse_MaxX]
	jle			%%NotHighX
	mov			cx, [Mouse_MaxX]
%%NotHighX:

	; Validate New Mouse Y position
	mov			dx, [Mouse_Position_Y]
	add			dx, di
	cmp			dx, [Mouse_MinY]
	jge			%%NotLowY
	mov			dx, [Mouse_MinY]
	jmp			%%NotHighY
%%NotLowY:
	cmp			dx, [Mouse_MaxY]
	jle			%%NotHighY
	mov			dx, [Mouse_MaxY]
%%NotHighY:

	; Test if mouse moved
	cmp			cx, [Mouse_Position_X]
	jne			%%MouseMoved
	cmp			dx, [Mouse_Position_Y]
	je			%%MouseNotMoved
%%MouseMoved:


%%MouseNotMoved:
	mov			[Mouse_Button_State], bx

	; reset movement counters
	mov			ax, 0x0b
	int			0x33
	popm			ds, ax, cx, dx, si, di
	popf
	retf

__?SECT?__

%endmacro

%imacro MouseInitialize 0

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize

	call 			MouseInitialize_PROC

%endif

%endmacro
; -----------------------------------------------------------------------------
%imacro MouseFinalize_INTERNAL 0

SECTION_PROC

MouseFinalize_PROC:
	cmp     [Mouse_Button_Count], word 0x0000
	je	%%Done
	; If mouse is present then restore original mouse
	RegsPreserve		cx, dx, es
	mov			cx, [Mouse_Original_Mask]
	mov			dx, [Mouse_Original_Handler]
	mov			es, [Mouse_Original_Handler + 2]
	mov			ax, 0x0014
	int			0x33
	RegsRestore		cx, dx, es
%%Done:
	ret

__?SECT?__

%endmacro

%imacro MouseFinalize 0

%ifdef Support_Mouse

	PROC_REQUIRE		MouseFinalize

	call 			MouseFinalize_PROC

%endif

%endmacro
; -----------------------------------------------------------------------------
%imacro PreWriteMouse_INTERNAL 0

SECTION_PROC

PreWriteMouse_PROC:
	nop
	nop
	ret

__?SECT?__

%endmacro

%imacro PreWriteMouse 0-2

%ifdef Support_Mouse

	PROC_REQUIRE		PreWriteMouse

	call 			PreWriteMouse_PROC
%endif

%endmacro
; -----------------------------------------------------------------------------
%imacro PostWriteMouse_INTERNAL 0

SECTION_PROC

PostWriteMouse_PROC:
	nop
	ret

__?SECT?__

%endmacro

%imacro PostWriteMouse 0

%ifdef Support_Mouse

	PROC_REQUIRE		PostWriteMouse

	call 			PostWriteMouse_PROC
%endif

%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE		MouseDataReset
	PROC_PROVIDE		MouseInitialize
	PROC_PROVIDE		MouseFinalize

	PROC_PROVIDE		PreWriteMouse
	PROC_PROVIDE		PostWriteMouse
%endif
