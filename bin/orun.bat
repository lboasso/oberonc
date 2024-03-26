@ECHO OFF

SET OBERON_BIN="%~dp0"

"%JAVA_HOME%/bin/java" -cp "%OBERON_BIN%/ob.jar":. %*
