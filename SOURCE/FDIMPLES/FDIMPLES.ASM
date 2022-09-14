; FreeDOS Installer (FDI) - My Package List Editor Software

; BSD 3-Clause License
; Copyright (c) 2016-2022, Jerome Shidel
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

use16				; Use 16-bit code.

cpu 8086			; Limit to 8086 instruction set

org 0x100			; Making a COM file.

SECTION .text			; Not required. It's the default. Used anyhow.

%include "FEATURES.INC"		; Default DEFINES & options for library macros

; %undef Preserve_Registers	; disable preserving registers in macros
; %undef DOS_BUG_FIXES		; keep some fixes for various DOS and BIOS bugs
%undef DOSCRT_Range_Check	; disable out of bounds coordinate checking
; %undef Stack_Overflow_Check
%undef Support_BIOS_Timer	; disable attempts to use int15 timer
; %undef Support_BIOS_Video	; keep BIOS video support
; %undef Support_Direct_Video	; keep Direct video addressing
; %undef Support_Wide_Screens	; keep direct video support on >80 columns modes
; %undef Support_Mouse		; keep Mouse support
%undef Video_MCGA		; disable MCGA check/support
%undef Video_VGA		; disable VGA check/support
%undef Video_VESA		; disable SuperVGA check/support

%include "DOSLIBS.INC"		; One INC to include them all. Some INCS have
				; initialization routines. Some calls for those
				; routines get inserted automatically. For
				; example DOSCRT requires preparation. If those
				; are not needed, you might save some bytes by
				; including only the required LIBS directly.
				; Or better yet, you disable those features to
				; prevent accidentally using a macro that you
				; did may have prevented from being initialized.

SECTION_CODE			; Already here. Going to reference it anyhow.

	InitStack		4	; Stack 4k,

	; jmp			ProbeModes
	call			Initialize
	call			DrawMainWindow

MainLoop:
	ReadKey			ax

Finished:
	call			ResetDisplay

	%ifdef Stack_Overflow_Check
		WriteStr		'Peak stack usage: '
		StackPeak		ax
		WriteUIntWord		ax
		WriteCRLF
		; WriteStr		'Peak heap usage: '
		; HeapPeakUsed		dx:ax
		; WriteUIntDWord		dx:ax
		; WriteCRLF
	%endif

	Terminate		0	; Also includes needed LIB function code

ResetDisplay:
; Resets video to normal (if needed), clears the screen and terminates the
; program.
	VideoResetSettings		; Reset TextMode, Cursor, etc if needed
	Window			max
	TextAttr		0x07
	ClrScr
	ret

	DebugPointer dx:ax

DrawMainWindow:
; Draws the title bar and framing. Also clears the statusbar, group, item list
; and data windows.
	Window			max
	cmp			[Theme_TitleBarVisible], byte True
	jne			.NoTitleBar
	Window			[XY_TitleBar], [XY_TitleBar + 2]
	TextAttr		[Theme_ProgMenuBar]
	ClrEOL
	RelativeX		+1
	WriteChar		Ascii_HamburgerMenu	; Hamburger menu icon
	mov			al, [Video_WindMaxX]	; Compute position for
	sub			al, [Video_WindMinX]	; centering Prog
	sub			al, 70
	cbw
	shr			ax, 1
	RelativeX		ax
	TextAttr		[Theme_ProgLongName]
	; DebugPointer		es, Text_ProgLong
	WriteStr		Text_ProgLong
	RelativeX		+1
	TextAttr		[Theme_ProgVersion]
	WriteStr		Text_ProgVersion
	RelativeX		+1
	TextAttr		[Theme_ProgMenuBar]
	WriteChar		Ascii_OpenParenthesis
	TextAttr		[Theme_ProgShortName]
	WriteStr		Text_ProgShort
	TextAttr		[Theme_ProgMenuBar]
	WriteChar		Ascii_CloseParenthesis
