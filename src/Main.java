import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.HashMap;

public class Main {

    public static void main(String[] args) {

        JFrame jframe = new JFrame();
        jframe.setSize(new Dimension(1280, 720));
        jframe.getContentPane().setBackground(Color.CYAN);
        jframe.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        jframe.setResizable(false);
        jframe.addMouseListener(new MouseHelper());

        GraphicsJPanel graphicsJPanel = new GraphicsJPanel(jframe);
        jframe.add(graphicsJPanel);

        jframe.setVisible(true);

        MouseHelper.init();
        CircleHelper.init();

        long startMillis = System.currentTimeMillis();
        while (true) { // drawing and rendering

            startMillis = System.currentTimeMillis();

            graphicsJPanel.clear();

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
            int posX = width /2; // middle of circle
            int posY = height /2; // middle of circle

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

            // fill in left side
            for (int x = posX -((int) radius); x <= posX -((int) innerRadius); x++) {
                Integer highestY = null;
                Integer lowestY = null;
                for (Integer y : mainCircle.get(x -posX)) {
                    if (highestY == null || lowestY == null) {
                        highestY = y;
                        lowestY = y;
                    } else {
                        if (y > highestY) {
                            highestY = y;
                        } else if (y < lowestY) {
                            lowestY = y;
                        }
                    }
                }
                if (highestY != null && lowestY != null) {
                    graphicsJPanel.bufferedImage_graphics2D.drawLine(x, posY -highestY, x, posY -lowestY);
                }
            }

            // fill in right side
            for (int x = posX +((int) innerRadius); x <= posX +((int) radius); x++) {
                Integer highestY = null;
                Integer lowestY = null;
                for (Integer y : mainCircle.get(x -posX)) {
                    if (highestY == null || lowestY == null) {
                        highestY = y;
                        lowestY = y;
                    } else {
                        if (y > highestY) {
                            highestY = y;
                        } else if (y < lowestY) {
                            lowestY = y;
                        }
                    }
                }
                if (highestY != null && lowestY != null) {
                    graphicsJPanel.bufferedImage_graphics2D.drawLine(x, posY -highestY, x, posY -lowestY);
                }
            }

            // fill in top side
            for (int x = posX -(innerRadius_INT) +1; x <= posX +(innerRadius_INT) -1; x++) {
                Integer outermostMainY = null; // outermost relative to the inside of the lines. i want to colour the circle points themselves.
                Integer outermostInnerY = null;
                for (Integer y : mainCircle.get(x -posX)) {
                    if (outermostMainY == null) {
                        outermostMainY = y;
                    } else {
                        if (y > outermostMainY) {
                            outermostMainY = y;
                        }
                    }
                }
                for (Integer y : innerCircle.get(x -posX)) {
                    if (y < 0) {
                        continue;
                    }
                    if (outermostInnerY == null) {
                        outermostInnerY = y;
                    } else {
                        if (y < outermostInnerY) {
                            outermostInnerY = y;
                        }
                    }
                }
                if (outermostMainY != null && outermostInnerY != null) {
                    graphicsJPanel.bufferedImage_graphics2D.drawLine(x, posY -outermostMainY, x, posY -outermostInnerY);
                }
            }

            // fill in bottom side
            for (int x = posX -(innerRadius_INT) +1; x <= posX +(innerRadius_INT) -1; x++) {
                Integer outermostMainY = null;
                Integer outermostInnerY = null;
                for (Integer y : mainCircle.get(x -posX)) {
                    if (outermostMainY == null) {
                        outermostMainY = y;
                    } else {
                        if (y < outermostMainY) {
                            outermostMainY = y;
                        }
                    }
                }
                for (Integer y : innerCircle.get(x -posX)) {
                    if (y > 0) {
                        continue;
                    }
                    if (outermostInnerY == null) {
                        outermostInnerY = y;
                    } else {
                        if (y > outermostInnerY) {
                            outermostInnerY = y;
                        }
                    }
                }
                if (outermostMainY != null && outermostInnerY != null) {
                    graphicsJPanel.bufferedImage_graphics2D.drawLine(x, posY -outermostInnerY, x, posY -outermostMainY);
                }
            }

            graphicsJPanel.render();

            long timeTook = System.currentTimeMillis() -startMillis;
            System.out.println("MS/F: " +timeTook +", FPS: " +(1 /(timeTook /1000d)));

        }

    }

}
