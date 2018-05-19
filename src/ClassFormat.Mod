(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

(*
  This module deals with the low level generation of a class file according to
  the Java Virtual Machine Specification. It uses CpCache to keep track of the
  constant pool entries written so far in the CFDesc record.
*)
MODULE ClassFormat;
  IMPORT Strings, Files, CpCache, Opcodes, OJS;

  CONST
    CpMax = 10000H;
    DescLenMax = 500;
    FieldsMax = CpMax;
    LineNumTabMax = CpMax;
    CodeMax = CpMax;
    MethodsMax = 34 + LineNumTabMax + CodeMax;
    ClassMax = 32 + CpMax + MethodsMax + FieldsMax;
    ShortMaxValue = 32767;
    UTF8 = 1;
    CLASS = 7;
    NAMExTYPE = 12;
    METH = 10;
    FIELD = 9;
    STR = 8;
    INT* = 3;
    FLOAT* = 4;

  TYPE
    Descriptor* = ARRAY DescLenMax OF CHAR;
    CF* = POINTER TO CFDesc;
    CFDesc = RECORD
      constantPool: ARRAY CpMax OF BYTE;
      cpCount, cpIndex: INTEGER;
      access: INTEGER;
      thisIndex, superIndex, sourceFileIndex: INTEGER;
      methods: ARRAY MethodsMax OF BYTE;
      methIndex, methCount: INTEGER;
      fields: ARRAY FieldsMax OF BYTE;
      fieldsIndex, fieldsCount: INTEGER;
      cpCache, procMap: CpCache.Cache;
    END;
    MethodInfo* = POINTER TO MethodInfoDesc;
    MethodInfoDesc = RECORD
      cf: CF;
      access: INTEGER;
      name: ARRAY OJS.IdLen OF CHAR;
      descriptor: ARRAY DescLenMax OF CHAR;
      code: ARRAY CodeMax OF BYTE;
      i*: INTEGER;
      maxStack, curStack*, maxLocals: INTEGER;
      lineNumTab: ARRAY LineNumTabMax OF BYTE;
      lineIndex: INTEGER;
    END;

  VAR classMap: CpCache.Cache;

  PROCEDURE Init*;
  BEGIN
    NEW(classMap)
  END Init;

  PROCEDURE lengthUTF8(s: ARRAY OF CHAR; add0X: BOOLEAN): INTEGER;
    VAR
      i,j, length: INTEGER;
      c: CHAR;
  BEGIN
    length := LEN(s);
    i := 0;
    j := 0;
    WHILE (j < length) & (s[j] # 0X) DO
      c := s[j];
      IF (c >= 1X) & (c <= 7FX) THEN INC(i)
      ELSIF c > 7FFX THEN INC(i,3)
      ELSE INC(i, 2)
      END;
      INC(j);
    END;
    IF add0X THEN INC(i, 2) END
    RETURN i
  END lengthUTF8;

  PROCEDURE putUTF8(VAR buf: ARRAY OF BYTE; i: INTEGER; s: ARRAY OF CHAR;
                    add0X: BOOLEAN): INTEGER;
    VAR
      j, c, slen, buflen: INTEGER;
  BEGIN
    slen := LEN(s);
    buflen := LEN(buf);
    j := 0;
    WHILE (j < slen) & (ORD(s[j]) # 0H) DO
      c := ORD(s[j]);
      IF (c >= 1H) & (c <= 7FH) & (i < buflen) THEN
        buf[i] := c;
        INC(i)
      ELSIF (c > 7FFH) & (i+2 < buflen) THEN
        buf[i] := BOR(0E0H, AND(ASR(c, 12), 0FH));
        buf[i+1] := BOR(80H, AND(ASR(c, 6), 3FH));
        buf[i+2] := BOR(80H, AND(c, 3FH));
        INC(i, 3)
      ELSIF (c >= 80H) & (c <= 7FFH) & (i+1 < buflen) THEN
        buf[i] := BOR(0C0H, AND(ASR(c, 6), 1FH));
        buf[i+1] := BOR(80H, AND(c, 3FH));
        INC(i, 2)
      ELSE
        OJS.Mark("Class file buffer limit reached");
        j := slen
      END;
      INC(j);
    END;
    IF add0X & (i+1 < buflen) THEN
      buf[i] := 0C0H;
      buf[i+1] := 80H;
      INC(i, 2)
    END
    RETURN i
  END putUTF8;

  PROCEDURE putByte(VAR buf: ARRAY OF BYTE; i, x: INTEGER): INTEGER;
  BEGIN
    IF i < LEN(buf) THEN
      buf[i] := x;
      INC(i)
    ELSE OJS.Mark("Class file buffer limit reached") END
    RETURN i
  END putByte;

  PROCEDURE putNBytes(VAR buf: ARRAY OF BYTE; i: INTEGER; x: BYTE;
                      n: INTEGER): INTEGER;
  BEGIN
    n := n + i;
    IF n-1 < LEN(buf) THEN
      WHILE(i < n) DO
        buf[i] := x;
        INC(i)
      END
    ELSE OJS.Mark("Class file buffer limit reached") END
    RETURN i
  END putNBytes;

  PROCEDURE putInt(VAR buf: ARRAY OF BYTE; i, x: INTEGER): INTEGER;
  BEGIN
    IF i+3 < LEN(buf) THEN
      buf[i] := ASR(x, 24);
      buf[i+1] := ASR(x, 16);
      buf[i+2] := ASR(x, 8);
      buf[i+3] := x;
      INC(i, 4)
    ELSE OJS.Mark("Class file buffer limit reached") END
    RETURN i
  END putInt;

  PROCEDURE putShort(VAR buf: ARRAY OF BYTE; i, x: INTEGER): INTEGER;
  BEGIN
    IF i+1 < LEN(buf) THEN
      buf[i] := ASR(x, 8);
      buf[i+1] := x;
      INC(i, 2)
    ELSE OJS.Mark("Class file buffer limit reached") END
    RETURN i
  END putShort;

  PROCEDURE putArray(VAR buf: ARRAY OF BYTE; i: INTEGER; x: ARRAY OF BYTE;
                     len: INTEGER): INTEGER;
    VAR j: INTEGER;
  BEGIN
    j := 0;
    IF i+len-1 < LEN(buf) THEN
      WHILE j < len DO
        buf[i+j] := x[j];
        INC(j)
      END;
      INC(i, j)
    ELSE OJS.Mark("Class file buffer limit reached") END
    RETURN i
  END putArray;

  PROCEDURE cpWriteUTF8(cf: CF; s: ARRAY OF CHAR; add0X: BOOLEAN): INTEGER;
    VAR
      i, z: INTEGER;
      key: CpCache.Key;
  BEGIN
    z := Strings.Write(s, key, 0);
    IF add0X THEN
      z := Strings.WriteChar("$", key, z)
    END;
    z := Strings.WriteInt(UTF8, 0, key, z);
    IF z = -1 THEN
      OJS.Mark("internal cache buffer limit reached")
    END;
    i := CpCache.get(cf.cpCache, key);
    IF i = -1 THEN
      i := cf.cpCount;
      cf.cpIndex := putByte(cf.constantPool, cf.cpIndex, UTF8);
      cf.cpIndex := putShort(cf.constantPool, cf.cpIndex, lengthUTF8(s, add0X));
      cf.cpIndex := putUTF8(cf.constantPool, cf.cpIndex, s, add0X);
      INC(cf.cpCount);
      CpCache.put(cf.cpCache, key, i);
    END
    RETURN i
  END cpWriteUTF8;

  PROCEDURE cpWriteClass(cf: CF; s: ARRAY OF CHAR): INTEGER;
    VAR
      i, j, z: INTEGER;
      key: CpCache.Key;
  BEGIN
    z := Strings.Write(s, key, 0);
    z := Strings.WriteInt(CLASS, 0, key, z);
    IF z = -1 THEN
      OJS.Mark("internal cache buffer limit reached")
    END;
    j := CpCache.get(cf.cpCache, key);
    IF j = -1 THEN
      i := cpWriteUTF8(cf, s, FALSE);
      j := cf.cpCount;
      cf.cpIndex := putByte(cf.constantPool, cf.cpIndex, CLASS);
      cf.cpIndex := putShort(cf.constantPool, cf.cpIndex, i);
      INC(cf.cpCount);
      CpCache.put(cf.cpCache, key, j)
    END
    RETURN j
  END cpWriteClass;

  PROCEDURE cpWriteNameAndType(cf: CF; name, desc: ARRAY OF CHAR): INTEGER;
    VAR
      i, j, k, z: INTEGER;
      key: CpCache.Key;
  BEGIN
    z := Strings.Write(name, key, 0);
    z := Strings.Write(desc, key, z);
    z := Strings.WriteInt(NAMExTYPE, 0, key, z);
    IF z = -1 THEN
      OJS.Mark("internal cache buffer limit reached")
    END;
    k := CpCache.get(cf.cpCache, key);
    IF k = -1 THEN
      i := cpWriteUTF8(cf, name, FALSE);
      j := cpWriteUTF8(cf, desc, FALSE);
      k := cf.cpCount;
      cf.cpIndex := putByte(cf.constantPool, cf.cpIndex, NAMExTYPE);
      cf.cpIndex := putShort(cf.constantPool, cf.cpIndex, i);
      cf.cpIndex := putShort(cf.constantPool, cf.cpIndex, j);
      INC(cf.cpCount);
      CpCache.put(cf.cpCache, key, k)
    END
    RETURN k
  END cpWriteNameAndType;

  PROCEDURE cpWriteString(cf: CF; val: ARRAY OF CHAR; add0X: BOOLEAN): INTEGER;
    VAR
      i, j, z: INTEGER;
      key: CpCache.Key;
  BEGIN
    z := Strings.Write(val, key, 0);
    IF add0X THEN
      z := Strings.WriteChar("$", key, z)
    END;
    z := Strings.WriteInt(STR, 0, key, z);
    IF z = -1 THEN
      OJS.Mark("internal cache buffer limit reached")
    END;
    j := CpCache.get(cf.cpCache, key);
    IF j = -1 THEN
      i := cpWriteUTF8(cf, val, add0X);
      j := cf.cpCount;
      cf.cpIndex := putByte(cf.constantPool, cf.cpIndex, STR);
      cf.cpIndex := putShort(cf.constantPool, cf.cpIndex, i);
      INC(cf.cpCount);
      CpCache.put(cf.cpCache, key, j)
    END
    RETURN j
  END cpWriteString;

  PROCEDURE cpWriteConst(cf: CF; tag, val: INTEGER): INTEGER;
    VAR
      i, z: INTEGER;
      key: CpCache.Key;
  BEGIN
    z := Strings.WriteInt(tag, 0, key, 0);
    z := Strings.WriteInt(val, 0, key, z);
    IF z = -1 THEN
      OJS.Mark("internal cache buffer limit reached")
    END;
    i := CpCache.get(cf.cpCache, key);
    IF i = -1 THEN
      i := cf.cpCount;
      cf.cpIndex := putByte(cf.constantPool, cf.cpIndex, tag);
      cf.cpIndex := putInt(cf.constantPool, cf.cpIndex, val);
      INC(cf.cpCount);
      CpCache.put(cf.cpCache, key, i)
    END
    RETURN i
  END cpWriteConst;

  PROCEDURE cpWriteRef(cf: CF; tag: INTEGER;
                       owner, name, desc: ARRAY OF CHAR): INTEGER;
    VAR
      i, j, k, z: INTEGER;
      key: CpCache.Key;
  BEGIN
    z := Strings.Write(owner, key, 0);
    z := Strings.Write(name, key, z);
    z := Strings.Write(desc, key, z);
    z := Strings.WriteInt(tag, 0, key, z);
    IF z = -1 THEN
      OJS.Mark("internal cache buffer limit reached")
    END;
    k := CpCache.get(cf.cpCache, key);
    IF k = -1 THEN
      i := cpWriteClass(cf, owner);
      j := cpWriteNameAndType(cf, name, desc);
      k := cf.cpCount;
      cf.cpIndex := putByte(cf.constantPool, cf.cpIndex, tag);
      cf.cpIndex := putShort(cf.constantPool, cf.cpIndex, i);
      cf.cpIndex := putShort(cf.constantPool, cf.cpIndex, j);
      INC(cf.cpCount);
      CpCache.put(cf.cpCache, key, k)
    END
    RETURN k
  END cpWriteRef;

  PROCEDURE cpWriteFiledRef(cf: CF; owner, name, desc: ARRAY OF CHAR): INTEGER;
    RETURN cpWriteRef(cf, FIELD, owner, name, desc)
  END cpWriteFiledRef;

  PROCEDURE cpWriteMethodRef(cf: CF; owner, name, desc: ARRAY OF CHAR): INTEGER;
    RETURN cpWriteRef(cf, METH, owner, name, desc)
  END cpWriteMethodRef;

  PROCEDURE addField*(cf: CF; access: INTEGER; name, desc: ARRAY OF CHAR);
  BEGIN
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex, access);
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex,
                               cpWriteUTF8(cf, name, FALSE));
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex,
                               cpWriteUTF8(cf, desc, FALSE));
    (* attribute_count *)
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex, 0);
    INC(cf.fieldsCount)
  END addField;

  PROCEDURE addConstField*(cf: CF; name, desc: ARRAY OF CHAR; val: INTEGER);
    VAR i: INTEGER;
  BEGIN
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex,
                               Opcodes.ACCxPUBLIC + Opcodes.ACCxFINAL +
                               Opcodes.ACCxSTATIC);
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex,
                               cpWriteUTF8(cf, name, FALSE));
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex,
                               cpWriteUTF8(cf, desc, FALSE));
    (* attribute_count: ConstantValue *)
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex, 1);
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex,
                               cpWriteUTF8(cf, "ConstantValue", FALSE));
    cf.fieldsIndex := putInt(cf.fields, cf.fieldsIndex, 2);
    IF desc[0] = "F" THEN
      i := cpWriteConst(cf, FLOAT, val)
    ELSE
      i := cpWriteConst(cf, INT, val)
    END;
    cf.fieldsIndex := putShort(cf.fields, cf.fieldsIndex, i);
    INC(cf.fieldsCount)
  END addConstField;

  PROCEDURE finalizeMethod*(cf: CF; mi: MethodInfo);
  BEGIN
    cf.methIndex := putShort(cf.methods, cf.methIndex, mi.access);
    cf.methIndex := putShort(cf.methods, cf.methIndex,
                             cpWriteUTF8(cf, mi.name, FALSE));
    cf.methIndex := putShort(cf.methods, cf.methIndex,
                             cpWriteUTF8(cf, mi.descriptor, FALSE));
    IF AND(mi.access, Opcodes.ACCxABSTRACT) = 0 THEN  (* is abstract? *)
      (* attribute_count: code *)
      cf.methIndex := putShort(cf.methods, cf.methIndex, 1);
      cf.methIndex := putShort(cf.methods, cf.methIndex,
                               cpWriteUTF8(cf, "Code", FALSE));
      (* attribute_length *)
      cf.methIndex := putInt(cf.methods, cf.methIndex,
                            20 + mi.i + mi.lineIndex);
      cf.methIndex := putShort(cf.methods, cf.methIndex, mi.maxStack);
      cf.methIndex := putShort(cf.methods, cf.methIndex, mi.maxLocals);
      cf.methIndex := putInt(cf.methods, cf.methIndex, mi.i);
      cf.methIndex := putArray(cf.methods, cf.methIndex, mi.code, mi.i);
      (* exception_table_length *)
      cf.methIndex := putShort(cf.methods, cf.methIndex, 0);
      (* attribute_count: LineNumberTable *)
      cf.methIndex := putShort(cf.methods, cf.methIndex, 1);
      cf.methIndex := putShort(cf.methods, cf.methIndex,
                               cpWriteUTF8(cf, "LineNumberTable", FALSE));
      (* attribute_length *)
      cf.methIndex := putInt(cf.methods, cf.methIndex,  2 + mi.lineIndex);
      (* line_number_table_length *)
      cf.methIndex := putShort(cf.methods, cf.methIndex,  mi.lineIndex DIV 4);
      cf.methIndex := putArray(cf.methods, cf.methIndex,
                               mi.lineNumTab, mi.lineIndex)
    ELSE
      (* attribute_count: code *)
      cf.methIndex := putShort(cf.methods, cf.methIndex, 0)
    END;
    INC(cf.methCount)
  END finalizeMethod;

  PROCEDURE toFile*(cf: CF; path: ARRAY OF CHAR);
    VAR
      out: ARRAY ClassMax OF BYTE;
      i, err, sourceFile: INTEGER;
      f: Files.File;
  BEGIN
    (* CpCache.debug(cf.cpCache); *)
    sourceFile := cpWriteUTF8(cf, "SourceFile", FALSE);
    i := putInt(out, 0, 0CAFEBABEH); (* magic *)
    i := putInt(out, i, 49); (* Java 1.5 *)
    i := putShort(out, i, cf.cpCount);
    i := putArray(out, i, cf.constantPool, cf.cpIndex);
    i := putShort(out, i, cf.access);
    i := putShort(out, i, cf.thisIndex);
    i := putShort(out, i, cf.superIndex);
    i := putShort(out, i, 0); (* interfaces_count *)
    i := putShort(out, i, cf.fieldsCount);
    i := putArray(out, i, cf.fields, cf.fieldsIndex);
    i := putShort(out, i, cf.methCount);
    i := putArray(out, i, cf.methods, cf.methIndex);
    i := putShort(out, i, 1); (* attributes_count: SourceFile *)
    i := putShort(out, i, sourceFile);
    i := putInt(out, i, 2); (* attribute_length *)
    i := putShort(out, i, cf.sourceFileIndex);
    err := Files.IOERROR;
    IF OJS.errcnt = 0 THEN
      f := Files.Create(path);
      IF f # NIL THEN
        Files.WriteNBytes(f, out, i);
        Files.Close(f);
        err := Files.Status(f)
      END
    END;
    IF (err # Files.OK) & (OJS.errcnt = 0) THEN
      OJS.MarkAppend("Failed to write ", path)
    END
  END toFile;

  PROCEDURE NewCF*(acc: INTEGER; n, sn: ARRAY OF CHAR): CF;
    VAR
      cf: CF;
      className: Descriptor;
  BEGIN
    NEW(cf);
    Strings.Append(n, className);
    Strings.Append(".Mod", className);
    cf.access := acc;
    cf.cpCount := 1;
    cf.cpCache := CpCache.New();
    cf.procMap := CpCache.New();
    cf.methCount := 0;
    cf.fieldsCount := 0;
    cf.thisIndex := cpWriteClass(cf, n);
    cf.sourceFileIndex := cpWriteUTF8(cf, className, FALSE);
    cf.superIndex := cpWriteClass(cf, sn);
    IF CpCache.get(classMap, n) = 1 THEN
      OJS.Mark("type names must be unique")
    ELSE
      CpCache.put(classMap, n, 1)
    END
    RETURN cf
  END NewCF;

  PROCEDURE NewMI*(classFormat: CF; acc: INTEGER;
                   n, desc: ARRAY OF CHAR): MethodInfo;
    VAR mi: MethodInfo;
  BEGIN
    NEW(mi);
    mi.cf := classFormat;
    mi.access := acc;
    mi.name := n;
    mi.descriptor := desc;
    mi.maxStack := 0;
    mi.maxLocals := 0;
    mi.curStack := 0;
    mi.lineIndex := 0;
    mi.i := 0;
    IF CpCache.get(mi.cf.procMap, mi.name) = 1 THEN
      OJS.Mark("procedure names must be unique")
    ELSE
      CpCache.put(mi.cf.procMap, mi.name, 1)
    END
    RETURN mi
  END NewMI;

  PROCEDURE setMaxStack(mi: MethodInfo);
  BEGIN
    IF mi.curStack > mi.maxStack THEN
      mi.maxStack := mi.curStack
    END
  END setMaxStack;

  PROCEDURE fix(mi: MethodInfo; at, with: INTEGER);
    VAR x: INTEGER;
  BEGIN
    x := putShort(mi.code, at+1, with)
  END fix;

  PROCEDURE FixLink*(mi: MethodInfo; L: INTEGER);
    VAR L1: INTEGER;
  BEGIN
    WHILE (L # 0) & (OJS.errcnt = 0) DO
      L1 := BOR(LSL(mi.code[L + 1], 8), mi.code[L + 2]);
      fix(mi, L, mi.i-L);
      L := L1
    END
  END FixLink;

  PROCEDURE FixLinkWith*(mi: MethodInfo; L0, dst: INTEGER);
    VAR L1: INTEGER;
  BEGIN
    WHILE (L0 # 0) & (OJS.errcnt = 0) DO
      L1 := BOR(LSL(mi.code[L0 + 1], 8), mi.code[L0 + 2]);
      fix(mi, L0, dst-L0);
      L0 := L1
    END
  END FixLinkWith;

  PROCEDURE merged*(mi: MethodInfo; L0, L1: INTEGER): INTEGER;
    VAR L2, L3: INTEGER;
  BEGIN
    IF L0 # 0 THEN
      L3 := L0;
      REPEAT
        L2 := L3;
        L3 := BOR(LSL(mi.code[L2 + 1], 8), mi.code[L2 + 2]);
      UNTIL L3 = 0;
      fix(mi, L2, L1);
      L1 := L0
    END
    RETURN L1
  END merged;

  PROCEDURE putMethodInsn*(mi: MethodInfo; opcode: INTEGER;
                           owner, name, desc: ARRAY OF CHAR; args: INTEGER);
  BEGIN
    IF (opcode = Opcodes.INVOKEVIRTUAL) OR
       (opcode = Opcodes.INVOKESPECIAL) OR
       (opcode = Opcodes.INVOKEINTERFACE) THEN
      mi.curStack := mi.curStack - (args + 1)
    ELSE
      mi.curStack := mi.curStack - args;
    END;
    IF desc[Strings.Length(desc)-1] # "V" THEN
      INC(mi.curStack)
    END;
    setMaxStack(mi);
    mi.i := putByte(mi.code, mi.i, opcode);
    mi.i := putShort(mi.code, mi.i, cpWriteMethodRef(mi.cf, owner, name, desc));
  END putMethodInsn;

  PROCEDURE addLineNumber*(mi: MethodInfo; line: INTEGER);
  BEGIN
    mi.lineIndex := putShort(mi.lineNumTab, mi.lineIndex, mi.i);
    mi.lineIndex := putShort(mi.lineNumTab, mi.lineIndex, line)
  END addLineNumber;

  PROCEDURE incStack(mi: MethodInfo; opcode: INTEGER);
  BEGIN
    CASE opcode OF
      Opcodes.AALOAD, Opcodes.ASTORE, Opcodes.ATHROW, Opcodes.BALOAD,
      Opcodes.CALOAD, Opcodes.DADD, Opcodes.DALOAD, Opcodes.DCMPG,
      Opcodes.DCMPL, Opcodes.DDIV, Opcodes.DMUL, Opcodes.DREM, Opcodes.DSTORE,
      Opcodes.DSUB, Opcodes.FADD, Opcodes.FALOAD, Opcodes.FCMPG, Opcodes.FCMPL,
      Opcodes.FDIV, Opcodes.FMUL, Opcodes.FREM, Opcodes.FSTORE, Opcodes.FSUB,
      Opcodes.IADD, Opcodes.IALOAD, Opcodes.IAND, Opcodes.IDIV, Opcodes.IFEQ,
      Opcodes.IFGE, Opcodes.IFGT, Opcodes.IFLE, Opcodes.IFLT, Opcodes.IFNE,
      Opcodes.IFNONNULL, Opcodes.IFNULL, Opcodes.IMUL, Opcodes.IOR,
      Opcodes.IREM, Opcodes.ISHL, Opcodes.ISHR, Opcodes.ISTORE, Opcodes.ISUB,
      Opcodes.IUSHR, Opcodes.IXOR, Opcodes.LADD, Opcodes.LALOAD, Opcodes.LAND,
      Opcodes.LCMP, Opcodes.LDIV, Opcodes.LMUL, Opcodes.LOOKUPSWITCH,
      Opcodes.LOR, Opcodes.LREM, Opcodes.LSHL, Opcodes.LSHR, Opcodes.LSTORE,
      Opcodes.LSUB, Opcodes.LUSHR, Opcodes.LXOR, Opcodes.MONITORENTER,
      Opcodes.MONITOREXIT, Opcodes.POP, Opcodes.PUTSTATIC, Opcodes.SALOAD,
      Opcodes.TABLESWITCH:
        INC(mi.curStack, -1)
    | Opcodes.IFACMPEQ, Opcodes.IFACMPNE, Opcodes.IFICMPEQ,
      Opcodes.IFICMPGE, Opcodes.IFICMPGT, Opcodes.IFICMPLE,
      Opcodes.IFICMPLT, Opcodes.IFICMPNE, Opcodes.POP2, Opcodes.PUTFIELD:
        INC(mi.curStack, -2)
    | Opcodes.AASTORE, Opcodes.BASTORE, Opcodes.CASTORE, Opcodes.DASTORE,
      Opcodes.FASTORE, Opcodes.IASTORE, Opcodes.LASTORE, Opcodes.SASTORE:
        INC(mi.curStack, -3)
    | Opcodes.DUP2, Opcodes.DUP2X1, Opcodes.DUP2X2:
        INC(mi.curStack, 2)
    | Opcodes.ACONSTNULL, Opcodes.ALOAD, Opcodes.BIPUSH, Opcodes.DCONST0,
      Opcodes.DCONST1, Opcodes.DLOAD, Opcodes.DUP, Opcodes.DUPX1,
      Opcodes.DUPX2, Opcodes.FCONST0, Opcodes.FCONST1, Opcodes.FCONST2,
      Opcodes.FLOAD, Opcodes.GETSTATIC, Opcodes.ICONSTM1, Opcodes.ICONST0,
      Opcodes.ICONST1, Opcodes.ICONST2, Opcodes.ICONST3, Opcodes.ICONST4,
      Opcodes.ICONST5, Opcodes.ILOAD, Opcodes.JSR, Opcodes.LCONST0,
      Opcodes.LCONST1, Opcodes.LDC, Opcodes.LLOAD, Opcodes.NEW, Opcodes.SIPUSH:
        INC(mi.curStack, 1)
    | Opcodes.ANEWARRAY, Opcodes.ARETURN, Opcodes.ARRAYLENGTH,
      Opcodes.CHECKCAST, Opcodes.D2F, Opcodes.D2I, Opcodes.D2L, Opcodes.DNEG,
      Opcodes.DRETURN, Opcodes.F2D, Opcodes.F2I, Opcodes.F2L, Opcodes.FNEG,
      Opcodes.FRETURN, Opcodes.GETFIELD, Opcodes.GOTO, Opcodes.I2B, Opcodes.I2C,
      Opcodes.I2D, Opcodes.I2F, Opcodes.I2L, Opcodes.I2S, Opcodes.IINC,
      Opcodes.INEG, Opcodes.INSTANCEOF, Opcodes.IRETURN, Opcodes.L2D,
      Opcodes.L2F, Opcodes.L2I, Opcodes.LNEG, Opcodes.LRETURN, Opcodes.NEWARRAY,
      Opcodes.NOP, Opcodes.RET, Opcodes.RETURNx, Opcodes.SWAP, Opcodes.WIDE:
        (* nothing to do *)
    END;
    setMaxStack(mi)
  END incStack;

  PROCEDURE putTypeInsn*(mi: MethodInfo; opcode: INTEGER; type: ARRAY OF CHAR);
  BEGIN
    incStack(mi, opcode);
    mi.i := putByte(mi.code, mi.i, opcode);
    mi.i := putShort(mi.code, mi.i, cpWriteClass(mi.cf, type))
  END putTypeInsn;

  PROCEDURE putMultiANewArrayInsn*(mi: MethodInfo; desc: ARRAY OF CHAR;
                                   dims: INTEGER);
  BEGIN
    mi.curStack := mi.curStack - (dims - 1);
    setMaxStack(mi);
    mi.i := putByte(mi.code, mi.i, Opcodes.MULTIANEWARRAY);
    mi.i := putShort(mi.code, mi.i, cpWriteClass(mi.cf, desc));
    mi.i := putByte(mi.code, mi.i, dims)
  END putMultiANewArrayInsn;

  PROCEDURE putTableSwitchInsn*(mi: MethodInfo; min, max, dflt, nLables: INTEGER;
                                labels: ARRAY OF INTEGER);
    VAR j: INTEGER;
   BEGIN
    incStack(mi, Opcodes.TABLESWITCH);
    mi.i := putByte(mi.code, mi.i, Opcodes.TABLESWITCH);
    mi.i := putNBytes(mi.code, mi.i, 0, (4 - mi.i MOD 4) MOD 4);
    mi.i := putInt(mi.code, mi.i, dflt);
    mi.i := putInt(mi.code, mi.i, min);
    mi.i := putInt(mi.code, mi.i, max);
    FOR j := 0 TO nLables-1 DO
      mi.i := putInt(mi.code, mi.i, labels[j])
    END
  END putTableSwitchInsn;

  PROCEDURE putIincInsn*(mi: MethodInfo; var, increment: INTEGER);
  BEGIN
    incStack(mi, Opcodes.IINC);
    mi.i := putByte(mi.code, mi.i, Opcodes.IINC);
    mi.i := putByte(mi.code, mi.i, var);
    mi.i := putByte(mi.code, mi.i, increment)
  END putIincInsn;

  PROCEDURE putLdcInsnInt*(mi: MethodInfo; type, c: INTEGER);
    VAR x: INTEGER;
  BEGIN
    incStack(mi, Opcodes.LDC);
    x := cpWriteConst(mi.cf, type, c);
    IF x <= 255 THEN
      mi.i := putByte(mi.code, mi.i, Opcodes.LDC);
      mi.i := putByte(mi.code, mi.i, x)
    ELSE
      mi.i := putByte(mi.code, mi.i, Opcodes.LDCW);
      mi.i := putShort(mi.code, mi.i, x)
    END
  END putLdcInsnInt;

  PROCEDURE putLdcInsnStr*(mi: MethodInfo; c: ARRAY OF CHAR; add0X: BOOLEAN);
    VAR x: INTEGER;
  BEGIN
    incStack(mi, Opcodes.LDC);
    x := cpWriteString(mi.cf, c, add0X);
    IF x <= 255 THEN
      mi.i := putByte(mi.code, mi.i, Opcodes.LDC);
      mi.i := putByte(mi.code, mi.i, x)
    ELSE
      mi.i := putByte(mi.code, mi.i, Opcodes.LDCW);
      mi.i := putShort(mi.code, mi.i, x)
    END
  END putLdcInsnStr;

  PROCEDURE putVarInsn*(mi: MethodInfo; opcode, var: INTEGER);
    VAR opt: INTEGER;
  BEGIN
    incStack(mi, opcode);
    IF var < 4 THEN
      IF opcode < Opcodes.ISTORE THEN
        (* ILOAD_0 *)
        opt := 26 + LSL((opcode - Opcodes.ILOAD), 2) + var
      ELSE
        (* ISTORE_0 *)
        opt := 59 + LSL((opcode - Opcodes.ISTORE), 2) + var
      END;
      mi.i := putByte(mi.code, mi.i, opt)
    ELSE
      mi.i := putByte(mi.code, mi.i, opcode);
      mi.i := putByte(mi.code, mi.i, var)
    END
  END putVarInsn;

  PROCEDURE putFieldInsn*(mi: MethodInfo; opcode: INTEGER;
                          owner, name, desc: ARRAY OF CHAR);
  BEGIN
    incStack(mi, opcode);
    mi.i := putByte(mi.code, mi.i, opcode);
    mi.i := putShort(mi.code, mi.i, cpWriteFiledRef(mi.cf, owner, name, desc))
  END putFieldInsn;

  PROCEDURE putIntInsn*(mi: MethodInfo; opcode, operand: INTEGER);
  BEGIN
    incStack(mi, opcode);
    mi.i := putByte(mi.code, mi.i, opcode);
    IF opcode = Opcodes.SIPUSH THEN
      mi.i := putByte(mi.code, mi.i, ASR(operand, 8));
      mi.i := putByte(mi.code, mi.i, operand)
    ELSE (* BIPUSH or NEWARRAY *)
      mi.i := putByte(mi.code, mi.i, operand)
    END
  END putIntInsn;

  PROCEDURE putJumpInsn*(mi: MethodInfo; opcode, to: INTEGER);
  BEGIN
    incStack(mi, opcode);
    mi.i := putByte(mi.code, mi.i, opcode);
    mi.i := putShort(mi.code, mi.i, to)
  END putJumpInsn;

  PROCEDURE putGotoInsn*(mi: MethodInfo; to, incr: INTEGER);
  BEGIN
    INC(mi.curStack, incr);
    IF to <= ShortMaxValue THEN
      mi.i := putByte(mi.code, mi.i, Opcodes.GOTO);
      mi.i := putShort(mi.code, mi.i, to)
    ELSE
      mi.i := putByte(mi.code, mi.i, Opcodes.GOTOW);
      mi.i := putInt(mi.code, mi.i, to)
    END
  END putGotoInsn;

  PROCEDURE putInsn*(mi: MethodInfo; opcode: INTEGER);
  BEGIN
    incStack(mi, opcode);
    mi.i := putByte(mi.code, mi.i, opcode)
  END putInsn;

  PROCEDURE setMaxVars*(mi: MethodInfo; locals: INTEGER);
  BEGIN
    mi.maxLocals := locals
  END setMaxVars;
END ClassFormat.
