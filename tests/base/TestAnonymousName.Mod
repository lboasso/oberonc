MODULE TestAnonymousName;
  TYPE Anonymous0 = RECORD i :CHAR END;
  
  VAR x : RECORD i :INTEGER END;
      y : Anonymous0;
      c : CHAR;
BEGIN
  y.i := "A";
  c := y.i;
  x.i := 0;
  WriteChar(c)
END TestAnonymousName.