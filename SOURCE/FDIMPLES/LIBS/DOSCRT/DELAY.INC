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

%ifndef DELAY_INC_DEFINED
%define DELAY_INC_DEFINED
; -----------------------------------------------------------------------------
; Wait for a period of time to elapse. If Support_BIOS_Timer is enabled,
; it will first attempt to use the BIOS WAIT function. If that fails, it
; will fall back on counting system timer ticks.
; MACRO:  Delay 1
; INPUT:  %1 = Milliseconds to wait, (prefers ax)
; OUTPUT: none
; REGS:   ax, cx, dx
; -----------------------------------------------------------------------------
%macro Delay_INTERNAL 0

SECTION_PROC

Delay_PROC:
	RegsPreserve		cx, dx
	test			ax, ax
	jz			%%Done
	%ifdef Support_BIOS_Timer
		push		ax		; Convert Milli to MicroSeconds
		mov		cl, 0x0a
		shl		ax, cl
		mov		dx, ax
		pop		ax
		push		ax
		mov		cl, 0x06
		shr		ax, cl
		mov		cx, ax
		mov		ah, 0x86	; BIOS Wait (AT,PS or better)
		int		0x15
		pop		ax
		jnc		%%Done		; fails fall back to TimerTick
	%endif
	xor			dx, dx			; Convert MS to tick count
	mov			cx, 55
	div			cx
	cmp			dx, 23
	jb			%%SkipRoundUp
	inc			ax
%%SkipRoundUp:
	test			ax, ax
	jz			%%Done
	pushm			es, di
	mov			cx, ax
	mov			dx, 0x0040
	mov			es, dx
	mov			di, 0x006C
%%NextTick:
	mov			dx, [es:di]
%%WaitTick:
	hlt					; Sleep CPU
	mov			ax, [es:di]
	cmp			dx, ax
	je			%%WaitTick
	loop			%%NextTick
	popm			es, di
%%Done:
	RegsRestore		cx, dx
	ret

__?SECT?__

%endmacro

%imacro Delay 1

	PROC_REQUIRE Delay

	RegsPreserve		ax
	movndef			ax, %1
	call 			Delay_PROC
	RegsRestore		ax

%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE Delay
%endif
