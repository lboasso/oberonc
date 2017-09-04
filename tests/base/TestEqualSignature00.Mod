MODULE TestEqualSignature00;
  TYPE
    A = RECORD i : INTEGER END;
    B = RECORD(A) k : CHAR END;
    P0 = PROCEDURE(x : ARRAY OF B);
    P1 = PROCEDURE(x : B);
    PTRB = POINTER TO B;
    P2 = PROCEDURE(x : PTRB);
    ARR = ARRAY 10 OF B;
    P3 = PROCEDURE(x : BYTE; y : CHAR; z : ARRAY OF B) : CHAR;
    P4 = PROCEDURE(z : ARR; x : PROCEDURE(z : ARR) : CHAR) : CHAR;
  VAR
    p0: P0;
    p1: P1;
    p2: P2;
    p3: P3;
    p4: P4;
    x : ARRAY 1 OF B;
    pb : PTRB;
    y : ARR;

  PROCEDURE H0(x : ARRAY OF B);
  BEGIN
    WriteChar(x[0].k)
  END H0;

  PROCEDURE H1(x : B);
  BEGIN
   WriteChar(x.k)
  END H1;

  PROCEDURE H2(x : PTRB);
  BEGIN
   WriteChar(x.k)
  END H2;

  PROCEDURE H3(x : BYTE; y : CHAR; z : ARRAY OF B) : CHAR;
    RETURN CHR(x+ORD(y)+z[0].i)
  END H3;

  PROCEDURE H4(z : ARR; x : PROCEDURE(z : ARR) : CHAR) : CHAR;
    RETURN x(z)
  END H4;

  PROCEDURE H5() : CHAR;
    RETURN "F"
  END H5;
  PROCEDURE L(u : ARR) : CHAR;
    RETURN u[0].k
  END L;
BEGIN
  p0 := H0;
  x[0].k := "A";
  p0(x); (* A *)
  p1 := H1;
  x[0].k := "B";
  p1(x[0]); (* B *)
  p2 := H2;
  NEW(pb);
  pb.k := "C";
  p2(pb); (* C *)
  p3 := H3;
  x[0].i := 2;
  WriteChar(p3(1, "A", x)); (* D *)
  p4 := H4;
  y[0].k := "E";
  WriteChar(p4(y, L)); (* E *)
  WriteChar(H5())
END TestEqualSignature00.