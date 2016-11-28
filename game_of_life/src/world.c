#include "world.h"

#include <string.h>
#include <stdio.h>

ix_t new_ix(uint16_t r, uint16_t c) {
  ix_t ix = {r, c};
  return ix;
}

world_t blank_w() {
  world_t world;

  memset(world.hash, 0, BITNSLOTSM(IMHT, IMWD));
  memset(world.buffer, 0, BITNSLOTSM(3, IMWD));

  return world;
}

void print_ix(ix_t ix) {
  printf("{%d, %d}", ix.r, ix.c);
}

void printworld_w(world_t world) {
  char alive = 219;
  char dead = 176; // to 178 for other block characters

  print_ix(new_ix(IMHT, IMWD)); // print_ix doesn't print a newline
  printf(" world:\n");
  for (int r = 0; r < IMHT; r++) {
    for (int c = 0; c < IMWD; c++) {
      printf("%c", BITTESTM(world.hash, r, c, IMWD) ? alive : dead);
    }
    printf("\n");
  }
}

void printbuffer_w(world_t world) {
  char alive = 219;
  char dead = 176; // to 178 for other block characters

  print_ix(new_ix(3, IMWD)); // print_ix doesn't print a newline
  printf(" buffer:\n");
  for (int r = 0; r < 3; r++) {
    for (int c = 0; c < IMWD; c++) {
      printf("%c", BITTESTM(world.buffer, r, c, IMWD) ? alive : dead);
    }
    printf("\n");
  }
}

void printworldcode_w(world_t world, bit onlyalive) {
  for (int r = 0; r < IMHT; r++) {
    for (int c = 0; c < IMWD; c++) {
      if (isalive_w(world, new_ix(r, c))) {
        printf("world = setalive_w(world, new_ix(%d + ix.r, %d + ix.c));\n", r, c);
      } else if (!onlyalive) {
        printf("world = setdead_w(world, new_ix(%d + ix.r, %d + ix.c));\n", r, c);
      }
    }
  }
}

// world_t hashes are packed into bits, thus we need to extract them
bit isalive_w(world_t world, ix_t ix) {
  return BITTESTM(world.hash, ix.r, ix.c, IMWD);
}

// set the inactive hash to make sure the world is kept in sync
inline world_t setalive_w(world_t world, ix_t ix) {
  BITSETM(world.hash, ix.r, ix.c, IMWD);
  return world;
}

inline world_t setdead_w(world_t world, ix_t ix) {
  BITCLEARM(world.hash, ix.r, ix.c, IMWD);
  return world;
}

world_t set_w(world_t world, ix_t ix, bit alive) {
  if (alive) {
    BITSETM(world.hash, ix.r, ix.c, IMWD);
  } else {
    BITCLEARM(world.hash, ix.r, ix.c, IMWD);
  }
  return world;
}

bit gethash_w(world_t world, ix_t ix) {
  return BITTESTM(world.buffer, ix.r, ix.c, IMWD);
}

world_t sethash_w(world_t world, ix_t ix, bit alive) {
  if (alive) {
    BITSETM(world.buffer, ix.r, ix.c, IMWD);
  } else {
    BITCLEARM(world.buffer, ix.r, ix.c, IMWD);
  }
  return world;
}

// doesn't use pmod since new_ix only takes bit thus -1 will cause errors
// instead of doing -1, we do +world.bounds.x-1 which is the same effect
// this code is pretty slow and could be sped up using some if statements to
// only perform the wrap when on the boundary
uint8_t mooreneighbours_w(world_t world, ix_t ix) {
  bit i = 0;
  i += isalive_w(world, new_ix((ix.r + IMHT - 1) % IMHT, (ix.c + IMWD - 1) % IMWD));
  i += isalive_w(world, new_ix((ix.r + IMHT - 1) % IMHT, ix.c));
  i += isalive_w(world, new_ix((ix.r + IMHT - 1) % IMHT, (ix.c + 1) % IMWD));
  i += isalive_w(world, new_ix(ix.r,                     (ix.c + IMWD - 1) % IMWD));
  i += isalive_w(world, new_ix(ix.r,                     (ix.c + 1) % IMWD));
  i += isalive_w(world, new_ix((ix.r + 1) % IMHT,        (ix.c + IMWD - 1) % IMWD));
  i += isalive_w(world, new_ix((ix.r + 1) % IMHT,        ix.c));
  i += isalive_w(world, new_ix((ix.r + 1) % IMHT,        (ix.c + 1) % IMWD));
  return i;
}

