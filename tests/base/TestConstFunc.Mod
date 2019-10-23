MODULE TestConstFunc;
  IMPORT SYSTEM;
  CONST
    negReal = -2.5;
    posReal = 3.2;
    posInt = 2;
    a = "A";
    intA = 65;
    abs = ABS(negReal);
    odd = ODD(posInt);
    floor = FLOOR(posReal);
    flt = FLT(posInt);
    ord = ORD(a);
    chr = CHR(intA);
    lsl = LSL(intA, posInt);
    asr = ASR(intA, posInt);
    ror = ROR(intA, posInt);
    and = AND(intA, posInt);
    bor = BOR(intA, posInt);
    not = NOT(intA);
    set = {5};
    int = SYSTEM.VAL(INTEGER, set);
  TYPE arr5 = ARRAY 5 OF INTEGER;
       ARR = ARRAY 3 OF INTEGER;
  VAR
    r: REAL; i, j: INTEGER; c: CHAR;
    z: ARRAY 5 OF INTEGER; s: SET;
    y: ARRAY 4 OF ARR;

  PROCEDURE WriteBool(b: BOOLEAN);
  BEGIN
    WriteInt(ORD(b))
  END WriteBool;

  PROCEDURE LenP(a0: ARRAY OF INTEGER; a1: arr5; VAR a2: ARRAY OF ARR);
    CONST
       (* len0 = LEN(a0); ERROR expression not constant *)
       len1 = LEN(a1);
       len2 = LEN(a2[0]);
       len3 = AND(LEN(a2[0]), 1);
     VAR u: INTEGER;
  BEGIN
    u := 1;
    a2[0][u] := 1;
    WriteInt(len1); WriteInt(LEN(a1));
    WriteInt(len2); WriteInt(LEN(a2[0]));
    WriteInt(len3);  WriteInt(AND(LEN(a2[0]), a2[0][u]))
  END LenP;


  PROCEDURE P;
    CONST
      negReal = -2.5;
      posReal = 3.2;
      posInt = 2;
      a = "A";
      intA = 65;
      abs = ABS(negReal);
      odd = ODD(posInt);
      floor = FLOOR(posReal);
      flt = FLT(posInt);
      ord = ORD(a);
      chr = CHR(intA);
      lsl = LSL(intA, posInt);
      asr = ASR(intA, posInt);
      ror = ROR(intA, posInt);
      and = AND(intA, posInt);
      bor = BOR(intA, posInt);
      not = NOT(intA);
      set = {5};
      int = SYSTEM.VAL(INTEGER, set);
    TYPE arr5 = ARRAY 5 OF INTEGER;
         ARR = ARRAY 3 OF INTEGER;
    VAR
      r: REAL; i, j: INTEGER; c: CHAR;
      z: ARRAY 5 OF INTEGER; s: SET;
      y: ARRAY 4 OF ARR;
    BEGIN
      r := negReal;
      WriteReal(abs); WriteReal(ABS(r)); WriteLn;
      i := posInt;
      WriteBool(odd); WriteBool(ODD(i)); WriteLn;
      r := posReal;
      WriteInt(floor); WriteInt(FLOOR(r)); WriteLn;
      i := posInt;
      WriteReal(flt); WriteReal(FLT(i)); WriteLn;
      c := a;
      WriteInt(ord); WriteInt(ORD(c)); WriteLn;
      i := intA;
      WriteChar(chr); WriteChar(CHR(i)); WriteLn;
      LenP(z, z, y); WriteLn;
      i := intA;
      j := posInt;
      WriteInt(lsl); WriteInt(LSL(i, j)); WriteLn;
      WriteInt(asr); WriteInt(ASR(i, j)); WriteLn;
      WriteInt(ror); WriteInt(ROR(i, j)); WriteLn;
      WriteInt(and); WriteInt(AND(i, j)); WriteLn;
      WriteInt(bor); WriteInt(BOR(i, j)); WriteLn;
      WriteInt(not); WriteInt(NOT(i)); WriteLn;
      s := set;
      WriteInt(int); WriteInt(SYSTEM.VAL(INTEGER, s)); WriteLn;
  END P;

BEGIN
  r := negReal;
  WriteReal(abs); WriteReal(ABS(r)); WriteLn;
  i := posInt;
  WriteBool(odd); WriteBool(ODD(i)); WriteLn;
  r := posReal;
  WriteInt(floor); WriteInt(FLOOR(r)); WriteLn;
  i := posInt;
  WriteReal(flt); WriteReal(FLT(i)); WriteLn;
  c := a;
  WriteInt(ord); WriteInt(ORD(c)); WriteLn;
  i := intA;
  WriteChar(chr); WriteChar(CHR(i)); WriteLn;
  LenP(z, z, y); WriteLn;
  i := intA;
  j := posInt;
  WriteInt(lsl); WriteInt(LSL(i, j)); WriteLn;
  WriteInt(asr); WriteInt(ASR(i, j)); WriteLn;
  WriteInt(ror); WriteInt(ROR(i, j)); WriteLn;
  WriteInt(and); WriteInt(AND(i, j)); WriteLn;
  WriteInt(bor); WriteInt(BOR(i, j)); WriteLn;
  WriteInt(not); WriteInt(NOT(i)); WriteLn;
  s := set;
  WriteInt(int); WriteInt(SYSTEM.VAL(INTEGER, s)); WriteLn;
  P
END TestConstFunc.