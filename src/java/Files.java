/*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*/

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.file.Paths;

import static java.nio.file.StandardCopyOption.REPLACE_EXISTING;

public final class Files {
  public static final int OK = 0;
  public static final int EOF = -1;
  public static final int IOERROR = -2;
  public static final int UTF8ERROR = -3;
  public static final char[] SEPARATOR = java.io.File.separator.toCharArray();

  // Ensure non-instantiability
  private Files() {}

  public static int Status(Files_FileDesc file) {
    return file.err;
  }

  public static int Rename(char[] from, char[] to) {
    int r = OK;
    try {
      java.nio.file.Files.move(Paths.get(toStr(from)), Paths.get(toStr(to)),
                               REPLACE_EXISTING);
    } catch(IOException e) {
      r = IOERROR;
    }
    return r;
  }

  public static boolean Exists(char[] name) {
    boolean r;
    r = false;
    java.io.File f = new java.io.File(toStr(name));
    if(f.exists() && !f.isDirectory()) {
      r = true;
    }
    return r;
  }

  public static int Delete(char[] name) {
    int r;
    r = OK;
    java.io.File f = new java.io.File(toStr(name));
    try {
      if(!f.delete()) {
        r = IOERROR;
      }
    } catch(SecurityException e) {
      r = IOERROR;
    }
    return r;
  }

  public static Files_FileDesc Create(char[] name) {
    return open(name, "rw", true);
  }

  private static Files_FileDesc open(char[] name, String mode,
                                     boolean truncate) {
    Files_FileDesc file;
    file = new Files_FileDesc();
    try {
      file.f = new RandomAccessFile(toStr(name), mode);
      if(truncate) {
        file.f.setLength(0);
      }
      file.err = OK;
    } catch(FileNotFoundException e) {
      file = null;
    } catch(IOException e) {
      file.err = IOERROR;
    }
    return file;
  }

  public static Files_FileDesc Open(char[] name) {
    return open(name, "r", false);
  }

  public static void Close(Files_FileDesc file) {
    try {
      file.f.close();
    } catch(IOException e) {
      file.err = IOERROR;
    }
  }

  private static String toStr(char[] name) {
    int i, len;
    len = name.length;
    i = 0;
    if(len > 0) {
      while(i < len && name[i] != '\0') {
        i++;
      }
    }
    return new String(name, 0, i);
  }

  public static void WriteAsciiStr(Files_FileDesc file, char[] str) {
    int i;
    if(str.length > 0 && file.err == OK) {
      i = 0;
      while(i < str.length && str[i] != '\0' && file.err == OK) {
        Write(file, (byte) (str[i] & 0xFF));
        i++;
      }
      Write(file, (byte) 0);
    }
  }

  public static void WriteStr(Files_FileDesc file, char[] str) {
    int i;
    if(str.length > 0 && file.err == OK) {
      i = 0;
      while(i < str.length && str[i] != '\0' && file.err == OK) {
        WriteChar(file, str[i]);
        i++;
      }
      Write(file, (byte) 0);
    }
  }

  public static void Write(Files_FileDesc file, byte b) {
    if(file.err == OK) {
      try {
        file.f.write(b);
      } catch(IOException e) {
        file.err = IOERROR;
      }
    }
  }

  public static void WriteChar(Files_FileDesc file, char c) {
    // 0x0000 <= c <= 0xFFFF
    if(file.err == OK) {
      if (c >= 0x0000 && c <= 0x007F) { // 1 bytes format: 0xxxxxxx
        Write(file, (byte) c);
      } else if(c >= 0x0800) { // 3 bytes format: 1110xxxx 10xxxxxx 10xxxxxx
        Write(file, (byte) (0xE0 | ((c >> 12) & 0x0F)));
        Write(file, (byte) (0x80 | ((c >>  6) & 0x3F)));
        Write(file, (byte) (0x80 | (c & 0x3F)));
      } else { // 2 bytes format: 110xxxxx 10xxxxxx
        Write(file, (byte) (0xC0 | ((c >>  6) & 0x1F)));
        Write(file, (byte) (0x80 | (c & 0x3F)));
      }
    }
  }

  public static void WriteBytes(Files_FileDesc file, byte[] b) {
    if(file.err == OK) {
      try {
        file.f.write(b);
      } catch(IOException e) {
        file.err = IOERROR;
      }
    }
  }

