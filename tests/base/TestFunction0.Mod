MODULE TestFunction0;
  VAR x : INTEGER;
   
  PROCEDURE P1(i : INTEGER): INTEGER;
    PROCEDURE P2(j, z : INTEGER) : INTEGER;
      VAR k : INTEGER;
    BEGIN
      k := z;
      RETURN k + j
    END P2;
  BEGIN 
    RETURN i + P2(i, 2)
  END P1;

BEGIN
  x := P1(1);
  WriteInt(x);
END TestFunction0.