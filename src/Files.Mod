(*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

DEFINITION Files;
  CONST
    OK = 0;
    EOF = -1;
    IOERROR = -2;
    UTF8ERROR = -3;

  TYPE
    File = POINTER TO FileDesc;
    FileDesc = RECORD END;
  VAR
    SEPARATOR: ARRAY 2 OF CHAR;

  PROCEDURE Create(name: ARRAY OF CHAR): File;
  PROCEDURE Open(name: ARRAY OF CHAR): File;
  PROCEDURE Close(file: File);

  PROCEDURE WriteAsciiStr(file: File; str: ARRAY OF CHAR);
  PROCEDURE WriteStr(file: File; str: ARRAY OF CHAR);
  PROCEDURE Write(file: File; b: BYTE);
  PROCEDURE WriteChar(file: File; c: CHAR);
  PROCEDURE WriteBytes(file: File; b: ARRAY OF BYTE);
  PROCEDURE WriteNBytes(file: File; b: ARRAY OF BYTE; len: INTEGER);
  PROCEDURE WriteInt(file: File; x: INTEGER);
  PROCEDURE WriteNum(file: File; x: INTEGER);

  PROCEDURE ReadNum(file: File): INTEGER;
  PROCEDURE Read(file: File): BYTE;
  PROCEDURE ReadChar(file: File): CHAR;
  PROCEDURE ReadInt(file: File): INTEGER;
  PROCEDURE ReadBytes(file: File; VAR b: ARRAY OF BYTE; VAR n: INTEGER);
  PROCEDURE ReadAsciiStr(file: File; VAR str: ARRAY OF CHAR);
  PROCEDURE ReadStr(file: File; VAR str: ARRAY OF CHAR): INTEGER;

  PROCEDURE Status(file: File): INTEGER;
  PROCEDURE Rename(from, to: ARRAY OF CHAR): INTEGER;
  PROCEDURE Exists(name: ARRAY OF CHAR): BOOLEAN;
  PROCEDURE Delete(name: ARRAY OF CHAR): INTEGER;
  PROCEDURE Seek(file: File; pos: INTEGER): INTEGER;
  PROCEDURE Size(file: File): INTEGER;
END Files.
