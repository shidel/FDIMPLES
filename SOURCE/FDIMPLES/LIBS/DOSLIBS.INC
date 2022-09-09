; LIBS for DOS
; Similar (but a little different) to a Pascal CRT unit.

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
%ifndef DOSLIBS_INC_DEFINED
%define DOSLIBS_INC_DEFINED

	%macro DOSLIBS_INCLUDE_ALL 0
		%include "NASMEXT.INC"
		%include "FEATURES.INC"
		%include "DATAOUT.INC"
		%include "DOSSYS.INC"
		%ifndef NO_VIDEO_SUPPORT
			%include "CRT.INC"
		%endif
		%include "MEMORY.INC"
	%endmacro

	%imacro Include_LIB_Functions 0
		; At present, sometimes more than one inclusion pass is required
		; for all required macro PROC code to be included. Yes, there
		; could be optimizations and code rearranged so only 1 pass is
		; needed. But, don't have the time or energy for that now.
		; Maybe later sometime. A couple passes through and all the
		; requirements should sort themselves out nicely.
		%rep 2
			DOSLIBS_INCLUDE_ALL
		%endrep
	%endmacro

%endif

%ifndef DOSLIBS_INCLUDED_DEFINED
	DOSLIBS_INCLUDE_ALL
	%define DOSLIBS_INCLUDED_DEFINED
%endif

%ifndef EXIT_PROCS_DEFINED
%define EXIT_PROCS_DEFINED
%macro  EXIT_PROCS_INTERNAL 0
%define EXIT_PROCS_INTERNAL_DEFINED

	%ifndef NASMEXT_INC_DEFINED
		%include "NASMEXT.INC"
	%endif

SECTION_PROC

	EXIT_PROCS_PROC:
		xor		ax, ax
		cmp     	[EXIT_PROCS_NEXT], ax
		jnz		%%HasProc
		cmp     	[EXIT_PROCS_NEXT + 2], ax
		jnz		%%HasProc
		mov		ax, [EXIT_CODE]
		ret
	%%HasProc:
		call far  	[EXIT_PROCS_NEXT]
		jmp		EXIT_PROCS_PROC

SECTION_DATA

	EXIT_PROCS_NEXT:	dw 0,0
	EXIT_CODE:		dw 0

__?SECT?__

%endmacro


%imacro  EXIT_PROCS 0

	%ifndef EXIT_PROCS_INTERNAL_DEFINED
		EXIT_PROCS_INTERNAL
	%endif

	call	EXIT_PROCS_PROC

%endmacro

%imacro ADD_EXIT_PROC 1

%ifndef ADD_EXIT_PROC_DEFINED
%define ADD_EXIT_PROC_DEFINED

SECTION_PROC

ADD_EXIT_PROC_PROC:
	push		ax
	mov		ax, [EXIT_PROCS_NEXT]
	mov		[di], ax
	mov		ax, [EXIT_PROCS_NEXT + 2]
	mov		[di + 2], ax
	push		cs
	pop		ax
	mov		[EXIT_PROCS_NEXT + 2], ax
	pop		ax
	mov		[EXIT_PROCS_NEXT], ax
	ret
REMOVE_EXIT_PROC_PROC:
	RegsPreserve	ax
	mov		ax, [di]
	mov		[EXIT_PROCS_NEXT], ax
	mov		ax, [di + 2]
	mov		[EXIT_PROCS_NEXT + 2], ax
	RegsRestore	ax
	ret

%endif

SECTION_BSS

EXIT_PROC_BEFORE_%1:
	resw 2

__?SECT?__

	RegsPreserve 	ax
	push		di
	movndef		ax, %1
	mov		di, EXIT_PROC_BEFORE_%1
	call		ADD_EXIT_PROC_PROC
	pop		di
	RegsRestore 	ax

%endmacro

%imacro REMOVE_EXIT_PROC 1

__?SECT?__

	push		di
	mov		di, EXIT_PROC_BEFORE_%1
	call		REMOVE_EXIT_PROC_PROC
	pop		di

%endmacro

%imacro Die 1-*
	%ifnum %1
		; Don't save, it gets hard coded
	%elifidni %1, al
		push			ax
	%elifidni %1, ah
		push			ax
	%endif

	%ifdef ADD_EXIT_PROC_DEFINED
		EXIT_PROCS
	%endif

	%ifdef MouseInitialize_REQUIRED
		MouseFinalize
	%endif

	%if %0 > 1
		mov	ah, 0x02
		cld
		%if %0 > 2
			mov     cx, %0 - 1
		%endif
		mov	si, %%Messages
		push	cs
		pop	ds
	%%Display:
		lodsb
		test	al, al
		jz	%%DisplayDone
		mov	dl, al
		int	0x21
		jmp	%%Display
	%%DisplayDone:
		mov	dl, 0x0d
		int 	0x21
		mov	dl, 0x0a
		int 	0x21
		%if %0 > 2
			loop	%%Display
		%endif
	%endif

	%ifnum %1
	%elifidni %1, al
		pop			ax
	%elifidni %1, ah
		pop			ax
	%endif

	%ifnum %1
		mov			ax, 0x4c00 + %1
	%else
		mov			ah, 0x4c
		movndef			al, %1
	%endif
	int	0x21

	%if %0 > 1
	%%Messages:
		%rep  %0 - 1
		%rotate 1
			db %1,0
		%endrep
		%rotate 1
	%endif
%endmacro

%endif