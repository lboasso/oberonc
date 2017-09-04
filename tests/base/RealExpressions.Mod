MODULE RealExpressions;
  CONST NaN* = 0.0/0.0;
  PROCEDURE One() : REAL;
    RETURN 1.0
  END One;
  PROCEDURE Arithmetic;
    VAR  r, x, y : REAL;
  BEGIN
    x := 3.0;
    y := 2.0;
    r := x + y + One();
    WriteReal(r); WriteLn;
    r := x - y;
    WriteReal(r); WriteLn;
    r := x * y;
    WriteReal(r); WriteLn;
    r := x / y;
    WriteReal(r); WriteLn;
    WriteReal(3.5 + 10.0 * 2.0); WriteLn
  END Arithmetic;
  PROCEDURE Relations;
    VAR  x, y : REAL;
  BEGIN
    x := 3.0;
    y := NaN;
    IF x = y THEN WriteInt(1) END;
    IF x <= y THEN WriteInt(1) END;
    IF x < y THEN WriteInt(1) END;
    IF x >= y THEN WriteInt(1) END;
    IF x > y THEN WriteInt(1) END;
    y := 1.E0;
    IF x = y THEN WriteInt(1) END;
    IF x <= y THEN WriteInt(2) END;
    IF x < y THEN WriteInt(3) END;
    IF x >= y THEN WriteInt(4) END;
    IF x > y THEN WriteInt(5) END;
    WriteLn
  END Relations;
BEGIN
  Arithmetic;
  Relations
END RealExpressions.
