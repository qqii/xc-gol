#ifndef WORLD_H_
#define WORLD_H_

#include <stdio.h>
#include <stdint.h>

#define MAX_WORLD_HEIGHT 64
#define MAX_WORLD_WIDTH 64
#define MAX_WORLD_SIZE MAX_WORLD_HEIGHT*MAX_WORLD_WIDTH

#define NULL_INDEX -1

/*
 * ix_t represents a position in a world_t
 * world_t is indexed from (0, 0) in the positive direction using the row column notation
 */
typedef struct Ix {
  uint16_t r;
  uint16_t c;
} ix_t;

/*
 * world_t is an iterable hash set implimented without pointers
 *
 */
typedef struct World {
  ix_t bounds;
  int32_t hash[MAX_WORLD_WIDTH][MAX_WORLD_HEIGHT];
  ix_t alive[2][MAX_WORLD_SIZE];
  int32_t alivesize;
  uint8_t active;
} world_t;

ix_t new_ix(uint16_t r, uint16_t c) {
  ix_t ix = {r, c};
  return ix;
}

world_t blank_w(ix_t bounds) {
  world_t world;

  world.bounds = bounds;
  for (int r = 0; r < bounds.r; r++) {
    for (int c = 0; c < bounds.c; c++) {
      world.hash[r][c] = NULL_INDEX;
    }
  }
  world.alivesize = 0;
  world.active = 0;

  return world;
}

uint8_t isalive_w(world_t world, ix_t ix) {
  return world.hash[ix.r][ix.c] == NULL_INDEX;
}

world_t tick_w(world_t world) {
  world.active = (world.active + 1) % 2;
  world.alivesize = 0;
  return world;
}

// tick then insert
// TODO: consider other way around
world_t insert_w(world_t world, ix_t ix) {
  if (isalive_w(world, ix)) {
    return world;
  } else {
    world.alive[world.active][world.alivesize] = ix;
    world.hash[ix.r][ix.c] = world.alivesize;
    world.alivesize += 1;
  }

  return world;
}

world_t remove_w(world_t world, ix_t ix) {
  world.hash[ix.r][ix.c] = NULL_INDEX;

  return world;
}

world_t flip_w(world_t world, ix_t ix) {
  if (isalive_w(world, ix)) {
    remove_w(world, ix);
  } else {
    insert_w(world, ix);
  }

  return world;
}
// partition is thread index * (alivesize / number of threads)

//HELPER PRINT FUNCTIONS
void print_ix(ix_t ix) {
  printf("{%d, %d}", ix.r, ix.c);
}

void printalive_w(world_t world) {
  for (int i = 0; i < world.alivesize; i++) {
    print_ix(world.alive[world.active][i]);
    printf("\n");
  }
}

#endif
