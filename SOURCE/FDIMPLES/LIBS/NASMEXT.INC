; Language Extensions and general macros for NASM

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

%ifndef NASMEXT_INC_DEFINED
%define NASMEXT_INC_DEFINED

%include "FEATURES.INC"
; -----------------------------------------------------------------------------
%idefine Ascii_CR 		0x0d
%idefine Ascii_LF 		0x0a
%idefine Ascii_Space		0x20
%idefine Ascii_OpenParenthesis	0x28
%idefine Ascii_CloseParenthesis	0x29
%idefine Ascii_HamburgerMenu	0xf0

%idefine CR 			Ascii_CR
%idefine LF 			Ascii_LF
%idefine CRLF CR,LF
%idefine FALSE 0
%idefine TRUE  1
; -----------------------------------------------------------------------------
%define SECTION_CODE [section .text]
%define SECTION_PROC [section .proc]
%define SECTION_DATA [section .data]
%define SECTION_BSS  [section .bss]

%define CODE_SEGMENT section .text
%define PROC_SEGMENT section .proc
%define DATA_SEGMENT section .data
%define BSS_SEGMENT  section .bss

%assign NEW_SECTION_ID_VALUE 0
%macro NEW_SECTIONS 0
	%assign NEW_SECTION_ID_VALUE NEW_SECTION_ID_VALUE + 1
	%define SECTION_CODE [section .text %+ NEW_SECTION_ID_VALUE]
	%define SECTION_PROC [section .proc %+ NEW_SECTION_ID_VALUE]
	%define SECTION_DATA [section .data %+ NEW_SECTION_ID_VALUE]
	%define CODE_SEGMENT section .text %+ NEW_SECTION_ID_VALUE
	%define PROC_SEGMENT section .proc %+ NEW_SECTION_ID_VALUE
	%define DATA_SEGMENT section .data %+ NEW_SECTION_ID_VALUE
	CODE_SEGMENT
%endmacro

%define NEW_SEGMENTS NEW_SECTIONS

; -----------------------------------------------------------------------------
%imacro movip 1
; mov	ip (+3 bytes) into register.
	call %%ShortCall
%%ShortCall:
	pop	 %1
%endmacro

%imacro movipa 1
; mov	adjusted ip (+0 bytes) into register.
	call %%ShortCall
%%ShortCall:
	pop	%1
	pushf
	sub	%1, 0x0003
	popf
%endmacro

%imacro retz 0
; return if zero flag is set
        jnz	%%Skip
        ret
    %%Skip:
%endmacro

%imacro retnz 0
; return if zero flag is not set
        jz	%%Skip
        ret
    %%Skip:
%endmacro

%imacro rete 0
; return if equal
        jne	%%Skip
        ret
    %%Skip:
%endmacro

%imacro retne 0
; return if not equal
        je	%%Skip
        ret
    %%Skip:
%endmacro

%imacro retc 0
; return if carry flag is set
        jnc	%%Skip
        ret
    %%Skip:
%endmacro

%imacro retnc 0
; return if carry flag is not set
        jc	%%Skip
        ret
    %%Skip:
%endmacro

%imacro pushall 0
; More or les equivalent to pusha
	pushf
	push		ax
	push		bx
	push		cx
	push		dx
	push		si
	push		di
	push		es
	push		ds
	push		bp
%endmacro

%imacro popall 0
; More or les equivalent to popa
	pop		bp
	pop		ds
	pop		es
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
%endmacro

%imacro pushm 0-*
; push a group of registers
	%ifidni %0, 0
		pushall
	%else
		%rep  %0
			push    %1
		%rotate 1
		%endrep
	%endif
%endmacro

%imacro popm 0-*
; pop a group of registers (in reverse order)
	%ifidni %0, 0
		popall
	%else
		%rep %0
		%rotate -1
			pop     %1
		%endrep
	%endif
%endmacro

%imacro poppush 1-*
; Performa a pop and push for each register
	popm	%{1:-1}
	pushm   %{1:-1}
%endmacro

%imacro loddax 	0-1
	%if %0 = 0
		mov		ax, [si]
		mov		dx, [si + 2]
		add		si, 4
	%else
		mov		ax, [%1]
		mov		dx, [%1 + 2]
	%endif
%endmacro

