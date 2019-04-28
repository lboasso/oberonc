(*
  Strings provides a set of operations on strings (i.e., on string constants and
  character arrays, both of which contain the character 0X as a terminator).
  All positions in strings start at 0.
  Strings.Length(s)
    returns the number of characters in s up to and excluding the first 0X.
  Strings.Insert(src, pos, dst)
    inserts the string src into the string dst at position pos
    (0 <= pos <= Length(dst)).
    If pos >= Length(dst), src is appended to dst. If the size of dst is not
    large enough to hold the result of the operation, the result is truncated so
    that dst is always terminated with a 0X.
  Strings.Append(s, dst)
    has the same effect as Insert(s, Length(s), dst).
  Strings.AppendChar(c, dst)
    has the same effect as WriteChar(c, dst, Length(dst))
  Strings.AppendInt(x, n, dst)
    has the same effect as WriteInt(x, n, dst, Length(dst))
  Strings.Delete(s, pos, n)
    deletes n characters from s starting at position pos (0 <= pos < Length(s)).
    If n > Length(s) - pos, the new length of s is pos.
  Strings.Replace(src, pos, dst)
    has the same effect as Delete(dst, pos, Length(src)) followed by an
    Insert(src, pos, dst).
  Strings.Extract(src, pos, n, dst)
    extracts a substring dst with n characters from position pos
    (0 <= pos < Length(src)) in src.
    If n > Length(src) - pos, dst is only the part of src from pos to
    Length(src) - 1. If the size of dst is not large enough to hold the result
    of the operation, the result is truncated so that dst is always terminated
    with a 0X.
  Strings.Pos(pat, s, pos)
    returns the position of the first occurrence of pat in s after position
    pos (inclusive). If pat is not found, -1 is returned.
  Strings.Cap(s)
    replaces each lower case letter in s by its upper case equivalent.
  Strings.Copy(s, dst)
    has the same effect as Insert(s, 0, dst).
  Strings.Write(s, dst, at)
    write the string s (and a final 0X) in dst at position at overwriting any
    existing characters. It returns the position of the terminal 0X. If the size
    of dst is not large enough to hold the result of the operation, the result
    is truncated so that dst is always terminated with a 0X and the function
    returns -1.
  Strings.WriteChar(c, dst, at)
    write the character c in dst at position at, if the size of dst is large
    enough to hold c while keeping the terminal character 0X. It returns the
    position of terminal 0X or -1 if nothing was written.
  Strings.WriteInt(x, n, dst)
    write in dst at position at the string representation of x padded with
    blanks on the left up to a length of n. If n is too small no padding is
    applied. If the size of dst is too small to hold x and the padding, the
    function does not append any characters.  It returns the position of
    terminal 0X or -1 if nothing was written.
*)

MODULE Strings; (*HM 94-06-22, LB 2017 *)

PROCEDURE Length* (s: ARRAY OF CHAR): INTEGER;
  VAR i: INTEGER;
BEGIN
  i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END;
  RETURN i
END Length;

PROCEDURE Write* (src: ARRAY OF CHAR; VAR dest: ARRAY OF CHAR;
                  at: INTEGER): INTEGER;
  VAR i, ldest, lsrc: INTEGER;
