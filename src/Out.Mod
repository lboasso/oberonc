(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

(* Simple procedures to print to standard output *)
DEFINITION Out;
  PROCEDURE Char(ch: CHAR);
  PROCEDURE String(str: ARRAY OF CHAR);
  PROCEDURE Real(x: REAL; n: INTEGER);
  PROCEDURE Int(x, n: INTEGER);
  PROCEDURE Ln;
  PROCEDURE Hex(x: INTEGER);
END Out.