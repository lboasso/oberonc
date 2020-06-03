MODULE TestMath;
  IMPORT Math;
  VAR x: REAL;

BEGIN
  x := Math.pi;
  x := Math.e;
  x := 0.7;
  WriteReal(Math.sqrt(x)); WriteLn;
  WriteReal(Math.power(2.0, x)); WriteLn;
  WriteReal(Math.exp(x)); WriteLn;
  WriteReal(Math.ln(x)); WriteLn;
  WriteReal(Math.log(x, 2.0)); WriteLn;
  WriteReal(Math.round(x)); WriteLn;
  WriteReal(Math.sin(x)); WriteLn;
  WriteReal(Math.cos(x)); WriteLn;
  WriteReal(Math.tan(x)); WriteLn;
  WriteReal(Math.arcsin(x)); WriteLn;
  WriteReal(Math.arccos(x)); WriteLn;
  WriteReal(Math.arctan(x)); WriteLn;
  WriteReal(Math.arctan2(x, 0.3)); WriteLn;
  WriteReal(Math.sinh(x)); WriteLn;
  WriteReal(Math.cosh(x)); WriteLn;
  WriteReal(Math.tanh(x)); WriteLn;
  WriteReal(Math.arcsinh(x)); WriteLn;
  WriteReal(Math.arccosh(1.0 + x)); WriteLn;
  WriteReal(Math.arctanh(x)); WriteLn
END TestMath.