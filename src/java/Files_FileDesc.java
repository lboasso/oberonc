/*
  Copyright 2017 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*/

import java.io.RandomAccessFile;

public class Files_FileDesc {
  public RandomAccessFile f;
  public int err;
  public Files_FileDesc() {}

  public Files_FileDesc copy() {
    Files_FileDesc x = new Files_FileDesc();
    x.f = this.f;
    x.err = this.err;
    return x;
  }
}