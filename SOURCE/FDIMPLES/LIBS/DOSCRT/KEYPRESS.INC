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

%ifndef KEYPRESS_INC_DEFINED
%define KEYPRESS_INC_DEFINED
; -----------------------------------------------------------------------------
; Test for key was pressed
; MACRO:  KeyPressed 0-1
; INPUT:  %1 = [Optional] jump address if key was pressed.
; OUTPUT: Carry Flag Set if key has been pressed.
; REGS:	  ax
; -----------------------------------------------------------------------------
%imacro KeyPressed_INTERNAL 0

SECTION_PROC

KeyPressed_PROC:
	RegsPreserve		ax
	mov  			ah, 0x01
	int  			0x16
	clc
	jz   			%%Done
	stc
%%Done:
	RegsRestore		ax
	ret

__?SECT?__

%endmacro

%imacro KeyPressed 0-1

	PROC_REQUIRE 		KeyPressed

	call 			KeyPressed_PROC
	%if %0 = 1
		jc		%1
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Test for key not pressed
; MACRO:  NotKeyPressed 0-1
; INPUT:  %1 = [Optional] jump address if key was not pressed.
; OUTPUT: Carry Flag Set if key has been pressed. (Same as KeyPressed)
; REGS:	  ax
; -----------------------------------------------------------------------------
%imacro NotKeyPressed 0-1

	PROC_REQUIRE 		KeyPressed

	call 			KeyPressed_PROC
	%if %0 = 1
		jnc		%1
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Wait for and read key press
; MACRO:  ReadKey 1
; INPUT:  none
; OUTPUT: %1 is key press (prefers ax)
; REGS:	  ax
; -----------------------------------------------------------------------------
%imacro ReadKey_INTERNAL 0

SECTION_PROC

ReadKey_PROC:
	mov  			ah, 0x00
	int  			0x16
	cmp			ah, 0x40
	jnb			%%Done
	test			al, al
	jz			%%Done
	xor			ah, ah
%%Done:
	ret

__?SECT?__

%endmacro

%imacro ReadKey 1

	PROC_REQUIRE 		ReadKey

	%ifnidni %1, ax
		RegsPreserve	ax
	%endif
	call 			ReadKey_PROC
	%ifnidni %1, ax
		mov		%1, ax
		RegsRestore	ax
	%endif

%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE 		KeyPressed
	PROC_PROVIDE 		ReadKey
%endif
