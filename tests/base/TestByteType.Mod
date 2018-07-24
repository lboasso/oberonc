MODULE TestByteType;
  VAR x : INTEGER;
      y : BYTE;
      r : RECORD y : BYTE END;
      ar : ARRAY 1 OF BYTE;

  PROCEDURE P1(i : BYTE): INTEGER;
  BEGIN
    RETURN i + 1
  END P1;

  PROCEDURE P2(i : INTEGER): BYTE;
  BEGIN
    RETURN i + 1
  END P2;

  PROCEDURE Par1(b : BYTE);
  BEGIN
    WriteInt(b)
  END Par1;

  PROCEDURE Par2(b : INTEGER);
  BEGIN
    WriteInt(b)
  END Par2;

  PROCEDURE Ret1(): BYTE;
  BEGIN
    RETURN 8
  END Ret1;

  PROCEDURE Ret2(): INTEGER;
  BEGIN
    RETURN 800
  END Ret2;

  PROCEDURE P3;
    VAR x : INTEGER;
      y : BYTE;
      r : RECORD y : BYTE END;
      ar : ARRAY 1 OF BYTE;
  BEGIN
    WriteInt(P1(255));
    WriteInt(P2(256));
    WriteLn;
    y := 255;
    WriteInt(y);
    x := 129;
    WriteInt(x);
    y := x;
    x := y + 1;
    WriteInt(x);
    x := y;
    WriteInt(x);
    WriteLn;
    r.y := 255;
    WriteInt(r.y);
    x := 129;
    WriteInt(x);
    r.y := x;
    x := r.y + 1;
    WriteInt(x);
    x := r.y;
    WriteInt(x);
    WriteLn;
    ar[0] := 255;
    WriteInt(ar[0]);
    x := 129;
    WriteInt(x);
    ar[0] := x;
    x := ar[0] + 1;
    WriteInt(x);
    x := ar[0];
    WriteInt(x);
    x := y;
    IF x = y THEN WriteInt(1) END
  END P3;

BEGIN
  WriteInt(P1(255));
  WriteInt(P2(256));
  WriteLn;
  y := 255;
  WriteInt(y);
  x := 129;
  WriteInt(x);
  y := x;
  x := y + 1;
  WriteInt(x);
  x := y;
  WriteInt(x);
  WriteLn;
  r.y := 255;
  WriteInt(r.y);
  x := 129;
  WriteInt(x);
  r.y := x;
  x := r.y + 1;
  WriteInt(x);
  x := r.y;
  WriteInt(x);
  WriteLn;
  ar[0] := 255;
  WriteInt(ar[0]);
  x := 129;
  WriteInt(x);
  ar[0] := x;
  x := ar[0] + 1;
  WriteInt(x);
  x := ar[0];
  WriteInt(x);
  x := y;
  IF x = y THEN WriteInt(1) END;
  WriteLn;
  P3;
  WriteLn;
  WriteInt(Ret1());
  WriteInt(Ret2());
  Par1(8);
  Par2(800);
  y := 8;
  WriteInt(y);
  x := 800;
  WriteInt(x)
END TestByteType.
