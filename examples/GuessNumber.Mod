MODULE GuessNumber;
  IMPORT In, Out;
  VAR
    name: ARRAY 20 OF CHAR;
    number, left, right, old: INTEGER;
    choice: CHAR;

BEGIN
  Out.String("What's your name? ");
  In.String(name);
  Out.String("Hi "); Out.String(name); Out.Char("!"); Out.Ln;
  Out.String("Please think of a number from 0 to 50 and I'll guess it.");
  Out.Ln;
  left := 0;
  right := 50;
  number := 27;
  REPEAT
    Out.String("Is "); Out.Int(number, 3);
    REPEAT
      Out.String(" the correct number? [(h)igher (l)ower (c)orrect] ");
      In.Char(choice)
    UNTIL In.Done & ((choice = "h") OR (choice = "l") OR (choice = "c"));
    IF choice = "h" THEN left := number + 1
    ELSIF choice = "l" THEN right := number - 1
    END ;
    old := number;
    number := left + (right - left) DIV 2;
    IF (choice # "c") & (number = old) THEN
       Out.Ln; Out.String("You lied :)");
       choice := "c"
    END
  UNTIL choice = "c";
  Out.Ln
END GuessNumber.
