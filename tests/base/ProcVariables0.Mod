MODULE ProcVariables0;
  TYPE 
    MyFun = PROCEDURE() : INTEGER;
    R = RECORD i : INTEGER END;
    P = POINTER TO R;
  VAR
    a: MyFun;
    b : PROCEDURE(r : R) : P;
    c : PROCEDURE(f : R) : P;
    r : R;
    p : P;

  PROCEDURE getNum8() : INTEGER;
    RETURN 8 
  END getNum8;

  PROCEDURE getNum7() : INTEGER;
    RETURN 7 
  END getNum7;
  
  PROCEDURE getPtr0(x : R) : P;
    VAR y : P;
  BEGIN
    NEW(y);
    y.i := x.i;
    RETURN y
  END getPtr0;
  
  PROCEDURE getPtr1(x : R) : P;
    VAR y : P;
  BEGIN
    NEW(y);
    y.i := x.i+1;
    RETURN y
  END getPtr1;
  
  PROCEDURE Run;
    VAR
    a0: MyFun;
    b0 : PROCEDURE(r : R) : P;
    c0 : PROCEDURE(f : R) : P;
    r0: R;
    p0 : P;
  BEGIN
    a0 := getNum8;
    WriteInt(a0());
    a0 := getNum7;
    WriteInt(a0());

    r0.i := 1;
    b0 := getPtr0;
    p0 := b0(r0);
    WriteInt(p0.i);
    b0 := getPtr1;
    p0 := b0(r0);
    WriteInt(p0.i);
    c0 := b0;
    p0 := c0(r0);
    WriteInt(p0.i)
  END Run;
BEGIN
  Run;
  WriteLn;
  a := getNum8;
  WriteInt(a());
  a := getNum7;
  WriteInt(a());

  r.i := 1;
  b := getPtr0;
  p := b(r);
  WriteInt(p.i);
  b := getPtr1;
  p := b(r);
  WriteInt(p.i);
  c := b;
  p := c(r);
  WriteInt(p.i)
END ProcVariables0.