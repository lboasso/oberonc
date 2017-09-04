MODULE BitFunc;
  VAR x: ARRAY 18 OF BYTE;
      i: INTEGER;
      ch: CHAR;

  PROCEDURE next(in: ARRAY OF BYTE; VAR i: INTEGER): CHAR;
    VAR x, size, b1, b2, b3: INTEGER;
      ch: CHAR;
  BEGIN
    ch := 0X;
    size := LEN(in);
    IF i < size THEN
      b1 := in[i];
      x := ASR(b1, 4);
      CASE x OF
        0..7: (* 1 bytes format: 0xxxxxxx *)
          ch := CHR(b1); INC(i)
        | 12,13: (* 2 bytes format: 110xxxxx 10xxxxxx *)
          IF i+1 < size THEN
            INC(i);
            b2 := in[i];
            IF AND(b2, 0C0H) = 80H THEN
              ch := CHR(BOR(LSL(AND(b1, 1FH), 6), AND(b2, 3FH)))
            END;
            INC(i)
          END
        | 14:  (* 3 bytes format: 1110xxxx 10xxxxxx 10xxxxxx *)
          IF i+2 < size THEN
            INC(i);
            b2 := in[i];
            INC(i);
            b3 := in[i];
            IF (AND(b2, 0C0H) = 80H) & (AND(b3, 0C0H) = 80H) THEN
              ch := CHR(BOR(LSL(AND(b1, 0FH), 12),
                            BOR(LSL(AND(b2, 3FH), 6), AND(b3, 3FH))));
            END;
            INC(i)
          END
        | 8..11, 15: (* ERROR + 4 bytes format: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx *)
          ch := 0X
      END
    END
    RETURN ch
  END next;

BEGIN
  x[0] := 041H;
  x[1] := 0D0H;
  x[2] := 094H;
  x[3] := 0D0H;
  x[4] := 0B0H;
  x[5] := 0E2H;
  x[6] := 082H;
  x[7] := 0ACH;
  x[8] := 0E4H;
  x[9] := 0B8H;
  x[10] := 096H;
  x[11] := 0E7H;
  x[12] := 095H;
  x[13] := 08CH;
  x[14] := 0F0H;
  x[15] := 000H;
  x[16] := 000H;
  x[17] := 000H;
  i := NOT(-1); (* 0 *)
  ch := next(x, i);
  WHILE ch # 0X DO
    WriteChar(ch);
    WriteInt(ORD(ch));
    WriteLn;
    ch := next(x, i)
  END
END BitFunc.