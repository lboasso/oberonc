(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

MODULE oberonc;
IMPORT OJS, OJP, Out, Strings;

  PROCEDURE Help;
  BEGIN
    Out.String("Oberon-07 compiler v1.X"); Out.Ln;
    Out.Ln;
    Out.String("Usage: oberonc outputFolder sourceFile1.Mod[+] sourceFile2.Mod[+] ..."); Out.Ln;
    Out.Ln;
    Out.String("It compiles the list of provided source module files and places the generated"); Out.Ln;
    Out.String("classes in the existing 'outputFolder'."); Out.Ln;
    Out.String("The optional suffix '+' allows the compiler to create a new symbol file. If this"); Out.Ln;
    Out.String("option is not specified, a change in the interface of the module results in a"); Out.Ln;
    Out.String("compilation error."); Out.Ln;
  END Help;

  PROCEDURE Main;
    VAR i, len, n: INTEGER;
      folder, arg: ARRAY OJS.maxPath OF CHAR;
      newSym: BOOLEAN;
  BEGIN
    n := ARGNUM();
    IF n < 2 THEN
      Help
    ELSE
      ARGS(0, folder);
      FOR i := 1 TO n-1 DO
        ARGS(i, arg);
        len := Strings.Length(arg);
        IF arg[len-1] = "+" THEN
          newSym := TRUE;
          arg[len-1] := 0X
        END ;
        OJP.Compile(arg, newSym, folder)
      END
    END
  END Main;
END oberonc.