.NoTitleBar:
	TextAttr		[Theme_WindowBoxAttr]
	Window			[XY_Frame], [XY_Frame + 2]
	ClrScr
	Window			max
	cmp			[Theme_WindowBoxVisible], byte True
	jne			.NoWindowBox
	DrawBox			word [XY_Frame], word [XY_Frame + 2], lnSingle
.NoWindowBox:
	cmp			[Theme_StatusBarVisible], byte True
	jne			.NoStatusBar
	mov			dl, al
	Window			[XY_StatusBar], [XY_StatusBar + 2]
	TextAttr		[Theme_StatusBarAttr]
	ClrScr
	Window			max
.NoStatusBar:
	Window			max
	TextAttr		[Theme_WindowBoxAttr]
	DrawLine		word [XY_HorizontalBar], word [XY_HorizontalBar + 2], lnHorizontal + lnDouble
	DrawLine		word [XY_VerticalBar], word [XY_VerticalBar + 2], lnVertical
	mov			cx, 0x0003
	mov			si, XY_GroupArea
.ClearAreasLoop:
	push			cx
	Window			[si], [si + 2]
	ClrScr
	pop			cx
	add			si, 4
	loop			.ClearAreasLoop
	Window			max
	ret

CalculateScreenPositions:
	moves			cs ; Set ES to CS for hard-coded program strings
; Needs called at startup and when/if resolution is changed.
	Window			max
	WindMin			ax
	WindMax			dx

	; Reduced screen area usage. For testing calculated areas, sizes and
	; such mundane program aspects.
	; add			ax, 0x0303
	; sub			dx, 0x0303

	; Title Bar position
	push			dx
	mov			dh, ah
	mov			[XY_TitleBar], ax
	mov			[XY_TitleBar + 2], dx
	pop			dx
	; Main window frame
	inc			ah
	dec			dh
	cmp			[Theme_TitleBarVisible], byte False
	jne			.WithTitleBar
	dec			ah
.WithTitleBar:
	cmp			[Theme_StatusBarVisible], byte False
	jne			.WithStatusBar
	inc			dh
.WithStatusBar:
	mov			[XY_Frame], ax
	mov			[XY_Frame + 2], dx
	; Status Bar position
	pushm			ax, dx
	inc			dh
	mov			ah, dh
	mov			[XY_StatusBar], ax
	mov			[XY_StatusBar + 2], dx
	popm			ax, dx
	; Group list window area
	add			ax, 0x0101
	mov			dx, [Size_GroupArea]
	add			dx, ax
	mov			[XY_GroupArea], ax
	mov			[XY_GroupArea + 2], dx
	; Group list / Item list separator bar position and length
	dec			ah
	add			dx, 0x0201
	sub			dh, ah
	mov			al, dl
	mov			dl, dh
	xor			dh, dh
	mov			[XY_VerticalBar], ax
	mov			[XY_VerticalBar + 2], dx
	; Group & Item list / Data separator bar position and length
	add			ah, dl
	dec			ah
	mov			al, [XY_Frame]
	mov			dl, [XY_Frame + 2]
	sub			dl, al
	inc			dl
	mov			[XY_HorizontalBar], ax
	mov			[XY_HorizontalBar + 2], dx
	; Item list window area
	mov			dh, ah
	mov			dl, [XY_Frame + 2]
	sub			dx, 0x0101
	mov			al, [XY_GroupArea + 2]
	mov			ah, [XY_GroupArea + 1]
	add			al, 0x02
	mov			[XY_ItemArea], ax
	mov			[XY_ItemArea + 2], dx
	; Data display window area
	mov			al, [XY_GroupArea]
	mov			ah, [XY_GroupArea + 3]
	mov			dh, [XY_Frame + 3]
	add			ah, 0x02
	dec			dh
	mov			[XY_DataArea], ax
	mov			[XY_DataArea + 2], dx
	ret

Initialize:
; Performs the initialization of the program at startup.
	mov			ax, [MinimumGroupAreaSize]
	mov			[Size_GroupArea], ax

	Cursor			hide
	; WriteStr		Text_ProgShort
	; WriteChar		Ascii_Space
	; WriteStr		__DATE__, CRLF
	; Delay			500
	TextAttr		clLightRed
	WriteStr		'Package media not found!'
	TextAttr		original
	Delay			250
	WriteStr		CRLF, 'please stand by...'
	Delay			1500

	cmp			[Theme_TextMode], byte 0xff
	je			.CurrentTextMode
	TextMode		[Theme_TextMode]
	Cursor			hide
