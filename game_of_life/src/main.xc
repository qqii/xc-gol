// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <platform.h>
// #include <xs1.h>
#include "worker.h"
#include "io.h"

bit hamming[16]; // hamming weight to calculate alive cells
bit hash[65536]; // hash for lookup

// interface ports to orientation
on tile[0]: port p_scl = XS1_PORT_1E;
on tile[0]: port p_sda = XS1_PORT_1F;
// both of these must be on tile 0
on tile[0]: in   port p_buttons = XS1_PORT_4E; // port to access xCore-200 buttons
on tile[0]: out  port p_leds    = XS1_PORT_4F; // port to access xCore-200 LEDs

// main thread to perform precomputation and spawn workers
unsafe void distributor(chanend ori, chanend but, streaming chanend c_led) {
  // world of 2x2 cells with border
  bit world[BITSLOTSP(WDHT + 4, WDWD + 4)];
  // pointer to world to give to workers
  bit (*unsafe world_p)[BITSLOTSP(WDHT + 4, WDWD + 4)] = &world;
  // uint32_t alive; // number of alive cells;
  timer t;        // timer, overflows after (2^32 - 1) * 10 ns (~42 sec)
  uint32_t start; // timer start time
  uint32_t stop;  // timer stop time
  uintmax_t i;    // iteration

  t :> start;
  // this also sets the border wrap to 0
  memset(world, 0, BITSLOTSP(WDHT + 4, WDWD + 4));
  memset(hamming, 0, 16);
  // in theory this isn't needed since it is completly overwritten
  memset(hash, 0, 65536);

  // precompute all hamming weights for 8 bit numbers (2x2 cells)
  // TODO: there are many ways to speedup the calculating done here
  for (uint16_t i = 0; i < 16; i++) {
    //forall i. hamming[i] = 0 due to memset
    hamming[i] += (i & 0b00000001) >> 0;
    hamming[i] += (i & 0b00000010) >> 1;
    hamming[i] += (i & 0b00000100) >> 2;
    hamming[i] += (i & 0b00001000) >> 3;
  }

  // precompute all cell steps for a 4x4 -> 2x2
  for (uint32_t i = 0; i < 65536; i++) {
    bit chunk[BITSLOTSP(4, 4)];
    bit result[BITSLOTSP(2, 2)];

    memset(result, 0, BITSLOTSP(2, 2));

    // the top 2x4
    BITSET4(chunk, i & 0b11111111, 0, 0, 4);
    // the bottom 2x4
    BITSET4(chunk, i >> 8, 2, 0, 4);

    // calculate the step for the inner 2x2
    // TODO: consider loop unrolling
    for (uint8_t r = 0; r < 2; r++) {
      for (uint8_t c = 0; c < 2; c++) {
        uint8_t neighbours = 0;
        neighbours += BITTESTP(chunk, r + 1 - 1, c + 1 - 1, 4);
        neighbours += BITTESTP(chunk, r + 1 - 1, c + 1    , 4);
        neighbours += BITTESTP(chunk, r + 1 - 1, c + 1 + 1, 4);
        neighbours += BITTESTP(chunk, r + 1,     c + 1 - 1, 4);
        // neighbours += BITTESTP(chunk, r + 1,     c + 1,     4);
        neighbours += BITTESTP(chunk, r + 1,     c + 1 + 1, 4);
        neighbours += BITTESTP(chunk, r + 1 + 1, c + 1 - 1, 4);
        neighbours += BITTESTP(chunk, r + 1 + 1, c + 1    , 4);
        neighbours += BITTESTP(chunk, r + 1 + 1, c + 1 + 1, 4);

        if (neighbours == 3 || (neighbours == 2 && BITTESTP(chunk, r + 1, c + 1, 4))) {
          // write it to result
          BITSETP(result, r, c, 2);
        }
      }
    }

    // store it in the hash
    hash[i] = BITGET2(result, 0, 0, 2);
  }
  t :> stop;

  printf("Calculating hamming weights and hashes took: %d0ns\n", stop - start);
  printf("%s -> %s\n%dx%d -> %dx%d\n", FILENAME_IN, FILENAME_OUT, IMHT, IMWD, WDHT, WDWD);
  printf("Press SW1 to load...\n");

  // end of precomputation

  // await sw1
  but :> uint8_t _;
  // green led for reading
  c_led <: D1_g;

  // read file
  if (_openinpgm(FILENAME_IN, IMWD, IMHT)) {
    printf("Error openening %s for reading.\n.", FILENAME_IN);
    printf("Defaulting to a blank (or hardcoded) world...\n.");

    checkboard_w(world_p, 0, 0, WDHT + 4, WDWD + 4);
    // random_w(world_p, 0, 0, WDHT + 4, WDWD + 4, 0);
    // TODO: put random world generation here
  } else {
    uint8_t line[IMWD]; // read in storage
    for (int r = 0; r < IMHT; r++) {
      _readinline(line, IMWD);
      for (int c = 0; c < IMWD; c++) {
        if (line[c]) {
          // image is offset from 0, 0 by OFHT, OFWD
          BITSETP(world, r + 2 + OFHT, c + 2 + OFWD, WDWD + 4);
        }
        // clear not needed since world is 0 from memset
        // else {
        //   BITCLEARP(world, r, c, IMWD);
        // }
      }
    }
  }
  _closeinpgm();
  printworld_w(world, 0);

  // finished loading file

  chan toWorker[WCOUNT];
  chan toNextWorker[WCOUNT];

  par{
    // start worker threads
    par (uint8_t i = 0; i < WCOUNT - 1; i++) {
      worker(world_p, i, toWorker[i], toNextWorker[i + 1], toNextWorker[i]);
    }
    lastWorker(world_p, 6, toWorker[6],  toNextWorker[6]);

    // worker management code
    {
      // start timer
      t :> start;
      for (i = 0; i < ITERATIONS; i++) {
        select {
          // tilt sensor thread
          case ori :> uint8_t _:
            t :> stop;
            c_led <: D1_r;
            printf("Iteration: %llu\t", i);
            printf("Elapsed Time (ns): %lu0\t", stop - start);
            printf("Alive Cells: %d\n", alivecount_w(world_p));
            // printworld_w(world, i);
            // wait until untilt
            ori :> uint8_t _;
            break;
          // button sw2
          case but :> uint8_t _:
            c_led <: D1_b;
            printworld_w(world, i);
            // save to file
            if (_openinpgm(FILENAME_IN, WDWD, WDHT)) {
              printf("Error opening %s for saving.\n.", FILENAME_OUT);
              printf("Skipping save...\n.");
            } else {
              uint8_t line[WDWD]; // write out in storage
              for (int r = 0; r < WDHT; r++) {
                for (int c = 0; c < WDWD; c++) {
                  if (BITTESTP(world, r, c, WDWD + 4)) {
                    line[c] = ~0;
                  } else {
                    line[c] = 0;
                  }
                }
                _writeoutline(line, WDWD);
              }
            }
            _closeoutpgm();
            break;
          // carry on as normal
          default:
            switch (i % 2) {
              case 0:
              c_led <: D0;
              break;
              case 1:
              c_led <: D2;
              break;
            }
            break;
        }
        // in theory the following code should go ito the default block, but
        // that would be very indented

        // sync start
        for(int i = 0; i < WCOUNT; i++){
          // send 0 for not finished
          toWorker[i] <: 0;
        }
        // copy border into opposite border wrap
        // TODO: these can be merged into the for loop
        // TODO: consider moving this into the workers
        BITSET2(world, BITGET2(world, WDHT, WDWD, WDWD + 4),        0,        0, WDWD + 4);
        BITSET2(world, BITGET2(world, WDHT,    2, WDWD + 4),        0, WDWD + 2, WDWD + 4);
        BITSET2(world, BITGET2(world,    2, WDWD, WDWD + 4), WDWD + 2,        0, WDWD + 4);
        BITSET2(world, BITGET2(world,    2,    2, WDWD + 4), WDWD + 2, WDWD + 2, WDWD + 4);
        for (int r = 2; r < WDHT + 2; r += 2) {
          BITSET2(world, BITGET2(world, r,    2, WDWD + 4), r, WDWD + 2, WDWD + 4);
          BITSET2(world, BITGET2(world, r, WDWD, WDWD + 4), r,        0, WDWD + 4);
        }
        for (int c = 2; c < WDWD + 2; c += 2) {
          BITSET2(world, BITGET2(world,    2, c, WDWD + 4), WDHT + 2, c, WDWD + 4);
          BITSET2(world, BITGET2(world, WDHT, c, WDWD + 4),        0, c, WDWD + 4);
        }

        // workers must be started in such an order to ensure none of them
        // write over what another worker hasn't read
        // workers perfrom work in columns
        // start worker[0] for 1 line
        for(int i = 0; i < WDWD + 2; i += 2){
          toNextWorker[0] <: 1;
        }
        // sync completion
        for(int i = 0; i < WCOUNT; i++){
          toWorker[i] :> int _;
        }
        printworld_w(world, i + 1);
      }
      t :> stop;
      // no more iterations, workers can stop now
      // unfortunatly with 7 workers there are not enough channels to
      // gracefully shutdown the other threads
      for(int i = 0; i < WCOUNT; i++){
        // send 0 for finished
        toWorker[i] <: 1;
      }
      printf("Iteration: %llu\t", i);
      printf("Elapsed Time (ns): %lu0\t", stop - start);
      printf("Alive Cells: %d\n", alivecount_w(world_p));
      printworld_w(world, i);
    }
  }
}

// args can be used for timing instead of defined constants
// TODO: consider using this for testing
unsafe int main(unsigned int argc, char* unsafe argv[argc]) {
  i2c_master_if i2c[1]; // interface to orientation
  chan c_ori, c_but;    // orientation, button and led channel
  streaming chan c_led;

  par {
    // these must be placed on tile[0] to access ports
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);
    on tile[0]: orientation(i2c[0], c_ori);
    on tile[0]: button(p_buttons, c_but);
    on tile[0]: led(p_leds, c_led);
    // this must be placed on tile[1] for more than 3 workers
    on tile[1]: distributor(c_ori, c_but, c_led);
  }

  return 0;
}
