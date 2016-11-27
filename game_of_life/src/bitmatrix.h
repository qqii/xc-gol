#ifndef _BITS_H_
#define _BITS_H_

#include <stdint.h>

typedef uint8_t bits;

#define BIT_SIZE 8
#define LOG2_BIT_SIZE 3

// #define BITMASK(b) (1 << ((b) % BIT_SIZE))
#define BITMASK(b) (1 << ((b) & (BIT_SIZE - 1)))
// using >> seems to slow it down a tiny bit
#define BITSLOT(b) ((b) / BIT_SIZE)
// #define BITSLOT(b) ((b) >> LOG2_BIT_SIZE)
#define BITSET(a, b) ((a)[BITSLOT(b)] |= BITMASK(b))
#define BITCLEAR(a, b) ((a)[BITSLOT(b)] &= ~BITMASK(b))
#define BITTEST(a, b) ((a)[BITSLOT(b)] & BITMASK(b))
#define BITNSLOTS(nb) ((nb + BIT_SIZE - 1) / BIT_SIZE)
// #define BITNSLOTS(nb) ((nb + BIT_SIZE - 1) >> LOG2_BIT_SIZE)

#define BITMASKM(r, c, h) BITMASK((r)*(h)+c)
#define BITSLOTM(r, c, h) BITSLOT((r)*(h)+c)
#define BITSETM(a, r, c, h) BITSET(a, (r)*(h)+(c))
#define BITCLEARM(a, r, c, h) BITCLEAR(a, (r)*(h)+(c))
#define BITTESTM(a, r, c, h) BITTEST(a, (r)*(h)+(c))
#define BITNSLOTSM(h, w) BITNSLOTS((w)*(h))

#endif
