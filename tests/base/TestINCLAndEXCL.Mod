MODULE TestINCLAndEXCL;
  CONST K = {1, 2, 3};
  VAR y : SET;
      j,f : INTEGER;
      b : ARRAY 2 OF SET;
   
  PROCEDURE PrintSet(x : SET);
  VAR i : INTEGER;
  BEGIN
    FOR i:= 0 TO 31 DO
      IF i IN x THEN WriteInt(i) END
    END;
    WriteLn
  END PrintSet;

  PROCEDURE P0(VAR a0 : SET; VAR a1 : ARRAY OF SET);
    VAR i : ARRAY 2 OF SET;
        z : RECORD x : SET END;
        x : BYTE;
  BEGIN 
    x := 0;
    i[0] := K; 
    i[1] := K + {8}; 
    INCL(i[0], 8);
    PrintSet(i[0]); (* {1 2 3 8} *)
    EXCL(i[x+1], 1);
    PrintSet(i[x+1]); (* {2 3 8} *)
    
    z.x := K;
    EXCL(z.x, 2);
    PrintSet(z.x); (* {1 3} *)
        
    EXCL(a0, 2);
    PrintSet(a0); (* {1 3} *)
    
    EXCL(a1[x+1], 3);
    PrintSet(a1[x+1]); (* {1 2} *)
    
    j := 0;
    INCL(a1[j+1], 3);
    PrintSet(a1[j+1]); (* {1 2 3} *)
    (* INCL(a0, x+1); INCL/EXCL's second argument must be a constant or simple variable *)
  END P0; 
  
  PROCEDURE Effect(VAR x : BYTE) : INTEGER;
  BEGIN 
    WriteInt(x); (* 7 *)
    INC(f); 
    RETURN 0
  END Effect;
  
  PROCEDURE P1;
    VAR i : ARRAY 2 OF RECORD b : SET END;
        j : ARRAY 20 OF BYTE;
        x : BYTE;
  BEGIN 
    i[0].b := K;
    x := 10;
    f := 0;
    j[x+5] := 7;
    EXCL(i[Effect(j[x+5])].b, 2);
    WriteInt(f); (* 1 *)
    PrintSet(i[0].b); (* {1 3} *)
  END P1; 

BEGIN
  y := K;
  EXCL(y, 2); (* {1 3} *)
  PrintSet(y);
  j := 2;
  y := K;
  EXCL(y, j);
  PrintSet(y); (* {1 3} *)
  b[j - 1] := K;
  EXCL(b[j - 1], j); (* {1 3} *)
  PrintSet(b[j - 1]);
  y := K;
  b[1] := K;
  P0(y, b);
  P1
END TestINCLAndEXCL.