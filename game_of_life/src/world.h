#ifndef _WORLD_H_
#define _WORLD_H_

#include "constants.h"
#include "bitmatrix.h"

#define pmod(i, n) (((i) % (n) + (n)) % (n))

void printworld_w(bit world[BITSLOTSP(WDHT + 4, WDWD + 4)], uintmax_t i);

unsafe uint32_t alivecount_w(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)]);

#endif
