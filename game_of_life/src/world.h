#ifndef _WORLD_H_
#define _WORLD_H_

#include <stdint.h>

#include "constants.h"

// index
typedef struct Ix {
  uint16_t r;
  uint16_t c;
} ix_t;

// cellular world
typedef struct World {
  ix_t bounds;
  uint8_t active;
  uint8_t hash[2][IMWD][IMHT/8];
} world_t;

// creates a new ix_t
ix_t new_ix(uint16_t r, uint16_t c);

// create a blank word_t with all dead cells and hash 0 active
world_t blank_w(ix_t bounds);

world_t test16x16_w();

// prints an ix_t
void print_ix(ix_t ix);

// prints the active hash of the world
void printworld_w(world_t world);

// checks if the active hash of the world is alive
#define ISALIVE_W(world, ix) ((world.hash[world.active][ix.r][ix.c / 8] & (0b10000000 >> (ix.c % 8))) >> (7 - (ix.c % 8)))
// uint8_t isalive_w(world_t world, ix_t ix);

// sets the hash for the inactive cell to be alive
#define SETALIVE_W(world, ix) world.hash[!world.active][ix.r][ix.c / 8] = world.hash[!world.active][ix.r][ix.c / 8] | (0b10000000 >> (ix.c % 8))
// world_t setalive_w(world_t world, ix_t ix);

// sets the hash for the inactive cell to be dead
#define SETDEAD_W(world, ix) world.hash[!world.active][ix.r][ix.c / 8] = world.hash[!world.active][ix.r][ix.c / 8] & ~(0b10000000 >> (ix.c % 8))
// world_t setdead_w(world_t world, ix_t ix);

// calls setalive_w or setdead_w depending on the alive argument
#define SET_W(world, ix, alive) if (alive) { SETALIVE_W(world, ix); } else { SETDEAD_W(world, ix); }
// world_t set_w(world_t world, ix_t ix, uint8_t alive);

// flips the world hash
#define FLIP_W(world) world.active = !world.active
// world_t flip_w(world_t world);

// returns the number of neighbours in the moore boundary of a cell in the
// active hash
#define MOORE_NEIGHBOURS_W(world, ix)\
  ( \
  ISALIVE_W(world, new_ix((ix.r + world.bounds.r - 1) % world.bounds.r, (ix.c + world.bounds.c - 1) % world.bounds.c))+ \
  ISALIVE_W(world, new_ix((ix.r + world.bounds.r - 1) % world.bounds.r, ix.c))+ \
  ISALIVE_W(world, new_ix((ix.r + world.bounds.r - 1) % world.bounds.r, (ix.c + 1) % world.bounds.c))+ \
  ISALIVE_W(world, new_ix(ix.r,                                         (ix.c + world.bounds.c - 1) % world.bounds.c))+ \
  ISALIVE_W(world, new_ix(ix.r,                                         (ix.c + 1) % world.bounds.c))+ \
  ISALIVE_W(world, new_ix((ix.r + 1) % world.bounds.r,                  (ix.c + world.bounds.c - 1) % world.bounds.c))+ \
  ISALIVE_W(world, new_ix((ix.r + 1) % world.bounds.r,                  ix.c))+\
  ISALIVE_W(world, new_ix((ix.r + 1) % world.bounds.r,                  (ix.c + 1) % world.bounds.c)) \
  )
// uint8_t moore_neighbours_w(world_t world, ix_t ix);

// returns the next iteratation of a cell in the active hash according to the
// rules of game of life
// if you wanted to change the rules, here would be the place to change it
#define STEP_W(world, ix) (MOORE_NEIGHBOURS_W(world, ix) == 3 || (MOORE_NEIGHBOURS_W(world, ix) == 2 && ISALIVE_W(world, ix)))
// uint8_t step_w(world_t world, ix_t ix);

#endif
