MODULE TestNestedProcs;
  PROCEDURE Outer(n: INTEGER);
    PROCEDURE Inner(n: CHAR);
    BEGIN
        Outer(ORD(n)-1)
    END Inner;
  BEGIN
    IF n > 0 THEN Inner(CHR(n)) END;
    WriteInt(n)
  END Outer;
BEGIN
  Outer(3)
END TestNestedProcs.