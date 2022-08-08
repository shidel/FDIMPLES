; CRT for DOS v1.0

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

%ifndef DOSCRT_INC_DEFINED
%define DOSCRT_INC_DEFINED
; -----------------------------------------------------------------------------
; List of macros and functions provided by this file.
; Note: Macros often have have preferred register to use when passing when
; passing them a parameter. Using the preferred register will result in saving
; a few bytes of code. However, it is not required.

; Probes video hardware for card type and current settings. It needs called
; prior to any other DOSCRT macros. However, it can be called multiple times.
; For example, after mode changes.
; Registers AX, BX, CX, DX, ES, DI are not preserved.
; MACRO:  ProbeVideoCard 0
; INPUT:  none
; OUTPUT: undefined, sets data in BSS.
%include "DOSCRT/PROBVID.INC"

; Probes for current video settings. It needs called prior to any other DOSCRT
; macros. It should really be called only once at startup. That is normally
; handled by DOSCRT.INC.
; Registers AX, BX, CX, DX, ES, DI are not preserved.
; MACRO:  InitialVideoSettings 0
; INPUT:  none
; OUTPUT: undefined, sets data in BSS.
%include "DOSCRT/INITIALV.INC"

; -----------------------------------------------------------------------------
; Included card support levels and returned detection values

%idefine Video_MDA 	0
%idefine Video_CGA 	1
; EGA test is strongly recommended but not required. Otherwise, locked into
; 25 screen rows.
%idefine Video_EGA 	2
; Disable Video_MCGA, VGA, VESA to reduce code size if don't care
; %idefine Video_MCGA 	3
; %idefine Video_VGA 	4
; %idefine Video_VESA	5

; -----------------------------------------------------------------------------
; Automatically initialize video display settings in BSS

ProbeVideoCard
InitialVideoSettings

; -----------------------------------------------------------------------------
%endif
