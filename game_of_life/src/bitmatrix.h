#ifndef _BITS_H_
#define _BITS_H_

#include <stdint.h>

typedef uint8_t bit;

#define BIT_W 4
#define BIT_H 2
#define BIT_SIZE (BIT_W * BIT_H)

#define BITSLOTH(h) (((h) + BIT_H - 1) / BIT_H)
#define BITSLOTW(w) (((w) + BIT_W - 1) / BIT_W)

#define BITSLOTSP(h, w) (BITSLOTH(h) * BITSLOTW(w))
#define BITSLOTP(r, c, w) ((((r) / BIT_H) * BITSLOTW(w)) + ((c) / BIT_W))
#define BITSHIFTP(r, c, w) ((((c % BIT_W) / BIT_H) * BIT_W) + ((r % BIT_H) * BIT_H) + (c % BIT_H))
// c must be a multiple of 2
#define BITSET2(a, s, r, c, w) if ((c) % BIT_W) { (a)[BITSLOTP(r, c, w)] = (s) << BIT_W | ((a)[BITSLOTP(r, c, w)] & (BIT_SIZE - 1)); } else { (a)[BITSLOTP(r, c, w)] = (s) | ((a)[BITSLOTP(r, c, w)] & ((BIT_SIZE - 1) << BIT_W)); }
// c must be a multiple of 4
#define BITSET4(a, s, r, c, w) ((a)[BITSLOTP(r, c, w)] = (s))
#define BITSETP(a, r, c, w) ((a)[BITSLOTP(r, c, w)] |= (1 << BITSHIFTP(r, c, w)))
#define BITCLEARP(a, r, c, w) ((a)[BITSLOTP(r, c, w)] &= ~(1 << BITSHIFTP(r, c, w)))
#define BITTESTP(a, r, c, w) (((a)[BITSLOTP(r, c, w)] & (1 << BITSHIFTP(r, c, w))) != 0)
// c must be a multiple of 2
#define BITGET2(a, r, c, w) (((c) % BIT_W) ? ((a)[BITSLOTP(r, c, w)] >> BIT_W) : ((a)[BITSLOTP(r, c, w)] & (BIT_SIZE - 1)))
// c must be a multiple of 2
#define BITGET4(a, r, c, w) (((c) % BIT_W) ? (((a)[BITSLOTP(r, c, w)] >> BIT_W) | (((a)[BITSLOTP(r, c + BIT_H, w)] & (BIT_SIZE - 1)) << BIT_W)) : ((a)[BITSLOTP(r, c, w)]))

#endif
