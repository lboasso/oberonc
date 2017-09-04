MODULE Out3;
  CONST con = 100;
  VAR           
    i, j, k : INTEGER;
    o, x : BOOLEAN;
  PROCEDURE gdc(m, n : INTEGER) : INTEGER;
  BEGIN
    WHILE m > n DO m := m - n
    ELSIF n > m DO n := n - m
    END;
    RETURN m
  END gdc;
BEGIN 
  i := 5;
  j := 5;
  IF i > j THEN 
    k := 1;
    WriteInt(k)
  ELSIF i = j THEN
    k := 2;
    WriteInt(k);
    o := TRUE;
    IF k >= 1 THEN
      WHILE (i # j) OR o & (k < 4) DO 
        k := k + 1;
        WriteInt(k)
      END
    END
  ELSE
    k := 3;
    WriteInt(k)
  END;
  WHILE (i # j) OR o & (k <= 4) DO 
    k := k + 1;
    WriteInt(k)
  END;
  REPEAT 
    i := i + 1;
    WriteInt(i)
  UNTIL (( i = 6) & o) OR ((j = 6) OR ~o);
  IF i > 0 THEN WriteInt(7) END;
  i := +12; x := TRUE;
  o := (8 > 3) & x & (i IN  {0..13});
  IF o THEN WriteInt(8) END;
  i := 8;
  WriteLn;
  REPEAT 
    i := i + 1;
    WriteInt(i)
  UNTIL ( (i = 15) OR (j = 10) & ~o) & ((j # 6) OR ~o);
  WriteInt(gdc(8, 12))
END Out3.