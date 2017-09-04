MODULE TestABS;
  CONST r = -1.2; i = -2;
  VAR x, y : INTEGER;
      a, b : REAL;
      z : BYTE;
   
BEGIN
  b := r;
  y := i;
  a := ABS(r);
  WriteReal(a);
  a := ABS(b);
  WriteReal(a);
  x := ABS(i);
  WriteInt(x);
  x := ABS(y);
  WriteInt(x);
  WriteLn;
  b := 7.3;
  y := 8;
  WriteReal(ABS(b));
  WriteInt(ABS(y));
  z := 10;
  WriteInt(ABS(z))
END TestABS.