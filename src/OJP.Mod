(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

(*
  Parser of Oberon-JVM compiler. Uses Scanner OJS to obtain symbols (tokens),
  OJB for definition of data structures and for handling import and export, and
  OJG to produce bytecode. OJP performs type checking and data allocation.
  Parser is target-independent, except for part of the handling of allocations.
*)

MODULE OJP; (*Oberon compiler for JVM in Oberon-07*)
  IMPORT OJS, OJB, OJG, Strings;

  TYPE PtrBase = POINTER TO PtrBaseDesc;
    PtrBaseDesc = RECORD  (*list of names of pointer base types*)
      name: OJS.Ident; type: OJB.Type; next: PtrBase
    END ;

  VAR sym: INTEGER;   (*last symbol read*)
    level: INTEGER;
    newSF, isDefinition: BOOLEAN;
    expression: PROCEDURE (VAR x: OJG.Item);  (*to avoid forward reference*)
    Type: PROCEDURE (typedef: BOOLEAN): OJB.Type;
    FormalType: PROCEDURE (): OJB.Type;
    EqualSignatures: PROCEDURE (t0, t1: OJB.Type): BOOLEAN;
    modid: OJS.Ident;
    pbsList: PtrBase;   (*list of names of pointer base types*)
    dummy: OJB.Object;
    hasMain: BOOLEAN;

  PROCEDURE Check(s: INTEGER; msg: ARRAY OF CHAR);
  BEGIN
    IF sym = s THEN OJS.Get(sym) ELSE OJS.Mark(msg) END
  END Check;

  PROCEDURE qualident(VAR modName: ARRAY OF CHAR): OJB.Object;
    VAR obj, modObj: OJB.Object;
  BEGIN
    obj := OJB.thisObj(OJS.id); OJS.Get(sym);
    IF obj = NIL THEN OJS.Mark("undef"); obj := dummy END ;
    IF (sym = OJS.period) & (obj.class = OJB.Mod) THEN
      modObj := OJB.GetModFrom(obj);
      Strings.Copy(modObj.name, modName);
      OJS.Get(sym);
      IF sym = OJS.ident THEN obj := OJB.thisimport(obj, OJS.id); OJS.Get(sym);
        IF obj = NIL THEN OJS.Mark("undef"); obj := dummy END
      ELSE OJS.Mark("identifier expected"); obj := dummy
      END
    ELSE Strings.Copy(modid, modName)
    END
    RETURN obj
  END qualident;

  PROCEDURE CheckBool(VAR x: OJG.Item);
  BEGIN
    IF x.type.form # OJB.Bool THEN
      OJS.Mark("not Boolean"); x.type := OJB.boolType
    END
  END CheckBool;

  PROCEDURE CheckInt(VAR x: OJG.Item);
  BEGIN
    IF x.type.form # OJB.Int THEN
      OJS.Mark("not Integer"); x.type := OJB.intType
    END
  END CheckInt;

  PROCEDURE CheckByteRange(VAR x: OJG.Item);
  BEGIN
    IF (x.mode = OJB.Const) & ((x.a < 0) OR (x.a > 255)) THEN
      OJS.Mark("not a valid BYTE value")
    END
  END CheckByteRange;

  PROCEDURE CheckReal(VAR x: OJG.Item);
  BEGIN
    IF x.type.form # OJB.Real THEN
      OJS.Mark("not Real"); x.type := OJB.realType
    END
  END CheckReal;

  PROCEDURE CheckSet(VAR x: OJG.Item);
  BEGIN
    IF x.type.form # OJB.Set THEN OJS.Mark("not Set"); x.type := OJB.setType END
  END CheckSet;

  PROCEDURE CheckSetVal(VAR x: OJG.Item);
  BEGIN
    IF x.type.form # OJB.Int THEN OJS.Mark("not Int"); x.type := OJB.setType
    ELSIF x.mode = OJB.Const THEN
      IF (x.a < 0) OR (x.a >= OJG.MaxSetElement) THEN
        OJS.Mark("invalid set")
      END
    END
  END CheckSetVal;

  PROCEDURE CheckConst(VAR x: OJG.Item);
  BEGIN
    IF x.mode # OJB.Const THEN
      OJS.Mark("not a constant"); x.mode := OJB.Const
    END
  END CheckConst;

  PROCEDURE CheckReadOnly(VAR x: OJG.Item);
  BEGIN
    IF x.rdo THEN OJS.Mark("read-only") END
  END CheckReadOnly;

  PROCEDURE CheckExport(): BOOLEAN;
    VAR expo: BOOLEAN;
  BEGIN
    IF sym = OJS.times THEN
      expo := TRUE; OJS.Get(sym);
      IF level # 0 THEN OJS.Mark("remove asterisk") END
    ELSE expo := isDefinition
    END
    RETURN expo
  END CheckExport;

  PROCEDURE FindObjFrom(modid: ARRAY OF CHAR; VAR x: OJG.Item): OJB.Object;
    VAR obj: OJB.Object;
  BEGIN
    IF (x.mode = OJB.Var) OR (x.mode = OJB.Par) OR (x.mode = OJB.ParStruct) THEN
      obj := OJB.FindObj(modid, x.modName, x.name)
    ELSE
      obj := NIL
    END
    RETURN obj
  END FindObjFrom;

  PROCEDURE IsExtension(t0, t1: OJB.Type): BOOLEAN;
  BEGIN (*t1 is an extension of t0*)
    RETURN (t0 = t1) OR (t1 # NIL) & IsExtension(t0, t1.base)
  END IsExtension;

  (* expressions *)

  PROCEDURE TypeTest(VAR x: OJG.Item; T: OJB.Type; guard: BOOLEAN);
    VAR xt: OJB.Type;
  BEGIN xt := x.type;
    IF (T.form = xt.form) &
       ((T.form = OJB.Pointer) OR
        (T.form = OJB.Record) & (x.mode = OJB.ParStruct)) THEN
      WHILE (xt # T) & (xt # NIL) DO xt := xt.base END ;
      IF xt # T THEN xt := x.type;
        IF xt.form = OJB.Pointer THEN
          IF IsExtension(xt.base, T.base) THEN
            OJG.TypeTest(x, T.base, guard); x.type := T
          ELSE
            OJS.Mark("not an extension")
          END
        ELSIF (xt.form = OJB.Record) & (x.mode = OJB.ParStruct) THEN
          IF IsExtension(xt, T) THEN  OJG.TypeTest(x, T, guard); x.type := T
          ELSE OJS.Mark("not an extension")
          END
        ELSE OJS.Mark("incompatible types")
        END
      ELSIF ~guard THEN OJG.ConstTypeTest(x)
      END
    ELSE OJS.Mark("type mismatch")
    END ;
    IF ~guard THEN x.type := OJB.boolType END
  END TypeTest;

  PROCEDURE selector(VAR x: OJG.Item);
    VAR y: OJG.Item; obj: OJB.Object;
      modName: OJS.Ident;
  BEGIN
    WHILE (sym = OJS.lbrak) OR (sym = OJS.period) OR (sym = OJS.arrow)
        OR (sym = OJS.lparen) & (x.type.form IN {OJB.Record, OJB.Pointer}) DO
      IF sym = OJS.lbrak THEN
        REPEAT
          OJG.Index0(x);
          OJS.Get(sym); expression(y);
          IF x.type.form = OJB.Array THEN
            CheckInt(y); OJG.Index(x, y); x.type := x.type.base
          ELSE OJS.Mark("not an array")
          END
        UNTIL sym # OJS.comma;
        Check(OJS.rbrak, "no ]")
      ELSIF sym = OJS.period THEN OJS.Get(sym);
        IF sym = OJS.ident THEN
          IF x.type.form = OJB.Pointer THEN x.type := x.type.base END ;
          IF x.type.form = OJB.Record THEN
            obj := OJB.thisfield(x.type); OJS.Get(sym);
            IF obj # NIL THEN OJG.FieldAccess(x, obj); x.type := obj.type
            ELSE OJS.Mark("undef")
            END
          ELSE OJS.Mark("not a record")
          END
        ELSE OJS.Mark("ident?")
        END
      ELSIF sym = OJS.arrow THEN
        OJS.Get(sym);
        IF x.type.form = OJB.Pointer THEN x.type := x.type.base
        ELSE OJS.Mark("not a pointer")
        END
      ELSE (*type guard*)
        OJS.Get(sym);
        IF sym = OJS.ident THEN
          obj := qualident(modName);
          IF obj.class = OJB.Typ THEN
            TypeTest(x, obj.type, TRUE)
          ELSE
            OJS.Mark("guard type expected")
          END
        ELSE OJS.Mark("not an identifier")
        END ;
        Check(OJS.rparen, " ) missing")
      END
    END
  END selector;

  (* Type Rule A, B *)
  PROCEDURE EqualTypes(t0, t1: OJB.Type): BOOLEAN;
  BEGIN
    RETURN (t0 = t1)
           OR (t0.form = OJB.Array) & (t1.form = OJB.Array) &
              (t0.len = t1.len) & EqualTypes(t0.base, t1.base)
           OR (t0.form = OJB.Proc) & (t1.form = OJB.Proc) &
              EqualSignatures(t0, t1)
           OR (t0.form = OJB.Pointer) & (t1.form = OJB.Pointer) &
              EqualTypes(t0.base, t1.base)
  END EqualTypes;


  (* Type Rule F.1, F.2 *)
  PROCEDURE CompatibleOpenArrays(t0, t1: OJB.Type): BOOLEAN;
  BEGIN
    RETURN EqualTypes(t0, t1)
           OR (t0.form = OJB.Array) & (t1.form = OJB.Array) & (t1.len < 0) &
              CompatibleOpenArrays(t0.base, t1.base)
  END CompatibleOpenArrays;

  PROCEDURE EqualSignatures0(t0, t1: OJB.Type): BOOLEAN;
    VAR p0, p1: OJB.Object; com: BOOLEAN;
  BEGIN com := TRUE;
    (* Type Rule C.1, C.2 *)
    IF (t0.nofpar = t1.nofpar) & EqualTypes(t0.base, t1.base) THEN
      p0 := t0.dsc; p1 := t1.dsc;
      WHILE p0 # NIL DO
        (* Type Rule C.3, C.4 *)
        IF (p0.class = p1.class) & (p0.rdo = p1.rdo) &
           EqualTypes(p0.type, p1.type)
        THEN p0 := p0.next; p1 := p1.next
        ELSE p0 := NIL; com := FALSE
        END
      END
    ELSE com := FALSE
    END ;
    RETURN com
  END EqualSignatures0;

  PROCEDURE CompTypes(t0, t1: OJB.Type; varpar: BOOLEAN): BOOLEAN;
  BEGIN (*check for assignment compatibility*)
    (* Type Rule E.1, E.2, E.3, E.4 *)
    RETURN ~((t0.form = OJB.Array) & (t1.form = OJB.Array) & (t0.len < 0) &
             (t1.len < 0)) & EqualTypes(t0, t1)
      OR (t0.form = OJB.Record) & (t1.form = OJB.Record) & IsExtension(t0, t1)
      OR ~varpar &
        ((t0.form = OJB.Pointer) & (t1.form = OJB.Pointer) &
          IsExtension(t0.base, t1.base)
        OR (t0.form IN {OJB.Pointer, OJB.Proc}) & (t1.form = OJB.NilTyp))
  END CompTypes;

  PROCEDURE Parameter(par: OJB.Object);
    VAR x: OJG.Item; varpar: BOOLEAN;
  BEGIN
    expression(x);
    IF par # NIL THEN
      varpar := (par.class = OJB.Par) OR (par.class = OJB.ParStruct);
      IF CompTypes(par.type, x.type, varpar) OR    (* Type Rule G.1, G.2, G.3 *)
         CompatibleOpenArrays(x.type, par.type) THEN (* Type Rule F.1, F.2 *)
        IF varpar & x.rdo THEN OJS.Mark("read only actual parameter")
        ELSIF ~varpar OR (par.class = OJB.ParStruct) THEN
          IF x.mode = OJB.Typ THEN OJS.Mark("illegal value parameter") END ;
          OJG.ValueParam(x)
        ELSE (*par.class = Par*)
          IF ~par.rdo THEN CheckReadOnly(x) END ;
          OJG.VarParam(x)
        END
      (* Type Rule F.3  *)
      ELSIF (x.type.form = OJB.String) & par.rdo & (par.type.form = OJB.Array) &
            (par.type.base.form = OJB.Char) & (par.type.len < 0) THEN
        OJG.StringParam(x)
      (* Type Rule F.3, J *)
      ELSIF (x.type.form = OJB.Char) & x.rdo & par.rdo &
            (par.type.form = OJB.Array) & (par.type.base.form = OJB.Char) &
            (par.type.len < 0) THEN
        OJG.CharToStr(x);
        OJG.StringParam(x)
      (*
        ~varpar below to prevent this:
           PROCEDURE P(VAR n: INTEGER);  ...  n := ...    uses a STR instruction
           P(b)     STR overwrites bytes around byte variable b
      *)
      (* Type Rule I, G.2 *) (*BYTE*)
      ELSIF ~varpar & (par.type.form = OJB.Int) & (x.type.form = OJB.Int) THEN
        IF par.type = OJB.byteType THEN CheckByteRange(x) END;
        OJG.ValueParam(x)
      (* Type Rule J, G.2 *)
      ELSIF (x.type.form = OJB.String) & (x.b = 2) & (par.class = OJB.Var) &
            (par.type.form = OJB.Char) THEN
        OJG.StrToChar(x);
        OJG.ValueParam(x)
      ELSE OJS.Mark("incompatible parameters")
      END
    END
  END Parameter;

  PROCEDURE ParamList(VAR x: OJG.Item);
    VAR n: INTEGER; par: OJB.Object;
  BEGIN par := x.type.dsc; n := 0;
    IF sym # OJS.rparen THEN
      Parameter(par); n := 1;
      WHILE sym <= OJS.comma DO
        Check(OJS.comma, "comma?");
        IF par # NIL THEN par := par.next END ;
        INC(n); Parameter(par)
      END ;
      Check(OJS.rparen, ") missing")
    ELSE OJS.Get(sym);
    END ;
    IF n < x.type.nofpar THEN OJS.Mark("too few params")
    ELSIF n > x.type.nofpar THEN OJS.Mark("too many params")
    END
  END ParamList;

  PROCEDURE StandFunc(VAR x: OJG.Item; fct: INTEGER; restyp: OJB.Type);
    VAR y: OJG.Item; n, npar: INTEGER;
  BEGIN
    Check(OJS.lparen, "no (");
    npar := fct MOD 10; fct := fct DIV 10;
    n := 0;
    IF npar # 0 THEN expression(x); n := 1 END ;
    WHILE sym = OJS.comma DO
      OJS.Get(sym);
      IF (x.mode # OJB.Typ) & (* x.mode = ORB.Typ for SYSTEM.VAL(x, y) *)
         (x.mode # OJB.Const) (* allow constant folding in OJG.Shift/Band/Bor *)
         THEN
        OJG.ValueParam(x)
      END ;
      expression(y);
      INC(n)
    END ;
    Check(OJS.rparen, "no )");
    IF n = npar THEN
      IF fct = 0 THEN (*ABS*)
        IF x.type.form IN {OJB.Int, OJB.Real} THEN
          OJG.Abs(x); restyp := x.type
        ELSE
          OJS.Mark("bad type")
        END
      ELSIF fct = 1 THEN (*ODD*) CheckInt(x); OJG.Odd(x)
      ELSIF fct = 2 THEN (*FLOOR*) CheckReal(x); OJG.Floor(x)
      ELSIF fct = 3 THEN (*FLT*) CheckInt(x); OJG.Float(x)
      ELSIF fct = 4 THEN (*ORD*)
        IF x.type.form IN {OJB.Char, OJB.Bool, OJB.Set} THEN OJG.Ord(x)
        ELSIF (x.type.form = OJB.String) & (x.b = 2) THEN OJG.StrToChar(x)
        ELSE OJS.Mark("bad type")
        END
      ELSIF fct = 5 THEN (*CHR*) CheckInt(x); OJG.Ord(x)
      ELSIF fct = 6 THEN (*LEN*)
          IF x.type.form = OJB.Array THEN
            OJG.Len(x)
          ELSE
            OJS.Mark("not an array")
          END
      ELSIF fct IN {7, 8, 9} THEN (*LSL, ASR, ROR*)
        IF x.type.form IN {OJB.Int, OJB.Set} THEN
          CheckInt(x); CheckInt(y);
          OJG.Shift(fct-7, x, y); restyp := x.type
        ELSE
          OJS.Mark("bad type")
        END
      ELSIF fct = 11 THEN (*AND*) CheckInt(x); CheckInt(y); OJG.Band(x, y)
      ELSIF fct = 12 THEN (*BOR*) CheckInt(x); CheckInt(y); OJG.Bor(x, y)
      ELSIF fct = 15 THEN (*NOT*) CheckInt(x); OJG.Bnot(x)
      ELSIF fct = 16 THEN (*VAL*)
        IF x.mode = OJB.Typ THEN
          IF ((x.type.form = OJB.Int) OR (x.type.form = OJB.Set)) &
             ((y.type.form = OJB.Int) OR (y.type.form = OJB.Set)) THEN
            restyp := x.type
          ELSIF (x.type.form = OJB.Real) & (y.type.form = OJB.Int) THEN
            OJG.IntToReal(y);
            restyp := x.type
          ELSIF (x.type.form = OJB.Int) & (y.type.form = OJB.Real) THEN
            OJG.RealToInt(y);
            restyp := x.type
          ELSIF (x.type.form = OJB.Pointer) & (y.type.form = OJB.Pointer)
          THEN
            TypeTest(y, x.type, TRUE);
            restyp := x.type
          ELSE OJS.Mark("casting not allowed")
          END ;
          x := y
        ELSE OJS.Mark("casting not allowed")
        END
      ELSIF fct = 21 THEN (*eot*) OJG.eot(x)
      ELSIF fct = 22 THEN (*ReadInt*) OJG.ReadInt(x)
      ELSIF fct = 23 THEN (*ARGNUM*) OJG.Argnum(x)
      END ;
      x.type := restyp
    ELSE OJS.Mark("wrong nof params")
    END
  END StandFunc;

  PROCEDURE element(VAR x: OJG.Item);
    VAR y: OJG.Item;
  BEGIN
    expression(x); CheckSetVal(x);
    IF sym = OJS.upto THEN
      OJS.Get(sym);
      OJG.Set0(x);
      expression(y);
      CheckSetVal(y);
      OJG.Set1(x, y)
    ELSE OJG.Singleton(x)
    END ;
    x.type := OJB.setType
  END element;

  PROCEDURE set(VAR x: OJG.Item);
    VAR y: OJG.Item;
  BEGIN
    IF sym >= OJS.if THEN
      IF sym # OJS.rbrace THEN OJS.Mark(" } missing") END ;
      OJG.MakeConstItem(x, OJB.setType, 0) (*empty set*)
    ELSE element(x);
      WHILE sym < OJS.rparen DO
        IF sym = OJS.comma THEN OJS.Get(sym)
        ELSE OJS.Mark("missing comma")
        END ;
        element(y); OJG.SetOp(OJS.plus, x, y)
      END
    END
  END set;

  PROCEDURE factor(VAR x: OJG.Item);
    VAR obj: OJB.Object;
      modName: OJS.Ident;
  BEGIN (*sync*)
    IF (sym < OJS.char) OR (sym > OJS.ident) THEN
      OJS.Mark("expression expected");
      REPEAT OJS.Get(sym)
      UNTIL (sym >= OJS.char) & (sym <= OJS.for) OR (sym >= OJS.then)
    END ;
    IF sym = OJS.ident THEN
      obj := qualident(modName);
      IF obj.class = OJB.SFunc THEN StandFunc(x, obj.val, obj.type)
      ELSE
        Strings.Copy(modName, x.modName);
        OJG.MakeItem(x, obj); selector(x);
        IF sym = OJS.lparen THEN
          OJS.Get(sym);
          IF (x.type.form = OJB.Proc) & (x.type.base.form # OJB.NoTyp) THEN
            OJG.PrepCall(x); ParamList(x); OJG.Call(x);
            OJG.storeVarPar;
            x.type := x.type.base
          ELSE OJS.Mark("not a function"); ParamList(x)
          END
        END
      END
    ELSIF sym = OJS.int THEN
      OJG.MakeConstItem(x, OJB.intType, OJS.ival); OJS.Get(sym)
    ELSIF sym = OJS.real THEN
      OJG.MakeRealItem(x, OJS.rval); OJS.Get(sym)
    ELSIF sym = OJS.char THEN
      OJG.MakeConstItem(x, OJB.charType, OJS.ival); OJS.Get(sym)
    ELSIF sym = OJS.nil THEN
       OJS.Get(sym); OJG.MakeConstItem(x, OJB.nilType, 0)
    ELSIF sym = OJS.string THEN
       OJG.MakeStringItem(x); OJS.Get(sym)
    ELSIF sym = OJS.lparen THEN
       OJS.Get(sym); expression(x); Check(OJS.rparen, "no )")
    ELSIF sym = OJS.lbrace THEN
       OJS.Get(sym); set(x); Check(OJS.rbrace, "no }")
    ELSIF sym = OJS.not THEN
      OJS.Get(sym); factor(x); CheckBool(x); OJG.Not(x)
    ELSIF sym = OJS.false THEN
      OJS.Get(sym); OJG.MakeConstItem(x, OJB.boolType, 0)
    ELSIF sym = OJS.true THEN
      OJS.Get(sym); OJG.MakeConstItem(x, OJB.boolType, 1)
    ELSE
      OJS.Mark("not a factor"); OJG.MakeConstItem(x, OJB.intType, 0)
    END
  END factor;

  PROCEDURE term(VAR x: OJG.Item);
    VAR y: OJG.Item; op, f: INTEGER;
  BEGIN
    factor(x); f := x.type.form;
    WHILE (sym >= OJS.times) & (sym <= OJS.and) DO
      op := sym; OJS.Get(sym);
      IF op = OJS.times THEN
        OJG.loadOp(x);
        IF f = OJB.Int THEN factor(y); CheckInt(y); OJG.MulOp(x, y)
        ELSIF f = OJB.Real THEN factor(y); CheckReal(y); OJG.RealOp(op, x, y)
        ELSIF f = OJB.Set THEN factor(y); CheckSet(y); OJG.SetOp(op, x, y)
        ELSE OJS.Mark("bad type")
        END
      ELSIF (op = OJS.div) OR (op = OJS.mod) THEN
        OJG.loadOp(x);
        CheckInt(x); factor(y); CheckInt(y);
        OJG.DivOp(op, x, y)
      ELSIF op = OJS.rdiv THEN
        OJG.loadOp(x);
        IF f = OJB.Real THEN factor(y); CheckReal(y); OJG.RealOp(op, x, y)
        ELSIF f = OJB.Set THEN factor(y); CheckSet(y); OJG.SetOp(op, x, y)
        ELSE OJS.Mark("bad type")
        END
      ELSE (*op = and*)
        CheckBool(x); OJG.And1(x); factor(y); CheckBool(y); OJG.And2(x, y)
      END
    END
  END term;

  PROCEDURE SimpleExpression(VAR x: OJG.Item);
    VAR y: OJG.Item; op: INTEGER;
  BEGIN
    IF sym = OJS.minus THEN OJS.Get(sym); term(x);
      IF x.type.form IN {OJB.Int, OJB.Real, OJB.Set} THEN
        OJG.Neg(x)
      ELSE
        CheckInt(x)
      END
    ELSIF sym = OJS.plus THEN OJS.Get(sym); term(x);
    ELSE term(x)
    END ;
    WHILE (sym >= OJS.plus) & (sym <= OJS.or) DO
      op := sym; OJS.Get(sym);
      IF op = OJS.or THEN
         OJG.Or1(x); CheckBool(x); term(y); CheckBool(y); OJG.Or2(x, y)
      ELSIF x.type.form = OJB.Int THEN
         OJG.loadOp(x); term(y); CheckInt(y); OJG.AddOp(op, x, y)
      ELSIF x.type.form = OJB.Real THEN
         OJG.loadOp(x); term(y); CheckReal(y); OJG.RealOp(op, x, y)
      ELSE
        CheckSet(x); OJG.loadOp(x); term(y); CheckSet(y); OJG.SetOp(op, x, y)
      END
    END
  END SimpleExpression;

  PROCEDURE expression0(VAR x: OJG.Item);
    VAR y: OJG.Item; obj: OJB.Object; rel, xf, yf: INTEGER;
      modName: OJS.Ident;
  BEGIN
    SimpleExpression(x);
    IF (sym >= OJS.eql) & (sym <= OJS.geq) THEN
      rel := sym; OJS.Get(sym);
      OJG.loadOp(x);
      SimpleExpression(y); xf := x.type.form; yf := y.type.form;
      IF x.type = y.type THEN
        IF (xf IN {OJB.Char, OJB.Int}) THEN OJG.IntRelation(rel, x, y)
        ELSIF xf = OJB.Real THEN OJG.RealRelation(rel, x, y)
        ELSIF xf IN {OJB.Set, OJB.Pointer, OJB.Proc, OJB.NilTyp, OJB.Bool} THEN
          IF rel <= OJS.neq THEN
            OJG.IntRelation(rel, x, y)
          ELSE
            OJS.Mark("only = or #")
          END
        ELSIF (xf = OJB.Array) &
              (x.type.base.form = OJB.Char) OR (xf = OJB.String) THEN
          OJG.StringRelation(rel, x, y)
        ELSE OJS.Mark("illegal comparison")
        END
      ELSIF (xf IN {OJB.Pointer, OJB.Proc}) & (yf = OJB.NilTyp)
          OR (yf IN {OJB.Pointer, OJB.Proc}) & (xf = OJB.NilTyp) THEN
        IF rel <= OJS.neq THEN
           OJG.IntRelation(rel, x,  y)
        ELSE
          OJS.Mark("only = or #")
        END
      ELSIF (xf = OJB.Pointer) & (yf = OJB.Pointer) &
            (IsExtension(x.type.base, y.type.base) OR
             IsExtension(y.type.base, x.type.base)) OR
            (xf = OJB.Proc) & (yf = OJB.Proc) &
             EqualSignatures(x.type, y.type) THEN
        IF rel <= OJS.neq THEN
          OJG.IntRelation(rel,  x, y)
        ELSE
          OJS.Mark("only = or #")
        END
      ELSIF (xf = OJB.Array) & (x.type.base.form = OJB.Char) &
            ((yf = OJB.String) OR (yf = OJB.Array) &
             (y.type.base.form = OJB.Char)) OR
            (yf = OJB.Array) & (y.type.base.form = OJB.Char) &
            (xf = OJB.String) THEN
        OJG.StringRelation(rel, x, y)
      ELSIF (xf = OJB.Char) & (yf = OJB.String) & (y.b = 2) THEN
        OJG.StrToChar(y); OJG.IntRelation(rel, x, y)
      ELSIF (yf = OJB.Char) & (xf = OJB.String) & (x.b = 2) THEN
        OJG.StrToChar(x); OJG.IntRelation(rel, x, y)
      (*BYTE*)
      ELSIF (xf = OJB.Int) & (yf = OJB.Int) THEN OJG.IntRelation(rel,  x, y)
      ELSE OJS.Mark("illegal comparison")
      END ;
      x.type := OJB.boolType
    ELSIF sym = OJS.in THEN
      OJG.In0(x);
      OJS.Get(sym);
      CheckInt(x); SimpleExpression(y);
      CheckSet(y); OJG.In1(y);
      x.type := OJB.boolType
    ELSIF sym = OJS.is THEN
      OJS.Get(sym);
      obj := qualident(modName);
      Strings.Copy(modName, x.modName);
      TypeTest(x, obj.type, FALSE);
      x.type := OJB.boolType
    END
  END expression0;

  (* statements *)

  PROCEDURE StandProc(pno: INTEGER);
    VAR npar: INTEGER; (*nof formal parameters*)
      x, y, z: OJG.Item;
  BEGIN
    npar := pno MOD 10; pno := pno DIV 10;
    IF (npar = 0) & (pno = 17) THEN
      OJG.WriteLn
    ELSIF (npar = 2) & (pno = 24) THEN (*ARGS*)
      OJG.Args0();
      Check(OJS.lparen, "no (");
      expression(x); CheckInt(x); OJG.Args1(x);
      Check(OJS.comma, "no ,");
      expression(y);
      Check(OJS.rparen, "no )");
      IF (y.type.form # OJB.Array) OR (y.type.base # OJB.charType) THEN
        OJS.Mark("not ARRAY OF CHAR")
      END ;
      OJG.Args2(y)
    ELSIF (npar = 2) & ((pno = 2) OR (pno = 3)) THEN (*INCL, EXCL*)
      Check(OJS.lparen, "no (");
      expression(x); CheckSet(x); CheckReadOnly(x);
      OJG.Include0(x, z);
      Check(OJS.comma, "no ,");
      expression(y);
      Check(OJS.rparen, "no )");
      CheckInt(y); OJG.Include1(pno-2, y, z)
    ELSIF (pno = 0) OR (pno = 1) THEN (*INC, DEC*)
      Check(OJS.lparen, "no (");
      expression(x); CheckInt(x); CheckReadOnly(x);
      OJG.Increment0(x, z);
      IF sym = OJS.comma THEN
        OJS.Get(sym); expression(y); CheckInt(y)
      ELSE
        y.type := OJB.noType
      END ;
      Check(OJS.rparen, "no )");
      OJG.Increment1(pno, x, y, z)
    ELSE
      Check(OJS.lparen, "no (");
      expression(x);
      Check(OJS.rparen, "no )");
      IF pno = 4 THEN CheckBool(x); OJG.Assert(x)
      ELSIF pno = 5 THEN(*NEW*) CheckReadOnly(x);
         IF (x.type.form = OJB.Pointer) & (x.type.base.form = OJB.Record) THEN
           OJG.New(x)
         ELSE
           OJS.Mark("not a pointer to record")
         END
      ELSIF pno = 15 THEN
        IF (x.type.form = OJB.String) & (x.b = 2) THEN
          OJG.StrToChar(x)
        ELSIF x.type.form # OJB.Char THEN
          OJS.Mark("not Char"); x.type := OJB.charType
        END ;
        OJG.WriteChar(x)
      ELSIF pno = 16 THEN CheckInt(x); OJG.WriteInt(x)
      ELSIF pno = 18 THEN CheckReal(x); OJG.WriteReal(x)
      END
    END
  END StandProc;

  PROCEDURE StatSequence;
    VAR obj: OJB.Object;
      orgtype: OJB.Type; (*original type of case var*)
      x, y, z, w: OJG.Item;
      L0, L1: INTEGER;
      modName: OJS.Ident;

    PROCEDURE TypeCase(obj: OJB.Object; VAR x: OJG.Item);
      VAR typobj: OJB.Object;
        modName: OJS.Ident;
    BEGIN
      IF sym = OJS.ident THEN
        typobj := qualident(modName);
        Strings.Copy(modName, x.modName);
        OJG.MakeItem(x, obj);
        x.oldType := NIL;
        IF typobj.class # OJB.Typ THEN OJS.Mark("not a type") END ;
        TypeTest(x, typobj.type, FALSE); obj.caseOrgType := obj.type;
        obj.type := typobj.type;
        OJG.CFJump(x); Check(OJS.colon, ": expected"); StatSequence
      ELSE OJS.Mark("type id expected"); OJG.CFJump(x)
      END
    END TypeCase;

    PROCEDURE LabelRange(labelForm: INTEGER; VAR x, y: OJG.Item; VAR n: INTEGER;
                         VAR tab: ARRAY OF OJG.LabelRange; stmts: INTEGER);
      VAR i: INTEGER; done: BOOLEAN;
    BEGIN
      expression(x);
      CheckConst(x);
      IF (x.type.form = OJB.String) & (x.b = 2) THEN OJG.StrToChar(x) END ;
      IF x.type.form # labelForm THEN
        OJS.Mark("wrong type of case label")
      END ;
      IF sym = OJS.upto THEN
        OJS.Get(sym);
        expression(y);
        CheckConst(y);
        IF (y.type.form = OJB.String) & (y.b = 2) THEN OJG.StrToChar(y) END ;
        IF y.type.form # x.type.form THEN
           OJS.Mark("wrong type of case label")
        END ;
        IF y.a < x.a THEN OJS.Mark("illegal value of constant"); y.a := x.a END;
      ELSE y := x
      END ;
      (*enter label range into ordered table*)
      i := n;
      done := FALSE;
      IF i < OJG.NofCases THEN
        WHILE (i # 0) & ~done DO
          IF tab[i-1].low <= y.a THEN
            IF tab[i-1].high >= x.a THEN
              OJS.Mark("case label defined more than once")
            END ;
            done := TRUE
          ELSE
            tab[i] := tab[i-1];
            DEC(i)
          END
        END ;
        tab[i].low := x.a; tab[i].high := y.a;
        tab[i].L := stmts;
        INC(n)
      ELSE OJS.Mark("too many cases or no case in case statement")
      END
    END LabelRange;

    PROCEDURE Case(labelForm: INTEGER; VAR n: INTEGER;
                   VAR tab: ARRAY OF OJG.LabelRange);
      VAR x, y: OJG.Item;
        stmts: INTEGER;
    BEGIN
      IF sym IN {OJS.int, OJS.char, OJS.minus, OJS.plus, OJS.string, OJS.ident}
         THEN
        stmts := OJG.getPC();
        LabelRange(labelForm, x, y, n, tab, stmts);
        WHILE sym = OJS.comma DO
          OJS.Get(sym);
          LabelRange(labelForm, x, y, n, tab, stmts)
        END ;
        IF sym IN {OJS.int, OJS.char, OJS.minus, OJS.plus, OJS.string,OJS.ident}
           THEN
          OJS.Mark("',' missing")
        END ;
        Check(OJS.colon, ": expected");
        StatSequence;
      ELSE OJS.Mark("integer or character expected")
      END
    END Case;

    PROCEDURE CasePart(VAR caseExpr: OJG.Item);
      VAR n, L0, dflt, end: INTEGER;
        tab: ARRAY OJG.NofCases OF OJG.LabelRange;
    BEGIN
      L0 := 0;
      end := 0;
      n := 0;
      L0 := OJG.CaseIn(caseExpr, L0);
      Case(caseExpr.type.form, n, tab);
      end := OJG.FJump(end);
      WHILE sym = OJS.bar DO
        OJS.Get(sym); Case(caseExpr.type.form, n, tab);
        end := OJG.FJump(end)
      END ;
      dflt := OJG.CaseDefault();
      OJG.CaseOut(caseExpr, end, L0, n, dflt, tab)
    END CasePart;

    PROCEDURE SkipCase;
    BEGIN
      WHILE sym # OJS.colon DO OJS.Get(sym) END ;
      OJS.Get(sym); StatSequence
    END SkipCase;

  BEGIN
    (* StatSequence *)
    REPEAT (*sync*) obj := NIL;
      IF ~((sym >= OJS.ident) & (sym <= OJS.for) OR (sym >= OJS.semicolon)) THEN
        OJS.Mark("statement expected");
        REPEAT OJS.Get(sym) UNTIL sym >= OJS.ident
      END ;
      OJG.SetLineNumber(OJS.GetLine());
      IF sym = OJS.ident THEN
        obj := qualident(modName);
        Strings.Copy(modName, x.modName);
        OJG.MakeItem(x, obj);
        IF x.mode = OJB.SProc THEN StandProc(obj.val)
        ELSE selector(x);
          IF sym = OJS.becomes THEN (*assignment*)
            OJS.Get(sym); CheckReadOnly(x);
            OJG.PrepAssign(x);
            expression(y);
            IF y.mode = OJB.Typ THEN
              OJS.Mark("illegal assignment")
            (* Type Rule E.1, E.2, E.3, E.4 *)
            ELSIF CompTypes(x.type, y.type, FALSE) THEN
              IF x.type.form <= OJB.Pointer THEN OJG.Store(x, y, FALSE)
              ELSIF x.type.form = OJB.Proc THEN OJG.StoreProc(x, y)
              ELSIF y.type.form = OJB.Record THEN
                  OJG.Store(x, y, TRUE)
              ELSIF y.type.form = OJB.Array THEN
                OJG.storeArray(x, y)
              END
            (* Type Rule E.6 *)
            ELSIF (x.type.form = OJB.Array) & (y.type.form = OJB.Array) &
                  (x.type.len > 0) & (y.type.len < 0) &
                  EqualTypes(x.type.base, y.type.base) THEN
              OJG.storeArray(x, y)
            (* Type Rule E.5 *)
            ELSIF (x.type.form = OJB.Array) & (x.type.base.form = OJB.Char) &
                  (y.type.form = OJB.String) THEN
              OJG.CopyString(x, y)
            (* Type Rule E.5, J *)
            ELSIF (x.type.form = OJB.Array) & (x.type.base.form = OJB.Char) &
                  y.rdo & (y.type.form = OJB.Char) THEN
              OJG.CharToStr(y);
              OJG.CopyString(x, y);
            (* Type Rule I *)  (*BYTE*)
            ELSIF (x.type.form = OJB.Int) & (y.type.form = OJB.Int) THEN
              IF x.type = OJB.byteType THEN CheckByteRange(y) END;
              OJG.Store(x, y, FALSE)
            (* Type Rule J *)
            ELSIF (x.type.form = OJB.Char) & (y.type.form = OJB.String) &
                  (y.b = 2) THEN
              OJG.StrToChar(y); OJG.Store(x, y, FALSE)
            ELSE OJS.Mark("illegal assignment")
            END
          ELSIF sym = OJS.eql THEN
            OJS.Mark("should be :="); OJS.Get(sym); expression(y)
          ELSIF sym = OJS.lparen THEN (*procedure call*)
            OJS.Get(sym);
            IF (x.type.form = OJB.Proc) & (x.type.base.form = OJB.NoTyp) THEN
              OJG.PrepCall(x); ParamList(x); OJG.Call(x);
              OJG.storeVarPar
            ELSE OJS.Mark("not a procedure"); ParamList(x)
            END
          (*procedure call without parameters*)
          ELSIF x.type.form = OJB.Proc THEN
            IF x.type.nofpar > 0 THEN OJS.Mark("missing parameters") END ;
            IF x.type.base.form = OJB.NoTyp THEN
              OJG.PrepCall(x);
              OJG.Call(x)
            ELSE
              OJS.Mark("not a procedure")
            END
          ELSIF x.mode = OJB.Typ THEN OJS.Mark("illegal assignment")
          ELSE OJS.Mark("not a procedure")
          END
        END
      ELSIF sym = OJS.if THEN
        OJS.Get(sym); expression(x); CheckBool(x); OJG.CFJump(x);
        Check(OJS.then, "no THEN");
        StatSequence; L0 := 0;
        WHILE sym = OJS.elsif DO
          OJS.Get(sym); L0 := OJG.FJump(L0); OJG.Fixup(x.a); expression(x);
          CheckBool(x); OJG.CFJump(x); Check(OJS.then, "no THEN"); StatSequence
        END ;
        IF sym = OJS.else THEN
          OJS.Get(sym); L0 := OJG.FJump(L0); OJG.Fixup(x.a); StatSequence
        ELSE
          OJG.Fixup(x.a)
        END ;
        OJG.Fixup(L0); Check(OJS.end, "no END")
      ELSIF sym = OJS.while THEN
        OJS.Get(sym); L0 := OJG.getPC(); expression(x); CheckBool(x);
        OJG.CFJump(x); Check(OJS.do, "no DO"); StatSequence; OJG.BJump(L0);
        WHILE sym = OJS.elsif DO
          OJS.Get(sym); OJG.Fixup(x.a); expression(x); CheckBool(x);
          OJG.CFJump(x); Check(OJS.do, "no DO"); StatSequence; OJG.BJump(L0)
        END ;
        OJG.Fixup(x.a); Check(OJS.end, "no END")
      ELSIF sym = OJS.repeat THEN
        OJS.Get(sym); L0 := OJG.getPC(); StatSequence;
        IF sym = OJS.until THEN
          OJS.Get(sym); expression(x); CheckBool(x); OJG.CBJump(x, L0)
        ELSE OJS.Mark("missing UNTIL")
        END
      ELSIF sym = OJS.for THEN
        OJS.Get(sym);
        IF sym = OJS.ident THEN
          obj := qualident(modName);
          Strings.Copy(modName, x.modName);
          OJG.MakeItem(x, obj); CheckInt(x); CheckReadOnly(x);
          IF sym = OJS.becomes THEN
            OJG.loadPar(x); OJS.Get(sym); expression(y); CheckInt(y);
            OJG.For0(x, y); L0 := OJG.getPC();
            Check(OJS.to, "no TO"); expression(z); CheckInt(z); obj.rdo := TRUE;
            IF sym = OJS.by THEN
              OJS.Get(sym); expression(w); CheckConst(w); CheckInt(w)
            ELSE
              OJG.MakeConstItem(w, OJB.intType, 1)
            END ;
            Check(OJS.do, "no DO"); L1 := OJG.For1(x, z, w);
            StatSequence; Check(OJS.end, "no END");
            OJG.For2(x, w); OJG.BJump(L0); OJG.Fixup(L1); obj.rdo := FALSE
          ELSE OJS.Mark(":= expected")
          END
        ELSE OJS.Mark("identifier expected")
        END
      ELSIF sym = OJS.case THEN
        OJS.Get(sym);
        expression(x);
        Check(OJS.of, "OF expected");
        obj := FindObjFrom(modid, x);
        IF (obj # NIL) & ((obj.type.form = OJB.Pointer) OR
                            (obj.type.form = OJB.Record) &
                            (obj.class = OJB.ParStruct)) THEN
          orgtype := obj.type;
          TypeCase(obj, x); L0 := 0;
          WHILE sym = OJS.bar DO
            OJS.Get(sym); L0 := OJG.FJump(L0); OJG.Fixup(x.a);
            obj.type := orgtype; obj.caseOrgType := NIL;
            TypeCase(obj, x)
          END ;
          OJG.Fixup(x.a); OJG.Fixup(L0); obj.type := orgtype;
          obj.caseOrgType := NIL
        ELSIF (obj = NIL) & ((x.type.form = OJB.Pointer) OR
                             (x.type.form = OJB.Record)) THEN
          OJS.Mark("identifier expected")
        ELSIF (x.type.form = OJB.Int) OR (x.type.form = OJB.Char) THEN
          CasePart(x)
        ELSE OJS.Mark("inadmissible type");
          SkipCase;
          WHILE sym = OJS.bar DO SkipCase END
        END ;
        Check(OJS.end, "no END")
      END ;
      IF sym = OJS.semicolon THEN OJS.Get(sym)
      ELSIF sym < OJS.semicolon THEN OJS.Mark("missing semicolon?")
      END ;
      IF (OJG.curStack() # 0) & (OJS.errcnt = 0) THEN
        OJS.Mark("Reg Stack")
      END
    UNTIL sym > OJS.semicolon
  END StatSequence;

  (* Types and declarations *)

  PROCEDURE IdentList(class: INTEGER): OJB.Object;
    VAR obj, first: OJB.Object;
  BEGIN
    IF sym = OJS.ident THEN
      first := OJB.InsertObj(OJS.id, class); OJS.Get(sym);
      first.expo := CheckExport();
      WHILE sym = OJS.comma DO
        OJS.Get(sym);
        IF sym = OJS.ident THEN
          obj := OJB.InsertObj(OJS.id, class); OJS.Get(sym);
          obj.expo := CheckExport()
        ELSE OJS.Mark("ident?")
        END
      END;
      IF sym = OJS.colon THEN OJS.Get(sym) ELSE OJS.Mark(":?") END
    ELSE first := NIL
    END
    RETURN first
  END IdentList;

  PROCEDURE ArrayType(): OJB.Type;
    VAR x: OJG.Item;
      typ, type: OJB.Type; len: INTEGER;
  BEGIN
    NEW(typ); typ.form := OJB.NoTyp;
    expression(x);
    IF (x.mode = OJB.Const) & (x.type.form = OJB.Int) & (x.a >= 0) THEN
      len := x.a
    ELSE
      len := 1; OJS.Mark("not a valid length")
    END ;
    IF sym = OJS.of THEN OJS.Get(sym); typ.base := Type(FALSE);
    ELSIF sym = OJS.comma THEN OJS.Get(sym); typ.base := ArrayType()
    ELSE OJS.Mark("missing OF"); typ.base := OJB.intType
    END ;
    typ.form := OJB.Array; typ.len := len; type := typ
    RETURN type
  END ArrayType;

  PROCEDURE RecordType(): OJB.Type;
    VAR obj, obj0, new, bot, base: OJB.Object;
      type, typ, tp: OJB.Type;
      modName: OJS.Ident;
  BEGIN NEW(typ); typ.form := OJB.NoTyp; typ.base := NIL;
    typ.nofpar := 0; bot := NIL;
    IF sym = OJS.lparen THEN
      OJS.Get(sym); (*record extension*)
      IF sym = OJS.ident THEN
        base := qualident(modName);
        IF base.class = OJB.Typ THEN
          IF base.type.form = OJB.Record THEN typ.base := base.type
          ELSE typ.base := OJB.intType; OJS.Mark("invalid extension")
          END ;
          bot := typ.base.dsc
        ELSE OJS.Mark("type expected")
        END
      ELSE OJS.Mark("ident expected")
      END ;
      Check(OJS.rparen, "no )")
    END ;
    WHILE sym = OJS.ident DO  (*fields*)
      obj := bot;
      WHILE sym = OJS.ident DO
        obj0 := obj;
        WHILE (obj0 # NIL) & (obj0.name # OJS.id) DO obj0 := obj0.next END ;
        IF obj0 # NIL THEN OJS.Mark("mult def") END ;
        NEW(new); Strings.Copy(OJS.id, new.name);
        new.class := OJB.Fld; new.recordType := typ;
        new.next := obj; obj := new;
        OJS.Get(sym); new.expo := CheckExport();
        IF (sym # OJS.comma) & (sym # OJS.colon) THEN OJS.Mark("comma expected")
        ELSIF sym = OJS.comma THEN OJS.Get(sym)
        END
      END ;
      Check(OJS.colon, "colon expected"); tp := Type(FALSE);
      IF (tp.form = OJB.Array) & (tp.len < 0) THEN
         OJS.Mark("dyn array not allowed")
      END ;
      obj0 := obj;
      WHILE obj0 # bot DO obj0.type := tp; obj0.lev := 0; obj0 := obj0.next END;
      bot := obj;
      IF sym = OJS.semicolon THEN OJS.Get(sym) ELSIF sym # OJS.end THEN
        OJS.Mark(" ; or END")
      END
    END ;
    typ.form := OJB.Record; typ.dsc := bot; type := typ
    RETURN type
  END RecordType;

  PROCEDURE FPSection(VAR adr: INTEGER; VAR nofpar: INTEGER);
    VAR obj, first: OJB.Object; tp: OJB.Type;
      cl: INTEGER; rdo: BOOLEAN;
  BEGIN
    IF sym = OJS.var THEN OJS.Get(sym); cl := OJB.Par ELSE cl := OJB.Var END ;
    first := IdentList(cl); tp := FormalType(); rdo := FALSE;
    IF (cl = OJB.Var) & (tp.form >= OJB.Array) THEN
      (* cl = ORB.Par; not needed as arrays/records are references in JVM*)
      rdo := TRUE
    ELSIF (cl = OJB.Par) & (tp.form >= OJB.Array) THEN
      (* arrays/records are references in JVM, OJB.ParStruct is equivalent
         to OJB.Var but for structured types *)
      cl := OJB.ParStruct
    END ;
    obj := first;
    WHILE obj # NIL DO
      INC(nofpar); obj.class := cl; obj.type := tp; obj.rdo := rdo;
      obj.lev := level; obj.val := adr;
      adr := adr + 1; obj := obj.next
    END ;
    IF adr > OJG.ParamsMax THEN OJS.Mark("too many parameters") END
  END FPSection;

  PROCEDURE ProcedureType(ptype: OJB.Type; parblksize: INTEGER): INTEGER;
    VAR obj: OJB.Object; size: INTEGER; nofpar: INTEGER;
      modName: OJS.Ident;
  BEGIN ptype.base := OJB.noType; size := parblksize; nofpar := 0;
    ptype.dsc := NIL;
    IF sym = OJS.lparen THEN
      OJS.Get(sym);
      IF sym = OJS.rparen THEN OJS.Get(sym)
      ELSE FPSection(size, nofpar);
        WHILE sym = OJS.semicolon DO OJS.Get(sym); FPSection(size, nofpar) END ;
        Check(OJS.rparen, "no )")
      END ;
      IF sym = OJS.colon THEN  (*function*)
        OJS.Get(sym);
        IF sym = OJS.ident THEN
          obj := qualident(modName); ptype.base := obj.type;
          (* Type Rule H *)
          IF ~((obj.class = OJB.Typ) &
               (obj.type.form IN {OJB.Byte .. OJB.Pointer, OJB.Proc})) THEN
            OJS.Mark("illegal function type")
          END
        ELSE OJS.Mark("type identifier expected")
        END
      END
    END ;
    ptype.nofpar := nofpar; parblksize := size
    RETURN parblksize
  END ProcedureType;

  PROCEDURE FormalType0(): OJB.Type;
    VAR obj: OJB.Object; dmy: INTEGER;
      typ: OJB.Type;
      modName: OJS.Ident;
  BEGIN
    IF sym = OJS.ident THEN
      obj := qualident(modName);
      IF obj.class = OJB.Typ THEN
        typ := obj.type
      ELSE
        OJS.Mark("not a type"); typ := OJB.intType
      END
    ELSIF sym = OJS.array THEN
      OJS.Get(sym); Check(OJS.of, "OF ?");
      NEW(typ); typ.form := OJB.Array; typ.len := -1;
      typ.base := FormalType()
    ELSIF sym = OJS.procedure THEN
      OJS.Get(sym); OJB.OpenScope;
      NEW(typ); typ.form := OJB.Proc; dmy := ProcedureType(typ, 0);
      typ.dsc := OJB.topScope.next; OJB.CloseScope;
      OJG.genSignature(typ);
      OJG.MakeProcType(typ)
    ELSE OJS.Mark("identifier expected"); typ := OJB.noType
    END
    RETURN typ
  END FormalType0;

  PROCEDURE Type0(typedef: BOOLEAN): OJB.Type;
    VAR dmy: INTEGER; obj, tmp: OJB.Object; ptbase: PtrBase;
      type: OJB.Type; modName: OJS.Ident;
  BEGIN type := OJB.intType; (*sync*)
    IF (sym # OJS.ident) & (sym < OJS.array) THEN OJS.Mark("not a type");
      REPEAT OJS.Get(sym) UNTIL (sym = OJS.ident) OR (sym >= OJS.array)
    END ;
    IF sym = OJS.ident THEN
      obj := qualident(modName);
      IF obj.class = OJB.Typ THEN
        IF (obj.type # NIL) & (obj.type.form # OJB.NoTyp) THEN
          type := obj.type
        END
      ELSE OJS.Mark("not a type or undefined")
      END
    ELSIF sym = OJS.array THEN OJS.Get(sym); type := ArrayType()
    ELSIF sym = OJS.record THEN
      OJS.Get(sym); type := RecordType(); Check(OJS.end, "no END");
      IF ~typedef & ~isDefinition THEN
        OJG.MakeRecordType(OJB.generateAnonymousTypeObj(type))
      END
    ELSIF sym = OJS.pointer THEN
      OJS.Get(sym); Check(OJS.to, "no TO");
      NEW(type);  type.form := OJB.Pointer; type.base := OJB.intType;
      IF sym = OJS.ident THEN
        obj := OJB.thisObj(OJS.id);
        OJS.Get(sym);
        IF obj # NIL THEN
          IF (obj.class = OJB.Typ) &
             (obj.type.form IN {OJB.Record, OJB.NoTyp}) THEN
            type.base := obj.type
          ELSIF (sym = OJS.period) & (obj.class = OJB.Mod) THEN
            OJS.Get(sym);
            IF sym = OJS.ident THEN obj := OJB.thisimport(obj, OJS.id);
              OJS.Get(sym);
              IF obj = NIL THEN OJS.Mark("undef")
              ELSE type.base := obj.type
              END
            ELSE OJS.Mark("identifier expected")
            END
          ELSE
            OJS.Mark("no valid base type")
          END
        ELSE
          (*enter into list of forward references to be fixed in Declarations*)
          NEW(ptbase); Strings.Copy(OJS.id, ptbase.name); ptbase.type := type;
           ptbase.next := pbsList; pbsList := ptbase;
          (* Temporarily save base type name (needed by OJG.internalName despite
             forward references are not fixed yet) *)
          NEW(type.base); type.base.form := OJB.Int; NEW(tmp);
          Strings.Copy(ptbase.name, tmp.name); type.base.typobj := tmp
        END
      ELSE type.base := Type(FALSE);
        IF type.base.form # OJB.Record THEN
          OJS.Mark("must point to record");
          type := OJB.intType
        END
      END
    ELSIF sym = OJS.procedure THEN
      OJS.Get(sym); OJB.OpenScope;
      NEW(type); type.form := OJB.Proc;
      dmy := ProcedureType(type, 0); type.dsc := OJB.topScope.next;
      OJB.CloseScope;
      OJG.genSignature(type);
      OJG.MakeProcType(type)
    ELSE OJS.Mark("illegal type")
    END
    RETURN type
  END Type0;

  PROCEDURE Declarations(varsize: INTEGER): INTEGER;
    VAR obj, first: OJB.Object;
      x: OJG.Item; tp: OJB.Type; ptbase: PtrBase;
      expo, alias: BOOLEAN; id: OJS.Ident;
  BEGIN
    (*sync*) pbsList := NIL;
    IF (sym < OJS.const) & (sym # OJS.end) & (sym # OJS.return) THEN
      OJS.Mark("declaration?");
      REPEAT OJS.Get(sym)
      UNTIL (sym >= OJS.const) OR (sym = OJS.end) OR (sym = OJS.return)
    END ;
    IF sym = OJS.const THEN
      OJS.Get(sym);
      WHILE sym = OJS.ident DO
        Strings.Copy(OJS.id, id); OJS.Get(sym); expo := CheckExport();
        IF sym = OJS.eql THEN OJS.Get(sym) ELSE OJS.Mark("= ?") END;
        expression(x);
        IF (x.type.form = OJB.String) & (x.b = 2) THEN OJG.StrToChar(x) END ;
        obj := OJB.InsertObj(id, OJB.Const); obj.expo := expo; obj.rdo := TRUE;
        IF x.mode = OJB.Const THEN
          obj.val := x.a; obj.len := x.b; obj.type := x.type
        ELSE
          OJS.Mark("expression not constant"); obj.type := OJB.intType
        END;
        Check(OJS.semicolon, "; missing")
      END
    END ;
    IF sym = OJS.type THEN
      OJS.Get(sym);
      WHILE sym = OJS.ident DO
        alias := FALSE;
        Strings.Copy(OJS.id, id); OJS.Get(sym); expo := CheckExport();
        IF sym = OJS.eql THEN OJS.Get(sym) ELSE OJS.Mark("=?") END ;
        tp := Type(TRUE);
        obj := OJB.InsertObj(id, OJB.Typ); obj.type := tp; obj.expo := expo;
        obj.lev := level;
        IF tp.typobj = NIL THEN
          (*aliases must not modify the typobj*)
          tp.typobj := obj
        ELSE
          alias := TRUE
        END ;
        IF tp.form = OJB.Record THEN
          (*check whether this is base of a pointer type; search and fixup*)
          ptbase := pbsList;
          WHILE ptbase # NIL DO
            IF obj.name = ptbase.name THEN ptbase.type.base := obj.type END ;
            ptbase := ptbase.next
          END ;
        END ;
        Check(OJS.semicolon, "; missing");
        IF (obj.type.form = OJB.Record) & ~alias THEN
          IF ~isDefinition THEN OJG.MakeRecordType(obj) END
        END
      END
    END ;
    IF sym = OJS.var THEN
      OJS.Get(sym);
      WHILE sym = OJS.ident DO
        first := IdentList(OJB.Var); tp := Type(FALSE);
        obj := first;
        WHILE obj # NIL DO
          obj.type := tp; obj.lev := level;
          obj.val := varsize; INC(varsize);
          obj := obj.next
        END ;
        Check(OJS.semicolon, "; missing")
      END
    END ;
    ptbase := pbsList;
    WHILE ptbase # NIL DO
      IF ptbase.type.base.form = OJB.Int THEN
       OJS.MarkAppend("undefined pointer base: ", ptbase.name)
      END ;
      ptbase := ptbase.next
    END ;
    IF (sym >= OJS.const) & (sym <= OJS.var) THEN
      OJS.Mark("declaration in bad order")
    END
    RETURN varsize
  END Declarations;

  PROCEDURE ProcedureDecl;
    VAR proc: OJB.Object;
      type: OJB.Type;
      procid: OJS.Ident;
      x: OJG.Item;
      locblksize, parblksize: INTEGER;
  BEGIN
    (* ProcedureDecl *) OJS.Get(sym);
    IF sym = OJS.ident THEN
      Strings.Copy(OJS.id, procid); OJS.Get(sym);
      proc := OJB.InsertObj(OJS.id, OJB.Const); proc.lev := level; parblksize := 0;
      NEW(type); type.form := OJB.Proc; proc.type := type;
      proc.expo := CheckExport();
      OJB.OpenScope; INC(level); proc.val := 0; type.base := OJB.noType;
      parblksize := ProcedureType(type, parblksize);  (*formal parameter list*)
      IF procid = "Main" THEN
        IF type.nofpar # 0 THEN
          OJS.Mark("Main cannot have formal parameters");
        ELSE
          hasMain := TRUE
        END
      END ;
      IF ~isDefinition THEN
        Check(OJS.semicolon, "no ;"); locblksize := parblksize;
        locblksize := Declarations(locblksize);
        proc.type.dsc := OJB.topScope.next;
        OJG.genSignature(proc.type);
        IF sym = OJS.procedure THEN
          REPEAT ProcedureDecl; Check(OJS.semicolon, "no ;")
          UNTIL sym # OJS.procedure;
          proc.type.dsc := OJB.topScope.next
        END ;
        OJG.Enter(proc, locblksize);
        IF sym = OJS.begin THEN OJS.Get(sym); StatSequence END ;
        IF sym = OJS.return THEN
          OJS.Get(sym); expression(x);
          IF type.base = OJB.noType THEN OJS.Mark("this is not a function")
          (* Type Rule I *)
          ELSIF (type.base.form = OJB.Int) & (x.type.form = OJB.Int) THEN
            IF type.base = OJB.byteType THEN CheckByteRange(x) END
          (* Type Rule J *)
          ELSIF (type.base.form = OJB.Char) & (x.type.form = OJB.String) &
                (x.b = 2) THEN
            OJG.StrToChar(x);
          (* Type Rule H *)
          ELSIF ~CompTypes(type.base, x.type, FALSE) THEN
            OJS.Mark("wrong result type")
          END
        ELSIF type.base.form # OJB.NoTyp THEN
          OJS.Mark("function without result"); type.base := OJB.noType
        END ;
        OJG.Return(type.base, x);
        OJB.CheckUnused(parblksize);
        OJB.CloseScope; DEC(level); Check(OJS.end, "no END");
        IF sym = OJS.ident THEN
          IF OJS.id # procid THEN OJS.Mark("no match") END ;
          OJS.Get(sym)
        ELSE OJS.Mark("no proc id")
        END
      ELSE
        proc.type.dsc := OJB.topScope.next;
        OJG.genSignature(proc.type);
        OJB.CloseScope; DEC(level)
      END
    ELSE OJS.Mark("proc id expected")
    END
  END ProcedureDecl;

  PROCEDURE Import;
    VAR aliasName, impName: OJS.Ident;
  BEGIN
    IF sym = OJS.ident THEN
      Strings.Copy(OJS.id, aliasName); OJS.Get(sym);
      IF sym = OJS.becomes THEN
        OJS.Get(sym);
        IF isDefinition THEN OJS.Mark("module alias not allowed") END ;
        IF sym = OJS.ident THEN Strings.Copy(OJS.id, impName); OJS.Get(sym)
        ELSE OJS.Mark("id expected"); impName := ""
        END
      ELSE Strings.Copy(aliasName, impName)
      END ;
      OJB.Import(aliasName, impName, modid)
    ELSE OJS.Mark("id expected")
    END
  END Import;

  PROCEDURE Module(outputFolder: ARRAY OF CHAR);
    VAR dc: INTEGER;
      dmy: OJG.Item;
  BEGIN
    isDefinition := FALSE;
    hasMain := FALSE;
    OJS.Get(sym);
    IF (sym = OJS.module) OR (sym = OJS.definition) THEN
      IF sym = OJS.definition THEN isDefinition := TRUE END ;
      OJS.Get(sym);
      IF sym = OJS.ident THEN
        Strings.Copy(OJS.id, modid); OJS.Get(sym);
      ELSE OJS.Mark("identifier expected")
      END ;
      Check(OJS.semicolon, "no ;"); level := 0; dc := 0;
      OJB.Init(outputFolder, modid); OJB.OpenScope;
      IF sym = OJS.import THEN
        OJS.Get(sym); Import;
        WHILE sym = OJS.comma DO OJS.Get(sym); Import END ;
        Check(OJS.semicolon, "; missing")
      END ;
      OJG.Open(modid); dc := Declarations(dc);
      WHILE sym = OJS.procedure DO
        ProcedureDecl; Check(OJS.semicolon, "no ;")
      END ;
      IF ~isDefinition THEN
        OJG.Header(OJB.topScope);
        OJG.MainProc(hasMain);
        OJG.ModuleBody(OJB.topScope);
        IF sym = OJS.begin THEN OJS.Get(sym); StatSequence END ;
        OJG.Return(NIL, dmy);
      END ;
      Check(OJS.end, "no END");
      IF sym = OJS.ident THEN
        IF OJS.id # modid THEN OJS.Mark("no match") END ;
        OJS.Get(sym)
      ELSE OJS.Mark("identifier missing")
      END ;
      IF sym # OJS.period THEN OJS.Mark("period missing") END ;
      IF ~isDefinition THEN OJB.CheckUnused(0) END ;
      IF OJS.errcnt = 0 THEN
        OJB.Export(modid, newSF);
      END ;
      IF OJS.errcnt = 0 THEN
        IF ~isDefinition THEN OJG.Close END ;
      ELSE OJS.Mark("compilation FAILED"); OJG.deleteModule
      END ;
      OJB.CloseScope; pbsList := NIL
    ELSE OJS.Mark("must start with MODULE or DEFINITION")
    END
  END Module;

  PROCEDURE Compile*(fname: ARRAY OF CHAR; newSym: BOOLEAN;
                     VAR outputFolder: ARRAY OF CHAR);
  BEGIN
    newSF := newSym;
    OJS.Init(fname);
    IF OJS.errcnt = 0 THEN
      Module(outputFolder)
    END
  END Compile;

BEGIN
  NEW(dummy); dummy.class := OJB.Var; dummy.type := OJB.intType;
  expression := expression0; Type := Type0; FormalType := FormalType0;
  EqualSignatures := EqualSignatures0
END OJP.