uint8_t allfieldsum_w(world_t world, ix_t ix) {
  bit i = isalive_w(world, ix);
  i += isalive_w(world, new_ix((ix.r + IMHT - 1) % IMHT, (ix.c + IMWD - 1) % IMWD));
  i += isalive_w(world, new_ix((ix.r + IMHT - 1) % IMHT, ix.c));
  i += isalive_w(world, new_ix((ix.r + IMHT - 1) % IMHT, (ix.c + 1) % IMWD));
  i += isalive_w(world, new_ix(ix.r,                     (ix.c + IMWD - 1) % IMWD));
  i += isalive_w(world, new_ix(ix.r,                     (ix.c + 1) % IMWD));
  i += isalive_w(world, new_ix((ix.r + 1) % IMHT,        (ix.c + IMWD - 1) % IMWD));
  i += isalive_w(world, new_ix((ix.r + 1) % IMHT,        ix.c));
  i += isalive_w(world, new_ix((ix.r + 1) % IMHT,        (ix.c + 1) % IMWD));
  return i;
}

// rules for game of life
bit step_w(world_t world, ix_t ix) {
  bit neighbours = mooreneighbours_w(world, ix);

  return neighbours == 3 || (neighbours == 2 && isalive_w(world, ix));
}

// this can be easily optimised by partially calculating the allfieldsum
state_t stepchange_w(world_t world, ix_t ix) {
  switch (allfieldsum_w(world, ix)) {
    case 3:
      return ALIVE;
    case 4:
      return UNCHANGED;
    default:
      return DEAD;
  }
}

world_t gardenofeden6_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 4 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 5 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 7 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 4 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 6 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 9 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 4 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 7 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 8 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 4 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 5 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 6 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 7 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 9 + ix.c));
  world = setalive_w(world, new_ix(4 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(4 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(4 + ix.r, 6 + ix.c));
  world = setalive_w(world, new_ix(4 + ix.r, 7 + ix.c));
  world = setalive_w(world, new_ix(4 + ix.r, 8 + ix.c));
  world = setalive_w(world, new_ix(4 + ix.r, 9 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 6 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 9 + ix.c));
  world = setalive_w(world, new_ix(6 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(6 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(6 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(6 + ix.r, 4 + ix.c));
  world = setalive_w(world, new_ix(6 + ix.r, 5 + ix.c));
  world = setalive_w(world, new_ix(6 + ix.r, 6 + ix.c));
  world = setalive_w(world, new_ix(6 + ix.r, 8 + ix.c));
  world = setalive_w(world, new_ix(7 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(7 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(7 + ix.r, 5 + ix.c));
  world = setalive_w(world, new_ix(7 + ix.r, 6 + ix.c));
  world = setalive_w(world, new_ix(7 + ix.r, 7 + ix.c));
  world = setalive_w(world, new_ix(7 + ix.r, 9 + ix.c));
  world = setalive_w(world, new_ix(8 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(8 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(8 + ix.r, 5 + ix.c));
  world = setalive_w(world, new_ix(8 + ix.r, 7 + ix.c));
  world = setalive_w(world, new_ix(9 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(9 + ix.r, 4 + ix.c));
  world = setalive_w(world, new_ix(9 + ix.r, 5 + ix.c));
  world = setalive_w(world, new_ix(9 + ix.r, 6 + ix.c));
  world = setalive_w(world, new_ix(9 + ix.r, 8 + ix.c));

  return world;
}

world_t block_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 1 + ix.c));

  return world;
}

world_t beehive_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));

  return world;
}

world_t loaf_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 2 + ix.c));

  return world;
}

world_t boat_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));

  return world;
}

world_t blinker0_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));

  return world;
}

world_t blinker1_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));

  return world;
}

world_t toad0_w(world_t world, ix_t ix) {
  world = blinker0_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = blinker0_w(world, new_ix(1 + ix.r, 0 + ix.c));

  return world;
}

world_t clock_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 2 + ix.c));

  return world;
}

