MODULE PrimeNumbers;  (*NW 6.9.07; Tabulate prime numbers; for Oberon-07  NW 25.1.2013*)
  
  VAR n: INTEGER;
    p: ARRAY 400 OF INTEGER;
    v: ARRAY 20 OF INTEGER;

  PROCEDURE Primes(n: INTEGER);
    VAR i, k, m, x, inc, lim, sqr: INTEGER; prim: BOOLEAN;
  BEGIN x := 1; inc := 4; lim := 1; sqr := 4; m := 0; i := 3;
    WHILE i <= n DO
      REPEAT x := x + inc; inc := 6 - inc;
        IF sqr <= x THEN  (*sqr = p[lim]^2*)
          v[lim] := sqr; lim := lim + 1; sqr := p[lim]*p[lim]
        END ;
        k := 2; prim := TRUE;
        WHILE prim & (k < lim) DO
          k := k+1;
          IF v[k] < x THEN v[k] := v[k] + p[k] END ;
          prim := x # v[k]
        END
      UNTIL prim;
      p[i] := x; WriteInt(x);
      IF m = 10 THEN WriteLn; m := 0 ELSE m := m+1 END ;
      i := i+1
    END ;
    IF m > 0 THEN WriteLn END
  END Primes;

BEGIN n:= ReadInt(); WriteInt(n); WriteLn; Primes(n)
END PrimeNumbers.