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

HEAP_CONTROL:

.FAIL:	; Function to call on allocation failure
	resd 1
.LIMIT:	; Pointer to last memory location available to program
	resd 1
.BOTTOM:; First possible, starting point of heap
	resd 1
.TOP:	; Pointer to first free block above allocated space
	resd 1
.FIRST:	; Pointer to first free block
	resd 1
.PEAK:	; Max amount of used heap during program execution
	resd 1
.USED:  ; Current total heap memory in use
	resd 1
.FREE:	; Total amount of heap memory free space
	resd 1
.FREEBLK:	; Largest free block inside heap
	resd 1
.FREETOP: ; Largest free block on top  of heap
	resd 1

HEAP_MEMORY_BEGIN: ; All of the heap is past here. Starts at next paragraph.
	resb 0

__?SECT?__

%endmacro

%macro DebugHeapPtrs_INTERNAL 0

SECTION_PROC

DebugHeapPtrs_PROC:
	DebugText	'LIMIT: '
	DebugPointer	HEAP_CONTROL.TOP
	DebugText	'  TOP:    '
	DebugPointer	HEAP_CONTROL.TOP
	DebugText	'  FREE TOP: 0x'
	DebugHexWord	[HEAP_CONTROL.FREETOP + 2]
	DebugHexWord	[HEAP_CONTROL.FREETOP]
	DebugCRLF
	DebugText	'BASE:  '
	DebugPointer	cs,HEAP_MEMORY_BEGIN
	DebugText	'  BOTTOM: '
	DebugPointer	HEAP_CONTROL.BOTTOM
	DebugText	'  FREE BLK: 0x'
	DebugHexWord	[HEAP_CONTROL.FREEBLK + 2]
	DebugHexWord	[HEAP_CONTROL.FREEBLK]
	DebugText	'  FIRST: '
	DebugPointer	HEAP_CONTROL.FIRST
	DebugCRLF
	ret

__?SECT?__

%endmacro

%imacro DebugHeapPtrs 0
	PROC_REQUIRE DebugHeapPtrs
	call 	DebugHeapPtrs_PROC
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

%imacro HeapMemAvail 1
	RegisterPair	%1
	mov		REGISTER_PAIR_LOW, [HEAP_CONTROL.FREE]
	mov		REGISTER_PAIR_HIGH, [HEAP_CONTROL.FREE + 2]
%endmacro

%macro HeapMaxAvail_INTERNAL 0

SECTION_PROC

HeapMaxAvail_PROC:
	loddax		HEAP_CONTROL.FREETOP
	cmpdax		HEAP_CONTROL.FREEBLK
	ja		%%NotLargerInside
	loddax		HEAP_CONTROL.FREEBLK
%%NotLargerInside:
	ret

__?SECT?__

%endmacro

%imacro HeapMaxAvail 1
	PROC_REQUIRE 	HeapMaxAvail
	RegisterPair	%1
	%ifnidni %1, dx:ax
		RegsPreserve dx, ax
	%endif
	call		HeapMaxAvail_PROC
	movndef		REGISTER_PAIR_HIGH, dx, REGISTER_PAIR_LOW,  ax
	%ifnidni %1, dx:ax
		RegsRestore dx, ax
	%endif
%endmacro

%imacro HeapMemUsed 1
	RegisterPair	%1
	mov		REGISTER_PAIR_LOW,  [HEAP_CONTROL.USED]
	mov		REGISTER_PAIR_HIGH, [HEAP_CONTROL.USED + 2]
%endmacro

%imacro HeapPeakUsed 1
	RegisterPair	%1
	mov		REGISTER_PAIR_LOW,  [HEAP_CONTROL.PEAK]
	mov		REGISTER_PAIR_HIGH, [HEAP_CONTROL.PEAK + 2]
%endmacro

%macro HeapMemory_INTERNAL 0

SECTION_PROC

HeapAlloc_PROC:
	; in cx is size, out dx:ax is pointer
	call		BlockAdjustSize

	loddax		HEAP_CONTROL.FREEBLK
	cmpdax		cx
	jb		%%NoReuseBlock
	; Find Block inside heap
	ret
%%NoReuseBlock:
	; Try block on top of heap
	loddax		HEAP_CONTROL.FREETOP
	cmpdax		cx
	jb		OUT_OF_MEMORY
	; Put on top of heap
	subdax		cx
	stodax		HEAP_CONTROL.FREETOP
	loddax		HEAP_CONTROL.TOP
	pushm		dx, ax
	adddax		cx
	stodax		HEAP_CONTROL.TOP

	; Adjust FREE, USED and PEAK counters
	loddax		HEAP_CONTROL.FREE
	subdax		cx
	stodax		HEAP_CONTROL.FREE
	loddax		HEAP_CONTROL.USED
	adddax		cx
	stodax		HEAP_CONTROL.USED
	cmpdax		HEAP_CONTROL.PEAK
	jbe		%%NoPeakChange
	stodax		HEAP_CONTROL.PEAK
