MODULE Permutations;  (*NW 22.1.2013 for Oberon-0*)
  VAR m, n: INTEGER;
    a: ARRAY 10 OF INTEGER;

  PROCEDURE perm(k: INTEGER);
    VAR i, x: INTEGER;
  BEGIN
    IF k = 0 THEN i := 0;
      WHILE i < n DO WriteInt(a[i]); i := i+1 END ;
      WriteLn
    ELSE perm(k-1); i := 0;
      WHILE i < k-1 DO
        x := a[i]; a[i] := a[k-1]; a[k-1] := x;
        perm(k-1);
        x := a[i]; a[i] := a[k-1]; a[k-1] := x;
        i := i+1
      END
    END
  END perm;

BEGIN n := 0; m := ReadInt();
  WHILE ~eot() DO a[n] := m; n := n+1; m:= ReadInt() END ;
  perm(n)
END Permutations.