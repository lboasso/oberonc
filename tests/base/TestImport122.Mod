MODULE TestImport122;
  IMPORT TestImport121, X := TestImport120;

  VAR
    a: X.TypeA;
    b: X.TypeB;
    c: TestImport121.TypeC;
    d: TestImport121.TypeD;

BEGIN
  c := a;
  b := d
END TestImport122.
