MODULE TestImport42;
IMPORT TestImport40, TestImport41;
  VAR r: TestImport40.T;
BEGIN
  r.x := 8;
  TestImport41.P(r)
END TestImport42.