%imacro stodax 	0-1
	%if %0 = 0
		mov		[es:di], ax
		mov		[es:di + 2], dx
		add		di, 4
	%else
		mov		[%1], ax
		mov		[%1 + 2], dx
	%endif
%endmacro

%imacro adddax 	1
	push		cx
	add		ax, [%1]
	pushf
	add		dx, [%1 + 2]
	jc		%%Overflow
	popf
	jnc		%%Done
	inc		dx
	jmp		%%Done
%%Overflow:
	pop		cx
%%Done:
	pop		cx
%endmacro

%imacro subdax 	1
	push		cx
	sub		ax, [%1]
	pushf
	sub		dx, [%1 + 2]
	jc		%%Overflow
	popf
	jnc		%%Done
	dec		dx
	jmp		%%Done
%%Overflow:
	pop		cx
%%Done:
	pop		cx
%endmacro

%imacro cmpdax 	1
	cmp		dx, [%1 + 2]
	jne		%%Done
	cmp		ax, [%1]
%%Done:
%endmacro

; -----------------------------------------------------------------------------
%imacro TempBuffer 1
; Include an extremely temporary application wide shared buffer of %1 bytes
; Care must be taken that multiple functions do not use the buffer while data
; is still needed.
	%ifndef TEMP_BUFFER_%1_DEFINED
		%idefine TEMP_BUFFER_%1_DEFINED

		SECTION_BSS

		TEMP_BUFFER_%1:
			resb	%1

		__?SECT?__

	%endif
%endmacro
; -----------------------------------------------------------------------------
%imacro RegsPreserve 0-*
; Used by macros. When enabled, macros will preserve (push) a list of registers
; they use internally.
	%ifdef Preserve_Registers
		%ifidni %0, 0
			pushall
		%else
			%rep  %0
				push    %1
			%rotate 1
			%endrep
		%endif
	%endif
%endmacro

%imacro RegsRestore 0-*
; Used by macros. When enabled, macros will restore (pop) a list of registers
; they use internally.
	%ifdef Preserve_Registers
		%ifidni %0, 0
			popall
		%else
			%rep %0
			%rotate -1
				pop     %1
			%endrep
		%endif
	%endif
%endmacro

%imacro regpush 0-*
; When Registers are not Preserved, perform push
	%ifndef Preserve_Registers
		%ifidni %0, 0
			pushall
		%else
			%rep  %0
				push    %1
			%rotate 1
			%endrep
		%endif
	%endif
%endmacro

%imacro regpop 0-*
; When Registers are not Preserved, perform pop
	%ifndef Preserve_Registers
		%ifidni %0, 0
			popall
		%else
			%rep %0
			%rotate -1
				pop     %1
			%endrep
		%endif
	%endif
%endmacro
; -----------------------------------------------------------------------------
%imacro regmatch 2-*
; %1 = 16-bit register to check against
; %2+ = 8/16-bit possible matching registers
; REGISTER_MATCH is left defined if it was matched
	%define  REGISTER_MATCH %1
	%undef  REGISTER_MATCH_FLAG
	%rep  %0 - 1
		%rotate 1
		%ifidni REGISTER_MATCH, %1
			%define  REGISTER_MATCH_FLAG
		%elifidni REGISTER_MATCH, ax
			%ifidni %1, al
				%define  REGISTER_MATCH_FLAG
			%elifidni %1, ah
				%define  REGISTER_MATCH_FLAG
			%endif
		%elifidni REGISTER_MATCH, bx
			%ifidni %1, bl
				%define  REGISTER_MATCH_FLAG
			%elifidni %1, bh
				%define  REGISTER_MATCH_FLAG
			%endif
		%elifidni REGISTER_MATCH, cx
			%ifidni %1, cl
				%define  REGISTER_MATCH_FLAG
			%elifidni %1, ch
				%define  REGISTER_MATCH_FLAG
			%endif
		%elifidni REGISTER_MATCH, dx
			%ifidni %1, dl
				%define  REGISTER_MATCH_FLAG
			%elifidni %1, dh
				%define  REGISTER_MATCH_FLAG
			%endif
		%endif
	%endrep
	%ifdef REGISTER_MATCH_FLAG
		%undef  REGISTER_MATCH_FLAG
	%else
		%undef  REGISTER_MATCH
	%endif
