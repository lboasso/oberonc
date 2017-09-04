/*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*/

public final class Os {

  private static String toString(char[] name) {
    int i;

    i = 0;
    while(i < name.length && name[i] != '\0') {
      i++;
    }
    return new String(name, 0, i);
  }

  public static void GetEnv(char[] out, char[] name) {
    int i;

    if(out.length > 0 && name.length > 0) {
      try {
        String s = System.getenv(toString(name));
        i = 0;
        if(s != null) {
          i = Math.min(s.length(), out.length-1);
          System.arraycopy(s.toCharArray(), 0, out, 0, i);
        }
        out[i] = '\0';
      } catch(Exception e) {
        out[0] = '\0';
      }
    }
  }
}
