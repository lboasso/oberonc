MODULE TestImport31;
IMPORT TestImport30;
  VAR y : TestImport30.T;
BEGIN
  y := TestImport30.x;
  WriteChar(y.c)
END TestImport31.