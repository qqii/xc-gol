#ifndef WORLD_H_
#define WORLD_H_

#include <stdbool.h>
#include <stdint.h>

#define MAX_WORLD_HEIGHT 1024
#define MAX_WORLD_WIDTH 1024
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
  ix_t alive0[MAX_WORLD_SIZE];
  ix_t alive1[MAX_WORLD_SIZE];
  int32_t alivesize;
  bool alive0active;
} world_t;

world_t blankWorld(ix_t bounds) {
  world_t world;

  world.bounds = bounds;
  for (int r = 0; r < bounds.r; r++) {
    for (int c = 0; c < bounds.c; c++) {
      world.hash[r][c] = NULL_INDEX;
    }
  }
  world.alivesize = 0;
  world.alive0active = true;
}

bool isAlive(world_t world, ix_t ix) {
  return hash[ix.r][ix.c] == NULL_INDEX;
}

world_t tick(world_t world) {
  world.alive0active = !world.alive0active;
  alivesize = 0;
  return world;
}

// tick then insert
// TODO: consider other way around
world_t insert(world_t world, ix_t ix) {
  if (isAlive(world, ix)) {
    return world;
  } else {
    if (alive0active) {
      alive0[alivesize] = ix;
    } else {
      alive1[alivesize] = ix;
    }
    world.hash[ix.r][ix.c] = alivesize;
    alivesize += 1;
  }
}

world_t remove(world_t world, ix_t ix) {
  world.hash[ix.r][ix.c] = NULL_INDEX;
  return world;
}

world_t flip(world_t world, ix_t ix) {
  if (isAlive(world, ix)) {
    remove(world, ix);
  } else {
    insert(world, ix);
  }
}
// partition is thread index * (alivesize / number of threads)

#endif
