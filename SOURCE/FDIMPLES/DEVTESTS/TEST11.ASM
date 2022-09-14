; FreeDOS Installer (FDI) - My Package List Editor Software

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

use16

cpu 8086

org 0x100

SECTION .text

%include "FEATURES.INC"		; Default DEFINES & options for library macros

; %undef Preserve_Registers
; %undef DOS_BUG_FIXES
; %undef DOSCRT_Range_Check
; %undef Stack_Overflow_Check
; %undef Support_BIOS_Timer
;%undef Support_BIOS_Video
%undef Support_Direct_Video
%undef Support_Mouse
%undef Video_MCGA
%undef Video_VGA
%undef Video_VESA

%include "DOSLIBS.INC"		; One INC to include them all. Some INCS have
				; initialization routines. Some calls for those
				; routines gets inserted automatically. For
				; example DOSCRT requires preparation. If those
				; are not needed, you can save some bytes by
				; including only the required LIBS directly.

	InitStack		1	; Stack 4k
 	InitHeap		16	; Minimum Heap 16k

	DebugText		'SP='
	StdOutHexWord		sp
	StdOutCRLF


%idefine MAX_PTRS 20 ;  4096

	movds   cs
	moves	ds
	xor 	ax, ax
	mov	cx, (MAX_PTRS + 1) * 3
	cld
	mov	di, Ptrs
	mov	si, di
	push	di
	rep 	stosw
	pop	di

Main:
	push		cs
	pop		dx
	StdOutStr	'Code Segment: 0x'
	StdOutHexWord	dx
	StdOutCRLF
	StdOutStr	'Memory Top: 0x'
	mov		ax, [cs:0x0002]
	StdOutHexWord	ax
	StdOutCRLF

	StdOutStr	'Program Memory: '
	sub		ax, dx
	mov		cx, 16
	mul		cx
	StdOutUIntDWord  dx:ax
	StdOutStr	' bytes', CRLF

	StdOutStr	'Heap Offset: cs:0x'
	StdOutHexWord	HEAP_MEMORY_BEGIN
	StdOutCRLF
	call		MemoryStatus
	StdOutCRLF
	StdOutCRLF

	mov		cx, MAX_PTRS
	mov		bx, MAX_PTRS + 1
	sub		bx, cx
	call 		AllocSome
	mov		cx, MAX_PTRS / 2
	call 		FreeSome
	mov		cx, MAX_PTRS
	call 		AllocSome
	call 		FreeSome

Finished:
	StdOutCRLF
	StdOutStr		'Peak Memory Used: '
	HeapPeakUsed		dx:ax
	StdOutUIntDWord		dx:ax
	StdOutCRLF
	DebugText		'SP='
	StdOutHexWord		sp
	StdOutCRLF
	Terminate		0 ; Automatically includes used LIB functions

AllocSome:
	pushm			cx
	mov			di, Ptrs
AllocLoop:
	mov			ax, [cs:di + 2]
	test			ax, ax
	jnz			AllocSkip

	add			bx, 0x10
	pushm			cx, bx
	call			AllocBlock
	popm			cx, bx
AllocNext:
	loop			AllocLoop
	DebugCRLF
	DebugHeapPtrs
	pop			cx
	ret
AllocSkip:
	add			di, 6
	jmp			AllocNext

FreeSomeStats:
	DebugCRLF
	DebugText		'[#'
	DebugHexWord		cx
	DebugChar		','
	DebugPointer		dx:ax
	DebugChar		'.'
	DebugHexWord		bx
	DebugChar		']'
	DebugCRLF
	ret

FreeSome:
	pushm			cx, bx
	mov			si, Ptrs
FreeLoop:
	mov			di, si
	push			cx
	loddax
	lodreg			bx
	call			FreeSomeStats
	mov			si, di
	test 			dx, dx
	jz			.NextPtr
	call			FreeBlock
	xor			dx, dx
	mov			[cs:si + 0], dx
	mov			[cs:si + 2], dx
	call			ShowHeapPtrs
.NextPtr:
	pop			cx
	add			si, 6
	loop			FreeLoop
	call			MemoryStatus
	DebugCRLF
	popm			cx, bx
	ret

FreeSomeAlt:
	pushm			cx, bx
	mov			bx, (MAX_PTRS * 6)
	mov			si, Ptrs
	add			si, bx
.FreeLoop:
	mov			di, si
	push			cx
	loddax
	lodreg			bx
	call			FreeSomeStats
	mov			si, di
	test 			dx, dx
	jz			.NextPtr
	call			FreeBlock
	xor			dx, dx
	mov			[cs:si + 0], dx
	mov			[cs:si + 2], dx
	call			ShowHeapPtrs
.NextPtr:
	pop			cx
	sub			si, 6
	loop			.FreeLoop
	call			MemoryStatus
	DebugCRLF
	popm			cx, bx
	ret

ShowHeapPtrs:
	DebugHeapPtrs
	ret

AllocBlock:
	HeapAlloc		dx:ax, bx
	stodax
	storeg			bx
	call			MemoryStatus
	pushm			dx, ax, bx
	StdOutStr		' -> '
	popm			dx, ax, bx
	call			Ptr_Status
	StdOutCRLF
	ret

FreeBlock:
	call			Ptr_Status
	StdOutStr		' ? '
	HeapRelease		dx:ax, bx
	call			MemoryStatus
	StdOutCRLF
	ret

Ptr_Status:
	push			dx
	push			ax
	StdOutHexWord		dx
	StdOutChar		':'
	pop			ax
	StdOutHexWord		ax
	StdOutChar		'+'
	StdOutHexWord		bx
	pop			dx
	ret

MemoryStatus:
	pushm			dx,ax
	StdOutStr		'Memory: '
	HeapMaxAvail		dx:ax
	StdOutUIntDWord		dx:ax
	StdOutChar		','
	HeapMemAvail		dx:ax
	StdOutUIntDWord		dx:ax
	StdOutChar		'/'
	HeapMemUsed		dx:ax
	StdOutUIntDWord		dx:ax
	popm			dx,ax
	ret

Status_DXAX:
	pushf
	StdOutUIntDWord 	dx:ax
	StdOutStr 		' (0x'
	StdOutHexDWord 		dx:ax
	StdOutChar		')'
	popf
	jnc			.NotCarry
	StdOutChar 		'+'
.NotCarry:
	StdOutCRLF
	ret

SECTION_BSS

Ptrs:
	resq MAX_PTRS + 1

SECTION_MEMORY


