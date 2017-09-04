MODULE ConstantFoldingAndLoadOp;
  CONST con = 100;
  TYPE
    V = RECORD
          x : ARRAY 10 OF INTEGER;
        END;
  VAR
    i,j : INTEGER;
    c : ARRAY 2 OF INTEGER;
    d : V;
    e : ARRAY 2 OF BOOLEAN;
    b : BOOLEAN;

  PROCEDURE PrintBool(x : BOOLEAN);
  BEGIN IF x THEN WriteInt(1) ELSE WriteInt(0) END;
  END PrintBool;
BEGIN
  j := 2;
  c[0] := 3;
  d.x[0] := 4;
  e[0] := TRUE;
  i := 2 * 3 + 10 DIV 2;
  WriteInt(i);
  i := 2*c[0];
  WriteInt(i);
  i := 2*d.x[0];
  WriteInt(i);
  i := 2*con;
  WriteInt(i);
  i := j*c[0];
  WriteInt(i);
  i := j*d.x[0];
  WriteInt(i);
  i := j*con;
  WriteInt(i);
  WriteLn;
  i := c[0] - 2;
  WriteInt(i);
  i := d.x[0] - 2;
  WriteInt(i);
  i := con - 2;
  WriteInt(i);
  i := c[0] - j;
  WriteInt(i);
  i := d.x[0] - j;
  WriteInt(i);
  i := con - j;
  WriteInt(i);
  i := con + 0;
  WriteInt(i);
  i := con - 0;
  WriteInt(i);
  WriteLn;
  b := TRUE & e[0];
  PrintBool(b);
  b := b & e[0];
  PrintBool(b);
  b := e[0] & TRUE;
  PrintBool(b);
  b := e[0] & b;
  PrintBool(b);
  b := (TRUE & e[0]) OR e[0];
  PrintBool(b);
  b := TRUE OR TRUE;
  PrintBool(b);
END ConstantFoldingAndLoadOp.