import javax.swing.*;
import java.awt.*;
import java.awt.event.KeyEvent;
import java.util.ArrayList;
import java.util.HashMap;

public class Main {

    public static void main(String[] args) {

        boolean dragging = false;
        int draggingRelativeX = 0; // mouse position relative to window position. mousePos -windowPos
        int draggingRelativeY = 0;

        boolean resizing = false;
        int resizingOriginalMousePosX = 0;
        int resizingOriginalMousePosY = 0;
        int resizingOriginalPosX = 0;
        int resizingOriginalPosY = 0;
        int resizingOriginalWidth = 0;
        int resizingOriginalHeight = 0;
        int resizeBorder = 10;
        int resizeType = 0; // Example. Cursor.NW_RESIZE_CURSOR

        int jframeLastWidth = 200;
        int jframeLastHeight = 200;

        JFrame jframe = new JFrame();
        jframe.setLocation((Toolkit.getDefaultToolkit().getScreenSize().width /2) -(jframeLastWidth /2), (Toolkit.getDefaultToolkit().getScreenSize().height /2) -(jframeLastHeight /2));
        jframe.setSize(jframeLastWidth, jframeLastHeight);
        jframe.getContentPane().setBackground(Color.CYAN);
        jframe.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        jframe.setResizable(true);
        jframe.setUndecorated(true);
        jframe.setAlwaysOnTop(true);
        jframe.addMouseListener(new MouseHelper());
        jframe.addKeyListener(new KeyHelper());

        GraphicsJPanel graphicsJPanel = new GraphicsJPanel(jframe);
        jframe.add(graphicsJPanel);

        jframe.setVisible(true);

        MouseHelper.init();
        KeyHelper.init();
        CircleHelper.init();

        long startMillis = System.currentTimeMillis();
        while (true) { // drawing and rendering

            startMillis = System.currentTimeMillis();

            Point mousePos = MouseInfo.getPointerInfo().getLocation();

            // check for resize
            if (jframe.getWidth() != jframeLastWidth || jframe.getHeight() != jframeLastHeight) {
                graphicsJPanel.newBufferedImageStuff();
                jframeLastWidth = jframe.getWidth();
                jframeLastHeight = jframe.getHeight();
            } else {
                graphicsJPanel.clear(); // we only have to clear it here. if it IS resized, it creates a new bufferedimage anyway that starts clear.
            }

            // keyboard stuff
            if (KeyHelper.states.containsKey(KeyEvent.VK_ESCAPE) && KeyHelper.states.get(KeyEvent.VK_ESCAPE)) {
                System.out.println("Escape pressed. Exiting.");
                System.exit(0);
            }

            // mouse stuff (dragging, resizing). the reason this doesnt break is because the click is only detected if its on the window. so it should be impossible to click off the window and move the cursor onto it to start dragging.
            if (MouseHelper.states.get(1)) { // left button is down
                if (!dragging) {
                    if (resizing) {

                        int mousePosX_delta = mousePos.x -resizingOriginalMousePosX;
                        int mousePosY_delta = mousePos.y -resizingOriginalMousePosY;

                        if (resizeType == Cursor.W_RESIZE_CURSOR) {
                            jframe.setLocation(resizingOriginalPosX +mousePosX_delta, resizingOriginalPosY);
                            jframe.setSize(resizingOriginalWidth -mousePosX_delta, resizingOriginalHeight);
                        } else if (resizeType == Cursor.E_RESIZE_CURSOR) {
                            jframe.setSize(resizingOriginalWidth +mousePosX_delta, resizingOriginalHeight);
                        } else if (resizeType == Cursor.N_RESIZE_CURSOR) {
                            jframe.setLocation(resizingOriginalPosX, resizingOriginalPosY +mousePosY_delta);
                            jframe.setSize(resizingOriginalWidth, resizingOriginalHeight -mousePosY_delta);
                        } else if (resizeType == Cursor.S_RESIZE_CURSOR) {
                            jframe.setSize(resizingOriginalWidth, resizingOriginalHeight +mousePosY_delta);
                        } else if (resizeType == Cursor.NW_RESIZE_CURSOR) {
                            jframe.setLocation(resizingOriginalPosX +mousePosX_delta, resizingOriginalPosY +mousePosY_delta);
                            jframe.setSize(resizingOriginalWidth -mousePosX_delta, resizingOriginalHeight -mousePosY_delta);
                        } else if (resizeType == Cursor.NE_RESIZE_CURSOR) {
                            jframe.setLocation(resizingOriginalPosX, resizingOriginalPosY +mousePosY_delta);
                            jframe.setSize(resizingOriginalWidth +mousePosX_delta, resizingOriginalHeight -mousePosY_delta);
                        } else if (resizeType == Cursor.SW_RESIZE_CURSOR) {
                            jframe.setLocation(resizingOriginalPosX +mousePosX_delta, resizingOriginalPosY);
                            jframe.setSize(resizingOriginalWidth -mousePosX_delta, resizingOriginalHeight +mousePosY_delta);
                        } else if (resizeType == Cursor.SE_RESIZE_CURSOR) {
                            jframe.setLocation(resizingOriginalPosX, resizingOriginalPosY);
                            jframe.setSize(resizingOriginalWidth +mousePosX_delta, resizingOriginalHeight +mousePosY_delta);
                        }
                    } else {
                        if (mousePos.x >= jframe.getLocationOnScreen().x && mousePos.x <= jframe.getLocationOnScreen().x +resizeBorder) { // left
                            if (mousePos.y >= jframe.getLocationOnScreen().y && mousePos.y <= jframe.getLocationOnScreen().y +resizeBorder) { // left +top
                                resizeType = Cursor.NW_RESIZE_CURSOR;
                                resizing = true;
                                resizingOriginalMousePosX = mousePos.x;
                                resizingOriginalMousePosY = mousePos.y;
                                resizingOriginalPosX = jframe.getLocationOnScreen().x;
                                resizingOriginalPosY = jframe.getLocationOnScreen().y;
                                resizingOriginalWidth = jframeLastWidth;
                                resizingOriginalHeight = jframeLastHeight;
                            } else if (mousePos.y <= jframe.getLocationOnScreen().y +jframeLastHeight && mousePos.y >= jframe.getLocationOnScreen().y +jframeLastHeight -resizeBorder) { // left +bottom
                                resizeType = Cursor.SW_RESIZE_CURSOR;
                                resizing = true;
                                resizingOriginalMousePosX = mousePos.x;
                                resizingOriginalMousePosY = mousePos.y;
                                resizingOriginalPosX = jframe.getLocationOnScreen().x;
                                resizingOriginalPosY = jframe.getLocationOnScreen().y;
                                resizingOriginalWidth = jframeLastWidth;
                                resizingOriginalHeight = jframeLastHeight;
                            } else { // only left
                                resizeType = Cursor.W_RESIZE_CURSOR;
                                resizing = true;
                                resizingOriginalMousePosX = mousePos.x;
                                resizingOriginalMousePosY = mousePos.y;
                                resizingOriginalPosX = jframe.getLocationOnScreen().x;
                                resizingOriginalPosY = jframe.getLocationOnScreen().y;
                                resizingOriginalWidth = jframeLastWidth;
                                resizingOriginalHeight = jframeLastHeight;
                            }
                        } else if (mousePos.x <= jframe.getLocationOnScreen().x +jframeLastWidth && mousePos.x >= jframe.getLocationOnScreen().x +jframeLastWidth -resizeBorder) { // right
                            if (mousePos.y >= jframe.getLocationOnScreen().y && mousePos.y <= jframe.getLocationOnScreen().y +resizeBorder) { // right +top
                                resizeType = Cursor.NE_RESIZE_CURSOR;
                                resizing = true;
                                resizingOriginalMousePosX = mousePos.x;
                                resizingOriginalMousePosY = mousePos.y;
                                resizingOriginalPosX = jframe.getLocationOnScreen().x;
                                resizingOriginalPosY = jframe.getLocationOnScreen().y;
                                resizingOriginalWidth = jframeLastWidth;
                                resizingOriginalHeight = jframeLastHeight;
                            } else if (mousePos.y <= jframe.getLocationOnScreen().y +jframeLastHeight && mousePos.y >= jframe.getLocationOnScreen().y +jframeLastHeight -resizeBorder) { // right +bottom
                                resizeType = Cursor.SE_RESIZE_CURSOR;
                                resizing = true;
                                resizingOriginalMousePosX = mousePos.x;
                                resizingOriginalMousePosY = mousePos.y;
                                resizingOriginalPosX = jframe.getLocationOnScreen().x;
                                resizingOriginalPosY = jframe.getLocationOnScreen().y;
                                resizingOriginalWidth = jframeLastWidth;
                                resizingOriginalHeight = jframeLastHeight;
                            } else { // only right
                                resizeType = Cursor.E_RESIZE_CURSOR;
                                resizing = true;
                                resizingOriginalMousePosX = mousePos.x;
                                resizingOriginalMousePosY = mousePos.y;
                                resizingOriginalPosX = jframe.getLocationOnScreen().x;
                                resizingOriginalPosY = jframe.getLocationOnScreen().y;
                                resizingOriginalWidth = jframeLastWidth;
                                resizingOriginalHeight = jframeLastHeight;
                            }
                        } else if (mousePos.y >= jframe.getLocationOnScreen().y && mousePos.y <= jframe.getLocationOnScreen().y +resizeBorder) { // top
                            resizeType = Cursor.N_RESIZE_CURSOR;
                            resizing = true;
                            resizingOriginalMousePosX = mousePos.x;
                            resizingOriginalMousePosY = mousePos.y;
                            resizingOriginalPosX = jframe.getLocationOnScreen().x;
                            resizingOriginalPosY = jframe.getLocationOnScreen().y;
                            resizingOriginalWidth = jframeLastWidth;
                            resizingOriginalHeight = jframeLastHeight;
                        } else if (mousePos.y <= jframe.getLocationOnScreen().y +jframeLastHeight && mousePos.y >= jframe.getLocationOnScreen().y +jframeLastHeight -resizeBorder) { // bottom
                            resizeType = Cursor.S_RESIZE_CURSOR;
                            resizing = true;
                            resizingOriginalMousePosX = mousePos.x;
                            resizingOriginalMousePosY = mousePos.y;
                            resizingOriginalPosX = jframe.getLocationOnScreen().x;
                            resizingOriginalPosY = jframe.getLocationOnScreen().y;
                            resizingOriginalWidth = jframeLastWidth;
                            resizingOriginalHeight = jframeLastHeight;
                        }
                    }
                }
                if (!resizing) {
                    if (dragging) {
                        jframe.setLocation(mousePos.x -draggingRelativeX, mousePos.y -draggingRelativeY);
                    } else {
                        if (
                                mousePos.x >= jframe.getLocationOnScreen().x &&
                                        mousePos.x <= jframe.getLocationOnScreen().x +jframeLastWidth &&
                                        mousePos.y >= jframe.getLocationOnScreen().y &&
                                        mousePos.y <= jframe.getLocationOnScreen().y +jframeLastHeight
                        ) {
                            dragging = true;
                            draggingRelativeX = mousePos.x -jframe.getLocationOnScreen().x;
                            draggingRelativeY = mousePos.y -jframe.getLocationOnScreen().y;
                        }
                    }
                }
            } else { // left button is up
                dragging = false;
                resizing = false;
            }

            // do cursor icon stuff
            if (mousePos.x >= jframe.getLocationOnScreen().x && mousePos.x <= jframe.getLocationOnScreen().x +resizeBorder) { // left
                if (mousePos.y >= jframe.getLocationOnScreen().y && mousePos.y <= jframe.getLocationOnScreen().y +resizeBorder) { // left +top
                    jframe.setCursor(Cursor.NW_RESIZE_CURSOR);
                } else if (mousePos.y <= jframe.getLocationOnScreen().y +jframeLastHeight && mousePos.y >= jframe.getLocationOnScreen().y +jframeLastHeight -resizeBorder) { // left +bottom
                    jframe.setCursor(Cursor.SW_RESIZE_CURSOR);
                } else { // only left
                    jframe.setCursor(Cursor.W_RESIZE_CURSOR);
                }
            } else if (mousePos.x <= jframe.getLocationOnScreen().x +jframeLastWidth && mousePos.x >= jframe.getLocationOnScreen().x +jframeLastWidth -resizeBorder) { // right
                if (mousePos.y >= jframe.getLocationOnScreen().y && mousePos.y <= jframe.getLocationOnScreen().y +resizeBorder) { // right +top
                    jframe.setCursor(Cursor.NE_RESIZE_CURSOR);
                } else if (mousePos.y <= jframe.getLocationOnScreen().y +jframeLastHeight && mousePos.y >= jframe.getLocationOnScreen().y +jframeLastHeight -resizeBorder) { // right +bottom
                    jframe.setCursor(Cursor.SE_RESIZE_CURSOR);
                } else { // only right
                    jframe.setCursor(Cursor.E_RESIZE_CURSOR);
                }
            } else if (mousePos.y >= jframe.getLocationOnScreen().y && mousePos.y <= jframe.getLocationOnScreen().y +resizeBorder) { // top
                jframe.setCursor(Cursor.N_RESIZE_CURSOR);
            } else if (mousePos.y <= jframe.getLocationOnScreen().y +jframeLastHeight && mousePos.y >= jframe.getLocationOnScreen().y +jframeLastHeight -resizeBorder) { // bottom
                jframe.setCursor(Cursor.S_RESIZE_CURSOR);
            } else {
                jframe.setCursor(Cursor.DEFAULT_CURSOR);
            }

            // set radius using time so its animated
            float radius = 0;
            long totalAnimationTime = 9000L; // in millis
            float progress = System.currentTimeMillis() %totalAnimationTime /((float) totalAnimationTime); // 0 to 1
            if (progress < .5f) { // 0 to .5
                radius = MathHelper.interpolate_circular_slowFastSlow(progress *2f, 10, 500);
            } else { // .5 to 1
                radius = MathHelper.interpolate_circular_slowFastSlow((progress -.5f) *2f, 500, 10);
            }

//            jframe.setLocation((int) (Math.cos(System.currentTimeMillis() %1300L /1300f *3.1416 *2) *300 +300), (int) (Math.sin(System.currentTimeMillis() %1300L /1300f *3.1416 *2) *300 +300)); // fun
            jframe.setLocation((Toolkit.getDefaultToolkit().getScreenSize().width /2) -(jframeLastWidth /2) +(int) (Math.cos(System.currentTimeMillis() %1300L /1300f *3.1416 *2) *radius), (Toolkit.getDefaultToolkit().getScreenSize().height /2) -(jframeLastHeight /2) +(int) (Math.sin(System.currentTimeMillis() %1300L /1300f *3.1416 *2) *radius *-1)); // fun


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

//            // set radius using time so its animated
//            float radius = 0;
//            long totalAnimationTime = 9000L; // in millis
//            float progress = System.currentTimeMillis() %totalAnimationTime /((float) totalAnimationTime); // 0 to 1
//            if (progress < .5f) { // 0 to .5
//                radius = MathHelper.interpolate_circular_slowFastSlow(progress *2f, 10, 500);
//            } else { // .5 to 1
//                radius = MathHelper.interpolate_circular_slowFastSlow((progress -.5f) *2f, 500, 10);
//            }

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
            for (int y = posY -radius_INT; y <= posY -innerRadius_INT; y+=1) { // y for the jpanel.
                if (y < 0 || y > jframeLastHeight -1) {
                    continue;
                }
//                if (!mainCircle.containsKey(-(y -posY))) {
//                    continue;
//                }
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
            for (int y = posY -innerRadius_INT +1; y <= posY +innerRadius_INT -1; y+=1) {
                if (y < 0 || y > jframeLastHeight -1) {
                    continue;
                }
//                if (!mainCircle.containsKey(-(y -posY))) {
//                    continue;
//                }
//                if (!innerCircle.containsKey(-(y -posY))) {
//                    continue;
//                }

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
            for (int y = posY +innerRadius_INT; y <= posY +radius_INT; y+=1) { // y for the jpanel.
                if (y < 0 || y > jframeLastHeight -1) {
                    continue;
                }
//                if (!mainCircle.containsKey(-(y -posY))) {
//                    continue;
//                }
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
