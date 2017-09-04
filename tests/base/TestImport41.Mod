MODULE TestImport41;
IMPORT TestImport40;
  PROCEDURE P*(VAR t: TestImport40.T);
  BEGIN WriteInt(t.x)
  END P;
END TestImport41.