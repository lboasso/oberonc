MODULE TestImport151;
  IMPORT X := TestImport150, Y:= TestImport150, TestImport150;
  TYPE J = TestImport150.Rec150;
       K = Y.Rec150;
  VAR a: Y.Rec150;
      b: X.Rec150;
      c: J;
      d: K;

BEGIN
  a := b;
  c := d;
  X.Two;
  Y.Two;
  TestImport150.Two
END TestImport151.