%endmacro
; -----------------------------------------------------------------------------
%imacro regtemp 2-*
; 1+ = List of needed 8/16-bit registers
; TEMP_REGISTER is defined as suggested unused register
	%undef   TEMP_REGISTER
	%define  REGISTER_AX_AVAILABLE
	%define  REGISTER_BX_AVAILABLE
	%define  REGISTER_CX_AVAILABLE
	%define  REGISTER_DX_AVAILABLE
	%define  REGISTER_SI_AVAILABLE
	%define  REGISTER_DI_AVAILABLE
	%rep  %0
		%rotate 1
		%ifidni %1, ax
			%undef  REGISTER_AX_AVAILABLE
		%elifidni %1, al
			%undef  REGISTER_AX_AVAILABLE
		%elifidni %1, ah
			%undef  REGISTER_AX_AVAILABLE
		%elifidni %1, bx
			%undef  REGISTER_BX_AVAILABLE
		%elifidni %1, bl
			%undef  REGISTER_BX_AVAILABLE
		%elifidni %1, bh
			%undef  REGISTER_BX_AVAILABLE
		%elifidni %1, cx
			%undef  REGISTER_CX_AVAILABLE
		%elifidni %1, cl
			%undef  REGISTER_CX_AVAILABLE
		%elifidni %1, ch
			%undef  REGISTER_CX_AVAILABLE
		%elifidni %1, dx
			%undef  REGISTER_DX_AVAILABLE
		%elifidni %1, dl
			%undef  REGISTER_DX_AVAILABLE
		%elifidni %1, dh
			%undef  REGISTER_DX_AVAILABLE
		%elifidni %1, si
			%undef  REGISTER_DI_AVAILABLE
		%elifidni %1, di
			%undef  REGISTER_SI_AVAILABLE
		%endif
	%endrep
	%ifdef REGISTER_AX_AVAILABLE
		%define TEMP_REGISTER ax
	%elifdef REGISTER_BX_AVAILABLE
		%define TEMP_REGISTER bx
	%elifdef REGISTER_CX_AVAILABLE
		%define TEMP_REGISTER cx
	%elifdef REGISTER_DX_AVAILABLE
		%define TEMP_REGISTER dx
	%elifdef REGISTER_SI_AVAILABLE
		%define TEMP_REGISTER si
	%elifdef REGISTER_DI_AVAILABLE
		%define TEMP_REGISTER di
	; %else
	;	%error All registers used.
	%endif
	%undef  REGISTER_AX_AVAILABLE
	%undef  REGISTER_BX_AVAILABLE
	%undef  REGISTER_CX_AVAILABLE
	%undef  REGISTER_DX_AVAILABLE
	%undef  REGISTER_DI_AVAILABLE
	%undef  REGISTER_SI_AVAILABLE
%endmacro
; -----------------------------------------------------------------------------
%imacro regtype 1
	%ifidni %1, ax
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, bx
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, cx
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, dx
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, si
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, di
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, bp
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, sp
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, es
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, ds
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, cs
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, ss
		%define REGISTER_TYPE_BITS 16
	%elifidni %1, ah
		%define REGISTER_TYPE_BITS 8
	%elifidni %1, al
		%define REGISTER_TYPE_BITS 8
	%elifidni %1, bh
		%define REGISTER_TYPE_BITS 8
	%elifidni %1, bl
		%define REGISTER_TYPE_BITS 8
	%elifidni %1, ch
		%define REGISTER_TYPE_BITS 8
	%elifidni %1, cl
		%define REGISTER_TYPE_BITS 8
	%elifidni %1, dh
		%define REGISTER_TYPE_BITS 8
	%elifidni %1, dl
		%define REGISTER_TYPE_BITS 8
	%else
		%define REGISTER_TYPE_BITS 0
	%endif
