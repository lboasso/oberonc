public final class Out {
  private Out() {}

  public static void Char(char ch) {
    System.out.print(ch);
  }

  public static void String(char[] str) {
    int i = 0;
    int len = str.length;
    while(i < len && str[i] != '\0') {
      System.out.print(str[i]);
      i++;
    }
  }

  public static void Real(float x, int n) {
    System.out.printf("%" + n + "f", x);
  }

  public static void Int(int x, int n) {
    System.out.printf("%" + n + "d", x);
  }

  public static void Ln() {
    System.out.print('\n');
  }

  public static void Hex(int x) {
    System.out.printf("%08X", x);
  }

}
