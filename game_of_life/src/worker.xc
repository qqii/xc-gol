#ifndef _WORKER_H_
#define _WORKER_H_

#include "stdio.h"
#include "constants.h"
#include "bitmatrix.h"

extern bit hamming[16]; // hamming weight to calculate alive cells
extern bit hash[65536];  // hash for lookup

#define BUFFERWIDTH 2

unsafe void worker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist){

  uint16_t startRow = (WDHT / WCOUNT) * wnumber;
  uint16_t endRow = (WDHT / WCOUNT) * (wnumber + 1);

  bit buffer[BITSLOTSP(BUFFERWIDTH, (IMHT / WCOUNT))];
  uint8_t bufferPointer = 0;
  
  bit finished = 0;
  toDist :> int _;
  while (!finished){
    printf("Worker %d starting\n", wnumber); 
    //first column
    for (int y = startRow; y < endRow + 2; y += 2) {
      uint16_t chunk = 0;
      uint8_t result = 0;

      chunk |= BITGET4((*world), y,     0, WDWD + 4);
      chunk |= BITGET4((*world), y + 2, 0, WDWD + 4) << 8;

      result = hash[chunk];
      
      printf("r:%d\tc:%d\n", y, 0);
      BITSET2(buffer, result, y % (WDHT / WCOUNT), bufferPointer, BUFFERWIDTH);
    }
    bufferPointer = bufferPointer + 1 % BUFFERWIDTH;
    //the other columns
    for (int x = 2; x < WDWD + 2; x += 2) {
      for (int y = startRow; y < endRow + 2; y += 2) {
        uint16_t chunk = 0;
        uint8_t result = 0;

        chunk |= BITGET4((*world), y,     x, WDWD + 4);
        chunk |= BITGET4((*world), y + 2, x, WDWD + 4) << 8;

        result = hash[chunk];
        
        printf("r:%d\tc:%d\n", y, x);
        BITSET2(buffer, result, x % (WDHT / WCOUNT), bufferPointer, BUFFERWIDTH);
        BITSET2((*world), BITGET2(buffer, y % (WDHT / WCOUNT), bufferPointer - 1, BUFFERWIDTH), y, x, WDWD + 4);
      }
      bufferPointer = bufferPointer + 1 % BUFFERWIDTH;
    }

    for (int y = startRow; y < endRow + 2; y += 2) {
      BITSET2((*world), BITGET2(buffer, y % (WDHT / WCOUNT), bufferPointer - 1, BUFFERWIDTH), y, WDWD, WDWD + 4);
    }

    printf("Worker %d finished\n", wnumber);
    toDist :> finished; 
  }
}

#endif