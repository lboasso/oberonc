MODULE CaseRecord4;
  TYPE
    A = POINTER TO ADesc;
    ADesc = RECORD
      next: A
    END;

    B = POINTER TO RECORD(ADesc)
        value: INTEGER
    END;

  VAR x: B;
      fn: PROCEDURE(z: A);

  PROCEDURE CaseGuardOnParam(a: A);
  BEGIN
    IF a # NIL THEN
      CASE a OF
        B:
          WriteChar("B"); WriteLn;
          (* BUG-FIX: here 'a' has type B thanks to the implicit type guard:
           so 'a.next' is equivalent to 'a(B).next'. The 'next' field has type
           A and the formal parameter 'a' must be treated as of type A while
           we type check the function call to CaseGuardOnParam *)
          CaseGuardOnParam(a.next);
          (* BUG-FIX: In the signature of CaseGuardOnParam, 'a' must have type
            A, regardless of implicit type guards. Only when 'a' appears in
            expressions we can assume it has type 'B' *)
          fn := CaseGuardOnParam
      END
    END
  END CaseGuardOnParam;

BEGIN
  NEW(x); x.next := NIL;
  CaseGuardOnParam(x)
END CaseRecord4.
