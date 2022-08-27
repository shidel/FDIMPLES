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

use16

cpu 8086

org 0x100

SECTION .text

%include "FEATURES.INC"		; Default DEFINES & options for library macros

; %undef Preserve_Registers	; disable preserving registers in macros
; %undef DOS_BUG_FIXES		; keep some fixes for various DOS and BIOS bugs
%undef DOSCRT_Range_Check	; disable out of bounds coordinate settings
%undef Support_BIOS_Timer	; disable attempts to use int15 timer
; %undef Support_BIOS_Video	; keep BIOS video support
%undef Support_Direct_Video	; Direct video addressing, not yet implemented
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

SECTION_CODE

	call			Initialize
	call			DrawMainWindow

MainLoop:
	NotKeyPressed		MainLoop
	ReadKey			ax

Finished:
	VideoResetSettings		; Reset TextMode, Cursor, etc if needed
	TextAttr		0x07
	ClrScr
	Terminate		0	; Also includes needed LIB function code

DrawMainWindow:
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
	cmp			[Theme_WindowBoxVisible], byte True
	jne			.NoWindowBox
	Window			max
	TextAttr		[Theme_WindowBoxAttr]
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
	Window			[XY_GroupArea], [XY_GroupArea + 2]
	TextAttr		[Theme_WindowBoxAttr]
	ClrScr
	Window			max
	DrawLine		word [XY_VerticalBar], word [XY_VerticalBar + 2], lnVertical + lnSingle + lnConnect

	ret

Initialize:
	mov			ax, [Theme_GroupAreaSize]
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

CalculateScreenPositions:
	Window			max
	WindMin			ax
	WindMax			dx

	; add			ax, 0x0101
	; sub			dx, 0x0101

	push			dx
	mov			dh, ah
	mov			[XY_TitleBar], ax
	mov			[XY_TitleBar + 2], dx
	pop			dx
	inc			ah
	dec			dh
	mov			[XY_Frame], ax
	mov			[XY_Frame + 2], dx
	pushm			ax, dx
	inc			dh
	mov			ah, dh
	mov			[XY_StatusBar], ax
	mov			[XY_StatusBar + 2], dx
	popm			ax, dx
	add			ax, 0x0101
	mov			dx, [Size_GroupArea]
	add			dx, ax
	mov			[XY_GroupArea], ax
	mov			[XY_GroupArea + 2], dx
	add			dx, 0x0101
	sub			dh, ah
	mov			al, dl
	mov			dl, dh
	xor			dh, dh
	mov			[XY_VerticalBar], ax
	mov			[XY_VerticalBar + 2], dx


	ret

SECTION_DATA

Text_ProgLong:		db 'FreeDOS Installer - My Package List Editor Software',0
Text_ProgShort: 	db 'FDIMPLES',0
Text_ProgVersion:	db '1.0.0',0

Theme_TextMode:		db 0xff
Theme_TitleBarVisible:	db TRUE
Theme_WindowBoxVisible:	db TRUE
Theme_StatusBarVisible:	db TRUE
Theme_ProgMenuBar:	db 0x70
Theme_ProgLongName:	db 0x70
Theme_ProgShortName:	db 0x78
Theme_ProgVersion:	db 0x74
Theme_WindowBoxAttr:	db 0x17
Theme_StatusBarAttr:	db 0x47

Theme_GroupAreaSize:	dw 0x0712

	Include_LIB_Functions	; Include additional needed LIB function code

SECTION_BSS

Size_GroupArea:		resw 1

XY_TitleBar:		resw 2
XY_Frame:		resw 2
XY_StatusBar:		resw 2
XY_GroupArea:		resw 2
XY_VerticalBar:		resw 2
XY_HorizontalBar:	resw 2