%%NoPeakChange:
	popm		dx,ax
	; Adjust pointer SEG:OFS to lowest OFS from a SEG
	resegptr	dx:ax
	ret

HeapRelease_PROC:
	; Assumption no pointers in heap can live at segment 0.
	; in cx is size, out dx:ax is null pointer
	pushm		es,di,bx,si
	ValidatePointer dx:ax
	call		BlockAdjustSize
	xor		bx, bx
	mov		si, bx				; Prev free block null
	les		di, [HEAP_CONTROL.FIRST]	; load first free block
%%FindHeapSlot:
	; Search chain for previous and next blocks
	DebugChar	' ', '?', ' '
	DebugPointer	bx:si
	DebugChar	'/'
	DebugPointer	es:di
	testes		es
	jz		%%FindSlotFound
	cmpdax		es:di
	jb		%%FindSlotFound
	mov		bx, es
	mov		si, di
	les		di, [es:di]
	jmp		%%FindHeapSlot
%%FindSlotFound:
	; bx:si = prev block or null
	; dx:ax = block to free, cx = block size
	; es:di = next block or null
	DebugChar	' ', '=', ' ', 'P'
	DebugPointer	bx:si
	DebugChar	',','N'
	DebugPointer	es:di
	DebugChar	'>'

	cld
	; store next block pointer and block size in block to free
	xchges		dx
	xchg		di, ax			; swap es:di and dx:ax
	push		di

	DebugText	'(BLK,'
	DebugPointer	es:di
	DebugChar	'='
	DebugPointer	bx:si
	DebugChar	')', '['
	stodax					; save next block pointer
	DebugPointer	es:di
	DebugChar	'='
	DebugHexWord	cx
	DebugChar	']'
	storeg		cx			; save block size
	pop		di			; es:di is block to free
	DebugCRLF

	xchges		bx
	xchg		si, di			; swap es:di and bx:si
	testes		es			; is previous block NULL ?
	jz		%%IsFirstBlock		; then don't set a pointer
	DebugText	'NF,('
	DebugPointer	es:di
	DebugChar	'='
	DebugPointer	bx:si
	DebugChar	')',' '


	mov		[es:di], si
	mov		[es:di + 2], bx		; save block ptr in previous
						; es:di points to first block
	jmp		%%FindChainEnd
%%IsFirstBlock:
	DebugText	'FB,('
	DebugPointer	bx:si
	DebugChar	')'
	mov		[HEAP_CONTROL.FIRST+ 2], bx
	mov		[HEAP_CONTROL.FIRST], si

%%FindChainEnd:


%%HeapFreeDone:
	DebugChar	'!', ' '
	xor		dx, dx
	xor		ax, ax
	popm		es,di,bx,si
	ret

BlockAdjustSize:
	; in cx is requested bytes, out cx is bytes required that is rounded up
	; by HEAP_BLOCK_SIZE. )
	pushm		dx, ax
	mov		ax, - HEAP_BLOCK_SIZE
	mov		dx, cx
	and		dx, ax
	mov		ax, HEAP_BLOCK_SIZE - 1
	and		ax, cx
	jz		%%SizeIsEven
	add		dx, HEAP_BLOCK_SIZE
%%SizeIsEven:
	mov		cx, dx
	popm		dx, ax
	ret
__?SECT?__

%endmacro

%imacro HeapAlloc 2

	PROC_REQUIRE HeapMemory

	%ifnidni %2, cx
		RegsPreserve	cx
		mov	cx, %2
	%endif
	RegisterPair	%1
	%ifnidni %1, dx:ax
		RegsPreserve	dx, ax
	%endif
	call		HeapAlloc_PROC

	movndef		REGISTER_PAIR_LOW,  ax,	REGISTER_PAIR_HIGH, dx
	%ifnidni %1, dx:ax
		RegsRestore	dx, ax
	%endif
	%ifnidni %2, cx
		RegsRestore	cx
	%endif
%endmacro

%imacro HeapRelease 2
	PROC_REQUIRE HeapMemory
	RegisterPair	%1
	%ifnidni %2, cx
		RegsPreserve	cx
		mov	cx, %2
	%endif
	RegisterPair	%1
	%ifnidni %1, dx:ax
		RegsPreserve	dx, ax
	%endif
	call		HeapRelease_PROC

	movndef		REGISTER_PAIR_LOW,  ax,	REGISTER_PAIR_HIGH, dx
	%ifnidni %1, dx:ax
		RegsRestore	dx, ax
	%endif
	%ifnidni %2, cx
		RegsRestore	cx
	%endif
%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE DebugHeapPtrs
	PROC_PROVIDE HeapMaxAvail
	PROC_PROVIDE HeapMemory
%endif
