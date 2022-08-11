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
; Adjusts the window to its maximum size. Does not move cursor.
; MACRO: WindowReset 0
; REGS:  ax
; -----------------------------------------------------------------------------
%imacro WindowReset 0

%ifndef WindowReset_PROC_DEFINED
	%idefine WindowReset_PROC_DEFINED

[section .procs]

WindowReset_PROC:
	RegsPreserve		ax
	mov			ax, [Video_ScreenMax]
	mov			[Video_WindMax], ax
	mov			ax, 0x0101
	mov			[Video_WindMin], ax
	RegsRestore		ax
	ret

%endif

__?SECT?__

	call 			WindowReset_PROC

%endmacro
; -----------------------------------------------------------------------------
; Set the window size. Moves cursor to top/left in window.
; MACRO: Window 2 or 4
; INPUT:
;	%1 = Window MinXY (prefers ax)
;	%2 = Window MaxXY (prefers dx)
; OR:
;	%1 = Window Min X (prefers al)
;	%2 = Window Min Y (prefers ah)
;	%3 = Window Max X (prefers dl)
;	%4 = Window Max Y (prefers dh)
; REGS:  ax, cx, dx
; -----------------------------------------------------------------------------
%imacro Window 2

%ifndef Window_PROC_DEFINED
	%idefine Window_PROC_DEFINED

[section .procs]

Window_PROC:
	%ifdef DOSCRT_Range_Check
		RegsPreserve	cx
		mov		cx, [Video_ScreenMax]
	%%TryAgain:
		cmp		ah, dh
		jbe		%%NoSwapY
		xchg		ah, dh
	%%NoSwapY:
		cmp		al, dl
		jbe		%%NoSwapX
		xchg		al, dl
	%%NoSwapX:
		test		al, al
		jnz		%%OkayX1
		inc		al
		jmp		%%TryAgain
	%%OkayX1:
		test		ah, ah
		jnz		%%OkayY1
		inc		ah
		jmp		%%TryAgain
	%%OkayY1:
		cmp		dl, cl
		jbe		%%OkayX2
		mov		dl, cl
		jmp		%%TryAgain
	%%OkayX2:
		cmp		dh, dh
		jbe		%%OkayY2
		mov		dh, ch
		jmp		%%TryAgain
	%%OkayY2:
	%endif
	mov		[Video_WindMin], ax
	mov		[Video_Where], ax
	mov		[Video_WindMax], dx

	%ifdef DOSCRT_Range_Check
		RegsRestore	cx
	%endif
	ret

%endif

__?SECT?__

	RegsPreserve 	ax, dx
	movndef	     	ax, %1, dx, %2
	call		Window_PROC
	RegsRestore  	ax, dx

%endmacro

%imacro Window 4

%ifndef Window_PROC_DEFINED
	%idefine Window_PROC_DEFINED

[section .procs]

WindowCoord_PROC:
	ret

%endif

__?SECT?__

	RegsPreserve ax, dx
;	movndef	     al, %1, ah, %2, dl, %3, dh, %4
	RegsRestore  ax, dx

%endmacro
