MODULE TestTypeGuardExt;
IMPORT ExtTypes;
  VAR
    p0: ExtTypes.pR0;
    p1, p: ExtTypes.pR1;
BEGIN
  NEW(p1);
  p1.y := 25;
  p0 := p1;
  p := p0(ExtTypes.pR1);
  WriteInt(p.y); (* 25 *)

  NEW(p1);
  p1.y := 26;
  p := p1(ExtTypes.pR1);
  WriteInt(p.y) (* 26 *)
END TestTypeGuardExt.
