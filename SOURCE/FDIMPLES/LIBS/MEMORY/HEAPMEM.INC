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

%ifndef HEAPMEM_INC_DEFINED
%define HEAPMEM_INC_DEFINED
; *****************************************************************************
%imacro SECTION_HEAP 0

SECTION_BSS

HEAP_MEMORY_LIMIT: ; Pointer to last memory location available to program
	resd 1
HEAP_MEMORY_TOP:   ; Pointer to first free block above allocated space
	resd 1
HEAP_MEMORY_USED:  ; Current total heap memory in use
	resd 1
HEAP_FIRST_FREE:   ; Pointer to next free block
	resd 1
HEAP_TOTAL_FREE:
	resd 1	   ; Total amount of free space in heap
HEAP_PEAK_USED:
	resd 1	   ; Max amount of used heap during program execution

HEAP_MEMORY_BEGIN: ; All of the heap
	resb 0

__?SECT?__

%endmacro

%imacro RESET_HEAP 0
	RegsPreserve	ax, cx, dx
	call 	CALC_HEAP_SETTINGS
	call	STORE_HEAP_SETTINGS	; For now, it does not reset the HEAP
					; MEMORY LIMIT. If the program memory
					; block wa resized. It will need
					; adjusted.
					; Also, HEAP PEAK USED is not reset.
	RegsRestore 	ax, cx, dx
%endmacro

%imacro HeapAvail 1-2
	%ifidni %1, dx:ax
		movndef		ax, [HEAP_TOTAL_FREE]
		movndef		dx, [HEAP_TOTAL_FREE + 2]
	%else
		RegsPreserve 	dx, ax
		movndef		%2, [HEAP_TOTAL_FREE]
		movndef		%1, [HEAP_TOTAL_FREE + 2]
		RegsRestore 	dx, ax
	%endif
%endmacro

%imacro HeapUsed 1-2
	%ifidni %1, dx:ax
		movndef		ax, [HEAP_TOTAL_FREE]
		movndef		dx, [HEAP_TOTAL_FREE + 2]
	%else
		RegsPreserve 	dx, ax
		movndef		%2, [HEAP_TOTAL_FREE]
		movndef		%1, [HEAP_TOTAL_FREE + 2]
		RegsRestore 	dx, ax
	%endif
%endmacro

%imacro HeapPeak 1-2
	%ifidni %1, dx:ax
		movndef		ax, [HEAP_TOTAL_FREE]
		movndef		dx, [HEAP_TOTAL_FREE + 2]
	%else
		RegsPreserve 	dx, ax
		movndef		%2, [HEAP_TOTAL_FREE]
		movndef		%1, [HEAP_TOTAL_FREE + 2]
		RegsRestore 	dx, ax
	%endif
%endmacro
; *****************************************************************************
%else
	; PROC_PROVIDE ReleaseHeap
%endif
