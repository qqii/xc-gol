#include "world.h"

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

void print_ix(int16_t r, int16_t c) {
  printf("{%d, %d}", r, c);
}

void printworld_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)]) {
  char alive = 219;
  char dead = 177; // to 178 for other block characters
  print_ix(WDHT, WDWD); // print_ix doesn't print a newline
  printf(" world:\n");
  for (int r = -1; r < WDHT + 1; r++) {
    for (int c = -1; c < WDWD + 1; c++) {
      printf("%c", isalive_w(hash, r, c) ? alive : dead);
    }
    printf("\n");
  }
}

void printworldcode_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], bit onlyalive) {
  uint16_t rm = ~0;
  uint16_t cm = ~0;

  for (int r = 0; r < WDHT; r++) {
    for (int c = 0; c < WDWD; c++) {
      if (isalive_w(hash, r, c)) {
        if (r < rm) {
          rm = r;
        }
        if (c < cm) {
          cm = c;
        }
      }
    }
  }
  for (int r = 0; r < WDHT; r++) {
    for (int c = 0; c < WDWD; c++) {
      if (isalive_w(hash, r, c)) {
        printf("world = setalive_w(world, %d + r, %d + c);\n", r - rm, c - cm);
      } else if (!onlyalive) {
        printf("world = setdead_w(world, %d + r, %d + c);\n", r - rm, c - cm);
      }
    }
  }
}

// // world_t hashes are packed into bits, thus we need to extract them
// bit isalive_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   return BITTESTM(hash, r + 1, c + 1, WDWD + 2);
// }

// set the inactive hash to make sure the world is kept in sync
// inline world_t setalive_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   BITSETM(hash, r + 1, c + 1, WDWD + 2);
//   return world;
// }

// inline world_t setdead_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   BITCLEARM(hash, r + 1, c + 1, WDWD + 2);
//   return world;
// }

// world_t set_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c, bit alive) {
//   if (alive) {
//     BITSETM(hash, r + 1, c + 1, WDWD + 2);
//   } else {
//     BITCLEARM(hash, r + 1, c + 1, WDWD + 2);
//   }
//   return world;
// }

// doesn't use pmod since new_ix only takes bit thus -1 will cause errors
// instead of doing -1, we do +world.bounds.x-1 which is the same effect
// this code is pretty slow and could be sped up using some if statements to
// only perform the wrap when on the boundary
// uint8_t mooreneighbours_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   bit i = 0;
//   i += isalive_w(hash, r - 1, c - 1));
//   i += isalive_w(hash, r - 1, c    ));
//   i += isalive_w(hash, r - 1, c + 1));
//   i += isalive_w(hash, r,     c - 1));
//   i += isalive_w(hash, r,     c + 1));
//   i += isalive_w(hash, r + 1, c - 1));
//   i += isalive_w(hash, r + 1, c    ));
//   i += isalive_w(hash, r + 1, c + 1));
//   return i;
// }

// rules for game of life
// bit step_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   bit neighbours = mooreneighbours_w(hash, r, c);
//
//   return neighbours == 3 || (neighbours == 2 && isalive_w(hash, r, c));
// }

