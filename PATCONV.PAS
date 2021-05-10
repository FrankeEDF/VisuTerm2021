unit Patconv;

interface
function Patt2Array (Pattern : Ansistring; P : PAnsiChar; IsHex : Boolean) : word;
function Patt2String (Pattern : AnsiString; IsHex : Boolean) : AnsiString;
function Array2PattStr (ArrayData : PAnsiChar; DataCount : Word) : AnsiString;
function String2PattStr (Str : AnsiString) : AnsiString;
function HexString (ArrayData : PAnsiChar; DataCount : Word) : AnsiString;

implementation
uses SysUtils;

function Patt2Array (Pattern : AnsiString; P : PAnsiChar; IsHex : Boolean) : word;
var
  readpos  : word;
  writepos : word;
procedure readNumberBase (Base : Byte);
var
  Number : Byte;
  Nipp   : Byte;
begin
  Number := 0;
  while (readpos <= length (Pattern)) do begin
    case (Pattern [readpos]) of
      '0' : Nipp :=0 ;
      '1' : Nipp :=1 ;
      '2' : Nipp :=2 ;
      '3' : Nipp :=3 ;
      '4' : Nipp :=4 ;
      '5' : Nipp :=5 ;
      '6' : Nipp :=6 ;
      '7' : Nipp :=7 ;
      '8' : Nipp :=8 ;
      '9' : Nipp :=9 ;
      'A' : Nipp :=10;
      'B' : Nipp :=11;
      'C' : Nipp :=12;
      'D' : Nipp :=13;
      'E' : Nipp :=14;
      'F' : Nipp :=15;
      'a' : Nipp :=10;
      'b' : Nipp :=11;
      'c' : Nipp :=12;
      'd' : Nipp :=13;
      'e' : Nipp :=14;
      'f' : Nipp :=15;
      else Nipp := 16;
    end;
    if Nipp < Base then begin
      Number := Number * Base + Nipp;
    end else begin
      break;
    end;
    inc (ReadPos);
  end;
  P^ := AnsiChar (Number);
  inc (P);
  inc (writepos);
end;

procedure readNumber ;
begin
  inc (readPos);
  if readPos <= length (Pattern) then begin
    if (Pattern [readpos] = 'x') OR (Pattern [readpos] = 'X') then begin
      inc (readPos);
      readNumberBase (16);
    end else begin
      readNumberBase (8);
    end;
  end else begin
    P^ := char (0);
    inc (P);
    inc (writepos);
  end;
end;


procedure readLiteral;
begin
  if readPos <= length (Pattern) then begin
    case Pattern [readpos] of
      't' : begin P^ := #$09; inc (p); inc (writePos); inc (readPos); end;
      'n' : begin P^ := #$0D; inc (p); inc (writePos);
                  P^ := #$0A; inc (p); inc (writePos); inc (readPos); end;
      'x' : begin inc (readPos); ReadNumberBase (16); end;
      '0' : begin inc (readPos); ReadNumberBase (8); end;
      else  begin P^ := Pattern [readpos]; inc (P); inc (writePos); inc (readPos); end;
    end;
  end;
end;

procedure readString (endchar : ansiChar);
begin
  inc (Readpos);
  while (Pattern [readpos] <> endchar) and (readpos <= length (Pattern)) do begin
    if Pattern [readpos] = '\' then begin
      inc (readpos);
      readLiteral;
    end else begin
      P^ := Pattern [readpos];
      inc (P);
      inc (writepos);
      inc (readpos);
    end;
  end;
  inc (readpos);
end;


begin
  readpos := 1;
  WritePos := 0;
  while (readpos <= length (Pattern)) do begin
    case Pattern [readpos] of
      '"'  : readString ('"');
      '''' : readString ('''');
      '0'  : if ishex then readNumberBase(16) else readNumber;
      '$'  : begin inc (readPos); readNumberBase (16); end;
      '1' .. '9' : if ishex then readNumberBase(16) else readNumberBase(10);
      'A' .. 'F',
      'a' .. 'f' : if ishex then readNumberBase(16) else inc (readpos);
      '\'  : begin inc (readPos); readLiteral; end;
      else inc (readpos);
    end;
  end;
  result := WritePos;
end;

function Patt2String (Pattern : AnsiString;IsHex : Boolean) : AnsiString;
var
  Count : Word;
begin
  Count := Patt2Array (Pattern, @result[1], IsHex);
  SetLength (result, Count);
end;

function Array2PattStr (ArrayData : PAnsiChar; DataCount : Word) : AnsiString;
var
  n : word;
begin
  result := '';
  if DataCount > 0 then begin
    for n := 0 to dataCount - 1 do begin
      result := result + Format ('0x%.2X ', [Byte (ArrayData^)]);
      inc (ArrayData);
    end;
  end;
end;

function HexString (ArrayData : PAnsiChar; DataCount : Word) : AnsiString;
var
  Dst : PAnsiChar;
const
  NippTab : array [0..15] of Ansichar = '0123456789ABCDEF';
begin
  if DataCount < 1 then begin
    result := '';
    exit;
  end;
  SetLength (Result, DataCount * 3 - 1);
  fillchar (Result[1], DataCount * 3 - 1, ' ');
  Dst :=  @Result[1];
  While DataCount > 0 Do
  Begin
    Dst^ := NippTab [Byte (ArrayData^) shr 4];
    inc (Dst);
    Dst^ := NippTab [Byte (ArrayData^) and $F];
    inc (Dst,2);
    inc (ArrayData);
    dec (DataCount);
  End;
end;

function String2PattStr (Str : AnsiString) : AnsiString;
begin
  result := Array2PattStr (@Str[1], Length (Str));
end;



end.
