MODULE TestCyclicImport00;
  IMPORT TestCyclicImport01;

  TYPE R0* = RECORD k*: INTEGER END;
  VAR
     r1: TestCyclicImport01.R1;
BEGIN
  r1.x := 1
END TestCyclicImport00.