// world_t random_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t sr, int16_t sc, int16_t er, int16_t ec, uint32_t seed) {
//   srand(seed);
//   for (int r = sr; r < er; r++) {
//     for (int c = sc; c < ec; c++) {
//       set_w(world, r, c, rand() > RAND_MAX / 2);
//     }
//   }
//   return world;
// }
//
// world_t checkboard_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t sr, int16_t sc, int16_t er, int16_t ec) {
//   for (int r = sr, x = 0; r < er; r++) {
//     for (int c = sc; c < ec; c++, x++) {
//       set_w(world, r, c, x % 2 == 0);
//     }
//     if ((ec - sc) % 2 == 0) {
//       x++;
//     }
//   }
//   return world;
// }
//
// world_t gardenofeden6_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 0 + r, 3 + c);
//   world = setalive_w(world, 0 + r, 4 + c);
//   world = setalive_w(world, 0 + r, 5 + c);
//   world = setalive_w(world, 0 + r, 7 + c);
//   world = setalive_w(world, 1 + r, 2 + c);
//   world = setalive_w(world, 1 + r, 4 + c);
//   world = setalive_w(world, 1 + r, 6 + c);
//   world = setalive_w(world, 1 + r, 9 + c);
//   world = setalive_w(world, 2 + r, 0 + c);
//   world = setalive_w(world, 2 + r, 2 + c);
//   world = setalive_w(world, 2 + r, 3 + c);
//   world = setalive_w(world, 2 + r, 4 + c);
//   world = setalive_w(world, 2 + r, 7 + c);
//   world = setalive_w(world, 2 + r, 8 + c);
//   world = setalive_w(world, 3 + r, 1 + c);
//   world = setalive_w(world, 3 + r, 3 + c);
//   world = setalive_w(world, 3 + r, 4 + c);
//   world = setalive_w(world, 3 + r, 5 + c);
//   world = setalive_w(world, 3 + r, 6 + c);
//   world = setalive_w(world, 3 + r, 7 + c);
//   world = setalive_w(world, 3 + r, 9 + c);
//   world = setalive_w(world, 4 + r, 0 + c);
//   world = setalive_w(world, 4 + r, 3 + c);
//   world = setalive_w(world, 4 + r, 6 + c);
//   world = setalive_w(world, 4 + r, 7 + c);
//   world = setalive_w(world, 4 + r, 8 + c);
//   world = setalive_w(world, 4 + r, 9 + c);
//   world = setalive_w(world, 5 + r, 0 + c);
//   world = setalive_w(world, 5 + r, 1 + c);
//   world = setalive_w(world, 5 + r, 2 + c);
//   world = setalive_w(world, 5 + r, 3 + c);
//   world = setalive_w(world, 5 + r, 6 + c);
//   world = setalive_w(world, 5 + r, 9 + c);
//   world = setalive_w(world, 6 + r, 0 + c);
//   world = setalive_w(world, 6 + r, 2 + c);
//   world = setalive_w(world, 6 + r, 3 + c);
//   world = setalive_w(world, 6 + r, 4 + c);
//   world = setalive_w(world, 6 + r, 5 + c);
//   world = setalive_w(world, 6 + r, 6 + c);
//   world = setalive_w(world, 6 + r, 8 + c);
//   world = setalive_w(world, 7 + r, 1 + c);
//   world = setalive_w(world, 7 + r, 2 + c);
//   world = setalive_w(world, 7 + r, 5 + c);
//   world = setalive_w(world, 7 + r, 6 + c);
//   world = setalive_w(world, 7 + r, 7 + c);
//   world = setalive_w(world, 7 + r, 9 + c);
//   world = setalive_w(world, 8 + r, 0 + c);
//   world = setalive_w(world, 8 + r, 3 + c);
//   world = setalive_w(world, 8 + r, 5 + c);
//   world = setalive_w(world, 8 + r, 7 + c);
//   world = setalive_w(world, 9 + r, 2 + c);
//   world = setalive_w(world, 9 + r, 4 + c);
//   world = setalive_w(world, 9 + r, 5 + c);
//   world = setalive_w(world, 9 + r, 6 + c);
//   world = setalive_w(world, 9 + r, 8 + c);
//
//   return world;
// }
//
// world_t block_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 0 + c);
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 1 + r, 0 + c);
//   world = setalive_w(world, 1 + r, 1 + c);
//
//   return world;
// }
//
// world_t beehive_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 0 + r, 2 + c);
//   world = setalive_w(world, 1 + r, 0 + c);
//   world = setalive_w(world, 1 + r, 3 + c);
//   world = setalive_w(world, 2 + r, 1 + c);
//   world = setalive_w(world, 2 + r, 2 + c);
//
//   return world;
// }
//
// world_t loaf_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 0 + r, 2 + c);
//   world = setalive_w(world, 1 + r, 0 + c);
//   world = setalive_w(world, 1 + r, 3 + c);
//   world = setalive_w(world, 2 + r, 1 + c);
//   world = setalive_w(world, 2 + r, 3 + c);
//   world = setalive_w(world, 3 + r, 2 + c);
//
//   return world;
// }
//
// world_t boat_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 0 + c);
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 1 + r, 0 + c);
//   world = setalive_w(world, 1 + r, 2 + c);
//   world = setalive_w(world, 2 + r, 1 + c);
//
//   return world;
// }
//
// world_t blinker0_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 0 + c);
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 0 + r, 2 + c);
//
//   return world;
// }
//
// world_t blinker1_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 0 + c);
//   world = setalive_w(world, 1 + r, 0 + c);
//   world = setalive_w(world, 2 + r, 0 + c);
//
//   return world;
// }
//
// world_t toad0_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = blinker0_w(world, 0 + r, 1 + c);
//   world = blinker0_w(world, 1 + r, 0 + c);
//
//   return world;
// }
//
// world_t clock_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 1 + r, 2 + c);
//   world = setalive_w(world, 1 + r, 3 + c);
//   world = setalive_w(world, 2 + r, 0 + c);
//   world = setalive_w(world, 2 + r, 1 + c);
//   world = setalive_w(world, 3 + r, 2 + c);
//
//   return world;
// }
//
// world_t tumbler_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 0 + r, 5 + c);
//   world = blinker1_w(world, 0 + r, 0 + c);
//   world = blinker1_w(world, 0 + r, 6 + c);
//   world = blinker1_w(world, 1 + r, 2 + c);
//   world = blinker1_w(world, 1 + r, 4 + c);
//   world = block_w(world, 4 + r, 1 + c);
//   world = block_w(world, 4 + r, 4 + c);
//
//   return world;
// }
//
// world_t beacon_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = block_w(world, 0 + r, 0 + c);
//   world = block_w(world, 2 + r, 2 + c);
//
//   return world;
// }
//
// world_t pulsar_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = blinker0_w(world, 0 + r, 2 + c);
//   world = blinker0_w(world, 0 + r, 8 + c);
//   world = blinker0_w(world, 5 + r, 2 + c);
//   world = blinker0_w(world, 5 + r, 8 + c);
//   world = blinker0_w(world, 7 + r, 2 + c);
//   world = blinker0_w(world, 7 + r, 8 + c);
//   world = blinker0_w(world, 12 + r, 2 + c);
//   world = blinker0_w(world, 12 + r, 8 + c);
//   world = blinker1_w(world, 2 + r, 0 + c);
//   world = blinker1_w(world, 2 + r, 5 + c);
//   world = blinker1_w(world, 2 + r, 7 + c);
//   world = blinker1_w(world, 2 + r, 12 + c);
//   world = blinker1_w(world, 8 + r, 0 + c);
//   world = blinker1_w(world, 8 + r, 5 + c);
//   world = blinker1_w(world, 8 + r, 7 + c);
//   world = blinker1_w(world, 8 + r, 12 + c);
//
//   return world;
// }
//
// world_t pentadecathlon_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 2 + c);
//   world = setalive_w(world, 0 + r, 7 + c);
//   world = setalive_w(world, 1 + r, 0 + c);
//   world = setalive_w(world, 1 + r, 1 + c);
//   world = setalive_w(world, 1 + r, 3 + c);
//   world = setalive_w(world, 1 + r, 4 + c);
//   world = setalive_w(world, 1 + r, 5 + c);
//   world = setalive_w(world, 1 + r, 6 + c);
//   world = setalive_w(world, 1 + r, 8 + c);
//   world = setalive_w(world, 1 + r, 9 + c);
//   world = setalive_w(world, 2 + r, 2 + c);
//   world = setalive_w(world, 2 + r, 7 + c);
//
//   return world;
// }
//
// world_t glider_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 1 + r, 2 + c);
//   world = setalive_w(world, 2 + r, 0 + c);
//   world = setalive_w(world, 2 + r, 1 + c);
//   world = setalive_w(world, 2 + r, 2 + c);
//
//   return world;
// }
//
// world_t lwss_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 0 + c);
//   world = setalive_w(world, 0 + r, 3 + c);
//   world = setalive_w(world, 2 + r, 0 + c);
//   world = blinker0_w(world, 3 + r, 1 + c);
//   world = blinker1_w(world, 1 + r, 4 + c);
//
//   return world;
// }
//
// world_t rpentomino_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 2 + c);
//   world = setalive_w(world, 1 + r, 0 + c);
//   world = blinker1_w(world, 0 + r, 1 + c);
//
//   return world;
// }
//
// world_t diehard_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 6 + c);
//   world = setalive_w(world, 1 + r, 0 + c);
//   world = setalive_w(world, 1 + r, 1 + c);
//   world = setalive_w(world, 2 + r, 1 + c);
//   world = blinker0_w(world, 2 + r, 5 + c);
//
//   return world;
// }
//
// world_t acorn_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 1 + c);
//   world = setalive_w(world, 1 + r, 3 + c);
//   world = setalive_w(world, 2 + r, 0 + c);
//   world = setalive_w(world, 2 + r, 1 + c);
//   world = blinker0_w(world, 2 + r, 4 + c);
//
//   return world;
// }
//
// world_t glidergun_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   world = setalive_w(world, 0 + r, 24 + c);
//   world = setalive_w(world, 1 + r, 22 + c);
//   world = setalive_w(world, 1 + r, 24 + c);
//   world = setalive_w(world, 2 + r, 12 + c);
//   world = setalive_w(world, 2 + r, 13 + c);
//   world = setalive_w(world, 3 + r, 11 + c);
//   world = setalive_w(world, 3 + r, 15 + c);
//   world = setalive_w(world, 5 + r, 14 + c);
//   world = setalive_w(world, 5 + r, 17 + c);
//   world = setalive_w(world, 5 + r, 22 + c);
//   world = setalive_w(world, 5 + r, 24 + c);
//   world = setalive_w(world, 6 + r, 24 + c);
//   world = setalive_w(world, 7 + r, 11 + c);
//   world = setalive_w(world, 7 + r, 15 + c);
//   world = setalive_w(world, 8 + r, 12 + c);
//   world = setalive_w(world, 8 + r, 13 + c);
//   world = block_w(world, 2 + r, 34 + c);
//   world = block_w(world, 4 + r, 0 + c);
//   world = blinker1_w(world, 2 + r, 20 + c);
//   world = blinker1_w(world, 2 + r, 21 + c);
//   world = blinker1_w(world, 4 + r, 10 + c);
//   world = blinker1_w(world, 4 + r, 16 + c);
//
//   return world;
// }
