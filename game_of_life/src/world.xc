#include "world.h"

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

unsafe void blank_w(world_t* unsafe world) {
  memset(world->hash, 0, BITNSLOTSM(IMHT + 2, IMWD + 2));
}

void print_ix(int16_t r, int16_t c) {
  printf("{%d, %d}", r, c);
}

unsafe void printworld_w(world_t* unsafe world) {
  char alive = 219;
  char dead = 177; // to 178 for other block characters
  print_ix(WDHT, WDWD); // print_ix doesn't print a newline
  printf(" world:\n");
  for (int r = -1; r < WDHT + 1; r++) {
    for (int c = -1; c < WDWD + 1; c++) {
      printf("%c", isalive_w(world, r, c) ? alive : dead);
    }
    printf("\n");
  }
}

unsafe void printworldcode_w(world_t* unsafe world, bit onlyalive) {
  uint16_t rm = UINT16_MAX;
  uint16_t cm = UINT16_MAX;

  for (int r = 0; r < WDHT; r++) {
    for (int c = 0; c < WDWD; c++) {
      if (isalive_w(world, r, c)) {
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
      if (isalive_w(world, r, c)) {
        printf("setalive_w(world, %d + r, %d + c);\n", r - rm, c - cm);
      } else if (!onlyalive) {
        printf("setdead_w(world, %d + r, %d + c);\n", r - rm, c - cm);
      }
    }
  }
}

// // world_t hashes are packed into bits, thus we need to extract them
// unsafe bit isalive_w(world_t* unsafe world, int16_t r, int16_t c) {
//   return BITTESTM(world->hash, r + 1, c + 1, WDWD + 2);
// }

// set the inactive hash to make sure the world is kept in sync
unsafe void setalive_w(world_t* unsafe world, int16_t r, int16_t c) {
  BITSETM(world->hash, r + 1, c + 1, WDWD + 2);
}

unsafe void setdead_w(world_t* unsafe world, int16_t r, int16_t c) {
  BITCLEARM(world->hash, r + 1, c + 1, WDWD + 2);
}

// unsafe void set_w(world_t* unsafe world, int16_t r, int16_t c, bit alive) {
//   if (alive) {
//     BITSETM(world->hash, r + 1, c + 1, WDWD + 2);
//   } else {
//     BITCLEARM(world->hash, r + 1, c + 1, WDWD + 2);
//   }
// }

unsafe uint8_t mooreneighbours_w(world_t* unsafe world, int16_t r, int16_t c) {
  bit i = 0;
  i += isalive_w(world, r - 1, c - 1);
  i += isalive_w(world, r - 1, c    );
  i += isalive_w(world, r - 1, c + 1);
  i += isalive_w(world, r,     c - 1);
  // if (i >= 4) {
  //   return 4;
  // }
  i += isalive_w(world, r,     c + 1);
  // if (i >= 4) {
  //   return 4;
  // }
  i += isalive_w(world, r + 1, c - 1);
  // if (i >= 4) {
  //   return 4;
  // }
  i += isalive_w(world, r + 1, c    );
  // if (i >= 4) {
  //   return 4;
  // }
  i += isalive_w(world, r + 1, c + 1);
  return i;
}

// rules for game of life
unsafe bit step_w(world_t* unsafe world, int16_t r, int16_t c) {
  // int8_t dr[8] = {-1, -1, -1, +0, +0, +1, +1, +1};
  // int8_t dc[8] = {-1, +0, +1, -1, +1, +1, +0, -1};
  // uint8_t neighbours = 0;
  //
  // for (int i = 0; i < 8 && neighbours < 4; i++) {
  //   neighbours += isalive_w(world, r + dr[i], c + dc[i]);
  // }
  //
  // return neighbours == 3 || (neighbours == 2 && isalive_w(world, r, c));

  uint8_t neighbours = mooreneighbours_w(world, r, c);

  return neighbours == 3 || (neighbours == 2 && isalive_w(world, r, c));
}

unsafe void random_w(world_t* unsafe world, int16_t sr, int16_t sc, int16_t er, int16_t ec, uint32_t seed) {
  srand(seed);
  for (int r = sr; r < er; r++) {
    for (int c = sc; c < ec; c++) {
      set_w(world, r, c, rand() > RAND_MAX / 2);
    }
  }}

unsafe void checkboard_w(world_t* unsafe world, int16_t sr, int16_t sc, int16_t er, int16_t ec) {
  for (int r = sr, x = 0; r < er; r++) {
    for (int c = sc; c < ec; c++, x++) {
      set_w(world, r, c, x % 2 == 0);
    }
    if ((ec - sc) % 2 == 0) {
      x++;
    }
  }}

unsafe void gardenofeden6_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 0 + r, 3 + c);
  setalive_w(world, 0 + r, 4 + c);
  setalive_w(world, 0 + r, 5 + c);
  setalive_w(world, 0 + r, 7 + c);
  setalive_w(world, 1 + r, 2 + c);
  setalive_w(world, 1 + r, 4 + c);
  setalive_w(world, 1 + r, 6 + c);
  setalive_w(world, 1 + r, 9 + c);
  setalive_w(world, 2 + r, 0 + c);
  setalive_w(world, 2 + r, 2 + c);
  setalive_w(world, 2 + r, 3 + c);
  setalive_w(world, 2 + r, 4 + c);
  setalive_w(world, 2 + r, 7 + c);
  setalive_w(world, 2 + r, 8 + c);
  setalive_w(world, 3 + r, 1 + c);
  setalive_w(world, 3 + r, 3 + c);
  setalive_w(world, 3 + r, 4 + c);
  setalive_w(world, 3 + r, 5 + c);
  setalive_w(world, 3 + r, 6 + c);
  setalive_w(world, 3 + r, 7 + c);
  setalive_w(world, 3 + r, 9 + c);
  setalive_w(world, 4 + r, 0 + c);
  setalive_w(world, 4 + r, 3 + c);
  setalive_w(world, 4 + r, 6 + c);
  setalive_w(world, 4 + r, 7 + c);
  setalive_w(world, 4 + r, 8 + c);
  setalive_w(world, 4 + r, 9 + c);
  setalive_w(world, 5 + r, 0 + c);
  setalive_w(world, 5 + r, 1 + c);
  setalive_w(world, 5 + r, 2 + c);
  setalive_w(world, 5 + r, 3 + c);
  setalive_w(world, 5 + r, 6 + c);
  setalive_w(world, 5 + r, 9 + c);
  setalive_w(world, 6 + r, 0 + c);
  setalive_w(world, 6 + r, 2 + c);
  setalive_w(world, 6 + r, 3 + c);
  setalive_w(world, 6 + r, 4 + c);
  setalive_w(world, 6 + r, 5 + c);
  setalive_w(world, 6 + r, 6 + c);
  setalive_w(world, 6 + r, 8 + c);
  setalive_w(world, 7 + r, 1 + c);
  setalive_w(world, 7 + r, 2 + c);
  setalive_w(world, 7 + r, 5 + c);
  setalive_w(world, 7 + r, 6 + c);
  setalive_w(world, 7 + r, 7 + c);
  setalive_w(world, 7 + r, 9 + c);
  setalive_w(world, 8 + r, 0 + c);
  setalive_w(world, 8 + r, 3 + c);
  setalive_w(world, 8 + r, 5 + c);
  setalive_w(world, 8 + r, 7 + c);
  setalive_w(world, 9 + r, 2 + c);
  setalive_w(world, 9 + r, 4 + c);
  setalive_w(world, 9 + r, 5 + c);
  setalive_w(world, 9 + r, 6 + c);
  setalive_w(world, 9 + r, 8 + c);
}

