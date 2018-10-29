MODULE RecordAndTypeExtension;
  TYPE
    A = RECORD
          x : INTEGER;
          next : POINTER TO A;
          next2 : POINTER TO RECORD y : REAL END;
        END;
    B = RECORD(A) b : INTEGER END;
    C = RECORD(A) c : BOOLEAN END;
    PTRA = POINTER TO A;
    PTRB = POINTER TO B;
    PTRC = POINTER TO C;
  VAR
    pa : PTRA;
    pb : POINTER TO B;
    a : A;
    b : B;
    k : INTEGER;

  PROCEDURE PrintBool(x : BOOLEAN);
  BEGIN
    IF x THEN WriteInt(1) ELSE WriteInt(0) END;
    WriteLn
  END PrintBool;

  PROCEDURE testRelation;
    VAR a, b : PTRA;
  BEGIN 
    NEW(a);
    b := NIL;
    PrintBool(NIL = b);
    PrintBool(b = NIL);
    PrintBool(NIL # b);
    PrintBool(b # NIL);
    PrintBool(a = b);
    PrintBool(a # b);
    b := a;
    PrintBool(a = b);
    PrintBool(a # b);
  END testRelation;

  PROCEDURE typeTest(VAR a3 : A);
    VAR
      pa2 : POINTER TO A;
      pa2T : PTRA;
      pb2 : POINTER TO B;
      b2 : B;
  BEGIN
    b2 := a3(B);
    WriteInt(b2.b); (* 8 *)
    NEW(pb2);
    pb2.x := 9;
    pb2.b := 15;
    pa2 := pb2;
    WriteInt(pa2.x); (* 9 *)
    pa2.x := 10;
    WriteInt(pb2.x); (* 10 *)
    pa2T := pb2;
    WriteInt(pa2T.x); (* 10 *)
    k := a3(B).b;
    WriteInt(k); (* 8 *)
    (* k := pa2(B).b; incompatible types *)
    (* k := pa2T(B).b; incompatible types *)
    k := a3(A).x;
    WriteInt(k); (* 7 *)
    (* k := pa2(A).x; incompatible types *)
    (* k := pa2T(A).x; incompatible types *)
    (* PrintBool(i IS INTEGER); incompatible types *)
    (* k := a3(PTRB).b; incompatible types *)
    k := pa2(PTRB).b;
    WriteInt(k); (* 15 *)
    k := pa2T(PTRB).b;
    WriteInt(k); (* 15 *)
    (* k := a3(PTRA).x; incompatible types *)
    k := pa2(PTRA).x; (* Todo: here we generate an unnecessary CHECKCAST *)
    WriteInt(k); (* 10 *)
    k := pa2T(PTRA).x;
    WriteInt(k); (* 10 *)
    PrintBool(a3 IS B);
    (* PrintBool(pa2 IS B); incompatible types *)
    (*PrintBool(pa2T IS B); incompatible types *)
    PrintBool(a3 IS A);
    (* PrintBool(pa2 IS A); incompatible types *)
    (* PrintBool(pa2T IS A); incompatible types *)
    (* PrintBool(a3 IS PTRB); incompatible types *)
    PrintBool(pa2 IS PTRB);
    PrintBool(pa2T IS PTRB);
    (* PrintBool(a3 IS PTRA); incompatible types *)
    PrintBool(pa2 IS PTRA);
    PrintBool(pa2T IS PTRA);
    PrintBool(pa2T IS PTRC);
  END typeTest;

  PROCEDURE localPointer;
    VAR
      pa2 : POINTER TO A;
      pb2 : POINTER TO B;
      a2 : A;
      b2 : B;
      arr2 : ARRAY 1 OF POINTER TO A;
      mulArr2 : ARRAY 1,3 OF POINTER TO A;
  BEGIN
    pa2 := NIL;
    NEW(pa2);
    pa2.x := 10;
    a2 := pa2^;
    WriteInt(a2.x); (* 10 *)
    pa2.x := 11;
    a2.x := pa2^.x;
    WriteInt(a2.x); (* 11 *)
    a2.x := pa2.x;
    WriteInt(a2.x); (* 11 *)
    a := pa2^;
    NEW(arr2[0]);
    NEW(mulArr2[0][2]);
    mulArr2[0][2].x := 12;
    NEW(a2.next2);
    NEW(pb2);
    pb2.x := 99;
    b2.x := 13;
    a2 := b2;
    WriteInt(a2.x); (* 13 *)
    pa2 := pb2;
    WriteInt(pa2.x); (* 99 *)
  END localPointer;
  PROCEDURE NewPar(VAR x : PTRA);
  BEGIN NEW(x) END NewPar;

BEGIN
  WriteInt(a.x); (* 0 *)
  localPointer;
  WriteInt(a.x); (* 11 *)
  WriteLn;
  (* varRuntimeCheck(b); this fails with an ArrayStoreException as expected.
     Maybe we should use our own Trap instead: 'type guard failure'*)
  b.b := 8;
  b.x := 7;
  typeTest(b);
  NewPar(pa);
  testRelation;
  NEW(pb);
  pa := pb;
  PrintBool(pa = pb)
END RecordAndTypeExtension.