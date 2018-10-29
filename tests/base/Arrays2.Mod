MODULE Arrays2;
  TYPE X = ARRAY 1 OF INTEGER;
  VAR
       a : X;
       b : ARRAY 1 OF INTEGER;
       (*i : ARRAY 3, 2 OF INTEGER;
       j : ARRAY 2, 4 OF INTEGER;*)
       i0 : ARRAY 4, 3, 2 OF INTEGER;
       j0 : ARRAY 4, 3, 2 OF INTEGER;
  PROCEDURE P(s : X);
  BEGIN  WriteInt(s[0] + 1); (* 3 *)
  END P;
BEGIN
  a[0] := 1;
  b[0] := 2;
  a := b;
  WriteInt(a[0]); (* 2 *)
  (*i := j; illegal assignment *)
  i0[1, 1, 1] := 8;
  j0[1][1][1] := 9;
  WriteInt(i0[1, 1, 1]); (* 8 *);
  i0 := j0;
  WriteInt(i0[1, 1, 1]); (* 9 *);
  P(a);
  P(b);
END Arrays2.