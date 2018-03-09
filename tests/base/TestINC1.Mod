MODULE TestINC1;
  VAR k: INTEGER;
      i: ARRAY 2 OF RECORD b : BYTE END;
      j: ARRAY 20 OF BYTE;
      x: BYTE;
  PROCEDURE Effect(VAR x : BYTE) : INTEGER;
  BEGIN 
    WriteInt(x); (* 7 *)
    INC(k); 
    RETURN 0
  END Effect;

  PROCEDURE CallMe(VAR x : BYTE) : INTEGER;
  BEGIN
    RETURN x
  END CallMe;

  PROCEDURE P;
    VAR i: ARRAY 2 OF RECORD b : BYTE END;
        j: ARRAY 20 OF BYTE;
        x: BYTE;
  BEGIN 
    i[0].b := 6;
    x := 10;
    k := 0;
    j[x+5] := 7;
    INC(i[Effect(j[x+5])].b, 2);
    WriteInt(k); (* 1 *)
    WriteInt(i[0].b); (* 8 *)
    INC(i[0].b, j[x+5]);
    WriteInt(i[0].b); (* 15 *)
    INC(j[x+5], i[0].b);
    WriteInt(j[x+5]); (* 22 *)
    INC(x, CallMe(i[0].b));
    WriteInt(x); (* 25 *)
  END P; 
  
BEGIN
  P;
  WriteLn;
  i[0].b := 6;
  x := 10;
  k := 0;
  j[x+5] := 7;
  INC(i[Effect(j[x+5])].b, 2);
  WriteInt(k); (* 1 *)
  WriteInt(i[0].b); (* 8 *)
  INC(i[0].b, j[x+5]);
  WriteInt(i[0].b); (* 15 *)
  INC(j[x+5], i[0].b);
  WriteInt(j[x+5]); (* 22 *)
  INC(x, CallMe(i[0].b));
  WriteInt(x) (* 25 *)
END TestINC1.