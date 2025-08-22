// #include <windows.h>
struct colour_RGB {
    UINT8 red;
    UINT8 green;
    UINT8 blue;
};

extern "C" float interpolate_circular_slowFastSlow(float progress, float start, float end);
extern "C" float getProgress(UINT32 duration);
extern "C" struct colour_RGB HSBToRGB(float hue, float saturation, float brightness);