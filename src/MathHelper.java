public class MathHelper {

    public static final float pi = 3.1416f;

    /**
     *
     * @param progress float from 0 to 1 indicating progress from start (0) to finish (1)
     * @param start float to start at
     * @param end float to end at
     * @return a float for the current interpolated number
     *
     * this function interpolates using a circle (cosine) to make it ease. This works by turning the progress into a radian and getting the cosine of the radian. The radian will increase linearly, but because cosine is a circle function, the speed of the interpolation starts slow (the circle is verticle here, so the x doesnt change much), then gets faster (the circle is horizontal at the top, making x change really fast), then gets slow again (circle gets vertical again, making x change slowly).
     * I DID IT ALL ON MY OWN YAY. though i think i did it unconventionally because i think normally people use sine, but i found a way to do it with cosine.
     */
    public static float interpolate_circular_slowFastSlow(float progress, float start, float end) { // TODO: clamp progress
        float radians = progress *pi; // 0 to pi
        float x = (float) Math.cos(radians); // starts at 1 (0 radians), ends at -1 (pi radians, half the circle)
        // Note: we multiply BEFORE we do offset. (if you offset first, then the multiply will affect the offset, making it wrong).
        float inputRange = Math.abs(end -start);
        float inputRangeHalf = inputRange /2f;
        float x2 = x *inputRangeHalf; // multiply it to give it the right range
        if (end > start) { // reverse sign if necessary to keep it the right way
            x2 *= -1f;
        }
        x2 += (start +end) /2f; // offset it and make sure its the right direction. this works because x2 acts as an offset from the MIDDLE VALUE which used to be 0, but it should now the value in the MIDDLE of start and end, which makes the min and max the start and end.
        return x2;
    }

}
