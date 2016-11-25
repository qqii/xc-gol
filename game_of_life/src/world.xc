#include "world.h"

#include <stdlib.h>
#include <stdio.h>

ix_t new_ix(uint16_t r, uint16_t c) {
  ix_t ix = {r, c};
  return ix;
}

unsafe void blank_w(world_t* unsafe world, ix_t bounds) {
  world->bounds = bounds;
  world->active = 0;
  for (int r = 0; r < world->bounds.r; r++) {
    for (int c = 0; c < world->bounds.c/8; c++) {
      world->hash[world->active][r][c] = 0b00000000;
      world->hash[!world->active][r][c] = 0b00000000;
    }
  }
}

// returns the same world as test.pgm
world_t test16x16_w() {
  world_t world = {
    {16, 16},
    0,
    {
      {
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00010000, 0b00000000},
        {0b00001000, 0b00000000},
        {0b00111000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
      },
      {
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00010000, 0b00000000},
        {0b00001000, 0b00000000},
        {0b00111000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
        {0b00000000, 0b00000000},
      },
    },
  };

  return world;
}

void print_ix(ix_t ix) {
  printf("{%d, %d}", ix.r, ix.c);
}

unsafe void printworld_w(world_t* unsafe world) {
  char alive = 219;
  char dead = 176; // to 178 for other block characters

  printf("world: ");
  print_ix(world->bounds); // print_ix doesn't print a newline
  printf(" %d\n", world->active);
  for (int r = 0; r < world->bounds.r; r++) {
    for (int c = 0; c < world->bounds.c/8; c++) {
      printf("%c%c%c%c%c%c%c%c", world->hash[world->active][r][c] & 0b10000000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b01000000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00100000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00010000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00001000 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00000100 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00000010 ? alive : dead,
                                 world->hash[world->active][r][c] & 0b00000001 ? alive : dead);
    }
    printf("\n");
  }
}

// world_t hashes are packed into bits, thus we need to extract them
unsafe uint8_t isalive_w(world_t* unsafe world, ix_t ix) {
  div_t i = div(ix.c, 8);
  return (world->hash[world->active][ix.r][i.quot] & (0b10000000 >> i.rem)) >> (7 - i.rem);
}

// set the inactive hash to make sure the world is kept in sync
unsafe void setalive_w(world_t* unsafe world, ix_t ix) {
  div_t i = div(ix.c, 8);
  world->hash[!world->active][ix.r][i.quot] = world->hash[!world->active][ix.r][i.quot] | (0b10000000 >> i.rem);
}

unsafe void setdead_w(world_t* unsafe world, ix_t ix) {
  div_t i = div(ix.c, 8);
  world->hash[!world->active][ix.r][i.quot] = world->hash[!world->active][ix.r][i.quot] & ~(0b10000000 >> i.rem);
}

unsafe void set_w(world_t* unsafe world, ix_t ix, uint8_t alive) {
  if (alive) {
    setalive_w(world, ix);
  } else {
    setdead_w(world, ix);
  }
}

unsafe void flip_w(world_t* unsafe world) {
  world->active = !world->active;
}

// doesn't use pmod since new_ix only takes uint8_t thus -1 will cause errors
// instead of doing -1, we do +world->bounds.x-1 which is the same effect
// this code is pretty slow and could be sped up using some if statements to
// only perform the wrap when on the boundary
unsafe uint8_t moore_neighbours_w(world_t* unsafe world, ix_t ix) {
  uint8_t i = 0;
  i += isalive_w(world, new_ix((ix.r + world->bounds.r - 1) % world->bounds.r, (ix.c + world->bounds.c - 1) % world->bounds.c));
  i += isalive_w(world, new_ix((ix.r + world->bounds.r - 1) % world->bounds.r, ix.c));
  i += isalive_w(world, new_ix((ix.r + world->bounds.r - 1) % world->bounds.r, (ix.c + 1) % world->bounds.c));
  i += isalive_w(world, new_ix(ix.r,                                           (ix.c + world->bounds.c - 1) % world->bounds.c));
  i += isalive_w(world, new_ix(ix.r,                                           (ix.c + 1) % world->bounds.c));
  i += isalive_w(world, new_ix((ix.r + 1) % world->bounds.r,                   (ix.c + world->bounds.c - 1) % world->bounds.c));
  i += isalive_w(world, new_ix((ix.r + 1) % world->bounds.r,                   ix.c));
  i += isalive_w(world, new_ix((ix.r + 1) % world->bounds.r,                   (ix.c + 1) % world->bounds.c));
  return i;
}

// rules for game of life
unsafe uint8_t step_w(world_t* unsafe world, ix_t ix) {
  uint8_t neighbours = moore_neighbours_w(world, ix);
  uint8_t isalive    = isalive_w(world, ix);

  return neighbours == 3 || (neighbours == 2 && isalive);
}
