MODULE DivMul;
  CONST eight = 8;

  PROCEDURE PrintDiv(a,b : INTEGER);
  BEGIN
    WriteInt(a);
    WriteInt(b);
    WriteInt(a DIV b);
    WriteInt(a MOD b);
    WriteLn
  END PrintDiv;
  
  PROCEDURE Division; 
    VAR x,y : INTEGER;
        a : ARRAY 2 OF INTEGER;
  BEGIN
    PrintDiv(8, 3);
    PrintDiv(8, -3);
    PrintDiv(-8, 3);
    PrintDiv(-8, -3);
    PrintDiv(1, 2);
    PrintDiv(1, -2);
    PrintDiv(-1, 2);
    PrintDiv(-1, -2);
    WriteInt(10 DIV 8);
    WriteInt(10 MOD eight);
    WriteLn;
    x := 8;
    WriteInt(10 DIV x);
    WriteInt(10 MOD x);
    x := 10;
    WriteInt(x DIV 8);
    WriteInt(x MOD eight);
    y := 8;
    WriteInt(x DIV y);
    WriteInt(x MOD y);
    WriteLn;
    a[0] := 8;
    WriteInt(10 DIV a[0]);
    WriteInt(10 MOD a[0]);
    a[0] := 10;
    WriteInt(a[0] DIV 8);
    WriteInt(a[0] MOD eight);
    a[1] := 8;
    WriteInt(a[0] DIV a[1]);
    WriteInt(a[0] MOD a[1]);
  END Division;
  
  PROCEDURE Multiplication; 
    TYPE V = RECORD x : INTEGER END;
    VAR x,y : INTEGER;
        a : ARRAY 2 OF INTEGER;
        b : V;
  BEGIN
    WriteInt(4 * 8);
    WriteInt(4 * eight);
    WriteLn;
    x := 8;
    b.x := 8;
    WriteInt(4 * x);
    WriteInt(4 * b.x);
    x := 4;
    b.x := 4;
    WriteInt(x * 8);
    WriteInt(b.x * eight);
    y := 8;
    WriteInt(x * y);
    WriteInt(y * b.x);
    WriteLn;
    a[0] := 8;
    WriteInt(4 * a[0]);
    WriteInt(b.x * a[0]);
    a[0] := 4;
    b.x := 8;
    WriteInt(a[0] * 8);
    WriteInt(a[0] * b.x);
    a[1] := 8;
    WriteInt(a[0] * a[1]);
  END Multiplication;
BEGIN
  Division;
  WriteLn;
  Multiplication
END DivMul.