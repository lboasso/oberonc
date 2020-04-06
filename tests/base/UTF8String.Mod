MODULE UTF8String;
  VAR x : ARRAY 15 OF CHAR;
      i: INTEGER;

(*
   Comments can contain UTF8 chars: 世 界,
   and (* can be (* nested *) *)
 *)

BEGIN
  x  := "Hello, 世 界 - Ʉ";
  i := 0;
  WHILE (i < LEN(x)) & (x[i] # 0X) DO
    WriteChar(x[i]); INC(i)
  END
END UTF8String.