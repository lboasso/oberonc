MODULE VarParGuard;
  TYPE
    P0 = POINTER TO R0;
    P1 = POINTER TO R1;
    R0 = RECORD x: INTEGER END;
    R1 = RECORD(R0)
           y: ARRAY 10 OF R0;
           z: INTEGER;
         END;

  VAR
    p0: P0;
    p1: P1;

  PROCEDURE Proc(VAR p1: P1);
  BEGIN
    p1.x := p1.x + p1.z
  END Proc;

  PROCEDURE ProcInt(VAR c: INTEGER);
  BEGIN c := 6
  END ProcInt;

  PROCEDURE Proc1(VAR p0: P0);
  BEGIN
    Proc(p0(P1))
  END Proc1;

  PROCEDURE Proc2;
    VAR
      p0: P0;
      p1: P1;
  BEGIN
    NEW(p1);
    p0 := p1;
    p0.x := 1;
    p0(P1).z := 4;
    Proc(p0(P1));
    WriteInt(p0.x)
  END Proc2;

  PROCEDURE Proc3;
    VAR
      p0: P0;
      p1: P1;
      i: BYTE;
  BEGIN
    i := 2;
    NEW(p1);
    p0 := p1;
    p0(P1).y[1+i].x := 1;
    ProcInt(p0(P1).y[1+i].x);
    WriteInt(p0(P1).y[1+i].x);
  END Proc3;

  PROCEDURE Proc4;
    VAR
      p0: ARRAY 5 OF P0;
      p1: P1;
      i: BYTE;
  BEGIN
    i := 2;
    NEW(p1);
    p0[1+i] := p1;
    p0[1+i].x := 1;
    p0[1+i](P1).z := 6;
    Proc(p0[1+i](P1));
    WriteInt(p0[1+i].x)
  END Proc4;

  PROCEDURE Proc5;
    VAR
      r: RECORD a: P0 END;
      p1: P1;
  BEGIN
    NEW(p1);
    r.a := p1;
    r.a.x := 1;
    r.a(P1).z := 7;
    Proc(r.a(P1));
    WriteInt(r.a.x)
  END Proc5;

  PROCEDURE Proc6;
    VAR
      r: RECORD a: ARRAY 5 OF P0 END;
      p1: P1;
      i: BYTE;
  BEGIN
    i := 2;
    NEW(p1);
    r.a[1+i] := p1;
    r.a[1+i].x := 1;
    r.a[1+i](P1).z := 8;
    Proc(r.a[1+i](P1));
    WriteInt(r.a[1+i].x)
  END Proc6;

BEGIN
  NEW(p1);
  p0 := p1;

  p0.x := 1;
  p0(P1).z := 2;
  Proc(p0(P1));
  WriteInt(p0.x);

  p0.x := 1;
  p0(P1).z := 3;
  Proc1(p0);
  WriteInt(p0.x);

  Proc2;
  Proc3;
  Proc4;
  Proc5;
  Proc6
END VarParGuard.