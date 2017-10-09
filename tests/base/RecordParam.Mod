MODULE RecordParam;
  TYPE RP = POINTER TO R;
    R = RECORD
          i: INTEGER;
          p: RP;
        END;
  VAR
  g0, g1, g2: RP;

  PROCEDURE Print(x: RP);
  BEGIN
    WriteInt(x.i);
    IF x.p = NIL THEN WriteInt(0) ELSE WriteInt(x.p.i) END;
    WriteLn
  END Print;

  PROCEDURE Init0(VAR x: RP; i: INTEGER);
  BEGIN
    x.i := i;
    NEW(x.p);
    x.p.i := i;
  END Init0;
  
  PROCEDURE Init1(x: RP; i: INTEGER);
  BEGIN
    x.i := i;
    NEW(x.p);
    x.p.i := i;
  END Init1;
  
  PROCEDURE Init2(VAR x: R; i: INTEGER);
  BEGIN
    x.i := i;
    NEW(x.p);
    x.p.i := i;
  END Init2;
  
PROCEDURE Run*;
BEGIN
  NEW(g0);
  g0.p := g0;
  Init0(g0.p, 8);
  Print(g0.p); (* 8 8 *)

  NEW(g1);
  g1.p := g1;
  Init1(g1.p, 8);
  Print(g1.p); (* 8 0 *)

  NEW(g2);
  g2.p := g2;
  Init2(g2.p^, 8);
  Print(g2.p); (* 8 0 *)

END Run;

BEGIN
 Run
END RecordParam.
