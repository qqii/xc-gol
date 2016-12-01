#ifndef _WORLD_H_
#define _WORLD_H_

#include "constants.h"
#include "bitmatrix.h"

// positive modulo
#define pmod(i, n) (((i) % (n) + (n)) % (n))

// prints the world
// takes the iteration number to account for dift
void printworld_w(bit world[BITSLOTSP(WDHT + 4, WDWD + 4)], uintmax_t i);

// returns the number of alive cells
unsafe uint32_t alivecount_w(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)]);

// sets the board in a checkerboard pattern
unsafe void checkboard_w(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int16_t sr, int16_t sc, int16_t er, int16_t ec);

// sets the board in a random pattern
unsafe void random_w(uint8_t (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int16_t sr, int16_t sc, int16_t er, int16_t ec, uint32_t seed);

#endif
