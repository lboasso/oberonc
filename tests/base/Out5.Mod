MODULE Out5;
  TYPE A = RECORD x : INTEGER END;
  VAR i: INTEGER;
      v : ARRAY 20 OF INTEGER;
      a : A;
BEGIN 
  i := 1;
  v[i] := 10;
  WriteInt(v[i]);
  i := v[i] + 1; 
  WriteInt(i);
  v[i] := i + 1; 
  WriteInt(v[i]);
  i := v[i] + v[i] - 4; 
  WriteInt(i);
  a.x := 21;
  WriteInt(a.x);
  i := a.x + 1; 
  WriteInt(i);
  a.x := i + 1; 
  WriteInt(a.x);
  i := a.x + a.x - 22; 
  WriteInt(i);
END Out5.