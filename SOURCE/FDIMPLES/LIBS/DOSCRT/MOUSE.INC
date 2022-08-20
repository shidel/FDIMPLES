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
; Most of the stuff in this file is overhead required to support the mouse and
; does not need direct interaction by the end user (programmer/developer).
; Look for the end-user section bellow.
; -----------------------------------------------------------------------------
%idefine Mouse_Buffer_Struc_Size 4 ; 1 word + 2 bytes per event buffer entry

%imacro MouseDataReset_INTERNAL 0

SECTION_PROC

MouseDataReset_PROC:
	RegsPreserve		ax, bx, cx, dx
	mov			[Mouse_Cursor_State], word -1
	mov			ax, Mouse_Buffer_Start
	mov			[Mouse_Buffer_Head], ax
	mov			[Mouse_Buffer_Tail], ax
	xor			ax, ax
	mov			[Mouse_Move_Flag], al
	mov			[Mouse_Button_State], ax
	mov			cl, 1
	mov			[Mouse_MinX], ax
	mov			[Mouse_MinY], ax

	; Figure out X related values
	xor			ah, ah
	mov			bh, ah
	mov			al, [Video_MaxX]   ; Max number of Columns - 1
	mov			bl, 0x10
	cmp			al, 0x28
	jb			%%SetShrX
	mov			bl, 0x08
	cmp			al, 0x50
	jb			%%SetShrX
	mov			bl, 0x04
	cmp			al, 0x84
	jb			%%SetShrX	   ; Probably never set
	mov			bl, 0x02
%%SetShrX:
	push			ax
	mov			[Mouse_DivX], bx
	mul			bx
	mov			[Mouse_MaxX], ax
	shr			ax, cl
	mov			[Mouse_Value_X], ax
	pop			ax
	shr			ax, cl
	mov			[Mouse_Position_X], ax

	; Figure out Y related values
	; xor			ah, ah	 ; ah should still be 0
	; mov			bh, ah	 ; bh should still be 0
	mov			al, [Video_MaxY]   ; Max number of Rows - 1
	mov			bl, 0x10
	cmp			al, 0x19
	jb			%%SetShrY
	mov			bl, 0x08
	cmp			al, 0x2b
	jb			%%SetShrY
	mov			bl, 0x04
	cmp			al, 0x32
	jb			%%SetShrY
	mov			bl, 0x02	   ; Probably never set
%%SetShrY:
	push			ax
	mov			[Mouse_DivY], bx
	mul			bx
	mov			[Mouse_MaxY], ax
	shr			ax, cl
	mov			[Mouse_Value_Y], ax
	pop			ax
	shr			ax, cl
	mov			[Mouse_Position_Y], ax

	RegsRestore		ax, bx, cx, dx
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
Mouse_Redraw_Flag:		resb 1
Mouse_Move_Flag:		resb 1
Mouse_Button_State:		resw 1

Mouse_Value_X:			resw 1
Mouse_Value_Y:			resw 1
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

	; Adjust mouse X position
	mov			ax, [Mouse_Value_X]
	add			ax, si
	cmp			ax, [Mouse_MinX]
	jge			%%NotLowX
	mov			ax, [Mouse_MinX]
%%NotLowX:
	cmp			ax, [Mouse_MaxX]
	jle			%%NotHighX
	mov			ax, [Mouse_MaxX]
%%NotHighX:
	mov			[Mouse_Value_X], ax
	mov			cx, [Mouse_DivX]
	cwd
	idiv			cx
	push			ax
	; Adjust mouse Y position
	mov			ax, [Mouse_Value_Y]
	add			ax, di
	cmp			ax, [Mouse_MinY]
	jge			%%NotLowY
	mov			ax, [Mouse_MinY]
%%NotLowY:
	cmp			ax, [Mouse_MaxY]
	jle			%%NotHighY
	mov			ax, [Mouse_MaxY]
%%NotHighY:
	mov			[Mouse_Value_Y], ax
	mov			cx, [Mouse_DivY]
	cwd
	idiv			cx
	mov			dx, ax
	pop			cx

	; Test if mouse moved
	cmp			cx, [Mouse_Position_X]
	jne			%%MouseMoved
	cmp			dx, [Mouse_Position_X]
	je			%%MouseNotMoved
%%MouseMoved:
	call			MouseUndraw_PROC
	mov			[Mouse_Position_X], cx
	mov			[Mouse_Position_Y], dx
	call			MouseDraw_PROC
	mov			[Mouse_Move_Flag], byte 0x01

