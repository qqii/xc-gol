#include "world.h"

#include <stdlib.h>
#include <stdio.h>

ix_t new_ix(uint16_t r, uint16_t c) {
  ix_t ix = {r, c};
  return ix;
}

world_t blank_w() {
  world_t world;

  world.active = 0;
  for (int i = 0; i < BITNSLOTSM(IMHT, IMWD); i++) {
    world.hash[0][i] = 0b00000000;
    world.hash[1][i] = 0b00000000;
  }

  return world;
}

void print_ix(ix_t ix) {
  printf("{%d, %d}", ix.r, ix.c);
}

void printworld_w(world_t world) {
  char alive = 219;
  char dead = 176; // to 178 for other block characters

  printf("world: ");
  print_ix(new_ix(IMHT, (IMWD/8)*8)); // print_ix doesn't print a newline
  printf(" %d\n", world.active);
  for (int r = 0; r < IMHT; r++) {
    for (int c = 0; c < IMWD; c++) {
      printf("%c", BITTESTM(world.hash[world.active], r, c, IMHT) ? alive : dead);
    }
    printf("\n");
  }
}

void printworldcode_w(world_t world, uint8_t onlyalive) {
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
uint8_t isalive_w(world_t world, ix_t ix) {
  return BITTESTM(world.hash[world.active], ix.r, ix.c, IMHT) >> ((ix.r*IMHT+ix.c) & (BIT_SIZE - 1));
}

// set the inactive hash to make sure the world is kept in sync
inline world_t setalive_w(world_t world, ix_t ix) {
  world.hash[!world.active][BITSLOTM(ix.r, ix.c, IMHT)] |= BITMASKM(ix.r, ix.c, IMHT);
  return world;
}

inline world_t setdead_w(world_t world, ix_t ix) {
  world.hash[!world.active][BITSLOTM(ix.r, ix.c, IMHT)] &= ~BITMASKM(ix.r, ix.c, IMHT);
  return world;
}

world_t set_w(world_t world, ix_t ix, uint8_t alive) {
  if (alive) {
    // return setalive_w(world, ix);
    world.hash[!world.active][BITSLOTM(ix.r, ix.c, IMHT)] |= BITMASKM(ix.r, ix.c, IMHT);
    return world;
  } else {
    // return setdead_w(world, ix);
    world.hash[!world.active][BITSLOTM(ix.r, ix.c, IMHT)] &= ~BITMASKM(ix.r, ix.c, IMHT);
    return world;
  }
}

world_t flip_w(world_t world) {
  world.active = !world.active;
  return world;
}

// doesn't use pmod since new_ix only takes uint8_t thus -1 will cause errors
// instead of doing -1, we do +world.bounds.x-1 which is the same effect
// this code is pretty slow and could be sped up using some if statements to
// only perform the wrap when on the boundary
uint8_t mooreneighbours_w(world_t world, ix_t ix) {
  uint8_t i = 0;
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
uint8_t step_w(world_t world, ix_t ix) {
  uint8_t neighbours = mooreneighbours_w(world, ix);

  return neighbours == 3 || (neighbours == 2 && isalive_w(world, ix));
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
