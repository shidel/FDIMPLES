; Basic Memory Functions for DOS
; Similar (but a little different) to a Pascal DOS unit.

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
%include "FEATURES.INC"
%include "NASMEXT.INC"
; *****************************************************************************
%ifndef DOSMEM_INC_DEFINED
%define DOSMEM_INC_DEFINED
; -----------------------------------------------------------------------------
%imacro SECTION_MEMORY 0

Include_LIB_Functions	  ; Ensure all macro proc code has been compiled.

SECTION_BSS

PROGRAM_MEMORY_REGION:
	resw 0

__?SECT?__

SECTION_STACK
SECTION_HEAP

%endmacro
; -----------------------------------------------------------------------------
%imacro Memory 2

	; COM file, SS is already CS
	; The stack will need it's own segment if compiling to EXE.

	; We may want to free all memory and reallocate a the STACK and HEAP
	; into their own fresh segments.  That would permit a large stack and
	; large code segment.

	; Also, that would allow the "heap" to exist elsewhere. For example,
	; if the program was loaded high. The Heap could be in low memory.



	%ifdef MEMORY_REQUIREMENTS_DECLARED
		%error Memory requirements can only be delcared once.
	%endif
	%define MEMORY_REQUIREMENTS_DECLARED

	%define STACK_BYTE_SIZE %1 * 1024

	call	CALC_HEAP_SETTINGS

	; figure out seg required for min heap
	mov	bx, %2 * 1024 / 16
	add 	bx, ax

	cmp	cx, bx
	ja	%%Configure_Heap

	; Not enough memory then die
	mov	al, 0x08 ; same as DOS ERROR 8, out of memory
	jmp	OUT_OF_MEMORY_AL
OUT_OF_MEMORY:
	mov	al, 0xcb ; same as PASCAL error 203 - heap overflow
OUT_OF_MEMORY_AL:
	Die 	al, 'insufficient memory'
%ifdef Valid_Pointer_Check
VALIDATE_POINTER_PROC:
	push	dx
	test	dx, dx
	jz	INVALID_POINTER
	mov	dx, - HEAP_BLOCK_SIZE - 1 ; basically, not HEAP_BLOCK_SIZE bits
	test	ax, dx
	jnz	INVALID_POINTER
	pop	dx
	ret
INVALID_POINTER:
	Die	0xcc, 'invalid pointer operation' ; same as PASCAL error 204
%endif

CALC_HEAP_SETTINGS:
	; figure out segment of HEAP
	mov	ax, HEAP_MEMORY_BEGIN ; Why not / 16 + 1 as a constant...
	mov	cl, 4
	shr	ax, cl
	inc	ax
	push	cs
	pop	cx
	add	ax, cx

	; check max seg avail to program against requirements
	mov	cx, [0x0002]
	dec	cx
	ret

STORE_HEAP_SETTINGS:
	mov	[HEAP_CONTROL.TOP + 2], ax
	mov	[HEAP_CONTROL.BOTTOM + 2], ax
	push 	cx
	xchg	ax, cx
	sub	ax, cx
	mov	cx, 16
	mul	cx
	mov	[HEAP_CONTROL.FREE], ax
	mov	[HEAP_CONTROL.FREE + 2], dx
	mov	[HEAP_CONTROL.FREETOP], ax
	mov	[HEAP_CONTROL.FREETOP + 2], dx
	pop	cx
	xor	ax, ax
	mov	[HEAP_CONTROL.TOP], ax
	mov	[HEAP_CONTROL.BOTTOM], ax
	mov	[HEAP_CONTROL.FIRST], ax
	mov	[HEAP_CONTROL.FIRST + 2], ax
	mov	[HEAP_CONTROL.USED], ax
	mov	[HEAP_CONTROL.USED + 2], ax
	mov	[HEAP_CONTROL.FREEBLK], ax
	mov	[HEAP_CONTROL.FREEBLK + 2], ax
	ret

%%Configure_Heap:
	call 	STORE_HEAP_SETTINGS
	mov	[HEAP_CONTROL.LIMIT + 2], cx
	mov	[HEAP_CONTROL.LIMIT], ax
	mov	[HEAP_CONTROL.PEAK], ax
	mov	[HEAP_CONTROL.PEAK + 2], ax
	mov	[HEAP_CONTROL.FAIL], ax
	mov	[HEAP_CONTROL.FAIL + 2], ax

%%Configure_Stack:
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

%imacro ValidatePointer 1
%ifdef Valid_Pointer_Check
	isregpair %1
	%ifnidni %1, dx:ax
		pushm dx, ax
	%endif
	%ifdef REGISTER_PAIR_HIGH
		movndef dx, REGISTER_PAIR_HIGH, ax, REGISTER_PAIR_LOW
	%else
		mov dx, [%1 + 2]
		mov ax, [%1]
	%endif
	call	VALIDATE_POINTER_PROC
	%ifnidni %1, dx:ax
		popm dx, ax
	%endif
%endif
%endmacro
; -----------------------------------------------------------------------------
%else
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
%endif
; *****************************************************************************
; List of macros and functions provided by this file.
; Note: Macros often have have preferred register to use when passing when
; passing them a parameter. Using the preferred register will result in saving
; a few bytes of code. However, it is not required.

%include "MEMORY/STACKMEM.INC"

%include "MEMORY/HEAPMEM.INC"

%include "MEMORY/XMSMEM.INC"

%include "MEMORY/EMSMEM.INC"
