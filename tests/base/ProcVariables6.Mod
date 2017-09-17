MODULE ProcVariables6;
  TYPE
    Q = PROCEDURE (c: CHAR);
  VAR
    q: Q;

  PROCEDURE P0(VAR j: Q);
    PROCEDURE P1(c: CHAR);
    BEGIN
      WriteChar(c);
      WriteLn
    END P1;
  BEGIN
    j := P1
  END P0;

BEGIN
  P0(q);
  q("a")
END ProcVariables6.
