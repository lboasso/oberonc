@echo off

set JAVA_SOURCES=src/java/Files_FileDesc.java src/java/Files.java src/java/OberonRuntime.java src/java/Os.java src/java/Out.java src/java/In.java src/java/Math.java
set MOD_SOURCES=src/Out.Mod src/Os.Mod src/Files.Mod src/Strings.Mod src/OJS.Mod src/CpCache.Mod src/Opcodes.Mod src/ClassFormat.Mod src/OJB.Mod src/OJG.Mod src/OJP.Mod src/oberonc.Mod src/In.Mod src/Math.Mod


if "%~1"=="" goto build
if "%~1"=="build" goto build
if "%~1"=="bootstrap" goto bootstrap
if "%~1"=="runFern" goto runFern
if "%~1"=="test" goto test
if "%~1"=="clean" goto clean

echo "%~1": invalid target
goto end

:build
mkdir "out/"
javac -d out %JAVA_SOURCES%
java -cp %OBERON_BIN% oberonc out %MOD_SOURCES%
echo build done
goto end

:bootstrap
javac -d bin %JAVA_SOURCES%
java -cp %OBERON_BIN% oberonc bin %MOD_SOURCES%
echo bootstrap done
goto end

:runFern
mkdir "examples/fern/out/"
javac -cp %OBERON_BIN% -d examples/fern/out examples/fern/java/*.java
java -cp %OBERON_BIN% oberonc examples/fern/out examples/fern/RandomNumbers.Mod examples/fern/XYplane.Mod examples/fern/IFS.Mod
java -cp %OBERON_BIN%;examples/fern/out IFS
goto end

:test
mkdir "tests/out/"
javac -cp %OBERON_BIN% -d tests/out tests/TestRunner.java
java -Dfile.encoding=UTF-8 -cp %OBERON_BIN%;tests/out TestRunner
goto end

:clean
rmdir out /s /q
rmdir tests\out /s /q
rmdir examples\fern\out /s /q

:end

