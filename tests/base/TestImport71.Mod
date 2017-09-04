MODULE TestImport71;
IMPORT Qs := TestImport70;
TYPE
  ActorDesc* = RECORD (Qs.ItemDesc) END;
VAR a: POINTER TO ActorDesc;
BEGIN NEW(a); a.key := 1; WriteInt(a.key)
END TestImport71.