world_t tumbler_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 5 + ix.c));
  world = blinker1_w(world, new_ix(0 + ix.r, 0 + ix.c));
  world = blinker1_w(world, new_ix(0 + ix.r, 6 + ix.c));
  world = blinker1_w(world, new_ix(1 + ix.r, 2 + ix.c));
  world = blinker1_w(world, new_ix(1 + ix.r, 4 + ix.c));
  world = block_w(world, new_ix(4 + ix.r, 1 + ix.c));
  world = block_w(world, new_ix(4 + ix.r, 4 + ix.c));

  return world;
}

world_t beacon_w(world_t world, ix_t ix) {
  world = block_w(world, new_ix(0 + ix.r, 0 + ix.c));
  world = block_w(world, new_ix(2 + ix.r, 2 + ix.c));

  return world;
}

world_t pulsar_w(world_t world, ix_t ix) {
  world = blinker0_w(world, new_ix(0 + ix.r, 2 + ix.c));
  world = blinker0_w(world, new_ix(0 + ix.r, 8 + ix.c));
  world = blinker0_w(world, new_ix(5 + ix.r, 2 + ix.c));
  world = blinker0_w(world, new_ix(5 + ix.r, 8 + ix.c));
  world = blinker0_w(world, new_ix(7 + ix.r, 2 + ix.c));
  world = blinker0_w(world, new_ix(7 + ix.r, 8 + ix.c));
  world = blinker0_w(world, new_ix(12 + ix.r, 2 + ix.c));
  world = blinker0_w(world, new_ix(12 + ix.r, 8 + ix.c));
  world = blinker1_w(world, new_ix(2 + ix.r, 0 + ix.c));
  world = blinker1_w(world, new_ix(2 + ix.r, 5 + ix.c));
  world = blinker1_w(world, new_ix(2 + ix.r, 7 + ix.c));
  world = blinker1_w(world, new_ix(2 + ix.r, 12 + ix.c));
  world = blinker1_w(world, new_ix(8 + ix.r, 0 + ix.c));
  world = blinker1_w(world, new_ix(8 + ix.r, 5 + ix.c));
  world = blinker1_w(world, new_ix(8 + ix.r, 7 + ix.c));
  world = blinker1_w(world, new_ix(8 + ix.r, 12 + ix.c));

  return world;
}

world_t pentadecathlon_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 7 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 4 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 5 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 6 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 8 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 9 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 7 + ix.c));

  return world;
}

world_t glider_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));

  return world;
}

world_t lwss_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(0 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  world = blinker0_w(world, new_ix(3 + ix.r, 1 + ix.c));
  world = blinker1_w(world, new_ix(1 + ix.r, 4 + ix.c));

  return world;
}

world_t rpentomino_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  world = blinker1_w(world, new_ix(0 + ix.r, 1 + ix.c));

  return world;
}

world_t diehard_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 6 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  world = blinker0_w(world, new_ix(2 + ix.r, 5 + ix.c));

  return world;
}

world_t acorn_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  world = blinker0_w(world, new_ix(2 + ix.r, 4 + ix.c));

  return world;
}

world_t glidergun_w(world_t world, ix_t ix) {
  world = setalive_w(world, new_ix(0 + ix.r, 24 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 22 + ix.c));
  world = setalive_w(world, new_ix(1 + ix.r, 24 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 12 + ix.c));
  world = setalive_w(world, new_ix(2 + ix.r, 13 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 11 + ix.c));
  world = setalive_w(world, new_ix(3 + ix.r, 15 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 14 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 17 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 22 + ix.c));
  world = setalive_w(world, new_ix(5 + ix.r, 24 + ix.c));
  world = setalive_w(world, new_ix(6 + ix.r, 24 + ix.c));
  world = setalive_w(world, new_ix(7 + ix.r, 11 + ix.c));
  world = setalive_w(world, new_ix(7 + ix.r, 15 + ix.c));
  world = setalive_w(world, new_ix(8 + ix.r, 12 + ix.c));
  world = setalive_w(world, new_ix(8 + ix.r, 13 + ix.c));
  world = block_w(world, new_ix(2 + ix.r, 34 + ix.c));
  world = block_w(world, new_ix(4 + ix.r, 0 + ix.c));
  world = blinker1_w(world, new_ix(2 + ix.r, 20 + ix.c));
  world = blinker1_w(world, new_ix(2 + ix.r, 21 + ix.c));
  world = blinker1_w(world, new_ix(4 + ix.r, 10 + ix.c));
  world = blinker1_w(world, new_ix(4 + ix.r, 16 + ix.c));

  return world;
}
