#include "world.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

ix_t new_ix(uint16_t r, uint16_t c) {
  ix_t ix = {r, c};
  return ix;
}

unsafe void blank_w(world_t* unsafe world) {
  memset(world->hash, 0, BITNSLOTSM(IMHT + 2, IMWD + 2));
}

void print_ix(ix_t ix) {
  printf("{%d, %d}", ix.r, ix.c);
}

unsafe void printworld_w(world_t* unsafe world) {
  char alive = 219;
  char dead = 176; // to 178 for other block characters

  print_ix(new_ix(IMHT, IMWD)); // print_ix doesn't print a newline
  printf(" world:\n");
  for (int r = -1; r < IMHT + 1; r++) {
    for (int c = -1; c < IMWD + 1; c++) {
      printf("%c", isalive_w(world, new_ix(r, c)) ? alive : dead);
    }
    printf("\n");
  }
}

unsafe void printworldcode_w(world_t* unsafe world, uint8_t onlyalive) {
  for (int r = 0; r < IMHT; r++) {
    for (int c = 0; c < IMWD; c++) {
      if (isalive_w(world, new_ix(r, c))) {
        printf("setalive_w(world, new_ix(%d + ix.r, %d + ix.c));\n", r, c);
      } else if (!onlyalive) {
        printf("setdead_w(world, new_ix(%d + ix.r, %d + ix.c));\n", r, c);
      }
    }
  }
}

// world_t hashes are packed into bits, thus we need to extract them
unsafe uint8_t isalive_w(world_t* unsafe world, ix_t ix) {
  return BITTESTM(world->hash, ix.r + 1, ix.c + 1, IMWD + 2);
}

// set the inactive hash to make sure the world is kept in sync
unsafe void setalive_w(world_t* unsafe world, ix_t ix) {
  BITSETM(world->hash, ix.r + 1, ix.c + 1, IMWD + 2);
}

unsafe void setdead_w(world_t* unsafe world, ix_t ix) {
  BITCLEARM(world->hash, ix.r + 1, ix.c + 1, IMWD + 2);
}

unsafe void set_w(world_t* unsafe world, ix_t ix, uint8_t alive) {
  if (alive) {
    BITSETM(world->hash, ix.r + 1, ix.c + 1, IMWD + 2);
  } else {
    BITCLEARM(world->hash, ix.r + 1, ix.c + 1, IMWD + 2);
  }
}

// doesn't use pmod since new_ix only takes uint8_t thus -1 will cause errors
// instead of doing -1, we do +world->bounds.x-1 which is the same effect
// this code is pretty slow and could be sped up using some if statements to
// only perform the wrap when on the boundary
unsafe uint8_t mooreneighbours_w(world_t* unsafe world, ix_t ix) {
  uint8_t i = 0;
  i += isalive_w(world, new_ix(ix.r - 1, ix.c - 1));
  i += isalive_w(world, new_ix(ix.r - 1, ix.c    ));
  i += isalive_w(world, new_ix(ix.r - 1, ix.c + 1));
  i += isalive_w(world, new_ix(ix.r,     ix.c - 1));
  i += isalive_w(world, new_ix(ix.r,     ix.c + 1));
  i += isalive_w(world, new_ix(ix.r + 1, ix.c - 1));
  i += isalive_w(world, new_ix(ix.r + 1, ix.c    ));
  i += isalive_w(world, new_ix(ix.r + 1, ix.c + 1));
  return i;
}

unsafe uint8_t allfieldsum_w(world_t* unsafe world, ix_t ix) {
  uint8_t i = isalive_w(world, ix);
  i += isalive_w(world, new_ix(ix.r - 1, ix.c - 1));
  i += isalive_w(world, new_ix(ix.r - 1, ix.c    ));
  i += isalive_w(world, new_ix(ix.r - 1, ix.c + 1));
  i += isalive_w(world, new_ix(ix.r,     ix.c - 1));
  i += isalive_w(world, new_ix(ix.r,     ix.c + 1));
  i += isalive_w(world, new_ix(ix.r + 1, ix.c - 1));
  i += isalive_w(world, new_ix(ix.r + 1, ix.c    ));
  i += isalive_w(world, new_ix(ix.r + 1, ix.c + 1));
  return i;
}

// rules for game of life
unsafe uint8_t step_w(world_t* unsafe world, ix_t ix) {
  uint8_t neighbours = mooreneighbours_w(world, ix);

  return neighbours == 3 || (neighbours == 2 && isalive_w(world, ix));
}

// this can be easily optimised by partially calculating the allfieldsum
unsafe state_t stepchange_w(world_t* unsafe world, ix_t ix) {
  switch (allfieldsum_w(world, ix)) {
    case 3:
      return ALIVE;
    case 4:
      return UNCHANGED;
    default:
      return DEAD;
  }
}

unsafe void checkboard_w(world_t* unsafe world, ix_t start, ix_t end) {
  printf("end.c - start.c: %d\n", end.c - start.c);
  for (int r = start.r, x = 0; r < end.r; r++) {
    for (int c = start.c; c < end.c; c++, x++) {
      if (x % 2 == 0) {
        set_w(world, new_ix(r, c), 1);
      } else {
        set_w(world, new_ix(r, c), 0);
      }
    }
    if ((end.c - start.c) % 2 == 0) {
      x++;
    }
  }
}

