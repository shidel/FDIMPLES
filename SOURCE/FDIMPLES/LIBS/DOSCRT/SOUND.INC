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

%ifndef SOUND_INC_DEFINED
%define SOUND_INC_DEFINED
; -----------------------------------------------------------------------------
; Output sound through PC speaker
; MACRO:  Sound 1
; INPUT:  %1 = Frequency in Hertz (prefers ax)
; OUTPUT: none
; REGS:   ax, cx, dx
; -----------------------------------------------------------------------------
%imacro Sound_INTERNAL 0

SECTION_PROC

Sound_PROC:
	RegsPreserve		ax, cx ,dx
	mov			cx, ax
	cmp			cx, 0x0012
	jbe			%%NoFrequency
	mov			dx, 0x0012
	mov			ax, 0x34dc
	div			cx
	jmp			%%SendSound
%%NoFrequency:
	xor			ax, ax
%%SendSound:
	push			ax
	mov			al, 10110110b
	mov			dx, 0x0043
	out			dx, al
	mov			dx, 0x0042
	pop			ax
	out			dx, al
	mov			al, ah
	out			dx, al
	mov			dx, 0x0061
	in			al, dx
	mov			al, 0x03
	out			dx, al
	RegsRestore		ax, cx, dx
	ret

__?SECT?__

%endmacro

%imacro Sound 1

	PROC_REQUIRE		Sound

	%ifnidni %1, ax
		RegsPreserve	ax
		mov		ax, %1
	%endif
	call 			Sound_PROC
	%ifnidni %1, ax
		RegsRestore	ax
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Turns off PC Speaker
; MACRO:  NoSound 0
; INPUT:  none
; OUTPUT: none
; REGS:   ax, dx
; -----------------------------------------------------------------------------
%imacro NoSound_INTERNAL 0

SECTION_PROC

NoSound_PROC:
	RegsPreserve		ax, dx
	mov			dx, 0x0061
	in			al, dx
	and			al, 11111101b
	out			dx, al
	mov			al, 10110110b
	mov			dx, 0x0043
	out			dx, al
	mov			dx, 0x0042
	xor			al, al
	out			dx, al
	out			dx, al
	RegsRestore		ax, dx
	ret

__?SECT?__

%endmacro

%imacro NoSound 0

	PROC_REQUIRE		NoSound

	call 			NoSound_PROC

%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE		Sound
	PROC_PROVIDE		NoSound
%endif
