import java.io.IOException;

public final class OberonRuntime {

  // Ensure non-instantiability
  private OberonRuntime() {}

  /*
    Euclidean division (from "Division and Modulus for Computer Scientists")

    For any real numbers x and y with y # 0, there exists a unique
    pair of numbers q and r that satisfy the following conditions:
    - q is a signed integer
    - x = q*y + r
    - 0 <= r < |y|

    Euclidean division satisfies the following:
    1. x DIV (-y) = - (x DIV y)
    2. x MOD (-y) = x MOD y
    3. x DIV 2^n = x ASR n  (arithmetic/signed shift right)
    4. x * 2^n = x LSL n (logical shift left)
    5. x MOD 2^n = x and (2^n - 1)

   */
  public static int DIV(int x, int y) {
    int q = x / y;
    int r = x % y;
    if (r < 0) {
      if (y > 0) {
        q = q - 1;
      } else {
        q = q + 1;
      }
    }
    return q;
  }

  public static int MOD(int x, int y) {
    int r = x % y;
    if (r < 0) {
      if (y > 0) {
        r = r + y;
      } else {
        r = r - y;
      }
    }
    return r;
  }

  /*
    From the Java Language Specification:
    only the five lowest-order bits
    of the right-hand operand are used as the shift distance. It is as if the
    right-hand  operand were subjected to a bitwise logical AND operator &
    (§15.22.1) with the mask value 0x1f ( 0b11111 ). The shift distance
    actually used is therefore always in the range 0 to 31, inclusive.
  */
  public static int ASR(int x, int n) {
    /*
      From the Java Language Specification:
      The value of n >> s is n right-shifted s bit positions with
      sign-extension. The resulting value is floor(n / 2^s). For non-negative
      values of n, this is equivalent to truncating integer division, as
      computed by the integer division operator / , by two to the power s.
    */
    return x >> n;
  }


  public static int ROR(int x, int n) {
    // This is equivalent

    //return (x >>> n) | (x << (31-n));
    //return (x >>> n) | (x << (-n & 31));
    /*
       Like Integer.rotateRight()
       Returns the value obtained by rotating the two's complement binary
       representation of the specified int value right by the specified number
       of bits. (Bits shifted out of the right hand, or low-order, side reenter
       on the left, or high-order.)
       Note that right rotation with a negative distance is equivalent to left
       rotation: rotateRight(val, -distance) == rotateLeft(val, distance).
       Note also that rotation by any multiple of 32 is a no-op, so all but the
       last five bits of the rotation distance can be ignored, even if the
       distance is negative:
       rotateRight(val, distance) == rotateRight(val, distance & 0x1F).
    */
    return (x >>> n) | (x << -n);
  }

  public static int StrCmp(char[] s0, char[] s1) {
    int i = 0;
    int j = 0;
    int cmp = -1;
    if(i < s0.length && j < s1.length) {
      // this is safe, it will never overflow as cmp is an int (32 bits) and a
      // s0, s1 are of type char(16 bits)
      cmp = s0[i] - s1[j];
      while(i < s0.length && j < s1.length &&
        s0[i] != '\0' && s1[j] != '\0' &&
        cmp == 0) {
        cmp = s0[i] - s1[j];
        i++;
        j++;
      }
      if(cmp == 0) {
        if(i < s0.length && j < s1.length) {
          cmp = s0[i] - s1[j];
        } else {
          cmp = -1;
        }
      }
    }
    return cmp;
  }

  public static void ARGS(String[] args, int i, char[] out) {
    int end;
    if(out.length > 0) {
      end = 0;
      if(i < args.length) {
        end = args[i].length();
        if(end >= out.length) {
          end = out.length - 1;
        }
        System.arraycopy(args[i].toCharArray(), 0, out, 0, end);
      }
      out[end] = '\0';
    }
  }

  public static int ReadInt() {
    int c;
    int num = 0;
    boolean neg = false;
    try {
      c = System.in.read();
      if(c == '-') {
        neg = true;
        c = System.in.read();
      }
      while(c != -1 && c != ' ' && c != '\n') {
        num = (num*10) + c - '0';
        c = System.in.read();
      }
    } catch(IOException e) { num = 0;}
    if(neg) {
      num = -num;
    }
    return num;
  }

  public static void WriteInt(int num) {
    if(num <= 999 && num >= -99) {
      System.out.printf("%4d", num);
    } else {
      System.out.printf(" %d", num);
    }
  }

  public static void WriteReal(float num) {
    System.out.printf(" %f", num);
  }

  public static void WriteChar(int c) {
    System.out.print((char)c);
  }

  public static void WriteLn() {
    System.out.print('\n');
  }

  public static boolean eot() {
    int available = 0;
    try {
      available = System.in.available();
    } catch(IOException e) { }
    return available == 0;
  }
}
