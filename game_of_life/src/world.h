#ifndef _WORLD_H_
#define _WORLD_H_

#include <stdint.h>

#include "constants.h"
#include "bitmatrix.h"

// prints an ix_t
void print_ix(int16_t r, int16_t c);

// prints the active hash of the world
void printworld_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)]);

// prints the code needed to set a world
void printworldcode_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], bit onlyalive);

// checks if the active hash of the world is alive
// bit isalive_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
#define isalive_w(world, r, c) (BITTESTM((world), (r) + 1, (c) + 1, WDWD + 2))

// sets the hash for the inactive cell to be alive
// world_t setalive_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
#define setalive_w(world, r, c) (BITSETM((world), (r) + 1, (c) + 1, WDWD + 2))

// sets the hash for the inactive cell to be dead
// world_t setdead_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
#define setdead_w(world, r, c) (BITCLEARM((world), (r) + 1, (c) + 1, WDWD + 2))

// calls setalive_w or setdead_w depending on the alive argument
// world_t set_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c, bit alive);
#define set_w(world, r, c, alive) if (alive) { BITSETM((world), (r) + 1, (c) + 1, WDWD + 2); } else { BITCLEARM((world), (r) + 1, (c) + 1, WDWD + 2); }

// returns the number of neighbours in the moore boundary of a cell in the
// active hash
// uint8_t mooreneighbours_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
#define mooreneighbours_w(world, r, c) (isalive_w((world), (r) - 1, (c) - 1) + isalive_w((world), (r) - 1, (c)) + isalive_w((world), (r) - 1, (c) + 1) + isalive_w((world), (r), (c) - 1) + isalive_w((world), (r), (c) + 1) + isalive_w((world), (r) + 1, (c) - 1) + isalive_w((world), (r) + 1, (c)) + isalive_w((world), (r) + 1, (c) + 1))

// returns the next iteratation of a cell in the active hash according to the
// rules of game of life
// if you wanted to change the rules, here would be the place to change it
// bit step_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// #define step_w(world, ix) (mooreneighbours_w((world), (ix)) == 3 || (mooreneighbours_w((world), (ix)) == 2 && isalive_w((world), (ix))))

// // sets the cells to be equal to pattern at the position specified
// world_t random_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t sr, int16_t sc, int16_t er, int16_t ec, uint32_t seed);
// world_t checkboard_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t sr, int16_t sc, int16_t er, int16_t ec);
// world_t gardenofeden6_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t block_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t beehive_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t loaf_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t boat_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t blinker0_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t blinker1_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t toad0_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t clock_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t tumbler_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t beacon_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t pulsar_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t pentadecathlon_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t glider_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t lwss_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t rpentomino_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t diehard_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t acorn_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// world_t glidergun_w(bit hash[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);

#endif
