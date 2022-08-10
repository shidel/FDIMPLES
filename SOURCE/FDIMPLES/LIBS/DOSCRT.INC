; CRT for DOS v1.0
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

%ifndef DOSCRT_INC_DEFINED
%define DOSCRT_INC_DEFINED
; -----------------------------------------------------------------------------
; List of macros and functions provided by this file.
; Note: Macros often have have preferred register to use when passing when
; passing them a parameter. Using the preferred register will result in saving
; a few bytes of code. However, it is not required.

; Probes video hardware for card type and current settings. It needs called
; prior to any other DOSCRT macros. However, it can be called multiple times.
; For example, after mode changes. Warning: If VESA is enabled, the macro will
; use a shared temporary buffer in the BSS.
; Registers AX, BX, CX, DX, ES, DI are not preserved.
; MACRO:  ProbeVideoCard 0
; INPUT:  none
; OUTPUT: undefined, sets data in BSS.

; Probes for current video settings. It needs called prior to any other DOSCRT
; macros. It should really be called only once at startup.
; Registers AX, BX, CX, DX, ES, DI are not preserved.
; MACRO:  InitialVideoSettings 0
; INPUT:  none
; OUTPUT: undefined, sets data in BSS.

; Restores video settings, to original mode, page, and cursor if needed.
; Requires using InitialVideoSettings macro during startup.
; Registers AX, BX, CX, DX, ES, DI are not preserved. Should probably call
; before exit. Automatically, calls ProbeVideoSettings to update data.
; MACRO:  ResetVideoSettings 0
; INPUT:  none
%include "DOSCRT/TEXTMODE.INC"

; Test for key was pressed
; MACRO:  KeyPressed 0-1
; INPUT:  %1 = [Optional] jump address if key was pressed.
; OUTPUT: Carry Flag Set if key has been pressed.

; Test for key not pressed
; MACRO:  NotKeyPressed 0-1
; INPUT:  %1 = [Optional] jump address if key was not pressed.
; OUTPUT: Carry Flag Set if key has been pressed. (Same as KeyPressed)

; Wait for and read key press
; MACRO:  ReadKey 1
; INPUT:  none
; OUTPUT: %1 is key press (prefers ax)
%include "DOSCRT/KEYPRESS.INC"

; Set the foreground color for text writes
; MACRO:  TextColor 1
; INPUT:  %1 = 4-bit color (prefers al), original returns it to Initial Setting
; OUTPUT: none

; Set the background color for text writes
; MACRO:  TextBackground 1
; INPUT:  %1 = 3-bit color (prefers al), original returns it to Initial Setting
; OUTPUT: none

; Set both foreground and background color.
; MACRO:  TextAttr 1
; INPUT:  %1 = 8-bit color (prefers al), original returns it to Initial Setting
; OUTPUT: none

; Clear foreground text color intensity bit
; MACRO:  LowVideo 0
; INPUT:  none
; OUTPUT: none

; Set foreground text color intensity bit
; MACRO:  HighVideo 0
; INPUT:  none
; OUTPUT: none

; Restore foreground intensity bit to last/original video Initial Setting
; MACRO:  NormVideo 0
; INPUT:  none
; OUTPUT: none
%include "DOSCRT/TEXTATTR.INC"
; -----------------------------------------------------------------------------
; Included overall feature support for DOSCRT
%idefine Support_BIOS_Video		1
%idefine Support_Direct_Video   	1
%idefine Support_Mouse			1

; Included card support levels and returned detection values
%idefine Video_MDA 	0
%idefine Video_CGA 	1
; EGA test is strongly recommended but not required. Otherwise, locked into
; 25 screen rows.
%idefine Video_EGA 	2
; Disable Video_MCGA, VGA, VESA. If you don't care about them and want to
; reduce the code size a few bytes (+256 bytes BSS for VESA)
; %idefine Video_MCGA 	3
; %idefine Video_VGA 	4
; %idefine Video_VESA	5

; Standard text video display mode constants
%idefine tmBW40		0	; 40x25 B/W on Color adapter
%idefine tmCO40		1	; 40x25 Color on Color adapter
%idefine tmBW80		2	; 80x25 B/W on Color adapter
%idefine tmCO80		3	; 80x25 Color on Color adapter
%idefine tmMono		7	; 80x25 on Monochrome adapter

; Foreground and background color constants
%idefine clBlack	0
%idefine clBlue		1
%idefine clGreen	2
%idefine clCyan		3
%idefine clRed		4
%idefine clMagenta	5
%idefine clBrown	6
%idefine clLightGray	7

; Foreground color constants
%idefine clDarkGray	8
%idefine clLightBlue	9
%idefine clLightGreen	10
%idefine clLightCyan	11
%idefine clLightRed	12
%idefine clLightMagenta	13
%idefine clYellow	14
%idefine clWhite	15

; -----------------------------------------------------------------------------
; Automatically initialize video display settings in BSS

ProbeVideoCard
InitialVideoSettings;

; -----------------------------------------------------------------------------
%endif
