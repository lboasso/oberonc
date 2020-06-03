(*
  Copyright 2020 Luca Boasso. All rights reserved.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

(* Math provides a basic set of general purpose mathematical functions using
   REAL arithmetic. It implements the interface described in "The Oakwood
   Guidelines for Oberon-2 Compiler Developers". *)
DEFINITION Math;
  CONST
    pi = 3.14159265358979323846;
    e = 2.71828182845904523536;

  (* sqrt returns the square root of x, where x must be positive *)
  PROCEDURE sqrt(x: REAL): REAL;

  (* power returns base raised to the power of x. *)
  PROCEDURE power(x, base: REAL): REAL;

  (* exp returns Math.e raised to the power of x: power(x, e)*)
  PROCEDURE exp(x: REAL): REAL;

  (* ln returns the natural logarithm (base e) of x. *)
  PROCEDURE ln(x: REAL): REAL;

  (* log returns the logarithm of x base b. All positive arguments are allowed.
     The base b must be positive.*)
  PROCEDURE log(x, b: REAL): REAL;

  (* If the fraction part of x is in range 0.0 to 0.5 (excluded) then the result
     of round is the largest integer not greater than x, otherwise the result
     is x rounded up to the next highest whole number.
     Note that integer values cannot always be exactly represented in REAL
     format. *)
  PROCEDURE round(x: REAL): REAL;

  (* sin returns the sine value of x, where x is in radians. *)
  PROCEDURE sin(x: REAL): REAL;

  (* cos returns the cosine value of x, where x is in radians. *)
  PROCEDURE cos(x: REAL): REAL;

  (* tan returns the tangent value of x, where x is in radians. *)
  PROCEDURE tan(x: REAL): REAL;

  (* arcsin returns the arcsine value in radians of x, where x is
     in the sine value. *)
  PROCEDURE arcsin(x: REAL): REAL;

  (* arcos returns the arcos value in radians of x, where x is
    in the cosine value. *)
  PROCEDURE arccos(x: REAL): REAL;

  (* arctan returns the arctan value in radians of x, where x is
    in the tangent value. *)
  PROCEDURE arctan(x: REAL): REAL;

  (* arctan2 returns the quadrant-correct arc tangent atan(x/y).
     If the denominator y is zero, then the numerator x must not be zero.
     All arguments are legal except x = y = 0. *)
  PROCEDURE arctan2(x, y: REAL): REAL;

  (* sinh returns the hyperbolic sine of x. *)
  PROCEDURE sinh(x: REAL): REAL;

  (* cosh returns the hyperbolic cosine of x. *)
  PROCEDURE cosh(x: REAL): REAL;

  (* tanh returns the hyperbolic tangent of x. *)
  PROCEDURE tanh(x: REAL): REAL;

  (* arcsinh returns the arc hyperbolic sine of x. *)
  PROCEDURE arcsinh(x: REAL): REAL;

  (* arccosh returns the arc hyperbolic cosine of x. All arguments greater than
     or equal to 1 are legal. *)
  PROCEDURE arccosh(x: REAL): REAL;

  (* arctanh returns the arc hyperbolic tangent of x. *)
  PROCEDURE arctanh(x: REAL): REAL;
END Math.
