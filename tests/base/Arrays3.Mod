MODULE Arrays3;
  TYPE ARR = ARRAY 3 OF INTEGER;
       ARR2 = ARRAY 3, 2 OF INTEGER;
  VAR
    x : ARRAY 3 OF INTEGER;
    y : ARR;
    i : ARRAY 3, 2 OF INTEGER;
    k0, m0 : ARRAY 0 OF INTEGER;
    k1, m1 : ARRAY 3, 0 OF INTEGER;
  PROCEDURE P1(VAR b, c : ARRAY OF INTEGER; d : ARRAY OF INTEGER);
    VAR y2 : ARR;
        (*y3 : ARRAY 0 OF INTEGER;
        y4 : ARRAY 1 OF INTEGER;*)
    BEGIN
      (* b := c; illegal assignment *)
      (* b := d;  illegal assignment *)
      y2[1] := 0;
      y2 := b;
      WriteInt(y2[1]); (*88*)
      (* y3 := b;  illegal assignment *)
      (*y4:= b;  trap *)
  END P1;

  PROCEDURE P4(b : ARRAY OF ARRAY OF INTEGER);
    VAR k : INTEGER;
  BEGIN
    k := b[0][1];
    WriteInt(k) (*8*)
  END P4;

  PROCEDURE P3(VAR b : ARRAY OF ARRAY OF INTEGER);
  BEGIN b[0][1] := 8
  END P3;

  PROCEDURE P5(VAR b : ARR2);
    VAR c : ARRAY 3, 2 OF INTEGER;
  BEGIN
    c[0][1] := 9;
    b := c
  END P5;

BEGIN
  y[1] := 88;
  P1(y, y, y);
  x[1] := 1;
  y[1] := 99;
  y := x;
  WriteInt(y[1]); (*1*)
  i[0][1] := 0;
  P3(i);
  WriteInt(i[0][1]); (*8*)
  P4(i);
  P5(i);
  WriteInt(i[0][1]); (*9*)
  k0 := m0;
  k1 := m1;
END Arrays3.