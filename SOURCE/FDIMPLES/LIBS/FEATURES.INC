; Features for DOS v1.0
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

%ifndef FEATURES_INC_DEFINED
%define FEATURES_INC_DEFINED

; -----------------------------------------------------------------------------
; Features and compile options for macros in the DOS libraries
; -----------------------------------------------------------------------------
; When enabled, includes some hardware, os and other specific bug fixes.
; You should probably leave it enabled.
%define DOS_BUG_FIXES

; When enabled and unless otherwise specified, the macro will preserve all the
; registers it uses. This can be useful for large and complex programs. However,
; there will be a small performance hit and the bytes needed for all those
; pushs ands pops does add up.
%define Preserve_Registers

; Include DOSCRT screen range checking. Adds several bytes. For small programs,
; this can be noticeable. Preferably, write code that does not go out of
; range and don't waste bytes. :-)
%define DOSCRT_Range_Check

; Include support for additional Interrupt based timer. Disabling this can save
; a few bytes. It will then always use system TimerTicks and accuracy will be
; +/- 55ms.
%define Support_BIOS_Timer

; Support BIOS video access. The only method supported at present. It is slower
; than direct video access.
%define Support_BIOS_Video

; Support direct video access. I don't know if I will bother implementing this.
; Probably. We will see.
%define Support_Direct_Video

; Include mouse support
%define Support_Mouse

; Included card support levels and detection values, MDA & CGA are required
%define Video_MDA 	0
%define Video_CGA 	1
; EGA test is strongly recommended but not required. Otherwise, locked into
; 25 screen rows.
%define Video_EGA 	2
; Disable Video_MCGA, VGA, VESA. If you don't care about them and want to
; reduce the code size a few bytes (+256 bytes BSS for VESA)
%define Video_MCGA 	3
%define Video_VGA 	4
%define Video_VESA	5

; -----------------------------------------------------------------------------
; Video control option bits
; default is vcbDirectVideo + vcbScroll
%define vcbDirect	00000001b	; Use Direct Video if possible
%define vcbScroll	00000010b	; Enable last line auto-scroll
%define vcbControls 	00000100b	; Print, dont process control chars
; -----------------------------------------------------------------------------
; Internal defines to make coding macros simpler
%undef BIOS_Direct_Video
%ifdef Support_BIOS_Video
	%ifdef Support_Direct_Video
		%define BIOS_Direct_Video
	%endif
%endif
; -----------------------------------------------------------------------------
%endif
