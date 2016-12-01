#ifndef _WORLD_H_
#define _WORLD_H_

#include <stdint.h>

#include "constants.h"
#include "bitmatrix.h"

// prints an ix_t
void print_ix(int16_t r, int16_t c);

// prints the world
unsafe void printworld_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)]);

// prints the code needed to set a world
unsafe void printworldcode_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], uint8_t onlyalive);

unsafe void blank_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)]);

// checks a cell is alive
// unsafe uint8_t isalive_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
#define isalive_w(world, r, c) (BITTESTM(*(world), (r) + 1, (c) + 1, WDWD + 2))

// sets the cell to be alive
unsafe void setalive_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// #define setalive_w(world, r, c) (BITSETM((world), (r) + 1, (c) + 1, WDWD + 2))

// sets the cell to be dead
unsafe void setdead_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
// #define setdead_w(world, r, c) (BITCLEARM((world), (r) + 1, (c) + 1, WDWD + 2))

// calls setalive_w or setdead_w depending on the alive argument
// unsafe void set_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c, uint8_t alive);
#define set_w(world, r, c, alive) if (alive) { BITSETM(*(world), (r) + 1, (c) + 1, WDWD + 2); } else { BITCLEARM(*(world), (r) + 1, (c) + 1, WDWD + 2); }

// calculate the all bit field shiftfted into a uint16_t
unsafe uint16_t allbitfieldpacked_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], uint16_t r, uint16_t c);
// #define allbitfieldpacked_w(world, r, c) ((isalive_w(world, r - 1, c - 1) << 0) | (isalive_w(world, r - 1, c) << 1) | (isalive_w(world, r - 1, c + 1) << 2) | (isalive_w(world, r, c - 1) << 3) | (isalive_w(world, r, c) << 4) | (isalive_w(world, r, c + 1) << 5) | (isalive_w(world, r + 1, c - 1) << 6) | (isalive_w(world, r + 1, c) << 7) | (isalive_w(world, r + 1, c + 1) << 8))

// // sets the cells to be equal to pattern at the position specified
unsafe void random_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t sr, int16_t sc, int16_t er, int16_t ec, uint32_t seed);
unsafe void checkboard_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t sr, int16_t sc, int16_t er, int16_t ec);
unsafe void gardenofeden6_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void block_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void beehive_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void loaf_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void boat_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void blinker0_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void blinker1_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void toad0_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void clock_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void tumbler_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void beacon_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void pulsar_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void pentadecathlon_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void glider_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void lwss_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void rpentomino_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void diehard_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void acorn_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);
unsafe void glidergun_w(uint8_t (*unsafe world)[BITNSLOTSM(WDHT + 2, WDWD + 2)], int16_t r, int16_t c);

#endif
