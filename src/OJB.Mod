(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

(*
  Definition of data types Object, Type, and Module which together form the data
  structure called "symbol table". Contains procedures for creation of
  Objects, and for search.
  Handling of import and export, i.e. reading and writing of "symbol files"
  is done by procedures Import and Export. This module contains the list of
  standard identifiers, with which the symbol table (universe), and that of the
  pseudo-module SYSTEM are initialized.
*)
MODULE OJB;
  IMPORT Files, OJS, ClassFormat, Strings, Os;

  CONST versionkey = 1;  keypos = 2;
    MaxTyptab = 500; MaxLModtab = 100; MaxGModtab = 200;

    (* class values *) Head = 0;
      Const* = 1; Var* = 2; Par* = 3; ParStruct* = 4;
      Fld* = 5; Typ* = 6; SProc* = 7; SFunc* = 8; Mod* = 9;

    (* form values *)
      Byte* = 1; Bool* = 2; Char* = 3; Int* = 4; Real* = 5;  Set* = 6;
      Pointer* = 7; NilTyp* = 8; NoTyp* = 9; Proc* = 10; String* = 11;
      Array* = 12; Record* = 13;

  TYPE Object* = POINTER TO ObjDesc;
    Type* = POINTER TO TypeDesc;

    ObjDesc* = RECORD
      class*, modref: INTEGER;
      (*
         when class = Typ, lev <= 0 -> mno = -lev, 0 is the compiling module
         otherwise lev >= 0 -> scope level, 0 is the global scope
       *)
      lev*: INTEGER;
      expo*, rdo*: BOOLEAN;   (*exported / read-only*)
      used: BOOLEAN;
      next*, dsc*: Object;
      type*: Type;
      recordType*, caseOrgType*: Type; (* computed, not serialized *)
      name*: OJS.Ident;
      val*, len*: INTEGER
    END ;

    TypeDesc* = RECORD
      form*, ref*: INTEGER;  (*ref is only used for import/export*)
      nofpar*: INTEGER;  (*for procedures, extension level for records*)
      len*: INTEGER;  (*for arrays, len < 0 -> open array*)
      dsc*, typobj*: Object;
      base*: Type;  (*for arrays, records, pointers*)
      signature*: ClassFormat.Descriptor;
    END;

  VAR topScope*, universe, system*: Object;
    byteType*, boolType*, charType*: Type;
    intType*, realType*, setType*, nilType*, noType*, strType*: Type;
    nofGMods, nofLMods, nofLTypes, anonRecIdx: INTEGER;
    GModtab: ARRAY MaxGModtab OF Object; (* GModtab[0] = compiling module *)
    LModtab: ARRAY MaxLModtab OF Object;
    LTyptab: ARRAY MaxTyptab OF Type; (* LTyptab[0] = NIL *)
    outFolder, homeFolder: ARRAY OJS.maxPath OF CHAR;

  PROCEDURE getOutputFolder*(VAR folder: ARRAY OF CHAR): INTEGER;
    VAR i: INTEGER;
  BEGIN
    i := Strings.Write(outFolder, folder, 0)
    RETURN i
  END getOutputFolder;

  PROCEDURE GetModFrom*(obj: Object): Object;
    VAR modIdx: INTEGER;
  BEGIN
    modIdx := 0;
    IF (obj # NIL) & (obj.lev < 0) THEN
      (* external type *)
      modIdx := -obj.lev;
    END
    RETURN GModtab[modIdx]
  END GetModFrom;

  (*insert new Object with name id*)
  PROCEDURE InsertObj*(id: OJS.Ident; class: INTEGER): Object;
    VAR new, x, obj: Object;
  BEGIN x := topScope;
    WHILE (x.next # NIL) & (x.next.name # id) DO x := x.next END ;
    IF x.next = NIL THEN
      NEW(new); new.name := id;
      new.class := class; new.next := NIL; new.rdo := FALSE; new.dsc := NIL;
      new.modref := -1; (*un-marked*); new.lev := 0; new.len := 0; new.val := 0;
      new.expo := FALSE; new.type := NIL; new.recordType := NIL;
      new.caseOrgType := NIL; new.used := FALSE;
      x.next := new; obj := new
    ELSE obj := x.next; OJS.Mark("mult def")
    END ;
    RETURN obj
  END InsertObj;

  PROCEDURE generateAnonymousTypeObj*(type: Type): Object;
    VAR anon: Object;
  BEGIN
    NEW(anon);
    Strings.Append("$Anonymous", anon.name);
    Strings.AppendInt(anonRecIdx, 0, anon.name);
    anon.class := Typ;
    anon.type := type;
    anon.lev := 0;
    anon.expo := FALSE;
    type.typobj := anon;
    INC(anonRecIdx)
    RETURN anon
  END generateAnonymousTypeObj;

  PROCEDURE thisObj*(name: ARRAY OF CHAR): Object;
    VAR s, x: Object;
  BEGIN s := topScope;
    REPEAT x := s.next;
      WHILE (x # NIL) & (x.name # name) DO x := x.next END ;
      IF (x # NIL) & (s # topScope) & (x.lev > 0) & (* no local or global *)
          (x.class IN {Var, Par, ParStruct}) THEN
        OJS.Mark("not accessible");
        x := NIL
      END ;
      s := s.dsc
    UNTIL (x # NIL) OR (s = NIL);
    IF x # NIL THEN x.used := TRUE END
    RETURN x
  END thisObj;

  PROCEDURE thisimport*(mod: Object; name: ARRAY OF CHAR): Object;
    VAR obj: Object;
  BEGIN
    obj := NIL;
    IF (mod # NIL) & (mod.class = Mod) THEN
      obj := mod.dsc;
      WHILE (obj # NIL) & (~obj.expo OR (obj.name # name)) DO
        obj := obj.next
      END
    END
    RETURN obj
  END thisimport;

  PROCEDURE thisfield*(rec: Type): Object;
    VAR fld: Object;
  BEGIN fld := rec.dsc;
    WHILE (fld # NIL) & (fld.name # OJS.id) DO fld := fld.next END ;
    RETURN fld
  END thisfield;

  PROCEDURE FindObj*(modid, modName, name: ARRAY OF CHAR): Object;
    VAR obj: Object;
  BEGIN
    IF modid # modName THEN
      obj := thisObj(modName);
      obj := thisimport(obj, name)
    ELSE
      obj := thisObj(name)
    END
    RETURN obj
  END FindObj;

  PROCEDURE OpenScope*;
    VAR s: Object;
  BEGIN NEW(s); s.class := Head; s.dsc := topScope; s.next := NIL; topScope := s
  END OpenScope;

  PROCEDURE CheckUnused*(parsNum: INTEGER);
    VAR err: ARRAY OJS.IdLen*30 OF CHAR;
      i: INTEGER; x: Object;
  BEGIN
    x := topScope.next;
    i := 0;
    (* skip parameters *)
    WHILE i < parsNum DO x := x.next; INC(i) END;
    i := 0;
    WHILE x # NIL DO
      IF ~x.expo & ~x.used & ((x.class = Var) OR (x.class = Mod)) THEN
        i := Strings.Write(x.name, err, i);
        i := Strings.WriteChar(" ", err, i)
      END ;
      x := x.next
    END ;
    IF i # 0 THEN OJS.MarkAppend("Unused: ", err) END
  END CheckUnused;

  PROCEDURE CloseScope*;
  BEGIN topScope := topScope.dsc
  END CloseScope;

  (*------------------------------- Import ---------------------------------*)

  PROCEDURE MakeFileName*(useHome: BOOLEAN; VAR FName: ARRAY OF CHAR;
                          name, ext: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    IF useHome THEN
      i := Strings.Write(homeFolder, FName, 0)
    ELSE
      i := getOutputFolder(FName)
    END ;
    i := Strings.Write(Files.SEPARATOR, FName, i);
    i := Strings.Write(name, FName, i);
    i := Strings.Write(ext, FName, i);
    IF i = -1 THEN OJS.Mark("Maximum file path length reached") END
  END MakeFileName;

  PROCEDURE findSymFile(VAR fname: ARRAY OF CHAR;
                        modName: ARRAY OF CHAR): Files.File;
    VAR f: Files.File;
  BEGIN
    MakeFileName(FALSE, fname, modName, ".smb");
    f := Files.Open(fname);
    IF f = NIL THEN
      MakeFileName(TRUE, fname, modName, ".smb");
      f := Files.Open(fname)
    END
    RETURN f
  END findSymFile;

  PROCEDURE InsertImport(obj, mod: Object): Object;
    VAR prev, cur: Object;
  BEGIN
    IF mod.dsc = NIL THEN
      mod.dsc := obj
    ELSE
      prev := NIL;
      cur := mod.dsc;
      WHILE (cur # NIL) & (cur.name # obj.name) DO
        prev := cur;
        cur := cur.next
      END ;
      IF cur = NIL THEN prev.next := obj ELSE obj := cur END
    END ;
    obj.lev := mod.lev
    RETURN obj
  END InsertImport;

  PROCEDURE InsertMod(name: OJS.Ident; key: INTEGER): Object;
    VAR mod: Object; i: INTEGER;
  BEGIN
    i := 0;
    WHILE (i < nofGMods) & (name # GModtab[i].name) DO INC(i) END;
    IF i < nofGMods THEN (* module already imported *)
      mod := GModtab[i];
      IF mod.val # key THEN OJS.Mark("key inconsistency of imported module") END
    ELSE
      NEW(mod); mod.class := Mod; mod.rdo := TRUE; mod.expo := FALSE;
      Strings.Copy(name, mod.name); mod.val := key;
      mod.lev := -nofGMods; mod.type := noType;
      mod.dsc := NIL; mod.next := NIL;
      mod.modref := -1;
      IF nofGMods < MaxGModtab THEN
        GModtab[nofGMods] := mod; INC(nofGMods)
      ELSE
        OJS.Mark("too many imported modules")
      END
    END
    RETURN mod
  END InsertMod;

  PROCEDURE InMod(f: Files.File; selfName: OJS.Ident): Object;
    VAR
      ref, key: INTEGER;
      name: OJS.Ident;
      mod: Object;
  BEGIN
    ref := Files.ReadNum(f);
    IF ref > 0 THEN (* first occurrence *)
      key := Files.ReadInt(f);
      Files.ReadAsciiStr(f, name);
      IF name = selfName THEN OJS.Mark("recursive import not allowed") END;
      mod := InsertMod(name, key);
      IF nofLMods < MaxLModtab THEN
        LModtab[nofLMods] := mod; INC(nofLMods)
      ELSE
        OJS.Mark("too many imported modules")
      END
    ELSE
      mod := LModtab[-ref]
    END
    RETURN mod
  END InMod;

  PROCEDURE InType(f: Files.File; selfName: OJS.Ident): Type;
    VAR
      class, form, np: INTEGER;
      fld, par, obj, last, mod: Object;
      typ, htyp: Type;
      name: OJS.Ident;
  BEGIN
    typ := NIL;
    IF Files.Status(f) = Files.OK THEN
      form := Files.ReadNum(f);
      IF form <= 0 THEN typ := LTyptab[-form] (* already read or NIL *)
      ELSE
        NEW(htyp); htyp.form := form;
        Files.ReadAsciiStr(f, name);
        IF name[0] # 0X THEN (* named type *)
          NEW(obj); Strings.Copy(name, obj.name);
          obj.expo := Files.ReadNum(f) = 1;
          obj.class := Typ; obj.type := htyp;
          htyp.typobj := obj; mod := InMod(f, selfName);
          obj := InsertImport(obj, mod);
          typ := obj.type
        ELSE
          typ := htyp
        END ;
        IF nofLTypes < MaxTyptab THEN LTyptab[nofLTypes] := typ; INC(nofLTypes)
        ELSE OJS.Mark("too many imported types")
        END;
        IF form = Pointer THEN htyp.base := InType(f, selfName)
        ELSIF form = Array THEN
          htyp.base := InType(f, selfName); htyp.len := Files.ReadNum(f)
        ELSIF form = Record THEN
          htyp.base := InType(f, selfName);
          IF htyp.base = NIL THEN obj := NIL
          ELSE obj := htyp.base.dsc
          END;
          class := Files.ReadNum(f);
          last := NIL;
          WHILE class # 0 DO (* fields *)
            NEW(fld); fld.class := class;
            Files.ReadAsciiStr(f, fld.name);
            fld.expo := TRUE; fld.type := InType(f, selfName);
            fld.recordType := htyp;
            fld.val := 0; class := Files.ReadNum(f);
            IF last = NIL THEN htyp.dsc := fld ELSE last.next := fld END ;
            last := fld
          END ;
          (* append base type fields *)
          IF last = NIL THEN htyp.dsc := obj ELSE last.next := obj END
        ELSIF form = Proc THEN
          htyp.base := InType(f, selfName);
          Files.ReadAsciiStr(f, htyp.signature);
          np := Files.ReadNum(f);
          htyp.nofpar := np;
          par := NIL;
          last := NIL;
          WHILE np > 0 DO (* parameters *)
            NEW(obj); obj.class := Files.ReadNum(f);
            obj.rdo := Files.ReadNum(f) = 1;
            obj.type := InType(f, selfName);
            IF par = NIL THEN par := obj ELSE last.next := obj END;
            last := obj; DEC(np)
          END ;
          htyp.dsc := par
        END
      END
    END
    RETURN typ
  END InType;

  PROCEDURE Import*(VAR aliasName, impName, selfName: OJS.Ident);
    VAR
      class, version, i: INTEGER;
      obj, mod, mod0, dummyMod: Object;
      dummyType: Type;
      name: OJS.Ident;
      fname: ARRAY OJS.maxPath OF CHAR;
      str: ARRAY OJS.stringBufSize OF CHAR;
      f: Files.File;
  BEGIN
    IF impName = "SYSTEM" THEN
      mod := InsertObj(aliasName, Mod);
      mod.dsc := system; mod.rdo := TRUE
    ELSE
      f := findSymFile(fname, impName);
      IF f # NIL THEN
        nofLMods := 0;
        nofLTypes := Record + 1;
        version := Files.ReadNum(f);
        IF version # versionkey THEN OJS.Mark("wrong symbol version key") END;
        mod0 := InMod(f, selfName);
        IF mod0.name # impName THEN OJS.Mark("inconsistent module name") END;
        (* Read imported modules *)
        i := Files.ReadNum(f);
        WHILE i > 0 DO dummyMod := InMod(f, selfName); DEC(i) END;
        class := Files.ReadNum(f);
        WHILE (class # 0) & (Files.Status(f) = Files.OK) DO
          IF class = Typ THEN
            Files.ReadAsciiStr(f, name);
            IF name[0] # 0X THEN (* alias type *)
              NEW(obj); Strings.Copy(name, obj.name);
              obj.class := class; obj.expo := TRUE;
              obj.type := InType(f, selfName);
              obj := InsertImport(obj, mod0)
            ELSE (* other types *)
              dummyType := InType(f, selfName)
            END
          ELSE
            Files.ReadAsciiStr(f, name); NEW(obj);
            Strings.Copy(name, obj.name); obj.class := class;
            obj.expo := TRUE;
            obj.type := InType(f, selfName);
            IF class = Const THEN
              IF obj.type.form = Real THEN obj.val := Files.ReadInt(f)
              ELSIF obj.type.form = String THEN
                obj.len := Files.ReadStr(f, str) + 1; (* length + 0X *)
                obj.val := OJS.InsertStr(str, obj.len)
              ELSE obj.val := Files.ReadNum(f)
              END
            ELSIF class = Var THEN obj.rdo := TRUE
            END ;
            obj := InsertImport(obj, mod0)
          END ;
          class := Files.ReadNum(f)
        END ;
        mod := InsertObj(aliasName, Mod);
        mod.rdo := TRUE;
        mod.val := mod0.val; mod.lev := mod0.lev; mod.dsc := mod0.dsc;
        Files.Close(f);
        IF Files.Status(f) = Files.IOERROR THEN
          OJS.MarkAppend("error importing ", fname)
        END
      ELSE
        OJS.MarkAppend("import not available: ", fname)
      END
    END
  END Import;

  (*-------------------------------- Export ---------------------------------*)

  PROCEDURE OutMod(f: Files.File; mod: Object);
  BEGIN
    IF mod.modref < 0 THEN (* first occurrence *)
      mod.modref := nofLMods;
      INC(nofLMods);
      Files.WriteNum(f, Mod); Files.WriteInt(f, mod.val);
      Files.WriteAsciiStr(f, mod.name)
    ELSE
      Files.WriteNum(f, -mod.modref)
    END
  END OutMod;

  PROCEDURE OutType(f: Files.File; t: Type);
    VAR fld, par, bot: Object;
      np: INTEGER;
  BEGIN
    IF Files.Status(f) = Files.OK THEN
      IF t = NIL THEN Files.WriteNum(f, 0)
      ELSIF t.ref > 0 THEN (*type was already output*) Files.WriteNum(f, -t.ref)
      ELSE
        Files.WriteNum(f, t.form);
        t.ref := nofLTypes; INC(nofLTypes);
        IF t.typobj # NIL THEN (* named type *)
          Files.WriteAsciiStr(f, t.typobj.name);
          IF ~t.typobj.expo THEN (* invisible type *)
            Files.WriteNum(f, 0)
          ELSE
            Files.WriteNum(f, 1)
          END ;
          OutMod(f, GModtab[-t.typobj.lev])
        ELSE
          Files.WriteNum(f, 0)
        END ;
        IF t.form = Pointer THEN OutType(f, t.base)
        ELSIF t.form = Array THEN OutType(f, t.base); Files.WriteNum(f, t.len)
        ELSIF t.form = Record THEN
          OutType(f, t.base);
          IF t.base # NIL THEN
            bot := t.base.dsc
          ELSE
            bot := NIL
          END ;
          fld := t.dsc;
          WHILE fld # bot DO  (*fields*)
            IF fld.expo THEN
              Files.WriteNum(f, Fld); Files.WriteAsciiStr(f, fld.name);
              OutType(f, fld.type)
            END ;
            fld := fld.next
          END ;
          Files.WriteNum(f, 0)
        ELSIF t.form = Proc THEN
          OutType(f, t.base);
          Files.WriteAsciiStr(f, t.signature);
          par := t.dsc;
          np := t.nofpar;
          Files.WriteNum(f, np);
          WHILE np > 0 DO
            Files.WriteNum(f, par.class);
            IF par.rdo THEN Files.WriteNum(f, 1) ELSE Files.WriteNum(f, 0) END;
            OutType(f, par.type);
            par := par.next;
            DEC(np)
          END
        END
      END
    END
  END OutType;

  PROCEDURE readOldKey(filename: ARRAY OF CHAR; VAR oldkey: INTEGER): BOOLEAN;
    VAR f: Files.File;
      ok: BOOLEAN;
  BEGIN
    ok := FALSE;
    f := Files.Open(filename);
    IF (f # NIL) & (Files.Seek(f, keypos) = Files.OK) THEN
      oldkey := Files.ReadInt(f);
      Files.Close(f);
      ok := Files.Status(f) = Files.OK
    END
    RETURN ok
  END readOldKey;

  PROCEDURE Export*(VAR modid: OJS.Ident; newSF: BOOLEAN);
    VAR x, sum, i, r, len, rename, oldkey: INTEGER;
      obj: Object;
      filename, tmpFile: ARRAY OJS.maxPath OF CHAR;
      str: ARRAY OJS.stringBufSize OF CHAR;
      f: Files.File;
      found: BOOLEAN;
  BEGIN
    rename := Files.OK;
    nofLMods := 0;
    nofLTypes := Record + 1; MakeFileName(FALSE, filename, modid, ".smb");
    MakeFileName(FALSE, tmpFile, modid, ".smb.tmp");
    f := Files.Create(tmpFile);
    IF f # NIL THEN
      Files.WriteNum(f, versionkey);
      OutMod(f, GModtab[0]);
      (* Write imported modules *)
      Files.WriteNum(f, nofGMods - 1);
      i := 1;
      WHILE i < nofGMods DO OutMod(f, GModtab[i]); INC(i) END;
      obj := topScope.next;
      WHILE (obj # NIL) & (Files.Status(f) = Files.OK) DO
        IF obj.expo THEN
          Files.WriteNum(f, obj.class);
          IF (obj.class # Typ) OR (obj.type.typobj # obj) THEN
            (* no type or alias type *)
            Files.WriteAsciiStr(f, obj.name)
          ELSE
            (* other type, write name in OutType *)
            Files.WriteNum(f, 0)
          END ;
          OutType(f, obj.type);
          IF obj.class = Const THEN
            IF obj.type.form = Real THEN Files.WriteInt(f, obj.val)
            ELSIF obj.type.form = String THEN
              OJS.ExtractStr(obj.val, obj.len, str);
              Files.WriteStr(f, str)
            ELSE Files.WriteNum(f, obj.val)
            END
          END
        END ;
        obj := obj.next;
      END ;
      len := Files.Size(f);
      IF len # -1 THEN
        REPEAT Files.WriteNum(f, 0); INC(len) UNTIL len MOD 4 = 0;
      END ;
      (* reset local type table *)
      FOR nofLTypes := Record+1 TO MaxTyptab-1 DO LTyptab[nofLTypes] := NIL END ;
      (* compute key (checksum) *)
      r := Files.Seek(f, 0); sum := Files.ReadInt(f);
      i := 4;
      WHILE (i < len) & (Files.Status(f) = Files.OK) DO
        x := Files.ReadInt(f); sum := sum + x; INC(i, 4)
      END ;
      found := readOldKey(filename, oldkey);
      IF ~found OR (sum # oldkey) THEN
        IF newSF OR ~found THEN
          r := Files.Seek(f, keypos);
          Files.WriteInt(f, sum);  (*insert checksum*)
          Files.Close(f);
          rename := Files.Rename(tmpFile, filename)
        ELSE Files.Close(f); OJS.Mark("new symbol file inhibited")
        END
      ELSE
        Files.Close(f);
        r := Files.Delete(tmpFile)
      END ;
      IF (Files.Status(f) = Files.IOERROR) OR (rename = Files.IOERROR) OR
         (r = Files.IOERROR) THEN
        OJS.MarkAppend("error exporting ", filename)
      END
    ELSE
      OJS.MarkAppend("error while creating symbol file ", filename)
    END
  END Export;

  PROCEDURE Init*(outputFolder: ARRAY OF CHAR; modid: OJS.Ident);
    VAR dummy: Object;
  BEGIN
    topScope := universe; nofGMods := 0; anonRecIdx := 0;
    Strings.Copy(outputFolder, outFolder);
    dummy := InsertMod(modid, 0)
  END Init;

  PROCEDURE type(ref, form: INTEGER): Type;
    VAR tp: Type;
  BEGIN NEW(tp); tp.form := form; tp.ref := ref; tp.base := NIL;
    LTyptab[ref] := tp
    RETURN tp
  END type;

  PROCEDURE enter(name: ARRAY OF CHAR; cl: INTEGER; type: Type; n: INTEGER);
    VAR obj: Object;
  BEGIN NEW(obj); Strings.Copy(name, obj.name); obj.class := cl;
    obj.type := type; obj.val := n; obj.dsc := NIL;
    IF cl = Typ THEN type.typobj := obj END ;
    obj.next := system; system := obj
  END enter;

BEGIN
  byteType := type(Byte, Int);
  boolType := type(Bool, Bool);
  charType := type(Char, Char);
  intType := type(Int, Int);
  realType := type(Real, Real);
  setType := type(Set, Set);
  nilType := type(NilTyp, NilTyp);
  noType := type(NoTyp, NoTyp);
  strType := type(String, String);

  (*initialize universe with data types and in-line procedures;
    LONGINT is synonym to INTEGER, LONGREAL to REAL. *)
  system := NIL;  (*n = procno*10 + nofpar*)
  enter("BOR", SFunc, intType, 122);  (*functions*)
  enter("AND", SFunc, intType, 112);
  enter("NOT", SFunc, intType, 151);
  enter("ROR", SFunc, intType, 92);
  enter("ASR", SFunc, intType, 82);
  enter("LSL", SFunc, intType, 72);
  enter("LEN", SFunc, intType, 61);
  enter("CHR", SFunc, charType, 51);
  enter("ORD", SFunc, intType, 41);
  enter("FLT", SFunc, realType, 31);
  enter("FLOOR", SFunc, intType, 21);
  enter("ODD", SFunc, boolType, 11);
  enter("ABS", SFunc, intType, 1);
  enter("NEW", SProc, noType, 51);
  enter("ASSERT", SProc, noType, 41);
  enter("EXCL", SProc, noType, 32);
  enter("INCL", SProc, noType, 22);
  enter("DEC", SProc, noType, 11);
  enter("INC", SProc, noType, 1);
  enter("SET", Typ, setType, 0);   (*types*)
  enter("BOOLEAN", Typ, boolType, 0);
  enter("BYTE", Typ, byteType, 0);
  enter("CHAR", Typ, charType, 0);
  enter("LONGREAL", Typ, realType, 0);
  enter("REAL", Typ, realType, 0);
  enter("LONGINT", Typ, intType, 0);
  enter("INTEGER", Typ, intType, 0);
  enter("ARGNUM", SFunc, intType, 230);
  enter("ARGS", SProc, noType, 242);

  (* Useful during bootstrapping *)
  enter("eot", SFunc, boolType, 210);
  enter("ReadInt", SFunc, intType, 220);
  enter("WriteChar", SProc, noType, 151);
  enter("WriteInt", SProc, noType, 161);
  enter("WriteLn", SProc, noType, 170);
  enter("WriteReal", SProc, noType, 181);

  topScope := NIL; OpenScope; topScope.next := system; universe := topScope;

  system := NIL;  (* initialize "unsafe" pseudo-module SYSTEM*)
  enter("VAL", SFunc, intType, 162);
  system.expo := TRUE; (* export VAL *)
  Os.GetEnv(homeFolder, "OBERON_BIN");
  IF homeFolder = "" THEN homeFolder := "." END
END OJB.
