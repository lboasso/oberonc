(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

(*
  Oberon Scanner does lexical analysis. Input is UTF8 text, output is
  sequence of symbols, i.e identifiers, numbers, strings, and special symbols.
  Recognises all Oberon keywords and skips comments. The keywords are
  recorded in a table.
  Get(sym) delivers next symbol from input text.
  Mark()/MarkAppend() record error and delivers error message on
  standard output.
  If Get delivers ident, then the identifier (a string) is in variable id,
  if int or char in ival, if real in rval, and if string in str (and slen)
*)
MODULE OJS;
  IMPORT SYSTEM, Strings, Files, Out;

  CONST IdLen* = 32;
    NKW = 34;  (*nof keywords*)
    maxKWX = 11; maxKWD = 11;
    maxExp = 38; minExp = -45;
    stringBufSize* = 256; maxStrx = stringBufSize*500;
    maxSrcSize = 200000;
    maxErrMsgSize = 200;
    maxPath* = 200;

    (*lexical symbols*)
    null = 0; times* = 1; rdiv* = 2; div* = 3; mod* = 4;
    and* = 5; plus* = 6; minus* = 7; or* = 8; eql* = 9;
    neq* = 10; lss* = 11; leq* = 12; gtr* = 13; geq* = 14;
    in* = 15; is* = 16; arrow* = 17; period* = 18;
    char* = 20; int* = 21; real* = 22; false* = 23; true* = 24;
    nil* = 25; string* = 26; not* = 27; lparen* = 28; lbrak* = 29;
    lbrace* = 30; ident* = 31;
    if* = 32; while* = 34; repeat* = 35; case* = 36; for* = 37;
    comma* = 40; colon* = 41; becomes* = 42; upto* = 43; rparen* = 44;
    rbrak* = 45; rbrace* = 46; then* = 47; of* = 48; do* = 49;
    to* = 50; by* = 51; semicolon* = 52; end* = 53; bar* = 54;
    else* = 55; elsif* = 56; until* = 57; return* = 58;
    array* = 60; record* = 61; pointer* = 62; const* = 63; type* = 64;
    var* = 65; procedure* = 66; begin* = 67; import* = 68; module* = 69;
    definition* = 70; eot = 71;

  TYPE Ident* = ARRAY IdLen OF CHAR;

  VAR ival*, strpos*: INTEGER;  (*results of Get*)
    slen*: INTEGER; (*include terminal 0X*)
    rval*: REAL;
    id*: Ident;  (*for identifiers*)
    strBuf: ARRAY maxStrx OF CHAR;
    strx: INTEGER;
    errcnt*: INTEGER;

    ch: CHAR;  (*last character read*)
    errpos: INTEGER;
    pos: INTEGER;
    EOF: BOOLEAN;
    k: INTEGER;
    KWX: ARRAY maxKWX OF INTEGER;
    keyTab: ARRAY NKW OF
        RECORD sym: INTEGER; id: ARRAY maxKWD OF CHAR END;
    src: ARRAY maxSrcSize OF BYTE;
    srcSize: INTEGER;
    line, prevLine, col, prevCol: INTEGER;
    inputPath: ARRAY maxPath OF CHAR;

  PROCEDURE MarkAppend*(msg, extra: ARRAY OF CHAR);
    VAR out: ARRAY maxErrMsgSize OF CHAR;
  BEGIN
    IF (pos > errpos) & (errcnt < 25) THEN
      Strings.Append(inputPath, out);
      Strings.AppendChar(":", out);
      Strings.AppendInt(prevLine, 0, out);
      Strings.AppendChar(":", out);
      Strings.AppendInt(prevCol, 0, out);
      Strings.Append(": ", out);
      Strings.Append(msg, out);
      Out.String(out);
      Out.String(extra);
      Out.Ln;
      INC(errcnt); errpos := pos + 4
    END
  END MarkAppend;

  PROCEDURE Mark*(msg: ARRAY OF CHAR);
  BEGIN
    MarkAppend(msg, "")
  END Mark;

  PROCEDURE ExtractChar*(a: INTEGER): CHAR;
    VAR c: CHAR;
  BEGIN
    IF a < maxStrx THEN c := strBuf[a] ELSE c := 0X END
    RETURN c
  END ExtractChar;

  PROCEDURE InsertChar*(c: CHAR): INTEGER;
    VAR idx: INTEGER;
  BEGIN
    idx := strx;
    IF (strx + 1) < maxStrx THEN
        strBuf[strx] := c;
        strBuf[strx + 1] := 0X;
        INC(strx, 2)
    ELSE Mark("too many strings")
    END
    RETURN idx
  END InsertChar;

  PROCEDURE ExtractStr*(i, len: INTEGER; VAR out: ARRAY OF CHAR);
    VAR j: INTEGER;
  BEGIN
    j := 0;
    WHILE (j < len) & (i < maxStrx) & (j < LEN(out)) DO
      out[j] := strBuf[i];
      INC(i);
      INC(j)
    END
  END ExtractStr;

  PROCEDURE InsertStr*(in: ARRAY OF CHAR; len: INTEGER): INTEGER;
    VAR i, idx: INTEGER;
  BEGIN
    i := 0;
    idx := strx;
    IF (strx + len - 1) < maxStrx THEN
      WHILE len > 0 DO strBuf[strx] := in[i]; INC(strx); INC(i); DEC(len) END
    ELSE Mark("too many strings")
    END
    RETURN idx
  END InsertStr;

  PROCEDURE getUTF8(): BOOLEAN;
    VAR ok: BOOLEAN;
      x, b1, b2, b3: INTEGER;
  BEGIN
    ok := FALSE;
    ch := 0X;
    IF pos < srcSize THEN
      b1 := src[pos];
      x := ASR(b1, 4);
      CASE x OF
        0..7: (* 1 bytes format: 0xxxxxxx *)
          ch := CHR(b1); ok := TRUE
        | 12, 13: (* 2 bytes format: 110xxxxx 10xxxxxx *)
          IF pos+1 < srcSize THEN
            INC(pos);
            b2 := src[pos];
            IF AND(b2, 0C0H) # 80H THEN
              Mark("Invalid UTF8 character")
            ELSE
              ch := CHR(BOR(LSL(AND(b1, 1FH), 6), AND(b2, 3FH)));
              ok := TRUE
            END
          END
        | 14:  (* 3 bytes format: 1110xxxx 10xxxxxx 10xxxxxx *)
          IF pos+2 < srcSize THEN
            INC(pos);
            b2 := src[pos];
            INC(pos);
            b3 := src[pos];
            IF (AND(b2, 0C0H) # 80H) OR (AND(b3, 0C0H) # 80H) THEN
              Mark("Invalid UTF8 character")
            ELSE
              ch := CHR(BOR(LSL(AND(b1, 0FH), 12),
                            BOR(LSL(AND(b2, 3FH), 6), AND(b3, 3FH))));
              ok := TRUE
            END
          END
        | 8..11, 15:
         (* ERROR + 4 bytes format: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx *)
          Mark("Invalid UTF8 character")
      END
    END
    RETURN ok
  END getUTF8;

  PROCEDURE read();
  BEGIN
    IF getUTF8() THEN
      IF ch = 0AX THEN (* 0AX = \n *)
        col := 0;
        INC(line)
      ELSE
        INC(col);
      END ;
      INC(pos)
    ELSE
      EOF := TRUE;
      ch := 0X
    END
  END read;

  PROCEDURE GetLine*(): INTEGER;
    RETURN line
  END GetLine;

  PROCEDURE Identifier(VAR sym: INTEGER);
    VAR i, k: INTEGER;
  BEGIN i := 0;
    REPEAT
      IF i < IdLen-1 THEN id[i] := ch; INC(i) END ;
      read
    UNTIL (ch < "0") OR (ch > "9") & (ch < "A") OR (ch > "Z") & (ch < "a") OR
          (ch > "z");
    id[i] := 0X;
    IF i < maxKWX THEN k := KWX[i-1];  (*search for keyword*)
      WHILE (k < KWX[i]) & (id # keyTab[k].id) DO INC(k) END ;
      IF k < KWX[i] THEN sym := keyTab[k].sym ELSE sym := ident END
    ELSE sym := ident
    END
  END Identifier;

  PROCEDURE String;
  BEGIN read;
    strpos := strx;
    WHILE ~EOF & (ch # 22X) DO (* 22X = " *)
      IF ch >= " " THEN
        IF strx < maxStrx-1 THEN
          strBuf[strx] := ch; INC(strx)
        ELSE
          Mark("string too long")
        END
      END ;
      read
    END ;
    IF strx < maxStrx THEN strBuf[strx] := 0X; INC(strx) END;
    read; slen := strx-strpos
  END String;

  PROCEDURE HexString;
    VAR m, n: INTEGER;
  BEGIN read;
    strpos := strx;
    WHILE ~EOF & (ch # "$") DO
      WHILE ~EOF & (ch <= " ") DO read END ;  (*skip*)
      IF ("0" <= ch) & (ch <= "9") THEN m := ORD(ch) - ORD("0")
      ELSIF ("A" <= ch) & (ch <= "F") THEN m := ORD(ch) - ORD("7")
      ELSE m := 0; Mark("hexdig expected")
      END ;
      read;
      IF ("0" <= ch) & (ch <= "9") THEN n := ORD(ch) - ORD("0")
      ELSIF ("A" <= ch) & (ch <= "F") THEN n := ORD(ch) - ORD("7")
      ELSE n := 0; Mark("hexdig expected")
      END ;
      IF strx < maxStrx THEN
        strBuf[strx] := CHR(m*10H + n); INC(strx)
      ELSE
        Mark("string too long")
      END ;
      read
    END ;
    read; slen := strx-strpos  (*no 0X appended*)
  END HexString;

  PROCEDURE Ten(e: INTEGER): REAL;
    VAR x, t: REAL;
  BEGIN x := 1.0; t := 10.0;
    WHILE e > 0 DO
      IF ODD(e) THEN x := t * x END ;
      t := t * t; e := e DIV 2
    END ;
    RETURN x
  END Ten;

  PROCEDURE Number(VAR sym: INTEGER);
    CONST max = 2147483647 (*2^31 - 1*);
      maxChar = 0FFFFH ;
    VAR i, k, e, n, s, h: INTEGER; x: REAL;
      d: ARRAY 16 OF INTEGER;
      negE: BOOLEAN;
  BEGIN ival := 0; i := 0; n := 0; k := 0;
    REPEAT
      IF n < 16 THEN
         d[n] := ORD(ch)-ORD("0"); INC(n)
      ELSE
        Mark("too many digits"); n := 0
      END ;
      read
    UNTIL (ch < "0") OR (ch > "9") & (ch < "A") OR (ch > "F");
    IF (ch = "H") OR (ch = "R") OR (ch = "X") THEN  (*hex*)
      REPEAT h := d[i];
        (* ex . ORD("A")-ORD("0") = 65-48 = 17 -> 17-7 = 10 *)
        IF h >= 10 THEN h := h-7 END ;
        k := k*10H + h; INC(i) (*no overflow check*)
      UNTIL i = n;
      IF ch = "X" THEN sym := char;
        IF k <= maxChar THEN ival := k ELSE Mark("illegal value"); ival := 0 END
      ELSIF ch = "R" THEN sym := real; rval := SYSTEM.VAL(REAL, k)
      ELSE sym := int; ival := k
      END ;
      read
    ELSIF ch = "." THEN
      read;
      IF ch = "." THEN (*double dot*) ch := 7FX;  (*decimal integer*)
        REPEAT
          IF d[i] < 10 THEN
            IF k <= (max-d[i]) DIV 10 THEN
              k := k *10 + d[i]
            ELSE Mark("too large");
              k := 0
            END
          ELSE Mark("bad integer")
          END ;
          INC(i)
        UNTIL i = n;
        sym := int; ival := k
      ELSE (*real number*) x := 0.0; e := 0;
        REPEAT  (*integer part*) x := x * 10.0 + FLT(d[i]); INC(i) UNTIL i = n;
        WHILE (ch >= "0") & (ch <= "9") DO  (*fraction*)
          x := x * 10.0 + FLT(ORD(ch) - ORD("0")); DEC(e); read
        END ;
        IF (ch = "E") OR (ch = "D") THEN  (*scale factor*)
          read; s := 0;
          IF ch = "-" THEN negE := TRUE; read
          ELSE negE := FALSE;
            IF ch = "+" THEN read END
          END ;
          IF (ch >= "0") & (ch <= "9") THEN
            REPEAT s := s*10 + ORD(ch)-ORD("0"); read
            UNTIL (ch < "0") OR (ch >"9");
            IF negE THEN e := e-s ELSE e := e+s END
          ELSE Mark("digit?")
          END
        END ;
        IF e < 0 THEN
          IF e >= minExp THEN x := x / Ten(-e) ELSE x := 0.0 END
        ELSIF e > 0 THEN
          IF e <= maxExp THEN
            x := Ten(e) * x
          ELSE
            x := 0.0; Mark("too large")
          END
        END ;
        sym := real; rval := x
      END
    ELSE  (*decimal integer*)
      REPEAT
        IF d[i] < 10 THEN
          IF k <= (max-d[i]) DIV 10 THEN
            k := k*10 + d[i]
          ELSE
            Mark("too large"); k := 0
          END
        ELSE Mark("bad integer")
        END ;
        INC(i)
      UNTIL i = n;
      sym := int; ival := k
    END
  END Number;

  PROCEDURE comment;
    VAR level: INTEGER;
  BEGIN
    level := 1; read;
    WHILE ~EOF & (level > 0) DO
      IF ch = "(" THEN read;
        IF ch = "*" THEN INC(level); read END
      ELSIF ch = "*" THEN read;
        IF ch = ")" THEN DEC(level); read END
      ELSE read
      END
    END ;
    IF level # 0 THEN Mark("unterminated comment") END
  END comment;

  PROCEDURE Get*(VAR sym: INTEGER);
  BEGIN
    prevLine := line;
    prevCol := col;
    REPEAT
      WHILE ~EOF & (ch <= " ") DO read END;
      IF EOF THEN sym := eot
      ELSIF ch <= 7FX THEN
        CASE ch OF (* " " < ch <= 7FX *)
          "!", "%", "'", "?", "@", "\", "_", "`": read; sym := null
          | 22X : String; sym := string
          | "#" : read; sym := neq
          | "$" : HexString; sym := string
          | "&" : read; sym := and
          | "(" : read;
                  IF ch = "*" THEN sym := null; comment
                  ELSE sym := lparen END
          | ")" : read; sym := rparen
          | "*" : read; sym := times
          | "+" : read; sym := plus
          | "," : read; sym := comma
          | "-" : read; sym := minus
          | "." : read;
                  IF ch = "." THEN read; sym := upto
                  ELSE sym := period END
          | "/" : read; sym := rdiv
          | "0".."9": Number(sym)
          | ":" : read;
                  IF ch = "=" THEN read; sym := becomes
                  ELSE sym := colon END
          | ";" : read; sym := semicolon
          | "<" : read;
                  IF ch = "=" THEN read; sym := leq
                  ELSE sym := lss END
          | "=" : read; sym := eql
          | ">" : read;
                  IF ch = "=" THEN read; sym := geq
                  ELSE sym := gtr END
          | "A".."Z": Identifier(sym)
          | "[" : read; sym := lbrak
          | "]" : read; sym := rbrak
          | "^" : read; sym := arrow
          | "a".."z": Identifier(sym)
          | "{" : read; sym := lbrace
          | "|" : read; sym := bar
          | "}" : read; sym := rbrace
          | "~" : read; sym := not
          | 7FX : read; sym := upto
        END
      ELSE read; sym := null
      END
    UNTIL sym # null
  END Get;

  PROCEDURE Init*(path: ARRAY OF CHAR);
    VAR f: Files.File;
      n, len: INTEGER;
  BEGIN
    pos := 0; line := 1; col := 0;
    EOF := FALSE; errpos := -1; errcnt := 0;
    Strings.Copy(path, inputPath);
    f := Files.Open(path);
    IF f = NIL THEN
      Mark("file not found")
    ELSE
      len := Files.Size(f);
      IF (len = -1) OR (len >= maxSrcSize) THEN
        Mark("file too big")
      ELSE
        Files.ReadBytes(f, src, n);
        srcSize := n;
        IF Files.Status(f) # Files.OK THEN
          Mark("error while reading the file")
        END ;
        read
      END ;
      Files.Close(f)
    END
  END Init;

  PROCEDURE InitStr*(s: ARRAY OF BYTE);
  BEGIN
    pos := 0;
    line := 1;
    col := 0;
    EOF := FALSE;
    errpos := -1;
    errcnt := 0;
    src := s;
    srcSize := LEN(s);
    read
  END InitStr;

  PROCEDURE EnterKW(sym: INTEGER; name: ARRAY OF CHAR);
  BEGIN keyTab[k].id := name; keyTab[k].sym := sym; INC(k)
  END EnterKW;

BEGIN strx := 0; k := 0; KWX[0] := 0; KWX[1] := 0;
  EnterKW(if, "IF");
  EnterKW(do, "DO");
  EnterKW(of, "OF");
  EnterKW(or, "OR");
  EnterKW(to, "TO");
  EnterKW(in, "IN");
  EnterKW(is, "IS");
  EnterKW(by, "BY");
  KWX[2] := k;
  EnterKW(end, "END");
  EnterKW(nil, "NIL");
  EnterKW(var, "VAR");
  EnterKW(div, "DIV");
  EnterKW(mod, "MOD");
  EnterKW(for, "FOR");
  KWX[3] := k;
  EnterKW(else, "ELSE");
  EnterKW(then, "THEN");
  EnterKW(true, "TRUE");
  EnterKW(type, "TYPE");
  EnterKW(case, "CASE");
  KWX[4] := k;
  EnterKW(elsif, "ELSIF");
  EnterKW(false, "FALSE");
  EnterKW(array, "ARRAY");
  EnterKW(begin, "BEGIN");
  EnterKW(const, "CONST");
  EnterKW(until, "UNTIL");
  EnterKW(while, "WHILE");
  KWX[5] := k;
  EnterKW(record, "RECORD");
  EnterKW(repeat, "REPEAT");
  EnterKW(return, "RETURN");
  EnterKW(import, "IMPORT");
  EnterKW(module, "MODULE");
  KWX[6] := k;
  EnterKW(pointer, "POINTER");
  KWX[7] := k; KWX[8] := k;
  EnterKW(procedure, "PROCEDURE");
  KWX[9] := k;
  EnterKW(definition, "DEFINITION");
  KWX[10] := k
END OJS.
