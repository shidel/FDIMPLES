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

	Memory			2, 16	; Stack 4k, Minimum Heap 16k

	StdOutHexWord		sp
	StdOutCRLF

%idefine MAX_PTRS 3 ;  4096

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
	StdOutCRLF

	mov	cx, MAX_PTRS
StepOne:
	mov			bx, 1
	mov			bx, cx
	add			bx, cx
	add			bx, cx
	add			bx, cx
	add			bx, cx
	push			cx
	call			AllocBlock
	pop			cx
	loop			StepOne
	DebugHeapPtrs

StepTwo:
	loddax
	lodreg			bx
	test 			dx, dx
	jz			StepThree
	call			FreeBlock
	jmp			StepTwo

StepThree:
	StdOutCRLF
	StdOutStr		'Peak Memory Used: '
	HeapPeakUsed		dx:ax
	StdOutUIntDWord		dx:ax
	StdOutCRLF
	StdOutHexWord		sp
	StdOutCRLF

Finished:
	Terminate		0 ; Automatically includes used LIB functions

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
	StdOutCRLF		2
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