%%MouseNotMoved:
	cmp			bx, [Mouse_Button_State]
	je			%%NoButtonEvent
	mov			[Mouse_Button_State], bx

	; Button event add to buffer
	mov			di, [Mouse_Buffer_Head]
	add			di, Mouse_Buffer_Struc_Size
	cmp			di, Mouse_Buffer_End
	jb			%%BufferNoWrap
	mov			di, Mouse_Buffer_Start
%%BufferNoWrap:
	cmp			di, [Mouse_Buffer_Tail]
	je			%%BufferFull
	mov			[Mouse_Buffer_Head], di
	mov			[di], bx
	mov			[di + 2], cl
	mov			[di + 3], dl

	; jmp			%%DoneBufferAdd
%%BufferFull:
	; Could put something here to note buffer hit limit.

%%DoneBufferAdd:

%%NoButtonEvent:
	; reset movement counters
	mov			ax, 0x0b
	int			0x33
	popm			ds, ax, cx, dx, si, di
	popf
	retf

MouseUndraw_PROC:
	push			ax
	cmp			[Mouse_Cursor_State], word 0x0000
	jl			%%DoneDrawing
	xor			al, al
	jmp			%%MouseDrawing

MouseDraw_PROC:
	push			ax
	cmp			[Mouse_Cursor_State], word 0x0000
	jl			%%DoneDrawing
	mov			al, 0x01
;	jmp			%%MouseDrawing

%%MouseDrawing:
	; AL = 0/1 for Undraw/Draw
	; Basically save then move cursor to mouse position. Then ether
	; read or write charattr. Then move cursor back to previous position.

BIOSorDIRECT MouseDrawing

%ifdef Support_BIOS_Video
MouseDrawing_BIOS:


	pushm			bx, cx, dx
	; Save current cursor position
	%ifdef DOS_BUG_FIXES
		; See -- https://fd.lod.bz/rbil/interrup/video/1003.html#122
		push		ax
	%endif
	mov			bh, [Video_Page]
	mov			ah, 0x03
	int			0x10
	%ifdef DOS_BUG_FIXES
		; See -- https://fd.lod.bz/rbil/interrup/video/1003.html#122
		pop		ax
	%endif
	push			dx
	; Move cursor to mouse position
	mov			dl, [Mouse_Position_X]
	mov			dh, [Mouse_Position_Y]
	; mov			bh, [Video_Page]
	mov			ah, 0x02
	int			0x10
	test 			al, al
	jz			%%DoUndraw
%%DoDraw:
	mov			ah, 0x08 ; fetch char/attr
	; mov			bh, [Video_Page]
	int			0x10
	mov			[Mouse_CharAttr], ax
	not			ah
	and			ah, 0x7f
	jmp			%%SetCharAttr
%%DoUndraw:
	mov			ax, [Mouse_CharAttr]
%%SetCharAttr:
	mov			bl, ah
	mov			ah, 0x09
	mov			cx, 0x0001
	; mov			bh, [Video_Page]
	int			0x10
	; all done, restore cursor position
%%NoWrite:
	pop			dx
	; mov			bh, [Video_Page]
	mov			ah, 0x02
	int			0x10
	popm			bx, cx, dx
%endif

%ifdef BIOS_AND_DIRECT_VIDEO
	jmp			%%DoneDrawing
%endif

%ifdef Support_Direct_Video
MouseDrawing_DIRECT:
	%warning 'MOUSE, direct video support not implemented'
	jmp  MouseDrawing_BIOS
	ret
%endif

%%DoneDrawing:
	pop			ax
	ret



MouseHide_PROC:
	sub			[Mouse_Cursor_State], word 1
	cmp			[Mouse_Cursor_State], word -1
	jne			%%NoStateChange
	push			ax
	xor			al, al
	jmp			%%MouseDrawing

MouseShow_PROC:
	add			[Mouse_Cursor_State], word 1
	cmp			[Mouse_Cursor_State], word 0
	je			MouseDraw_PROC
%%NoStateChange:
	ret

__?SECT?__

%endmacro

%imacro MouseInitialize 0

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize

	call 			MouseInitialize_PROC
	test			[Video_Options], word vcbAutoMouse
	jz			%%NoAutoMouse
	call 			MouseShow_PROC
%%NoAutoMouse:

%endif

%endmacro

%imacro MouseShow 0

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize

	call 			MouseShow_PROC

%endif

%endmacro

%imacro MouseHide 0

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize

	call 			MouseHide_PROC

