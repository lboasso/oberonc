MODULE TestImport80;
  IMPORT I := TestImport81, TestImport82;

  VAR
    b: I.TypeB;
    c: TestImport82.TypeC;

BEGIN
  c := b
END TestImport80.