.CurrentTextMode:
	call			CalculateScreenPositions
	ret

ProbeModes:
; At some point after stack handling is added, will do this there instead of
; wasting bytes in the BSS.
	mov			cx, 0x7f
	mov			di, MODE_PROBING
	mov			si, di
	cld
.Probing:
	dec			cx
	cmp			cx, 0xffff
	je			.ProbeDone
	cmp			cl, 0x13
	ja			.Probe
	cmp			cl, 0x07
	je			.Probe
	cmp			cl, 0x03
	jbe			.Probe
	jmp			.Probing
.Probe:
	push			cx
	TextMode		cl
	Delay			50
	pop			cx
	xor			ah, ah
	mov			al, [Video_Mode]
	cmp			al, cl
	jne			.Probing
	; check height against known possibilities
	cmp			[Video_MaxY], byte 0x18
	je			.HeightOK
	cmp			[Video_MaxY], byte 0x2a
	je			.HeightOK
	cmp			[Video_MaxY], byte 0x31
	je			.HeightOK
	jmp			.Probing
.HeightOK:
	; check width against known possibilities
	cmp			[Video_MaxX], byte 0x27
	je			.WidthOK
	cmp			[Video_MaxX], byte 0x4f
	je			.WidthOK
	cmp			[Video_MaxX], byte 0x83
	je			.WidthOK
	jmp			.Probing
.WidthOK:
	inc			ah
	stosw
	mov			ax, [Video_Max]
	add			ax, 0x0101
	stosw
	jmp			.Probing
.ProbeDone:
	xor			ax, ax
	stosw
	call			ResetDisplay
	StdOutStr		'Detected video modes:', CRLF, CRLF
.Displaying:
	lodsw
	test			ah, ah
	jz			.Done
	push			ax
	StdOutStr		'	0x'
	pop			ax
	StdOutHexByte		al
	StdOutChar		' '
	lodsb
	StdOutUIntByte		al
	StdOutStr		' x '
	lodsb
	StdOutUIntByte		al
	StdOutCRLF
	jmp			.Displaying
.Done:
	StdOutCRLF
	Terminate		0


SECTION_DATA

; Hard coded program text strings
Text_ProgLong:		db 'FreeDOS Installer - My Package List Editor Software',0
Text_ProgShort: 	db 'FDIMPLES',0
Text_ProgVersion:	db '1.0.0',0

; Default theme settings
Theme_TextMode:		db 0x54 ;0xff
Theme_TitleBarVisible:	db TRUE
Theme_WindowBoxVisible:	db TRUE
Theme_StatusBarVisible:	db TRUE
Theme_ProgMenuBar:	db 0x70
Theme_ProgLongName:	db 0x70
Theme_ProgShortName:	db 0x78
Theme_ProgVersion:	db 0x74
Theme_WindowBoxAttr:	db 0x17
Theme_StatusBarAttr:	db 0x47

; Some other default data
MinimumGroupAreaSize:	dw 0x0712

; Include any additional LIB function code that is needed and have not yet been
; included. Basically, this is code required by any functions that were used
; for the first time after the latest "Include_LIB_Functions" or "Terminate"
; macros. There might not be any. However, no code would be generated when
; that is the case.
Include_LIB_Functions

SECTION_BSS

Size_GroupArea:		resw 1	; Calculated current needed demensions.

; Screen position location data
XY_TitleBar:		resw 2
XY_Frame:		resw 2
XY_StatusBar:		resw 2
XY_VerticalBar:		resw 2
XY_HorizontalBar:	resw 2
XY_GroupArea:		resw 2
XY_ItemArea:		resw 2
XY_DataArea:		resw 2

MODE_PROBING:		resw 0x100

SECTION_STACK
; SECTION_HEAP