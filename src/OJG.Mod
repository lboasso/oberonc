(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

(*Code generator for Oberon compiler for the Java Virtual Machine.*)
MODULE OJG;
  IMPORT SYSTEM, Files, Opcodes, Strings, ClassFormat, OJS, OJB;

  CONST NofCases* = 256;
    MaxSetElement* = 32;
    ParamsMax* = 20;
    Stack = 10; RegI = 11; Cond = 12; Field = 13; (*internal item modes*)

  TYPE
    Item* = RECORD
      mode*: INTEGER;
      type*, oldType*: OJB.Type;
      a*, b*, r: INTEGER;
      rdo*: BOOLEAN;  (*read only*)
      name*: OJS.Ident;
      modName*: OJS.Ident;
      recordName: ClassFormat.Descriptor
    END ;

    LabelRange* = RECORD low*, high*, L*: INTEGER END ;

    StoreStmt = POINTER TO StoreStmtDesc;
    StoreStmtDesc = RECORD
      x, y: Item;
      next: StoreStmt
    END ;

    ClassContext = POINTER TO ClassContextDesc;
    ClassContextDesc = RECORD
      c: ClassFormat.CF;
      m: ClassFormat.MethodInfo;
      className:  ClassFormat.Descriptor;
      numTmpVars: INTEGER;
      storeStmt: StoreStmt;
      next: ClassContext
    END ;

  VAR
    check: BOOLEAN;  (*emit run-time checks*)
    topCtx: ClassContext;
    relmap: ARRAY 6 OF INTEGER;  (*condition codes for relations*)
    relmap0: ARRAY 6 OF INTEGER;  (*condition codes for relations with 0*)
    relmapNil: ARRAY 2 OF INTEGER;  (*condition codes for relations with NIL*)
    relmapAdr: ARRAY 2 OF INTEGER;  (*condition codes for relations with adr*)
    dummyMethod: ClassFormat.MethodInfo;
  PROCEDURE curStack*(): INTEGER;
    RETURN topCtx.m.curStack
  END curStack;

  PROCEDURE clearCtx(ctx: ClassContext);
  BEGIN
    ctx.numTmpVars := 0
  END clearCtx;

  PROCEDURE closeContext;
  BEGIN
    ClassFormat.finalizeMethod(topCtx.c, topCtx.m);
    clearCtx(topCtx);
    topCtx.m := dummyMethod
  END closeContext;

  PROCEDURE SetCC(VAR x: Item; n: INTEGER);
  BEGIN
    x.mode := Cond;
    x.a := 0;
    x.b := 0;
    x.r := n;
  END SetCC;

  PROCEDURE negated(op: INTEGER): INTEGER;
    VAR ret: INTEGER;
  BEGIN
    ret := 0;
    CASE op OF
       Opcodes.IFACMPEQ: ret := Opcodes.IFACMPNE
      | Opcodes.IFACMPNE: ret := Opcodes.IFACMPEQ
      | Opcodes.IFEQ: ret := Opcodes.IFNE
      | Opcodes.IFNE: ret := Opcodes.IFEQ
      | Opcodes.IFLT: ret := Opcodes.IFGE
      | Opcodes.IFGE: ret := Opcodes.IFLT
      | Opcodes.IFGT: ret := Opcodes.IFLE
      | Opcodes.IFLE: ret := Opcodes.IFGT
      | Opcodes.IFICMPEQ: ret := Opcodes.IFICMPNE
      | Opcodes.IFICMPNE: ret := Opcodes.IFICMPEQ
      | Opcodes.IFNULL: ret := Opcodes.IFNONNULL
      | Opcodes.IFNONNULL: ret := Opcodes.IFNULL
      | Opcodes.IFICMPLT: ret := Opcodes.IFICMPGE
      | Opcodes.IFICMPGE: ret := Opcodes.IFICMPLT
      | Opcodes.IFICMPLE: ret := Opcodes.IFICMPGT
      | Opcodes.IFICMPGT: ret := Opcodes.IFICMPLE
    END
    RETURN ret
  END negated;

  PROCEDURE normalize(s: ARRAY OF CHAR; VAR out: ARRAY OF CHAR;
                      i: INTEGER): INTEGER;
    VAR ch: CHAR;
      j, slen, olen: INTEGER;
  BEGIN
    IF i >= 0 THEN
      j := 0;
      slen := LEN(s);
      olen := LEN(out)-1;
      WHILE (j < slen) & (i < olen) & (s[j] # 0X) DO
        ch := s[j];
        IF (ch < "0") OR (ch > "9") & (ch < "A") OR
           (ch > "Z") & (ch < "a") OR (ch > "z") THEN
          ch := "x"
        END ;
        out[i] := ch;
        INC(i);
        INC(j)
      END ;
      out[i] := 0X
    END
    RETURN i
  END normalize;

  PROCEDURE internalNameAt(type: OJB.Type; VAR out: ARRAY OF CHAR;
                           i: INTEGER): INTEGER;
    VAR mod: OJB.Object;
  BEGIN
    IF type.form = OJB.Record THEN
      mod := OJB.GetModFrom(type.typobj);
      i := Strings.Write(mod.name, out, i);
      i := Strings.WriteChar("_", out, i);
      i := Strings.Write(type.typobj.name, out, i)
    ELSIF type.form = OJB.Pointer THEN
      mod := OJB.GetModFrom(type.base.typobj);
      i := Strings.Write(mod.name, out, i);
      i := Strings.WriteChar("_", out, i);
      i := Strings.Write(type.base.typobj.name, out, i)
    ELSIF type.form = OJB.Proc THEN
      i := normalize(type.signature, out, i)
    END
    RETURN i
  END internalNameAt;


  PROCEDURE internalName(type: OJB.Type; VAR out: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    i := internalNameAt(type, out, 0);
    IF (i = -1) THEN OJS.Mark("Maximum descriptor length reached") END
  END internalName;

  PROCEDURE DescriptorR(type: OJB.Type; VAR out: ARRAY OF CHAR;
                        i: INTEGER): INTEGER;
  BEGIN
    IF type = OJB.boolType THEN
      i := Strings.WriteChar("Z", out, i)
    ELSIF (type = OJB.intType) OR (type = OJB.setType) THEN
      i := Strings.WriteChar("I", out, i)
    ELSIF type = OJB.byteType THEN
      i := Strings.WriteChar("B", out, i)
    ELSIF type = OJB.charType THEN
      i := Strings.WriteChar("C", out, i)
    ELSIF type = OJB.realType THEN
      i := Strings.WriteChar("F", out, i)
    ELSIF type = OJB.noType THEN
      i := Strings.WriteChar("V", out, i)
    ELSIF (type.form = OJB.Record) OR (type.form = OJB.Pointer) THEN
      i := Strings.WriteChar("L", out, i);
      i := internalNameAt(type, out, i);
      i := Strings.WriteChar(";", out, i)
    ELSIF type.form = OJB.Array THEN
      i := Strings.WriteChar("[", out, i);
      i := DescriptorR(type.base, out, i)
    ELSIF type.form = OJB.Proc THEN
      i := Strings.WriteChar("L", out, i);
      i := normalize(type.signature, out, i);
      i := Strings.WriteChar(";", out, i)
    END
    RETURN i
  END DescriptorR;

  PROCEDURE DescriptorProc(type: OJB.Type; end: INTEGER;
                           VAR desc: ARRAY OF CHAR);
    VAR args: OJB.Object;
      i, j: INTEGER;
  BEGIN
    i := 0;
    j := 0;
    j := Strings.WriteChar("(", desc, j);
    args := type.dsc;
    WHILE (args # NIL) & (i < end) DO
      IF args.class = OJB.Par THEN
        j := Strings.WriteChar("[", desc, j)
      END ;
      j := DescriptorR(args.type, desc, j);
      args := args.next;
      INC(i)
    END ;
    j := Strings.WriteChar(")", desc, j);
    j := DescriptorR(type.base, desc, j);
    IF j = -1 THEN OJS.Mark("Maximum descriptor length reached") END
  END DescriptorProc;

  PROCEDURE DescriptorAt(type: OJB.Type; VAR desc: ARRAY OF CHAR; i: INTEGER);
    VAR x: INTEGER;
  BEGIN
    x := DescriptorR(type, desc, i);
    IF x = -1 THEN OJS.Mark("Maximum descriptor length reached") END
  END DescriptorAt;

  PROCEDURE Descriptor(type: OJB.Type; VAR desc: ARRAY OF CHAR);
  BEGIN DescriptorAt(type, desc, 0)
  END Descriptor;

  PROCEDURE pushTypedLocal(VAR x: Item);
  BEGIN
    IF (x.type = OJB.intType) OR (x.type = OJB.boolType) OR
       (x.type = OJB.charType) OR (x.type = OJB.setType) OR
       (x.type = OJB.byteType ) THEN
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, x.a)
    ELSIF x.type = OJB.realType THEN
      ClassFormat.putVarInsn(topCtx.m, Opcodes.FLOAD, x.a)
    ELSE
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a)
    END
  END pushTypedLocal;

  PROCEDURE pushTypedArray(type: OJB.Type);
  BEGIN
    IF (type = OJB.intType) OR (type = OJB.setType) THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.IALOAD)
    ELSIF type = OJB.realType THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.FALOAD)
    ELSIF (type = OJB.boolType) OR (type = OJB.byteType) THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.BALOAD)
    ELSIF type = OJB.charType THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.CALOAD)
    ELSE
      ClassFormat.putInsn(topCtx.m, Opcodes.AALOAD)
    END
  END pushTypedArray;

  PROCEDURE storeTypedLocal(VAR x: Item);
  BEGIN
    IF (x.type = OJB.intType) OR (x.type = OJB.boolType) OR
       (x.type = OJB.charType) OR (x.type = OJB.setType) OR
       (x.type = OJB.byteType) THEN
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ISTORE, x.a)
    ELSIF x.type = OJB.realType THEN
      ClassFormat.putVarInsn(topCtx.m, Opcodes.FSTORE, x.a)
    ELSE
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ASTORE, x.a)
    END
  END storeTypedLocal;

  PROCEDURE storeTypedArray(type: OJB.Type);
  BEGIN
    IF (type = OJB.intType) OR (type = OJB.setType) THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.IASTORE)
    ELSIF (type = OJB.boolType) OR (type = OJB.byteType) THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.BASTORE)
    ELSIF type = OJB.charType THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.CASTORE)
    ELSIF type = OJB.realType THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.FASTORE)
    ELSE
      ClassFormat.putInsn(topCtx.m, Opcodes.AASTORE)
    END
  END storeTypedArray;

  PROCEDURE pushConst*(a: INTEGER);
  BEGIN
    IF (a = -1) OR (a >= 0) & (a <= 5) THEN
      CASE a OF
         -1: ClassFormat.putInsn(topCtx.m, Opcodes.ICONSTM1)
        | 0: ClassFormat.putInsn(topCtx.m, Opcodes.ICONST0)
        | 1: ClassFormat.putInsn(topCtx.m, Opcodes.ICONST1)
        | 2: ClassFormat.putInsn(topCtx.m, Opcodes.ICONST2)
        | 3: ClassFormat.putInsn(topCtx.m, Opcodes.ICONST3)
        | 4: ClassFormat.putInsn(topCtx.m, Opcodes.ICONST4)
        | 5: ClassFormat.putInsn(topCtx.m, Opcodes.ICONST5)
      END
    ELSIF (a >= -128) & (a <= 127) THEN
      ClassFormat.putIntInsn(topCtx.m, Opcodes.BIPUSH, a)
    ELSIF (a >= -32768) & (a <= 32767) THEN
      ClassFormat.putIntInsn(topCtx.m, Opcodes.SIPUSH, a)
    ELSE
      ClassFormat.putLdcInsnInt(topCtx.m, ClassFormat.INT, a)
    END
  END pushConst;

  PROCEDURE pushRealConst(a: INTEGER);
    VAR num: REAL;
  BEGIN
    num := SYSTEM.VAL(REAL, a);
    IF num = 0.0 THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.FCONST0)
    ELSIF num = 1.0 THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.FCONST1)
    ELSIF num = 2.0 THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.FCONST2)
    ELSE
      ClassFormat.putLdcInsnInt(topCtx.m, ClassFormat.FLOAT, a)
    END
  END pushRealConst;

  PROCEDURE isPrimitiveType(type: OJB.Type): BOOLEAN;
    RETURN (type = OJB.boolType) OR
           (type = OJB.charType) OR
           (type = OJB.realType) OR
           (type = OJB.setType) OR
           (type = OJB.byteType) OR
           (type = OJB.intType)
  END isPrimitiveType;

  PROCEDURE findMultiArrayDimension(type: OJB.Type;
                                   skipPrimitiveAndPtrArrays: BOOLEAN): INTEGER;
    VAR i: INTEGER; tmp: OJB.Type;
  BEGIN
    i := 1;
    tmp := type.base;
    WHILE tmp.form = OJB.Array DO
      tmp := tmp.base;
      INC(i)
    END ;
    IF skipPrimitiveAndPtrArrays &
       (isPrimitiveType(tmp) OR (tmp.form = OJB.Pointer) OR
        (tmp.form = OJB.Proc)) THEN
      i := 0
    END
    RETURN i
  END findMultiArrayDimension;

  PROCEDURE NewTmpObj(i: INTEGER; root: OJB.Object; type: OJB.Type;
                      size: INTEGER): OJB.Object;
    VAR new: OJB.Object;
  BEGIN
    NEW(new);
    Strings.Append("@tmp", new.name);
    Strings.AppendInt(i, 0, new.name);
    new.class := OJB.Var;
    new.type := type; new.val := size;
    new.next := root;
    RETURN new
  END NewTmpObj;

  PROCEDURE storeRef(x: OJB.Object);
    VAR desc, iname: ClassFormat.Descriptor;
  BEGIN
    IF x.lev = 0 THEN
      Descriptor(x.type, desc);
      IF x.class = OJB.Fld THEN
        internalName(x.recordType, iname);
        ClassFormat.putFieldInsn(topCtx.m, Opcodes.PUTFIELD, iname, x.name,
                                 desc)
      ELSE
        ClassFormat.putFieldInsn(topCtx.m, Opcodes.PUTSTATIC, topCtx.className,
                                 x.name, desc)
      END
    ELSE
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ASTORE, x.val)
    END
  END storeRef;

  PROCEDURE loadRef(x: OJB.Object);
    VAR desc, iname: ClassFormat.Descriptor;
  BEGIN
    IF x.lev = 0 THEN
      Descriptor(x.type, desc);
      IF x.class = OJB.Fld THEN
        internalName(x.recordType, iname);
        ClassFormat.putFieldInsn(topCtx.m, Opcodes.GETFIELD, iname, x.name,
                                 desc)
      ELSE
        ClassFormat.putFieldInsn(topCtx.m, Opcodes.GETSTATIC, topCtx.className,
                                 x.name, desc)
      END
    ELSE
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.val)
    END
  END loadRef;

  PROCEDURE getLocalVars(obj: OJB.Object; end: INTEGER): OJB.Object;
    VAR i: INTEGER;
  BEGIN
    i := 0;
    WHILE (obj # NIL) & (i < end) DO
      obj := obj.next;
      INC(i)
    END
    RETURN obj
  END getLocalVars;

  PROCEDURE createArraysTempVars(topScope: OJB.Object; VAR size: INTEGER;
                                skipPrimitiveAndPtrArrays: BOOLEAN): OJB.Object;
    VAR maxArrayDimension: INTEGER;
      tmp, vars: OJB.Object;
      dim, i: INTEGER;
  BEGIN
    maxArrayDimension := 0;
    tmp := topScope;
    vars := NIL;
    i := 0;
    WHILE tmp # NIL DO
      IF ((tmp.class = OJB.Var) OR (tmp.class = OJB.Fld)) &
         (tmp.type.form = OJB.Array) THEN
        dim := findMultiArrayDimension(tmp.type, skipPrimitiveAndPtrArrays);
        IF dim > maxArrayDimension THEN
          WHILE maxArrayDimension < dim DO
            vars := NewTmpObj(i, vars, OJB.intType, size);
            INC(maxArrayDimension);
            INC(i);
            INC(size)
          END
        END
      END ;
      tmp := tmp.next
    END
    RETURN vars
  END createArraysTempVars;

  PROCEDURE initializeLocalVar(x: OJB.Object);
  BEGIN
    IF (x.type = OJB.intType) OR (x.type = OJB.boolType) OR
       (x.type = OJB.setType) OR (x.type = OJB.byteType) OR
       (x.type = OJB.charType) THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.ICONST0);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ISTORE, x.val)
    ELSIF x.type = OJB.realType THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.FCONST0);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.FSTORE, x.val)
    ELSE  (* x.class = ORB.Pointer *)
      ClassFormat.putInsn(topCtx.m, Opcodes.ACONSTNULL);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ASTORE, x.val)
    END
  END initializeLocalVar;

  PROCEDURE emitPrimitiveNewArray(type: OJB.Type);
  BEGIN
    IF type = OJB.boolType THEN
      ClassFormat.putIntInsn(topCtx.m, Opcodes.NEWARRAY, Opcodes.TBOOLEAN)
    ELSIF type = OJB.charType THEN
      ClassFormat.putIntInsn(topCtx.m, Opcodes.NEWARRAY, Opcodes.TCHAR)
    ELSIF type = OJB.realType THEN
      ClassFormat.putIntInsn(topCtx.m, Opcodes.NEWARRAY, Opcodes.TFLOAT)
    ELSIF type = OJB.byteType THEN
      ClassFormat.putIntInsn(topCtx.m, Opcodes.NEWARRAY, Opcodes.TBYTE)
    ELSIF (type = OJB.intType) OR (type = OJB.setType) THEN
      ClassFormat.putIntInsn(topCtx.m, Opcodes.NEWARRAY, Opcodes.TINT)
    END
  END emitPrimitiveNewArray;

  PROCEDURE getLastArray(type: OJB.Type): OJB.Type;
    VAR last: OJB.Type;
  BEGIN
    last := NIL;
    WHILE type.form = OJB.Array DO
      last := type;
      type := type.base
    END
    RETURN last
  END getLastArray;

  PROCEDURE Fixup*(L: INTEGER);
  BEGIN
    ClassFormat.FixLink(topCtx.m, L)
  END Fixup;

  PROCEDURE pushIndexes(i: INTEGER; tmpVars: OJB.Object): OJB.Object;
    VAR k: INTEGER;
  BEGIN
    k := 0;
    WHILE k # i-1 DO
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, tmpVars.val);
      ClassFormat.putInsn(topCtx.m, Opcodes.AALOAD);
      tmpVars := tmpVars.next;
      INC(k)
    END
    RETURN tmpVars
  END pushIndexes;

  PROCEDURE pushIndexes2(i: INTEGER): INTEGER;
    VAR tmpVars, k: INTEGER;
  BEGIN
    tmpVars := topCtx.numTmpVars - i;
    k := 0;
    WHILE k < i-1 DO
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, tmpVars);
      ClassFormat.putInsn(topCtx.m, Opcodes.AALOAD);
      INC(tmpVars);
      INC(k)
    END
    RETURN tmpVars
  END pushIndexes2;

  PROCEDURE genNew(typeName: ARRAY OF CHAR);
  BEGIN
    ClassFormat.putTypeInsn(topCtx.m, Opcodes.NEW, typeName);
    ClassFormat.putInsn(topCtx.m, Opcodes.DUP);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESPECIAL, typeName,
                              "<init>", "()V", 0)
  END genNew;

  PROCEDURE initializeMultiDimArray(i: INTEGER; x: OJB.Object; type: OJB.Type;
                                    tmpVars, currTmpVar: OJB.Object);
    VAR iname: ClassFormat.Descriptor;
      cond, end: INTEGER;
  BEGIN
    IF type.form = OJB.Array THEN
      pushConst(type.len - 1);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ISTORE, currTmpVar.val);
      cond := topCtx.m.i;
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, currTmpVar.val);
      end := topCtx.m.i;
      ClassFormat.putJumpInsn(topCtx.m, Opcodes.IFLT, 0);
      initializeMultiDimArray(i + 1, x, type.base, tmpVars, currTmpVar.next);
      ClassFormat.putIincInsn(topCtx.m, currTmpVar.val, -1);
      ClassFormat.putGotoInsn(topCtx.m, cond-topCtx.m.i, 0);
      Fixup(end)
    ELSE
      IF x.class = OJB.Fld THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0)
      END ;
      loadRef(x);
      tmpVars := pushIndexes(i, tmpVars);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, tmpVars.val);
      internalName(type, iname);
      genNew(iname);
      ClassFormat.putInsn(topCtx.m, Opcodes.AASTORE)
    END
  END initializeMultiDimArray;

  PROCEDURE initializeRecord(x: OJB.Object);
    VAR iname: ClassFormat.Descriptor;
  BEGIN
    IF x.class = OJB.Fld THEN
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0)
    END ;
    internalName(x.type, iname);
    genNew(iname);
    storeRef(x)
  END initializeRecord;

  PROCEDURE initializeArray(x, tmpVars: OJB.Object);
    VAR
      desc, iname: ClassFormat.Descriptor;
      arrDim, i: INTEGER;
      type, tbase, base, t: OJB.Type;
  BEGIN
    type := x.type;
    arrDim := 1;
    tbase := type.base;
    IF x.class = OJB.Fld THEN
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0)
    END ;
    i := Strings.WriteChar("[", desc, 0);
    pushConst(type.len);
    WHILE (tbase # NIL) & (tbase.form = OJB.Array) DO
      pushConst(tbase.len);
      INC(arrDim);
      i := Strings.WriteChar("[", desc, i);
      tbase := tbase.base
    END ;
    IF (arrDim = 1) & (tbase # NIL) THEN
      IF isPrimitiveType(tbase) THEN
        emitPrimitiveNewArray(tbase);
        storeRef(x)
      ELSE
        internalName(tbase, iname);
        ClassFormat.putTypeInsn(topCtx.m, Opcodes.ANEWARRAY, iname);
        storeRef(x);
        IF (tbase.form # OJB.Pointer) & (tbase.form # OJB.Proc) THEN
          initializeMultiDimArray(0, x, type, tmpVars, tmpVars)
        END
      END
    ELSE
      DescriptorAt(tbase, desc, i);
      ClassFormat.putMultiANewArrayInsn(topCtx.m, desc, arrDim);
      storeRef(x);
      t := getLastArray(x.type);
      base := t.base;
      IF ~isPrimitiveType(base) & (base.form # OJB.Pointer) &
         (base.form # OJB.Proc) THEN
        initializeMultiDimArray(0, x, type, tmpVars, tmpVars)
      END
    END
  END initializeArray;

  PROCEDURE initializeScope(x: OJB.Object; offset: INTEGER);
    VAR type, recordType: OJB.Type;
      num, numTmpVars: INTEGER;
      tempVars: OJB.Object;
  BEGIN
    num := offset;
    (* skipPrimitiveAndPtrArrays = TRUE, as we don't want to create local
       variables to index multi-dimensional primitive/reference arrays as by
       default they are already initialized by MULTIANEWARRAY *)
    tempVars := createArraysTempVars(x, num, TRUE);
    numTmpVars := num;
    IF x # NIL THEN
      recordType := x.recordType;
      WHILE (x # NIL) & (recordType = x.recordType) DO
        IF (x.class = OJB.Var) OR (x.class = OJB.Fld) THEN
          type := x.type;
          IF type.form = OJB.Record THEN
            initializeRecord(x)
          ELSIF type.form = OJB.Array THEN
            initializeArray(x, tempVars)
          ELSIF x.lev > 0 THEN
            initializeLocalVar(x)
          END
        END ;
        x := x.next
      END
    END ;
    topCtx.numTmpVars := numTmpVars
  END initializeScope;

  PROCEDURE Constructor(obj: OJB.Object);
    VAR baseName: ClassFormat.Descriptor;
      tmp: OJB.Object;
  BEGIN
    topCtx.m := ClassFormat.NewMI(topCtx.c, Opcodes.ACCxPUBLIC, "<init>",
                                  "()V");
    clearCtx(topCtx);
    ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0);
    Strings.Append("java/lang/Object", baseName);
    tmp := NIL;
    IF obj # NIL THEN
      tmp := obj.type.dsc;
      IF obj.type.base # NIL THEN
        internalName(obj.type.base, baseName)
      END
    END ;
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESPECIAL, baseName,
                              "<init>", "()V", 0);
    initializeScope(tmp, 1);
    ClassFormat.putInsn(topCtx.m, Opcodes.RETURNx);
    ClassFormat.setMaxVars(topCtx.m, topCtx.numTmpVars);
    closeContext
  END Constructor;

  PROCEDURE emitTypedReturn(type: OJB.Type);
  BEGIN
    IF (type = OJB.intType) OR (type = OJB.boolType) OR
       (type = OJB.charType) OR (type = OJB.setType) OR
       (type = OJB.byteType) THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.IRETURN)
    ELSIF type = OJB.realType THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.FRETURN)
    ELSE
      ClassFormat.putInsn(topCtx.m, Opcodes.ARETURN)
    END
  END emitTypedReturn;

  PROCEDURE InvokeMethod(signature: ARRAY OF CHAR; procType: OJB.Type;
                         qualifierModName, procName: ARRAY OF CHAR;
                         impl: BOOLEAN);
    VAR access, i: INTEGER; par: OJB.Object;
      tmp: Item;
  BEGIN
    access := Opcodes.ACCxPUBLIC;
    IF ~impl THEN INC(access, Opcodes.ACCxABSTRACT) END ;
    topCtx.m := ClassFormat.NewMI(topCtx.c, access, "invoke", signature);
    clearCtx(topCtx);
    IF impl THEN
      par := procType.dsc;
      FOR i := 1 TO procType.nofpar DO
        IF par.class = OJB.Par THEN
          (* it's a VAR parameter, force pushTypedLocal() to generate an
             ALOAD *)
          tmp.type := OJB.nilType
        ELSE
          tmp.type := par.type
        END ;
        tmp.a := i;
        pushTypedLocal(tmp);
        par := par.next
      END ;
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC,
                                qualifierModName, procName, signature,
                                procType.nofpar);
      IF procType.base.form # OJB.NoTyp THEN
        emitTypedReturn(procType.base)
      ELSE ClassFormat.putInsn(topCtx.m, Opcodes.RETURNx)
      END ;
      ClassFormat.setMaxVars(topCtx.m, procType.nofpar+1) (* +1 is this *)
    END ;
    closeContext
  END InvokeMethod;

  PROCEDURE genClassFilePath(name: ARRAY OF CHAR; VAR path: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    i := OJB.getOutputFolder(path);
    i := Strings.Write(Files.SEPARATOR, path, i);
    i := Strings.Write(name, path, i);
    i := Strings.Write(".class", path, i);
    IF i = -1 THEN OJS.Mark("Maximum file path length reached") END
  END genClassFilePath;

  PROCEDURE MakeProcType*(type: OJB.Type);
    VAR typeName: ClassFormat.Descriptor;
      path: ARRAY OJS.maxPath OF CHAR;
      newCtx: ClassContext;
  BEGIN
    internalName(type, typeName);
    genClassFilePath(typeName, path);
    IF ~Files.Exists(path) THEN
      NEW(newCtx);
      Strings.Copy(typeName, newCtx.className);
      newCtx.next := topCtx;
      topCtx := newCtx;
      newCtx.c := ClassFormat.NewCF(Opcodes.ACCxPUBLIC + Opcodes.ACCxABSTRACT,
                                    topCtx.className, "java/lang/Object");
      Constructor(NIL);
      InvokeMethod(type.signature, NIL, "", "", FALSE);
      genClassFilePath(topCtx.className, path);
      ClassFormat.toFile(topCtx.c, path);
      topCtx := topCtx.next
    END
  END MakeProcType;

  PROCEDURE joinNames(VAR s0, s1: ARRAY OF CHAR; VAR out: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    i := Strings.Write(s0, out, 0);
    i := Strings.WriteChar("_", out, i);
    i := Strings.Write(s1, out, i);
    IF i = -1 THEN OJS.Mark("Maximum descriptor length reached") END
  END joinNames;

  PROCEDURE makeRefDesc(VAR s, desc: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    i := Strings.WriteChar("L", desc, 0);
    i := Strings.Write(s, desc, i);
    i := Strings.WriteChar(";", desc, i);
    IF i = -1 THEN OJS.Mark("Maximum descriptor length reached") END
  END makeRefDesc;

  PROCEDURE ConstructorProcInstance(signature: OJB.Type);
    VAR iname: ClassFormat.Descriptor;
  BEGIN
    topCtx.m := ClassFormat.NewMI(topCtx.c, Opcodes.ACCxPRIVATE, "<init>",
                                  "()V");
    clearCtx(topCtx);
    ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0);
    internalName(signature, iname);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESPECIAL, iname, "<init>",
                              "()V", 0);
    ClassFormat.putInsn(topCtx.m, Opcodes.RETURNx);
    ClassFormat.setMaxVars(topCtx.m, 1);
    closeContext
  END ConstructorProcInstance;

  PROCEDURE InitProcInstance(VAR typeName: ARRAY OF CHAR);
    VAR desc: ClassFormat.Descriptor;
  BEGIN
    topCtx.m := ClassFormat.NewMI(topCtx.c, Opcodes.ACCxSTATIC, "<clinit>",
                                  "()V");
    clearCtx(topCtx);
    genNew(typeName);
    makeRefDesc(typeName, desc);
    ClassFormat.putFieldInsn(topCtx.m, Opcodes.PUTSTATIC, typeName, "INSTANCE",
                             desc);
    ClassFormat.putInsn(topCtx.m, Opcodes.RETURNx);
    ClassFormat.setMaxVars(topCtx.m, topCtx.numTmpVars);
    closeContext
  END InitProcInstance;

  PROCEDURE MakeProcInstance(VAR x: Item);
    VAR
      path: ARRAY OJS.maxPath OF CHAR;
      iname, instanceName:ClassFormat.Descriptor;
      procType: OJB.Type;
      newCtx: ClassContext;
      access: INTEGER;
  BEGIN
    procType := x.type;
    MakeProcType(procType);
    joinNames(x.modName, x.name, instanceName);
    genClassFilePath(instanceName, path);
    IF ~Files.Exists(path) THEN
      NEW(newCtx);
      access := Opcodes.ACCxPUBLIC + Opcodes.ACCxSUPER + Opcodes.ACCxFINAL;
      joinNames(x.modName, x.name, newCtx.className);
      newCtx.next := topCtx;
      topCtx := newCtx;
      internalName(procType, iname);
      newCtx.c := ClassFormat.NewCF(access, topCtx.className, iname);
      makeRefDesc(topCtx.className, iname);
      ClassFormat.addField(topCtx.c, Opcodes.ACCxPUBLIC + Opcodes.ACCxSTATIC,
                           "INSTANCE", iname);
      ConstructorProcInstance(procType);
      InvokeMethod(procType.signature, procType, x.modName, x.name, TRUE);
      InitProcInstance(topCtx.className);
      genClassFilePath(topCtx.className, path);
      ClassFormat.toFile(topCtx.c, path);
      topCtx := topCtx.next
    END
  END MakeProcInstance;

  PROCEDURE load(VAR x: Item);
    VAR
      L0, L1: INTEGER;
      xt: OJB.Type;
      desc, procType: ClassFormat.Descriptor;
      s: ARRAY OJS.stringBufSize OF CHAR;
  BEGIN
    IF x.mode # Stack THEN
      IF x.oldType # NIL THEN
        xt := x.oldType
      ELSE
        xt := x.type
      END ;
      IF (x.mode = OJB.Var) OR (x.mode = OJB.ParStruct) THEN
        IF x.r > 0 THEN
          (*local*)
          pushTypedLocal(x)
        ELSE
          Descriptor(xt, desc);
          ClassFormat.putFieldInsn(topCtx.m, Opcodes.GETSTATIC, x.modName,
                                   x.name, desc)
        END
      ELSIF x.mode = OJB.Par THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
        pushConst(0);
        pushTypedArray(xt)
      ELSIF  x.mode = OJB.Const THEN
        IF xt = OJB.realType THEN
          pushRealConst(x.a)
        ELSIF xt = OJB.nilType THEN
          ClassFormat.putInsn(topCtx.m, Opcodes.ACONSTNULL);
        ELSIF xt = OJB.strType THEN
          OJS.ExtractStr(x.a, x.b, s);
          ClassFormat.putLdcInsnStr(topCtx.m, s, TRUE)
        ELSIF xt.form = OJB.Proc THEN
          MakeProcInstance(x);
          joinNames(x.modName, x.name, procType);
          makeRefDesc(procType, desc);
          ClassFormat.putFieldInsn(topCtx.m, Opcodes.GETSTATIC, procType,
                                   "INSTANCE", desc)
        ELSE
          pushConst(x.a)
        END
      ELSIF x.mode = RegI THEN
        pushTypedArray(xt)
      ELSIF x.mode = Field THEN
        Descriptor(xt, desc);
        ClassFormat.putFieldInsn(topCtx.m, Opcodes.GETFIELD, x.recordName,
                                 x.name, desc)
      ELSIF x.mode = Cond THEN
        L0 := topCtx.m.i;
        ClassFormat.putJumpInsn(topCtx.m, negated(x.r), 0);
        ClassFormat.FixLink(topCtx.m, x.b);
        ClassFormat.putInsn(topCtx.m, Opcodes.ICONST1);
        L1 := topCtx.m.i;
        ClassFormat.putGotoInsn(topCtx.m, 0, -1);
        ClassFormat.FixLink(topCtx.m, x.a);
        Fixup(L0);
        ClassFormat.putInsn(topCtx.m, Opcodes.ICONST0);
        Fixup(L1)
      END ;
      x.mode := Stack;
      IF x.oldType # NIL THEN
        x.oldType := NIL;
        internalName(x.type, desc);
        ClassFormat.putTypeInsn(topCtx.m, Opcodes.CHECKCAST, desc)
      END ;
      IF x.type = OJB.byteType THEN
        pushConst(255);
        ClassFormat.putInsn(topCtx.m, Opcodes.IAND)
      END
    END
  END load;

  PROCEDURE TypeTest*(VAR x: Item; T: OJB.Type; isguard: BOOLEAN);
    VAR iname: ClassFormat.Descriptor;
  BEGIN
    IF isguard THEN
      IF x.oldType = NIL THEN x.oldType := x.type END
    ELSE
      load(x);
      internalName(T, iname);
      ClassFormat.putTypeInsn(topCtx.m, Opcodes.INSTANCEOF, iname)
    END
  END TypeTest;

  PROCEDURE loadCond(VAR x: Item);
  BEGIN
   IF x.type.form = OJB.Bool THEN
     load(x); x.r := Opcodes.IFNE;
     x.mode := Cond; x.a := 0; x.b := 0;
   ELSE OJS.Mark("not Boolean") END
  END loadCond;

  PROCEDURE getPC*(): INTEGER;
    RETURN topCtx.m.i
  END getPC;

  PROCEDURE CFJump*(VAR x: Item);  (*conditional forward jump*)
    VAR L0: INTEGER;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    L0 := topCtx.m.i;
    ClassFormat.putJumpInsn(topCtx.m, negated(x.r), x.a);
    ClassFormat.FixLink(topCtx.m, x.b); x.a := L0
  END CFJump;

  PROCEDURE FJump*(L: INTEGER): INTEGER;   (*unconditional forward jump*)
    VAR L0: INTEGER;
  BEGIN
    L0 := topCtx.m.i;
    ClassFormat.putGotoInsn(topCtx.m, L, 0);
    RETURN L0
  END FJump;

  PROCEDURE CBJump*(VAR x: Item; L: INTEGER);   (*conditional backward jump*)
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    ClassFormat.putJumpInsn(topCtx.m, negated(x.r), L-topCtx.m.i);
    ClassFormat.FixLink(topCtx.m, x.b);
    ClassFormat.FixLinkWith(topCtx.m, x.a, L)
  END CBJump;

  PROCEDURE BJump*(L: INTEGER);   (*unconditional backward jump*)
  BEGIN
    ClassFormat.putGotoInsn(topCtx.m, L-topCtx.m.i, 0)
  END BJump;

  PROCEDURE genSignature*(type: OJB.Type);
  BEGIN DescriptorProc(type, type.nofpar, type.signature)
  END genSignature;

  PROCEDURE MakeConstItem*(VAR x: Item; typ: OJB.Type; val: INTEGER);
  BEGIN
    x.mode := OJB.Const; x.type := typ; x.a := val; x.rdo := TRUE
  END MakeConstItem;

  PROCEDURE MakeRealItem*(VAR x: Item; val: REAL);
  BEGIN
    x.mode := OJB.Const; x.type := OJB.realType;
    x.a := SYSTEM.VAL(INTEGER, val); x.rdo := TRUE
  END MakeRealItem;

  PROCEDURE MakeStringItem*(VAR x: Item);
  BEGIN
    x.mode := OJB.Const; x.type := OJB.strType;
    x.a := OJS.strpos; x.b := OJS.slen; x.rdo := TRUE;
  END MakeStringItem;

  PROCEDURE MakeItem*(VAR x: Item; y: OJB.Object);
  BEGIN
    x.mode := y.class; x.type := y.type; x.a := y.val;  x.rdo := y.rdo;
    Strings.Copy(y.name, x.name);
    x.oldType := y.caseOrgType;
    IF (y.class = OJB.Const) & (y.type.form = OJB.String) THEN
      x.b := y.len
    END ;
    x.r := y.lev
  END MakeItem;

  PROCEDURE Pop(x: Item);
  BEGIN
    IF x.mode IN {Stack, Field} THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.POP)
    ELSIF x.mode = RegI THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.POP2)
    END
  END Pop;

  PROCEDURE ConstTypeTest*(VAR x: Item);
  BEGIN
    IF x.mode IN {OJB.Var, OJB.Par, OJB.ParStruct, Field, Stack, RegI} THEN
      Pop(x);
      MakeConstItem(x, OJB.boolType, 1)
    ELSE OJS.Mark("Unexpected internal mode")
    END
  END ConstTypeTest;

  PROCEDURE FieldAccess*(VAR x: Item; y: OJB.Object);   (* x := x.y *)
  BEGIN
    load(x);
    x.mode := Field;
    internalName(x.type, x.recordName);
    Strings.Copy(y.name, x.name)
  END FieldAccess;

  PROCEDURE Index0*(VAR x: Item);
  BEGIN
    load(x)
  END Index0;

  PROCEDURE Index*(VAR x, y: Item);   (* x := x[y] *)
  BEGIN
    IF (y.mode = OJB.Const) & (x.type.len >= 0) THEN
      IF (y.a < 0) OR (y.a >= x.type.len) THEN OJS.Mark("bad index") END
    END ;
    load(y);
    x.mode := RegI
  END Index;

  PROCEDURE Not*(VAR x: Item);   (* x := ~x *)
    VAR t: INTEGER;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    x.r := negated(x.r); t := x.a; x.a := x.b; x.b := t
  END Not;

  PROCEDURE And1*(VAR x: Item);   (* x := x & *)
    VAR L0: INTEGER;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    L0 := topCtx.m.i;
    ClassFormat.putJumpInsn(topCtx.m, negated(x.r), x.a);
    x.a := L0; ClassFormat.FixLink(topCtx.m, x.b);
    x.b := 0
  END And1;

  PROCEDURE And2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := ClassFormat.merged(topCtx.m, y.a, x.a); x.b := y.b; x.r := y.r
  END And2;

  PROCEDURE Or1*(VAR x: Item);   (* x := x OR *)
    VAR L0: INTEGER;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    L0 := topCtx.m.i;
    ClassFormat.putJumpInsn(topCtx.m, x.r, x.b);
    x.b := L0; ClassFormat.FixLink(topCtx.m, x.a);
    x.a := 0
  END Or1;

  PROCEDURE Or2*(VAR x, y: Item);
  BEGIN
    IF y.mode # Cond THEN loadCond(y) END ;
    x.a := y.a; x.b := ClassFormat.merged(topCtx.m, y.b, x.b); x.r := y.r
  END Or2;

  PROCEDURE loadAndMaybeSwap(VAR x, y: Item);
  BEGIN
    IF (x.mode = OJB.Const) & (y.mode # OJB.Const) THEN
      (*x loading has been delayed, so fully load y and restore the order
        (SWAP)*)
      load(y);
      load(x);
      ClassFormat.putInsn(topCtx.m, Opcodes.SWAP)
    ELSE load(x); load(y)
    END
  END loadAndMaybeSwap;

  PROCEDURE Neg*(VAR x: Item);   (* x := -x *)
  BEGIN
    IF x.type.form = OJB.Int THEN
      IF x.mode = OJB.Const THEN x.a := -x.a
      ELSE load(x); ClassFormat.putInsn(topCtx.m, Opcodes.INEG)
      END
    ELSIF x.type.form = OJB.Real THEN
      IF x.mode = OJB.Const THEN
        x.a := SYSTEM.VAL(INTEGER, -SYSTEM.VAL(REAL, x.a));
      ELSE load(x); ClassFormat.putInsn(topCtx.m, Opcodes.FNEG)
      END
    ELSE (*form := Set*)
      (* The sign of a two’s complement number is reversed in a process called
         taking the two’s complement:
          Ex. 8 := 00001000 -> -8 := oneComplement(8) + 1
                := 11110111 + 1 := 11111000
        So if I only need the oneComplement I subtract 1 to the two's
        complement:
          Ex.  -8 := oneComplement(8) + 1 ->  -8 - 1 := oneComplement(8)
      *)
      IF x.mode = OJB.Const THEN x.a := -x.a-1
      ELSE  (* there is no Not instruction in JVM *)
        load(x);
        pushConst(-1);
        ClassFormat.putInsn(topCtx.m, Opcodes.IXOR)
      END
    END
  END Neg;

  PROCEDURE AddOp*(op: INTEGER; VAR x, y: Item);   (* x := x +- y *)
  BEGIN
    IF op = OJS.plus THEN
      IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN x.a := x.a + y.a
      ELSIF x.mode = OJB.Const THEN
        load(y);
        IF x.a # 0 THEN
          load(x);
          ClassFormat.putInsn(topCtx.m, Opcodes.IADD)
        ELSE x.mode := Stack
        END
      ELSIF y.mode = OJB.Const THEN
        load(x);
        IF y.a # 0 THEN
          load(y); ClassFormat.putInsn(topCtx.m, Opcodes.IADD)
        END ;
      ELSE load(x); load(y); ClassFormat.putInsn(topCtx.m, Opcodes.IADD)
      END
    ELSE (*op = ORS.minus*)
      IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN x.a := x.a - y.a
      ELSIF y.mode = OJB.Const THEN
        load(x);
        IF y.a # 0 THEN load(y); ClassFormat.putInsn(topCtx.m, Opcodes.ISUB) END
      ELSE loadAndMaybeSwap(x, y); ClassFormat.putInsn(topCtx.m, Opcodes.ISUB)
      END
    END
  END AddOp;

  (*
    The log2(x) is the number of bits needed to represent the value of a
    positive x. As The result is a real number
    we actually compute the ceiling(log2(x)).
    Ex. log2(5) = 2.32 -> ceiling(2.32) = 3 in fact 5 is 101 in binary
    This means that to implement log2(x) we count how many bits we have until
    we reach the Most Significant Bit.
    So we basically shift x by one in a loop until x = 1 i.e. the
    MSB ( while(x # 1) { x = x >> 1; res++;} ceiling(res);)

    Here however, we are interested in the log2(x) where x is a power of 2.
    ex. 2^3 = 1000 = 1 * 2^3 + 0 * 2^2 + 0 * 2^1 + 0 * 2^0
    All the power of 2 have the MSB set to 1 and the rest of the bits set to 0.
    So we can stop the loop when we find the first 1 and check at the call site
    (log2(x) = 1) to know if x is indeed a power of 2.
    Also remember that log2(2^k) = k = ceiling(k) as there is no fractional
    part.
  *)

  PROCEDURE log2(m: INTEGER; VAR e: INTEGER): INTEGER;
  BEGIN e := 0;
    WHILE ~ODD(m) DO m := m DIV 2; INC(e) END ;
    RETURN m
  END log2;

  PROCEDURE MulOp*(VAR x, y: Item);   (* x := x * y *)
    VAR e: INTEGER;
  BEGIN
    IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN  x.a := x.a * y.a
    ELSIF (y.mode = OJB.Const) & (y.a >= 2) & (log2(y.a, e) = 1) THEN
      load(x); pushConst(e);
      ClassFormat.putInsn(topCtx.m, Opcodes.ISHL)
    ELSIF x.mode = OJB.Const THEN
      load(y);
      IF (x.a >= 2) & (log2(x.a, e) = 1) THEN
        pushConst(e);
        ClassFormat.putInsn(topCtx.m, Opcodes.ISHL);
      ELSIF x.a # 0 THEN
        load(x);
        ClassFormat.putInsn(topCtx.m, Opcodes.IMUL)
      END ;
      x.mode := Stack
    ELSE load(x); load(y); ClassFormat.putInsn(topCtx.m, Opcodes.IMUL)
    END
  END MulOp;

  (*
    Delayed code generation is used to implement constant folding
    Given VAR i,j : INTEGER; a : ARRAY 10 OF INTEGER;
      i := 2 + a[1+3];
    will be compiled as i := a[4] + 2:
      GETSTATIC A.a : [I
      ICONST_4
      IALOAD
      ICONST_2
      IADD
      PUTSTATIC A.i : I
    We delay the code generation for the first operands of both additions.
    In the first addition 2 will be emitted after the evaluation of a[1+3] as
    at that point is clear that no constant folding is possible between 2 and a.
    In the second addition we delay the emission of 1 as it could be folded as
    indeed happens as the second operand is the constant 3.
    The statement
      i := 2 - a[j+3];
    Will be compiled as i = 2 - a[j + 3];
      GETSTATIC A.a : [I
      GETSTATIC A.j : I
      ICONST_3
      IADD
      IALOAD
      ICONST_2
      SWAP
      ISUB
      PUTSTATIC A.i : I
    Notice the presence of an extra SWAP. Because 2 is emitted after evaluating
    a[j+3] and because - is not commutative we need to swap the argument of the
    ISUB instruction.
  *)

  PROCEDURE loadOp*(VAR x: Item);
  BEGIN
    IF x.mode # OJB.Const THEN
      load(x)
    END
  END loadOp;

  PROCEDURE SetLineNumber*(line: INTEGER);
  BEGIN
    ClassFormat.addLineNumber(topCtx.m, line)
  END SetLineNumber;

  PROCEDURE Trap(msg: ARRAY OF CHAR);
  BEGIN
    ClassFormat.putTypeInsn(topCtx.m, Opcodes.NEW,
                            "java/lang/RuntimeException");
    ClassFormat.putInsn(topCtx.m, Opcodes.DUP);
    ClassFormat.putLdcInsnStr(topCtx.m, msg, FALSE);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESPECIAL,
                              "java/lang/RuntimeException", "<init>",
                              "(Ljava/lang/String;)V", 1);
    ClassFormat.putInsn(topCtx.m, Opcodes.ATHROW)
  END Trap;

  PROCEDURE TrapWithCond(cond: INTEGER; msg: ARRAY OF CHAR);
    VAR L: INTEGER;
  BEGIN
    ClassFormat.putInsn(topCtx.m, Opcodes.DUP);
    L := topCtx.m.i;
    ClassFormat.putJumpInsn(topCtx.m, negated(cond), 0);
    Trap(msg);
    Fixup(L)
  END TrapWithCond;

  PROCEDURE DivOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
    VAR e: INTEGER; skip: BOOLEAN;
  BEGIN
    skip := FALSE;
    IF op = OJS.div THEN
      IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
        (* Euclidean division, use y.a > 0 for Floored division *)
        IF y.a # 0 THEN
          x.a := x.a DIV y.a
        ELSE
          OJS.Mark("bad divisor")
        END
      ELSIF (y.mode = OJB.Const) & (y.a >= 2) & (log2(y.a, e) = 1) THEN
        load(x); pushConst(e);
        ClassFormat.putInsn(topCtx.m, Opcodes.ISHR)
      ELSE
        (* Euclidean division, use y.a <= 0 for Floored division *)
        IF y.mode = OJB.Const THEN
          IF y.a = 0 THEN OJS.Mark("bad divisor")
          ELSIF y.a > 0 THEN skip := TRUE END
        END ;
        loadAndMaybeSwap(x, y);
        (* Euclidean division, use Opcodes.IFLE for Floored division *)
        IF check & ~skip THEN TrapWithCond(Opcodes.IFEQ, "bad divisor") END ;
        ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC,
                                  "OberonRuntime", "DIV", "(II)I", 2)
      END
    ELSE (*op := ORS.mod*)
      IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
        (* Euclidean division, use y.a > 0 for Floored division *)
        IF y.a # 0 THEN
          x.a := x.a MOD y.a
        ELSE
          OJS.Mark("bad modulus")
        END
      ELSIF (y.mode = OJB.Const) & (y.a >= 2) & (log2(y.a, e) = 1) THEN
        load(x); pushConst(y.a-1);
        ClassFormat.putInsn(topCtx.m, Opcodes.IAND)
      ELSE
        (* Euclidean division, use y.a <= 0 for Floored division *)
        IF (y.mode = OJB.Const) & (y.a = 0) THEN OJS.Mark("bad modulus")
        ELSE skip := TRUE END ;
        loadAndMaybeSwap(x, y);
        (* Euclidean division, use Opcodes.IFLE for Floored division *)
        IF check & ~skip THEN TrapWithCond(Opcodes.IFEQ, "bad modulus") END ;
        ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC,
                                  "OberonRuntime", "MOD", "(II)I", 2)
      END
    END
  END DivOp;

  (* Code generation for REAL operators *)

  PROCEDURE RealOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
  BEGIN
    IF op = OJS.plus THEN
      IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
        x.a := SYSTEM.VAL(INTEGER, SYSTEM.VAL(REAL, x.a) +SYSTEM.VAL(REAL, y.a))
      ELSE
        loadAndMaybeSwap(x, y); ClassFormat.putInsn(topCtx.m, Opcodes.FADD)
      END ;
    ELSIF op = OJS.minus THEN
      IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
        x.a := SYSTEM.VAL(INTEGER, SYSTEM.VAL(REAL, x.a) -SYSTEM.VAL(REAL, y.a))
      ELSE
        loadAndMaybeSwap(x, y); ClassFormat.putInsn(topCtx.m, Opcodes.FSUB)
      END ;
    ELSIF op = OJS.times THEN
      IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
        x.a := SYSTEM.VAL(INTEGER, SYSTEM.VAL(REAL, x.a) *SYSTEM.VAL(REAL, y.a))
      ELSE
        loadAndMaybeSwap(x, y); ClassFormat.putInsn(topCtx.m, Opcodes.FMUL)
      END ;
    ELSE (* op = ORS.rdiv *)
      IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
        x.a := SYSTEM.VAL(INTEGER, SYSTEM.VAL(REAL, x.a) /SYSTEM.VAL(REAL, y.a))
      ELSE
        loadAndMaybeSwap(x, y); ClassFormat.putInsn(topCtx.m, Opcodes.FDIV)
      END ;
    END
  END RealOp;

  (* Code generation for set operators *)

  PROCEDURE Singleton*(VAR x: Item);  (* x := {x} *)
  BEGIN
    IF x.mode = OJB.Const THEN x.a := LSL(1, x.a)
    ELSIF x.mode # OJB.Var THEN
      load(x);
      pushConst(1);
      ClassFormat.putInsn(topCtx.m, Opcodes.SWAP);
      ClassFormat.putInsn(topCtx.m, Opcodes.ISHL)
    ELSE pushConst(1); load(x); ClassFormat.putInsn(topCtx.m, Opcodes.ISHL)
    END
  END Singleton;

  (*
     Example s := {3..5}

      -1 = 11111111111111111111111111111111
      -2 = 11111111111111111111111111111110
      LSL(-1, 3) = 11111111111111111111111111111000
      LSL(-2, 5) = 11111111111111111111111111000000
      LSL(-1, 3) - LSL(-2, 5)
        = 11111111111111111111111111111000 - 11111111111111111111111111000000
        = 11111111111111111111111111111000 + 00000000000000000000000000111111
          + 1 (two's complement)
        = 11111111111111111111111111111001 + 00000000000000000000000000111111
        = 00000000000000000000000000111000
        = 56
      LSL(2, 5) - LSL(1, 3)
        = 00000000000000000000000001000000 - 00000000000000000000000000001000
        = 00000000000000000000000001000000 + 11111111111111111111111111110111
          + 1 (two's complement)
        = 00000000000000000000000001000001 + 11111111111111111111111111110111
        = 00000000000000000000000000111000
        = 56


        = LSL(-1, 3) &  ~LSL(-2, 5)
        = 11111111111111111111111111111000 & 00000000000000000000000000111111

        = (LSL(-2, 5) xor -1) & LSL(-1, 3)    // where LSL(-1, 3) is computed
                                              // at compile time
        = ~LSL(-2, 5) & LSL(-1, 3)  // there is no Not institution in RISC


   *)

  PROCEDURE Set0*(VAR x: Item);   (* x := {x .. y} *)
  BEGIN
    (* delay generation if x is constant, handle it in Set1 *)
    IF x.mode # OJB.Const THEN
      IF x.mode # OJB.Var THEN
        load(x);
        pushConst(-1);
        ClassFormat.putInsn(topCtx.m, Opcodes.SWAP);
        ClassFormat.putInsn(topCtx.m, Opcodes.ISHL)
      ELSE pushConst(-1); load(x); ClassFormat.putInsn(topCtx.m, Opcodes.ISHL)
      END
    END
  END Set0;

  PROCEDURE Set1*(VAR x, y: Item);   (* x := {x .. y} *)
  BEGIN
    IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
      IF x.a <= y.a THEN  x.a := LSL(-1, x.a) - LSL(-2, y.a) ELSE x.a := 0 END
    ELSE
      IF y.mode = OJB.Const THEN
        pushConst(LSL(-2, y.a)); y.mode := Stack
      ELSIF y.mode # OJB.Var THEN
        load(y);
        pushConst(-2);
        ClassFormat.putInsn(topCtx.m, Opcodes.SWAP);
        ClassFormat.putInsn(topCtx.m, Opcodes.ISHL)
      ELSE pushConst(-2); load(y); ClassFormat.putInsn(topCtx.m, Opcodes.ISHL)
      END ;
      IF x.mode = OJB.Const THEN
        pushConst(LSL(-1, x.a)); x.mode := Stack;
        ClassFormat.putInsn(topCtx.m, Opcodes.SWAP)
      END ;
      ClassFormat.putInsn(topCtx.m, Opcodes.ISUB);
    END
  END Set1;

  (*
     Example

     s := 4 in {3..5}

     {3..5}  = 56 =  00000000000000000000000000111000
     4 = 100
     We add 1 as our set is 0 based
     4 + 1 = 5 = 101

     ROR(56, 5) = 11000000000000000000000000000001
                -> as the most significant bit is set to 1 this number is
                   negative so it means that 4 is indeed in {3..5}

     Alternately as in the JVM ROR will be implemented with too many
     instructions (i.e. (x >>> n) | (x << -n) )

     LSL(1, 4) =          00000000000000000000000000010000
     LSL(1, 4) & {3..5} = 00000000000000000000000000010000 &
                          00000000000000000000000000111000
                        = 00000000000000000000000000010000
                        -> the result is not 0 so it means that 4 is
                           indeed in {3..5}

     x IN y
     If x is not in the implementation defined SET range {0..MaxSetElement-1}
     the IN operator is undefined
  *)

  PROCEDURE In0*(VAR x: Item);   (* x := x IN y *)
  BEGIN
    IF x.mode = OJB.Const THEN
      x.a := LSL(1, x.a);
      load(x)
    ELSE
      load(x);
      pushConst(1);
      ClassFormat.putInsn(topCtx.m, Opcodes.SWAP);
      ClassFormat.putInsn(topCtx.m, Opcodes.ISHL)
    END ;
    SetCC(x, Opcodes.IFNE)
  END In0;

  PROCEDURE In1*(VAR x: Item);   (* x := x IN y *)
  BEGIN
    load(x);
    ClassFormat.putInsn(topCtx.m, Opcodes.IAND)
  END In1;

  (* See "SET: A neglected data type, and its compilation for the ARM" *)
  PROCEDURE SetOp*(op: INTEGER; VAR x, y: Item);   (* x := x op y *)
    VAR xset, yset: SET;   (*x.type.form = Set*)
  BEGIN
    IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
      xset := SYSTEM.VAL(SET, x.a); yset := SYSTEM.VAL(SET, y.a);
      IF op = OJS.plus THEN xset := xset + yset
      ELSIF op = OJS.minus THEN xset := xset - yset
      ELSIF op = OJS.times THEN xset := xset * yset
      ELSIF op = OJS.rdiv THEN xset := xset / yset
      END ;
      x.a := SYSTEM.VAL(INTEGER, xset)
    ELSE
      loadAndMaybeSwap(x, y);
      IF op = OJS.plus THEN ClassFormat.putInsn(topCtx.m, Opcodes.IOR)
      ELSIF op = OJS.minus THEN
        (*ANN*)
        pushConst(-1);
        ClassFormat.putInsn(topCtx.m, Opcodes.IXOR);
        ClassFormat.putInsn(topCtx.m, Opcodes.IAND)
      ELSIF op = OJS.times THEN ClassFormat.putInsn(topCtx.m, Opcodes.IAND)
      ELSIF op = OJS.rdiv THEN ClassFormat.putInsn(topCtx.m, Opcodes.IXOR)
      END
    END
  END SetOp;

  (* Code generation for relations *)

  PROCEDURE IntRelation*(op: INTEGER; VAR x, y: Item);    (* x := x < y *)
  BEGIN
    IF (y.mode = OJB.Const) & (y.type.form # OJB.Proc) & (y.a = 0) THEN
      load(x);
      IF y.type.form = OJB.NilTyp THEN
        SetCC(x, relmapNil[op - OJS.eql])
      ELSE
        SetCC(x, relmap0[op - OJS.eql])
      END
    ELSE
      loadAndMaybeSwap(x, y);
      IF (x.type.form = OJB.Pointer) OR (x.type.form = OJB.Proc) OR
         (x.type.form = OJB.NilTyp) THEN
        SetCC(x, relmapAdr[op - OJS.eql])
      ELSE
        SetCC(x, relmap[op - OJS.eql])
      END
    END
  END IntRelation;

  PROCEDURE RealRelation*(op: INTEGER; VAR x, y: Item);    (* x := x < y *)
  BEGIN
    loadAndMaybeSwap(x, y);
    IF (op = OJS.lss) OR (op = OJS.leq) THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.FCMPG)
    ELSE
      ClassFormat.putInsn(topCtx.m, Opcodes.FCMPL)
    END ;
    SetCC(x, relmap0[op - OJS.eql])
  END RealRelation;

  PROCEDURE StrToChar*(VAR x: Item);
  BEGIN
    x.type := OJB.charType; x.a := ORD(OJS.ExtractChar(x.a))
  END StrToChar;

  PROCEDURE CharToStr*(VAR x: Item);
    VAR c: CHAR;
  BEGIN
    c := CHR(x.a);
    x.mode := OJB.Const; x.type := OJB.strType; x.a := OJS.InsertChar(c);
    x.b := 2; (* 1 char + 0X *) x.rdo := TRUE
  END CharToStr;

  PROCEDURE StringRelation*(op: INTEGER; VAR x, y: Item);    (* x := x < y *)
  BEGIN
    (*x, y are char arrays or strings*)
    IF (x.type.form = OJB.String) & (x.b = 2) & (y.type.form = OJB.String) &
       (y.b = 2) THEN
      StrToChar(x); StrToChar(y);
      IntRelation(op, x, y)
    ELSIF (x.type.form # OJB.String) & (y.type.form = OJB.String) &
          (y.b = 1) THEN (* x := x < "" *)
      load(x);
      pushConst(0);
      pushTypedArray(x.type.base);
      SetCC(x, relmap0[op - OJS.eql])
    ELSIF (x.type.form = OJB.String) & (y.type.form # OJB.String) THEN
      load(y);
      load(x);
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKEVIRTUAL,
                                "java/lang/String", "toCharArray", "()[C", 0);
      x.mode := Stack;
      ClassFormat.putInsn(topCtx.m, Opcodes.SWAP);
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC,
                                "OberonRuntime", "StrCmp", "([C[C)I", 2);
      SetCC(x, relmap0[op - OJS.eql])
    ELSE
      load(x);
      IF x.type.form = OJB.String THEN
        ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKEVIRTUAL,
                                  "java/lang/String", "toCharArray", "()[C", 0);
        x.mode := Stack
      END ;
      load(y);
      IF y.type.form = OJB.String THEN
        ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKEVIRTUAL,
                                  "java/lang/String", "toCharArray", "()[C", 0);
        x.mode := Stack
      END ;
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC,
                                "OberonRuntime", "StrCmp", "([C[C)I", 2);
      SetCC(x, relmap0[op - OJS.eql])
    END
  END StringRelation;

  PROCEDURE makeCopyDesc(VAR s, desc: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    i := Strings.Write("(L", desc, 0);
    i := Strings.Write(s, desc, i);
    i := Strings.Write(";)V", desc, i);
    IF i = -1 THEN OJS.Mark("Maximum descriptor length reached") END
  END makeCopyDesc;


  (* Code generation of Assignments *)

  PROCEDURE Store*(VAR x, y: Item; storeStruct: BOOLEAN);   (* x := y *)
    VAR  desc, typeName :ClassFormat.Descriptor;
  BEGIN
    load(y);
    IF storeStruct THEN
      internalName(x.type, typeName);
      makeCopyDesc(typeName, desc);
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKEVIRTUAL, typeName,
                                "copyFrom", desc, 1)
    ELSE
      IF (x.mode = OJB.Var) OR (x.mode = Stack) OR (x.mode = OJB.ParStruct) THEN
        IF x.r > 0 THEN (*local*)
          storeTypedLocal(x)
        ELSE
          Descriptor(x.type, desc);
          ClassFormat.putFieldInsn(topCtx.m, Opcodes.PUTSTATIC, x.modName,
                                   x.name, desc)
        END
      ELSIF x.mode = RegI THEN
        storeTypedArray(x.type)
      ELSIF x.mode = Field THEN
        Descriptor(x.type, desc);
        ClassFormat.putFieldInsn(topCtx.m, Opcodes.PUTFIELD, x.recordName,
                                 x.name, desc)
      ELSIF x.mode = OJB.Par THEN
        storeTypedArray(x.type)
      ELSE OJS.Mark("illegal assignment")
      END
    END
  END Store;

  PROCEDURE storeArrayR(i: INTEGER; type: OJB.Type; VAR x, y: Item);
    VAR desc, iname: ClassFormat.Descriptor;
      cond, end, lastTmp, index: INTEGER;
  BEGIN
    IF type.form = OJB.Array THEN
      IF type.len < 0  THEN
        (*
          only monodimensional open arrays are supported.
          ex.
            PROCEDURE P(VAR b : ARRAY OF ARRAY OF INTEGER);
              VAR c: ARRAY 10, 10 OF INTEGER;
            BEGIN
              c := b; (* illegal see Type Rule E.6, B.2, B.3 *)
            END P;
         *)
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, y.a);
        ClassFormat.putInsn(topCtx.m, Opcodes.ARRAYLENGTH);
        pushConst(1);
        ClassFormat.putInsn(topCtx.m, Opcodes.ISUB)
      ELSE
        pushConst(type.len - 1)
      END ;
      (* topCtx.numTmpVars is the first free local to use *)
      index := i + topCtx.numTmpVars;
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ISTORE, index);
      cond := topCtx.m.i;
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, index);
      end := topCtx.m.i;
      ClassFormat.putJumpInsn(topCtx.m, Opcodes.IFLT, 0);
      storeArrayR(i + 1, type.base, x, y);
      ClassFormat.putIincInsn(topCtx.m, index, -1);
      ClassFormat.putGotoInsn(topCtx.m, cond-topCtx.m.i, 0);
      Fixup(end)
    ELSE
      (* as we incremented index(= last used local) we have to
         update topCtx.numTmpVars as it is still pointing to the
         first used local *)
      IF ~isPrimitiveType(type) & (type.form # OJB.Pointer) &
        (type.form # OJB.Proc) THEN
        topCtx.numTmpVars := topCtx.numTmpVars + i + 1;
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
        lastTmp := pushIndexes2(i+1);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, y.a);
        lastTmp := pushIndexes2(i+1);
        internalName(type, iname);
        makeCopyDesc(iname, desc);
        ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKEVIRTUAL, iname,
                                  "copyFrom", desc, 1);
      ELSE
        topCtx.numTmpVars := topCtx.numTmpVars + i;
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
        lastTmp := pushIndexes2(i);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, lastTmp);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, y.a);
        lastTmp := pushIndexes2(i);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, lastTmp);
        pushTypedArray(type);
        storeTypedArray(type)
      END
    END
  END storeArrayR;

  PROCEDURE storeTempLocal(VAR x: Item);
  BEGIN
    load(x);
    x.a := topCtx.numTmpVars;
    storeTypedLocal(x);
    INC(topCtx.numTmpVars)
  END storeTempLocal;

  PROCEDURE storeArray*(VAR x, y: Item);
    VAR end: INTEGER;
  BEGIN
    load(y);
    y.a := topCtx.numTmpVars;
    storeTypedLocal(y);
    INC(topCtx.numTmpVars);
    (* OJP guarantees x and y are regular arrays (not open) with equal element
       types and length or x is a regular array, y is an open array with equal
       base type *)
    IF (check) & (y.type.len < 0) THEN (*open array len*)
      pushConst(x.type.len);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, y.a);
      ClassFormat.putInsn(topCtx.m, Opcodes.ARRAYLENGTH);
      end := topCtx.m.i;
      ClassFormat.putJumpInsn(topCtx.m, Opcodes.IFICMPGE, 0);
      Trap("array copy overflow");
      Fixup(end)
    END ;
    IF isPrimitiveType(x.type.base) THEN
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, y.a);
      pushConst(0);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
      pushConst(0);
      IF y.type.len < 0 THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, y.a);
        ClassFormat.putInsn(topCtx.m, Opcodes.ARRAYLENGTH)
      ELSE
        pushConst(y.type.len)
      END ;
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC,
                                "java/lang/System", "arraycopy",
                                "(Ljava/lang/Object;ILjava/lang/Object;II)V", 5)
    ELSE
      storeArrayR(0, y.type, x, y)
    END
  END storeArray;

  PROCEDURE StoreProc*(VAR x, y: Item);   (* x := y *)
  BEGIN
    IF y.mode = OJB.Const THEN
      load(y)
    END ;
    Store(x, y, FALSE)
  END StoreProc;

  PROCEDURE ValueParam*(VAR x: Item);
  BEGIN
    load(x)
  END ValueParam;

  PROCEDURE StringParam*(VAR x: Item);
  BEGIN
    load(x);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKEVIRTUAL,
                              "java/lang/String", "toCharArray", "()[C", 0)
  END StringParam;

  PROCEDURE CopyString*(VAR x, y: Item);   (* x := y *)
    VAR len, end: INTEGER;
  BEGIN
    len := x.type.len;
    IF len >= 0 THEN
      IF len < y.b THEN OJS.Mark("string too long") END
    ELSIF check THEN (*open array len*)
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
      ClassFormat.putInsn(topCtx.m, Opcodes.ARRAYLENGTH);
      pushConst(y.b);
      end := topCtx.m.i;
      ClassFormat.putJumpInsn(topCtx.m, Opcodes.IFICMPGE, 0);
      Trap("string too long");
      Fixup(end)
    END ;
    IF y.b = 1 THEN (* x := "" *)
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
      pushConst(0);
      pushConst(0);
      ClassFormat.putInsn(topCtx.m, Opcodes.CASTORE)
    ELSE
      StringParam(y);
      pushConst(0);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
      pushConst(0);
      pushConst(y.b);
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC,
                                "java/lang/System", "arraycopy",
                                "(Ljava/lang/Object;ILjava/lang/Object;II)V", 5)
    END
  END CopyString;

  PROCEDURE loadPar*(VAR x: Item);
  BEGIN
    IF x.mode = OJB.Par THEN
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
      ClassFormat.putInsn(topCtx.m, Opcodes.ICONST0)
    END
  END loadPar;

  PROCEDURE VarParam*(VAR x: Item);
    VAR desc:  ClassFormat.Descriptor;
      newStoreStmt: StoreStmt;
      type, newType: OJB.Type;
  BEGIN
    IF (x.mode = OJB.Par) & (x.oldType = NIL) THEN
      (* x is already a var parameter with no type guard, so pass it by value *)
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a)
    ELSE
      IF x.oldType # NIL THEN
        newType := x.oldType
      ELSE
        newType := x.type
      END ;
      NEW(newStoreStmt);
      IF x.mode = Field THEN
        newStoreStmt.x.a := topCtx.numTmpVars;
        newStoreStmt.x.mode := x.mode;
        Strings.Copy(x.recordName, newStoreStmt.x.recordName);
        Strings.Copy(x.modName, newStoreStmt.x.modName);
        Strings.Copy(x.name, newStoreStmt.x.name);
        newStoreStmt.x.type := newType;
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ASTORE, newStoreStmt.x.a);
        INC(topCtx.numTmpVars)
      ELSIF x.mode = RegI THEN
        newStoreStmt.x.a := topCtx.numTmpVars;
        INC(topCtx.numTmpVars);
        newStoreStmt.x.b := topCtx.numTmpVars;
        INC(topCtx.numTmpVars);
        newStoreStmt.x.mode := x.mode;
        Strings.Copy(x.name, newStoreStmt.x.name);
        Strings.Copy(x.modName, newStoreStmt.x.modName);
        newStoreStmt.x.type := newType;
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ISTORE, newStoreStmt.x.b);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ASTORE, newStoreStmt.x.a)
      ELSIF (x.mode = OJB.Var) OR (x.oldType # NIL) THEN
        newStoreStmt.x.a := x.a;
        newStoreStmt.x.r := x.r;
        newStoreStmt.x.mode := x.mode;
        Strings.Copy(x.name, newStoreStmt.x.name);
        Strings.Copy(x.modName, newStoreStmt.x.modName);
        newStoreStmt.x.type := newType
      ELSE OJS.Mark("Only variables allowed")
      END ;
      ClassFormat.putInsn(topCtx.m, Opcodes.ICONST1);
      type := x.type;
      IF isPrimitiveType(type) THEN
        emitPrimitiveNewArray(type)
      ELSIF type.form = OJB.Array THEN
        Descriptor(type, desc);
        ClassFormat.putTypeInsn(topCtx.m, Opcodes.ANEWARRAY, desc)
      ELSE
        internalName(type, desc);
        ClassFormat.putTypeInsn(topCtx.m, Opcodes.ANEWARRAY, desc)
      END ;
      ClassFormat.putInsn(topCtx.m, Opcodes.DUP);
      ClassFormat.putInsn(topCtx.m, Opcodes.ICONST0);
      IF x.mode = Field THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, newStoreStmt.x.a)
      ELSIF x.mode = RegI THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, newStoreStmt.x.a);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, newStoreStmt.x.b)
      END ;
      load(x);
      storeTypedArray(x.type);
      newStoreStmt.y.a := topCtx.numTmpVars;
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ASTORE, topCtx.numTmpVars);
      INC(topCtx.numTmpVars);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, newStoreStmt.y.a);
      newStoreStmt.y.mode := RegI;
      newStoreStmt.y.type := type;
      newStoreStmt.next := topCtx.storeStmt;
      topCtx.storeStmt := newStoreStmt
    END
  END VarParam;

  PROCEDURE storeVarPar*;
    VAR h: StoreStmt;
  BEGIN
    h := topCtx.storeStmt;
    WHILE h # NIL DO
      IF h.x.mode = Field THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, h.x.a)
      ELSIF h.x.mode = RegI THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, h.x.a);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, h.x.b)
      ELSIF h.x.mode = OJB.Par THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, h.x.a);
        ClassFormat.putInsn(topCtx.m, Opcodes.ICONST0)
      END ;
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, h.y.a);
      ClassFormat.putInsn(topCtx.m, Opcodes.ICONST0);
      Store(h.x, h.y, FALSE);
      h := h.next;
    END ;
    topCtx.storeStmt := NIL
  END storeVarPar;

  PROCEDURE PrepAssign*(VAR x: Item);
  BEGIN
    IF x.type.form = OJB.Array THEN
      storeTempLocal(x)
    ELSIF x.type.form = OJB.Record THEN
      load(x)
    ELSE
      loadPar(x)
    END
  END PrepAssign;

  PROCEDURE For0*(VAR x, y: Item);
  BEGIN
    Store(x, y, FALSE)
  END For0;

  PROCEDURE For1*(VAR x, z, w: Item): INTEGER;
    VAR L, oldMode: INTEGER;
  BEGIN
    load(z);
    oldMode := x.mode;
    load(x);
    x.mode := oldMode;
    L := topCtx.m.i;
    IF w.a < 0 THEN ClassFormat.putJumpInsn(topCtx.m, Opcodes.IFICMPGT, 0)
    ELSIF w.a > 0 THEN ClassFormat.putJumpInsn(topCtx.m, Opcodes.IFICMPLT, 0)
    ELSE OJS.Mark("zero increment")
    END
    RETURN L
  END For1;

  PROCEDURE For2*(VAR x, w: Item);
  BEGIN
    IF (x.mode = OJB.Var) & (x.r > 0) THEN
      ClassFormat.putIincInsn(topCtx.m, x.a, w.a)
    ELSIF x.mode = OJB.Par THEN
      loadPar(x);
      AddOp(OJS.plus, x, w);
      w.mode := Stack;
      x.mode := OJB.Par;
      Store(x, w, FALSE)
    ELSE
      AddOp(OJS.plus, x, w);
      w.mode := Stack;
      Store(x, w, FALSE)
    END
  END For2;

  PROCEDURE CaseIn*(VAR x: Item; L: INTEGER): INTEGER;
  BEGIN
    storeTempLocal(x)
    RETURN FJump(L)
  END CaseIn;

  PROCEDURE CaseDefault*(): INTEGER;
    VAR dflt: INTEGER;
  BEGIN
    dflt := topCtx.m.i;
    Trap("Invalid case in CASE statement")
    RETURN dflt
  END CaseDefault;

  PROCEDURE CaseOut*(VAR caseExpr: Item; end, L0, n, dflt: INTEGER;
                     tab: ARRAY OF LabelRange);
    VAR max, lastLow, nLables, i, j: INTEGER;
      all: ARRAY NofCases OF INTEGER;
  BEGIN
    IF n > 0 THEN
      max := tab[n-1].high;
      lastLow := tab[0].low;
      nLables := ABS(max - lastLow + 1);
    ELSE
      max := 0; lastLow := 0; nLables := 0;
    END ;
    IF nLables < NofCases THEN
      ClassFormat.FixLink(topCtx.m, L0);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, caseExpr.a);
      dflt := dflt-topCtx.m.i;
      i := 0; j := 0;
      WHILE j < n DO
        WHILE lastLow < tab[j].low DO
          all[i] := dflt;
          INC(i);
          INC(lastLow)
        END ;
        WHILE lastLow <= tab[j].high DO
          all[i] := tab[j].L-topCtx.m.i;
          INC(i);
          INC(lastLow)
        END ;
        INC(j)
      END ;
      ClassFormat.putTableSwitchInsn(topCtx.m, tab[0].low, max,
                                     dflt, nLables, all);
      ClassFormat.FixLink(topCtx.m, end)
    ELSE OJS.Mark("too many cases or no case in case statement")
    END
  END CaseOut;

  PROCEDURE PrepCall*(VAR x: Item);
  BEGIN
    (*x.type.form = OJB.Proc*)
    IF x.mode # OJB.Const THEN
      (*call on procedure variable*)
      load(x)
    END
  END PrepCall;

  PROCEDURE Call*(VAR x: Item);
    VAR iname: ClassFormat.Descriptor;
  BEGIN
    (*x.type.form = OJB.Proc*)
    IF x.mode = OJB.Const THEN
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, x.modName,
                                x.name, x.type.signature, x.type.nofpar)
    ELSE
      internalName(x.type, iname);
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKEVIRTUAL, iname,
                                "invoke", x.type.signature, x.type.nofpar)
    END ;
    IF x.type.base.form # OJB.NoTyp THEN (*function*)
      x.mode := Stack
    END
  END Call;

  PROCEDURE Enter*(proc: OJB.Object; locblksize: INTEGER);
    VAR acc: INTEGER;
  BEGIN
    acc := Opcodes.ACCxSTATIC + Opcodes.ACCxPUBLIC + Opcodes.ACCxFINAL;
    topCtx.m := ClassFormat.NewMI(topCtx.c, acc, proc.name,
                                  proc.type.signature);
    clearCtx(topCtx);
    initializeScope(getLocalVars(proc.type.dsc, proc.type.nofpar), locblksize)
  END Enter;

  PROCEDURE Return*(type: OJB.Type; VAR x: Item);
  BEGIN
    IF (type # NIL) & (type.form # OJB.NoTyp) THEN
      load(x);
      IF type = OJB.byteType THEN
        pushConst(255);
        ClassFormat.putInsn(topCtx.m, Opcodes.IAND)
      END ;
      emitTypedReturn(x.type)
    ELSE ClassFormat.putInsn(topCtx.m, Opcodes.RETURNx)
    END ;
    ClassFormat.setMaxVars(topCtx.m, topCtx.numTmpVars);
    closeContext
  END Return;

  PROCEDURE Increment1*(upordown: INTEGER; VAR x, y, z: Item);
    VAR op: INTEGER;
  BEGIN
    IF upordown = 0 THEN op := Opcodes.IADD ELSE op := Opcodes.ISUB END ;
    IF y.type.form = OJB.NoTyp THEN y.mode := OJB.Const; y.a := 1 END ;
    IF (x.mode = OJB.Var) & (x.r > 0) & (y.mode = OJB.Const) &
       (y.a >= -128) & (y.a <= 127) THEN
      IF op = Opcodes.ISUB THEN y.a := -y.a END ;
      ClassFormat.putIincInsn(topCtx.m, x.a, y.a)
    ELSE
      IF (x.mode = OJB.Var) & (x.r > 0) THEN
        z := x;
        load(x)
      END ;
      load(y);
      ClassFormat.putInsn(topCtx.m, op);
      Store(z, x, FALSE)
    END
  END Increment1;

  PROCEDURE Increment0*(VAR x, z: Item);
  BEGIN
    IF (x.mode # OJB.Var) OR (x.r = 0) THEN
      z := x;
      IF x.mode = RegI THEN
        ClassFormat.putInsn(topCtx.m, Opcodes.DUP2)
      ELSIF x.mode = Field THEN
        ClassFormat.putInsn(topCtx.m, Opcodes.DUP)
      END ;
      IF x.mode = OJB.Par THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
        pushConst(0);
        ClassFormat.putInsn(topCtx.m, Opcodes.DUP2);
        pushTypedArray(x.type);
        x.mode := Stack
      ELSE
        load(x)
      END ;
    END
  END Increment0;

  PROCEDURE Include0*(VAR x, z: Item);
  BEGIN
    z := x;
    IF x.mode = RegI THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.DUP2)
    ELSIF x.mode = Field THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.DUP)
    END ;
    IF x.mode = OJB.Par THEN
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, x.a);
      pushConst(0);
      ClassFormat.putInsn(topCtx.m, Opcodes.DUP2);
      pushTypedArray(x.type);
      x.mode := Stack
    ELSE
      load(x)
    END ;
  END Include0;

  PROCEDURE Include1*(inorex: INTEGER; VAR y, z: Item);
  BEGIN
    Singleton(y);
    load(y);
    IF inorex = 0 THEN
      ClassFormat.putInsn(topCtx.m, Opcodes.IOR)
    ELSE
      pushConst(-1);
      ClassFormat.putInsn(topCtx.m, Opcodes.IXOR);
      ClassFormat.putInsn(topCtx.m, Opcodes.IAND)
    END ;
    Store(z, y, FALSE)
  END Include1;

  PROCEDURE Assert*(VAR x: Item);
    VAR L0: INTEGER;
  BEGIN
    IF x.mode # Cond THEN loadCond(x) END ;
    L0 := topCtx.m.i;
    ClassFormat.putJumpInsn(topCtx.m, x.r, x.b);
    ClassFormat.FixLink(topCtx.m, x.a); x.b := L0;
    Trap("assertion violated");
    ClassFormat.FixLink(topCtx.m, x.b)
  END Assert;

  PROCEDURE New*(VAR x: Item);
    VAR iname: ClassFormat.Descriptor;
      dummy: Item;
  BEGIN
    loadPar(x);
    dummy.mode := Stack;
    internalName(x.type, iname);
    genNew(iname);
    Store(x, dummy, FALSE)
  END New;

  PROCEDURE ReadInt*(VAR x: Item);
  BEGIN
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "OberonRuntime",
                              "ReadInt", "()I", 0);
    x.mode := Stack
  END ReadInt;

  PROCEDURE eot*(VAR x: Item);
  BEGIN
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "OberonRuntime",
                              "eot", "()Z", 0);
    x.mode := Stack
  END eot;

  PROCEDURE WriteInt*(VAR x: Item);
  BEGIN
    load(x);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "OberonRuntime",
                              "WriteInt", "(I)V", 1)
  END WriteInt;

  PROCEDURE WriteReal*(VAR x: Item);
  BEGIN
    load(x);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "OberonRuntime",
                              "WriteReal", "(F)V", 1)
  END WriteReal;

  PROCEDURE WriteChar*(VAR x: Item);
  BEGIN
    load(x);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "OberonRuntime",
                              "WriteChar", "(I)V", 1)
  END WriteChar;

  PROCEDURE WriteLn*;
  BEGIN
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "OberonRuntime",
                              "WriteLn", "()V", 0)
  END WriteLn;

  PROCEDURE Args0*;
  BEGIN
    ClassFormat.putFieldInsn(topCtx.m, Opcodes.GETSTATIC, topCtx.className,
                             "args", "[Ljava/lang/String;");
  END Args0;

  PROCEDURE Args1*(VAR x: Item);
  BEGIN
    load(x)
  END Args1;

  PROCEDURE Args2*(VAR y: Item);
  BEGIN
    load(y);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "OberonRuntime",
                              "ARGS", "([Ljava/lang/String;I[C)V", 3)
  END Args2;

  PROCEDURE Abs*(VAR x: Item);
    VAR f: REAL; end: INTEGER;
  BEGIN
    IF x.mode = OJB.Const THEN
      IF x.type.form = OJB.Real THEN
        f := ABS(SYSTEM.VAL(REAL, x.a));
        x.a := SYSTEM.VAL(INTEGER, f)
      ELSE x.a := ABS(x.a)
      END
    ELSE load(x);
      IF x.type.form = OJB.Real THEN
        ClassFormat.putInsn(topCtx.m, Opcodes.DUP);
        ClassFormat.putInsn(topCtx.m, Opcodes.FCONST0);
        ClassFormat.putInsn(topCtx.m, Opcodes.FCMPG);
        end := topCtx.m.i;
        ClassFormat.putJumpInsn(topCtx.m, Opcodes.IFGT, 0);
        ClassFormat.putInsn(topCtx.m, Opcodes.FCONST0);
        ClassFormat.putInsn(topCtx.m, Opcodes.SWAP);
        ClassFormat.putInsn(topCtx.m, Opcodes.FSUB);
        Fixup(end)
      ELSE
        ClassFormat.putInsn(topCtx.m, Opcodes.DUP);
        end := topCtx.m.i;
        ClassFormat.putJumpInsn(topCtx.m, Opcodes.IFGE, 0);
        ClassFormat.putInsn(topCtx.m, Opcodes.INEG);
        Fixup(end)
      END
    END
  END Abs;

  PROCEDURE Odd*(VAR x: Item);
  BEGIN
    IF x.mode = OJB.Const THEN
      x.a := ORD(ODD(x.a))
    ELSE
      load(x);
      pushConst(1);
      ClassFormat.putInsn(topCtx.m, Opcodes.IAND);
      SetCC(x, Opcodes.IFNE)
    END
  END Odd;

  PROCEDURE Floor*(VAR x: Item);
    VAR f: REAL;
  BEGIN
    IF x.mode = OJB.Const THEN
       f := SYSTEM.VAL(REAL, x.a);
       x.a := FLOOR(f)
    ELSE
      load(x);
      ClassFormat.putInsn(topCtx.m, Opcodes.F2D);
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "java/lang/Math",
                                "floor", "(D)D", 1);
      ClassFormat.putInsn(topCtx.m, Opcodes.D2I)
    END
  END Floor;

  PROCEDURE IntToReal*(VAR x: Item);
  BEGIN
    load(x);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "java/lang/Float",
                              "intBitsToFloat", "(I)F", 1)
  END IntToReal;

  PROCEDURE RealToInt*(VAR x: Item);
  BEGIN
    load(x);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "java/lang/Float",
                              "floatToRawIntBits", "(F)I", 1)
  END RealToInt;

  PROCEDURE Float*(VAR x: Item);
  BEGIN
    IF x.mode = OJB.Const THEN
       x.a := SYSTEM.VAL(INTEGER, FLT(x.a))
    ELSE
      load(x);
      ClassFormat.putInsn(topCtx.m, Opcodes.I2F)
    END
  END Float;

  PROCEDURE Ord*(VAR x: Item);
  BEGIN
    (* allow constant folding: ORD("A") + 1 *)
    IF x.mode # OJB.Const THEN
      load(x)
    END
  END Ord;

  PROCEDURE Len*(VAR x: Item);
  BEGIN
    IF x.type.len >= 0 THEN
      Pop(x);
      x.mode := OJB.Const; x.a := x.type.len
    ELSE (*open array*)
      load(x);
      ClassFormat.putInsn(topCtx.m, Opcodes.ARRAYLENGTH);
      x.mode := Stack
    END
  END Len;

  PROCEDURE Argnum*(VAR x: Item);
  BEGIN
    ClassFormat.putFieldInsn(topCtx.m, Opcodes.GETSTATIC, topCtx.className,
                             "args", "[Ljava/lang/String;");
    ClassFormat.putInsn(topCtx.m, Opcodes.ARRAYLENGTH);
    x.mode := Stack
  END Argnum;

  PROCEDURE Shift*(fct: INTEGER; VAR x, y: Item);
    CONST Ror = 3;
    VAR op: INTEGER;
  BEGIN
    IF fct = 0 THEN
      op := Opcodes.ISHL
    ELSIF fct = 1 THEN
      op := Opcodes.ISHR
    ELSE op := Ror
    END ;
    IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
      IF fct = 0 THEN
        x.a := LSL(x.a, y.a)
      ELSIF fct = 1 THEN
        x.a := ASR(x.a, y.a)
      ELSE
        x.a := ROR(x.a, y.a)
      END
    ELSE
      loadAndMaybeSwap(x, y);
      IF op = Ror THEN
        ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC, "OberonRuntime",
                                  "ROR", "(II)I", 2)
      ELSE
        ClassFormat.putInsn(topCtx.m, op)
      END
    END
  END Shift;

  PROCEDURE Band*(VAR x, y: Item);
  BEGIN
    IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
       x.a := AND(x.a, y.a)
    ELSE
      loadAndMaybeSwap(x, y);
      ClassFormat.putInsn(topCtx.m, Opcodes.IAND)
    END
  END Band;

  PROCEDURE Bor*(VAR x, y: Item);
  BEGIN
    IF (x.mode = OJB.Const) & (y.mode = OJB.Const) THEN
       x.a := BOR(x.a, y.a)
    ELSE
      loadAndMaybeSwap(x, y);
      ClassFormat.putInsn(topCtx.m, Opcodes.IOR)
    END
  END Bor;

  PROCEDURE Bnot*(VAR x: Item);
  BEGIN
    IF x.mode = OJB.Const THEN
       x.a := NOT(x.a)
    ELSE
      load(x);
      pushConst(-1);
      ClassFormat.putInsn(topCtx.m, Opcodes.IXOR)
    END
  END Bnot;

  PROCEDURE Open*(modid: ARRAY OF CHAR);
    VAR ctx: ClassContext;
  BEGIN
    ClassFormat.Init;
    check := TRUE;
    NEW(ctx);
    Strings.Copy(modid, ctx.className);
    topCtx := ctx;
    topCtx.c := ClassFormat.NewCF(Opcodes.ACCxPUBLIC + Opcodes.ACCxFINAL,
                                  topCtx.className, "java/lang/Object");
    dummyMethod := ClassFormat.NewMI(topCtx.c, Opcodes.ACCxPUBLIC, "DUMMY",
                                     "()V");
    topCtx.m := dummyMethod
  END Open;

  PROCEDURE Header*(topScope: OJB.Object);
    VAR desc: ClassFormat.Descriptor;
      tmp: OJB.Object;
  BEGIN
    ClassFormat.addField(topCtx.c, Opcodes.ACCxPUBLIC + Opcodes.ACCxSTATIC,
                         "args", "[Ljava/lang/String;");
    tmp := topScope;
    WHILE tmp # NIL DO
      IF tmp.expo & (tmp.class = OJB.Const) & (tmp.type.form # OJB.Proc) &
         (tmp.type.form # OJB.String) THEN
        Descriptor(tmp.type, desc);
        ClassFormat.addConstField(topCtx.c, tmp.name, desc, tmp.val)
      ELSIF tmp.class = OJB.Var THEN
        Descriptor(tmp.type, desc);
        ClassFormat.addField(topCtx.c, Opcodes.ACCxPUBLIC + Opcodes.ACCxSTATIC,
                             tmp.name, desc)
      END ;
      tmp := tmp.next
    END
  END Header;

  PROCEDURE copyRecord(x: OJB.Object);
    VAR desc, iname: ClassFormat.Descriptor;
  BEGIN
    ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0);
    loadRef(x);
    ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 1);
    loadRef(x);
    internalName(x.type, iname);
    makeCopyDesc(iname, desc);
    ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKEVIRTUAL, iname,"copyFrom",
                              desc, 1)
  END copyRecord;

  PROCEDURE copyPrimitiveField(x: OJB.Object);
  BEGIN
    ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0);
    ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 1);
    loadRef(x);
    storeRef(x)
  END copyPrimitiveField;

  PROCEDURE copyArrayR(i: INTEGER; x: OJB.Object; type: OJB.Type; tmpVars,
                       currTmpVar: OJB.Object);
    VAR desc, iname: ClassFormat.Descriptor;
      lastTmp: OJB.Object;
      cond, end: INTEGER;
  BEGIN
    IF type.form = OJB.Array THEN
      pushConst(type.len - 1);
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ISTORE, currTmpVar.val);
      cond := topCtx.m.i;
      ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, currTmpVar.val);
      end := topCtx.m.i;
      ClassFormat.putJumpInsn(topCtx.m, Opcodes.IFLT, 0);
      copyArrayR(i + 1, x, type.base, tmpVars, currTmpVar.next);
      ClassFormat.putIincInsn(topCtx.m, currTmpVar.val, -1);
      ClassFormat.putGotoInsn(topCtx.m, cond-topCtx.m.i, 0);
      Fixup(end)
    ELSE
      IF ~isPrimitiveType(type) & (type.form # OJB.Pointer) &
        (type.form # OJB.Proc) THEN
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0);
        loadRef(x);
        lastTmp := pushIndexes(i+1, tmpVars);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 1);
        loadRef(x);
        lastTmp := pushIndexes(i+1, tmpVars);
        internalName(type, iname);
        makeCopyDesc(iname, desc);
        ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKEVIRTUAL, iname,
                                  "copyFrom", desc, 1)
      ELSE
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0);
        loadRef(x);
        lastTmp := pushIndexes(i, tmpVars);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, lastTmp.val);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 1);
        loadRef(x);
        lastTmp := pushIndexes(i, tmpVars);
        ClassFormat.putVarInsn(topCtx.m, Opcodes.ILOAD, lastTmp.val);
        pushTypedArray(type);
        storeTypedArray(type)
      END
    END
  END copyArrayR;

  PROCEDURE copyArray(x, tmpVars: OJB.Object);
  BEGIN
    copyArrayR(0, x, x.type, tmpVars, tmpVars)
  END copyArray;

  PROCEDURE copyState(x: OJB.Object);
    VAR type: OJB.Type; tempVars: OJB.Object;
       num: INTEGER;
  BEGIN
    (* 2 locals so far: this + copyFrom's parameter *)
    num := 2;
    tempVars := createArraysTempVars(x, num, FALSE);
    WHILE x # NIL DO
      IF (x.class = OJB.Var) OR (x.class = OJB.Fld) THEN
        type := x.type;
        IF type.form = OJB.Record THEN
          copyRecord(x)
        ELSIF type.form = OJB.Array THEN
          copyArray(x, tempVars)
        ELSE
          copyPrimitiveField(x)
        END
      END ;
      x := x.next;
    END ;
    topCtx.numTmpVars := num
  END copyState;

  PROCEDURE CopyMethod(obj: OJB.Object);
    VAR desc,typeName: ClassFormat.Descriptor;
  BEGIN
    internalName(obj.type, typeName);
    makeCopyDesc(typeName, desc);
    topCtx.m := ClassFormat.NewMI(topCtx.c, Opcodes.ACCxPUBLIC +
                                  Opcodes.ACCxFINAL, "copyFrom", desc);
    clearCtx(topCtx);
    copyState(obj.type.dsc);
    ClassFormat.putInsn(topCtx.m, Opcodes.RETURNx);
    ClassFormat.setMaxVars(topCtx.m, topCtx.numTmpVars);
    closeContext
  END CopyMethod;

  PROCEDURE MainProc*(hasMain: BOOLEAN);
  BEGIN
    topCtx.m := ClassFormat.NewMI(topCtx.c, Opcodes.ACCxPUBLIC +
                                  Opcodes.ACCxSTATIC, "main",
                                  "([Ljava/lang/String;)V");
    clearCtx(topCtx);
    ClassFormat.putVarInsn(topCtx.m, Opcodes.ALOAD, 0);
    ClassFormat.putFieldInsn(topCtx.m, Opcodes.PUTSTATIC, topCtx.className,
                             "args", "[Ljava/lang/String;");
    IF hasMain THEN
      ClassFormat.putMethodInsn(topCtx.m, Opcodes.INVOKESTATIC,
                                topCtx.className, "Main", "()V", 0)
    END ;
    ClassFormat.putInsn(topCtx.m, Opcodes.RETURNx);
    ClassFormat.setMaxVars(topCtx.m, 1);
    closeContext
  END MainProc;

  PROCEDURE addCmdLineArgs;
  BEGIN
    pushConst(0);
    ClassFormat.putTypeInsn(topCtx.m, Opcodes.ANEWARRAY, "java/lang/String");
    ClassFormat.putFieldInsn(topCtx.m, Opcodes.PUTSTATIC, topCtx.className,
                             "args", "[Ljava/lang/String;")
  END addCmdLineArgs;

  PROCEDURE ModuleBody*(topScope: OJB.Object);
  BEGIN
    topCtx.m := ClassFormat.NewMI(topCtx.c, Opcodes.ACCxSTATIC, "<clinit>",
                                  "()V");
    clearCtx(topCtx);
    addCmdLineArgs;
    initializeScope(topScope, 0)
  END ModuleBody;

  PROCEDURE Close*;
    VAR path: ARRAY OJS.maxPath OF CHAR;
  BEGIN
    genClassFilePath(topCtx.className, path);
    ClassFormat.toFile(topCtx.c, path)
  END Close;

  PROCEDURE deleteModule*;
    VAR path: ARRAY OJS.maxPath OF CHAR;
      r: INTEGER;
  BEGIN
    genClassFilePath(topCtx.className, path);
    r := Files.Delete(path)
  END deleteModule;

  PROCEDURE MakeRecordType*(obj: OJB.Object);
    VAR desc, name, baseName: ClassFormat.Descriptor;
      path: ARRAY OJS.maxPath OF CHAR;
      newCtx: ClassContext;
      access: INTEGER;
      tmp: OJB.Object;
      recordType: OJB.Type;
  BEGIN
    NEW(newCtx);
    internalName(obj.type, name);
    access := Opcodes.ACCxPUBLIC;
    Strings.Append("java/lang/Object", baseName);
    IF obj.type.base # NIL THEN
      internalName(obj.type.base, baseName);
      INC(access, Opcodes.ACCxSUPER)
    END ;
    Strings.Copy(topCtx.className, newCtx.className);
    newCtx.next := topCtx;
    topCtx := newCtx;
    newCtx.c := ClassFormat.NewCF(access, name, baseName);
    tmp := obj.type.dsc;
    recordType := obj.type;
    WHILE (tmp # NIL) & (tmp.class = OJB.Fld) & (recordType = tmp.recordType) DO
      Descriptor(tmp.type, desc);
      ClassFormat.addField(topCtx.c, Opcodes.ACCxPUBLIC, tmp.name, desc);
      tmp := tmp.next
    END ;
    Constructor(obj);
    CopyMethod(obj);
    genClassFilePath(name, path);
    ClassFormat.toFile(topCtx.c, path);
    topCtx := topCtx.next
  END MakeRecordType;

BEGIN
  relmap[0] := Opcodes.IFICMPEQ; relmap[1] := Opcodes.IFICMPNE;
  relmap[2] := Opcodes.IFICMPLT; relmap[3] := Opcodes.IFICMPLE;
  relmap[4] := Opcodes.IFICMPGT; relmap[5] := Opcodes.IFICMPGE;
  relmap0[0] := Opcodes.IFEQ; relmap0[1] := Opcodes.IFNE;
  relmap0[2] := Opcodes.IFLT; relmap0[3] := Opcodes.IFLE;
  relmap0[4] := Opcodes.IFGT; relmap0[5] := Opcodes.IFGE;
  relmapNil[0] := Opcodes.IFNULL; relmapNil[1] := Opcodes.IFNONNULL;
  relmapAdr[0] := Opcodes.IFACMPEQ;relmapAdr[1] := Opcodes.IFACMPNE;
END OJG.
