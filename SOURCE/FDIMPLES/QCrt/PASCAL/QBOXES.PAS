{
Copyright 1990-2016, Jerome Shidel.

This project and related files are subject to the terms of the Mozilla Public License,
v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at
http://mozilla.org/MPL/2.0/.
}

unit QBoxes; { version 9.0x }

{$I QCRT.DEF}

interface

uses QCrt;

const
  { Box Constants }
    bxSingle     = $00; { Single Side/Single Top }
    bxDouble     = $03; { Double Side/Double Top }
    bxDoubleSide = $01; { Double Side/Single Top }
    bxDoubleTop  = $02; { Double Top/Single Side }

  { Box Shadow Styles }
    bsSingleWide = $00; { one character wide }
    bsDoubleWide = $01; { two characters wide }

  { Line Constants }
    lnSingle     = $00;
    lnDouble     = $01;
    lnVertical   = $02;
    lnHorizontal = $00;
    lnNoEnds     = $04;
    lnNoCenter   = $08;


{ Box and Line Functions }
  procedure DrawBox ( X1, Y1, X2, Y2, Style : byte );
  { Draws a box.  Does not move Cursor. }
  procedure DrawShadow ( X1, Y1, X2, Y2, Style : byte );
  { Draws a shadow for a box.  Does not move Cursor. }
  procedure DrawLine ( X1, Y1, Len, Style : byte );
  { Draws a line.  Does not move the Cursor. }

implementation


type
    BoxStr = Array[0..6] of Char;
    LineStr = String[41];

{$I QBOXES.INC}

function FReadChar : char;
begin
    FReadChar := #32;
end;

function FReadCharAttr : word;
begin
    FReadCharAttr := $0732;
end;


{ Box and line functions }
  procedure DrawBox ( X1, Y1, X2, Y2, Style : byte );
    var
      CursorX, CursorY : byte;
      RangeX,  RangeY  : byte;
      I                : byte;
    begin
      RangeX := GetMaxX;
      RangeY := GetMaxY;
      if (X1 > RangeX) or (Y1 > RangeY) then Exit;
      CursorX := WhereX;
      CursorY := WhereY;
      { Draw Top }
      GotoXY( X1, Y1 );
      Write(BoxData[Style][0] );
      for I := X1 + 1 to X2 - 1 do
        if I > RangeX then Break else
          Write( BoxData[Style][4] );
      if (X2 <= RangeX) and (X1 <> X2) then
        Write( BoxData[Style][1] );
      { Draw Sides }
      for I := Y1 + 1 to Y2 - 1 do
        if I > RangeY then Break else
          begin
            GotoXY ( X1, I );
            Write(BoxData[Style][5]);
            if (X2 <= RangeX) and (X1 <> X2) then
              begin
                GotoXY ( X2, I );
                Write(BoxData[Style][5]);
              end;
          end;
      { Draw Bottom }
      if (Y2 <= RangeY) and (Y2 <> Y1) then
        begin
          GotoXY( X1, Y2 );
          Write(BoxData[Style][2] );
          for I := X1 + 1 to X2 - 1 do
            if I > RangeX then Break else
              Write( BoxData[Style][4] );
          if (X2 <= RangeX) and (X1 <> X2) then
            Write( BoxData[Style][3] );
        end;
      GotoXY ( CursorX, CursorY );
    end;

  procedure DrawShadow ( X1, Y1, X2, Y2, Style : byte );
    var
      CursorX, CursorY : byte;
      RangeX,  RangeY  : byte;
      C                : Char;
      Attr             : byte;
      I                : byte;
    begin
      RangeX := GetMaxX;
      RangeY := GetMaxY;
      Inc(X1,1);
      Inc(Y1,1);
      Inc(X2,1);
      Inc(Y2,1);
      if Style and bsDoubleWide = bsDoubleWide then
        Inc(X1, 1);
      if (X1 > RangeX) or (Y1 > RangeY) then Exit;
      CursorX  := WhereX;
      CursorY  := WhereY;
      Attr     := TextAttr;
      TextAttr := $08;
      { Draw Sides }
      if (X2 <= RangeX) and (X1 <> X2) then
        for I := Y1 to Y2 do
          if I > RangeY then Break else
            begin
              GotoXY ( X2, I );
              C := FReadChar;
              GotoXY ( X2, I );
              WriteRawPStr( C );
              if (X2 + 1 <= RangeX) and (Style and bsDoubleWide = bsDoubleWide) then
                begin
                  C := FReadChar;
                  GotoXY ( X2 + 1, I );
                  WriteRawPStr( C );
                end;
            end;
      { Draw Bottom }
      if (Y2 <= RangeY) and (Y2 <> Y1) then
        for I := X1 to X2 - 1 do
          if I > RangeX then Break else
            begin
              GotoXY ( I, Y2 );
              C := FReadChar;
              GotoXY ( I, Y2 );
              WriteRawPStr( C );
            end;
      TextAttr := Attr;
      GotoXY ( CursorX, CursorY );
    end;

  procedure DrawLine ( X1, Y1, Len, Style : byte );
    var
      CursorX, CursorY : byte;
      RangeX,  RangeY  : byte;
      I,       TPos    : byte;
    begin
      CursorX := WhereX;
      CursorY := WhereY;
      RangeX  := GetMaxX;
      RangeY  := GetMaxY;
      Dec(Len);
      TPos := 41;
      Case Style and lnVertical = lnVertical of
        False : begin
          for I := X1 + 1 to X1 + Len - 1 do
            if I > RangeX then Break else
              begin
                GotoXY (I, Y1);
                WriteRawPStr ( LineData.Style[Style and lnDouble, False, Middle][TPos]);
              end;
        end;
        True : begin
          for I := Y1 + 1 to Y1 + Len - 1 do
            if I > RangeY then Break else
              begin
                GotoXY ( X1, I );
                WriteRawPStr ( LineData.Style[Style and lnDouble, True, Middle][TPos]);
              end;
        end;
      end;
      GotoXY ( CursorX, CursorY );
    end;

end.
