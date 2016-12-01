#ifndef _WORKER_H_
#define _WORKER_H_

#include "stdio.h"
#include "constants.h"
#include "bitmatrix.h"

extern bit hamming[16]; // hamming weight to calculate alive cells
extern bit hash[65536];  // hash for lookup

unsafe void worker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist, chanend toNextWorker, chanend fromLastWorker){

  uint16_t startRow =(((WDHT + 2) / WCOUNT) * wnumber) & ~1; // FIXME
  uint16_t endRow = (((WDHT + 2) / WCOUNT) * (wnumber + 1)) & ~1 ;
  if (wnumber == WCOUNT - 1) {
    endRow = WDHT;
  }
  // printf("Worker %d starting at %d and ending at %d\n", wnumber, startRow, endRow);

  int finished = 0;
  toDist :> int _;
  while (!finished){
    for (int x = 0; x < WDWD + 2; x += 2) {
      fromLastWorker :> int _;
      for (int y = startRow; y < endRow; y += 2) {
        uint16_t chunk = 0;
        uint8_t result = 0;

        chunk |= BITGET4((*world), y,     x, WDWD + 4);
        chunk |= BITGET4((*world), y + 2, x, WDWD + 4) << 8;

        result = hash[chunk];

        BITSET2((*world), result, y, x, WDWD + 4);
      }
      if (wnumber != WCOUNT - 1 ){ //FIXME
        toNextWorker <: 1;
      }
    }
    toDist <: 1;

    toDist :> finished;
  }
}

#endif
