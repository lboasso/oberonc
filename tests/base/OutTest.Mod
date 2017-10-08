MODULE OutTest;
  IMPORT Out;
  VAR str: ARRAY 3 OF CHAR;
BEGIN
  Out.Int(10, 0); Out.Ln;
  Out.String("Hello");
  Out.Ln;

  str[0] := "A";
  str[1] := "B";
  str[2] := "C";
  Out.String(str);
  Out.Ln;

  str[0] := "A";
  str[1] := "B";
  str[2] := 0X;
  Out.String(str);
  Out.Ln;

  str[0] := "A";
  str[1] := 0X;
  str[2] := "C";
  Out.String(str);
  Out.Ln;

  str[0] := 0X;
  str[1] := "B";
  str[2] := "C";
  Out.String(str);
END OutTest.
