MODULE CaseNum1;
  VAR i, a : INTEGER;
  
  PROCEDURE P(i : INTEGER);
     VAR a : INTEGER;
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
BEGIN
  P(9); (* 1 *)
  P(18); (* 2 *)
  P(25); (* 3 *)
  P(6); (* 4 *)
  NoLocals(5); (* 5 *)
END CaseNum1.