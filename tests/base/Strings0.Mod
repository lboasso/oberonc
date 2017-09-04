MODULE Strings0;
  CONST baobab =  "BAOBAB";
        C =  "C";
  TYPE Arr = ARRAY 10 OF CHAR;
  VAR a : CHAR;
      b : ARRAY 10 OF CHAR;
      c : ARRAY 10 OF CHAR;
  PROCEDURE P(VAR x : ARRAY OF CHAR);
  BEGIN 
    x := baobab;
    c := "BAOBAB"
  END P;
  
  PROCEDURE Init(VAR x : ARRAY OF CHAR);
    VAR i : INTEGER;
  BEGIN
    FOR i := 0 TO LEN(x)-1 DO
      x[i] := "-";
    END;
  END Init;
  
  PROCEDURE Print(x : ARRAY OF CHAR);
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
  END Print;
  
  PROCEDURE Print2(x : Arr);
    VAR i : INTEGER;
  BEGIN
    FOR i := 0 TO LEN(x)-1 DO
      IF x[i] = 0X THEN
        WriteChar("$")
      ELSE 
        WriteChar(x[i])
      END;    END;
    WriteLn
  END Print2;
BEGIN
  Init(b); 
  b := "BAOBAB";
  Print(b);
  a := "C";
  WriteChar(a);
  a := C;
  WriteChar(a);
  WriteLn;
  P(b);
  Print2(b);
END Strings0.