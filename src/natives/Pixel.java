package natives;

import com.sun.jna.Structure;

@Structure.FieldOrder({"red", "green", "blue"})
public class Pixel extends Structure {

    public int red;
    public int green;
    public int blue;

    public Pixel() {
        super();
    }

}
