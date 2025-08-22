#include <stdio.h>
#include <windows.h>

#include "Window.h"
#include "MathHelper.h"

byte * mallocDeviceBitmap(UINT16 windowWidth, UINT16 windowHeight) {
  byte *d_bitmap;
  const UINT32 bytesAmount = rowBytesAmountToPaddedRowBytesAmount(windowWidth *3) *windowHeight;
  cudaMalloc(&d_bitmap, bytesAmount);
  return d_bitmap;
}

void copyDeviceBitmapToHostBitmap(byte *bitmap, UINT16 windowWidth, UINT16 windowHeight, byte *d_bitmap) {
  const UINT32 bytesAmount = rowBytesAmountToPaddedRowBytesAmount(windowWidth *3) *windowHeight;
  cudaMemcpy(bitmap, d_bitmap, bytesAmount, cudaMemcpyDeviceToHost); // to, from
}

void freeDeviceBitmap(byte *d_bitmap) {
  cudaFree(d_bitmap);
}



// GPU kernel
__global__ void drawHollowCircleWithBorder_kernel(byte *d_bitmap, UINT16 windowWidth, UINT16 windowHeight, UINT32 pixelsAmount, float circleMiddleX, float circleMiddleY, float radius, float borderWidth, struct colour_RGB rgb) {
  UINT32 threadIndex = (threadIdx.z *blockDim.x *blockDim.y) +(threadIdx.y *blockDim.x) +threadIdx.x;
  UINT32 blockIndex = (blockIdx.z *gridDim.x *gridDim.y) +(blockIdx.y *gridDim.x) +blockIdx.x;
  UINT32 index = blockIndex *blockDim.x *blockDim.y *blockDim.z +threadIndex;
  if (index > pixelsAmount -1) {
    return;
  }
  UINT16 pixelX = index %windowWidth;
  UINT16 pixelY = index /windowWidth;

  float innerRadius = radius -borderWidth;
  if (innerRadius > radius) {
    innerRadius = radius;
  }

  float radiusSquared = radius *radius;
  float innerRadiusSquared = innerRadius *innerRadius;

  float distanceX = pixelX -circleMiddleX;
  float distanceY = pixelY -circleMiddleY;
  float distanceSquared = (distanceX *distanceX) +(distanceY *distanceY);
  if (distanceSquared < radiusSquared && distanceSquared > innerRadiusSquared) {
    // draw white
    long pixelIndex = (pixelY *rowBytesAmountToPaddedRowBytesAmount(windowWidth *3)) +(pixelX *3);
    d_bitmap[pixelIndex +0] = rgb.blue; // B
    d_bitmap[pixelIndex +1] = rgb.green; // G
    d_bitmap[pixelIndex +2] = rgb.red; // R
  } else { // background
    // d_bitmap[(pixelY *rowBytesAmountToPaddedRowBytesAmount(windowWidth *3)) +(pixelX *3 +0)] = 100; // B
    // d_bitmap[(pixelY *rowBytesAmountToPaddedRowBytesAmount(windowWidth *3)) +(pixelX *3 +1)] = 102; // G
    // d_bitmap[(pixelY *rowBytesAmountToPaddedRowBytesAmount(windowWidth *3)) +(pixelX *3 +2)] = 101; // R
  }
}

// extern "C" EXPORT void drawHollowCircleWithBorder(float posX, float posY, float radius, float borderWidth, int width, int height, uint8_t *colours) {
void drawHollowCircleWithBorder(byte *d_bitmap, UINT16 windowWidth, UINT16 windowHeight, float circleMiddleX, float circleMiddleY, float radius, float borderWidth, struct colour_RGB rgb) {
  
  const UINT32 pixelsAmount = windowWidth *windowHeight;

  dim3 gridDim_ = {((pixelsAmount -1) /256) +1, 1, 1};
  dim3 blockDim_ = {32, 4, 2};
  drawHollowCircleWithBorder_kernel<<<gridDim_, blockDim_>>>(d_bitmap, windowWidth, windowHeight, pixelsAmount, circleMiddleX, circleMiddleY, radius, borderWidth, rgb); // 1 thread per pixel

  return;
}



// GPU kernel
__global__ void clearWindow_kernel(byte *d_bitmap, UINT16 windowWidth, UINT16 windowHeight, UINT32 pixelsAmount, struct colour_RGB rgb) {
  UINT32 threadIndex = (threadIdx.z *blockDim.x *blockDim.y) +(threadIdx.y *blockDim.x) +threadIdx.x;
  UINT32 blockIndex = (blockIdx.z *gridDim.x *gridDim.y) +(blockIdx.y *gridDim.x) +blockIdx.x;
  UINT32 index = blockIndex *blockDim.x *blockDim.y *blockDim.z +threadIndex;
  if (index > pixelsAmount -1) {
    return;
  }
  UINT16 pixelX = index %windowWidth;
  UINT16 pixelY = index /windowWidth;


  long pixelIndex = (pixelY *rowBytesAmountToPaddedRowBytesAmount(windowWidth *3)) +(pixelX *3);
  d_bitmap[pixelIndex +0] = rgb.blue; // B
  d_bitmap[pixelIndex +1] = rgb.green; // G
  d_bitmap[pixelIndex +2] = rgb.red; // R

}

void clearWindow(byte *d_bitmap, UINT16 windowWidth, UINT16 windowHeight, struct colour_RGB rgb) {
  
  const UINT32 pixelsAmount = windowWidth *windowHeight;

  dim3 gridDim_ = {((pixelsAmount -1) /256) +1, 1, 1};
  dim3 blockDim_ = {32, 4, 2};
  clearWindow_kernel<<<gridDim_, blockDim_>>>(d_bitmap, windowWidth, windowHeight, pixelsAmount, rgb); // 1 thread per pixel

  return;
}