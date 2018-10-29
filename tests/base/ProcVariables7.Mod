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

BEGIN
  a := A;
  a();
  a := B;
  a
END ProcVariables7.
