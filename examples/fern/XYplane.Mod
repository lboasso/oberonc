DEFINITION XYplane;  
  CONST erase = 0; draw = 1;
  VAR X, Y, W, H: INTEGER;

  PROCEDURE Open;
  PROCEDURE Dot(x, y, mode: INTEGER);
  PROCEDURE IsDot(x, y: INTEGER): BOOLEAN;
  PROCEDURE Key(): CHAR;
  PROCEDURE Clear;
END XYplane.