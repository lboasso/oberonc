MODULE CaseRecord1;
  TYPE 
    R = RECORD a: INTEGER END ;
    R0 = RECORD (R) b: INTEGER END ;
    R1 = RECORD (R) b: REAL END ;
    R2 = RECORD (R) b: SET END ;

  VAR r1: R1; r : R; i : INTEGER;

  PROCEDURE P(VAR r : R);
  BEGIN
    CASE r OF
      R0: r.b := 10; i := 0 |
      R1: r.b := 2.5; i:= 1 |
      R2: r.b := {0, 2}; i:= 2
    END;
    WriteInt(i)
  END P;

BEGIN
  P(r1);
  i := -1;
  P(r)
END CaseRecord1.