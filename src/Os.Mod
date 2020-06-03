(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

DEFINITION Os;
  PROCEDURE GetEnv(VAR out: ARRAY OF CHAR; name: ARRAY OF CHAR);

  (* Get time in seconds since 2010-01-01-UTC *)
  PROCEDURE CurrentTime(): INTEGER;
END Os.