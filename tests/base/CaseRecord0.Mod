MODULE CaseRecord0;
  TYPE 
    R = RECORD a: INTEGER END ;
    R0 = RECORD (R) b: REAL END ;
    R1 = RECORD (R) b: INTEGER END ;
    R2 = RECORD (R) b: SET END ;
    P = POINTER TO R;
    P0 = POINTER TO R0;
    P1 = POINTER TO R1;
    P2 = POINTER TO R2;
    
  VAR p: P; p1 : P1; i : INTEGER;
BEGIN
  NEW(p1); p := p1; p.a := 1;
  CASE p OF
    P0: p.b := 2.5; i := 0 |
    P1: p.b := p.a + p.b + p.b DIV 3; i:= p.a |
    P2: p.b := {0, 2}; i:= 2
  END;
  WriteInt(i) (* 1 *)
END CaseRecord0.