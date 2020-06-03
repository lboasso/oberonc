MODULE RandomNumbers;
  IMPORT Math;

  VAR Z: INTEGER;

  PROCEDURE Uniform*(): REAL;
    CONST
      a = 16807;  m = 2147483647;
      q = m DIV a;  r = m MOD a;
    VAR g: INTEGER;
  BEGIN
    g := a*(Z MOD q) - r*(Z DIV q);
    IF g > 0 THEN Z := g ELSE Z := g + m END;
    RETURN FLT(Z)*(1.0/FLT(m))
  END Uniform;

  PROCEDURE Exp*(mu: REAL): REAL;
  BEGIN
    RETURN -Math.ln(Uniform())/mu
  END Exp;

  PROCEDURE InitSeed*(seed: INTEGER);
  BEGIN
    Z := seed
  END InitSeed;

BEGIN
  Z := 1;
END RandomNumbers.
