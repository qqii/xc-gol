#ifndef _BITS_H_
#define _BITS_H_

#include <stdint.h>

typedef uint8_t bit;

#define BIT_SIZE 8
#define LOG2_BIT_SIZE 3

#define BITMASK(b) (1 << ((b) % BIT_SIZE))
// #define BITMASK(b) (1 << ((b) & (BIT_SIZE - 1)))
// using >> seems to slow it down a tiny bit
#define BITSLOT(b) ((b) / BIT_SIZE)
// #define BITSLOT(b) ((b) >> LOG2_BIT_SIZE)
#define BITSET(a, b) ((a)[BITSLOT(b)] |= BITMASK(b))
#define BITCLEAR(a, b) ((a)[BITSLOT(b)] &= ~BITMASK(b))
#define BITTEST(a, b) (((a)[BITSLOT(b)] & BITMASK(b)) != 0)
// #define BITTEST(a, b) (((a)[BITSLOT(b)] & BITMASK(b)) >> ((b) % BIT_SIZE))
// #define BITTEST(a, b) (((a)[BITSLOT(b)] & BITMASK(b)) >> ((b) & (BIT_SIZE - 1)))
#define BITNSLOTS(nb) ((nb + BIT_SIZE - 1) / BIT_SIZE)
// #define BITNSLOTS(nb) ((nb + BIT_SIZE - 1) >> LOG2_BIT_SIZE)

#define BITMASKM(r, c, w) BITMASK((r)*(w)+(c))
#define BITSLOTM(r, c, w) BITSLOT((r)*(w)+(c))
#define BITSETM(a, r, c, w) BITSET(a, (r)*(w)+(c))
#define BITCLEARM(a, r, c, w) BITCLEAR(a, (r)*(w)+(c))
#define BITTESTM(a, r, c, w) BITTEST(a, (r)*(w)+(c))
#define BITNSLOTSM(h, w) BITNSLOTS((h)*(w))

#endif
