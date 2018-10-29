MODULE CaseNum1;
  TYPE ARR =  ARRAY 3 OF RECORD c: CHAR END;
  VAR b: ARR;

  PROCEDURE P(i: INTEGER);
     VAR a: INTEGER;
  BEGIN
    CASE i OF
      8..10, 14:
        a := 1;
      |2..4, 15..20, 25:
        CASE i OF
          3, 15..19:
            a := 2;
          |25:
            a := 3;
        END;
      |5..6:
        a := 4;
    END;
    WriteInt(a)
  END P;

  PROCEDURE NoLocals(i: INTEGER);
  BEGIN
    CASE i OF
       5: WriteInt(i)
    END
  END NoLocals;

  PROCEDURE P2(i: ARR);
  BEGIN
    CASE i[2].c OF
      "P": WriteInt(ORD(i[2].c))
    END
  END P2;

  PROCEDURE P3(i: ARR);
  BEGIN
    CASE ORD(i[2].c) OF
      80: WriteChar(i[2].c)
    END
  END P3;

BEGIN
  P(9); (* 1 *)
  P(18); (* 2 *)
  P(25); (* 3 *)
  P(6); (* 4 *)
  NoLocals(5); (* 5 *)
  b[2].c := "P";
  P2(b); (* 80 *)
  P3(b) (* "P" *)
END CaseNum1.
