MODULE TestAssignmentMix;
  TYPE A = RECORD i : INTEGER END;
       B = RECORD(A) j : REAL END;
       TA = ARRAY 1 OF A;
       TB = ARRAY 1 OF B;
  VAR
       (*ta : TA;
       tb : TB;*)
       a : A;
       b : B;
       pa : POINTER TO A;
       pb : POINTER TO B;
       (*ta2 : ARRAY 1 OF A;
       tb2 : ARRAY 1 OF B;*)
BEGIN
  (*b := a;  illegal assignment *)
  a := b; 
  (* pb := pa; illegal assignment *)
  pa := pb;
  (* tb := ta;  illegal assignment *)
  (* tb2 := ta2;  illegal assignment *)
  (* ta := tb;  illegal assignment *)
  (* ta2 := tb2; illegal assignment *)
END TestAssignmentMix.