%endmacro
; -----------------------------------------------------------------------------
%imacro movndef 2-*
; MOV if not Default.
; When not the default preferred register, generate a mov (or similar)
; instruction to load the register.
; MOVNDEF ax, ax		 -> NULL
; MOVNDEF ax, bx		 -> mov ax, bx
; MOVNDEF ax, bx, cx, dx	 -> mov ax, bx; mov cx, dx
; MOVNDEF ax, bx, cx, ax 	 -> push ax; mov ax, bx; pop cx
    %ifidni %0, 2
    	%ifnidni %1, %2
    	    mov %1, %2
    	%endif
    %elifidni %0, 4
	%ifidni %1, %4
	    push %4
    	    mov  %1, %2
	    pop  %3
	%else
	    %ifnidni %1, %2
		mov %1, %2
	    %endif
	    %ifnidni %3, %4
		mov %3, %4
	    %endif
	%endif
    %else
	%undef TEMP_REGISTER
        %rep  %0
	    	%ifnum %2
	    		%define TEMP_REGISTER
		%endif
        %rotate 2
        %endrep
	%ifdef TEMP_REGISTER
	    	regtemp %{1:-1}
	    	; %warning Temporary Register TEMP_REGISTER used.
	    	push TEMP_REGISTER
	%endif
        %rep  %0 / 2
	    %ifnidni %1, %2
	    	%ifnum %2
	    		%ifdef TEMP_REGISTER
			    	mov  TEMP_REGISTER, %2
			    	push TEMP_REGISTER
	    		%else
	    			%warning No temprorary register available. PUSH %2 for %1 is not 8086 compatible
				push word %2
	    		%endif
	    	%else
	    		; %warning PUSH %2 for %1
			push %2
		%endif
	    %endif
            %rotate 2
        %endrep
        %rep %0 / 2
	    %rotate -2
	    %ifnidni %1, %2
	    	; %warning POP %1 from %2
		pop %1
	    %endif
        %endrep
	%ifdef TEMP_REGISTER
	    	pop TEMP_REGISTER
	%endif
	%undef TEMP_REGISTER

    %endif
%endmacro
; -----------------------------------------------------------------------------
%imacro PROC_REQUIRE 1
	%ifndef %1_REQUIRED
		%define %1_REQUIRED 0
	%endif
%endmacro

%imacro PROC_PROVIDE 1
	%ifidni %1_REQUIRED, 0
		%define %1_REQUIRED 1
		%1_INTERNAL
	%endif
%endmacro
; -----------------------------------------------------------------------------
%imacro DebugChar 1-*

%ifndef DebugChar_DEFINED
	%define  DebugChar_DEFINED
	jmp	%%Over
DebugChar_PROC:
	pushf
	push			ax
	mov			ah, 0x02
	int			0x21
	pop			ax
	popf
	ret
%endif
%%Over:
	%rep %0
	%ifnidni %1, dl
		push	dx
		movndef dl, %1
		call	 DebugChar_PROC
		pop	dx
	%else
		call	 DebugChar_PROC
	%endif
	%rotate 1
	%endrep

%endmacro

%imacro DebugHexByte 1-*

%ifndef DebugHexByte_DEFINED
	%define  DebugHexByte_DEFINED
	jmp	%%Over
DebugHexByte_PROC:
	pushf
	pushm			dx, cx, ax

	mov			cx, 0x0204	; ch = count, cl = bit rotate
	mov			ah, ch		; mov ah, 0x02
%%Loopy:
	ror			al, cl		; rotate first to do high bits
	mov			dl, al
	and			dl, 0x0f
	add			dl, 0x30	; make numbers ascii numbers
	cmp			dl, 0x39
	jbe			%%Display	; <= to asciii 9
	add			dl, 0x27	; make value ascii letter
%%Display:
	push			ax
	int			0x21
	pop			ax
	dec			ch
	jnz			%%Loopy
	popm			dx, cx, ax
	popf
	ret
%endif

%%Over:
	%rep %0
	%ifnidni %1, al
		push	ax
		movndef al, %1
		call	 DebugHexByte_PROC
		pop	ax
	%else
		call	 DebugHexByte_PROC
	%endif
	%rotate 1
	%endrep

%endmacro

%imacro DebugHexWord 1-*
	%rep %0
	%ifnidni %1, ax
		push	ax
		movndef ax, %1
		DebugHexByte ah, al
		pop	ax
	%else
		DebugHexByte ah, al
	%endif
	%rotate 1
	%endrep
%endmacro

%imacro DebugCRLF 0

%ifndef DebugCRLF_DEFINED
	%define  DebugCRLF_DEFINED
	jmp	%%Over

DebugCRLF_PROC:
	pushf
	pushm			dx, ax
	mov			ah, 0x02
	mov			dl, 0x0d
	int			0x21
	mov			dl, 0x0a
	int			0x21
	popm			dx, ax
	popf
	ret
%endif
%%Over:
	call	DebugCRLF_PROC
