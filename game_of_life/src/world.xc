#include "world.h"

#include <stdio.h>
#include <stdlib.h>

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
  for (int16_t r = 0; r < WDHT + 4; r++) {
    for (int16_t c = 0; c < WDWD + 4; c++) {
      int sr = pmod((r - i), WDHT + 4);
      int sc = pmod((c - i), WDWD + 4);
      if (r < 2 || c < 2 || r >= WDHT + 2 || c >= WDWD + 2) {
        printf("%c", BITTESTP(world, sr, sc, WDWD + 4) ? balive : bdead);
      } else {
        printf("%c", BITTESTP(world, sr, sc, WDWD + 4) ? alive : dead);
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
      int sr = pmod((r - i), WDHT + 4);
      int sc = pmod((c - i), WDWD + 4);
      printf("%s", BITTESTP(world, sr, sc, WDWD + 4) ? alive : dead);
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

unsafe void checkboard_w(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int16_t sr, int16_t sc, int16_t er, int16_t ec) {
  for (int r = sr, x = 0; r < er; r++) {
    for (int c = sc; c < ec; c++, x++) {
      if (x % 2 == 0) {
        BITSETP(*world, r, c, WDWD);
      } else {
        BITCLEARP(*world, r, c, WDWD);
      }
    }
    if ((ec - sc) % 2 == 0) {
      x++;
    }
  }
}

unsafe void random_w(uint8_t (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int16_t sr, int16_t sc, int16_t er, int16_t ec, uint32_t seed){
  srand(seed);
  for (int r = sr; r < er; r++) {
    for (int c = sc; c < ec; c++) {
      if (rand() < RAND_MAX / 2) {
        BITSETP(*world, r, c, WDWD);
      } else {
        BITCLEARP(*world, r, c, WDWD);
      }
    }
  }
}
