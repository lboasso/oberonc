MODULE TestImport53;
IMPORT TestImport51, TestImport52; (*twice hidden import of TestImport50.T*)
  VAR
    p0: TestImport51.T;
    p1: TestImport52.T;
    p2: TestImport51.T1;
    p3: TestImport52.T1;
BEGIN
  p0 := p1;
  p2 := p3;
END TestImport53.