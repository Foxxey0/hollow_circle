import javax.swing.*;
import java.awt.*;

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

            AxisAlignedBoundingBox mainAABB = new AxisAlignedBoundingBox(posX -radius, posX +radius, posY -radius, posY +radius, width, height);

            float borderWidth = 10f;
            float innerRadius = radius -borderWidth;

            float innerAABB_sideLength = (float) ((innerRadius *2) /Math.sqrt(2));
            float innerAABB_halfSideLength = innerAABB_sideLength /2;
            AxisAlignedBoundingBox_Negate innerAABB = new AxisAlignedBoundingBox_Negate(posX -innerAABB_halfSideLength, posX +innerAABB_halfSideLength, posY -innerAABB_halfSideLength, posY +innerAABB_halfSideLength, width, height); // this AABB is a NEGATION. we DONT want to draw in here. just adding this note for future reference.

            float radiusSquared = radius *radius;
            float innerRadiusSquared = innerRadius *innerRadius;

            long totalColourAnimationTime = 2000L; // in millis
            float colourProgress = System.currentTimeMillis() %totalColourAnimationTime /((float) totalColourAnimationTime); // 0 to 1
            int circleColour = Color.getHSBColor(colourProgress, 1, 1).getRGB();

            // now draw each pixel

            // left part of hollow AABB
            for (int x = mainAABB.getxMin_INT_clamped(); x <= innerAABB.getxMin_INT_clamped(); x++) {
                for (int y = mainAABB.getyMin_INT_clamped(); y <= mainAABB.getyMax_INT_clamped(); y++) {
                    shader_hollowCircle(x, y, posX, posY, radiusSquared, innerRadiusSquared, graphicsJPanel, circleColour, Color.getHSBColor(0f, 1f, .1f).getRGB());
                }
            }
            // right part of hollow AABB
            for (int x = innerAABB.getxMax_INT_clamped(); x <= mainAABB.getxMax_INT_clamped(); x++) {
                for (int y = mainAABB.getyMin_INT_clamped(); y <= mainAABB.getyMax_INT_clamped(); y++) {
                    shader_hollowCircle(x, y, posX, posY, radiusSquared, innerRadiusSquared, graphicsJPanel, circleColour, Color.getHSBColor(.25f, 1f, .1f).getRGB());
                }
            }
            // top part of hollow AABB
            for (int x = innerAABB.getxMin_INT_clamped() +1; x <= innerAABB.getxMax_INT_clamped() -1; x++) { // the +1 and -1 are because when the left and right parts are drawn, it INCLUDES the mins and maxes. for example, since the innerAABB xMin was ALREADY drawn, we have to add 1 to get the STARTING x of the top and bottom parts.
                for (int y = mainAABB.getyMin_INT_clamped(); y <= innerAABB.getyMin_INT_clamped(); y++) {
                    shader_hollowCircle(x, y, posX, posY, radiusSquared, innerRadiusSquared, graphicsJPanel, circleColour, Color.getHSBColor(.5f, 1f, .1f).getRGB());
                }
            }
            // bottom part of hollow AABB
            for (int x = innerAABB.getxMin_INT_clamped() +1; x <= innerAABB.getxMax_INT_clamped() -1; x++) {
                for (int y = innerAABB.getyMax_INT_clamped(); y <= mainAABB.getyMax_INT_clamped(); y++) {
                    shader_hollowCircle(x, y, posX, posY, radiusSquared, innerRadiusSquared, graphicsJPanel, circleColour, Color.getHSBColor(.75f, 1f, .1f).getRGB());
                }
            }

            graphicsJPanel.render();

            long timeTook = System.currentTimeMillis() -startMillis;
            System.out.println("MS/F: " +timeTook +", FPS: " +(1 /(timeTook /1000d)));

        }

    }

    // this just calculates the colour of a pixel, the way an openGL shader would. if its part of the circle, it uses the circle's colour. if not, it uses the "background" colour, which is really a secondary background colour because i wanted to draw the REAL background and the bounding box colours differently :)
    public static void shader_hollowCircle(int x, int y, int posX, int posY, float radiusSquared, float innerRadiusSquared, GraphicsJPanel graphicsJPanel, int circleColour, int backgroundColour) {
        int distanceX = x -posX;
        int distanceY = y -posY;
        float distanceSquared = (distanceX *distanceX) +(distanceY *distanceY);
        if (distanceSquared < radiusSquared && distanceSquared > innerRadiusSquared) {
            graphicsJPanel.drawPixel(x, y, circleColour);
        } else { // show the AABB, just cuz its cool. OVER 3.3 MILLION CALCULATIONS ON AVERAGE PER FRAME THROWN OUT THE WINDOW :D
            graphicsJPanel.drawPixel(x, y, backgroundColour);
        }
    }

}
