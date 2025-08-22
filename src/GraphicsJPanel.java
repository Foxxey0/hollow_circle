import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;

public class GraphicsJPanel extends JPanel {

    public BufferedImage bufferedImage;
    private JFrame jFrame;

    public GraphicsJPanel(JFrame jFrame) {

        this.jFrame = jFrame;
        bufferedImage = new BufferedImage(jFrame.getWidth(), jFrame.getHeight(), BufferedImage.TYPE_INT_RGB);
        clear();

    }

    public void clear() {
        Graphics2D graphics2D = bufferedImage.createGraphics();
        graphics2D.clearRect(0, 0, bufferedImage.getWidth(), bufferedImage.getHeight());
        graphics2D.dispose();
    }

    public void drawPixel(int x, int y, int colour) {
        bufferedImage.setRGB(x, y, colour);
    }

    public void drawColumn(int x, int colour) {
        Graphics2D graphics2D = bufferedImage.createGraphics();
        graphics2D.setColor(new Color(colour));
        graphics2D.fillRect(x, 0, 1, bufferedImage.getHeight());
        graphics2D.dispose();
    }

    public void render() {
        getGraphics().drawImage(bufferedImage, 0, 0, this);
    }

}
