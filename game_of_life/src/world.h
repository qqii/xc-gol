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
  uint8_t active;
  uint8_t hash[2][IMHT][IMWD/8];
} world_t;

// creates a new ix_t
ix_t new_ix(uint16_t r, uint16_t c);

// create a blank word_t with all dead cells and hash 0 active
unsafe void blank_w(world_t* unsafe world);

// prints an ix_t
void print_ix(ix_t ix);

// prints the active hash of the world
unsafe void printworld_w(world_t* unsafe world);

// prints the code needed to set a world
unsafe void printworldcode_w(world_t* world, uint8_t onlyalive);

// checks if the active hash of the world is alive
unsafe uint8_t isalive_w(world_t* unsafe world, ix_t ix);

// sets the hash for the inactive cell to be alive
unsafe void setalive_w(world_t* unsafe world, ix_t ix);

// sets the hash for the inactive cell to be dead
unsafe void setdead_w(world_t* unsafe world, ix_t ix);

// calls setalive_w or setdead_w depending on the alive argument
unsafe void set_w(world_t* unsafe world, ix_t ix, uint8_t alive);

// flips the world hash
unsafe void flip_w(world_t* unsafe world);

// returns the number of neighbours in the moore boundary of a cell in the
// active hash
unsafe uint8_t moore_neighbours_w(world_t* unsafe world, ix_t ix);

// returns the next iteratation of a cell in the active hash according to the
// rules of game of life
// if you wanted to change the rules, here would be the place to change it
unsafe uint8_t step_w(world_t* unsafe world, ix_t ix);

// sets the cells to be equal to pattern at the position specified
unsafe void gardenofeden6_w(world_t* world, ix_t ix);
unsafe void block_w(world_t* world, ix_t ix);
unsafe void beehive_w(world_t* world, ix_t ix);
unsafe void loaf_w(world_t* world, ix_t ix);
unsafe void boat_w(world_t* world, ix_t ix);
unsafe void blinker0_w(world_t* world, ix_t ix);
unsafe void blinker1_w(world_t* world, ix_t ix);
unsafe void toad0_w(world_t* world, ix_t ix);
unsafe void clock_w(world_t* world, ix_t ix);
unsafe void tumbler_w(world_t* world, ix_t ix);
unsafe void beacon_w(world_t* world, ix_t ix);
unsafe void pulsar_w(world_t* world, ix_t ix);
unsafe void pentadecathlon_w(world_t* world, ix_t ix);
unsafe void glider_w(world_t* world, ix_t ix);
unsafe void lwss_w(world_t* world, ix_t ix);
unsafe void rpentomino_w(world_t* world, ix_t ix);
unsafe void diehard_w(world_t* world, ix_t ix);
unsafe void acorn_w(world_t* world, ix_t ix);
unsafe void glidergun_w(world_t* world, ix_t ix);

#endif
