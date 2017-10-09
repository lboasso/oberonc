MODULE RecordAssignment2;
  TYPE RP = POINTER TO R;
    R = RECORD
          i: INTEGER;
          a: ARRAY 10 OF RP;
          p: RP;
        END;
  VAR
  gbl0, gbl1 : RP;

  PROCEDURE Init(VAR x: R; i: INTEGER);
  BEGIN
    x.i := i;
    NEW(x.a[2]);
    x.a[2].i := i;
    NEW(x.p);
    x.p.i := i;
  END Init;

  PROCEDURE Print(x: R);
  BEGIN
    WriteInt(x.i);
    WriteInt(x.a[2].i);
    WriteInt(x.p.i);
    WriteLn
  END Print;

  PROCEDURE Run(local: RP; x: R);
    VAR y: R;
  BEGIN
    Init(y, 1);
    y := x;
    Print(y); (* 8   8   8 *)

    Init(gbl0^, 2);
    gbl0^ := x;
    Print(gbl0^); (* 8   8   8 *)

    Init(gbl0^, 3);
    gbl0^ := local^;
    Print(gbl0^); (* 8   8   8 *)

    Init(gbl0^.a[2]^, 4);
    gbl0^.a[2]^ := local^;
    Print(gbl0^.a[2]^); (* 8   8   8 *)

    Init(gbl0^.p^, 5);
    gbl0^.p^ := local^;
    Print(gbl0^.p^); (* 8   8   8 *)

    Init(gbl0^.p^.p^, 6);
    gbl0^.p^.p^ := local^;
    Print(gbl0^.p^.p^) (* 8   8   6 *)

  END Run;

BEGIN
  NEW(gbl0); NEW(gbl1);
  Init(gbl1^, 8);
  Run(gbl1, gbl1^)
END RecordAssignment2.
