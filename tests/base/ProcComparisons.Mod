MODULE ProcComparisons;
  VAR x: BOOLEAN;
   
  PROCEDURE P2(i : INTEGER): INTEGER;
  BEGIN 
    RETURN 2
  END P2;
  
  PROCEDURE P1(i : INTEGER): INTEGER;
  BEGIN 
    RETURN 1
  END P1;
   
BEGIN
  IF P2 = P1 THEN WriteInt(0) END;
  IF P2 = P2 THEN WriteInt(1) END;
  IF P2 # P1 THEN WriteInt(2) END;
  IF P2 # NIL THEN WriteInt(3) END;
  IF P2 = NIL THEN WriteInt(4) END;
  x := P2 = P2;
  x := P2 = NIL
END ProcComparisons.