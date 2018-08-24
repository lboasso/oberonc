MODULE TestImport131;
  IMPORT I:=TestImport130, TestImport130;
  VAR
    x: I.TypeD;
    y: TestImport130.TypeD;

BEGIN
  x.a := "@";
  x.d := 1;
  y := x;
  WriteChar(y.a); WriteInt(y.d)
END TestImport131.
