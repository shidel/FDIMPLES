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
	iret


SECTION_BSS

Mouse_Button_Count:		resw 1
Mouse_Original_Mask:		resw 1
Mouse_Original_Handler:		resw 2


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
	mov	dl, '-'
	cmp     [Mouse_Button_Count], word 0x0000
	je	%%Done

	RegsPreserve		cx, dx, es
	mov			cx, [Mouse_Original_Mask]
	mov			dx, [Mouse_Original_Handler]
	mov			es, [Mouse_Original_Handler + 2]
	mov			ax, 0x0014
	int			0x33
	RegsRestore		cx, dx, es

	mov	dl, 'X'

%%Done:
	mov	ah, 0x02
	int	0x21
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

; -----------------------------------------------------------------------------
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
	PROC_PROVIDE		MouseInitialize
	PROC_PROVIDE		MouseFinalize

	PROC_PROVIDE		PreWriteMouse
	PROC_PROVIDE		PostWriteMouse
%endif
