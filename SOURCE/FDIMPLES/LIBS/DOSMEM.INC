; Basic Memory Functions for DOS
; Similar (but a little different) to a Pascal DOS unit.

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

; -----------------------------------------------------------------------------
%include "FEATURES.INC"
%include "NASMEXT.INC"
; *****************************************************************************
%ifndef DOSMEM_INC_DEFINED
%define DOSMEM_INC_DEFINED
; -----------------------------------------------------------------------------
%macro Memory_INTERNAL 0

SECTION_PROC

Memory_PROC:
	ret

__?SECT?__

%endmacro

%imacro Memory 3
	PROC_PROVIDE		Memory
%endmacro
; -----------------------------------------------------------------------------
%else
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
%endif
; *****************************************************************************
; List of macros and functions provided by this file.
; Note: Macros often have have preferred register to use when passing when
; passing them a parameter. Using the preferred register will result in saving
; a few bytes of code. However, it is not required.

%include "DOSMEM/HEAPMEM.INC"

%include "DOSMEM/XMSMEM.INC"

%include "DOSMEM/EMSMEM.INC"
