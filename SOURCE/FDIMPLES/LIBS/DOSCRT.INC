; Basic CRT for DOS
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

; -----------------------------------------------------------------------------
%include "FEATURES.INC"
%include "NASMEXT.INC"
; -----------------------------------------------------------------------------
; List of macros and functions provided by this file.
; Note: Macros often have have preferred register to use when passing when
; passing them a parameter. Using the preferred register will result in saving
; a few bytes of code. However, it is not required.
; -----------------------------------------------------------------------------
; Probes video hardware for card type and current settings. It needs called
; prior to any other DOSCRT macros. However, it can be called multiple times.
; For example, after mode changes. Warning: If VESA is enabled, the macro will
; use a shared temporary buffer in the BSS.
; MACRO:  VideoInitializeState 0
; OUTPUT: undefined, sets data in BSS.
; REGS:	  AX, BX, CX, DX, ES, DI (NEVER preserved)

; Probes for current video settings. It needs called prior to any other DOSCRT
; macros. It probably should only be called only once at startup. It is called
; automatically. But if for some reason you need to call it again, its there.
; MACRO:  VideoInitializeOriginals 0
; OUTPUT: undefined, sets data in BSS.
; REGS:	  AX, BX, ES (NEVER preserved)

; Restores video settings, to original mode, page, and cursor if needed.
; Requires using InitialVideoSettings macro during startup. Should probably
; call before exit. Automatically, calls ProbeVideoSettings to update data.
; MACRO:  VideoResetSettings 0
; OUTPUT: undefined, sets data in BSS.
; REGS:	  AX, BX, CX, DX, ES, DI (NEVER preserved)

; Changes video mode if needed. Automatically calls ProbeVideoSettings to
; update data.
; MACRO:  TextMode 1
; INPUT:  %1 = video mode (prefers al), original returns it to Initial Setting
; OUTPUT: Carry Flag set if error occurred.
; REGS:	  AX, BX, CX, DX, ES, DI (NEVER preserved)

%include "DOSCRT/TEXTMODE.INC"

; Test for key was pressed
; MACRO:  KeyPressed 0-1
; INPUT:  %1 = [Optional] jump address if key was pressed.
; OUTPUT: Carry Flag Set if key has been pressed.
; REGS:	  ax

; Test for key not pressed
; MACRO:  NotKeyPressed 0-1
; INPUT:  %1 = [Optional] jump address if key was not pressed.
; OUTPUT: Carry Flag Set if key has been pressed. (Same as KeyPressed)
; REGS:	  ax

; Wait for and read key press
; MACRO:  ReadKey 1
; OUTPUT: %1 is key press (prefers ax)
; REGS:	  ax

%include "DOSCRT/KEYPRESS.INC"

; Set the foreground color for text writes
; MACRO:  TextColor 1
; INPUT:  %1 = 4-bit color (prefers al), original returns it to Initial Setting
; REGS:   ax

; Set the background color for text writes
; MACRO:  TextBackground 1
; INPUT:  %1 = 3-bit color (prefers al), original returns it to Initial Setting
; REGS:   ax, cx

; Set both foreground and background color.
; MACRO:  TextAttr 1
; INPUT:  %1 = 8-bit color (prefers al), original returns it to Initial Setting
; REGS:   cx

; Clear foreground text color intensity bit
; MACRO:  LowVideo 0
; REGS:   none

; Set foreground text color intensity bit
; MACRO:  HighVideo 0
; REGS:   none

; Restore foreground intensity bit to last/original video Initial Setting
; MACRO:  NormVideo 0
; REGS:   none

%include "DOSCRT/TEXTATTR.INC"

; Wait for a period of time to elapse. If Support_BIOS_Timer is enabled,
; it will first attempt to use the BIOS WAIT function. If that fails, it
; will fall back on counting system timer ticks.
; MACRO:  Delay 1
; INPUT:  %1 = Milliseconds to wait, (prefers ax)
; REGS:   ax, cx, dx

%include "DOSCRT/DELAY.INC"

; Output sound through PC speaker
; MACRO:  Sound 1
; INPUT:  %1 = Frequency in Hertz (prefers ax)
; REGS:   ax, cx, dx

; Turns off PC Speaker
; MACRO:  NoSound 0
; REGS:   ax, dx

%include "DOSCRT/SOUND.INC"

; Adjust the window to its maximum size. Does not move cursor. Automatically
; called at startup and with text mode changes.
; MACRO: WindowMax 0
; REGS:  ax

; Set the window size and moves cursor to top/left in window.
; MACRO: Window 2
; INPUT:
;	%1 = Window MinXY (prefers ax)
;	%2 = Window MaxXY (prefers dx)
; REGS:  ax, cx, dx

; Move cursor to new position within window
; MACRO: GotoXY 1
; INPUT: %1 - XY (prefers ax)
; REGS:  ax, bx, dx

; Return the cursor position within window
; MACRO: WhereXY 1
; OUTPUT: %1 - XY (prefers dx)
; REGS:  ax, bx, cx, dx

; Return the cursor column position within window
; MACRO: WhereX 1
; OUTPUT: %1 - X (prefers dl)
; REGS:  ax, bx, cx, dl

