package natives;

import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.Pointer;
import com.sun.jna.Structure;

public interface test2 extends Library {

    test2 INSTANCE = Native.load("natives/test2", test2.class);

    public void mainFunc(Image imagePointer); // returns struct Pixel* (pixel array pointer, so a memory address)

}
