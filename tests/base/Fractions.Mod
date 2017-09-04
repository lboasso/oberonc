MODULE Fractions;  (*NW  10.10.07;  Tabulate fractions 1/n*)
  CONST Base = 10; N = 32;
  
  PROCEDURE Go;
    VAR i, j, m, n, r: INTEGER;
      d: ARRAY N OF INTEGER;  (*digits*)
      x: ARRAY N OF INTEGER;  (*index*)
  BEGIN n := ReadInt(); i := 2;
      WHILE i <= n DO j := 0;
        WHILE j < i DO x[j] := 0; j := j+1 END ;
        m := 0; r := 1;
        WHILE x[r] = 0 DO
          x[r] := m; r := Base*r; d[m] := r DIV i; r := r MOD i; m := m+1
        END ;
        WriteInt(i); WriteChar(CHR(9)); WriteChar("."); j := 0;
        WHILE j < x[r] DO WriteChar(CHR(d[j] + 48)); j := j+1 END ;
        WriteChar("'");
        WHILE j < m DO WriteChar(CHR(d[j] + 48)); j := j+1 END ;
        WriteLn; i := i+1
      END
  END Go;

BEGIN Go
END Fractions.