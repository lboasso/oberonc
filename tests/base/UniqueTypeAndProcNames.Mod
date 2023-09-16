MODULE UniqueTypeAndProcNames;
  TYPE T = RECORD a: INTEGER END;

  PROCEDURE P1(i: INTEGER);
    TYPE T = RECORD b: CHAR END;
    PROCEDURE P2(j: INTEGER);
      TYPE T2 = RECORD b: ARRAY 2, 2 OF CHAR END;
      PROCEDURE P3(j: INTEGER);
         VAR x: T2;
      BEGIN
        x.b[1][1] := "F";
        WriteChar(x.b[1][1])
      END P3;
    BEGIN
      WriteChar("E");
      P3(3)
    END P2;
  BEGIN
    WriteChar("D");
    P2(2)
  END P1;

  PROCEDURE P0(i: INTEGER);
    TYPE T = RECORD b: REAL END;
    PROCEDURE P2(j: INTEGER);
      TYPE T2 = RECORD b: ARRAY 3, 3 OF CHAR END;
      PROCEDURE P3(j: INTEGER);
         VAR x: T2;
      BEGIN
        x.b[2][2] := "C";
        WriteChar(x.b[2][2])
      END P3;
    BEGIN
      WriteChar("B");
      P3(3)
    END P2;
  BEGIN
    WriteChar("A");
    P2(2)
  END P0;

BEGIN
  P0(1); WriteLn; P1(1)
END UniqueTypeAndProcNames.