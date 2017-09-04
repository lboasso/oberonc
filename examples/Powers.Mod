MODULE Powers;  (*Tabulate positive and negative powers of 2*)
  IMPORT Out, Util;
  CONST N = 32; M = 11;  (*M ~ N*log2*)

  PROCEDURE Power(n: INTEGER);
    VAR i, k, exp: INTEGER;
      c, r, t: INTEGER;
      d: ARRAY M OF INTEGER;
      f: ARRAY N OF INTEGER;
  BEGIN
      d[0] := 1; k := 1; exp := 1;
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
        WHILE i > k DO i := i-1; Out.Char(" ") END ;
        WHILE i > 0 DO i := i-1; Out.Char(CHR(d[i] + ORD("0"))) END ;
        Out.Int(exp, 5);
        (*compute  f = 2^-exp*)
        Out.String("   "); Out.Char("0"); Out.Char(".");
        r := 0; i := 1;
        WHILE i < exp DO
          r := 10*r + f[i]; f[i] := r DIV 2; r := r MOD 2;
          Out.Char(CHR(f[i] + ORD("0"))); i := i+1
        END ;
        f[exp] := 5; Out.Char("5"); Out.Ln; exp := exp + 1
      END
  END Power;

  PROCEDURE Main;
    VAR n, i: INTEGER;
      arg: ARRAY 3 OF CHAR;
  BEGIN
    n := ARGNUM();
    IF n # 1 THEN
      Out.String("usage: Powers number in [0..32]");
      Out.Ln
    ELSE
      ARGS(0, arg);
      i := Util.strToInt(arg);
      IF i <= 32 THEN  Power(i) END
    END
  END Main;
END Powers.
