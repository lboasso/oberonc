MODULE Util;

  PROCEDURE strToInt*(str: ARRAY OF CHAR): INTEGER;
    VAR res, i, x: INTEGER;
  BEGIN
    res := 0;
    FOR i := 0 TO LEN(str)-1 DO
      x := ORD(str[i]) - ORD("0");
      IF (x >= 0) & (x <= 9) THEN res := res * 10 + x END
    END
    RETURN res
  END strToInt;

END Util.

