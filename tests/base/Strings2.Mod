MODULE Strings2;

CONST
  a = "a";
  abcd = "abcd";

VAR
  s4: ARRAY 4 OF CHAR;
  s5: ARRAY 5 OF CHAR;
  f: ARRAY 20 OF CHAR;

  PROCEDURE P(x: ARRAY OF CHAR);
    VAR i : INTEGER;
  BEGIN
    FOR i := 0 TO LEN(x)-1 DO
      IF x[i] = 0X THEN
        WriteChar("$")
      ELSE
        WriteChar(x[i])
      END;
    END;
    WriteLn
  END P;

  PROCEDURE K;
   VAR f: ARRAY 20 OF CHAR;
  BEGIN
    f := "Hello";
    IF f = "" THEN WriteInt(1) END;
    f := "";
    IF f = "" THEN WriteInt(2) END;
    f[0] := 0X;
    IF f = "" THEN WriteInt(3) END
  END K;
BEGIN
  s4 := a; P(s4);
  s4 := "a"; P(s4);
  s4 := "ab"; P(s4);
  P(a);
  P("a");
  P("ab");
  (* s4 := abcd;  String too long *)
  (*s4 := "abcd"; String too long *)
  s5 := abcd; P(s5);
  s5 := "abcd"; P(s5);
  s5 := ""; P(s5);
  f := "Hello";
  IF f = "" THEN WriteInt(1) END;
  f := "";
  IF f = "" THEN WriteInt(2) END;
  f[0] := 0X;
  IF f = "" THEN WriteInt(3) END;
  K
END Strings2.