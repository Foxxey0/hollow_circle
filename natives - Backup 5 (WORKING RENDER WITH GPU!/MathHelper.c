#define PI 3.1416;

#include <math.h>
#include <windows.h>

struct colour_RGB {
    UINT8 red;
    UINT8 green;
    UINT8 blue;
};

/**
 * @brief this function interpolates using a circle (cosine) to make it ease. This works by turning the progress into a radian and getting the cosine of the radian. The radian will increase linearly, but because cosine is a circle function, the speed of the interpolation starts slow (the circle is verticle here, so the x doesnt change much), then gets faster (the circle is horizontal at the top, making x change really fast), then gets slow again (circle gets vertical again, making x change slowly). I DID IT ALL ON MY OWN YAY. though i think i did it unconventionally because i think normally people use sine, but i found a way to do it with cosine.
 * 
 * @param progress float from 0 to 1 indicating progress from start (0) to finish (1)
 * @param start float to start at
 * @param end float to end at
 * @return float - a float for the current interpolated number 
 */
float interpolate_circular_slowFastSlow(float progress, float start, float end) { // TODO: clamp progress
    float radians = progress *PI; // 0 to pi
    float x = cos(radians); // starts at 1 (0 radians), ends at -1 (pi radians, half the circle)
    // Note: we multiply BEFORE we do offset. (if you offset first, then the multiply will affect the offset, making it wrong).
    float inputRange = fabs(end -start);
    float inputRangeHalf = inputRange /2;
    float x2 = x *inputRangeHalf; // multiply it to give it the right range
    if (end > start) { // reverse sign if necessary to keep it the right way
        x2 = x2 *-1;
    }
    x2 = x2 +((start +end) /2); // offset it and make sure its the right direction. this works because x2 acts as an offset from the MIDDLE VALUE which used to be 0, but it should now the value in the MIDDLE of start and end, which makes the min and max the start and end.
    return x2;
}

/**
 * @brief get progress. float, 0 to 1, whose cycle is as long as the duration. useful for animating or interpolating through time. when the end of duration is reached, progress is 1, then it resets to 0.
 * 
 * @param duration duration of (progression from 0 to 1), in milliseconds.
 * @return float the progress from 0 to 1, interpolated through the duration. this means for every duration cycle that has passed, progress will have gone through 1 cycle as well and will go back to 0.
 */
float getProgress(UINT32 duration) {
    SYSTEMTIME time;
    GetLocalTime(&time);
    UINT32 time_totalMillis = (time.wMinute *60 *1000) +(time.wSecond *1000) +time.wMilliseconds; // i dont think i need more than an hour of duration for now, so ill only go up to minutes :)
    return time_totalMillis %duration /((float) duration);
}

struct colour_RGB HSBToRGB(float hue, float saturation, float brightness) {
    
    struct colour_RGB RGB;

    float r;
    float g;
    float b;
    int i = floorf(hue *6);
    float f = hue *6 -i;
    float p = brightness *(1 -saturation);
    float q = brightness *(1 -f *saturation);
    float t = brightness *(1 -(1 -f) *saturation);

    switch (i %6) {
        case 0: 
            r = brightness;
            g = t;
            b = p;
            break;
        case 1:
            r = q;
            g = brightness;
            b = p;
            break;
        case 2:
            r = p;
            g = brightness;
            b = t;
            break;
        case 3:
            r = p;
            g = q;
            b = brightness;
            break;
        case 4:
            r = t;
            g = p;
            b = brightness;
            break;
        case 5:
            r = brightness;
            g = p;
            b = q;
            break;
    }

    RGB.red = (UINT8) (r *255);
    RGB.green = (UINT8) (g *255);
    RGB.blue = (UINT8) (b *255);
    return RGB;
}