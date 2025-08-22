import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

public class CircleHelper {

    private static HashMap<Integer, ArrayList<Integer>>[] circles; // array of hashmaps containing <x, array of y's> of it's circle. circles[radius]. the circle is stored as points, 1 pixel thick, that make up the circle, the center of the circling being (0, 0). it does NOT store an image since thats a waste of memory.
//    private static ArrayList<Point>[] circles;

    public static void init() {

        circles = new HashMap[961]; // 961 (0 - 960) are needed for every radius for 1080p.
//        circles = new ArrayList[961];

        // just do this one manually.
        circles[0] = new HashMap<Integer, ArrayList<Integer>>(); // current circle
        circles[0].put(0, new ArrayList<Integer>(Arrays.asList(0)));
//        circles[0] = new ArrayList<Point>();
//        circles[0].add(new Point(0, 0));

        for (int radius = 1; radius <= 961 -1; radius++) {

            circles[radius] = new HashMap<Integer, ArrayList<Integer>>(); // current circle
//            circles[radius] = new ArrayList<Point>();

            int relativeX = 0;
            int relativeY = radius;
            float d = 3 -(2 *radius);

            drawBresenhamsCirclePixelMirrors(relativeX, relativeY, radius);

            // bresenham's method for drawing circle.
            while (relativeX <= relativeY) {

                if (d < 0) {
                    d = d +(4 *relativeX) +6;
                } else {
                    d = d +4 *(relativeX -relativeY) +10;
                    relativeY--;
                }
                relativeX++;

                drawBresenhamsCirclePixelMirrors(relativeX, relativeY, radius);

            }

        }

    }

    // mirrors this pixel 8 times, the way it works in Bresenhams method.
    private static void drawBresenhamsCirclePixelMirrors(int relativeX, int relativeY, int radius) {
        int relativeX_temp = relativeX;
        int relativeY_temp = relativeY;
        addPoint(relativeX_temp, relativeY_temp, radius); // 0 - 45 degrees

        relativeX_temp = relativeY;
        relativeY_temp = relativeX;
        addPoint(relativeX_temp, relativeY_temp, radius); // 45 - 90 degrees

        relativeX_temp = -relativeX;
        relativeY_temp = relativeY;
        addPoint(relativeX_temp, relativeY_temp, radius); // mirrored left

        relativeX_temp = relativeY;
        relativeY_temp = -relativeX;
        addPoint(relativeX_temp, relativeY_temp, radius); // mirrored left

        relativeX_temp = -relativeX;
        relativeY_temp = -relativeY;
        addPoint(relativeX_temp, relativeY_temp, radius); // mirrored left down

        relativeX_temp = -relativeY;
        relativeY_temp = -relativeX;
        addPoint(relativeX_temp, relativeY_temp, radius); // mirrored left down

        relativeX_temp = relativeX;
        relativeY_temp = -relativeY;
        addPoint(relativeX_temp, relativeY_temp, radius); // mirrored right down

        relativeX_temp = -relativeY;
        relativeY_temp = relativeX;
        addPoint(relativeX_temp, relativeY_temp, radius); // mirrored right down
    }

    private static void addPoint(int x, int y, int radius) {
        if (!circles[radius].containsKey(x)) {
            circles[radius].put(x, new ArrayList<Integer>());
        }
        circles[radius].get(x).add(y);
//        circles[radius].add(new Point(x ,y));
    }

    public static HashMap<Integer, ArrayList<Integer>> getCircle(int radius) {
        return circles[Math.max(radius, 0)]; // TODO add a max as well.
    }
//    public static ArrayList<Point> getCircle(int radius) {
//        return circles[Math.max(radius, 0)]; // TODO add a max as well.
//    }

}
