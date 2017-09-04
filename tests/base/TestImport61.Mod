MODULE TestImport61;
IMPORT TestImport60;
  TYPE
    P1* = POINTER TO R1;
    R1* = RECORD(TestImport60.R0) y* : CHAR END;
END TestImport61.