%endif

%endmacro

; -----------------------------------------------------------------------------
%imacro MouseFinalize_INTERNAL 0

SECTION_PROC

MouseFinalize_PROC:
	cmp     		[Mouse_Button_Count], word 0x0000
	je			%%Done
	; If mouse is present then hide it and restore original mouse
	RegsPreserve		cx, dx, es
	call			MouseHide_PROC
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
	cli
	push			ax
	mov			al, [Mouse_Position_X]
	mov			ah, [Mouse_Position_Y]
	cmp			al, cl
	jb			%%NoUndraw
	cmp			ah, ch
	jb			%%NoUndraw
	cmp			al, dl
	ja			%%NoUndraw
	cmp			ah, dh
	ja			%%NoUndraw
%%DoUndraw:
	mov			[Mouse_Redraw_Flag], byte 1
	call 			MouseUndraw_PROC
	jmp			%%Done

%%NoUndraw:
	mov			[Mouse_Redraw_Flag], byte 0
%%Done:
	pop			ax
	ret

__?SECT?__

%endmacro

%imacro PreWriteMouse 0-2

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize
	PROC_REQUIRE		PreWriteMouse

	pushm		cx, dx
	%if %0 = 0
		mov	cx, [Video_WindMin]
		mov	dx, [Video_WindMax]
	%elif %0 = 1
		movndef	cx, %1, dx, %1
	%else
		movndef	cx, %1, dx, %2
	%endif
	call		PreWriteMouse_PROC
	popm		cx, dx

%endif

%endmacro
; -----------------------------------------------------------------------------
%imacro PostWriteMouse_INTERNAL 0

SECTION_PROC

PostWriteMouse_PROC:
	cmp			[Mouse_Redraw_Flag], byte 0
	je			%%Done
	call 			MouseDraw_PROC
%%Done:
	sti
	ret

__?SECT?__

%endmacro

%imacro PostWriteMouse 0

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize
	PROC_REQUIRE		PostWriteMouse
	call			PostWriteMouse_PROC

%endif

%endmacro
; *****************************************************************************
; The end user bellow section. :-)
; *****************************************************************************
; -----------------------------------------------------------------------------
; Test if mouse has been moved
; MACRO:  MouseMoved 0-1
; INPUT:  %1 = [Optional] jump address if mouse has been moved.
; OUTPUT: Carry Flag Set if mouse has moved. Does not clear movement flag.
; REGS:	  none
; -----------------------------------------------------------------------------
%imacro MouseMoved_INTERNAL 0

SECTION_PROC

MouseMoved_PROC:
	clc
	cmp			[Mouse_Move_Flag], byte 0x00
	jz			%%Done
	stc
%%Done:
	ret

__?SECT?__

%endmacro

%imacro MouseMoved 0-1

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize
	PROC_REQUIRE		MouseMoved
	call			MouseMoved_PROC
	%if %0 = 1
		jc		%1
	%endif

%endif

%endmacro

; -----------------------------------------------------------------------------
; Test if mouse has not moved
; MACRO:  NotMouseMoved 0-1
; INPUT:  %1 = [Optional] jump address if mouse has not moved.
; OUTPUT: Carry Flag Set if mouse has moved. (Same as MouseMoved)
; REGS:	  none
; -----------------------------------------------------------------------------
%imacro NotMouseMoved 0-1

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize
	PROC_REQUIRE		MouseMoved
	call			MouseMoved_PROC
	%if %0 = 1
		jnc		%1
	%endif

%endif

%endmacro
; -----------------------------------------------------------------------------
; Check if mouse has moved and get position.
; MACRO:  ReadMouseMove 1
; INPUT:  none
; OUTPUT:
;	%1 = current mouse screen position (prefers dx)
;	Carry Flag Set if mouse has moved since last ReadMouseMove.
; REGS:	  dx
; -----------------------------------------------------------------------------
%imacro ReadMouseMove_INTERNAL 0

SECTION_PROC

ReadMouseMove_PROC:
	mov			dl, [Mouse_Position_X]
	mov			dh, [Mouse_Position_Y]
	clc
	cmp			[Mouse_Move_Flag], byte 0x00
	jz			%%Done
	mov			[Mouse_Move_Flag], byte 0x00
	stc
%%Done:
	ret

__?SECT?__

%endmacro

%imacro ReadMouseMove 1

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize
	PROC_REQUIRE		ReadMouseMove
	%ifnidni %1, dx
		RegsPreserve	dx
	%endif
	call			ReadMouseMove_PROC
	%ifnidni %1, dx
		movndef		%1, dx
		RegsRestore	dx
	%endif

