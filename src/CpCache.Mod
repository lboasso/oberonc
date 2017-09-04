(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

(* A string to integer map used by ClassFormat *)
MODULE CpCache;
  IMPORT Strings, OJS;
  CONST
    N = 997; (* prime number *)
    R = 31; (* prime number *)
    MaxKey* = OJS.stringBufSize;

  TYPE
    Node = POINTER TO NodeDesc;
    Key* = ARRAY MaxKey OF CHAR;
    NodeDesc = RECORD
      key: Key;
      val: INTEGER;
      next: Node
    END;
    Cache* = POINTER TO CacheDesc;
    CacheDesc* = RECORD
       map: ARRAY N OF Node;
    END;


  PROCEDURE hash(s: ARRAY OF CHAR): INTEGER;
    VAR h, i, len: INTEGER;
  BEGIN
    h := 0;
    i := 0;
    len := LEN(s);
    WHILE (i < len) & (s[i] # 0X) DO
      h := R * h + ORD(s[i]);
      INC(i)
    END
    (* MOD is >= 0 when N > 0 *)
    RETURN h MOD N
  END hash;

  PROCEDURE get*(m: Cache; k: ARRAY OF CHAR): INTEGER;
    VAR h, ret: INTEGER;
      c: Node;
  BEGIN
    h := hash(k);
    c := m.map[h];
    WHILE (c # NIL) & (c.key # k) DO
      c := c.next
    END;
    IF c = NIL THEN
      ret := -1
    ELSE
      ret := c.val
    END;
    RETURN ret
  END get;

  PROCEDURE put*(m: Cache; k: ARRAY OF CHAR; v: INTEGER);
    VAR h: INTEGER;
      r, c, tmp: Node;
  BEGIN
    h := hash(k);
    r := m.map[h];
    c := r;
    WHILE (c # NIL) & (c.key # k) DO
      c := c.next
    END;
    IF c = NIL THEN
      NEW(tmp);
      Strings.Copy(k, tmp.key);
      tmp.val := v;
      tmp.next := r;
      m.map[h] := tmp
    ELSE
      c.val := v
    END
  END put;

  PROCEDURE New*(): Cache;
    VAR c: Cache;
  BEGIN
    NEW(c);
    RETURN c
  END New;
END CpCache.
