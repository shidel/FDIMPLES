{
    Copyright 2019 Jerome Shidel
    Released Under GPL v2.0 License.
}

unit QASCIIZ; { QuickCrt 9.x, ASCIIZ Unit }

{$I QCRT.DEF}

interface

    { Return Key and Value from ASCIIZ Data Blob. Like Environment Table or
      Application Translation Messages, Returns empty string if not found.
      Returns Key & Value when found. }
    function LookupASCIIZ(Data : pointer; ID : String) : string;

    { Returns just the value portion of an ASCIIZ lookup label Key + Value pair }
    function KeyValueOnly(S : String) : String;

    { Returns up to the first 254 characters of an ASCIIZ string as a pascal
      string. }
    function PascalStr(const AsciiZ) : String;

implementation

{$L QASCIIZ.OBJ}

function LookupASCIIZ(Data : pointer; ID : String) : string;
var
    R : String;
    I : word;
begin
    ID := ID + '=';
    R[0] := ID[0];
    repeat
        Move(Data^, R[1], byte(R[0]));
        if (R <> ID) then begin
            repeat
                Data := Ptr(Seg(Data^), Ofs(Data^) + 1);
            until byte(Data^) = 0;
            Data := Ptr(Seg(Data^), Ofs(Data^) + 1);
        end;
    until (byte(Data^) = 0) or (R = ID);
    if R = ID then begin
        R := '';
        repeat
            if Pos(Char(Data^), #13#10#0 ) < 1 then begin
                Inc(byte(R[0]));
                R[byte(R[0])] := Char(Data^);
            end;
            Data := Ptr(Seg(Data^), Ofs(Data^) + 1);
        until (byte(Data^) = 0) or (Length(R) = 255);
        LookupASCIIZ := R;
    end else
        LookupASCIIZ := '';
end;

function KeyValueOnly(S : String) : String;
begin
    KeyValueOnly := Copy(S, Pos('=', S) + 1, 255);
end;


function PascalStr(const AsciiZ) : String;
type
	AsciiZStr = array[0..$FF] of char;
var
	I : integer;
	S : String;
begin
	PascalStr := '';
	I := 0;
	while (I <= 254) and (AsciiZStr(AsciiZ)[I] <> #0) do Inc(I);
	if I <= 254 then begin
		Move(AsciiZ, S[1], I);
		S[0] := Chr(I);
		PascalStr := S;
	end;
end;

end.
