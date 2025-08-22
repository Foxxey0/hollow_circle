import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;

public class GraphicsJPanel extends JPanel {

    private JFrame jFrame;
    private BufferedImage bufferedImage;
    public Graphics2D bufferedImage_graphics2D;

    public GraphicsJPanel(JFrame jFrame) {

        this.jFrame = jFrame;
        this.bufferedImage = new BufferedImage(jFrame.getWidth(), jFrame.getHeight(), BufferedImage.TYPE_INT_RGB);
        this.bufferedImage_graphics2D = bufferedImage.createGraphics();

        clear();

    }

    public void clear() {
        bufferedImage_graphics2D.clearRect(0, 0, bufferedImage.getWidth(), bufferedImage.getHeight());
    }

    public void drawPixel(int x, int y, Color colour) {
        if (x < 0) {
            return;
        }
        if (x > getWidth() -1) {
            return;
        }
        if (y < 0) {
            return;
        }
        if (y > getHeight() -1) {
            return;
        }
        bufferedImage.setRGB(x, y, colour.getRGB());
    }

    public void render() {
        getGraphics().drawImage(bufferedImage, 0, 0, this);
    }

}
