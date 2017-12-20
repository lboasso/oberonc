# Type rules

## Same types [A]
Two variables *a* and *b* with types *Ta* and *Tb* are of the *same* type if
1. *Ta* and *Tb* are both denoted by the same type identifier, or
2. *Ta* is declared in a type declaration of the form *Ta* = *Tb*, or
3. *a* and *b* appear in the same identifier list in a variable, record field,
   or formal parameter declaration.

## Equal types [B]
Two types *Ta* and *Tb* are *equal* if
1. *Ta* and *Tb* are the *same* type, or
2. *Ta* and *Tb* are open array types with *equal* element types, or
3. *Ta* and *Tb* are array types with *equal* element types and length, or
4. *Ta* and *Tb* are procedure types whose formal parameter lists *match*, or
5. *Ta* and *Tb* are pointer types with *equal* base types.

## Matching formal parameter lists [C]
Two formal parameter lists *match* if
1. they have the same number of parameters, and
2. they have either *equal* function result types or none, and
3. parameters at corresponding positions have *equal* types, and
4. parameters at corresponding positions are both either value or VAR
   parameters.

## Type extension (base type) [D]
Given a type declaration *Tb* = RECORD (*Ta*) ... END, *Tb* is a
*direct extension* of *Ta*, and *Ta* is a *direct base type* of *Tb*. A type
*Tb* is an *extension* of a type *Ta* (*Ta* is a *base type* of *Tb*) if
1. *Ta* and *Tb* are the *same* types, or
2. *Tb* is a *direct extension* of an *extension* of *Ta*.

If *Pa* = POINTER TO *Ta* and *Pb* = POINTER TO *Tb*, *Pb* is an *extension* of
*Pa* (*Pa* is a *base type* of *Pb*) if *Tb* is an *extension* of *Ta*.

## Assignment compatible [E]
An expression *e* of type *Te* is *assignment compatible* with a variable *v*
of type *Tv* if one of the following conditions hold:
1. *Te* and *Tv* are *equal* and are not open array types;
2. *Te* and *Tv* are record types and *Te* is an *extension* of *Tv* and the
   dynamic type of *v* is *Tv*;
3. *Te* and *Tv* are pointer types and *Te* is an *extension* of *Tv*;
4. *Tv* is a pointer or a procedure type and *e* is NIL;
5. *Tv* is array of CHAR, *e* is a string constant with *n* characters,
    and *n* < *LEN(v)*;
6. *Tv* is ARRAY *n* OF *Ta*, *e* is ARRAY OF *Tb* where *Ta* and *Tb* are
   *equal* and *LEN(e) <= LEN(v)*;
7. *Tv* is a procedure type and *e* is the name of a procedure whose formal
   parameters *match* those of *Tv*.

## Parameters

Let *f* be the formal parameter and *a* the corresponding actual parameter. If
*f* is an open array, then *a* must be *array compatible* to *f* and the lengths
of *f* are taken from *a*. Otherwise *a* must be *parameter compatible* to *f*.

### Array compatible [F]
An actual parameter *a* of type *Ta* is *array compatible* with a formal
parameter *f* of type *Tf* if
1. *Tf* and *Ta* are *equal* types, or
2. *Tf* is an open array, *Ta* is any array, and their element types are *array
   compatible*, or
3. *f* is a value parameter of type ARRAY OF CHAR and *a* is a string.

### Parameter compatible [G]
An actual parameter *a* of type *Ta* is *parameter compatible* with a formal
parameter *f* of type *Tf* if:
1. *Tf* and *Ta* are *equal* types, or
2. *f* is a value parameter and *Ta* is *assignment compatible* (except E.5 and
   E.6) with *Tf*, or
3. *f* is an VAR parameter and *Tf* and *Ta* are record types and *Ta* is an
   *extension* of *Tf*, or
4. *f* is a parameter of type ARRAY *m* OF BYTE and *Ta* is any type with size
   *n* = *m* bytes.

## RETURN expression [H]
The type of the expression must be *assignment compatible* with the result type
specified in the procedure heading and can be neither a record nor an array.

## BYTE and INTEGER [I]
The type BYTE is compatible with the type INTEGER, and vice versa.

## String and CHAR [J]
A string of length 1 can be used wherever a character constant is allowed and
vice versa.
