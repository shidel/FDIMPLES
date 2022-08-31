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

%ifndef STDOUT_INC_DEFINED
%define STDOUT_INC_DEFINED
; -----------------------------------------------------------------------------
; Internal data output to STDOUT
; -----------------------------------------------------------------------------
%macro WRITER_STDOUT_INTERNAL 0

SECTION_PROC

WRITER_STDOUT_PROC:
	; dl = character
	push		ax
	mov		ah, 0x02
	int		0x21
	pop		ax
	ret

__?SECT?__


%endmacro
; -----------------------------------------------------------------------------
; Send individual characters to standard output device
; MACRO:  StdOutChar 1-*
; INPUT:  %1+ = Characters (prefers dl)
; REGS: ax, dl
; -----------------------------------------------------------------------------
%imacro StdOutChar 1-*
	RegsPreserve		ax, dx
%ifnidni %0, 1
	mov			ah, 0x02
	%rep  %0
		movndef		dl, %1
		int    		0x21
	%rotate 1
	%endrep
%else
	movndef 		dl, %1
	mov			ah, 0x02
	int 			0x21
%endif
	RegsRestore		ax, dx
%endmacro
; -----------------------------------------------------------------------------
; Send CRLF to standard output device
; MACRO:  StdOutCRLF 0-1
; INPUT:  %1 = Number of CRLF to output device (default 1, prefers cx)
; REGS: ax, dl, cx
; -----------------------------------------------------------------------------
%macro StdOutCRLF_INTERNAL 0

SECTION_PROC

StdOutCRLF_PROC:
	RegsPreserve		ax, dx
	mov			ah, 0x02
	mov			dl, 0x0d
	int			0x21
	mov			dl, 0x0a
	int			0x21
	RegsRestore		ax, dx
	ret

__?SECT?__

%endmacro

%macro StdOutCR_INTERNAL 0

SECTION_PROC

StdOutCR_PROC:
	RegsPreserve		ax, dx
	mov			ah, 0x02
	mov			dl, 0x0d
	RegsRestore		ax, dx
	ret

__?SECT?__

%endmacro

%macro StdOutLF_INTERNAL 0

SECTION_PROC

StdOutLF_PROC:
	RegsPreserve		ax, dx
	mov			ah, 0x02
	mov			dl, 0x0a
	int			0x21
	RegsRestore		ax, dx
	ret

__?SECT?__

%endmacro

%imacro StdOutCRLF 0-1	1

	PROC_REQUIRE StdOutCRLF

	%ifnidni %1, 1
		RegsPreserve	cx
		movndef		cx, %1
		%%Loopy:
			call	StdOutCRLF_PROC
			loop	%%Loopy
		RegsRestore	cx
	%else
		call		StdOutCRLF_PROC
	%endif

%endmacro
; -----------------------------------------------------------------------------
; Send ASCIIz string to standard output device. When passed a memory reference,
; like a register or number, it will use the ES segment (like [ES:?]). When
; passed a hard string (like 'HELLO'), it will be stored in the DATA segment
; and it will automatically adjust ES to DS and back again.
; MACRO:  StdOutStr 1+
; INPUT:  %1+ = ASCIIz string sent to STDOUT (prefers si)
; REGS: al, dl
; -----------------------------------------------------------------------------
%macro StdOutStrES_INTERNAL 0
	DATAOUT_PROC STDOUT, STR_ES, StdOutStrES
%endmacro

%macro StdOutStrDS_INTERNAL 0
	DATAOUT_PROC STDOUT, STR_DS, StdOutStrDS
%endmacro

%macro StdOutStr_SUBMAC 1

	USES_WRITER  STDOUT, STR_ES, StdOutStrES

SECTION_DATA

	%ifstr %1

	%%str:
		db		%1
		db		0
	%endif

__?SECT?__

	%ifnidni %1, si
		push	si
	%endif
	%ifstr %1
		USES_WRITER  	STDOUT, STR_DS, StdOutStrDS
		movndef		si, %%str
		call		StdOutStrDS_PROC
	%else
		movndef		si, %1
		call		StdOutStrES_PROC
	%endif
	%ifnidni %1, si
		pop	si
	%endif

%endmacro

%imacro StdOutStr 1-*
	%rep  %0
		%ifidni %1, CR
			PROC_REQUIRE StdOutCR
			call	StdOutCR_PROC
		%elifidni %1, LF
			PROC_REQUIRE StdOutLF
			call	StdOutLF_PROC
		%else
			StdOutStr_SUBMAC %1
		%endif
	%rotate 1
	%endrep
%endmacro
; -----------------------------------------------------------------------------
; Send byte as HEX to standard output device
; MACRO:  StdOutHexByte 1-*
; INPUT:  %1+ = byte to print (prefers al)
; REGS:	  cx, dl
; -----------------------------------------------------------------------------
%macro StdOutHexByte_INTERNAL 0

DATAOUT_PROC STDOUT, HEXBYTE, StdOutHexByte

%endmacro

%macro StdOutHexByte 1-*

	PROC_REQUIRE WRITER_STDOUT
	PROC_REQUIRE DATAOUT_HEXBYTE
	PROC_REQUIRE StdOutHexByte

	%rep  %0
		%ifnidni %1, al
			push	ax
			mov	al, %1
		%endif
		call		StdOutHexByte_PROC
		%ifnidni %1, al
			pop	ax
		%endif
	%rotate 1
	%endrep

%endmacro
; -----------------------------------------------------------------------------
; Send word as HEX to standard output device
; MACRO:  StdOutHexWord 1-*
; INPUT:  %1+ = word to print (prefers ax)
; REGS:	  cx, dl
; -----------------------------------------------------------------------------
%macro StdOutHexWord_INTERNAL 0

DATAOUT_PROC STDOUT, HEXWORD, StdOutHexWord

%endmacro

%imacro StdOutHexWord 1-*

	PROC_REQUIRE WRITER_STDOUT
	PROC_REQUIRE DATAOUT_HEXWORD
	PROC_REQUIRE StdOutHexWord

	%rep  %0
		%ifnidni %1, ax
			push	ax
			mov	ax, %1
		%endif
		call		StdOutHexWord_PROC
		%ifnidni %1, ax
			pop	ax
		%endif
	%rotate 1
	%endrep
%endmacro
; -----------------------------------------------------------------------------
; Send byte as Unsigned Integer to standard output device
; MACRO:  StdOutUIntByte 1-*
; INPUT:  %1+ = word to print (prefers al)
; OUTPUT: none
; -----------------------------------------------------------------------------
%imacro StdOutUIntByte 1-*

	PROC_REQUIRE StdOutHexByte

	%rep  %0
		%ifnidni %1, al
			push	ax
			movndef	al, %1
		%endif
		push		ax
		StdOutChar	'0', 'x'
		pop		ax
		StdOutHexByte	al
		%ifnidni %1, al
			pop	ax
		%endif
	%rotate 1
	%endrep
%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE WRITER_STDOUT

	PROC_PROVIDE StdOutCRLF
	PROC_PROVIDE StdOutCR
	PROC_PROVIDE StdOutLF
	PROC_PROVIDE StdOutStr
	PROC_PROVIDE StdOutStrDS
	PROC_PROVIDE StdOutHexByte
	PROC_PROVIDE StdOutHexWord
%endif
