MODULE FragileBaseClass;
  TYPE
    List = POINTER TO ListDesc;
    Node = POINTER TO NodeDesc;
    List2 = POINTER TO List2Desc;
    ListDesc = RECORD
                 head: Node;
                 add: PROCEDURE(l: List; i: INTEGER);
                 addAll: PROCEDURE(l: List; i: ARRAY OF INTEGER);
                 size: PROCEDURE(s: List): INTEGER;
               END;
    List2Desc  = RECORD(ListDesc)
                  count: INTEGER;
               END;
    NodeDesc  = RECORD
                  x: INTEGER;
                  next: Node;
               END;
  VAR
    l: List;
    arr: ARRAY 2 OF INTEGER;

  PROCEDURE addList(l: List; i: INTEGER);
    VAR n: Node;
  BEGIN
    NEW(n);
    n.x := i;
    n.next := l.head;
    l.head := n;
  END addList;

  PROCEDURE addList2(l: List; i: INTEGER);
  BEGIN
    addList(l, i);
    INC(l(List2).count)
  END addList2;


  (*
    First version, the base class implements addAll without using the add
    method. This works fine.
  *)
  PROCEDURE addAllListA(l: List; i: ARRAY OF INTEGER);
    VAR j: INTEGER;
        n: Node;
  BEGIN
    FOR j := 0 TO LEN(i)-1 DO
      NEW(n);
      n.x := i[j];
      n.next := l.head;
      l.head := n
    END
  END addAllListA;

  (*
    Second version, the base class implements addAll by calling "add" in a loop.
    This works fine and does not break the subclass because "add" is called as
    a static invocation to addList. This is not possible in Java that resolves
    "add" dynamically.
  *)
  PROCEDURE addAllListB(l: List; i: ARRAY OF INTEGER);
    VAR j: INTEGER;
  BEGIN
    FOR j := 0 TO LEN(i)-1 DO
      addList(l, i[j])
    END
  END addAllListB;

  (*
    Third version, the base class implements addAll by calling "add" in a loop.
    This manifest the fragile base class problem. This is similar to Java normal
    dynamic dispatch of the method call "add": l.add(l, i[j]) will invoke
    addList2 that will invoke addList and so increment the count twice per
    element of the array i.
  *)
  PROCEDURE addAllListC(l: List; i: ARRAY OF INTEGER);
    VAR j: INTEGER;
  BEGIN
    FOR j := 0 TO LEN(i)-1 DO
      l.add(l, i[j])
    END
  END addAllListC;

  PROCEDURE addAllList2A(l: List; i: ARRAY OF INTEGER);
    VAR len: INTEGER;
  BEGIN
    addAllListA(l, i);
    len := LEN(i);
    INC(l(List2).count, len)
  END addAllList2A;

  PROCEDURE addAllList2B(l: List; i: ARRAY OF INTEGER);
    VAR len: INTEGER;
  BEGIN
    addAllListB(l, i);
    len := LEN(i);
    INC(l(List2).count, len)
  END addAllList2B;

  PROCEDURE addAllList2C(l: List; i: ARRAY OF INTEGER);
    VAR len: INTEGER;
  BEGIN
    addAllListC(l, i);
    len := LEN(i);
    INC(l(List2).count, len)
  END addAllList2C;

  PROCEDURE sizeList(l: List) :INTEGER;
    VAR
      size: INTEGER;
      tmp: Node;
  BEGIN
    size := 0;
    tmp := l.head;
    WHILE(tmp # NIL) DO INC(size); tmp := tmp.next END;
    RETURN size
  END sizeList;

  PROCEDURE sizeList2(l: List) :INTEGER;
  RETURN l(List2).count
  END sizeList2;

  PROCEDURE newList2(addAll: PROCEDURE(l: List; i: ARRAY OF INTEGER)): List2;
    VAR l: List2;
  BEGIN
    NEW(l);
    l.head := NIL;
    l.add := addList2;
    l.addAll := addAll;
    l.size := sizeList2;
    RETURN l
  END newList2;
BEGIN
  arr[0] := 8; arr[1] := 9;
  l := newList2(addAllList2A);
  l.addAll(l, arr);
  WriteInt(l.size(l));

  l := newList2(addAllList2B);
  l.addAll(l, arr);
  WriteInt(l.size(l));

  l := newList2(addAllList2C);
  l.addAll(l, arr);
  WriteInt(l.size(l))
END FragileBaseClass.