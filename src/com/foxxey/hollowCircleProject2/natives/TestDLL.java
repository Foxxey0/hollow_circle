package com.foxxey.hollowCircleProject2.natives;

import com.sun.jna.Library;
import com.sun.jna.Native;

public interface TestDLL extends Library {

//    public void drawHollowCircleWithBorder(float posX, float posY, float radius, float borderWidth, int width, int height, Pointer colours);

    public void startWindow();

}
