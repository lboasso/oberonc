/*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*/

import java.io.IOException;
import java.util.Locale;

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

  public static int ASR(int x, int n) {
    return x >> n;
  }


  public static int ROR(int x, int n) {
    // see Integer.rotateRight()
    return (x >>> n) | (x << -n);
  }

  public static int StrCmp(char[] s0, char[] s1) {
    int cmp;
    int i = 0;
    int len = java.lang.Math.min(s0.length, s1.length);
    while(i < len && s0[i] == s1[i] && s0[i] != '\0') {
      i++;
    }
    if(i < len) {
      // this is safe, it will never overflow as cmp is an int (32 bits) and
      // s0, s1 are of type char (16 bits)
      cmp = s0[i] - s1[i];
    } else {
      cmp = s0.length - s1.length;
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
      System.out.printf(Locale.US, "%4d", num);
    } else {
      System.out.printf(Locale.US, " %d", num);
    }
  }

  public static void WriteReal(float num) {
    System.out.printf(Locale.US, " %f", num);
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
