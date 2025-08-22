//import javax.swing.*;
//import java.awt.*;
//import java.awt.image.BufferedImage;
//import java.awt.image.DataBufferInt;
//import java.awt.image.VolatileImage;
//
//public class GraphicsJPanel extends JPanel {
//
//    private JFrame jFrame;
//    public VolatileImage volatileImage;
//    public Graphics2D bufferedImage_graphics2D;
//
//    public GraphicsJPanel(JFrame jFrame) {
//
//        super();
//        this.jFrame = jFrame;
//        this.volatileImage = null;
//        this.bufferedImage_graphics2D = null;
//        newBufferedImageStuff();
//
//    }
//
//    public void newBufferedImageStuff() {
//        if (volatileImage != null && bufferedImage_graphics2D != null) {
//            bufferedImage_graphics2D.dispose();
//        }
////        volatileImage = createVolatileImage(Math.max(1, getWidth()), Math.max(1, getHeight()));
//        volatileImage = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration().createCompatibleVolatileImage(Math.max(getWidth(), 1), Math.max(getHeight(), 1));
//        bufferedImage_graphics2D = volatileImage.createGraphics();
////        clear();
//    }
//
//    public void clear() {
//        bufferedImage_graphics2D.clearRect(0, 0, volatileImage.getWidth(), volatileImage.getHeight());
//    }
//
////    public void drawPixel(int x, int y, Color colour) {
////        if (x < 0) {
////            return;
////        }
////        if (x > getWidth() -1) {
////            return;
////        }
////        if (y < 0) {
////            return;
////        }
////        if (y > getHeight() -1) {
////            return;
////        }
////        bufferedImage.setRGB(x, y, colour.getRGB());
////    }
//
//    public void render() {
//        getGraphics().drawImage(volatileImage, 0, 0, this);
//    }
//
//}

import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferInt;
import java.awt.image.VolatileImage;
import java.nio.ByteBuffer;

public class GraphicsJPanel extends JPanel {

    private JFrame jFrame;
    public BufferedImage bufferedImage;
    public Graphics2D bufferedImage_graphics2D;
    ByteBuffer buffer;

    public GraphicsJPanel(JFrame jFrame) {

        super();
        this.jFrame = jFrame;
        this.bufferedImage = null;
        this.bufferedImage_graphics2D = null;
        newBufferedImageStuff();

    }

    public void newBufferedImageStuff() {
        if (bufferedImage != null && bufferedImage_graphics2D != null) {
            bufferedImage_graphics2D.dispose();
        }
//        volatileImage = createVolatileImage(Math.max(1, getWidth()), Math.max(1, getHeight()));
        bufferedImage = new BufferedImage(Math.max(1, getWidth()), Math.max(1, getHeight()), BufferedImage.TYPE_INT_RGB);
        bufferedImage_graphics2D = bufferedImage.createGraphics();
//        clear();
    }

    public void clear() {
        bufferedImage_graphics2D.clearRect(0, 0, bufferedImage.getWidth(), bufferedImage.getHeight());
    }

//    public void drawPixel(int x, int y, Color colour) {
//        if (x < 0) {
//            return;
//        }
//        if (x > getWidth() -1) {
//            return;
//        }
//        if (y < 0) {
//            return;
//        }
//        if (y > getHeight() -1) {
//            return;
//        }
//        bufferedImage.setRGB(x, y, colour.getRGB());
//    }

    public void render() {
//        getGraphics().drawImage(bufferedImage, 0, 0, this);
//        getGraphics().drawBytes(buffer, 0, buffer.remaining(), 0, 0);
    }

}