#ifndef _WORKER_H_
#define _WORKER_H_

#include "stdio.h"
#include "constants.h"
#include "bitmatrix.h"

extern bit hamming[16]; // hamming weight to calculate alive cells
extern bit hash[65536];  // hash for lookup

unsafe void worker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist){
  
  toDist :> uint8_t _;
  printf("Worker %d starting\n", wnumber); 

  for (int r = 0; r < WDHT + 2; r += 2) {
    for (int c = 0; c < WDWD + 2; c += 2) {
      uint16_t chunk = 0;
      uint8_t result = 0;

      chunk |= BITGET4((*world), r,     c, WDWD + 4);
      chunk |= BITGET4((*world), r + 2, c, WDWD + 4) << 8;

      result = hash[chunk];

      BITSET2((*world), result, r, c, WDWD + 4);
    }
  } 
}

#endif