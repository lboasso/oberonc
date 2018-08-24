MODULE TestImport112;
  IMPORT TestImport110, TestImport111;
  VAR
    x: TestImport110.X;
    y: TestImport111.Y;

BEGIN
  y := TestImport111.TWELVE;
  x.i := y;
  WriteInt(x.i)
END TestImport112.