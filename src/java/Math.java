/*
  Copyright 2020 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*/

public final class Math {
  public static final float pi = 3.14159265358979323846f;
  public static final float e = 2.71828182845904523536f;

  // Ensure non-instantiability
  private Math() {}

  public static float sqrt(float x) {
    return (float) java.lang.Math.sqrt(x);
  }

  public static float power(float x, float base) {
    return (float) java.lang.Math.pow(base, x);
  }

  public static float exp(float x) {
    return (float) java.lang.Math.exp(x);
  }

  public static float ln(float x) {
    return (float) java.lang.Math.log(x);
  }

  public static float log(float x, float b) {
    return (float) (java.lang.Math.log(x) / java.lang.Math.log(b));
  }

  public static float round(float x) {
    return (float) java.lang.Math.round(x);
  }

  public static float sin(float x) {
    return (float) java.lang.Math.sin(x);
  }

  public static float cos(float x) {
    return (float) java.lang.Math.cos(x);
  }

  public static float tan(float x) {
    return (float) java.lang.Math.tan(x);
  }

  public static float arcsin(float x) {
    return (float) java.lang.Math.asin(x);
  }

  public static float arccos(float x) {
    return (float) java.lang.Math.acos(x);
  }

  public static float arctan(float x) {
    return (float) java.lang.Math.atan(x);
  }

  public static float arctan2(float x, float y) {
    return (float) java.lang.Math.atan2(x, y);
  }

  public static float sinh(float x) {
    return (float) java.lang.Math.sinh(x);
  }

  public static float cosh(float x) {
    return (float) java.lang.Math.cosh(x);
  }

  public static float tanh(float x) {
    return (float) java.lang.Math.tanh(x);
  }

  public static float arcsinh(float x) {
    return (float) java.lang.Math.log(x +
                                     (float) java.lang.Math.sqrt(x * x + 1.0f));
  }

  public static float arccosh(float x) {
    return (float) java.lang.Math.log(x +
                                     (float) java.lang.Math.sqrt(x * x - 1.0f));
  }

  public static float arctanh(float x) {
    return (float) (0.5 * java.lang.Math.log((1.0f + x) / (1.0f - x)));
  }

}