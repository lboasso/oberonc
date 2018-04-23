MODULE TestImport91;
  IMPORT imp := TestImport90;
  VAR i: INTEGER;
      str: ARRAY 10 OF CHAR;
BEGIN
  str := imp.h;
  i := 0;
  WHILE str[i] # 0X DO
    WriteChar(str[i]);
    INC(i)
  END ;
  WriteChar(imp.x);
  WriteLn
END TestImport91.