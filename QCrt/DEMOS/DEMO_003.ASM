; Copyright 2016 Jerome Shidel
; Released Under GPL v2.0 License.

use16

org 100h

%idefine SaveAllRegs
; %idefine TargetOS DOS     ; its the default
; %idefine TargetCPU 286    ; its the default

%include "QCRT.ASM"

pushcall    TextMode, 0x0001
pushcall    HideCursor

mov         [TextAttr], byte 0x1F
pushcall    ClrScr
pushcall    Window, 2, 2, 38, 23
mov         [TextAttr], byte 0x74
pushcall    ClrScr

pushcall    WriteStr, ds, HelloWorld
pushcall    WriteStr, ds, PressAKey
WaitForKey:
    pushcall    KeyPressed
    jz          WaitForKey
pushcall    ReadKey

Terminate 0

; Verbose way of setting AX, AX, BX, DX window to dimensions
; and CX to ( height - 1 ) / 2
mov         ax, 1
xor         dx, dx
mov         cx, dx
mov         bx, [ScreenMax]
xchg        dl, bh
mov         cl, dl
inc         bx
inc         dx
shr         cl, 1
inc         cl

LoopColors:

    push        ax
    and         ax, 0x07
    pushcall    TextBackground, ax
    pop         ax
    pushcall    Window, ax, ax, bx, dx
    pushcall    ClrScr
    inc         ax
    dec         bx
    dec         dx
    loop        LoopColors

pushcall    NoSound

; A window that may be shifty
mov  ax, 4
xor  cx, cx
xor  bx, bx
mov  bx, [ScreenMax]
xchg cl, bh
sub bx, 2
sub cx, 2
pushcall Window, ax, ax, bx, cx

; We are feeling a bit shifty
mov ax, [WindMin]
mov cx, [WindMax]
sub ch, ah
mov cl, ch
mov ch, 0
inc cl

mov     [TextAttr], byte 0x4F
ShiftyLoop:
        pushcall    ScrollUp, 1
        pushcall    ScrollLeft, 1
        pushcall    Delay, 100
    loop        ShiftyLoop

; Minimal restoring of some stuff like TextMode and Cursor
; then exit to OS with no error code
Terminate 0

HelloWorld:     DB "Hello,",9,"World! (Demo #3)",CRLF,0
PressAKey:      DB "Press a key to continue.",CRLF,0