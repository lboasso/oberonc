MODULE TestImport10;
  CONST
    Ten* = 10; Dollar* = "$";
  TYPE
    R* = RECORD u*: INTEGER; v*: SET END ;
    S* = RECORD w*: ARRAY 4 OF R END ;
    P* = POINTER TO R;
    A* = ARRAY 8 OF INTEGER;
    B* = ARRAY 4, 5 OF REAL;
    C* = ARRAY 10 OF S;
    D* = ARRAY 2 OF CHAR;
  VAR x*: INTEGER;
  
  PROCEDURE Q0*;
  BEGIN INC(x, 10) END Q0;
  
  PROCEDURE Q1*(x, y: INTEGER): INTEGER;
  BEGIN RETURN x+y END Q1;
BEGIN x := 5
END TestImport10.