; Return the cursor row position within window
; MACRO: WhereY 1
; OUTPUT: %1 - Y (prefers dh)
; REGS:  ax, bx, cx, dh

%include "DOSCRT/WINDOW.INC"

; Clear the remaining portion of the current line
; MACRO: ClrEOL 0
; REGS: ax, bx, cx, dx

; Clear the current window and moves cursor to top/left in window.
; MACRO: ClrScr 0
; REGS: ax, bx, cx, dx

%include "DOSCRT/CLEAR.INC"

; Delete the current line and add fresh one at the bottom of the window
; MACRO: DelLine 0
; REGS: ax, bx, cx, dx

; Insert a blank line at the current location
; MACRO: InsLine 0
; REGS: ax, bx, cx, dx

; Scrolls the window up
; MACRO: WindowScrollUp 0
; REGS: ax, bx, cx, dx

; Scrolls the window down
; MACRO: WindowScrollDown 0
; REGS: ax, bx, cx, dx

%include "DOSCRT/INSDEL.INC"

; Write individual characters to display
; MACRO:  WriteChar 1-*
; INPUT:  %1+ = Characters (prefers al)
; REG: 	  ax, bx, cx, dx

; Write CRLF to display
; MACRO:  WriteCRLF 0-1
; INPUT:  %1 = Number of CRLF to output device (default 1, prefers cx)
; REG: 	  ax, bx, cx, dx

; Send ASCIIz string to display
; MACRO:  WriteStr 1-*
; INPUT:  ASCIIz string(s) to sent to display (prefers si)
; REGS:   ax, bx, cx, dx, si

; Send byte as HEX to display
; MACRO:  WriteHexByte 1-*
; INPUT:  %1+ = byte to display (prefers al)
; REGS:   ax, bx, cx, dx

; Send word as HEX to display
; MACRO:  WriteHexWord 1-*
; INPUT:  %1+ = word to display (prefers ax)
; REGS:   ax, bx, cx, dx

%include "DOSCRT/WRITE.INC"

; Return the current cursor shape
; MACRO:  GetCursor 1
; OUTPUT: %1 = Cursor Shape (prefers cx)
; REGS:   ax, bx, cx, dx

; Set the current cursor shape
; MACRO:  SetCursor 1
; INPUT:  %1 = Cursor Shape (prefers cx) (accepts: original, small, half, full)
;	  Also, it uses HIDE, SHOW with counters. 2 hides will need 2 shows.
;	  Like the cursor itself, the counters are reset on mode changes.
; REGS:   ax, cx

%include "DOSCRT/CURSOR.INC"

; Check if mouse button event has occurred and remove it from the buffer.
; Generally, this is the only mouse macro you will absolutely need to use.
; However, if you want to do things like hover-over highlighting. You will
; also may to use the MouseMove/ReadMouseMove macros to simplify the code.
; MACRO:  ReadMouseClick 2
; INPUT:  none
; OUTPUT:
;	If CarryFlag is true, then...
;	%1 = mouse button status for event (prefers bx)
;	%2 = mouse screen position for event (prefers dx)
;	If Carry Flag is false, then...
;	%1 = current mouse button status (prefers bx)
;	%2 = current mouse screen position (prefers dx)
; REGS:	bx, dx, si

; Test if mouse has been moved
; MACRO:  MouseMoved 0-1
; INPUT:  %1 = [Optional] jump address if mouse has been moved.
; OUTPUT: Carry Flag Set if mouse has moved. Does not clear movement flag.
; REGS:	  none

; Test if mouse has not moved
; MACRO:  NotMouseMoved 0-1
; INPUT:  %1 = [Optional] jump address if mouse has not moved.
; OUTPUT: Carry Flag Set if mouse has moved. (Same as MouseMoved)
; REGS:	  none

; Check if mouse has moved and get position.
; MACRO:  ReadMouseMove 1
; OUTPUT: %1 = current mouse screen position (prefers dx)
;	  Carry Flag Set if mouse has moved since last ReadMouseMove.
; REGS:	  dx

; Test if any mouse button event has occurred and is waiting in the buffer.
; MACRO:  MouseClicked 0-1
; INPUT:  %1 = [Optional] jump address if a mouse button event occurred.
; OUTPUT: Carry Flag Set if mouse has button event is waiting in the buffer.
; REGS:	  ax

; Test if no mouse button events are waiting in the buffer.
; MACRO:  NotMouseClicked 0-1
; INPUT:  %1 = [Optional] jump address if a mouse button event has not occurred.
; OUTPUT: Carry Flag Set if a button event is waiting. (Same as MouseClicked)
; REGS:	  ax

%include "DOSCRT/MOUSE.INC"
; -----------------------------------------------------------------------------
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
; Automatically initialize video display and other settings
%ifndef DO_NOT_INITIALIZE_LIBS
	%ifndef DOSCRT_INIT_CODE
	%define DOSCRT_INIT_CODE
		mov [Video_Options], byte vcbDirect + vcbScroll ; + vcbCtrlChar
		mov [Video_Tab], word 0x0408
		VideoInitializeState
		WindowMax
		VideoInitializeOriginals
		MouseInitialize
	%endif
%endif
; -----------------------------------------------------------------------------

