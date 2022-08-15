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
        %rep  %0 / 2
	 %ifnidni %1, %2
		push %2
	    %endif
            %rotate 2
        %endrep
        %rep %0 / 2
	%rotate -2
	    %ifnidni %1, %2
		pop %1
	    %endif
        %endrep
    %endif
%endmacro

%imacro TempBuffer 1
; Include an extremely temporary application wide shared buffer of %1 bytes
; Care must be taken that multiple functions do not use the buffer while data
; is still needed.
	%ifndef TEMP_BUFFER_%1_DEFINED
		%idefine TEMP_BUFFER_%1_DEFINED

		[section .bss]

		TEMP_BUFFER_%1:
			resb	%1

		__?SECT?__

	%endif
%endmacro

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

%endif

