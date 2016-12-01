#ifndef _WORLD_H_
#define _WORLD_H_

#include <stdint.h>

#include "constants.h"
#include "bitmatrix.h"

#define pmod(i, n) (((i) % (n) + (n)) % (n))

void printworld_w(bit world[BITSLOTSP(WDHT + 4, WDWD + 4)], uintmax_t i) {
  // characters for pretty printing the world
  char *dead;
  char *alive;
  char *bdead;
  char *balive;

#ifdef _WIN32 // the superior printing
  dead   =  32;
  alive  = 219;
  bdead  = 176;
  balive = 178;
#else
  dead   = "◻ ";
  alive  = "◼ ";
  bdead  = "◻ ";
  balive = "▦ ";
#endif

  printf("{%d, %d} ", WDHT + 4, WDWD + 4);
  printf("world:\n");
  for (uint16_t r = 0; r < WDHT + 4; r++) {
    for (uint16_t c = 0; c < WDWD + 4; c++) {
      if (r < 2 || c < 2 || r >= WDHT + 2 || c >= WDWD + 2) {
        printf("%s", BITTESTP(world, pmod(r - i, WDHT), pmod(c - i, WDWD), WDWD + 4) ? balive : bdead);
      } else {
        printf("%s", BITTESTP(world, pmod(r - i, WDHT), pmod(c - i, WDWD), WDWD + 4) ? alive : dead);
      }
    }
    printf("\n");
  }
}

#endif
