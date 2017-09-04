MODULE TestStringsMod;
IMPORT Strings;

  VAR l: INTEGER; 
    buf, tmp: ARRAY 30 OF CHAR;
    buf0, tmp0: ARRAY 0 OF CHAR;
    buf2: ARRAY 2 OF CHAR;
    buf3: ARRAY 3 OF CHAR;
    buf8: ARRAY 8 OF CHAR;

  PROCEDURE Print(x : ARRAY OF CHAR);
    VAR i,j : INTEGER;
  BEGIN
    i := 0;
    j := LEN(x);
    WriteChar("'");
    WHILE (i < j) & (x[i] # 0X) DO
      WriteChar(x[i]);
      INC(i)
    END;
    WriteChar("'");
    WriteLn
  END Print;
  
BEGIN
  Strings.Append("Hello...", buf);
  Strings.Append(" World!", buf);
  Print(buf);
  Strings.Insert("cruel", 8, buf);
  Print(buf);
  Strings.Delete(buf, 8, Strings.Length("cruel"));
  l := Strings.Pos("Worl", buf, 0);
  Strings.Extract(buf, l, 5, tmp);
  Strings.Cap(tmp);
  Print(tmp);
  Strings.Replace(tmp, l, buf);
  Print(buf);
  buf[0] := 0X;
  tmp[0] := 0X;
  Strings.Append("Hello...", buf0);
  Strings.Append(" World!", buf0);
  Print(buf0);
  Strings.Insert("cruel", 8, buf0);
  Print(buf0);
  Strings.Delete(buf0, 8, Strings.Length("cruel"));
  l := Strings.Pos("Worl", buf0, 0);
  Strings.Extract(buf0, l, 5, tmp);
  Strings.Cap(tmp);
  Print(tmp);
  Strings.Replace(tmp, l, buf0);
  Print(buf0);
  Strings.Append("Hello...", buf);
  Strings.Append(" World!", buf);
  Print(buf);
  Strings.Insert("cruel", 8, buf);
  Print(buf);
  Strings.Delete(buf, 8, Strings.Length("cruel"));
  l := Strings.Pos("Worl", buf, 0);
  Strings.Extract(buf, l, 5, tmp0);
  Strings.Cap(tmp0);
  Print(tmp0);
  Strings.Replace(tmp0, l, buf);
  Print(buf);
  Strings.Append("Hello...", buf0);
  Strings.Append(" World!", buf0);
  Print(buf0);
  Strings.Insert("cruel", 8, buf0);
  Print(buf0);
  Strings.Delete(buf0, 8, Strings.Length("cruel"));
  l := Strings.Pos("Worl", buf0, 0);
  Strings.Extract(buf0, l, 5, tmp0);
  Strings.Cap(tmp0);
  Print(tmp0);
  Strings.Replace(tmp0, l, buf0);
  Print(buf0);
  Strings.Copy("House", buf0);
  Print(buf0);
  Strings.Copy("House", buf);
  Print(buf);
  buf2[0] := "A";
  buf2[1] := "B";
  Print(buf2);
  Strings.Copy("House", buf2);
  Print(buf2);
  Strings.AppendChar("$", buf0);
  Print(buf0);
  Strings.AppendChar("$", buf2);
  Print(buf2);
  Strings.AppendChar("$", buf);
  Print(buf);

  buf3[0] := 0X;
  Strings.AppendInt(-2, -1, buf3);
  Print(buf3); (* '-2' *)
  buf3[0] := 0X;
  Strings.AppendInt(-2, 0, buf3);
  Print(buf3); (* '-2' *)
  buf3[0] := 0X;
  Strings.AppendInt(-2, 1, buf3);
  Print(buf3); (* '-2' *)
  buf3[0] := 0X;
  Strings.AppendInt(-2, 2, buf3);
  Print(buf3); (* '-2' *)

  buf3[0] := 0X;
  Strings.AppendInt(2, -1, buf3);
  Print(buf3); (* '2' *)
  buf3[0] := 0X;
  Strings.AppendInt(2, 0, buf3);
  Print(buf3); (* '2' *)
  buf3[0] := 0X;
  Strings.AppendInt(2, 1, buf3);
  Print(buf3); (* '2' *)
  buf3[0] := 0X;
  Strings.AppendInt(2, 2, buf3);
  Print(buf3); (* ' 2' *)

  buf3[0] := 0X;
  Strings.AppendInt(20, -1, buf3);
  Print(buf3); (* '20' *)
  buf3[0] := 0X;
  Strings.AppendInt(20, 0, buf3);
  Print(buf3); (* '20' *)
  buf3[0] := 0X;
  Strings.AppendInt(20, 1, buf3);
  Print(buf3); (* '20' *)
  buf3[0] := 0X;
  Strings.AppendInt(20, 2, buf3);
  Print(buf3); (* '20' *)

  buf3[0] := 0X;
  Strings.AppendInt(-20, -1, buf3);
  Print(buf3); (* '' *)
  buf3[0] := 0X;
  Strings.AppendInt(-20, 0, buf3);
  Print(buf3); (* '' *)
  buf3[0] := 0X;
  Strings.AppendInt(-20, 1, buf3);
  Print(buf3); (* '' *)
  buf3[0] := 0X;
  Strings.AppendInt(-20, 2, buf3);
  Print(buf3); (* '' *)
  
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(-2, -1, buf8);
  Print(buf8); (* 'XXXXX-2' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(-2, 0, buf8);
  Print(buf8); (* 'XXXXX-2' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(-2, 1, buf8);
  Print(buf8); (* 'XXXXX-2' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(-2, 2, buf8);
  Print(buf8); (* 'XXXXX-2' *)
  
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(2, -1, buf8);
  Print(buf8); (* 'XXXXX2' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(2, 0, buf8);
  Print(buf8); (* 'XXXXX2' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(2, 1, buf8);
  Print(buf8); (* 'XXXXX2' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(2, 2, buf8);
  Print(buf8); (* 'XXXXX 2' *)
  
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(20, -1, buf8);
  Print(buf8); (* 'XXXXX20' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(20, 0, buf8);
  Print(buf8); (* 'XXXXX20' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(20, 1, buf8);
  Print(buf8); (* 'XXXXX20' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(20, 2, buf8);
  Print(buf8); (* 'XXXXX20' *)
  
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(-20, -1, buf8);
  Print(buf8); (* 'XXXXX' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(-20, 0, buf8);
  Print(buf8); (* 'XXXXX' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(-20, 1, buf8);
  Print(buf8); (* 'XXXXX' *)
  Strings.Copy("XXXXX", buf8);
  Strings.AppendInt(-20, 2, buf8);
  Print(buf8); (* 'XXXXX' *)

  Strings.AppendInt(80000000H, 1, buf);
  Print(buf);

  l := Strings.Write("Hello", buf, 0);
  l := Strings.Write("... World!", buf, l);
  l := Strings.WriteInt(2, 2, buf, l);
  l := Strings.WriteChar("$", buf, l);
  Print(buf); (* 'Hello... World! 2$'*)
  WriteInt(l);
  WriteLn;

  l := Strings.WriteInt(2, 2, buf2, 0);
  WriteInt(l); (* -1 *)
  l := Strings.WriteChar("$", buf2, 1);
  WriteInt(l); (* -1 *)

  WriteLn;
  l := Strings.Write("Hello", buf2, 0);
  Print(buf2);
  WriteInt(l);
  WriteLn;
  l := Strings.Write("World", buf2, 2);
  Print(buf2);
  WriteInt(l)
END TestStringsMod.