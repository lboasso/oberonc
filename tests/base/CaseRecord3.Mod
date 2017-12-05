MODULE CaseRecord3;
  TYPE
    P = POINTER TO R;
    P0 = POINTER TO R0;
    P1 = POINTER TO R1;
    P2 = POINTER TO R2;
    R = RECORD a: INTEGER END ;
    R0 = RECORD (R) b: REAL; y: P0 END ;
    R1 = RECORD (R0) c: INTEGER END ;
    R2 = RECORD (R1) d: REAL; z: ARRAY 10 OF P1 END ;

  VAR p: P; p2 : P2; i : INTEGER;
BEGIN
  NEW(p2); NEW(p2.z[2]); NEW(p2.z[3]);
  p2.d := 2.0;
  p2.c := 6;
  p2.z[2].b := 3.0;
  p2.a := 1;
  p2.z[3].c := 8;
  p2.y := p2.z[3];
  p := p2;
  CASE p OF
    P0: p.b := 1.5 + p(P2).d + p(P2).z[2].b + FLT(p.a) +
               FLT(p.y(P1).c) + FLT(p(P1).c DIV 3);
        WriteInt(FLOOR(p.b)); (* 17 *)
        i:= p.a |
    P2: p.b := 1.8; i:= 2
  END;
  WriteInt(i) (* 1 *)
END CaseRecord3.