unsafe void block_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 1 + c);
}

unsafe void beehive_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 0 + r, 2 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 3 + c);
  setalive_w(world, 2 + r, 1 + c);
  setalive_w(world, 2 + r, 2 + c);
}

unsafe void loaf_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 0 + r, 2 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 3 + c);
  setalive_w(world, 2 + r, 1 + c);
  setalive_w(world, 2 + r, 3 + c);
  setalive_w(world, 3 + r, 2 + c);
}

unsafe void boat_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 2 + c);
  setalive_w(world, 2 + r, 1 + c);
}

unsafe void blinker0_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 0 + r, 2 + c);
}

unsafe void blinker1_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 2 + r, 0 + c);
}

unsafe void toad0_w(world_t* unsafe world, int16_t r, int16_t c) {
  blinker0_w(world, 0 + r, 1 + c);
  blinker0_w(world, 1 + r, 0 + c);
}

unsafe void clock_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 2 + c);
  setalive_w(world, 1 + r, 3 + c);
  setalive_w(world, 2 + r, 0 + c);
  setalive_w(world, 2 + r, 1 + c);
  setalive_w(world, 3 + r, 2 + c);
}

unsafe void tumbler_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 0 + r, 5 + c);
  blinker1_w(world, 0 + r, 0 + c);
  blinker1_w(world, 0 + r, 6 + c);
  blinker1_w(world, 1 + r, 2 + c);
  blinker1_w(world, 1 + r, 4 + c);
  block_w(world, 4 + r, 1 + c);
  block_w(world, 4 + r, 4 + c);
}

