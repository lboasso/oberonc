MODULE UTF8String;
  VAR x : ARRAY 11 OF CHAR;
      i: INTEGER;

BEGIN
  x  := "Hello, 世 界";
  i := 0;
  WHILE (i < LEN(x)) & (x[i] # 0X) DO
    WriteChar(x[i]); INC(i)
  END
END UTF8String.