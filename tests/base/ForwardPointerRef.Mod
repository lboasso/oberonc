MODULE ForwardPointerRef;
  TYPE
    P0 = POINTER TO R0;
    R0 = RECORD i: INTEGER END;

    R1 = RECORD
           j: INTEGER;
           dsc: POINTER TO R1;
           next: POINTER TO R2
         END;

    P2 = POINTER TO R2;
    R2 = RECORD c: CHAR END;

   VAR
     p0: P0;
     pa: POINTER TO R1;
     pb: P2;

BEGIN
  NEW(p0);
  p0.i := 3;
  WriteInt(p0.i); (* 3 *)

  NEW(pa);
  pa.j := 4;
  WriteInt(pa.j); (* 4 *)
  pa.dsc := pa;
  WriteInt(pa.dsc.j); (* 4 *)

  NEW(pb);
  pb.c := "C";
  pa.next := pb;
  WriteChar(pa.next.c); (* C *)
  WriteLn;
END ForwardPointerRef.