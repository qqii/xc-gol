#include "world.h"

#include <stdlib.h>
#include <stdio.h>

ix_t new_ix(uint16_t r, uint16_t c) {
  ix_t ix = {r, c};
  return ix;
}

unsafe void blank_w(world_t* unsafe world) {
  world->active = 0;
  for (int r = 0; r < IMHT; r++) {
    for (int c = 0; c < IMWD/8; c++) {
      world->hash[world->active][r][c] = 0b00000000;
      world->hash[!world->active][r][c] = 0b00000000;
    }
  }
}

void print_ix(ix_t ix) {
  printf("{%d, %d}", ix.r, ix.c);
}

unsafe void printworld_w(world_t* unsafe world) {
  char alive = 219;
  char dead = 176; // to 178 for other block characters

  printf("world: ");
  print_ix(new_ix(IMHT, (IMWD/8)*8)); // print_ix doesn't print a newline
  printf(" %d\n", world->active);
  for (int r = 0; r < IMHT; r++) {
    for (int c = 0; c < IMWD/8; c++) {
      printf("%c%c%c%c%c%c%c%c", world->hash[world->active][r][c] & 0b10000000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b01000000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00100000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00010000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00001000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00000100 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00000010 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00000001 ? alive : dead);
    }
    printf("\n");
  }
}

unsafe void printworldcode_w(world_t* world, uint8_t onlyalive) {
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
  return (world->hash[world->active][ix.r][ix.c / 8] & (0b10000000 >> (ix.c % 8))) >> (7 - (ix.c % 8));
}

// set the inactive hash to make sure the world is kept in sync
unsafe void setalive_w(world_t* unsafe world, ix_t ix) {
  world->hash[!world->active][ix.r][ix.c / 8] = world->hash[!world->active][ix.r][ix.c / 8] | (0b10000000 >> (ix.c % 8));
}

unsafe void setdead_w(world_t* unsafe world, ix_t ix) {
  world->hash[!world->active][ix.r][ix.c / 8] = world->hash[!world->active][ix.r][ix.c / 8] & ~(0b10000000 >> (ix.c % 8));
}

unsafe void set_w(world_t* unsafe world, ix_t ix, uint8_t alive) {
  if (alive) {
    setalive_w(world, ix);
  } else {
    setdead_w(world, ix);
  }
}

unsafe void flip_w(world_t* unsafe world) {
  world->active = !world->active;
}

// doesn't use pmod since new_ix only takes uint8_t thus -1 will cause errors
// instead of doing -1, we do +world->bounds.x-1 which is the same effect
// this code is pretty slow and could be sped up using some if statements to
// only perform the wrap when on the boundary
unsafe uint8_t moore_neighbours_w(world_t* unsafe world, ix_t ix) {
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
unsafe uint8_t step_w(world_t* unsafe world, ix_t ix) {
  uint8_t neighbours = moore_neighbours_w(world, ix);

  return neighbours == 3 || (neighbours == 2 && isalive_w(world, ix));
}

unsafe void gardenofeden6_w(world_t* world, ix_t ix) {
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

unsafe void block_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 1 + ix.c));
}

unsafe void beehive_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));
}

unsafe void loaf_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 2 + ix.c));
}

unsafe void boat_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
}

unsafe void blinker0_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
}

unsafe void blinker1_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
}

unsafe void toad0_w(world_t* world, ix_t ix) {
  blinker0_w(world, new_ix(0 + ix.r, 1 + ix.c));
  blinker0_w(world, new_ix(1 + ix.r, 0 + ix.c));
}

unsafe void clock_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(3 + ix.r, 2 + ix.c));
}

unsafe void tumbler_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 5 + ix.c));
  blinker1_w(world, new_ix(0 + ix.r, 0 + ix.c));
  blinker1_w(world, new_ix(0 + ix.r, 6 + ix.c));
  blinker1_w(world, new_ix(1 + ix.r, 2 + ix.c));
  blinker1_w(world, new_ix(1 + ix.r, 4 + ix.c));
  block_w(world, new_ix(4 + ix.r, 1 + ix.c));
  block_w(world, new_ix(4 + ix.r, 4 + ix.c));
}

unsafe void beacon_w(world_t* world, ix_t ix) {
  block_w(world, new_ix(0 + ix.r, 0 + ix.c));
  block_w(world, new_ix(2 + ix.r, 2 + ix.c));
}

unsafe void pulsar_w(world_t* world, ix_t ix) {
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

unsafe void pentadecathlon_w(world_t* world, ix_t ix) {
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

unsafe void glider_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 2 + ix.c));
}

unsafe void lwss_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(0 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  blinker0_w(world, new_ix(3 + ix.r, 1 + ix.c));
  blinker1_w(world, new_ix(1 + ix.r, 4 + ix.c));
}

unsafe void rpentomino_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 2 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  blinker1_w(world, new_ix(0 + ix.r, 1 + ix.c));
}

unsafe void diehard_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 6 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  blinker0_w(world, new_ix(2 + ix.r, 5 + ix.c));
}

unsafe void acorn_w(world_t* world, ix_t ix) {
  setalive_w(world, new_ix(0 + ix.r, 1 + ix.c));
  setalive_w(world, new_ix(1 + ix.r, 3 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 0 + ix.c));
  setalive_w(world, new_ix(2 + ix.r, 1 + ix.c));
  blinker0_w(world, new_ix(2 + ix.r, 4 + ix.c));
}

unsafe void glidergun_w(world_t* world, ix_t ix) {
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
