#include <windows.h>

// kernel function
extern __global__ void drawHollowCircleWithBorder_kernel(cudaSurfaceObject_t const surface, const UINT16 windowWidth, const UINT32 windowWidthReciprocal, const UINT16 windowHeight, const UINT32 pixelsAmount, const UINT32 paddedRowBytesAmount, const float circleMiddleX, const float circleMiddleY, const float radiusSquared, const float innerRadiusSquared, const float outerAABBHalfLength, const float innerAABBHalfLength, const struct colour_RGB rgb);
extern __global__ void clearWindow_kernel(cudaSurfaceObject_t const surface, const UINT16 windowWidth, const UINT32 windowWidthReciprocal, const UINT16 windowHeight, const UINT32 pixelsAmount, const UINT32 paddedRowBytesAmount, const struct colour_RGB rgb);