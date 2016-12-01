#ifndef _BITS_H_
#define _BITS_H_

#include <stdint.h>

typedef uint8_t bit;

// let uint8_t x = 0xhgfedcba;
// the uint8_t represents the following:
// ab ef
// cd gh

#define BIT_W 4
#define BIT_H 2

// the number of bits required to pack something of height h
#define BITSLOTH(h) (((h) + BIT_H - 1) / BIT_H)
// the number of bits required to pack something of width w
#define BITSLOTW(w) (((w) + BIT_W - 1) / BIT_W)

// the number of bits required to pack a world of h, w (matrix notation rows, columns)
#define BITSLOTSP(h, w) (BITSLOTH(h) * BITSLOTW(w))
// the index in the array to lookup r, c in a world width w
#define BITSLOTP(r, c, w) ((((r) / 2) * BITSLOTW(w)) + ((c) / 4))
// with the index, the following macro returns which bit it is
#define BITSHIFTP(r, c, w) (((((c) % 4) / 2) * 4) + (((r) % 2) * 2) + ((c) % 2))

// sets r, w in world 'a' with width 'w' to 1
#define BITSETP(a, r, c, w) ((a)[BITSLOTP(r, c, w)] |= (1 << BITSHIFTP(r, c, w)))
// sets r, w in world 'a' with width 'w' to 0
#define BITCLEARP(a, r, c, w) ((a)[BITSLOTP(r, c, w)] &= ~(1 << BITSHIFTP(r, c, w)))
// returns the value at r, w in world 'a' with width 'w'
#define BITTESTP(a, r, c, w) (((a)[BITSLOTP(r, c, w)] & (1 << BITSHIFTP(r, c, w))) != 0)

// sets a 4 bit 2x2 's' at r, c in world 'a' with width 'w'
// c must be a multiple of 2
#define BITSET2(a, s, r, c, w) if ((c) % BIT_W) { (a)[BITSLOTP(r, c, w)] = (s) << BIT_W | ((a)[BITSLOTP(r, c, w)] & 0b1111); } else { (a)[BITSLOTP(r, c, w)] = (s) | ((a)[BITSLOTP(r, c, w)] & 0b11110000); }
// sets a 8 bit 2x4 's' at r, c in world 'a' with width 'w'
// c must be a multiple of 4
#define BITSET4(a, s, r, c, w) ((a)[BITSLOTP(r, c, w)] = (s))
// returns a 4 bit 2x2 at r, c in world 'a' with width 'w'
// c must be a multiple of 2
#define BITGET2(a, r, c, w) (((c) % BIT_W) ? ((a)[BITSLOTP(r, c, w)] >> BIT_W) : ((a)[BITSLOTP(r, c, w)] & 0b1111))
// returns a 8 bit 2x4 at r, c in world 'a' with width 'w'
// this will perform the correct shifts and masks if it stradles 2 uint8_ts
// c must be a multiple of 2
#define BITGET4(a, r, c, w) (((c) % BIT_W) ? (((a)[BITSLOTP(r, c, w)] >> BIT_W) | (((a)[BITSLOTP(r, c + BIT_H, w)] & 0b1111) << BIT_W)) : ((a)[BITSLOTP(r, c, w)]))

#endif
