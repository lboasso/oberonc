MODULE TestReadOnlyPar;
  TYPE ARR = ARRAY 3 OF INTEGER;

  PROCEDURE P2(VAR e : ARRAY OF INTEGER);
  END P2;
  
  PROCEDURE P3(VAR e : ARR);
  END P3;
  
  PROCEDURE P1(k : ARR);
  BEGIN
      P2(k); (*read-only*)
      P3(k) (*read-only*)
  END P1;
  
END TestReadOnlyPar.