MODULE  IFS;
  IMPORT RandomNumbers, XYplane;

  VAR
    a1, b1, c1, d1, e1, f1, p1: REAL;   (* IFS parameters *)
    a2, b2, c2, d2, e2, f2, p2: REAL;   (* IFS parameters *)
    a3, b3, c3, d3, e3, f3, p3: REAL;   (* IFS parameters *)
    a4, b4, c4, d4, e4, f4, p4: REAL;   (* IFS parameters *)
    X, Y: REAL;   (* the position of the pen *)
    x0: INTEGER;  (* Distance of origin fm left edge[pixels] *)
    y0: INTEGER;  (* Distance of origin from bottom edge[pixels] *)
    e: INTEGER; (* Size of unit interval [pixels] *)

  PROCEDURE Draw;
  VAR
    x, y: REAL;         (* new position *)
    xi, eta: INTEGER;    (* pixel coordinates of pen *)
    rn: REAL;
    i : INTEGER;
  BEGIN
    i := 0;
    REPEAT
      rn := RandomNumbers.Uniform();
      IF rn < p1 THEN
        x := a1 * X + b1 * Y + e1;  y := c1 * X + d1 * Y + f1
      ELSIF rn < (p1 + p2) THEN
        x := a2 * X + b2 * Y + e2;  y := c2 * X + d2 * Y + f2
      ELSIF rn < (p1 + p2 + p3) THEN
        x := a3 * X + b3 * Y + e3;  y := c3 * X + d3 * Y + f3
      ELSE
        x := a4 * X + b4 * Y + e4;  y := c4 * X + d4 * Y + f4
      END;
      X := x;  xi := x0 + FLOOR(X*FLT(e));
      Y := y;  eta := y0 + FLOOR(Y*FLT(e));
      XYplane.Dot(xi, eta, XYplane.draw);
      INC(i)
    UNTIL i = 100000
  END Draw;

  PROCEDURE Init;
  BEGIN
    X := 0.0; Y := 0.0;   (* Initial position of pen *)
    RandomNumbers.InitSeed(1);
    x0 := 320; y0 := 75; e := 64;
    a1 := 0.0; a2 := 0.85; a3 := 0.2; a4 := -0.15;
    b1 := 0.0; b2 := 0.04; b3 := -0.26; b4 := 0.28;
    c1 := 0.0; c2 := -0.04; c3 := 0.23; c4 := 0.26;
    d1 := 0.16; d2 := 0.85; d3 := 0.22; d4 := 0.24;
    e1 := 0.0; e2 := 0.0; e3 := 0.0; e4 := 0.0;
    f1 := 0.0; f2 := 1.6; f3 := 1.6; f4 := 0.44;
    p1 := 0.01; p2 := 0.85; p3 := 0.07; p4 := 0.07;
  END Init;

BEGIN
  XYplane.Open; Init; Draw
END IFS.
