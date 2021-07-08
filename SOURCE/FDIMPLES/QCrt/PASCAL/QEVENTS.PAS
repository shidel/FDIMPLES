{
Copyright 1990-2016, Jerome Shidel.

This project and related files are subject to the terms of the Mozilla Public License,
v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at
http://mozilla.org/MPL/2.0/.
}

{$I QCRT.DEF}
unit QEVENTS; { version 9.0x }

interface

uses QCrt, QStrings;

const

  { Event Constants }
    evNothing   = $0000; { Event already handled }
    evKeyDown   = $0010; { Key pressed }
    evKeyboard  = $0010; { Keyboard event }
    evCommand   = $0100; { Command event }
    evBroadcast = $0200; { Broadcast event }
    evSystem    = $0400; { System Event }
    evMessage   = $FF00; { Message (command, broadcast, or user-defined) event }

  { Predefined Event Commands }
    cmNone          = $0000;
    cmClearedEvent  = $0001;
    cmMakeSysReq    = $0002;
    cmBreakSysReq   = $0003;
    cmPrintScreen   = $0004;
    cmBreak         = $0005;
    cmQuit          = $0006;
    cmHelp          = $0007;

  { Keyboard Shift Key Status Flags }
    RightSHift = $0001;
    LeftShift  = $0002;
    EitherCtrl = $0004;
    EitherAlt  = $0008;
    ScrollLock = $0010;
    NumsLock   = $0020;
    CapsLock   = $0040;
    InsertLock = $0080;
    LeftCtrl   = $0100;
    LeftAlt    = $0200;
    SysDown    = $0400;
    PauseFlag  = $0800;
    ScrollDown = $1000;
    NumsDown   = $2000;
    CapsDown   = $4000;
    InsertDown = $8000;

  type
    TPoint = record
      X : byte;
      Y : byte;
    end;

    TEvent = record
      What: Word;
      case Word of
        evNothing: ();
        evKeyDown: (
          ShiftCode : word;
          case Integer of
            0: (KeyCode: Word);
            1: (CharCode: Char;
                ScanCode: Byte));
        evMessage: (
          Command: Word;
          case Word of
            0: (InfoPtr: Pointer);
            1: (InfoLong: Longint);
            2: (InfoWord: Word);
            3: (InfoInt: Integer);
            4: (InfoByte: Byte);
            5: (InfoChar: Char));
    end;

{ Event Functions }
  procedure PurgeEvents;
  procedure ClearEvent(var Event : TEvent);
  procedure GetEvent(var Event : TEvent);
  function  PutEvent(var Event : TEvent) : boolean;

implementation

  const
    KeyBufSize         = 16;
    CommandBufSize     = 128;

{$F+}
(* Internal Event Buffer Handler *)
  type
    PEvents = ^TEvents;
    TEvents = array[1..$FFFF div Sizeof(TEvent)] of TEvent;
    EventBuf = object
         Buf   : PEvents;
         Head,
         Tail,
         Max,
         Count : word;
      procedure Init( ABuf : PEvents; AMax : word );
      procedure Done;
      procedure Purge;
      function  UsedSpace : word;
      function  FreeSpace : word;
      function  GetEvent(var Event : TEvent) : boolean;
      function  PutEvent(var Event : TEvent) : boolean;
    end;

  procedure EventBuf.Init( ABuf : PEvents; AMax : word );
    begin
      Buf := ABuf;
      Max := AMax;
      Purge;
    end;

  procedure EventBuf.Done;
    begin
      Purge;
    end;

  procedure EventBuf.Purge;
    begin
      Head  := 1;
      Tail  := 1;
      Count := 0;
    end;

  function  EventBuf.UsedSpace : word;
    begin
      UsedSpace := Count;
    end;

  function  EventBuf.FreeSpace : word;
    begin
      FreeSPace := Max - Count;
    end;

  function  EventBuf.GetEvent(var Event : TEvent) : boolean;
    begin
      if UsedSpace > 0 then
        begin
          Event := Buf^[Head];
          Inc(Head);
          Inc(Count);
          if Head > Max then Head := 1;
          GetEvent := True;
        end
      else
        GetEvent := False;
    end;

  function  EventBuf.PutEvent(var Event : TEvent) : boolean;
    begin
      if FreeSpace > 0 then
        begin
          Buf^[Tail] := Event;
          Inc(Tail);
          Dec(Count);
          if Tail > Max then Tail := 1;
          PutEvent := True;
        end
      else
        PutEvent := False;
    end;

  var
    KeyBuffer     : array[1..KeyBufSize] of TEvent;
    CommandBuffer : array[1..CommandBufSize] of TEvent;
    KeyBuf        : EventBuf;
    CommandBuf    : EventBuf;

(* Unit shutdown procedure *)
  procedure DoneVideoUnit; far;
    begin
      CommandBuf.Done;
      KeyBuf.Done;
    end;

(* Unit initialization procedure *)
  procedure InitQCRTUnit;
    begin
      KeyBuf.Init    (@KeyBuffer, KeyBufSize);
      CommandBuf.Init(@KeyBuffer, KeyBufSize);
    end;

{ Event Functions }
  procedure PurgeEvents;
    begin
      CommandBuf.Purge;
      KeyBuf.Purge;
    end;

  procedure ClearEvent(var Event : TEvent);
    begin
      Event.What := evNothing;
      Event.Command := cmClearedEvent;
    end;

  procedure GetEvent(var Event : TEvent);
    var
        Temp : TEvent;
    begin
      ClearEvent(Event);
      while KeypressedEnhanced do begin
          ClearEvent(Temp);
          Temp.What := evKeyDown;
          Temp.ShiftCode := MemW[Seg0040:$0017];
          Temp.KeyCode := ReadKeyEnhanced;
          KeyBuf.PutEvent(Temp);
      end;

      if Not CommandBuf.GetEvent(Event) then
      if Not KeyBuf.GetEvent(Event)     then
        begin
        end;
    end;

  function PutEvent(var Event : TEvent) : boolean;
    begin
      PutEvent := CommandBuf.PutEvent(Event);
    end;

begin
  InitQCRTUnit;
end.
