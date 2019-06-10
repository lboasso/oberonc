MODULE TestTypeTest;
  TYPE
    G1 = POINTER TO G1Desc;
    G1Desc = RECORD next: G1; next2: ARRAY 1 OF G1 END;
    G2 = POINTER TO G2Desc;
    G2Desc = RECORD(G1Desc) x: CHAR END;
  VAR
    g2: G2;
    g2Desc: G2Desc;

  PROCEDURE L(g: G1): G1;
    RETURN g
  END L;

  PROCEDURE P1(g: G1);
    VAR b: BOOLEAN; i: INTEGER;
  BEGIN
    i := 0;
    b := g IS G1;
    WriteInt(ORD(b));
    b := g IS G2;
    WriteInt(ORD(b));
    b := g.next IS G1;
    WriteInt(ORD(b));
    b := g.next IS G2;
    WriteInt(ORD(b));
    b := g.next.next.next IS G1;
    WriteInt(ORD(b));
    b := g.next.next.next IS G2;
    WriteInt(ORD(b));
    b := g.next2[i*3].next.next.next IS G1;
    WriteInt(ORD(b));
    b := g.next2[i*3].next.next.next IS G2;
    WriteInt(ORD(b));
    b := g.next.next.next2[i*3].next IS G1;
    WriteInt(ORD(b));
    b := g.next.next.next2[i*3].next IS G2;
    WriteInt(ORD(b));
    b := g.next.next.next.next2[i*3] IS G1;
    WriteInt(ORD(b));
    b := g.next.next.next.next2[i*3] IS G2;
    WriteInt(ORD(b));
    b := L(g) IS G1;
    WriteInt(ORD(b));
    b := L(g) IS G2;
    WriteInt(ORD(b))
  END P1;

  PROCEDURE P2(VAR g: G1Desc);
    VAR b: BOOLEAN;
  BEGIN
    b := g IS G1Desc;
    WriteInt(ORD(b));
    b := g IS G2Desc;
    WriteInt(ORD(b))
  END P2;

BEGIN
  NEW(g2);
  g2.next := g2;
  g2.next.next2[0] := g2;
  P1(g2);
  g2Desc.next := g2;
  g2Desc.next.next2[0] := g2;
  P2(g2Desc)
END TestTypeTest.
