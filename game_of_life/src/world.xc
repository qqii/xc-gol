#include "world.h"

#include <stdio.h>

void printworld_w(bit world[BITSLOTSP(WDHT + 4, WDWD + 4)], uintmax_t i) {
  // characters for pretty printing the world
#ifdef _WIN32 // the superior printing
  char dead   =  32;
  char alive  = 219;
  char bdead  = 176;
  char balive = 178;

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
  char *dead   = "◻ ";
  char *alive  = "◼ ";

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

