MODULE CaseChar0;
  CONST C = "C";
  VAR i, a : CHAR;
BEGIN
  i := "B";
  CASE i OF
    "A".."C", "Z":
      a := "1"; 
    | "I".. "K":
      a := "2"; 
    | "W":
      a := "3"; 
  END;
  WriteChar(a); (* 1 *)
  CASE C OF
    22X:
      i := "4"; 
    | "A".."C", "Z":
      i := "5"; 
  END;
  WriteChar(i) (* 5 *)
END CaseChar0.