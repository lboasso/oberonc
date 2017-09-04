MODULE TestShift;
  VAR x : INTEGER;
   
BEGIN
  x := 8;
  WriteInt(LSL(x, x DIV 4));
  WriteInt(ASR(x, 1));
  WriteInt(ROR(65280, x))
END TestShift.