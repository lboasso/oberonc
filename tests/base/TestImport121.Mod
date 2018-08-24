MODULE TestImport121;
  IMPORT I := TestImport120;

  TYPE
    TypeC* = I.TypeA;
    TypeD* = I.TypeB;
END TestImport121.