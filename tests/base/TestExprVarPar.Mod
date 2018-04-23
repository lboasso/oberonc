MODULE TestExprVarPar;
  VAR a: INTEGER;

  PROCEDURE G(VAR i: INTEGER); END G;

BEGIN
  G(a+1)
END TestExprVarPar.
