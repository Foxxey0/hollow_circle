import javafx.scene.input.KeyCode;

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.util.HashMap;

public class KeyHelper implements KeyListener {

    public static HashMap<Integer, Boolean> states; // keycode, pressed

    public static void init() {
        states = new HashMap<Integer, Boolean>();
    }

    @Override
    public void keyTyped(KeyEvent e) {

    }

    @Override
    public void keyPressed(KeyEvent e) {
        states.put(e.getKeyCode(), true);
    }

    @Override
    public void keyReleased(KeyEvent e) {
        states.put(e.getKeyCode(), false);
    }
}
