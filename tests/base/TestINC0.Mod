MODULE TestINC0;
  VAR xg : INTEGER;
      yg : BYTE;
      ig : ARRAY 2 OF INTEGER; 
      jg : RECORD x : INTEGER END;
   
  PROCEDURE P0(VAR i : INTEGER; VAR j : BYTE);
  BEGIN 
    INC(i);
    WriteInt(i); (* 2 *)
    INC(i, 130);
    WriteInt(i); (* 132 *)
    INC(i, -128);
    WriteInt(i); (* 4 *)
    DEC(j);
    WriteInt(j); (* 255 *)
    DEC(j, 130);
    WriteInt(j); (* 125 *)
    INC(j, 4);
    WriteInt(j); (* 129 *)
    DEC(j, -128);
    WriteInt(j) (* 1 *)
  END P0;
  
  
  PROCEDURE P2;
    VAR i : INTEGER; 
        j : BYTE;
  BEGIN 
    i := 1; j := 0;
    INC(i);
    WriteInt(i); (* 2 *)
    INC(i, 130);
    WriteInt(i); (* 132 *)
    INC(i, -128);
    WriteInt(i); (* 4 *)
    DEC(j);
    WriteInt(j); (* 255 *)
    DEC(j, 130);
    WriteInt(j); (* 125 *)
    INC(j, 4);
    WriteInt(j); (* 129 *)
    DEC(j, -128);
    WriteInt(j) (* 1 *)
  END P2; 
  
  PROCEDURE P3(VAR a0 : INTEGER; VAR a1 : ARRAY OF INTEGER);
    VAR i : ARRAY 2 OF INTEGER;
        j : RECORD x : INTEGER END;
        x : INTEGER;
        b : ARRAY 2 OF BYTE;
  BEGIN 
    x := 0;
    i[0] := 2; i[1] := 3;
    INC(i[0]);
    WriteInt(i[0]); (* 3 *)
    INC(i[x+1]);
    WriteInt(i[x+1]); (* 4 *)
    
    j.x := 3;
    INC(j.x);
    WriteInt(j.x); (* 4 *)
        
    INC(a0);
    WriteInt(a0); (* 2 *)
    
    x := 0;
    INC(a1[x+1]);
    WriteInt(a1[x+1]); (* 4 *)
    
    INC(ig[0]);
    WriteInt(ig[0]); (* 3 *)
    INC(ig[x+1]);
    WriteInt(ig[x+1]); (* 5 *)
    xg := 0;
    INC(ig[xg+1]);
    WriteInt(ig[xg+1]); (* 6 *)
    jg.x := 6;
    INC(jg.x);
    WriteInt(jg.x); (* 7 *)
    
    INC(a1[xg+1]);
    WriteInt(a1[xg+1]); (* 7 *)
    
    b[1] := 10;
    INC(b[x+1]);
    WriteInt(b[x+1]); (* 11 *)
    
    i[0] := 2; i[1] := 3;
    INC(i[0], 7);
    WriteInt(i[0]); (* 9 *)
    INC(i[x+1], 7);
    WriteInt(i[x+1]); (* 10 *)
    
    j.x := 3;
    INC(j.x, 2);
    WriteInt(j.x); (* 5 *)
    x := 98;
    a0 := 1;
    INC(a0, x);
    WriteInt(a0); (* 99 *)
    x := 0;
    a1[x+1] := 80;
    xg := 20;
    INC(a1[x+1], xg);
    WriteInt(a1[x+1]); (* 100 *)
    x := 3;
    DEC(x, -1);
    WriteInt(x); (* 4 *)
  END P3; 

  PROCEDURE P4(VAR a0 : INTEGER; VAR a1 : ARRAY OF INTEGER);
    VAR i : ARRAY 2 OF INTEGER;
        j : RECORD x : INTEGER END;
        x, r : INTEGER;
        b : ARRAY 2 OF BYTE;
  BEGIN
    x := 0;
    r := 0;
    i[0] := 2; i[1] := 3;

    INC(r, i[0]);
    WriteInt(r); (* 2 *)
    INC(r, i[x+1]);
    WriteInt(r); (* 5 *)

    j.x := 3;

    INC(r, j.x);
    WriteInt(r); (* 8 *)
    INC(r, a0);
    WriteInt(r); (* 9 *)

    x := 0;

    INC(r, a1[x+1]);
    WriteInt(r); (* 12 *)
    INC(r, ig[0]);
    WriteInt(r); (* 14 *)
    INC(r, ig[x+1]);
    WriteInt(r); (* 17 *)

    xg := 0;

    INC(r, ig[xg+1]);
    WriteInt(r); (* 20 *)

    jg.x := 6;

    INC(r, jg.x);
    WriteInt(r); (* 26 *)
    INC(r, a1[xg+1]);
    WriteInt(r); (* 29 *)

    b[1] := 10;

    INC(r, b[x+1]);
    WriteInt(r); (* 39 *)
    INC(r, 1+b[x+1]);
    WriteInt(r); (* 50 *)
    INC(r, b[x+1]+1);
    WriteInt(r); (* 61 *)
  END P4;
BEGIN
 xg := 1;
 yg := 0;
 P0(xg, yg);
 WriteLn;
 P2;
 WriteLn;
 xg := 1;
 ig[0] := 2; ig[1] := 3;
 P3(xg, ig);
 WriteLn;
 xg := 1;
 ig[0] := 2; ig[1] := 3;
 P4(xg, ig)
END TestINC0.