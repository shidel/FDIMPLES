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

%ifndef BOXLINES_INC_DEFINED
%define BOXLINES_INC_DEFINED
; -----------------------------------------------------------------------------
%macro BoxLineData_INTERNAL 0

SECTION_DATA

BoxLineData_DATA:
	db 0

__?SECT?__

%endmacro
; -----------------------------------------------------------------------------
; Display a horizontal line
; MACRO:  DrawHLine 3
; INPUT:  %1 = XY, %2 = Count, %3 = Options (Prefers AX, CL, CH)
; OUTPUT: none
; REGS:	  ax, cx
; -----------------------------------------------------------------------------
%macro DrawHLine_INTERNAL 0

SECTION_PROC

DrawHLine_PROC:
	ret

__?SECT?__

%endmacro

%imacro DrawHLine 3

	PROC_REQUIRE		BoxLineData
	PROC_REQUIRE		DrawHLine

	RegsPreserve		ax, cx
	regmatch		cx, %1
	%ifdef REGISTER_MATCH
		push		cx
		movndef		cl, %2, ch, %3
		pop		ax
	%else
		movndef		cl, %2, ch, %3
		movndef		ax, %1
	%endif
	call 			DrawHLine_PROC
	RegsRestore		ax, cx


%endmacro
; *****************************************************************************
%else
	PROC_PROVIDE		BoxLineData
	PROC_PROVIDE		DrawHLine
	PROC_PROVIDE		DrawVLine

%endif
