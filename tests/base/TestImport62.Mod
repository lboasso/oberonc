MODULE TestImport62;
IMPORT TestImport60, TestImport61;
  VAR p1* : TestImport61.P1;
BEGIN
  NEW(p1);
  p1.y := "A";
  WriteChar(p1.y);
  IF p1 IS TestImport61.P1 THEN WriteChar("Y") END;
  WriteReal(TestImport60.PI);
  WriteInt(TestImport60.N)
END TestImport62.