unsafe void beacon_w(world_t* unsafe world, int16_t r, int16_t c) {
  block_w(world, 0 + r, 0 + c);
  block_w(world, 2 + r, 2 + c);
}

unsafe void pulsar_w(world_t* unsafe world, int16_t r, int16_t c) {
  blinker0_w(world, 0 + r, 2 + c);
  blinker0_w(world, 0 + r, 8 + c);
  blinker0_w(world, 5 + r, 2 + c);
  blinker0_w(world, 5 + r, 8 + c);
  blinker0_w(world, 7 + r, 2 + c);
  blinker0_w(world, 7 + r, 8 + c);
  blinker0_w(world, 12 + r, 2 + c);
  blinker0_w(world, 12 + r, 8 + c);
  blinker1_w(world, 2 + r, 0 + c);
  blinker1_w(world, 2 + r, 5 + c);
  blinker1_w(world, 2 + r, 7 + c);
  blinker1_w(world, 2 + r, 12 + c);
  blinker1_w(world, 8 + r, 0 + c);
  blinker1_w(world, 8 + r, 5 + c);
  blinker1_w(world, 8 + r, 7 + c);
  blinker1_w(world, 8 + r, 12 + c);
}

unsafe void pentadecathlon_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 2 + c);
  setalive_w(world, 0 + r, 7 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 1 + c);
  setalive_w(world, 1 + r, 3 + c);
  setalive_w(world, 1 + r, 4 + c);
  setalive_w(world, 1 + r, 5 + c);
  setalive_w(world, 1 + r, 6 + c);
  setalive_w(world, 1 + r, 8 + c);
  setalive_w(world, 1 + r, 9 + c);
  setalive_w(world, 2 + r, 2 + c);
  setalive_w(world, 2 + r, 7 + c);
}

unsafe void glider_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 2 + c);
  setalive_w(world, 2 + r, 0 + c);
  setalive_w(world, 2 + r, 1 + c);
  setalive_w(world, 2 + r, 2 + c);
}

unsafe void lwss_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 0 + r, 3 + c);
  setalive_w(world, 2 + r, 0 + c);
  blinker0_w(world, 3 + r, 1 + c);
  blinker1_w(world, 1 + r, 4 + c);
}

unsafe void rpentomino_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 2 + c);
  setalive_w(world, 1 + r, 0 + c);
  blinker1_w(world, 0 + r, 1 + c);
}

unsafe void diehard_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 6 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 1 + c);
  setalive_w(world, 2 + r, 1 + c);
  blinker0_w(world, 2 + r, 5 + c);
}

unsafe void acorn_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 3 + c);
  setalive_w(world, 2 + r, 0 + c);
  setalive_w(world, 2 + r, 1 + c);
  blinker0_w(world, 2 + r, 4 + c);
}

unsafe void glidergun_w(world_t* unsafe world, int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 24 + c);
  setalive_w(world, 1 + r, 22 + c);
  setalive_w(world, 1 + r, 24 + c);
  setalive_w(world, 2 + r, 12 + c);
  setalive_w(world, 2 + r, 13 + c);
  setalive_w(world, 3 + r, 11 + c);
  setalive_w(world, 3 + r, 15 + c);
  setalive_w(world, 5 + r, 14 + c);
  setalive_w(world, 5 + r, 17 + c);
  setalive_w(world, 5 + r, 22 + c);
  setalive_w(world, 5 + r, 24 + c);
  setalive_w(world, 6 + r, 24 + c);
  setalive_w(world, 7 + r, 11 + c);
  setalive_w(world, 7 + r, 15 + c);
  setalive_w(world, 8 + r, 12 + c);
  setalive_w(world, 8 + r, 13 + c);
  block_w(world, 2 + r, 34 + c);
  block_w(world, 4 + r, 0 + c);
  blinker1_w(world, 2 + r, 20 + c);
  blinker1_w(world, 2 + r, 21 + c);
  blinker1_w(world, 4 + r, 10 + c);
  blinker1_w(world, 4 + r, 16 + c);
}
