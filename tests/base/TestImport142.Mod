MODULE TestImport142;
IMPORT I0 := TestImport140, I1 := TestImport141;

TYPE PtrRec1 = POINTER TO I1.Rec1;

VAR
  r0: POINTER TO I0.Rec0;
  r1: PtrRec1;

BEGIN
  NEW(r1);
  r0 := r1;
  IF r0 IS PtrRec1 THEN WriteInt(1) END;
  r1.a := 2;
  r1.b := "3";
  r1.c := 4.0;
  r1.d[1] := 5;
  r1.e := TRUE;
  r1.f := 6;
  WriteInt(r1.a);
  WriteChar(r1.b);
  WriteReal(r1.c);
  WriteInt(r1.d[1]);
  WriteInt(ORD(r1.e));
  WriteInt(r1.f)
END TestImport142.
