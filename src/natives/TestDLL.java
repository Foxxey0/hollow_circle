package natives;

import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.Pointer;

public interface TestDLL extends Library {

    TestDLL INSTANCE = Native.load("natives/TestDLL", TestDLL.class);

//    public void drawHollowCircleWithBorder(float posX, float posY, float radius, float borderWidth, int width, int height, Pointer colours);

    public void startWindow();

}
