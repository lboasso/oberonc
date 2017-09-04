MODULE CaseRecord2;
  TYPE 
    P = POINTER TO R;
    P0 = POINTER TO R0;
    P1 = POINTER TO R1;
    P2 = POINTER TO R2;
    R = RECORD a: INTEGER; next : P END ;
    R0 = RECORD (R) b: INTEGER; c : ARRAY 11 OF INTEGER END ;
    R1 = RECORD (R) b: REAL END ;
    R2 = RECORD (R) b: SET END ;
    
  VAR p: P; p0 : P0; p1 : P1; p2 : P2; i : INTEGER;
  
  PROCEDURE Run(p : P);
    VAR tmp : P;
  BEGIN
    CASE p OF
      P0: p.b := 10; p.c[p.b] := p.b; i := 0;
          tmp := p.next;
          CASE tmp OF
            P2: tmp.b := {3}; i := 1 
          END;
    | P1: p.b := 2.5; i:= 2;
          CASE p OF
            P1: p.b := 3.0; i := 3 
          END;
    | P2: p.b := {0, 2}; i:= 4
  END;
  WriteInt(i)
  END Run;
BEGIN
  NEW(p1);
  p := p1;
  Run(p);
  NEW(p0);
  NEW(p2);
  p := p0;
  p.next := p2;
  Run(p);
END CaseRecord2.