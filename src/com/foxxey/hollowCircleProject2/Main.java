package com.foxxey.hollowCircleProject2;

import com.foxxey.hollowCircleProject2.natives.TestDLL;
import com.sun.jna.Native;

import java.io.IOException;

public class Main {

    public static void main(String[] args) throws IOException {

        TestDLL TestDLL = Native.load("natives/TestDLL", TestDLL.class);

        TestDLL.startWindow();

//        long cooldown = 1000;
//        long lastmillis = System.currentTimeMillis();
//        while (true) {
//            if (System.currentTimeMillis() -lastmillis >= cooldown) {
//                lastmillis = System.currentTimeMillis();
//                System.out.println("java run");
//            }
//        }

////        Image imagePointer = new Image(new Memory(new Image().size()));
////        test2.INSTANCE.mainFunc(imagePointer);
////        System.out.println(imagePointer);
//
////        TestDLL.INSTANCE.mainFunc();
//
////
////        for (int i = 0; i <= bytes.length -1; i++) {
//////            System.out.println(bytes[i]);
////        }
//
//
//
//        JFrame jframe = new JFrame();
//        jframe.setLocation((Toolkit.getDefaultToolkit().getScreenSize().width /2) -(jframeLastWidth /2), (Toolkit.getDefaultToolkit().getScreenSize().height /2) -(jframeLastHeight /2));
//        jframe.setSize(jframeLastWidth, jframeLastHeight);
//        jframe.getContentPane().setBackground(Color.CYAN);
//        jframe.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
//        jframe.setResizable(true);
//        jframe.setUndecorated(true);
//        jframe.setAlwaysOnTop(true);
//        jframe.addMouseListener(new MouseHelper());
//        jframe.addKeyListener(new KeyHelper());
//
//        GraphicsJPanel graphicsJPanel = new GraphicsJPanel(jframe);
//        jframe.add(graphicsJPanel);
//
//        jframe.setVisible(true);
//
//        MouseHelper.init();
//        KeyHelper.init();
//        CircleHelper.init();
//
//
//        while (true) { // drawing and rendering

//
//
//
//
//
//


//
//
//
//
//
////
//
//            // render something cool
//            int width = graphicsJPanel.getWidth();
//            int height = graphicsJPanel.getHeight();
////            int posX = width /2; // middle of circle
////            int posY = height /2; // middle of circle
//            float posX = (Toolkit.getDefaultToolkit().getScreenSize().width /2f) -graphicsJPanel.getLocationOnScreen().x; // middle of circle
//            float posY = (Toolkit.getDefaultToolkit().getScreenSize().height /2f) -graphicsJPanel.getLocationOnScreen().y; // middle of circle
//
//            // set radius using time so its animated
//            float radius = 0;
//            long totalAnimationTime = 9000L; // in millis
//            float progress = System.currentTimeMillis() %totalAnimationTime /((float) totalAnimationTime); // 0 to 1
//            if (progress < .5f) { // 0 to .5
//                radius = MathHelper.interpolate_circular_slowFastSlow(progress *2f, 10, 500);
//            } else { // .5 to 1
//                radius = MathHelper.interpolate_circular_slowFastSlow((progress -.5f) *2f, 500, 10);
//            }
//
//            float borderWidth = 10f; // hard-coded
//
//
//            long totalColourAnimationTime = 2000L; // in millis
//            float colourProgress = System.currentTimeMillis() %totalColourAnimationTime /((float) totalColourAnimationTime); // 0 to 1
//            Color circleColour = Color.getHSBColor(colourProgress, 1, 1);
//
////            // draw outer circle piece first
////            for (Integer relativeX : mainCircle.keySet()) {
////                for (Integer relativeY : mainCircle.get(relativeX)) {
////                    graphicsJPanel.drawPixel(posX +relativeX, posY -relativeY, Color.WHITE);
////                }
////            }
////
////            // draw inner circle piece next
////            for (Integer relativeX : innerCircle.keySet()) {
////                for (Integer relativeY : innerCircle.get(relativeX)) {
////                    graphicsJPanel.drawPixel(posX +relativeX, posY -relativeY, Color.WHITE);
////                }
////            }
//
//            // fill in the circle including the 2 circles themselves.
////            graphicsJPanel.bufferedImage_graphics2D.setColor(circleColour);
//
//            // call gpu to draw circle
//
////            ByteBuffer buffer = ByteBuffer.allocateDirect(width *height *3); // RGB. every pixel only needs 3 x to store color. each colour from 0-255 is 1 byte. each red, green, and blue get 1 byte.
////            byte[] colours = new byte[width *height *3];
////            MemorySegment
////            MemorySegment segment = MemorySegment.ofArray(byteArray);
////            // Get the base memory address of the segment
////            MemoryAddress address = segment.address();
////            Pointer coloursP = Native.getDirectBufferPointer(buffer);
////            TestDLL.INSTANCE.drawHollowCircleWithBorder(posX, posY, radius, borderWidth, width, height, colours);
////            System.out.println(buffer.get(0) & 0xFF);
////            System.out.println(buffer.get(1) & 0xFF);
////            System.out.println(buffer.get(2) & 0xFF);
////            System.out.println(colours[0] & 0xFF);
////            System.out.println(colours[1] & 0xFF);
////            System.out.println(colours[2] & 0xFF);
//
////            TestDLL.INSTANCE.startWindow();
//
////            ((DataBufferInt) graphicsJPanel.bufferedImage.getRaster().getDataBuffer()).getData();
////            byte[] data = new byte[width *height *3]; // Create array to hold remaining bytes
////            for (int i = 0; i <= data.length -1; i++) {
////                data[i] = (byte) (buffer.get(i) & 0xFF);
////            }
////            graphicsJPanel.bufferedImage.createGraphics().drawBytes(data, 0, width *height *3, 0, 0);
////            graphicsJPanel.bufferedImage.getRaster().
////            graphicsJPanel.bufferedImage_graphics2D.drawBytes(data, 0, buffer.remaining(), 0, 0);
//
//
//
//        }

    }

}
