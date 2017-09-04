.POSIX:
.SUFFIXES:

build:
	javac -d bin src/java/*.java
	java -cp $(OBERON_BIN) oberonc bin src/*.Mod

bootstrapTest:
	rm -rf bootstrapOut/
	mkdir -p bootstrapOut/
	java -cp $(OBERON_BIN) oberonc bootstrapOut src/*.Mod
	sha1sum -b bootstrapOut/* > sha1sums0.txt
	sed s/bootstrapOut/bin/ sha1sums0.txt > sha1sums1.txt
	sha1sum -c --quiet sha1sums1.txt
	rm sha1sums0.txt sha1sums1.txt

runFern:
	rm -rf examples/fern/out/
	mkdir -p examples/fern/out/
	javac -cp $(OBERON_BIN) -d examples/fern/out examples/fern/java/*.java
	java -cp $(OBERON_BIN) oberonc examples/fern/out \
	  examples/fern/MathUtil.Mod examples/fern/RandomNumbers.Mod \
	  examples/fern/XYplane.Mod examples/fern/IFS.Mod
	java -cp $(OBERON_BIN):examples/fern/out IFS

test:
	rm -rf tests/out/
	mkdir -p tests/out/
	javac -cp $(OBERON_BIN) -d tests/out tests/TestRunner.java
	java -cp $(OBERON_BIN):tests/out TestRunner


clean:
	rm -rf tests/out/ bootstrapOut/ examples/fern/out/