BEGIN
  ldest := LEN(dest)-1;
  lsrc := LEN(src);
  IF (at >= 0) & (ldest > 0) & (lsrc > 0) & (at < ldest) THEN
    i := 0;
    WHILE (at < ldest) & (i < lsrc) & (src[i] # 0X) DO
      dest[at] := src[i];
      INC(at);
      INC(i)
    END;
    dest[at] := 0X;
    IF (i < lsrc) & (src[i] # 0X) THEN at := -1 END
  ELSE at := -1
  END
  RETURN at
END Write;

PROCEDURE Append* (extra: ARRAY OF CHAR; VAR dest: ARRAY OF CHAR);
  VAR n1, n2, i: INTEGER;
BEGIN
  n1 := Length(dest); n2 := Length(extra); i := 0;
  WHILE (i < n2) & (i + n1 < LEN(dest)) DO dest[i + n1] := extra[i]; INC(i) END;
  IF i + n1 < LEN(dest) THEN dest[i + n1] := 0X
  ELSIF LEN(dest) # 0 THEN dest[LEN(dest)-1] := 0X END
END Append;

PROCEDURE WriteChar* (c: CHAR; VAR dest: ARRAY OF CHAR; at: INTEGER): INTEGER;
BEGIN
  IF (at >= 0) & (at+1 < LEN(dest)) THEN
    dest[at] := c;
    dest[at+1] := 0X;
    INC(at)
  ELSE at := -1
  END
  RETURN at
END WriteChar;

PROCEDURE AppendChar* (c: CHAR; VAR dest: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := WriteChar(c, dest, Length(dest))
END AppendChar;

PROCEDURE WriteInt* (x, n: INTEGER; VAR dest: ARRAY OF CHAR;
                    at: INTEGER): INTEGER;
  VAR i, size, tot, neg: INTEGER;
    a: ARRAY 10 OF CHAR;
BEGIN
  IF ROR(x, 31) = 1 THEN at := Write(" -2147483648", dest, at)
  ELSE i := 0;
    IF x < 0 THEN DEC(n); x := -x; neg := 1 ELSE neg := 0 END;
    REPEAT
      a[i] := CHR(x MOD 10 + 30H); x := x DIV 10; INC(i)
    UNTIL x = 0;
    size := LEN(dest);
    tot := at + i + neg;
    IF n >= i THEN tot := tot + (n - i) END;
    IF (at >= 0) & (tot < size) THEN
      WHILE n > i  DO dest[at] := " "; DEC(n); INC(at) END;
      IF neg = 1 THEN dest[at] := "-"; INC(at) END;
      REPEAT DEC(i); dest[at] := a[i]; INC(at) UNTIL i = 0;
      dest[at] := 0X
    ELSE at := -1
    END
  END
  RETURN at
END WriteInt;

PROCEDURE AppendInt* (x, n: INTEGER; VAR dest: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := WriteInt(x, n, dest, Length(dest))
END AppendInt;

PROCEDURE Copy* (src: ARRAY OF CHAR; VAR dest: ARRAY OF CHAR);
  VAR i, ldest, lsrc: INTEGER;
BEGIN
  ldest := LEN(dest)-1;
  lsrc := LEN(src);
  IF (ldest > 0) & (lsrc > 0) THEN
    i := 0;
    WHILE (i < ldest) & (i < lsrc) & (src[i] # 0X) DO
      dest[i] := src[i];
      INC(i)
    END;
    dest[i] := 0X
  END
END Copy;

PROCEDURE Insert* (source: ARRAY OF CHAR; pos: INTEGER;
                   VAR dest: ARRAY OF CHAR);
  VAR n1, n2, len, i, j: INTEGER;
BEGIN
  n1 := Length(dest); n2 := Length(source); len := LEN(dest);
  IF pos < 0 THEN pos := 0 END;
  IF pos > n1 THEN Append(source, dest)
  ELSE
    (*--- make room for source*)
    IF pos + n2 < len THEN
      i := n1; j := i + n2; (*move also 0X if it is there*)
      WHILE i >= pos DO
        IF j < len THEN dest[j] := dest[i] END;
        DEC(i); DEC(j)
      END
    END;
    (*--- copy source to dest*)
    i := 0; j := pos;
    WHILE (i < n2) & (j < len) DO
      dest[j] := source[i];
      INC(i); INC(j)
    END;
    IF (j >= len) & (LEN(dest) # 0) THEN dest[len-1] := 0X END
  END
END Insert;


PROCEDURE Delete* (VAR s: ARRAY OF CHAR; pos, n: INTEGER);
  VAR len, i: INTEGER;
BEGIN
  len:=Length(s);
  IF pos < len THEN
    IF pos < 0 THEN pos:=0 END;
    IF pos + n < len THEN
      i:=pos + n; WHILE i < len DO s[i - n]:=s[i]; INC(i) END;
      IF i - n < LEN(s) THEN s[i - n]:=0X END
    ELSIF LEN(s) # 0 THEN s[pos]:=0X
    END
  END
END Delete;


PROCEDURE Replace* (source: ARRAY OF CHAR; pos: INTEGER;
                    VAR dest: ARRAY OF CHAR);
BEGIN
  Delete(dest, pos, Length(source));
  Insert(source, pos, dest)
END Replace;


PROCEDURE Extract* (source: ARRAY OF CHAR; pos, n: INTEGER;
                    VAR dest: ARRAY OF CHAR);
  VAR len, destLen, i: INTEGER;
BEGIN
  IF (LEN(dest) # 0) & (LEN(source) # 0) THEN
    len := Length(source); destLen := LEN(dest) - 1;
    IF pos < 0 THEN pos := 0 END;
    IF pos >= len THEN dest[0] := 0X
    ELSE
      i := 0;
      WHILE (pos + i <= LEN(source)) & (source[pos + i] # 0X) & (i < n) DO
        IF i < destLen THEN dest[i] := source[pos + i] END;
        INC(i)
      END;
      dest[i] := 0X
    END
  END
END Extract;


PROCEDURE Pos* (pattern, s: ARRAY OF CHAR; pos: INTEGER): INTEGER;
  VAR n1, n2, i, j, res: INTEGER; done: BOOLEAN;
BEGIN
  n1 := Length(s); n2 := Length(pattern);
  IF n2 = 0 THEN res := 0
  ELSE
    res := -1;
    done := FALSE;
    i := pos;
    WHILE ~done & (i <= n1 - n2) DO
      IF s[i] = pattern[0] THEN
        j := 1; WHILE (j < n2) & (s[i + j] = pattern[j]) DO INC(j) END;
        IF j = n2 THEN res := i; done := TRUE END
      END;
      INC(i)
    END;
  END
  RETURN res
END Pos;


PROCEDURE Cap* (VAR s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  IF LEN(s) # 0 THEN
    i := 0;
    WHILE s[i] # 0X DO
      IF ("a" <= s[i]) & (s[i] <= "z") THEN
        s[i] := CHR(ORD(s[i]) - ORD("a") + ORD("A"))
      END;
      INC(i)
    END
  END
END Cap;


PROCEDURE Match* (string, pattern: ARRAY OF CHAR): BOOLEAN;

  PROCEDURE M (name, mask: ARRAY OF CHAR; n, m: INTEGER): BOOLEAN;
    VAR res: BOOLEAN;
  BEGIN
    res := TRUE;
    WHILE (n >= 0) & (m >= 0) & (mask[m] # "*") DO
      IF name[n] # mask[m] THEN res := FALSE; n := 0; END;
      DEC(n); DEC(m)
    END;
    IF res THEN
      res := FALSE;
      (* ----- name empty | mask empty | mask ends with "*" *)
      IF m < 0 THEN res := n < 0
      ELSE
        (* ----- name empty | mask ends with "*" *)
        WHILE (m >= 0) & (mask[m] = "*") DO DEC(m) END;
        IF m < 0 THEN res := TRUE
        ELSE
          (* ----- name empty | mask still to be matched *)
          WHILE n >= 0 DO
            IF M(name, mask, n, m) THEN res := TRUE; n := 0 END;
            DEC(n)
          END
        END
      END
    END
    RETURN res
  END M;

BEGIN
  RETURN M(string, pattern, Length(string)-1, Length(pattern)-1)
END Match;

END Strings.
