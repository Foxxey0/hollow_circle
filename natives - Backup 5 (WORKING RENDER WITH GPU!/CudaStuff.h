#include <windows.h>

extern void drawHollowCircleWithBorder(byte *d_bitmap, UINT16 windowWidth, UINT16 windowHeight, float circleMiddleX, float circleMiddleY, float radius, float borderWidth, struct colour_RGB rgb);
extern void clearWindow(byte *d_bitmap, UINT16 windowWidth, UINT16 windowHeight, struct colour_RGB rgb);
extern byte * mallocDeviceBitmap(UINT16 windowWidth, UINT16 windowHeight);
extern void copyDeviceBitmapToHostBitmap(byte *bitmap, UINT16 windowWidth, UINT16 windowHeight, byte *d_bitmap);
extern void freeDeviceBitmap(byte *d_bitmap);