  public static void WriteNBytes(Files_FileDesc file, byte[] b, int len) {
    if(file.err == OK) {
      try {
        file.f.write(b, 0, len);
      } catch(IOException e) {
        file.err = IOERROR;
      }
    }
  }

  /* Little endian */
  public static void WriteInt(Files_FileDesc file, int x) {
    if(file.err == OK) {
      Write(file, (byte) (x & 0xFF));
      Write(file, (byte) ((x >> 8) & 0xFF));
      Write(file, (byte) ((x >> 16) & 0xFF));
      Write(file, (byte) ((x >> 24) & 0xFF));
    }
  }

  /*
  LEB128

  LEB128 ("Little-Endian Base 128") is a variable-length encoding for arbitrary
  signed or unsigned integer quantities.
  Each LEB128 encoded value consists of one to five bytes, which together
  represent a single 32-bit value.
  Each byte has its most significant bit set except for the final byte in the
  sequence, which has its most significant bit clear. The remaining seven bits
  of each byte are payload, with the least significant seven bits of the
  quantity in the first byte, the next seven in the second byte and so on.
  In the case of a signed LEB128, the most significant PAYLOAD bit of
  the final byte in the sequence is sign-extended to produce the final value.

   With 7 bits I can store numbers in this range:
    -2^6 <= x <= 2^6-1
    -64 <= x <= 63
    -64 <= x < 64
    -0x40 <= x < 0x40

    example:
    -908 = 11111111111111111111110001110100 in two's complement

    1111 1111111 1111111 1111000 1110100 ->  group of 7 bits

    write 8 bits -> 1 1110100
                    ^----------- always one so these bits represent an
                                 unsigned byte >= 128

    shift -908 7 bits to the right ->  1111 1111111 1111111 1111000 = -8
    -64 <= -8 < 64 , write it in 8 bits -> 01111000
  */
  public static void WriteNum(Files_FileDesc file, int x) {
    if(file.err == OK) {
      while((x < -0x40 || x >= 0x40) && file.err == OK) {
        Write(file, (byte) ((x & 0x7F) + 0x80));
        x = x >> 7;
      }
      Write(file, (byte) (x & 0x7F));
    }
  }

  /*
      example: read -999999999 = 11000100011001010011011000000001
                               = 1100 0100011 0010100 1101100 0000001
              back from 10000001 11101100 10010100 10100011 01111100

       1 0000001
       ^----------- one so these bits represent an unsigned byte
                    >= 128

       remove the first one -> 1 0000001 - 0x80 =
                               00000001 =
                               0000 0000000 0000000 0000000 0000001
       The number 0000001 represents the first least significant 7 bits group
       of the original number.
       The next byte read 11101100, encode the next 7 bits group (after
       removing the first one, like before), so we shift it by 7 and add it to
       the previous number:

       1 1101100 >= 128
       remove the first one -> 1 1101100 - 0x80 =
                               0 1101100 =
                               0000 0000000 0000000 0000000 1101100
       shift to the left by 7 on a 32 bit range  ->
                               00000000000000000011011000000000

       and add it to the previous number:
                               00000000000000000011011000000000 +
                               00000000000000000000000000000001
                        =      00000000000000000011011000000001
                        =  0000 0000000 0000000 1101100 0000001

       We keep doing the above for the next bytes with the MSB set to 1
       resulting in the sum  0000 0100011 0010100 1101100 0000001.


       the last byte 01111100 = 124 < 128

       0 1 111100
         ^---------- sign of the original number
       ^----------- tag, always 0 for the last byte read.

      We separate the sign bit of the original number form the rest.

      Sign
         0 1 111100 AND 0x40
       = 0 1 111100 AND
         0 1 000000
       = 0 1 000000

       The rest
          0 1 111100 AND 0x3F
       =  0 1 111100 AND
          0 0 111111
       =  0 0 111100

      We now can sign extend this last most significant 7 bits of the original
      number by subtracting  0 0 111100 with 0 1 000000:

                               0000 0000000 0000000 0000000 0 0 111100 -
                               0000 0000000 0000000 0000000 0 1 000000
                           =   1111 1111111 1111111 1111111 1 1 111100

      Now we can do a final shift and sum it with
      0000 0100011 0010100 1101100 0000001, to obtain the result


                              1111 1111111 1111111 1111111 1 1 111100 << 28
                           =  1100 0000000 0000000 0000000 0000000

                              0000 0100011 0010100 1101100 0000001 +
                              1100 0000000 0000000 0000000 0000000
                           =  1100 0100011 0010100 1101100 0000001
                           =  -999999999

  */
  public static int ReadNum(Files_FileDesc file) {
    int n, y, b, x;
    x = 0;
    if(file.err == OK) {
      n = 0;
      y = 0;
      b = read(file);
      while(b >= 0x80) {
        y += ((b - 0x80) << n);
        n += 7;
        b = read(file);
      }
      b = (b & 0x3F) - (b & 0x40);
      x = y + (b << n);
    }
    return x;
  }

