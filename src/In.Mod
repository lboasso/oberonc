(*
  Copyright 2019 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

(*
  Simple procedures to read from standard input in an interactive fashion.

  Done. Indicates the success of an input operation. If Done is TRUE after an
  input operation, the operation was successful and its result is valid.
  An unsuccessful input operation sets Done to FALSE; it remains FALSE until
  the next successful input operation.

  Each procedure reads an entire line of input and fills its parameter with
  input data when successful. Any remaining input in the input line is
  discarded.
*)
DEFINITION In;
  VAR Done: BOOLEAN;
  PROCEDURE Char(VAR ch: CHAR);
  PROCEDURE String(VAR str: ARRAY OF CHAR);
  PROCEDURE Real(VAR x: REAL);
  PROCEDURE Int(VAR x: INTEGER);
END In.