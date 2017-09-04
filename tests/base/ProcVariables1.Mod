MODULE ProcVariables1;
  TYPE 
    R = RECORD i : INTEGER END;
    MyFun = PROCEDURE(r : R) : INTEGER;
  VAR
    a : ARRAY 2 OF MyFun;
    i : INTEGER;
    r : R;

  PROCEDURE F1(x : R) : INTEGER;
    RETURN x.i+1
  END F1;
  
  PROCEDURE F2(x : R) : INTEGER;
    RETURN x.i+2
  END F2;
  
  PROCEDURE Run;
    VAR
      a0 : ARRAY 2 OF MyFun;
  BEGIN
    r.i := 1;
    a0[0] := F1;
    a0[1] := F2;
    FOR i := 0 TO 1 DO
      WriteInt(a0[i](r))
    END
  END Run;
BEGIN
  Run;
  WriteLn;
  r.i := 1;
  a[0] := F1;
  a[1] := F2;
  FOR i := 0 TO 1 DO
    WriteInt(a[i](r))
  END
END ProcVariables1.