  public static byte Read(Files_FileDesc file) {
    byte b = 0;
    if(file.err == OK) {
      b = (byte) read(file);
    }
    return b;
  }

  public static char ReadChar(Files_FileDesc file) {
    int b1, b2, b3;
    char ch = '\0';
    b1 = read(file);
    if (file.err == OK) {
      switch(b1 >> 4) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:   // 1 bytes format: 0xxxxxxx
          ch = (char) b1;
          break;

        case 12:
        case 13:  // 2 bytes format: 110xxxxx 10xxxxxx
          b2 = read(file);
          if(file.err == OK && (b2 & 0xC0) != 0x80) {
            file.err = UTF8ERROR;
          }
          ch = (char) (((b1 & 0x1F) << 6) | (b2 & 0x3F));
          break;

        case 14:  // 3 bytes format: 1110xxxx 10xxxxxx 10xxxxxx
          b2 = read(file);
          b3 = read(file);
          if(file.err == OK && ((b2 & 0xC0) != 0x80 || (b3 & 0xC0) != 0x80)) {
            file.err = UTF8ERROR;
          }
          ch = (char) (((b1 & 0x0F) << 12) |
            ((b2 & 0x3F) << 6) |
            (b3 & 0x3F));
          break;

        default:  // ERROR + 4 bytes format: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
          file.err = UTF8ERROR;
          ch = '\0';
      }
    }
    return ch;
  }

  private static int read(Files_FileDesc file) {
    int x;
    x = 0;
    if(file.err == OK) {
      try {
        x = file.f.read();
        if(x < 0) {
          file.err = EOF;
        }
      } catch(IOException e) {
        file.err = IOERROR;
      }
    }
    return x;
  }

  public static void ReadBytes(Files_FileDesc file, byte[] b, int[] n) {
    if(file.err == OK) {
      try {
        n[0] = file.f.read(b);
        if(n[0] < 0) {
          file.err = EOF;
        }
      } catch(IOException e) {
        file.err = IOERROR;
      }
    }
  }

  /* Little endian */
  public static int ReadInt(Files_FileDesc file) {
    int x0, x1, x2, x3, x;
    x0 = read(file); x1 = read(file); x2 = read(file); x3 = read(file);
    x = (((((x3 << 8) + x2) << 8) + x1) << 8) + x0;
    return x;
  }

  public static void ReadAsciiStr(Files_FileDesc file, char[] str) {
    int i, ch, last;
    if(str.length > 0 && file.err == OK) {
      i = 0;
      last = str.length - 1;
      ch = read(file);
      while(i < last && ch != '\0' && file.err == OK) {
        str[i] = (char) ch;
        ch = read(file);
        i++;
      }
      str[i] = '\0';
    }
  }

  public static int ReadStr(Files_FileDesc file, char[] str) {
    int i, last;
    char ch;
    i = 0;
    if(str.length > 0 && file.err == OK) {
      last = str.length - 1;
      ch = ReadChar(file);
      while(i < last && ch != '\0' && file.err == OK) {
        str[i] = ch;
        ch = ReadChar(file);
        i++;
      }
      str[i] = '\0';
    }
    return i;
  }

  public static int Seek(Files_FileDesc file, int pos) {
    int r;
    r = OK;
    try {
      file.f.seek(pos);
      if(file.err == EOF) {
        file.err = OK;
      }
    } catch(IOException e) {
      r = IOERROR;
    }
    return r;
  }

  public static int Size(Files_FileDesc file) {
    int len;
    len = -1;
    if(file.err == OK) {
      try {
        len = (int) file.f.length();
      } catch(IOException e) {
        file.err = IOERROR;
      }
    }
    return len;
  }
}
