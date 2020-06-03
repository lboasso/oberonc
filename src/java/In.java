/*
  Copyright 2019 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*/

import java.util.Scanner;

public final class In {

  static public boolean Done;
  static private Scanner scanner;

  // Ensure non-instantiability
  private In() {}

  static {
    Done = true;
    scanner = new Scanner(System.in, "UTF-8");
  }

  private static void nextLine() {
    try {
      scanner.nextLine();
    } catch(Exception e) {
      // ignore
    }
  }

  static public void Char(char[] ch) {
    char[] str = new char[2];
    String(str);
    if (Done) {
      ch[0] = str[0];
    }
  }

  static public void String(char[] str) {
    int i, ldest, lsrc;
    char[] line;

    Done = true;
    try {
      line = scanner.nextLine().toCharArray();
      ldest = str.length - 1;
      lsrc = line.length;
      if(ldest > 0 && lsrc > 0) {
        i = 0;
        while(i < ldest && i < lsrc && line[i] != '\0') {
          str[i] = line[i];
          i++;
        }
        str[i] = '\0';
      }
    } catch(Exception e) {
      Done = false;
    }
  }

  static public void Real(float[] x) {
    Done = true;
    try {
      x[0] = scanner.nextFloat();
    } catch(Exception e) {
      Done = false;
    }
    nextLine();
  }

  static public void Int(int[] i) {
    Done = true;
    try {
      i[0] = scanner.nextInt();
    } catch(Exception e) {
      Done = false;
    }
    nextLine();
  }
}
