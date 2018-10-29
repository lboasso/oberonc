MODULE OpenArrays2;
  TYPE ARR = ARRAY 3 OF INTEGER;
  VAR
    x : ARR;
    i : INTEGER;
  
  PROCEDURE P1(VAR b : ARRAY OF INTEGER; c : ARR; VAR d : ARR; e : ARRAY OF INTEGER);
  BEGIN
    WriteInt(b[i]);
    WriteInt(c[i]);
    WriteInt(d[i]);
    WriteInt(e[i])
  END P1; 

BEGIN
  i := 1;
  x[i] := 8;
  P1(x, x, x, x)
END OpenArrays2.
