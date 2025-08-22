import java.awt.*;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.util.HashMap;

public class MouseHelper implements MouseListener {

    public static HashMap<Integer, Boolean> states; // mouseButton, pressed

    public static void init() {
        states = new HashMap<Integer, Boolean>();
        states.put(1, false);
        states.put(2, false);
        states.put(3, false);
    }

    @Override
    public void mouseClicked(MouseEvent e) {

    }

    @Override
    public void mousePressed(MouseEvent e) {
        states.put(e.getButton(), true);
    }

    @Override
    public void mouseReleased(MouseEvent e) {
        states.put(e.getButton(), false);
    }

    @Override
    public void mouseEntered(MouseEvent e) {

    }

    @Override
    public void mouseExited(MouseEvent e) {

    }
}
