#define EXPORT __declspec(dllexport)

#include <stdio.h>

__global__ void drawPixel(float posX, float posY, float radius, float borderWidth, int width, int height, long pixels, uint8_t *d_colours) {
  uint32_t threadIndex = (threadIdx.z *blockDim.x *blockDim.y) +(threadIdx.y *blockDim.x) +threadIdx.x;
  uint32_t blockIndex = (blockIdx.z *gridDim.x *gridDim.y) +(blockIdx.y *gridDim.x) +blockIdx.x;
  uint32_t index = blockIndex *blockDim.x *blockDim.y *blockDim.z +threadIndex;
  if (index > pixels -1) {
    return;
  }
  uint16_t pixelX = index %width; // TODO
  uint16_t pixelY = index /width;

  float innerRadius = radius -borderWidth +1;
  if (innerRadius > radius) {
    innerRadius = radius;
  }

  float radiusSquared = radius *radius;
  float innerRadiusSquared = innerRadius *innerRadius;

  float distanceX = pixelX -posX;
  float distanceY = pixelY -posY;
  float distanceSquared = (distanceX *distanceX) +(distanceY *distanceY);
  if (distanceSquared < radiusSquared && distanceSquared > innerRadiusSquared) {
    // draw white
    d_colours[index *3 +0] = 255; // red
    d_colours[index *3 +1] = 254; // green
    d_colours[index *3 +2] = 253; // blue
  } else {
    // draw black
    d_colours[index *3 +0] = 100; // red
    d_colours[index *3 +1] = 102; // green
    d_colours[index *3 +2] = 101; // blue
  }
}

extern "C" EXPORT void drawHollowCircleWithBorder(float posX, float posY, float radius, float borderWidth, int width, int height, uint8_t *colours) {
  
  uint8_t *d_colours;
  const uint32_t pixels = width *height;
  const uint32_t bytes = pixels *3 *sizeof(uint8_t);
 
  cudaMalloc(&d_colours, bytes);

  struct dim3 gridDim_ = {(pixels /256) +1, 1, 1};
  struct dim3 blockDim_ = {32, 4, 2};
  drawPixel<<<gridDim_, blockDim_>>>(posX, posY, radius, borderWidth, width, height, pixels, d_colours); // 1 thread per pixel

  cudaMemcpy(colours, d_colours, bytes, cudaMemcpyDeviceToHost); // to, from

  cudaFree(d_colours);

  // DEBUG
  // colours[0] = 230;
  // colours[1] = 100;
  // colours[2] = 30;

  return;

}