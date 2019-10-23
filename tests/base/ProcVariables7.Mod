MODULE ProcVariables7;
  TYPE
    ProcA = PROCEDURE;
    ProcB = PROCEDURE;

  VAR
    a: ProcA;

  PROCEDURE A;
  BEGIN
    WriteChar("A")
  END A;


  PROCEDURE B;
  BEGIN
    WriteChar("B")
  END B;

  PROCEDURE C(x: PROCEDURE(b: BYTE; c: CHAR; r: REAL));
  BEGIN
    WriteChar("C")
  END C;

BEGIN
  a := NIL;
  a := A;
  a();
  a := B;
  a;
  C(NIL)
END ProcVariables7.
