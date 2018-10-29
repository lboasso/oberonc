MODULE TestReturn0;
  VAR x: INTEGER;
     
  PROCEDURE P1(): INTEGER;
  BEGIN RETURN x
  END P1;

  PROCEDURE P2(): INTEGER;
    RETURN x
  END P2;

  PROCEDURE P3(): INTEGER;
  VAR dummy: INTEGER;
    RETURN x+dummy
  END P3;
BEGIN
  x := 1;
  WriteInt(P1());
  WriteInt(P2());
  WriteInt(P3());
END TestReturn0.
