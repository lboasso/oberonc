MODULE Out1;
  CONST con = 100;
  VAR           
      a : ARRAY 4 OF INTEGER;
      b : ARRAY 3 OF ARRAY 5 OF INTEGER;
      c : ARRAY 4 OF INTEGER;
      i, j : INTEGER;

BEGIN 
  i := 1;
  j := 2;
  a[j] := 1;
  WriteInt(a[j]);
  a[2] := 2;
  WriteInt(a[2]);
  a[i+j] := 3;
  WriteInt(a[i+j]);
  b[i][j] := 4;
  WriteInt(b[i][j]);
  b[2][4] := 5;
  WriteInt(b[2][4]);
  a[a[i]] := 6;
  WriteInt(a[a[i]]);
  a[c[i]] := 7;
  WriteInt(a[c[i]]);
END Out1.