MODULE TestImport01;
IMPORT TestImport00;
VAR
   k1: INTEGER;
   a1: ARRAY TestImport00.N OF INTEGER;
   p: TestImport00.Ptr;
BEGIN
  p := NIL;
  k1 := TestImport00.k;
  WriteInt(TestImport00.N);
  WriteInt(k1);
  a1 := TestImport00.a;
  WriteInt(a1[2]);
  k1 := TestImport00.P(TestImport00.k);
  WriteInt(k1);
  k1 := TestImport00.b0[1].t.o;
  WriteInt(k1);
  k1 := TestImport00.b1[1].n;
  WriteInt(k1);
END TestImport01.