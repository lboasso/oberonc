MODULE TestImport00;
CONST N* = 100;
TYPE
  Ptr* = POINTER TO Rec;
  Rec* = RECORD n*: INTEGER; p: Ptr END ;
  Rec2 = RECORD o*: INTEGER; p: Ptr END ;
VAR
   k*: INTEGER;
   a*: ARRAY N OF INTEGER;
   b0*: ARRAY N OF RECORD t* : Rec2 END;
   b1*: ARRAY N OF Rec;
  PROCEDURE P*(x: INTEGER): INTEGER; RETURN 3 END P;
BEGIN
  k := 1;
  a[2] := 2;
  b0[1].t.o := 10;
  b1[1].n := 20
END TestImport00.