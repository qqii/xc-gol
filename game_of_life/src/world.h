#ifndef _WORLD_H_
#define _WORLD_H_

#include <stdint.h>

#include "constants.h"
#include "bitmatrix.h"

#define pmod(i, n) (((i) % (n) + (n)) % (n))

void printworld_w(bit world[BITSLOTSP(WDHT + 4, WDWD + 4)], uintmax_t i);

// sets the board in a checkerboard pattern
unsafe void checkboard_w(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int16_t sr, int16_t sc, int16_t er, int16_t ec);

#endif
