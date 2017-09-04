MODULE TestINC1;
  VAR k : INTEGER;
   
  PROCEDURE Effect(VAR x : BYTE) : INTEGER;
  BEGIN 
    WriteInt(x); (* 7 *)
    INC(k); 
    RETURN 0
  END Effect;
  
  PROCEDURE P;
    VAR i : ARRAY 2 OF RECORD b : BYTE END;
        j : ARRAY 20 OF BYTE;
        x : BYTE;
  BEGIN 
    i[0].b := 6;
    x := 10;
    k := 0;
    j[x+5] := 7;
    INC(i[Effect(j[x+5])].b, 2);
    WriteInt(k); (* 1 *)
    WriteInt(i[0].b); (* 8 *)
  END P; 
  
BEGIN
 P
END TestINC1.