%endmacro

%imacro DebugText 1

%ifndef DebugText_DEFINED
	%define  DebugText_DEFINED
	jmp	%%Over
DebugText_PROC:
	pushf
	cld
	pushm 		ds, ax, dx
	push 		cs
	pop		ds
	mov		ah, 0x02
%%Display:
	lodsb
	test		al, al
	jz		%%Done
	mov		dl, al
	int		0x21
	jmp		%%Display
%%Done:
	popm		ds, ax, dx
	popf
	ret

%endif

SECTION_DATA

	%ifstr %1

	%%str:
		db		%1
		db		0
	%endif

__?SECT?__

%%Over:
	push		si
	mov		si, %%str
	call		DebugText_PROC
	pop		si
%endmacro

%imacro DebugRegisters 0-*

%ifndef DebugRegisters_DEFINED
	%define  DebugRegisters_DEFINED
	jmp	%%Over

DebugRegisters_PROC:
	DebugText '	AX='
	DebugHexWord ax
	DebugText '	BX='
	DebugHexWord bx
	DebugText '	CX='
	DebugHexWord cx
	DebugText '	DX='
	DebugHexWord dx
	DebugText '	DS:SI='
	DebugHexWord ds
	DebugChar ':'
	DebugHexWord si
	DebugText '	ES:DI='
	DebugHexWord es
	DebugChar ':'
	DebugHexWord di
	DebugCRLF
	ret
%endif

%%Over:
	call	DebugRegisters_PROC
%endmacro

%imacro RegisterPair 1
	%ifidni %1, dx:ax
		%define REGISTER_PAIR_HIGH 	dx
		%define REGISTER_PAIR_LOW 	ax
	%elifidni %1, ds:si
		%define REGISTER_PAIR_HIGH 	ds
		%define REGISTER_PAIR_LOW 	si
	%elifidni %1, es:di
		%define REGISTER_PAIR_HIGH 	es
		%define REGISTER_PAIR_LOW 	di
	%elifidni %1, ss:bp
		%define REGISTER_PAIR_HIGH 	ss
		%define REGISTER_PAIR_LOW 	bp

	%elifidni %1, dx:bx
		%define REGISTER_PAIR_HIGH 	dx
		%define REGISTER_PAIR_LOW 	bx
	%elifidni %1, dx:cx
		%define REGISTER_PAIR_HIGH 	dx
		%define REGISTER_PAIR_LOW 	bx
	%elifidni %1, dx:si
		%define REGISTER_PAIR_HIGH 	dx
		%define REGISTER_PAIR_LOW 	si
	%elifidni %1, dx:di
		%define REGISTER_PAIR_HIGH 	dx
		%define REGISTER_PAIR_LOW 	di

	%elifidni %1, ds:ax
		%define REGISTER_PAIR_HIGH 	ds
		%define REGISTER_PAIR_LOW 	ax
	%elifidni %1, ds:bx
		%define REGISTER_PAIR_HIGH 	ds
		%define REGISTER_PAIR_LOW 	bx
	%elifidni %1, ds:cx
		%define REGISTER_PAIR_HIGH 	ds
		%define REGISTER_PAIR_LOW 	bx
	%elifidni %1, ds:dx
		%define REGISTER_PAIR_HIGH 	ds
		%define REGISTER_PAIR_LOW 	dx
	%elifidni %1, ds:di
		%define REGISTER_PAIR_HIGH 	ds
		%define REGISTER_PAIR_LOW 	di

	%elifidni %1, es:ax
		%define REGISTER_PAIR_HIGH 	es
		%define REGISTER_PAIR_LOW 	ax
	%elifidni %1, es:bx
		%define REGISTER_PAIR_HIGH 	es
		%define REGISTER_PAIR_LOW 	bx
	%elifidni %1, es:cx
		%define REGISTER_PAIR_HIGH 	es
		%define REGISTER_PAIR_LOW 	bx
	%elifidni %1, es:dx
		%define REGISTER_PAIR_HIGH 	es
		%define REGISTER_PAIR_LOW 	dx
	%elifidni %1, es:si
		%define REGISTER_PAIR_HIGH 	es
		%define REGISTER_PAIR_LOW 	si

	%else
		%error Undefined register pair %1
	%endif
%endmacro
; -----------------------------------------------------------------------------

%endif

