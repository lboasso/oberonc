MODULE SetTest;
IMPORT SYSTEM;
  CONST
        eight = 8;
        c0 = {6..eight};
        c1 = {0..4, 10, 30..31};
        six = {6};
  VAR  s : SET;
       x,y : INTEGER;
       b : BOOLEAN;

  PROCEDURE PrintSet(x : SET);
  VAR i : INTEGER;
  BEGIN
    FOR i:= 0 TO 31 DO
      IF i IN x THEN WriteInt(i) END
    END;
    WriteLn
  END PrintSet;
  PROCEDURE PrintBool(x : BOOLEAN);
  BEGIN
    IF x THEN WriteInt(1) ELSE WriteInt(0) END;
  END PrintBool;
  PROCEDURE testRelation;
    VAR a : ARRAY 1 OF SET;
        b: SET;
  BEGIN
    a[0] := {4, 5, 3};
    b := {4, 5, 1, 8};
    IF a[0] = b THEN WriteInt(3) END;
    IF a[0] # b THEN WriteInt(4) END;
    WriteLn;
    a[0] := {4, 5, 3};
    b := {1..8};
    IF a[0] = b THEN WriteInt(3) END;
    IF a[0] # b THEN WriteInt(4) END;
    WriteLn;
    a[0] := {1..8};
    b := {3, 8, 1};
    IF a[0] = b THEN WriteInt(3) END;
    IF a[0] # b THEN WriteInt(4) END;
    WriteLn;
    a[0] := {1..3};
    b := {3, 2, 1};
    IF a[0] = b THEN WriteInt(3) END;
    IF a[0] # b THEN WriteInt(4) END;
    WriteLn;
  END testRelation;
  PROCEDURE testSetAndArrayAndField;
    TYPE
      V = RECORD
            s : SET;
          END;
    VAR
      i : INTEGER;
      f : ARRAY 2 OF SET;
      m : ARRAY 2 OF INTEGER;
      s, k : SET;
      b : BOOLEAN;
      d : V;
  BEGIN
    s := {9};
    m[0] := 5;
    m[1] := 15;
    k := {8..m[1]} - s;
    PrintSet(k); (* {8, 10..15} *)
    i := 31;
    k := {8..10, i } - s;
    PrintSet(k);  (* {8, 10, 31} *)
    k := {8..10, m[1] } - s;
    PrintSet(k); (* {8, 10, 15} *)
    k := {8..10, 12..15 } - s;
    PrintSet(k); (* {8, 10, 12..15} *)
    k := {8..10, 12..m[1] } - s;
    PrintSet(k); (* {8, 10, 12..15} *)
    k := {8..10, m[0]..12 } - s;
    PrintSet(k); (* {5..8, 10..12} *)
    k := {8..10, m[0]..m[1] } - s;
    PrintSet(k); (* {5..8, 10..15} *)
    k := {m[0]..10, 12..m[1] } - s;
    PrintSet(k); (* {5..8, 10, 12..15} *)
    k := {8..m[1], 12..m[1] } - s;
    PrintSet(k); (* {8, 10..15} *)
    s := {3..20};
    k := s - {8..m[1], 12..m[1] };
    PrintSet(k); (* {3..7, 16..20} *)
    s := {9};
    k := {m[0]..m[1]} - s;
    PrintSet(k); (* {5..8, 10..15} *)
    k := {m[0]..13} - s;
    PrintSet(k); (* {5..8, 10..13} *)
    k := {8} - s;
    PrintSet(k); (* {8} *)
    k :=  s - {8};
    PrintSet(k); (* {9} *)
    k :=  {1..3} - {8};
    PrintSet(k); (* {1..3} *)
    k :=  s - s;
    PrintSet(k); (* {} *)
    s := {9};
    m[0] := 5;
    m[1] := 15;
    f[0] := {1..3};
    f[1] := {5};
    d.s := {1..10};
    k := {4, 1} - f[0];
    PrintSet(k); (* {4} *)
    k :=  f[0] - {2};
    PrintSet(k); (* {1, 3} *)
    k :=  {1..3} + {8};
    PrintSet(k);  (* {1..3, 8} *)
    k :=  s - f[0];
    PrintSet(k);  (* {9} *)
    k :=  f[0] - f[0];
    PrintSet(k); (* {} *)
    b := m[0] IN {1..3};
    PrintBool(b); (* 0 *)
    b := m[0] IN f[0];
    PrintBool(b); (* 0 *)
    b := m[0] IN d.s;
    PrintBool(b); (* 1 *)
    b := 1 IN {1..3};
    PrintBool(b); (* 1 *)
    b := 1 IN f[0];
    PrintBool(b); (* 1 *)
    b := 1 IN d.s;
    PrintBool(b); (* 1 *)
  END testSetAndArrayAndField;
BEGIN
  x := 5;
  s:= {3..x};
  PrintSet(s);
  s:= {3..x, 20};
  PrintSet(s);
  y := 20;
  s:= {3..x, y};
  PrintSet(s);
  y := 20;
  s:= {y, 3..x};
  PrintSet(s);
  b := (4 IN s) OR (x > 10);
  PrintBool(b);
  WriteLn;
  s := s + c0; (* {3..8, 20} *)
  PrintSet(s);
  s := {1..20, 22} - c1; (* {5..9, 11..20, 22} *)
  PrintSet(s);
  s := s * {6..8, 20}; (* {6..8, 20} *)
  PrintSet(s);
  s := s / {1..20, 23..31}; (* {1..5, 9..19, 23..31} *)
  PrintSet(s);
  s := {1, 2, 3} / {3, 4}; (* {1 2 4} *)
  PrintSet(s);
  x := 30;
  s:= {x..3};  (* this is wrong as x > 3, maybe we should put a check at runtime *)
  PrintSet(s);
  PrintBool(31 IN {0..2});
  x := 31;
  PrintBool(x IN {0..2});
  x := -100;
  PrintBool(x IN {0..2});
  x := 33;
  PrintBool(x IN {0..2}); (* this is wrong as x >= 32, maybe we should put a check at runtime *)
  WriteLn;
  PrintSet(-{3..6, eight..31});
  s := {3..6, eight..31};
  PrintSet(-s);
  b := 1 IN {1..3}; (* this could be computed at compile-time*);
  PrintBool(b);
  testSetAndArrayAndField;
  testRelation;
  PrintSet({5, 6, 7} * six);
  PrintSet({5..7} / six);
  WriteInt(SYSTEM.VAL(INTEGER, {9..1}))
END SetTest.
