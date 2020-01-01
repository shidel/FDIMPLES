{
    Copyright 2018 Jerome Shidel
    Released Under GPL v2.0 License.
}
unit FileIO;

interface

var
    StandbyProc : Procedure;

function UnixRead(var F : File; var S : String) : integer;

implementation

function UnixRead(var F : File; var S : String) : integer;
var
    P : longInt;
    N : boolean;
    C, D, O : integer;
begin
    if Assigned(StandbyProc) then StandbyProc;
    P := FilePos(F);
    BlockRead(F, S[1], Sizeof(S) - 10, C);
    S[0] := chr(C);
    N := False;
    if C = 0 then
        UnixRead := -1
    else begin
        O := 0;
        D := Pos(#$0a, S);
        if (D <> 0) and (D <= Ord(S[0])) then begin
            S[0] := Chr(D - 1);
            Inc(O);
            N := true;
        end;
        D := Pos(#$0d, S);
        if (D <> 0) and (D <= Ord(S[0])) then begin
            S[0] := Chr(D - 1);
            Inc(O);
            N := true;
        end;
 {       D := 1;
        while (D <= Length(S)) and (S <> '') do begin
            if (Ord(S[D]) = $0a) or (Ord(S[D]) = $0d) then begin
                Delete (S, D, 1);
                Inc(O);
            end else Inc(D);
        end;}
        if N then
            UnixRead := 1
        else
            UnixRead := 0;
        Seek(F, P + Ord(S[0]) + O);
    end;
end;

begin
    StandbyProc := nil;
end.