import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.WindowConstants;

public final class XYplane {
  public static final int erase = 0;
  public static final int draw = 1;
  public static int X, Y, W, H;
  private static char key;
  private static Viewer viewer;
  private static final int white = Color.WHITE.getRGB();
  private static final int black = Color.BLACK.getRGB();

  // Ensure non-instantiability
  private XYplane() {}

  public static void Open() {
    W = 800;
    H = 800;
    JFrame frame = new JFrame("XYPlane");
    viewer = new Viewer(W, H);
    frame.add(viewer);
    frame.pack();
    frame.setVisible(true);
    frame.setResizable(false);
    frame.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
  }

  public static void Dot(int x, int y, int mode) {
    y = H - y - 1;
    if(mode == erase) {
      viewer.canvas.setRGB(x, y, black);
    } else {
      viewer.canvas.setRGB(x, y, white);
    }
    viewer.updateUI();
  }

  public static boolean isDot(int x, int y) {
    y = H - y - 1;
    return viewer.canvas.getRGB(x, y) == white;
  }

  public static char Key() {
    return key;
  }

  public static void Clear() {
    viewer.fillCanvas(black);
  }

  private static class Viewer extends JPanel {
    private BufferedImage canvas;

    public Viewer(int width, int height) {
      canvas = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
      fillCanvas(black);
      setFocusable(true);
      requestFocus(true);
    }

    public Dimension getPreferredSize() {
      return new Dimension(canvas.getWidth(), canvas.getHeight());
    }

    public void paintComponent(Graphics g) {
      super.paintComponent(g);
      Graphics2D g2 = (Graphics2D) g;
      g2.drawImage(canvas, null, null);
    }

    public void fillCanvas(int color) {
      for(int x = 0; x < canvas.getWidth(); x++) {
        for(int y = 0; y < canvas.getHeight(); y++) {
          canvas.setRGB(x, y, color);
        }
      }
      repaint();
    }
  }
}
