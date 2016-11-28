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
world_t blank_w();

// prints an ix_t
void print_ix(int16_t r, int16_t c);

// prints the active hash of the world
void printworld_w(world_t world);

// prints the code needed to set a world
void printworldcode_w(world_t world, bit onlyalive);

// checks if the active hash of the world is alive
// bit isalive_w(world_t world, int16_t r, int16_t c);
#define isalive_w(world, r, c) (BITTESTM((world).hash, (r) + 1, (c) + 1, WDWD + 2))

// sets the hash for the inactive cell to be alive
world_t setalive_w(world_t world, int16_t r, int16_t c);

// sets the hash for the inactive cell to be dead
world_t setdead_w(world_t world, int16_t r, int16_t c);

// calls setalive_w or setdead_w depending on the alive argument
// world_t set_w(world_t world, int16_t r, int16_t c, bit alive);
#define set_w(world, r, c, alive) if (alive) { BITSETM((world).hash, (r) + 1, (c) + 1, WDWD + 2); } else { BITCLEARM((world).hash, (r) + 1, (c) + 1, WDWD + 2); }

// returns the number of neighbours in the moore boundary of a cell in the
// active hash
// uint8_t mooreneighbours_w(world_t world, int16_t r, int16_t c);
#define mooreneighbours_w(world, r, c) (isalive_w((world), (r) - 1, (c) - 1) + isalive_w((world), (r) - 1, (c)) + isalive_w((world), (r) - 1, (c) + 1) + isalive_w((world), (r), (c) - 1) + isalive_w((world), (r), (c) + 1) + isalive_w((world), (r) + 1, (c) - 1) + isalive_w((world), (r) + 1, (c)) + isalive_w((world), (r) + 1, (c) + 1))

// returns the next iteratation of a cell in the active hash according to the
// rules of game of life
// if you wanted to change the rules, here would be the place to change it
bit step_w(world_t world, int16_t r, int16_t c);
// #define step_w(world, ix) (mooreneighbours_w((world), (ix)) == 3 || (mooreneighbours_w((world), (ix)) == 2 && isalive_w((world), (ix))))

// sets the cells to be equal to pattern at the position specified
world_t random_w(world_t world, int16_t sr, int16_t sc, int16_t er, int16_t ec, uint32_t seed);
world_t checkboard_w(world_t world, int16_t sr, int16_t sc, int16_t er, int16_t ec);
world_t gardenofeden6_w(world_t world, int16_t r, int16_t c);
world_t block_w(world_t world, int16_t r, int16_t c);
world_t beehive_w(world_t world, int16_t r, int16_t c);
world_t loaf_w(world_t world, int16_t r, int16_t c);
world_t boat_w(world_t world, int16_t r, int16_t c);
world_t blinker0_w(world_t world, int16_t r, int16_t c);
world_t blinker1_w(world_t world, int16_t r, int16_t c);
world_t toad0_w(world_t world, int16_t r, int16_t c);
world_t clock_w(world_t world, int16_t r, int16_t c);
world_t tumbler_w(world_t world, int16_t r, int16_t c);
world_t beacon_w(world_t world, int16_t r, int16_t c);
world_t pulsar_w(world_t world, int16_t r, int16_t c);
world_t pentadecathlon_w(world_t world, int16_t r, int16_t c);
world_t glider_w(world_t world, int16_t r, int16_t c);
world_t lwss_w(world_t world, int16_t r, int16_t c);
world_t rpentomino_w(world_t world, int16_t r, int16_t c);
world_t diehard_w(world_t world, int16_t r, int16_t c);
world_t acorn_w(world_t world, int16_t r, int16_t c);
world_t glidergun_w(world_t world, int16_t r, int16_t c);

#endif
