#ifndef _WORLD_H_
#define _WORLD_H_

#include <stdint.h>

#include "constants.h"
#include "bitmatrix.h"

typedef enum CellState {
  ALIVE,
  DEAD,
  UNCHANGED,
} state_t;

// index
typedef struct Ix {
  uint16_t r;
  uint16_t c;
} ix_t;

// cellular world
typedef struct World {
  bit buffer[BITNSLOTSM(3, IMWD)]; // buffer 0 and 1 for working, buffer 2 for top
  bit hash[BITNSLOTSM(IMHT, IMWD)];
} world_t;

// creates a new ix_t
ix_t new_ix(uint16_t r, uint16_t c);

// create a blank word_t with all dead cells and hash 0 active
world_t blank_w();

// prints an ix_t
void print_ix(ix_t ix);

// prints the active hash of the world
void printworld_w(world_t world);

// prints the world buffer
void printbuffer_w(world_t world);

// prints the code needed to set a world
void printworldcode_w(world_t world, bit onlyalive);

// checks if the active hash of the world is alive
bit isalive_w(world_t world, ix_t ix);

// sets the hash for the inactive cell to be alive
world_t setalive_w(world_t world, ix_t ix);

// sets the hash for the inactive cell to be dead
world_t setdead_w(world_t world, ix_t ix);

// calls setalive_w or setdead_w depending on the alive argument
world_t set_w(world_t world, ix_t ix, bit alive);

bit gethash_w(world_t world, ix_t ix);

world_t sethash_w(world_t world, ix_t ix, bit alive);

// returns the number of neighbours in the moore boundary of a cell in the
// active hash
uint8_t mooreneighbours_w(world_t world, ix_t ix);

// all-field sum includes the current position
uint8_t allfieldsum_w(world_t world, ix_t ix);

// returns the next iteratation of a cell in the active hash according to the
// rules of game of life
// if you wanted to change the rules, here would be the place to change it
bit step_w(world_t world, ix_t ix);

state_t stepchange_w(world_t world, ix_t ix);

// sets the cells to be equal to pattern at the position specified
world_t gardenofeden6_w(world_t world, ix_t ix);
world_t block_w(world_t world, ix_t ix);
world_t beehive_w(world_t world, ix_t ix);
world_t loaf_w(world_t world, ix_t ix);
world_t boat_w(world_t world, ix_t ix);
world_t blinker0_w(world_t world, ix_t ix);
world_t blinker1_w(world_t world, ix_t ix);
world_t toad0_w(world_t world, ix_t ix);
world_t clock_w(world_t world, ix_t ix);
world_t tumbler_w(world_t world, ix_t ix);
world_t beacon_w(world_t world, ix_t ix);
world_t pulsar_w(world_t world, ix_t ix);
world_t pentadecathlon_w(world_t world, ix_t ix);
world_t glider_w(world_t world, ix_t ix);
world_t lwss_w(world_t world, ix_t ix);
world_t rpentomino_w(world_t world, ix_t ix);
world_t diehard_w(world_t world, ix_t ix);
world_t acorn_w(world_t world, ix_t ix);
world_t glidergun_w(world_t world, ix_t ix);

#endif
