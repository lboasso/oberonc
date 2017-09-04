MODULE TestODD;
  VAR x: INTEGER;
      y: SET;
   
BEGIN
  x := 14;
  y := {1..20};
  IF ODD(8) THEN WriteInt(1) END;
  IF ODD(9) THEN WriteInt(2) END;
  IF ~ODD(8) THEN WriteInt(3) END;
  IF ODD(x) OR (x IN y) & (x > 8) THEN WriteInt(4) END
END TestODD.