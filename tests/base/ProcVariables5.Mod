MODULE ProcVariables5;
  TYPE
    T = PROCEDURE (x, y: INTEGER; z: BYTE);
  VAR
    v: T;
    i,j: INTEGER;

  PROCEDURE P (x, y: INTEGER; z: BYTE);
  BEGIN
    WriteInt(x+y+z)
  END P;

  PROCEDURE P1 (p: PROCEDURE (x, y: INTEGER; z: BYTE));
  BEGIN
    IF i = 0 THEN
      INC(i);
      v := p;
      p(1, 2, 3); (* 6 *)
      v(1, 2, 4); (* 7 *)
      P1(p);
      P1(v)
    END;
  END P1;

  PROCEDURE P2 (p: T);
  BEGIN
    IF j = 0 THEN
      INC(j);
      v := p;
      p(1, 2, 3); (* 6 *)
      v(1, 2, 4); (* 7 *)
      P1(p);
      P1(v);
      P2(p);
      P2(v)
    END;
  END P2;
BEGIN
  i := 0;
  j := 0;
  v := P;
  P1(P);
  P2(P)
END ProcVariables5.