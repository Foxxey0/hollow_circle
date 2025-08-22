#include <stdio.h>
#include <windows.h>

extern "C" {
  #include "MathHelper.h"
}

// GPU kernel
__global__ void drawHollowCircleWithBorder_kernel(cudaSurfaceObject_t const surface, const UINT16 windowWidth, const UINT32 windowWidthReciprocal, const UINT16 windowHeight, const UINT32 pixelsAmount, const UINT32 paddedRowBytesAmount, const float circleMiddleX, const float circleMiddleY, const float radiusSquared, const float innerRadiusSquared, const float outerAABBHalfLength, const float innerAABBHalfLength, const struct colour_RGB rgb) {
  UINT32 threadIndex = (threadIdx.z *blockDim.x *blockDim.y) +(threadIdx.y *blockDim.x) +threadIdx.x;
  UINT32 blockIndex = (blockIdx.z *gridDim.x *gridDim.y) +(blockIdx.y *gridDim.x) +blockIdx.x;
  UINT32 index = (blockIndex *256) +threadIndex;
  if (index > pixelsAmount -1) {
    return;
  }
  // UINT16 pixelX = index %windowWidth;
  // UINT16 pixelY = index /windowWidth;
  UINT16 pixelY = __umulhi(index ,windowWidthReciprocal); // x *y but returns only high 32 bits, and then get the 16 bits out of the result that i need.
  UINT16 pixelX = index -(pixelY *windowWidth);

  float distanceX = pixelX -circleMiddleX;
  float distanceY = pixelY -circleMiddleY;
  // float distanceX = fabs(pixelX -circleMiddleX);
  // float distanceY = fabs(pixelY -circleMiddleY);

  // AABB check, sort of. its faster than full AABB check. this check PROBABLY makes many warps fail faster than they would have ended if they just did the distanceSquared calculation, saving time.
  // if (distanceX > outerAABBHalfLength || distanceY > outerAABBHalfLength || (distanceX < innerAABBHalfLength && distanceY < innerAABBHalfLength)) {
  //   return;
  // }
  if (distanceX < -outerAABBHalfLength || distanceX > outerAABBHalfLength || distanceY < -outerAABBHalfLength || distanceY > outerAABBHalfLength || (distanceX > -innerAABBHalfLength && distanceX < innerAABBHalfLength && distanceY > -innerAABBHalfLength && distanceY < innerAABBHalfLength)) {
    return;
  }

  float distanceSquared = (distanceX *distanceX) +(distanceY *distanceY);
  if (distanceSquared < radiusSquared && distanceSquared > innerRadiusSquared) {
    // draw white
    // long pixelIndex = (pixelY *paddedRowBytesAmount) +(pixelX *3);
    // d_bitmap[pixelIndex +0] = rgb.blue; // B
    // d_bitmap[pixelIndex +1] = rgb.green; // G
    // d_bitmap[pixelIndex +2] = rgb.red; // R

    uchar4 color = make_uchar4(rgb.red, rgb.green, rgb.blue, 255);
    surf2Dwrite(color, surface, pixelX *sizeof(uchar4), pixelY);
  }
}

// GPU kernel
__global__ void clearWindow_kernel(cudaSurfaceObject_t const surface, const UINT16 windowWidth, const UINT32 windowWidthReciprocal, const UINT16 windowHeight, const UINT32 pixelsAmount, const UINT32 paddedRowBytesAmount, const struct colour_RGB rgb) {
  UINT32 threadIndex = (threadIdx.z *blockDim.x *blockDim.y) +(threadIdx.y *blockDim.x) +threadIdx.x;
  UINT32 blockIndex = (blockIdx.z *gridDim.x *gridDim.y) +(blockIdx.y *gridDim.x) +blockIdx.x;
  UINT32 index = (blockIndex *256) +threadIndex;
  if (index > pixelsAmount -1) {
    return;
  }
  // UINT16 pixelX = index %windowWidth;
  // UINT16 pixelY = index /windowWidth;
  UINT16 pixelY = __umulhi(index ,windowWidthReciprocal); // x *y but returns only high 32 bits, and then get the 16 bits out of the result that i need.
  UINT16 pixelX = index -(pixelY *windowWidth);


  // long pixelIndex = (pixelY *paddedRowBytesAmount) +(pixelX *3);
  // d_bitmap[pixelIndex +0] = rgb.blue; // B
  // d_bitmap[pixelIndex +1] = rgb.green; // G
  // d_bitmap[pixelIndex +2] = rgb.red; // R

  uchar4 color = make_uchar4(rgb.red, rgb.green, rgb.blue, 255);
  surf2Dwrite(color, surface, pixelX *sizeof(uchar4), pixelY);

}