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

%ifndef STACKMEM_INC_DEFINED
%define STACKMEM_INC_DEFINED
; *****************************************************************************
; -----------------------------------------------------------------------------
%imacro SECTION_STACK 0

SECTION_BSS

%ifdef Stack_Overflow_Check
STACK_MEMORY_PEAK:
	resw 0

STACK_SAFTEY_NET:
	resw 64

STACK_OVERFLOW_DATA:
	resw 2
%endif

STACK_MEMORY_BEGIN:

	resb STACK_BYTE_SIZE

STACK_MEMORY_END:

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
%macro StackCheck_INTERNAL 0

SECTION_PROC

StackCheck_PROC:
	pushf
	push	ax
	cmp	sp, STACK_MEMORY_BEGIN
	jb	%%Stack_Overflow
	cmp	sp, [STACK_MEMORY_PEAK]
	jae	%%Test_for_Overflow
	mov	[STACK_MEMORY_PEAK], sp
%%Test_for_Overflow:
	push	cs
	pop	ax
	xor	ax, STACK_OVERFLOW_DATA
	cmp	[STACK_OVERFLOW_DATA], ax
	jb	%%Stack_Overflow
	not	ax
	cmp	[STACK_OVERFLOW_DATA + 2], ax
	jb	%%Stack_Overflow
	pop	ax
	popf
	ret
%%Stack_Overflow:
	mov	sp, STACK_MEMORY_END
	Die 	0xca, '!! STACK OVERFLOW ERROR !!' ; same as PASCAL error 202

__?SECT?__

%endmacro

%imacro StackCheck 0

%ifdef STACK_OVERFLOW_TESTING
	PROC_REQUIRE	StackCheck
	call		StackCheck_PROC
%endif

%endmacro
; -----------------------------------------------------------------------------
%imacro StackAvail 1
	StackCheck
	%ifnidni %1, ax
		push	ax
	%endif
	mov  ax, sp
	sub  ax, STACK_MEMORY_BEGIN
	movndef  %1, ax
	%ifnidni %1, ax
		pop	ax
	%endif
%endmacro

%imacro StackUsed 1
	StackCheck
	%ifnidni %1, ax
		push	ax
	%endif
	mov  ax, STACK_MEMORY_END
	sub  ax, sp
	movndef  %1, ax
	%ifnidni %1, ax
		pop	ax
	%endif
%endmacro

%imacro StackPeak 1
	StackCheck
	%ifnidni %1, ax
		push	ax
	%endif
	mov  ax, STACK_MEMORY_END
	sub  ax, [STACK_MEMORY_PEAK]
	movndef  %1, ax
	%ifnidni %1, ax
		pop	ax
	%endif
%endmacro
; -----------------------------------------------------------------------------
%imacro InitStack 1
	%ifdef InitStack_DECLARED
		%error Memory stack and requirements can only be initialized once.
	%endif
	%define InitStack_DECLARED

	%define STACK_BYTE_SIZE %1 * 1024

	PROC_REQUIRE Die_OutOfMemory

	; figure out seg required to make sure stack will fit
	mov	ax, STACK_MEMORY_END
	mov	cl, 4
	shr	ax, cl
	inc	ax
	push	cs
	pop	bx
	add 	ax, bx
	cmp	[cs:0x0002], ax
	jbe	INSUFFICIENT_MEMORY

	mov	sp, STACK_MEMORY_END

	%ifdef Stack_Overflow_Check
		%define STACK_OVERFLOW_TESTING
		push	cs
		pop	ax
		xor	ax, STACK_OVERFLOW_DATA
		mov	[STACK_OVERFLOW_DATA], ax
		not	ax
		mov	[STACK_OVERFLOW_DATA + 2], ax
		mov	ax, STACK_MEMORY_END
		mov	[STACK_MEMORY_PEAK], ax
	%else
		%undef STACK_OVERFLOW_TESTING
	%endif

%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE	StackCheck

%endif
