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
; COM file, SS is already CS

; We may want to free all memory and reallocate a the STACK and HEAP
; into their own fresh segments.  That would permit a large stack and
; large code segment.

; Also, that would allow the "heap" to exist elsewhere. For example,
; if the program was loaded high. The Heap could be in low memory.

; So, I'll probably do that at some point.
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

%ifdef InitStack_DECLARED
	SECTION_STACK
%endif

SECTION_BSS

PROGRAM_DATA_REGION:
	resw 0

__?SECT?__

%ifdef InitHeap_DECLARED
	SECTION_HEAP
%endif

%endmacro
; -----------------------------------------------------------------------------
%macro Die_OutOfMemory_INTERNAL 0

SECTION_PROC

INSUFFICIENT_MEMORY:
	; Not enough memory then die
	mov	al, 0x08 ; same as DOS ERROR 8, out of memory
	jmp	OUT_OF_MEMORY_AL
OUT_OF_MEMORY:
	mov	al, 0xcb ; same as PASCAL error 203 - heap overflow
OUT_OF_MEMORY_AL:
	Die 	al, 'insufficient memory'

__?SECT?__

%endmacro

%macro ValidatePointer_INTERNAL 0

SECTION_PROC

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

__?SECT?__

%endmacro

%imacro ValidatePointer 1
%ifdef Valid_Pointer_Check

	PROC_REQUIRE ValidatePointer

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
	PROC_PROVIDE Die_OutOfMemory
	PROC_PROVIDE ValidatePointer
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
