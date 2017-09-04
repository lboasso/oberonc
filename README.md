
# Oberon-07 compiler

`oberonc` is a single pass, self-hosting compiler for the
[Oberon-07](https://en.wikipedia.org/wiki/Oberon_(programming_language))
programming language. It targets the Java Virtual Machine (version >=1.5).

This project was started to showcase the art of Niklaus Wirth in writing
compilers (see ["Compiler Construction - The Art of Niklaus
Wirth"](ftp://debian.ssw.uni-linz.ac.at/pub/Papers/Moe00b.pdf)
by Hanspeter Mössenböck for more details).

`oberonc` is inspired by Niklaus Wirth's compiler for a RISC processor available
[here](http://www.inf.ethz.ch/personal/wirth/).

The compiler is compact and does not depend on any third party libraries. It
produces Java bytecode in one pass while parsing the source file. Although
generating code for a stack machine is straightforward, this task is acerbated
by a complex class file format and the fact that the JVM was designed with the
Java language in mind. In fact the JVM lacks many of the primitives required to
support Oberon's features:

* value types
* pass by reference evaluation strategy
* procedure variables (pointer to functions) and relative structural
  compatibility of types

Implementing those features with workarounds increased significantly the size
of the compiler, totaling roughly 6000 lines of Oberon.

The source code is written following as much as possible Niklaus Wirth's
coding style. `oberonc` compile itslef in less than 300 ms on an old
Intel i5 @ 2.80GHz (~ 100 ms with a hot VM).

## How to build

To build the compiler I am assuming a Linux box with a JDK >= 1.5 installed.
It should be easy to convert the makefile commands to Windows equivalents.

First of all, you need to set the OBERON_BIN environmental variable to the `bin`
folder of the repository, for
example `export OBERON_BIN=~/projects/oberonc/bin`. This is necessary since to
compile the sources in `src` you need an Oberon compiler, so I added to the
repository the binaries of the compiler to perform the bootstrapping.

By typing `make build` on the shell, the compiler will compile itself and
overwrite the files in the `bin` folder.

## How to run the tests

One typical test is to make sure that, by compiling the compiler, we get the
same (bit by bit) class files originally included in the `bin` folder.
To run this test simply type `make bootstrapTest`. This will compile the
sources into the `bootstrapOut` folder and compare these resulting class files
with the ones in `bin`. If something goes wrong `sha1sums` will complain.

To run the tests included in the `tests` folder, type `make test`. The output
should look like this:

    ...
    TOTAL: 88
    SUCCESSFUL: 88
    FAILED: 0

## Using the compiler

To use the compiler you need to have the OBERON_BIN variable set to the `bin`
folder of the repository. The command line syntax of `oberonc` is simple.
Let's compile examples\Hello.Mod:

    MODULE Hello;
      IMPORT Out; (* Import Out to print on the console *)
    BEGIN
      Out.String("Hello world");
      Out.Ln (* print a new line *)
    END Hello.

Assuming you are at the root of the repository, the following command will
compile the Hello.Mod example and place the generated classes in the current
folder:

    java -cp $OBERON_BIN oberonc . examples/Hello.Mod

The first argument of oberonc is `.`, this is the existing folder where the
generated class will be written, the next arguments specify modules file to
be compiled.

This will generate Hello.class and Hello.smb. The second file is a symbol file,
it is used only during compilation and enables `oberonc` to perform separate
compilation of modules that import Hello. In this simple case Hello.Mod
does not export anything, but the other modules in the `examples` folder do.

To run Hello.class you need the OberonRuntime.class and Out.class. This are
already present in the `bin` folder so they are already in the class path, we
just need to include the current folder as well to locate Hello.class:

    java -cp $OBERON_BIN:. Hello

If you want to compile and run automatically a simple example called `fern`,
type `make runFern`. It should open a window like this one:

![Fern](examples/fern/fern.png)

## License

The compiler is distributed under the MIT license found in the LICENSE.txt file.
