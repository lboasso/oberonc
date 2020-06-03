.POSIX:
.SUFFIXES:

JAVA_SOURCES = src/java/Files_FileDesc.java src/java/Files.java \
               src/java/OberonRuntime.java src/java/Os.java src/java/Out.java \
               src/java/In.java src/java/Math.java
MOD_SOURCES = src/Out.Mod src/Os.Mod src/Files.Mod src/Strings.Mod src/OJS.Mod \
              src/CpCache.Mod src/Opcodes.Mod src/ClassFormat.Mod src/OJB.Mod \
              src/OJG.Mod src/OJP.Mod src/oberonc.Mod src/In.Mod src/Math.Mod

build:
	mkdir -p out/
	javac -d out $(JAVA_SOURCES)
	java -cp $(OBERON_BIN) oberonc out $(MOD_SOURCES)

bootstrap:
	javac -d bin $(JAVA_SOURCES)
	java -cp $(OBERON_BIN) oberonc bin $(MOD_SOURCES)

bootstrapTest:
	rm -rf bootstrapOut/
	mkdir -p bootstrapOut/
	java -cp $(OBERON_BIN) oberonc bootstrapOut $(MOD_SOURCES)
	sha1sum -b bootstrapOut/* > sha1sums0.txt
	sed s/bootstrapOut/bin/ sha1sums0.txt > sha1sums1.txt
	sha1sum -c --quiet sha1sums1.txt
	rm sha1sums0.txt sha1sums1.txt

runFern:
	rm -rf examples/fern/out/
	mkdir -p examples/fern/out/
	javac -cp $(OBERON_BIN) -d examples/fern/out examples/fern/java/*.java
	java -cp $(OBERON_BIN) oberonc examples/fern/out \
	  examples/fern/RandomNumbers.Mod \
	  examples/fern/XYplane.Mod examples/fern/IFS.Mod
	java -cp $(OBERON_BIN):examples/fern/out IFS

test:
	rm -rf tests/out/
	mkdir -p tests/out/
	javac -cp $(OBERON_BIN) -d tests/out tests/TestRunner.java
	java -Dfile.encoding=UTF-8 -cp $(OBERON_BIN):tests/out TestRunner


clean:
	rm -rf out/ tests/out/ bootstrapOut/ examples/fern/out/
