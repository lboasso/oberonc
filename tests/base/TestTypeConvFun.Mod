MODULE TestTypeConvFun;
  CONST c2 = "A";
  VAR x : REAL;
      y : INTEGER;
      c : CHAR;
      b : BOOLEAN;
      s : SET;
   
BEGIN
  x := 8.9;
  y := 6;
  c := "A";
  b := TRUE;
  s := {1};
  WriteInt(FLOOR(8.9));
  WriteInt(FLOOR(x));
  WriteReal(FLT(6));
  WriteReal(FLT(y));
  WriteInt(ORD(c));
  WriteInt(ORD(c2));
  WriteInt(ORD("A"));
  WriteInt(ORD(b));
  WriteInt(ORD(s));
  WriteInt(ORD("A") + 1);
  WriteChar(CHR(ORD(c) + 1));
  c := CHR(ORD(c) + 2);
  WriteChar(c);
END TestTypeConvFun.