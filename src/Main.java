import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.HashMap;

public class Main {

    public static void main(String[] args) {

        int jframeLastWidth = 1280;
        int jframeLastHeight = 720;

        JFrame jframe = new JFrame();
        jframe.setSize(jframeLastWidth, jframeLastHeight);
        jframe.getContentPane().setBackground(Color.CYAN);
        jframe.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        jframe.setResizable(true);
        jframe.addMouseListener(new MouseHelper());

        GraphicsJPanel graphicsJPanel = new GraphicsJPanel(jframe);
        jframe.add(graphicsJPanel);

        jframe.setVisible(true);

        MouseHelper.init();
        CircleHelper.init();

        long startMillis = System.currentTimeMillis();
        while (true) { // drawing and rendering

            startMillis = System.currentTimeMillis();

            // check for resize
            if (jframe.getWidth() != jframeLastWidth || jframe.getHeight() != jframeLastHeight) {
                graphicsJPanel.newBufferedImageStuff();
                jframeLastWidth = jframe.getWidth();
                jframeLastHeight = jframe.getHeight();
            } else {
                graphicsJPanel.clear();
            }

//            jframe.setLocation((int) (Math.cos(System.currentTimeMillis() %1300L /1300f *3.1416 *2) *300 +300), (int) (Math.sin(System.currentTimeMillis() %1300L /1300f *3.1416 *2) *300 +300)); // fun

//            // TEST
//            if (System.currentTimeMillis() %1000L /1000f > .5f) {
//                graphicsJPanel.drawPixel(5, 5, new Color(255, 255, 255).getRGB());
//            }

//            // DRAWING
//            if (MouseHelper.states.get(1)) { // if left mouse button is down
//                Point mousePos = MouseInfo.getPointerInfo().getLocation();
//                SwingUtilities.convertPointFromScreen(mousePos, graphicsJPanel);
//
//                graphicsJPanel.drawPixel(mousePos.x, mousePos.y, Color.WHITE.getRGB());
//            }

            // render something cool
            int width = graphicsJPanel.getWidth();
            int height = graphicsJPanel.getHeight();
//            int posX = width /2; // middle of circle
//            int posY = height /2; // middle of circle
            int posX = (Toolkit.getDefaultToolkit().getScreenSize().width /2) -graphicsJPanel.getLocationOnScreen().x; // middle of circle
            int posY = (Toolkit.getDefaultToolkit().getScreenSize().height /2) -graphicsJPanel.getLocationOnScreen().y; // middle of circle

            // set radius using time so its animated
            float radius = 0;
            long totalAnimationTime = 9000L; // in millis
            float progress = System.currentTimeMillis() %totalAnimationTime /((float) totalAnimationTime); // 0 to 1
            if (progress < .5f) { // 0 to .5
                radius = MathHelper.interpolate_circular_slowFastSlow(progress *2f, 10, 500);
            } else { // .5 to 1
                radius = MathHelper.interpolate_circular_slowFastSlow((progress -.5f) *2f, 500, 10);
            }

            float borderWidth = 10f;
            float innerRadius = Math.min(radius -borderWidth +1, radius);

            int radius_INT = (int) radius;
            int innerRadius_INT = (int) innerRadius;

            long totalColourAnimationTime = 2000L; // in millis
            float colourProgress = System.currentTimeMillis() %totalColourAnimationTime /((float) totalColourAnimationTime); // 0 to 1
            Color circleColour = Color.getHSBColor(colourProgress, 1, 1);

            // now draw each pixel

            HashMap<Integer, ArrayList<Integer>> mainCircle = CircleHelper.getCircle(radius_INT);
            HashMap<Integer, ArrayList<Integer>> innerCircle = CircleHelper.getCircle(innerRadius_INT);

//            // draw outer circle piece first
//            for (Integer relativeX : mainCircle.keySet()) {
//                for (Integer relativeY : mainCircle.get(relativeX)) {
//                    graphicsJPanel.drawPixel(posX +relativeX, posY -relativeY, Color.WHITE);
//                }
//            }
//
//            // draw inner circle piece next
//            for (Integer relativeX : innerCircle.keySet()) {
//                for (Integer relativeY : innerCircle.get(relativeX)) {
//                    graphicsJPanel.drawPixel(posX +relativeX, posY -relativeY, Color.WHITE);
//                }
//            }

            // fill in the circle including the 2 circles themselves.
            graphicsJPanel.bufferedImage_graphics2D.setColor(circleColour);

            // fill in top side
            for (int y = Math.min(Math.max(posY -radius_INT, 0), jframeLastHeight); y <= Math.min(Math.max(posY -innerRadius_INT, 0), jframeLastHeight); y+=1) { // y for the jpanel.
                if (!mainCircle.containsKey(-(y -posY))) {
                    continue;
                }
                Integer leftmostX = null;
                Integer rightmostX = null;
                for (Integer x : mainCircle.get(-(y -posY))) {
                    if (leftmostX == null || rightmostX == null) {
                        leftmostX = x;
                        rightmostX = x;
                    } else {
                        if (x < leftmostX) {
                            leftmostX = x;
                        } else if (x > rightmostX) {
                            rightmostX = x;
                        }
                    }
                }
                if (leftmostX != null && rightmostX != null) {
                    graphicsJPanel.bufferedImage_graphics2D.drawLine(posX +leftmostX, y, posX +rightmostX, y);
                }
            }

            // fill in middle (left and right at same time by y level)
            for (int y = Math.min(Math.max(posY -innerRadius_INT +1, 0), jframeLastHeight); y <= Math.min(Math.max(posY +innerRadius_INT -1, 0), jframeLastHeight); y+=1) {
                if (!mainCircle.containsKey(-(y -posY))) {
                    continue;
                }
                if (!innerCircle.containsKey(-(y -posY))) {
                    continue;
                }

                Integer outermostMainX = null; // outermost relative to the inside of the lines. i want to colour the circle points themselves.
                Integer outermostInnerX = null;

                // left side of y-line
                outermostMainX = null; // outermost relative to the inside of the lines. i want to colour the circle points themselves.
                outermostInnerX = null;
                for (Integer x : mainCircle.get(-(y -posY))) {
                    if (outermostMainX == null) {
                        outermostMainX = x;
                    } else {
                        if (x < outermostMainX) {
                            outermostMainX = x;
                        }
                    }
                }
                for (Integer x : innerCircle.get(-(y -posY))) {
                    if (x > 0) {
                        continue;
                    }
                    if (outermostInnerX == null) {
                        outermostInnerX = x;
                    } else {
                        if (x > outermostInnerX) {
                            outermostInnerX = x;
                        }
                    }
                }
                if (outermostMainX != null && outermostInnerX != null) {
                    graphicsJPanel.bufferedImage_graphics2D.drawLine(posX +outermostMainX, y, posX +outermostInnerX, y);
                }

                // right side of y-line
                outermostMainX = null; // outermost relative to the inside of the lines. i want to colour the circle points themselves.
                outermostInnerX = null;
                for (Integer x : mainCircle.get(-(y -posY))) {
                    if (outermostMainX == null) {
                        outermostMainX = x;
                    } else {
                        if (x > outermostMainX) {
                            outermostMainX = x;
                        }
                    }
                }
                for (Integer x : innerCircle.get(-(y -posY))) {
                    if (x < 0) {
                        continue;
                    }
                    if (outermostInnerX == null) {
                        outermostInnerX = x;
                    } else {
                        if (x < outermostInnerX) {
                            outermostInnerX = x;
                        }
                    }
                }
                if (outermostMainX != null && outermostInnerX != null) {
                    graphicsJPanel.bufferedImage_graphics2D.drawLine(posX +outermostMainX, y, posX +outermostInnerX, y);
                }

            }

            // fill in bottom side
            for (int y = Math.min(Math.max(posY +innerRadius_INT, 0), jframeLastHeight); y <= Math.min(Math.max(posY +radius_INT, 0), jframeLastHeight); y+=1) { // y for the jpanel.
                if (!mainCircle.containsKey(-(y -posY))) {
                    continue;
                }
                Integer leftmostX = null;
                Integer rightmostX = null;
                for (Integer x : mainCircle.get(-(y -posY))) {
                    if (leftmostX == null || rightmostX == null) {
                        leftmostX = x;
                        rightmostX = x;
                    } else {
                        if (x < leftmostX) {
                            leftmostX = x;
                        } else if (x > rightmostX) {
                            rightmostX = x;
                        }
                    }
                }
                if (leftmostX != null && rightmostX != null) {
                    graphicsJPanel.bufferedImage_graphics2D.drawLine(posX +leftmostX, y, posX +rightmostX, y);
                }
            }

            graphicsJPanel.render();

            long timeTook = System.currentTimeMillis() -startMillis;
            System.out.println("MS/F: " +timeTook +", FPS: " +(1 /(timeTook /1000d)));

        }

    }

}
