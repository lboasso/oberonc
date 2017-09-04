MODULE TestImport11;
IMPORT I := TestImport10;
  VAR
    r : I.R;
    s : I.S;
    p : I.P;
    a : I.A;
    b : I.B;
    c : I.C;
    d : I.D;
BEGIN
  WriteInt(I.x); (* 5 *)
  r.v := {1..9};
  IF 6 IN r.v THEN WriteInt(6) END;
  s.w[2].u := 7;
  WriteInt(s.w[2].u);  (* 7 *)
  NEW(p);
  p.u := 8;
  WriteInt(p.u);  (* 8 *)
  a[4] := 9;
  WriteInt(a[4]);  (* 9 *)
  b[1, 2] := 20.0-10.0;
  WriteReal(b[1][2]);  (* 10.0 *)
  c[9].w[2].u := 11;
  WriteInt(c[9].w[2].u); (* 11 *)
  WriteLn;
  d[1] := "A";
  WriteChar(d[1]); (* A *)
  WriteChar(I.Dollar); (* $ *)
  WriteInt(I.Ten + 1); (* 11, compile time sum *)
  I.Q0;
  WriteInt(I.x); (* 15 *)
  WriteInt(I.Q1(8, 9)) (* 17 *)
END TestImport11.