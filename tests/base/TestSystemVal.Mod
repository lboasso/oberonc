MODULE TestSystemVal;

IMPORT SYSTEM;

  TYPE

    pR0 = POINTER TO R0;
    pR1 = POINTER TO R1;
    R0 = RECORD x: INTEGER END;
    R1 = RECORD(R0) y: INTEGER END;

  VAR

    a, b, c, i: INTEGER;
    r: REAL;
    p0: pR0;
    p1, p: pR1;
    byte, byte1: BYTE;

BEGIN

  (* converting INTEGER to BYTE and vice versa *)
  c := 257;
  byte := SYSTEM.VAL(BYTE, c);
  WriteInt(byte); (* 1 *)
  byte := 8;
  c := SYSTEM.VAL(INTEGER, byte);
  WriteInt(c); (* 8 *)

  c := 257;
  i := SYSTEM.VAL(INTEGER, c);
  WriteInt(i); (* 257 *)
  byte := 8;
  byte1 := SYSTEM.VAL(BYTE, byte);
  WriteInt(byte1); (* 8 *)
  WriteLn;

  (* converting SET to INTEGER and vice versa *)

  b := SYSTEM.VAL(INTEGER, {0, 5});
  c := SYSTEM.VAL(INTEGER, {1..4});
  a := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, b) + SYSTEM.VAL(SET, c));
  IF 2 IN SYSTEM.VAL(SET, a) THEN
    WriteInt(a); (* 63 *)
    WriteChar(CHR(a)); (* ? *)
  END;

  (* converting REAL to INTEGER and back *)

  i := 8;
  r := SYSTEM.VAL(REAL, i);
  WriteReal(r);
  i := SYSTEM.VAL(INTEGER, r);
  WriteInt(i); WriteLn;

  (* converting extension types *)

  NEW(p1);
  p1.y := 25;
  p0 := p1;
  p := SYSTEM.VAL(pR1, p0);
  WriteInt(p.y); (* 25 *)

  NEW(p1);
  p1.y := 26;
  p := SYSTEM.VAL(pR1, p1);
  WriteInt(p.y) (* 26 *)

END TestSystemVal.
