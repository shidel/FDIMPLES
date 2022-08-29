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

%undef Preserve_Registers
; %undef DOS_BUG_FIXES
%undef DOSCRT_Range_Check
%undef Support_BIOS_Timer
%undef Support_BIOS_Video
%undef Support_Direct_Video
%undef Support_Mouse
%undef Video_MCGA
%undef Video_VGA
%undef Video_VESA

%include "DOSLIBS.INC"		; One INC to include them all. Some INCS have
				; initialization routines. Some calls for those
				; routines gets inserted automatically. For
				; example DOSCRT requires preparation. If those
				; are not needed, you can save some bytes by
				; including only the required LIBS directly.

; NOTE: Some LIBS have Initialization and Shutdown routines that are compiled
; in or excluded through DEFINES (like Mouse Support). Those types of LIBS
; do not use the EXIT_PROC process and are shut down after any EXIT PROCS are
; called.

Main:
	StdOutStr		'ExitProcTest-'
	ADD_EXIT_PROC		Exit_1 ; label for 1st exit proc call
	ADD_EXIT_PROC		Exit_2 ; label for 2nd exit proc call
	ADD_EXIT_PROC		Exit_3 ; label for 3rd exit proc call

Finished:
; Automatically includes used LIB functions. Also, automatically call the
; EXIT_PROC's in reverse order. Finally, use the EXIT_PROC's EXIT_CODE as
; the ERRORLEVEL that is passed back to DOS.
	Terminate		[EXIT_CODE]

; The EXIT_PROCs. They could exist anywhere in the program.
Exit_1:					; This will be the last EXIT_PROC called
	REMOVE_EXIT_PROC  	Exit_1 	;Must remove itself or infinite loop
	StdOutChar		'1'
	retf				;These use far calls. So far return!

Exit_2:					; This will be the 2nd EXIT_PROC called
	REMOVE_EXIT_PROC  	Exit_2
	StdOutChar		'2'
	retf

Exit_3:					; This will be the 1st EXIT_PROC called
	REMOVE_EXIT_PROC  	Exit_3
	StdOutChar		'3'
	retf

; In this demo/test program Include_LIBS_Function is not needed. Although, they
; are after the 'Terminate" macro, the StdOutChar macro creates a simple DOS
; call directly and the REMOVE_EXIT_PROC macro code is automatically included
; with the ADD_EXIT_PROC code.

; Include_LIB_Functions
