MODULE ProcVariables4;
  TYPE P0 = PROCEDURE(VAR x : REAL) : INTEGER;
       P1 = PROCEDURE(VAR x : REAL; VAR y : P0) : INTEGER;
       P2 = PROCEDURE(VAR x : REAL; y : PROCEDURE(VAR x : REAL) : INTEGER) : INTEGER;
       P3 = PROCEDURE(VAR x : REAL; VAR y : PROCEDURE(VAR x : REAL) : INTEGER) : INTEGER;
VAR v: P0;
    v1: P1;
    v2: P2;
    v3: P3;
    f: REAL;

PROCEDURE Floor(VAR x : REAL) : INTEGER;
  RETURN FLOOR(x)
END Floor;

PROCEDURE Floor1(VAR x : REAL; VAR y : P0) : INTEGER;
  RETURN y(x)
END Floor1;

PROCEDURE Floor2(VAR x : REAL; y : PROCEDURE(VAR x : REAL) : INTEGER) : INTEGER;
  RETURN y(x)
END Floor2;

PROCEDURE Floor3(VAR x : REAL; VAR y : PROCEDURE(VAR x : REAL) : INTEGER) : INTEGER;
  RETURN y(x)
END Floor3;

BEGIN
  f := 8.5;
  v := Floor;
  (* WriteInt(Floor(8.0)); ERROR: read-only *) 
  WriteInt(v(f)); (* 8 *) 
  f := 9.5;
  v1 := Floor1;
  WriteInt(v1(f, v)); (* 9 *) 
  f := 10.5;
  v2 := Floor2;
  WriteInt(v2(f, v)); (* 10 *) 
  v3 := Floor3;
  (* WriteInt(v3(f, v)); ERROR: incompatible parameters (see rule E)) *) 
END ProcVariables4.