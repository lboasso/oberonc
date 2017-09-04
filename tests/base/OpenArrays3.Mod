MODULE OpenArrays3;
  TYPE ARR = ARRAY 3 OF INTEGER;
       R = RECORD i : INTEGER END;
  VAR
    d : ARRAY 10 OF INTEGER;
    x : ARRAY 3 OF INTEGER;
    e : ARRAY 10 OF R;
    y : ARRAY 3 OF R;
    f : ARRAY 10 OF ARRAY 3 OF INTEGER;
    z : ARRAY 3 OF ARR;
  
  PROCEDURE P0(VAR a : ARRAY OF INTEGER; b : ARRAY OF R; c : ARRAY OF ARR);
  BEGIN
    d := a;
    WriteInt(d[1]);
    e := b;
    WriteInt(e[1].i);
    f := c;
    WriteInt(f[1][1])
  END P0; 
  
  PROCEDURE P1(VAR a : ARRAY OF INTEGER; b : ARRAY OF R; c : ARRAY OF ARR);
  VAR
    d : ARRAY 10 OF INTEGER;
    e : ARRAY 10 OF R;
    f : ARRAY 10 OF ARR;
  BEGIN
    d[1] := -1;  e[1].i := -1; f[1][1] := -1;
    d := a;
    WriteInt(d[1]);
    e := b;
    WriteInt(e[1].i);
    f := c;
    WriteInt(f[1][1])
  END P1; 

BEGIN
  d[1] := -1; x[1] := 1;
  e[1].i := -1; y[1].i := 2;
  f[1][1] := -1; z[1][1] := 3;
  P0(x, y, z);
  WriteLn;
  x[1] := 4;
  y[1].i := 5;
  z[1][1] := 6;
  P1(x, y, z)
END OpenArrays3.