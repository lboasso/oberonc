import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.io.PrintStream;
import java.lang.reflect.Method;

public class TestRunner {
  private static final String suitePath = "tests/base/";
  private static final String outFolder = "tests/out/";

  public static void main(String[] args) {
    int[] tot = new int[1];
    int[] successful = new int[1];
    int[] failed = new int[1];
    String[] tests = {
      "VarInit", "DivMul", "ProcVariables0", "ProcVariables1", "ProcVariables2",
      "ProcVariables3", "ProcVariables4", "ProcVariables5", "ProcVariables6",
      "RecordAndTypeExtension", "ProcComparisons", "FragileBaseClass",
      "Strings0", "Strings1", "Strings2", "OpenArrays2", "OpenArrays3",
      "TestABS", "TestCPS", "TestODD", "TestOOP", "SetTest", "Out0",
      "UTF8String", "TestAnonymousName", "RecordAssignment", "TestShift",
      "TestByteType", "TestINC0", "TestINC1", "Arrays2", "Arrays3", "TestFor",
      "Out3", "EmptyArrayAndRecord", "ArrayAssignment", "OpenArrays",
      "TestAssignmentMix", "TestEqualSignature00", "BitFunc", "Out4",
      "ProcType", "ConstantFoldingAndLoadOp", "CommutativeSwap", "Out5",
      "TestFunction0", "RealExpressions", "Pattern2a", "Pattern2b", "Pattern2c",
      "Out2", "TestReturn0", "CaseNum0", "CaseNum1", "TestINCLAndEXCL",
      "CaseRecord0", "CaseRecord1", "CaseRecord2", "TestTypeConvFun",
      "TestFor1", "Out1", "TestAssert", "CaseChar0", "Out6", "TestSystemVal",
      "TestNestedProcs", "Pattern1", "TestStringsMod", "OutTest",
      "ProcVariables7", "RecordAssignment2", "RecordParam", "CaseRecord3",
      "VarParGuard", "TestTypeTest", "TestConstFunc", "TestMath"
    };
    successful[0] = 0;
    failed[0] = 0;
    tot[0] = 0;
    for(String test : tests) {
      check(tot, successful, failed, compileAndRun(test));
    }

    check(tot, successful, failed, compileAndRunArgs("TestCmdLineArgs", "",
                                             new String[] {"Hello", "World!"}));
    testImports(tot, successful, failed);
    testCyclicImports(tot, successful, failed);
    testWithInputs(tot, successful, failed);
    testTypeGuardExt(tot, successful, failed);
    check(tot, successful, failed,
          compileAndFail("TestReadOnlyPar", 3, "read only"));
    check(tot, successful, failed,
          compileAndFail("UniqueTypeAndProcNames", 3, "must be unique"));
    check(tot, successful, failed,
          compileAndFail("ArrayConstantSize", 2, "not a valid length"));
    check(tot, successful, failed,
          compileAndFail("TestExprVarPar", 2, "Only variables allowed"));
    System.err.println("TOTAL: "  + tot[0]);
    System.err.println("SUCCESSFUL: " + successful[0]);
    System.err.println("FAILED: " + failed[0]);
  }

  private static void check(int[] tot, int[] successful, int[] failed,
                            boolean res) {
    if(res) {
      successful[0]++;
    } else {
      failed[0]++;
    }
    tot[0]++;
  }

  private static void testImports(int[] tot, int[] successful, int[] failed) {
    boolean res, res0, res1;
    int i;
    // the compilation order matters
    String[][] suite = {
      {"TestImport00", "TestImport01"},
      {"TestImport10", "TestImport11"},
      {"TestImport20", "TestImport21", "TestImport22"},
      {"TestImport30", "TestImport31"},
      {"TestImport40", "TestImport41", "TestImport42"},
      {"TestImport50", "TestImport51", "TestImport52", "TestImport53"},
      {"TestImport60", "TestImport61", "TestImport62"},
      {"TestImport70", "TestImport71"},
      {"TestImport81", "TestImport82", "TestImport80"},
      {"TestImport90", "TestImport91"},
      {"TestImport100"},
      {"TestImport120", "TestImport121", "TestImport122"},
      {"TestImport130", "TestImport131"},
      {"TestImport140", "TestImport141", "TestImport142"},
      {"TestImport150", "TestImport151"},
    };

    for(String[] test : suite) {
      res = true;
      for(i = 0; i < test.length && res; i++) {
        res = compileAndRun(test[i]);
      }
      check(tot, successful, failed, res);
    }
    res0 = compileAndRun("TestImport110");
    res1 = compile("TestImport111", false) == 0;
    res = compileAndRun("TestImport112");
    check(tot, successful, failed, res0 && res1 && res);
  }

