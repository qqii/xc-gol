#ifndef _WORLD_H_
#define _WORLD_H_

#include <stdint.h>

#include "constants.h"
#include "bitmatrix.h"

void printworld_w(bit world[BITSLOTSP(WDHT + 4, WDWD + 4)]) {
  // characters for pretty printing the world
  char dead   =  32; // space
  char alive  = 219; // full block
  char bdead  = 176; // low density dotted
  char balive = 178; // high density dotted

  // for (int i = 0; i < BITSLOTSP(WDHT + 4, WDWD + 4); i++) {
  //   printf("%d%d%d%d %d%d%d%d\n", (world[i] & 0b00000001) != 0,
  //                                 (world[i] & 0b00000010) != 0,
  //                                 (world[i] & 0b00000100) != 0,
  //                                 (world[i] & 0b00001000) != 0,
  //                                 (world[i] & 0b00010000) != 0,
  //                                 (world[i] & 0b00100000) != 0,
  //                                 (world[i] & 0b01000000) != 0,
  //                                 (world[i] & 0b10000000) != 0);
  // }
  printf("{%d, %d} ", WDHT + 4, WDWD + 4);
  printf("world:\n");
  for (uint16_t r = 0; r < WDHT + 4; r++) {
    for (uint16_t c = 0; c < WDWD + 4; c++) {
      if (r < 2 || c < 2 || r >= WDHT + 2 || c >= WDWD + 2) {
        printf("%c", BITTESTP(world, r, c, WDWD + 4) ? balive : bdead);
        // printf("%c", BITTESTP(world, r, c, WDWD + 4) ? balive : bdead);
      } else {
        printf("%c", BITTESTP(world, r, c, WDWD + 4) ? alive : dead);
        // printf("%c", BITTESTP(world, r, c, WDWD + 4) ? alive : dead);
      }
    }
    printf("\n");
  }
}

#endif
