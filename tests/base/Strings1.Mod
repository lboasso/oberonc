MODULE Strings1;
  CONST y = "A";
  VAR a: ARRAY 10 OF CHAR;
      x : CHAR;
      s0 : ARRAY 5 OF ARRAY 5 OF CHAR;
      s1 : ARRAY 5 OF CHAR;
      i : INTEGER;

  PROCEDURE PrintMid(x : ARRAY OF CHAR);
  BEGIN
    WriteChar(x[LEN(x) DIV 2])
  END PrintMid;
  
  PROCEDURE Cmp(x, y : ARRAY OF CHAR);
  BEGIN
    IF x = y  THEN WriteInt(-1) END;
    IF y = x  THEN WriteInt(-2) END;
    IF x # y  THEN WriteInt(-3) END;
    IF y # x  THEN WriteInt(-4) END;
    IF x > y  THEN WriteInt(-5) END;
    IF y > x  THEN WriteInt(-6) END;
    IF x < y  THEN WriteInt(-7) END;
    IF y < x  THEN WriteInt(-8) END;
    IF x >= y THEN WriteInt(-9) END;
    IF y >= x THEN WriteInt(-10) END;
    IF x <= y THEN WriteInt(-11) END;
    IF y <= x THEN WriteInt(-12) END;
  END Cmp;


  PROCEDURE Comparisons;
    VAR a, b : ARRAY 15 OF CHAR;
        c : ARRAY 0 OF CHAR;

    PROCEDURE replace0x(VAR str: ARRAY OF CHAR);
      VAR i: INTEGER;
          found: BOOLEAN;
    BEGIN
      found := FALSE;
      FOR i := 0 TO LEN(str)-1 DO
        IF (str[i] = 0X) OR found THEN
          str[i] := "X";
          found := TRUE
        END;
      END;
    END replace0x;
  BEGIN
    a := "Hello";
    b := "World";
    Cmp(a, b);
    WriteLn;

    a := "Hello";
    b := "Hello";
    Cmp(a, b);
    WriteLn;

    a := "HelloWorld";
    b := "Hello";
    Cmp(a, b);
    WriteLn;

    a := "Hello";
    b := "HelloWorld";
    Cmp(a, b);
    WriteLn;

    a := "Hello";
    b := "";
    Cmp(a, b);
    WriteLn;

    a := "";
    b := "Hello";
    Cmp(a, b);
    WriteLn;

    a := "Hello";
    Cmp(a, c);
    WriteLn;

    a := "Hello";
    Cmp(c, a);
    WriteLn;

    a := "Hello";
    b := "World";
    replace0x(a);
    replace0x(b);
    Cmp(a, b);
    WriteLn;

    a := "Hello";
    b := "Hello";
    replace0x(a);
    replace0x(b);
    Cmp(a, b);
    WriteLn;

    a := "HelloWorld";
    b := "Hello";
    replace0x(a);
    Cmp(a, b);
    WriteLn;

    a := "Hello";
    b := "HelloWorld";
    replace0x(a);
    replace0x(b);
    Cmp(a, b);
    WriteLn;

    a := "Hello";
    b := "";
    replace0x(a);
    Cmp(a, b);
    WriteLn;

    a := "";
    b := "Hello";
    replace0x(a);
    replace0x(b);
    Cmp(a, b);
    WriteLn;

    a := "Hello";
    replace0x(a);
    Cmp(a, c);
    WriteLn;

    a := "Hello";
    replace0x(a);
    Cmp(c, a);
    WriteLn;


  END Comparisons;

BEGIN
  PrintMid("Hello");
  WriteLn;
  IF a = "Hello"         THEN WriteInt(0) END;
  IF "Hello" = "Hello"   THEN WriteInt(1) END;
  IF "Hello" = a         THEN WriteInt(2) END;
  IF a # "Hello"         THEN WriteInt(3) END;
  IF "Hello" # "Hello"   THEN WriteInt(4) END;
  IF "Hello" # a         THEN WriteInt(5) END;
  IF a > "Hello"         THEN WriteInt(6) END;
  IF "Hello" > "Hello"   THEN WriteInt(7) END;
  IF "Hello" > a         THEN WriteInt(8) END;
  IF a < "Hello"         THEN WriteInt(9) END;
  IF "Hello" < "Hello"   THEN WriteInt(10) END;
  IF "Hello" < a         THEN WriteInt(11) END;
  IF a >= "Hello"        THEN WriteInt(12) END;
  IF "Hello" >= "Hello"  THEN WriteInt(13) END;
  IF "Hello" >= a        THEN WriteInt(14) END;
  IF a <= "Hello"        THEN WriteInt(15) END;
  IF "Hello" <= "Hello"  THEN WriteInt(16) END;
  IF "Hello" <= a        THEN WriteInt(17) END;
  IF "HELL" = "HELLO"    THEN WriteInt(18) END;
  WriteLn;
  Comparisons;
  WriteLn;
  x := "A";
  IF x = "A" THEN WriteInt(1) END;
  IF "A" = x THEN WriteInt(2) END;
  IF "A" = y THEN WriteInt(3) END;
  s0[0] := "ZAB";
  i := -1;
  IF "ABC" < s0[1+i] THEN  WriteInt(4) END;
  IF s0[1+i] > "ABC" THEN  WriteInt(5) END;
  IF "ABC" < "ZBC" THEN WriteInt(6) END;
  IF "A" < "Z" THEN WriteInt(7) END;
  s1[0] := "A";
  IF s1[1+i] = "A" THEN WriteInt(8) END;
  IF "A" = s1[1+i] THEN WriteInt(9) END;
  IF "A" = y THEN WriteInt(10) END;
END Strings1.