  private static void testCyclicImports(int[] tot, int[] successful,
                                        int[] failed) {

    check(tot, successful, failed, compile("TestCyclicImport00A", true) == 0 &&
                                   compile("TestCyclicImport01A", true) == 0 &&
                                   compileAndFail("TestCyclicImport00B", 2,
                                                  "recursive import"));

    check(tot, successful, failed, compile("TestCyclicImport00A", true) == 0 &&
                                   compile("TestCyclicImport01B", true) == 0 &&
                                   compileAndFail("TestCyclicImport00B", 2,
                                                  "recursive import"));

    check(tot, successful, failed, compile("TestCyclicImport10A", true) == 0 &&
                                   compile("TestCyclicImport12", true) == 0 &&
                                   compile("TestCyclicImport11", true) == 0 &&
                                   compileAndFail("TestCyclicImport10B", 2,
                                                  "recursive import"));
  }

  private static void testWithInputs(int[] tot, int[] successful,
                                     int[] failed) {
    int i;
    String[] tests = {
      "Samples0", "Samples1", "Samples2", "MagicSquares", "PrimeNumbers",
      "Fractions", "Permutations", "Powers"
    };
    String[] inputs = {
      "0 8 5\n", "1 80 5\n", "2 1 2 3 2\n", "3\n", "20\n", "20\n", "3 7 11\n\n",
      "32\n"
    };

    for(i = 0; i < tests.length; i++) {
      check(tot, successful, failed, compileAndRunWithInput(tests[i],
                                                            inputs[i]));
    }
  }

  private static void testTypeGuardExt(int[] tot, int[] successful,
                                         int[] failed) {
    check(tot, successful, failed, compile("ExtTypes", true) == 0 &&
                                   compileAndRun("TestTypeGuardExt"));
  }

  private static boolean assertEquals(String name, String expected, String actual) {
    boolean res = expected.equals(actual);
    if(!res) {
      System.err.println("Test '" + suitePath + name + ".Mod" + "' FAILED:");
      System.err.println("EXPECTING:\n" + "'" + expected + "'");
      System.err.println("FOUND:\n" + "'" + actual + "'");
      System.err.println("---END---\n");
    }
    return res;
  }

  private static boolean compileAndRunArgs(String name, String input,
                                           String[] argv) {
    boolean res;
    InputStream org_in = System.in;
    PrintStream org_out = System.out;
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      PrintStream ps = new PrintStream(out);
      InputStream in = new ByteArrayInputStream(input.getBytes());
      System.setIn(in);
      System.setOut(ps);
      if(compile(name, false) != 0) {
        System.err.println("Compilation of " + suitePath + name + ".Mod" +
                           " FAILED:");
        System.err.println(out.toString());
        System.err.println("---END---\n");
        res = false;
      } else {
        ClassLoader classLoader = TestRunner.class.getClassLoader();
        Class<?> aClass = classLoader.loadClass(name);
        Method main = aClass.getMethod("main", String[].class);
        main.invoke(null, (Object) argv);
        res = assertEquals(name, getExpectedOutput(name), out.toString());
      }
    } catch (Exception e) {
      System.err.println("EXCEPTION thrown while executing " + suitePath +
                         name + ".Mod:");
      e.printStackTrace();
      System.err.println("---END---\n");
      res = false;
    }
    System.setIn(org_in);
    System.setOut(org_out);
    return res;
  }

  private static int compile(String name, boolean newSym) {
    OJP.Compile((suitePath + name + ".Mod\0").toCharArray(), newSym,
                outFolder.toCharArray());
    return OJS.errcnt;
  }

  private static boolean compileAndRunWithInput(String name, String input) {
    return compileAndRunArgs(name, input, null);
  }

  private static boolean compileAndRun(String name) {
    return compileAndRunArgs(name, "", null);
  }

  private static boolean compileAndFail(String name, int errors, String msg) {
    boolean res;
    int errcnt;

    ByteArrayOutputStream out = new ByteArrayOutputStream();
    PrintStream ps = new PrintStream(out);
    System.setOut(ps);
    errcnt = compile(name, false);
    if(errcnt != errors) {
      System.err.println("Test '" + name + "' FAILED:");
      System.err.println("EXPECTING: " + errors + " compilation error[s]");
      System.err.println("FOUND: "  + errcnt);
      System.err.println("---END---\n");
      res = false;
    } else {
      res = out.toString().contains(msg);
      if(!res) {
        System.err.println("Test '" + name + "' FAILED:");
        System.err.println("EXPECTED ERROR: " + msg);
        System.err.println("NOT FOUND IN: " + out.toString());
        System.err.println("---END---\n");
      }
    }
    return res;
  }

  private static String getExpectedOutput(String name) {
    char[] expected = new char[2000];
    String res;

    Files_FileDesc f = Files.Open((suitePath + name + ".txt\0").toCharArray());
    if(f == null) {
      System.err.println("ERROR: cannot open " + suitePath + name + ".txt");
      res = "";
    } else {
      Files.ReadStr(f, expected);
      Files.Close(f);
      res = new String(expected, 0, Strings.Length(expected));
    }
    return res;
  }
}
