MODULE EmptyArrayAndRecord;
  TYPE
    EMPTY0 = RECORD  END;
    EMPTY2 = RECORD e : RECORD END END;
    EMPTY3 = RECORD e : ARRAY 0 OF INTEGER END;
    EMPTY4 = RECORD e : ARRAY 0, 2 OF EMPTY0 END;
    EMPTY5 = RECORD e : ARRAY 2, 0 OF EMPTY0 END;
    EMPTY6 = RECORD i : INTEGER; e : ARRAY 2, 0 OF EMPTY0 END;
    AEMPTY = ARRAY 0 OF INTEGER;
    AEMPTY2 = ARRAY 0, 2 OF INTEGER;
    AEMPTY3 = ARRAY 0, 2 OF EMPTY0;
    AEMPTY4 = ARRAY 2, 0 OF EMPTY0;
  VAR 
    empty0, empty1 : EMPTY0;
    empty2, empty3 : EMPTY2;
    empty4, empty5 : EMPTY3;
    empty6, empty7 : EMPTY4;
    empty8, empty9 : EMPTY5;
    empty10, empty11 : EMPTY6;
    aempty0, aempty1 : AEMPTY;
    aempty2, aempty3 : AEMPTY2;
    aempty4, aempty5 : AEMPTY3;
    aempty6, aempty7 : AEMPTY4;
    x, y : ARRAY 1 OF EMPTY0;
    y0, y1 : ARRAY 2, 0 OF EMPTY0;
    y2, y3 : ARRAY 3 OF RECORD i : INTEGER; j : ARRAY 0 OF EMPTY0; END;
    e : EMPTY0;
    i : INTEGER;
BEGIN 
  empty0 := empty1;
  empty2 := empty3;
  empty4 := empty5;
  empty6 := empty7;
  empty8 := empty9;
  empty10 := empty11;
  aempty0 := aempty1;
  aempty2 := aempty3;
  aempty4 := aempty5;
  aempty6 := aempty7;
  x := y;
  x[i] := e;
  y0 := y1;
  y2[i].j := y3[i].j;
  i := 10;
  WriteInt(i);
END EmptyArrayAndRecord.