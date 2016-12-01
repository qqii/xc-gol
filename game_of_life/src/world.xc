#include "world.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

void print_ix(int16_t r, int16_t c) {
  printf("{%d, %d}", r, c);
}

unsafe void printworkerworld_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)]) {
  // characters for pretty printing the world
  char dead   =  32; // space
  char alive  = 219; // full block
  char bdead  = 176; // low density dotted
  char balive = 178; // high density dotted

  print_ix(WDHT, WDWD); // print_ix doesn't print a newline
  printf(" world:\n");
  for (int16_t r = -1; r < (WDHT / WORKERS) + 1; r++) {
    for (int16_t c = -1; c < WDWD + 1; c++) {
      if (r < 0 || c < 0 || r >= (WDHT / WORKERS) || c >= WDWD) {
        printf("%c", isalive_w(world, r, c) ? balive : bdead);
      } else {
        printf("%c", isalive_w(world, r, c) ? alive : dead);
      }
    }
    printf("\n");
  }
}

unsafe void printworld_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)]) {
  // characters for pretty printing the world
  char dead   =  32; // space
  char alive  = 219; // full block
  char bdead  = 176; // low density dotted
  char balive = 178; // high density dotted

  print_ix(WDHT, WDWD); // print_ix doesn't print a newline
  printf(" world:\n");
  for (int16_t r = -1; r < WDHT + 1; r++) {
    for (int16_t c = -1; c < WDWD + 1; c++) {
      if (r < 0 || c < 0 || r >= WDHT || c >= WDWD) {
        printf("%c", isalive_w(world, r, c) ? balive : bdead);
      } else {
        printf("%c", isalive_w(world, r, c) ? alive : dead);
      }
    }
    printf("\n");
  }
}

// prints a strip
unsafe void printstrip_s(strip_t (*unsafe strip)) {
  // characters for pretty printing the world
  char bdead  = 176; // low density dotted
  char balive = 178; // high density dotted

  // print_ix(0, WDWD); // print_ix doesn't print a newline
  // printf(" strip:\n");
  for (int16_t c = 0; c < WDWD; c++) {
    printf("%c", isalive_w(&(strip->line), -1, c - 1) ? balive : bdead);
  }
  printf("\n");
}

unsafe void printworldcode_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], uint8_t onlyalive) {
  uint16_t rm = ~0;
  uint16_t cm = ~0;

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

unsafe void blank_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)]) {
  memset(world, 0, BITNSLOTSM(WDHT + 2, WDWD + 2));
}

unsafe void blankworker_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)]) {
  memset(world, 0, BITNSLOTSM((WDHT / WORKERS) + 2, WDWD + 2));
}

// unsafe uint8_t isalive_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
//   return BITTESTM(*world, r + 1, c + 1, WDWD + 2);
// }

unsafe void setalive_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  BITSETM(*world, r + 1, c + 1, WDWD + 2);
}

unsafe void setdead_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  BITCLEARM(*world, r + 1, c + 1, WDWD + 2);
}

// unsafe void set_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c, uint8_t alive) {
//   if (alive) {
//     BITSETM(*world, r + 1, c + 1, WDWD + 2);
//   } else {
//     BITCLEARM(*world, r + 1, c + 1, WDWD + 2);
//   }
// }

unsafe uint16_t allbitfieldpacked_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], uint16_t r, uint16_t c) {
    uint16_t i = 0;
    i |= isalive_w(world, r - 1, c - 1) << 0;
    i |= isalive_w(world, r - 1, c    ) << 1;
    i |= isalive_w(world, r - 1, c + 1) << 2;
    i |= isalive_w(world, r,     c - 1) << 3;
    i |= isalive_w(world, r,     c    ) << 4;
    i |= isalive_w(world, r,     c + 1) << 5;
    i |= isalive_w(world, r + 1, c - 1) << 6;
    i |= isalive_w(world, r + 1, c    ) << 7;
    i |= isalive_w(world, r + 1, c + 1) << 8;
    return i;
}

unsafe void random_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t sr, int16_t sc, int16_t er, int16_t ec, uint32_t seed) {
  srand(seed);
  for (int r = sr; r < er; r++) {
    for (int c = sc; c < ec; c++) {
      set_w(world, r, c, rand() > RAND_MAX / 2);
    }
  }}

unsafe void checkboard_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t sr, int16_t sc, int16_t er, int16_t ec) {
  for (int r = sr, x = 0; r < er; r++) {
    for (int c = sc; c < ec; c++, x++) {
      set_w(world, r, c, x % 2 == 0);
    }
    if ((ec - sc) % 2 == 0) {
      x++;
    }
  }}

unsafe void gardenofeden6_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
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

unsafe void block_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 1 + c);
}

unsafe void beehive_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 0 + r, 2 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 3 + c);
  setalive_w(world, 2 + r, 1 + c);
  setalive_w(world, 2 + r, 2 + c);
}

unsafe void loaf_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 0 + r, 2 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 3 + c);
  setalive_w(world, 2 + r, 1 + c);
  setalive_w(world, 2 + r, 3 + c);
  setalive_w(world, 3 + r, 2 + c);
}

unsafe void boat_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 2 + c);
  setalive_w(world, 2 + r, 1 + c);
}

unsafe void blinker0_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 0 + r, 2 + c);
}

unsafe void blinker1_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 2 + r, 0 + c);
}

unsafe void toad0_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  blinker0_w(world, 0 + r, 1 + c);
  blinker0_w(world, 1 + r, 0 + c);
}

unsafe void clock_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 2 + c);
  setalive_w(world, 1 + r, 3 + c);
  setalive_w(world, 2 + r, 0 + c);
  setalive_w(world, 2 + r, 1 + c);
  setalive_w(world, 3 + r, 2 + c);
}

unsafe void tumbler_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 0 + r, 5 + c);
  blinker1_w(world, 0 + r, 0 + c);
  blinker1_w(world, 0 + r, 6 + c);
  blinker1_w(world, 1 + r, 2 + c);
  blinker1_w(world, 1 + r, 4 + c);
  block_w(world, 4 + r, 1 + c);
  block_w(world, 4 + r, 4 + c);
}

unsafe void beacon_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  block_w(world, 0 + r, 0 + c);
  block_w(world, 2 + r, 2 + c);
}

unsafe void pulsar_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
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

unsafe void pentadecathlon_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
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

unsafe void glider_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 2 + c);
  setalive_w(world, 2 + r, 0 + c);
  setalive_w(world, 2 + r, 1 + c);
  setalive_w(world, 2 + r, 2 + c);
}

unsafe void lwss_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 0 + c);
  setalive_w(world, 0 + r, 3 + c);
  setalive_w(world, 2 + r, 0 + c);
  blinker0_w(world, 3 + r, 1 + c);
  blinker1_w(world, 1 + r, 4 + c);
}

unsafe void rpentomino_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 2 + c);
  setalive_w(world, 1 + r, 0 + c);
  blinker1_w(world, 0 + r, 1 + c);
}

unsafe void diehard_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 6 + c);
  setalive_w(world, 1 + r, 0 + c);
  setalive_w(world, 1 + r, 1 + c);
  setalive_w(world, 2 + r, 1 + c);
  blinker0_w(world, 2 + r, 5 + c);
}

unsafe void acorn_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
  setalive_w(world, 0 + r, 1 + c);
  setalive_w(world, 1 + r, 3 + c);
  setalive_w(world, 2 + r, 0 + c);
  setalive_w(world, 2 + r, 1 + c);
  blinker0_w(world, 2 + r, 4 + c);
}

unsafe void glidergun_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c) {
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
