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

  CONST versionkey = 1; maxTypTab = 500;
    (* class values *) Head = 0;
      Const* = 1; Var* = 2; Par* = 3; ParStruct* = 4;
      Fld* = 5; Typ* = 6; SProc* = 7; SFunc* = 8; Mod* = 9;

    (* form values *)
      Byte* = 1; Bool* = 2; Char* = 3; Int* = 4; Real* = 5;  Set* = 6;
      Pointer* = 7; NilTyp* = 8; NoTyp* = 9; Proc* = 10; String* = 11;
      Array* = 12; Record* = 13;

  TYPE Object* = POINTER TO ObjDesc;
    Module* = POINTER TO ModDesc;
    Type* = POINTER TO TypeDesc;

    ObjDesc* = RECORD
      class*, lev*: INTEGER;
      expo*, rdo*: BOOLEAN;   (*exported / read-only*)
      next*, dsc*: Object;
      type*, recordType*, caseOrgType*: Type;
      name*: OJS.Ident;
      val*: INTEGER
    END ;

    ModDesc* = RECORD (ObjDesc) orgname*: OJS.Ident END ;

    TypeDesc* = RECORD
      form*, ref*, mno*: INTEGER;  (*ref is only used for import/export*)
      nofpar*: INTEGER;  (*for procedures, extension level for records*)
      len*: INTEGER;  (*for arrays, len < 0 => open array*)
      dsc*, typobj*: Object;
      base*: Type;  (*for arrays, records, pointers*)
      signature*: ClassFormat.Descriptor;
      name*, modName*: OJS.Ident;
    END;

  VAR topScope*, universe, system*: Object;
    byteType*, boolType*, charType*: Type;
    intType*, realType*, setType*, nilType*, noType*, strType*: Type;
    nofmod, Ref, anonRecIdx: INTEGER;
    typtab: ARRAY maxTypTab OF Type;
    outFolder, homeFolder: ARRAY OJS.maxPath OF CHAR;

  PROCEDURE getOutputFolder*(VAR folder: ARRAY OF CHAR): INTEGER;
    VAR i: INTEGER;
  BEGIN
    i := Strings.Write(outFolder, folder, 0)
    RETURN i
  END getOutputFolder;

  (*insert new Object with name id*)
  PROCEDURE NewObj*(id: OJS.Ident; class: INTEGER): Object;
    VAR new, x, obj: Object;
  BEGIN x := topScope;
    WHILE (x.next # NIL) & (x.next.name # id) DO x := x.next END ;
    IF x.next = NIL THEN
      NEW(new); new.name := id;
      new.class := class; new.next := NIL; new.rdo := FALSE; new.dsc := NIL;
      x.next := new; obj := new; x.caseOrgType := NIL;
    ELSE obj := x.next; OJS.Mark("mult def")
    END ;
    RETURN obj
  END NewObj;

  PROCEDURE generateAnonymousTypeObj*(type: Type): Object;
    VAR anon: Object;
  BEGIN
    NEW(anon);
    Strings.Append("$Anonymous", anon.name);
    Strings.AppendInt(anonRecIdx, 0, anon.name);
    anon.class := Typ;
    anon.type := type;
    anon.lev := 0;
    anon.expo := TRUE;
    type.typobj := anon;
    Strings.Copy(anon.name, anon.type.name);
    INC(anonRecIdx)
    RETURN anon
  END generateAnonymousTypeObj;

  PROCEDURE thisObj*(name: ARRAY OF CHAR): Object;
    VAR s, x: Object;
  BEGIN s := topScope;
    REPEAT x := s.next;
      WHILE (x # NIL) & (x.name # name) DO x := x.next END ;
      s := s.dsc
    UNTIL (x # NIL) OR (s = NIL);
    RETURN x
  END thisObj;

  PROCEDURE thisimport*(mod: Object; name: ARRAY OF CHAR): Object;
    VAR obj: Object;
  BEGIN
    IF mod.rdo THEN
      IF mod.name[0] # 0X THEN
        obj := mod.dsc;
        WHILE (obj # NIL) & (obj.name # name) DO obj := obj.next END
      ELSE obj := NIL
      END
    ELSE obj := NIL
    END ;
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

  PROCEDURE ThisModule(name, orgname: OJS.Ident; non: BOOLEAN;
                       key: INTEGER): Object;
    VAR mod: Module; obj, obj1: Object;
  BEGIN obj1 := topScope; obj := obj1.next;  (*search for module*)
    WHILE (obj # NIL) & (obj IS Module) & (obj(Module).orgname # orgname) DO
      obj1 := obj; obj := obj1.next
    END ;
    IF obj = NIL THEN  (*insert new module*)
      NEW(mod); mod.class := Mod; mod.rdo := FALSE;
      Strings.Copy(name, mod.name); Strings.Copy(orgname, mod.orgname);
      mod.val := key; mod.lev := nofmod; INC(nofmod); mod.type := noType;
      mod.dsc := NIL; mod.next := NIL;
      obj1.next := mod; obj := mod
    ELSE (*module already present*)
      IF non THEN OJS.Mark("invalid import order") END
    END
    RETURN obj
  END ThisModule;

  PROCEDURE InType(f: Files.File; thismod: Object): Type;
    VAR
      key, ref, class, form, np, readonly: INTEGER;
      fld, par, obj, mod: Object;
      T, t: Type;
      name, modname: OJS.Ident;
  BEGIN
    NEW(T);
    IF Files.Status(f) = Files.OK THEN
      ref := Files.Read(f);
      IF ref < 0 THEN T := typtab[-ref]  (*already read*)
      ELSE NEW(t); T := t; typtab[ref] := t; t.mno := thismod.lev;
        form := Files.Read(f); t.form := form;
        Files.ReadAsciiStr(f, t.name);
        Files.ReadAsciiStr(f, t.modName);
        IF form = Pointer THEN t.base := InType(f, thismod)
        ELSIF form = Array THEN
          t.base := InType(f, thismod); t.len := Files.ReadNum(f)
        ELSIF form = Record THEN
          t.base := InType(f, thismod);
          IF t.base.form = NoTyp THEN
            t.base := NIL; obj := NIL
          ELSE
            obj := t.base.dsc
          END;
          class := Files.Read(f);
          WHILE class # 0 DO  (*fields*)
            NEW(fld); fld.class := class; Files.ReadAsciiStr(f, fld.name);
            IF fld.name[0] # 0X THEN
              fld.expo := TRUE; fld.type := InType(f, thismod)
            ELSE
              fld.expo := FALSE; fld.type := nilType
            END ;
            fld.recordType := t;
            fld.val := 0; fld.next := obj; obj := fld; class := Files.Read(f)
          END ;
          t.dsc := obj
        ELSIF form = Proc THEN
          t.base := InType(f, thismod);
          Files.ReadAsciiStr(f, t.signature);
          obj := NIL; np := 0; class := Files.Read(f);
          WHILE class # 0 DO  (*parameters*)
            NEW(par); par.class := class; readonly := Files.Read(f);
            par.rdo := readonly = 1; par.type := InType(f, thismod);
            par.next := obj; obj := par; INC(np); class := Files.Read(f)
          END ;
          t.dsc := obj; t.nofpar := np
        END;
        Files.ReadAsciiStr(f, modname);
        IF modname[0] # 0X THEN  (*re-import*)
          key := Files.ReadInt(f); Files.ReadAsciiStr(f, name);
          mod := ThisModule(modname, modname, FALSE, key);
          obj := mod.dsc;  (*search type*)
          WHILE (obj # NIL) & (obj.name # name) DO obj := obj.next END ;
          IF obj # NIL THEN (*type object found in object list of mod*)
            T := obj.type
          ELSE (*insert new type object in object list of mod*)
            NEW(obj); Strings.Copy(name, obj.name); obj.class := Typ;
            obj.next := mod.dsc; mod.dsc := obj; obj.type := t;
            t.mno := mod.lev; t.typobj := obj; T := t
          END ;
          typtab[ref] := T
        END
      END
    END
    RETURN T
  END InType;

  PROCEDURE Import*(VAR modid, modid1: OJS.Ident);
    VAR
      key, class: INTEGER;
      obj: Object; t: Type;
      thismod: Object;
      modname: OJS.Ident;
      fname: ARRAY OJS.maxPath OF CHAR;
      f: Files.File;
  BEGIN
    key := 0;
    IF modid1 = "SYSTEM" THEN
      thismod := ThisModule(modid, modid1, TRUE, key); DEC(nofmod);
      thismod.lev := 0; thismod.dsc := system; thismod.rdo := TRUE
    ELSE
      f := findSymFile(fname, modid1);
      IF f # NIL THEN
        key := Files.ReadInt(f); Files.ReadAsciiStr(f, modname);
        IF modname # modid1 THEN OJS.Mark("inconsistent module name") END;
        thismod := ThisModule(modid, modid1, TRUE, key); thismod.rdo := TRUE;
        class := Files.Read(f); (*version key*)
        IF class # versionkey THEN OJS.Mark("wrong version") END ;
        class := Files.Read(f);
        WHILE (class # 0) & (Files.Status(f) = Files.OK) DO
          NEW(obj); obj.class := class; Files.ReadAsciiStr(f, obj.name);
          obj.type := InType(f, thismod); obj.lev := -thismod.lev;
          IF class = Typ THEN
            t := obj.type; t.typobj := obj
          ELSIF class = Const THEN
            IF obj.type.form = Real THEN
              obj.val :=  Files.ReadInt(f)
            ELSE
              obj.val := Files.ReadNum(f)
            END
          ELSIF class = Var THEN obj.rdo := TRUE
          END ;
          obj.next := thismod.dsc; thismod.dsc := obj; class := Files.Read(f)
        END ;
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

  PROCEDURE OutType(f: Files.File; t: Type);
    VAR obj, mod, fld: Object;

    PROCEDURE OutPar(f: Files.File; par: Object; n: INTEGER);
      VAR cl: INTEGER;
    BEGIN
      IF n > 0 THEN
        OutPar(f, par.next, n-1); cl := par.class;
        Files.Write(f, cl);
        IF par.rdo THEN Files.Write(f, 1) ELSE Files.Write(f, 0) END ;
        OutType(f, par.type)
      END
    END OutPar;

  BEGIN
    IF Files.Status(f) = Files.OK THEN
      IF t.ref > 0 THEN (*type was already output*) Files.Write(f, -t.ref)
      ELSE obj := t.typobj;
        IF obj # NIL THEN
          Files.Write(f, Ref); t.ref := Ref; INC(Ref)
        ELSE (*anonymous*)
          Files.Write(f, 0)
        END ;
        Files.Write(f, t.form);
        Files.WriteAsciiStr(f, t.name);
        Files.WriteAsciiStr(f, t.modName);
        IF t.form = Pointer THEN OutType(f, t.base)
        ELSIF t.form = Array THEN OutType(f, t.base); Files.WriteNum(f, t.len)
        ELSIF t.form = Record THEN
          IF t.base # NIL THEN OutType(f, t.base) ELSE OutType(f, noType) END ;
          fld := t.dsc;
          WHILE fld # NIL DO  (*fields*)
            IF fld.expo THEN
              Files.Write(f, Fld); Files.WriteAsciiStr(f, fld.name);
              OutType(f, fld.type)
            END ;
            fld := fld.next
          END ;
          Files.Write(f, 0)
        ELSIF t.form = Proc THEN
          OutType(f, t.base);
          Files.WriteAsciiStr(f, t.signature);
          OutPar(f, t.dsc, t.nofpar); Files.Write(f, 0)
        END ;
        IF (t.mno > 0) & (obj # NIL) THEN  (*re-export, output name*)
          mod := topScope.next;
          WHILE (mod # NIL) & (mod.lev # t.mno) DO  mod := mod.next END ;
          IF (mod # NIL) & (mod IS Module) THEN
            Files.WriteAsciiStr(f, mod(Module).orgname);
            Files.WriteInt(f, mod.val); Files.WriteAsciiStr(f, obj.name)
          ELSE OJS.Mark("re-export not found"); Files.Write(f, 0) END
        ELSE Files.Write(f, 0)
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
    IF (f # NIL) & (Files.Seek(f, 0) = Files.OK) THEN
      oldkey := Files.ReadInt(f);
      Files.Close(f);
      ok := Files.Status(f) = Files.OK
    END
    RETURN ok
  END readOldKey;

  PROCEDURE Export*(VAR modid: OJS.Ident; VAR newSF: BOOLEAN; VAR key: INTEGER);
    VAR x, sum, i, r, len, rename, oldkey: INTEGER;
      obj: Object;
      filename, tmpFile: ARRAY OJS.maxPath OF CHAR;
      f: Files.File;
      found: BOOLEAN;
  BEGIN
    rename := Files.OK;
    Ref := Record + 1; MakeFileName(FALSE, filename, modid, ".smb");
    MakeFileName(FALSE, tmpFile, modid, ".smb.tmp");
    f := Files.Create(tmpFile);
    IF f # NIL THEN
      Files.WriteInt(f, 0); (*placeholder for key to be inserted at the end*)
      Files.WriteAsciiStr(f, modid); Files.Write(f, versionkey);
      obj := topScope.next;
      WHILE (obj # NIL) & (Files.Status(f) = Files.OK) DO
        IF obj.expo THEN
          Files.Write(f, obj.class); Files.WriteAsciiStr(f, obj.name);
          OutType(f, obj.type);
          (* no need to export recordType *)
          IF obj.class = Const THEN
            IF obj.type.form = Real THEN Files.WriteInt(f, obj.val)
            ELSE Files.WriteNum(f, obj.val) END
          END
        END ;
        obj := obj.next;
      END ;
      len := Files.Size(f);
      IF len # -1 THEN
        REPEAT Files.Write(f, 0); INC(len) UNTIL len MOD 4 = 0;
      END ;
      FOR Ref := Record+1 TO maxTypTab-1 DO typtab[Ref] := NIL END ;
      (* compute key (checksum) *)
      r := Files.Seek(f, 0); sum := Files.ReadInt(f);
      i := 4;
      len := Files.Size(f);
      WHILE (i < len) & (Files.Status(f) = Files.OK) DO
        x := Files.ReadInt(f); sum := sum + x; INC(i, 4)
      END ;
      (*sum is new key*)
      found := readOldKey(filename, oldkey);
      IF (sum # oldkey) OR ~found THEN
        IF newSF OR ~found THEN
          key := sum; newSF := TRUE; r := Files.Seek(f, 0);
          Files.WriteInt(f, sum);  (*insert checksum*)
          Files.Close(f);
          rename := Files.Rename(tmpFile, filename)
        ELSE Files.Close(f); OJS.Mark("new symbol file inhibited") END ;
      ELSE
        newSF := FALSE; key := sum;
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

  PROCEDURE Init*(outputFolder: ARRAY OF CHAR);
  BEGIN
    topScope := universe; nofmod := 1; anonRecIdx := 0;
    Strings.Copy(outputFolder, outFolder)
  END Init;

  PROCEDURE type(ref, form: INTEGER): Type;
    VAR tp: Type;
  BEGIN NEW(tp); tp.form := form; tp.ref := ref; tp.base := NIL;
    typtab[ref] := tp RETURN tp
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
  enter("WriteLn", SProc, noType, 17);
  enter("WriteReal", SProc, noType, 181);

  topScope := NIL; OpenScope; topScope.next := system; universe := topScope;

  system := NIL;  (* initialize "unsafe" pseudo-module SYSTEM*)
  enter("VAL", SFunc, intType, 162);
  Os.GetEnv(homeFolder, "OBERON_BIN");
  IF homeFolder = "" THEN homeFolder := "." END
END OJB.
