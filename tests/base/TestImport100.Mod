MODULE TestImport100;
  IMPORT S := SYSTEM;
  VAR
    s: SET;
BEGIN
  s := {1};
  WriteInt(S.VAL(INTEGER, s));
END TestImport100.