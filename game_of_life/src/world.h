#ifndef _WORLD_H_
#define _WORLD_H_

#include <stdint.h>

#include "constants.h"
#include "bitmatrix.h"

// cellular world
typedef struct World {
  bit hash[BITNSLOTSM(IMHT + 2, IMWD + 2)];
} world_t;

// create a blank word_t with all dead cells and hash 0 active
unsafe void blank_w(world_t* unsafe world);

// prints an ix_t
void print_ix(int16_t r, int16_t c);

// prints the active hash of the world
unsafe void printworld_w(world_t* unsafe world);

unsafe void printworldcode_w(world_t* unsafe world, uint8_t onlyalive);

// checks if the active hash of the world is alive
// unsafe bit isalive_w(world_t* unsafe world, int16_t r, int16_t c);
#define isalive_w(world, r, c) (BITTESTM((world)->hash, (r) + 1, (c) + 1, WDWD + 2))

// sets the hash for the inactive cell to be alive
unsafe void setalive_w(world_t* unsafe world, int16_t r, int16_t c);

// sets the hash for the inactive cell to be dead
unsafe void setdead_w(world_t* unsafe world, int16_t r, int16_t c);

// calls setalive_w or setdead_w depending on the alive argument
// unsafe void set_w(world_t* unsafe world, int16_t r, int16_t c, bit alive);
#define set_w(world, r, c, alive) if (alive) { setalive_w(world, r, c); } else { setdead_w(world, r, c); }

// returns the number of neighbours in the moore boundary of a cell in the
// active hash
unsafe uint8_t mooreneighbours_w(world_t* unsafe world, int16_t r, int16_t c);

// returns the next iteratation of a cell in the active hash according to the
// rules of game of life
// if you wanted to change the rules, here would be the place to change it
unsafe bit step_w(world_t* unsafe world, int16_t r, int16_t c);

// sets the cells to be equal to pattern at the position specified
unsafe void random_w(world_t* unsafe world, int16_t sr, int16_t sc, int16_t er, int16_t ec, uint32_t seed);
unsafe void checkboard_w(world_t* unsafe world, int16_t sr, int16_t sc, int16_t er, int16_t ec);
unsafe void gardenofeden6_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void block_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void beehive_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void loaf_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void boat_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void blinker0_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void blinker1_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void toad0_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void clock_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void tumbler_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void beacon_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void pulsar_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void pentadecathlon_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void glider_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void lwss_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void rpentomino_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void diehard_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void acorn_w(world_t* unsafe world, int16_t r, int16_t c);
unsafe void glidergun_w(world_t* unsafe world, int16_t r, int16_t c);

#endif
