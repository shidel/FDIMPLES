; System for DOS v1.0

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

%ifndef DOSSYS_INC_DEFINED
%define DOSSYS_INC_DEFINED
; -----------------------------------------------------------------------------
; List of macros and functions provided by this file.
; Note: Macros often have have preferred register to use when passing when
; passing them a parameter. Using the preferred register will result in saving
; a few bytes of code. However, it is not required.

; Send individual characters to standard output device
; MACRO:  StdOutChar 1-*
; INPUT:  %1+ = Characters (prefers dl)
; OUTPUT: none
%include "DOSSYS/STDOCHAR.INC"

; Send ASCIIz string to standard output device
; MACRO:  StdOutStr 1+
; INPUT:  %1+ = ASCIIz string sent to STDOUT (prefers si)
; OUTPUT: none
%include "DOSSYS/STDOSTRZ.INC"

; Send CRLF to standard output device
; MACRO:  StdOutCRLF 0-1
; INPUT:  %1 = Number of CRLF to output device (default 1, prefers cx)
; OUTPUT: none
%include "DOSSYS/STDOCRLF.INC"

; Send byte as HEX to standard output device
; MACRO:  StdOutHexByte 1-*
; INPUT:  %1+ = byte to print (prefers al)
; OUTPUT: none
%include "DOSSYS/STDOBYTE.INC"

; Send word as HEX to standard output device
; MACRO:  StdOutHexWord 1-*
; INPUT:  %1+ = word to print (prefers ax)
; OUTPUT: none
%include "DOSSYS/STDOWORD.INC"

; Terminate Program
; MACRO:  Terminate 1-2+
; INPUT:
; 	%1  = DOS Exit Code (prefers al)
; 	%2+ = Any message sent to STDOUT at exit
; OUTPUT:
; 	None: Does not return
%include "DOSSYS/TERMINAT.INC"
; -----------------------------------------------------------------------------
%endif
