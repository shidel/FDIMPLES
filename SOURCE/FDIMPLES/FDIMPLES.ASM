; FreeDOS Installer (FDI) - My Package List Editor Software

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

	Cursor			hide
	WriteStr		'FDIMPLES ', __DATE__, CRLF
	Delay			500
	TextAttr		clLightRed
	WriteStr		'Package media not found!'
	TextAttr		original
	Delay			250
	WriteStr		CRLF, 'please stand by...'
	Delay			1500

MainWindow:
	Window			max
	TextAttr		[Theme_TextAttr]
	ClrScr
	TextAttr		[Theme_TitleBar]
	ClrEOL
	RelativeX		+1
	WriteChar		0xf0
	RelativeX		+4
	TextAttr		[Theme_TitleLongName]
	WriteStr		'FreeDOS Installer - My Package List Editor Software'
	RelativeX		+1
	TextAttr		[Theme_TitleVersion]
	WriteStr		'1.0.0'
	RelativeX		+1
	TextAttr		[Theme_TitleBar]
	WriteChar		'('
	TextAttr		[Theme_TitleShortName]
	WriteStr		'FDIMPLES'
	TextAttr		[Theme_TitleBar]
	WriteChar		')'

MainLoop:
	NotKeyPressed		MainLoop
	ReadKey			ax

Finished:
	VideoResetSettings		; Reset TextMode, Cursor, etc if needed
	TextAttr		original
	ClrScr
	Terminate		0	; Also includes used LIB functions

SECTION .data

Theme_TextAttr:			db 0x17
Theme_TitleBar:			db 0x70
Theme_TitleLongName:		db 0x70
Theme_TitleShortName:		db 0x78
Theme_TitleVersion:		db 0x74
