#ifndef _WORLD_H_
#define _WORLD_H_

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

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
uint8_t isalive_w(world_t world, ix_t ix);

// sets the hash for the inactive cell to be alive
world_t setalive_w(world_t world, ix_t ix);

// sets the hash for the inactive cell to be dead
world_t setdead_w(world_t world, ix_t ix);

// calls setalive_w or setdead_w depending on the alive argument
world_t set_w(world_t world, ix_t ix, uint8_t alive);

// flips the world hash
world_t flip_w(world_t world);

// returns the number of neighbours in the moore boundary of a cell in the
// active hash
uint8_t moore_neighbours_w(world_t world, ix_t ix);

// returns the next iteratation of a cell in the active hash according to the
// rules of game of life
// if you wanted to change the rules, here would be the place to change it
uint8_t step_w(world_t world, ix_t ix);

#endif
