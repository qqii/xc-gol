#ifndef _WORKER_H_
#define _WORKER_H_

#include "stdio.h"
#include "constants.h"
#include "bitmatrix.h"

extern bit hamming[16]; // hamming weight to calculate alive cells
extern bit hash[65536];  // hash for lookup

#define BUFFERWIDTH 2

unsafe void worker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist, chanend toNextWorker, chanend fromLastWorker){

  uint16_t startRow =(((WDHT + 2) / WCOUNT) * wnumber) & ~1; // FIXME
  uint16_t endRow = (((WDHT + 2) / WCOUNT) * (wnumber + 1)) & ~1 ;
  uint16_t rowCount = endRow - startRow;

  printf("Worker %d starting at %d and ending at %d\n", wnumber, startRow, endRow);

  if (wnumber == WCOUNT - 1){
    endRow = WDHT;
  }

  bit buffer[BITSLOTSP((WDHT / WCOUNT) + 2, BUFFERWIDTH * 2)];
  uint8_t bufferPointer = 0;
  
  int finished = 0;
  toDist :> int _;
  while (!finished){
    //first column
    for (int y = startRow; y < endRow + 2; y += 2) {
      uint16_t chunk = 0;
      uint8_t result = 0;

      chunk |= BITGET4((*world), y,     0, WDWD + 4);
      chunk |= BITGET4((*world), y + 2, 0, WDWD + 4) << 8;

      result = hash[chunk];
      
      BITSET2(buffer, result, y % rowCount, (bufferPointer + 2) % (BUFFERWIDTH * 2), BUFFERWIDTH * 2);
    }
    bufferPointer = (bufferPointer + 2) % (BUFFERWIDTH * 2);
    //the other columns
    for (int x = 2; x < WDWD + 2; x += 2) {
      fromLastWorker :> int _;
      for (int y = startRow; y < endRow; y += 2) {
        uint16_t chunk = 0;
        uint8_t result = 0;

        chunk |= BITGET4((*world), y,     x, WDWD + 4);
        chunk |= BITGET4((*world), y + 2, x, WDWD + 4) << 8;

        result = hash[chunk];

        BITSET2(buffer, result, y % (rowCount), (bufferPointer + 2) % (BUFFERWIDTH * 2), BUFFERWIDTH * 2);
        BITSET2((*world), BITGET2(buffer, y % (rowCount), bufferPointer, BUFFERWIDTH * 2), y, x, WDWD + 4);
      }
      bufferPointer = (bufferPointer + 2) % (BUFFERWIDTH * 2);
      if (wnumber != WCOUNT - 1 ){ //FIXME
        toNextWorker <: 1;
      }
    }

    for (int y = startRow; y < endRow + 2; y += 2) {
      BITSET2((*world), BITGET2(buffer, y % (rowCount), bufferPointer - 1, BUFFERWIDTH * 2), y, WDWD, WDWD + 4);
    }
    toDist <: 1;

    toDist :> finished; 
  }
}

#endif