%endif

%endmacro
; -----------------------------------------------------------------------------
; Test if any mouse button event has occurred and is waiting in the buffer.
; MACRO:  MouseClicked 0-1
; INPUT:  %1 = [Optional] jump address if a mouse button event occurred.
; OUTPUT: Carry Flag Set if mouse has button event is waiting in the buffer.
; REGS:	  ax
; -----------------------------------------------------------------------------
%imacro MouseClicked_INTERNAL 0

SECTION_PROC

MouseClicked_PROC:
	RegsPreserve		ax
	mov			ax, [Mouse_Buffer_Head]
	clc
	cmp			[Mouse_Buffer_Tail], ax
	je			%%Done
	stc
%%Done:
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro MouseClicked 0-1

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize
	PROC_REQUIRE		MouseClicked
	call			MouseClicked_PROC
	%if %0 = 1
		jc		%1
	%endif

%endif

%endmacro

; -----------------------------------------------------------------------------
; Test if no mouse button events are waiting in the buffer.
; MACRO:  NotMouseClicked 0-1
; INPUT:  %1 = [Optional] jump address if a mouse button event has not occurred.
; OUTPUT: Carry Flag Set if a button event is waiting. (Same as MouseClicked)
; REGS:	  ax
; -----------------------------------------------------------------------------
%imacro NotMouseClicked 0-1

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize
	PROC_REQUIRE		MouseClicked
	call			MouseClicked_PROC
	%if %0 = 1
		jnc		%1
	%endif

%endif

%endmacro
; -----------------------------------------------------------------------------
; Check if mouse button event has occurred and remove it from the buffer.
; Generally, this is the only mouse macro you will absolutely need to use.
; However, if you want to do things like hover-over highlighting. You will
; also may to use the MouseMove/ReadMouseMove macros to simplify the code.
; MACRO:  ReadMouseClick 2
; INPUT:  none
; OUTPUT:
;	If CarryFlag is true, then...
;	%1 = mouse button status for event (prefers bx)
;	%2 = mouse screen position for event (prefers dx)
;	If Carry Flag is false, then...
;	%1 = current mouse button status (prefers bx)
;	%2 = current mouse screen position (prefers dx)
; REGS:	bx, dx, si
; -----------------------------------------------------------------------------
%imacro ReadMouseClick_INTERNAL 0

SECTION_PROC

ReadMouseClick_PROC:
	cli
	RegsPreserve		si
	mov			si, [Mouse_Buffer_Tail]
	cmp			si, [Mouse_Buffer_Head]
	je			%%NoEvent
	add			si, Mouse_Buffer_Struc_Size
	cmp			si, Mouse_Buffer_End
	jb			%%BufferNoWrap
	mov			si, Mouse_Buffer_Start
%%BufferNoWrap:
	mov			[Mouse_Buffer_Tail], si
	mov			bx, [si]
	mov			dl, [si + 2]
	mov			dh, [si + 3]
	stc
	jmp			%%Done
%%NoEvent:
	mov			bx, [Mouse_Button_State]
	mov			dl, [Mouse_Position_X]
	mov			dh, [Mouse_Position_Y]
	clc
%%Done:
	RegsRestore		si
	sti
	ret

__?SECT?__

%endmacro

%imacro ReadMouseClick 2

%ifdef Support_Mouse

	PROC_REQUIRE		MouseInitialize
	PROC_REQUIRE		ReadMouseClick
	%ifnidni %1, bx
		RegsPreserve	bx
	%endif
	%ifnidni %2, dx
		RegsPreserve	dx
	%endif
	call			ReadMouseClick_PROC
	movndef			%1, bx, %2, dx
	%ifnidni %2, dx
		RegsRestore	dx
	%endif
	%ifnidni %1, bx
		RegsRestore	bx
	%endif

%endif

%endmacro

; *****************************************************************************
%else
	PROC_PROVIDE		MouseDataReset
	PROC_PROVIDE		MouseInitialize
	PROC_PROVIDE		MouseFinalize
	PROC_PROVIDE		PreWriteMouse
	PROC_PROVIDE		PostWriteMouse

	PROC_PROVIDE		MouseMoved
	PROC_PROVIDE		ReadMouseMove

	PROC_PROVIDE		MouseClicked
	; PROC_PROVIDE		NotMousewClicked
	PROC_PROVIDE		ReadMouseClick


%endif
