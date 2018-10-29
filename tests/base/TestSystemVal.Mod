MODULE TestSystemVal;
IMPORT SYSTEM;
  VAR
    a, b, c, i: INTEGER;
    r: REAL;
BEGIN
  b := SYSTEM.VAL(INTEGER, {0, 5});
  c := SYSTEM.VAL(INTEGER, {1..4});
  a := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, b) + SYSTEM.VAL(SET, c));
  IF 2 IN SYSTEM.VAL(SET, a) THEN
    WriteInt(a); (* 63 *)
    WriteChar(CHR(a)); (* ? *)
  END;
  i := 8;
  r := SYSTEM.VAL(REAL, i);
  WriteReal(r);
  i := SYSTEM.VAL(INTEGER, r);
  WriteInt(i)
END TestSystemVal.