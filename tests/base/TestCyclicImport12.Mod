MODULE TestCyclicImport12;
  IMPORT TestCyclicImport10;
  VAR
     r0: TestCyclicImport10.R0;
     w*: INTEGER;
BEGIN
  r0.k := 2;
  w := 8
END TestCyclicImport12.
