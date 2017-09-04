MODULE Powers;  (*NW  25.1.2013 fo Oberon-07; Tabulate positive and negative powers of 2*)
  CONST N = 32; M = 11;  (*M ~ N*log2*)
  
  PROCEDURE Go;
    VAR i, k, n, exp: INTEGER;
      c, r, t: INTEGER;
      d: ARRAY M OF INTEGER;
      f: ARRAY N OF INTEGER;
  BEGIN n := ReadInt(); d[0] := 1; k := 1; exp := 1;
      WHILE exp < n DO
        (*compute d = 2^exp*)
        c := 0;  (*carry*) i := 0;
        WHILE i < k DO
          t := 2*d[i] + c;
          IF t < 10 THEN d[i] := t; c := 0 ELSE d[i] := t - 10; c := 1 END ;
          i := i+1
        END ;
        IF c = 1 THEN d[k] := 1; k := k+1 END ;
        (*write d*) i := M;
        WHILE i > k DO i := i-1; WriteChar(" ") END ;
        WHILE i > 0 DO i := i-1; WriteChar(CHR(d[i] + 48)) END ;
        WriteInt(exp);
        (*compute  f = 2^-exp*)
        WriteChar(CHR(9)); WriteChar("0"); WriteChar(".");
        r := 0; i := 1;
        WHILE i < exp DO
          r := 10*r + f[i]; f[i] := r DIV 2; r := r MOD 2;
          WriteChar(CHR(f[i] + 48)); i := i+1
        END ;
        f[exp] := 5; WriteChar("5"); WriteLn; exp := exp + 1
      END
  END Go;

BEGIN Go
END Powers.