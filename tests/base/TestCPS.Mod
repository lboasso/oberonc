MODULE TestCPS;

TYPE F = PROCEDURE(i: INTEGER);

PROCEDURE log(i : INTEGER);
BEGIN 
  WriteInt(i)
END log;

PROCEDURE tailFact(n,a : INTEGER; ret : F);
BEGIN
  IF n = 0 THEN ret(a)
  ELSE tailFact(n-1, n*a, ret) END
END tailFact;

BEGIN
  tailFact(6, 1, log)
END TestCPS.