unsafe void gardenofeden6_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 4 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 5 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 7 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 4 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 9 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 4 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 7 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 8 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 4 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 5 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 7 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 9 + ix.c));
  setalive_w(world, new_ix(4 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(4 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(4 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(4 + ix.r, 7 + ix.c));
  setalive_w(world, new_ix(4 + ix.r, 8 + ix.c));
  setalive_w(world, new_ix(4 + ix.r, 9 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 9 + ix.c));
  setalive_w(world, new_ix(6 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(6 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(6 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(6 + ix.r, 4 + ix.c));
  setalive_w(world, new_ix(6 + ix.r, 5 + ix.c));
  setalive_w(world, new_ix(6 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(6 + ix.r, 8 + ix.c));
  setalive_w(world, new_ix(7 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(7 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(7 + ix.r, 5 + ix.c));
  setalive_w(world, new_ix(7 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(7 + ix.r, 7 + ix.c));
  setalive_w(world, new_ix(7 + ix.r, 9 + ix.c));
  setalive_w(world, new_ix(8 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(8 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(8 + ix.r, 5 + ix.c));
  setalive_w(world, new_ix(8 + ix.r, 7 + ix.c));
  setalive_w(world, new_ix(9 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(9 + ix.r, 4 + ix.c));
  setalive_w(world, new_ix(9 + ix.r, 5 + ix.c));
  setalive_w(world, new_ix(9 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(9 + ix.r, 8 + ix.c));
}

unsafe void block_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 1 + ix.c));
}

unsafe void beehive_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));
}

unsafe void loaf_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 2 + ix.c));
}

unsafe void boat_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
}

unsafe void blinker0_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
}

unsafe void blinker1_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
}

unsafe void toad0_w(world_t* unsafe world, ix_t ix) {
  blinker0_w(world, new_ix(0 + ix.r, 1 + ix.c));
  blinker0_w(world, new_ix(1 + ix.r, 0 + ix.c));
}

unsafe void clock_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 2 + ix.c));
}

unsafe void tumbler_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 5 + ix.c));
  blinker1_w(world, new_ix(0 + ix.r, 0 + ix.c));
  blinker1_w(world, new_ix(0 + ix.r, 6 + ix.c));
  blinker1_w(world, new_ix(1 + ix.r, 2 + ix.c));
  blinker1_w(world, new_ix(1 + ix.r, 4 + ix.c));
  block_w(world, new_ix(4 + ix.r, 1 + ix.c));
  block_w(world, new_ix(4 + ix.r, 4 + ix.c));
}

unsafe void beacon_w(world_t* unsafe world, ix_t ix) {
  block_w(world, new_ix(0 + ix.r, 0 + ix.c));
  block_w(world, new_ix(2 + ix.r, 2 + ix.c));
}

unsafe void pulsar_w(world_t* unsafe world, ix_t ix) {
  blinker0_w(world, new_ix(0 + ix.r, 2 + ix.c));
  blinker0_w(world, new_ix(0 + ix.r, 8 + ix.c));
  blinker0_w(world, new_ix(5 + ix.r, 2 + ix.c));
  blinker0_w(world, new_ix(5 + ix.r, 8 + ix.c));
  blinker0_w(world, new_ix(7 + ix.r, 2 + ix.c));
  blinker0_w(world, new_ix(7 + ix.r, 8 + ix.c));
  blinker0_w(world, new_ix(12 + ix.r, 2 + ix.c));
  blinker0_w(world, new_ix(12 + ix.r, 8 + ix.c));
  blinker1_w(world, new_ix(2 + ix.r, 0 + ix.c));
  blinker1_w(world, new_ix(2 + ix.r, 5 + ix.c));
  blinker1_w(world, new_ix(2 + ix.r, 7 + ix.c));
  blinker1_w(world, new_ix(2 + ix.r, 12 + ix.c));
  blinker1_w(world, new_ix(8 + ix.r, 0 + ix.c));
  blinker1_w(world, new_ix(8 + ix.r, 5 + ix.c));
  blinker1_w(world, new_ix(8 + ix.r, 7 + ix.c));
  blinker1_w(world, new_ix(8 + ix.r, 12 + ix.c));
}

unsafe void pentadecathlon_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 7 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 4 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 5 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 8 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 9 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 7 + ix.c));
}

unsafe void glider_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));
}

unsafe void lwss_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  blinker0_w(world, new_ix(3 + ix.r, 1 + ix.c));
  blinker1_w(world, new_ix(1 + ix.r, 4 + ix.c));
}

unsafe void rpentomino_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  blinker1_w(world, new_ix(0 + ix.r, 1 + ix.c));
}

unsafe void diehard_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  blinker0_w(world, new_ix(2 + ix.r, 5 + ix.c));
}

unsafe void acorn_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  blinker0_w(world, new_ix(2 + ix.r, 4 + ix.c));
}

unsafe void glidergun_w(world_t* unsafe world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 24 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 22 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 24 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 12 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 13 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 11 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 15 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 14 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 17 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 22 + ix.c));
  setalive_w(world, new_ix(5 + ix.r, 24 + ix.c));
  setalive_w(world, new_ix(6 + ix.r, 24 + ix.c));
  setalive_w(world, new_ix(7 + ix.r, 11 + ix.c));
  setalive_w(world, new_ix(7 + ix.r, 15 + ix.c));
  setalive_w(world, new_ix(8 + ix.r, 12 + ix.c));
  setalive_w(world, new_ix(8 + ix.r, 13 + ix.c));
  block_w(world, new_ix(2 + ix.r, 34 + ix.c));
  block_w(world, new_ix(4 + ix.r, 0 + ix.c));
  blinker1_w(world, new_ix(2 + ix.r, 20 + ix.c));
  blinker1_w(world, new_ix(2 + ix.r, 21 + ix.c));
  blinker1_w(world, new_ix(4 + ix.r, 10 + ix.c));
  blinker1_w(world, new_ix(4 + ix.r, 16 + ix.c));
}
