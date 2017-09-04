MODULE RecordAssignment;
  TYPE A = RECORD 
             x : INTEGER;
             y : ARRAY 1, 2 OF INTEGER;
           END;        
       D = RECORD d : REAL END;
       C = RECORD 
             c : INTEGER;
             d : ARRAY 1, 1 OF D;
           END;  
       B = RECORD(C)
             a : A;
             r : REAL;
             cArr : ARRAY 1 OF C;
           END;
  VAR 
    a1 : ARRAY 1 OF A;
    a2 : RECORD a : A END;
    c1, c2 : C;
    b1, b2 : B;
    
 PROCEDURE initA(VAR x : A);
  BEGIN
    x.x := 1;
    x.y[0][0] := 2;
    x.y[0][1] := 3;
  END initA;
  
  PROCEDURE initD(VAR x : D);
  BEGIN x.d := 20.0
  END initD;
  
  PROCEDURE initC(VAR x : C);
  BEGIN  
    x.c := 79;
    x.d[0][0].d := 99.0;
  END initC;
BEGIN 
  initA(a1[0]);
  a2.a := a1[0];
  a2.a.x := 11; 
  a2.a.y[0][1] := 33;
  WriteInt(a1[0].x);
  WriteInt(a2.a.x);
  WriteInt(a1[0].y[0][1]);
  WriteInt(a2.a.y[0][1]);
  WriteLn;
  
  initC(c1);
  c2 := c1;
  c2.c := 80;
  c2.d[0][0].d := 100.0;
  WriteInt(c1.c);
  WriteInt(c2.c);
  WriteReal(c1.d[0][0].d);
  WriteReal(c2.d[0][0].d);
  WriteLn;
  
  b1.r := 4.0;
  initA(b1.a);  
  initC(b1.cArr[0]);
  b1.c := 71;
  b1.d[0][0].d := 72.0;
  b2 := b1;
  b2.r := 44.0;
  b2.a.x := 11; 
  b2.a.y[0][1] := 33;
  b2.cArr[0].c := 80;
  b2.cArr[0].d[0][0].d := 100.0;
  b2.c := 75;
  b2.d[0][0].d := 76.0;
  WriteReal(b1.r);
  WriteReal(b2.r);
  WriteInt(b1.a.x );
  WriteInt(b2.a.x );
  WriteInt(b1.a.y[0][1]);
  WriteInt(b2.a.y[0][1]);
  WriteInt(b1.cArr[0].c);
  WriteInt(b2.cArr[0].c);
  WriteReal(b1.cArr[0].d[0][0].d);
  WriteReal(b2.cArr[0].d[0][0].d);
  WriteInt(b1.c);
  WriteInt(b2.c);
  WriteReal(b1.d[0][0].d);
  WriteReal(b2.d[0][0].d);
  b2 := b2;
END RecordAssignment.