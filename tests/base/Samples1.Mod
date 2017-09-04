MODULE Samples1;
  VAR n: INTEGER;
  PROCEDURE Multiply;
    VAR x, y, z: INTEGER;
  BEGIN x := ReadInt(); y := ReadInt(); z := 0;
      WHILE x > 0 DO
        IF x MOD 2 = 1 THEN z := z + y END ;
        y := 2*y; x := x DIV 2
      END ;
      WriteInt(x); WriteInt(y); WriteInt(z); WriteLn
  END Multiply;
  
  PROCEDURE Divide;
    VAR x, y, r, q, w: INTEGER;
  BEGIN x := ReadInt(); y := ReadInt(); r := x; q := 0; w := y;
    WHILE w <= r DO w := 2*w END ;
      WHILE w > y DO
        q := 2*q; w := w DIV 2;
        IF w <= r THEN r := r - w; q := q + 1 END
      END ;
    WriteInt(x); WriteInt(y); WriteInt(q); WriteInt(r); WriteLn
  END Divide;
  
  PROCEDURE BinSearch;
    VAR i, j, k, n, x: INTEGER;
        a: ARRAY 32 OF INTEGER;
  BEGIN x := ReadInt(); k := 0;
    WHILE ~eot() DO a[k] := ReadInt(); k := k + 1 END ;
    i := 0; j := n;
      WHILE i < j DO
      k := (i+j) DIV 2;
      IF x < a[k] THEN j := k ELSE i := k+1 END
    END ;
    WriteInt(i); WriteInt(j); WriteInt(a[j]); WriteLn
  END BinSearch;
  
BEGIN n := ReadInt();
  IF n = 0 THEN Multiply ELSIF n = 1 THEN Divide ELSE BinSearch END
END Samples1.