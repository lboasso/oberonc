MODULE TestCmdLineArgs;
  VAR x: INTEGER;
      y: ARRAY 10 OF CHAR;
   
  PROCEDURE Print(x: ARRAY OF CHAR);
    VAR i,j : INTEGER;
  BEGIN
    i := 0;
    j := LEN(x)-1;
    WHILE (i < j) & (x[i] # 0X) DO
      WriteChar(x[i]);
      INC(i)
    END;
    WriteLn
  END Print;
  PROCEDURE P(x: ARRAY OF CHAR);
  BEGIN
    ARGS(0, x)
  END P;
  PROCEDURE Main();
    VAR
      buf0: ARRAY 0 OF CHAR;
      buf1: ARRAY 1 OF CHAR;
      buf2: ARRAY 2 OF CHAR;
      buf: ARRAY 10 OF CHAR;
      i: INTEGER;
      r: RECORD a: INTEGER END;
      g: ARRAY 2 OF RECORD buf: ARRAY 2 OF CHAR END;
  BEGIN 
    ARGS(1, buf0);
    Print(buf0);
    ARGS(1, buf1);
    Print(buf1);
    ARGS(10, buf);
    Print(buf);
    ARGS(1, buf2);
    Print(buf2);

    r.a := 1;
    ARGS(r.a, g[1+i].buf);
    Print(buf2);

    P(buf);
    Print(buf);
    FOR i := 0 TO ARGNUM()-1 DO ARGS(i, buf); Print(buf) END
  END Main;
   
BEGIN
  WriteInt(ARGNUM());
  WriteLn;
  FOR x := 0 TO ARGNUM()-1 DO ARGS(x, y); Print(y) END
END TestCmdLineArgs.