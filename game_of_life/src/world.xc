#include "world.h"

#include <stdio.h>

extern uint8_t hamming[16]; // hamming weight to calculate alive cells

void printworld_w(bit world[BITSLOTSP(WDHT + 4, WDWD + 4)], uintmax_t i) {
  // characters for pretty printing the world
#ifdef _WIN32
  // the superior printing
  char dead   =  32; // space
  char alive  = 219; // full block
  char bdead  = 176; // light shade
  char balive = 178; // medium shade

  // prints with the border wrap
  printf("{%d, %d} ", WDHT + 4, WDWD + 4);
  printf("world:\n");
  for (uint16_t r = 0; r < WDHT + 4; r++) {
    for (uint16_t c = 0; c < WDWD + 4; c++) {
      if (r < 2 || c < 2 || r >= WDHT + 2 || c >= WDWD + 2) {
        printf("%c", BITTESTP(world, pmod(r - i, WDHT), pmod(c - i, WDWD), WDWD + 4) ? balive : bdead);
      } else {
        printf("%c", BITTESTP(world, pmod(r - i, WDHT), pmod(c - i, WDWD), WDWD + 4) ? alive : dead);
      }
    }
    printf("\n");
  }
#else
  // these characters don't print well on Windows
  char *dead   = "◻ ";
  char *alive  = "◼ ";

  // prints without the border wrap
  printf("{%d, %d} ", WDHT + 4, WDWD + 4);
  printf("world:\n");
  for (uint16_t r = 2; r < WDHT + 2; r++) {
    for (uint16_t c = 2; c < WDWD + 2; c++) {
      printf("%s", BITTESTP(world, pmod(r - i, WDHT), pmod(c - i, WDWD), WDWD + 4) ? alive : dead);
    }
    printf("\n");
  }
#endif
}

// this may return incorrect results if the board width isn't a multiple of 2
// in that case it may read into the border wrap
unsafe uint32_t alivecount_w(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)]){
  uint16_t alive = 0;

  for(uint16_t c = 2; c < WDHT + 2; c += 2){
    for (uint16_t r = 2; r < WDWD + 2; r += 2){
      alive += hamming[BITGET2((*world), r, c, WDWD + 4)];
    }
  }

  return alive;
}
