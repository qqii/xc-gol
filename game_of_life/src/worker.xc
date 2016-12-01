#include "worker.h"

#include <stdio.h>

extern uint8_t hamming[16]; // hamming weight to calculate alive cells
extern uint8_t hash[65536]; // hash for step lookup

unsafe void worker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist, chanend toNextWorker, chanend fromLastWorker){
  // these makes sure that the worker rows are algined to multiples of 2
  uint16_t sr = (((WDHT + 2) / WCOUNT) * wnumber) & ~1;         // start row
  uint16_t er = (((WDHT + 2) / WCOUNT) * (wnumber + 1)) & ~1 ;  // end row
  // printf("Worker %d starting at %d and ending at %d\n", wnumber, sr, er);

  int finished = 0;
  // sync start work
  toDist :> int _;
  while (!finished){
    // update all cells
    for (int x = 0; x < WDWD + 2; x += 2) {
      // syncronise rows to prevent another thread writing back before lookup
      fromLastWorker :> int _;
      for (int y = sr; y < er; y += 2) {
        uint16_t chunk = 0;
        uint8_t result = 0;

        // get 4x4
        chunk |= BITGET4((*world), y,     x, WDWD + 4);
        chunk |= BITGET4((*world), y + 2, x, WDWD + 4) << 8;

        // loopup middle 2x2 result
        result = hash[chunk];

        // store it in the north east 2x2
        BITSET2((*world), result, y, x, WDWD + 4);
      }
      // sync rows from worker
      toNextWorker <: 1;
    }
    // sync with distributor
    toDist <: 1;
    toDist :> finished;
  }
}

// the last worker doesn't sync to the next worker (since there isnt any)
// this is _required_ to maintain channel limit
unsafe void lastWorker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist, chanend fromLastWorker){
  uint16_t sr =(((WDHT + 2) / WCOUNT) * wnumber) & ~1; // FIXME
  uint16_t er = WDHT + 2;
  // printf("Worker %d starting at %d and ending at %d\n", wnumber, sr, er);

  int finished = 0;
  toDist :> int _;
  while (!finished){
    for (int x = 0; x < WDWD + 2; x += 2) {
      fromLastWorker :> int _;
      for (int y = sr; y < er; y += 2) {
        uint16_t chunk = 0;
        uint8_t result = 0;

        chunk |= BITGET4((*world), y,     x, WDWD + 4);
        chunk |= BITGET4((*world), y + 2, x, WDWD + 4) << 8;

        result = hash[chunk];

        BITSET2((*world), result, y, x, WDWD + 4);
      }
      // doesn't sync to next worker, there is no next worker
    }
    toDist <: 1;
    toDist :> finished;
  }
}
