MODULE CommutativeSwap;
  VAR i : INTEGER;       a : ARRAY 10 OF INTEGER;
BEGIN
  i := 5;
  a[i+3] := 5;
  WriteInt(1 - i + 3 * i); (* 11 *)
  WriteInt(2 - a[i+3]); (* -3 *)
END CommutativeSwap.