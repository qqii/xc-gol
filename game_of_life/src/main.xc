// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <platform.h>
#include <xs1.h>
#include "i2c.h"
#include "pgmIO.h"
#include "constants.h"
#include "world.h"
#include "worker.h"

bit hamming[16]; // hamming weight to calculate alive cells
bit hash[65536];  // hash for lookup

// interface ports to orientation
on tile[0]: port p_scl = XS1_PORT_1E;
on tile[0]: port p_sda = XS1_PORT_1F;
//  both of these must be on port 0
on tile[0]: in   port p_buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0]: out  port p_leds    = XS1_PORT_4F; //port to access xCore-200 LEDs

void led(out port p, chanend toDist) {
  int val;
  while (1) {
    toDist :> val;
    p <: val;
  }
}

// main concurrent thread
unsafe void distributor(chanend ori, chanend but, chanend c_led) {
  // world
  bit world[BITSLOTSP(WDHT + 4, WDWD + 4)]; // world of 2x2 cells with border
  uint32_t alive = 0;

  bit (*unsafe world_p)[BITSLOTSP(WDHT + 4, WDWD + 4)] = &world;

  // timer
  timer t;
  uint32_t start;
  uint32_t stop;
  // state
  uintmax_t i; // iteration

  t :> start;

  memset(world, 0, BITSLOTSP(WDHT + 4, WDWD + 4));
  memset(hamming, 0, 16);
  // in theory this isn't needed
  memset(hash, 0, 65536);


  // there are many ways to speedup the calculating
  for (uint16_t i = 0; i < 16; i++) {
    //forall i. hamming[i] = 0 due to memset
    hamming[i] += (i & 0b00000001) >> 0;
    hamming[i] += (i & 0b00000010) >> 1;
    hamming[i] += (i & 0b00000100) >> 2;
    hamming[i] += (i & 0b00001000) >> 3;
    // hamming[i] += (i & 0b00010000) >> 4;
    // hamming[i] += (i & 0b00100000) >> 5;
    // hamming[i] += (i & 0b01000000) >> 6;
    // hamming[i] += (i & 0b10000000) >> 7;
  }

  for (uint32_t i = 0; i < 65536; i++) {
    bit chunk[BITSLOTSP(4, 4)];
    bit result[BITSLOTSP(2, 2)];

    memset(result, 0, BITSLOTSP(2, 2));

    BITSET4(chunk, i & 0b11111111, 0, 0, 4);
    BITSET4(chunk, i >> 8, 2, 0, 4);

    // printf("chunk %d:\n", i);
    // for (int r = 0; r < 4; r++) {
    //   for (int c = 0; c < 4; c++) {
    //     printf("%c", BITTESTP(chunk, r, c, 4) ? 219 : 176);
    //   }
    //   printf("\n");
    // }

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
          BITSETP(result, r, c, 2);
        }
      }
    }

    // printf("result %d:\n", i);
    // for (int r = 0; r < 2; r++) {
    //   for (int c = 0; c < 2; c++) {
    //     printf("%c", BITTESTP(result, r, c, 2) ? 219 : 176);
    //   }
    //   printf("\n", 176);
    // }

    hash[i] = BITGET2(result, 0, 0, 2);
  }
  t :> stop;
  printf("Calculating hamming weights and hashes took: %d0\n", stop - start);
  printf("%s -> %s\n%dx%d -> %dx%d\n", FILENAME_IN, FILENAME_OUT, IMHT, IMWD, WDHT, WDWD);
  printf("Press SW1 to load...\n");

  // await sw1
  // but :> uint8_t _;
  // green led for reading
  c_led <: D1_g;

  // READ FILE
  if (_openinpgm(FILENAME_IN, IMWD, IMHT)) {
    printf("Error openening %s for reading.\n.", FILENAME_IN);
    printf("Defaulting to a blank (or hardcoded) world...\n.");
  } else {
    // Read image line-by-line and send byte by byte to channel ch
    uint8_t line[IMWD]; // read in storage
    for (int r = 0; r < IMHT; r++) {
      _readinline(line, IMWD);
      for (int c = 0; c < IMWD; c++) {
        if (line[c]) {
          alive++;
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

  printworld_w(world);

  // start timer

  chan toWorker[WCOUNT];
  chan toNextWorker[WCOUNT];

  par{
    worker(world_p, 0, toWorker[0], toNextWorker[1], toNextWorker[0]);
    worker(world_p, 1, toWorker[1], toNextWorker[2], toNextWorker[1]);
    worker(world_p, 2, toWorker[2], toNextWorker[3], toNextWorker[2]);
    worker(world_p, 3, toWorker[3], toNextWorker[4], toNextWorker[3]);
    worker(world_p, 4, toWorker[4], toNextWorker[5], toNextWorker[4]);
    // worker(world_p, 5, toWorker[5], fromLastWorker, toNextWorker[5]);
    worker(world_p, 5, toWorker[5], toNextWorker[6], toNextWorker[5]);
    lastWorker(world_p, 6, toWorker[6],  toNextWorker[6]);
    {
      t :> start;
      for (int I = 0; I < WCOUNT; I++){
        toWorker[I] <: 1;
      }
      for (i = 0; i < ITERATIONS; i++) {
        select {
          // tilt
          case ori :> uint8_t _:
            t :> stop;
            c_led <: D1_r;
            printf("Iteration: %llu\t", i);
            printf("Elapsed Time (ns): %lu0\t", stop - start);
            printf("Alive Cells: %d\n", alive);
            printworld_w(world);
            // wait until untilt
            ori :> uint8_t _;
            break;
          // button sw2
          case but :> uint8_t _:
            c_led <: D1_b;
            printworld_w(world);
            // SAVE
            if (_openinpgm(FILENAME_IN, WDWD, WDHT)) {
              printf("Error opening %s for saving.\n.", FILENAME_OUT);
              printf("Skipping save...\n.");
            } else {
              uint8_t line[WDWD]; // read in storage
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


        // copy wrap
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

        // printworld_w(world);

        for(int I = 0; I < WDWD + 2; I+= 2){
          toNextWorker[0] <: 1;
        }

        for(int I = 0; I < WCOUNT; I++){
          toWorker[I] :> int _;
        }


        for(int I = 0; I < WCOUNT; I++){
          toWorker[I] <: 0;
        }
      }
      t :> stop;
      printf("Iteration: %llu\t", i);
      printf("Elapsed Time (ns): %lu0\t", stop - start);
      printf("Alive Cells: %d\n", alive);
      printworld_w(world);
    }
  }
}

// orientation thread sends any tilt or untilt
void orientation(client interface i2c_master_if i2c, chanend c_ori) {
  i2c_regop_res_t result;
  char status_data = 0;
  uint8_t tilted = 0;
  // Configure FXOS8700EQ
  result =
      i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }
  // Enable FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_CTRL_REG_1, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }
  // Probe the orientation x-axis forever
  while (1) {
    // check until new orientation data is available
    do {
      status_data =
          i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
    } while (!status_data & 0x08);
    // get new x-axis tilt value
    int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);
    // send signal to distributor after first tilt
    if (tilted) {
      if (x < UNTILT_THRESHOLD) {
        c_ori <: tilted;
        tilted = 0;
      }
    } else {
      if (x > TILT_THRESHOLD) {
        c_ori <: tilted;
        tilted = 1;
      }
    }
  }
}

// button thread sends the first sw1 and any subsiquent sw2 presses
void button(in port b, chanend c_but) {
  uint8_t val;
  // detect sw1 one time
  while (1) {
    b when pinseq(15)  :> void;
    b when pinsneq(15) :> val;
    if (val == SW1) {
      c_but <: val;
      break;
    }
  }
  // detect subsiquent sw2
  while (1) {
    b when pinseq(15)  :> void;   // check that no button is pressed
    b when pinsneq(15) :> val;    // check if some buttons are pressed
    if (val == SW2) {
      c_but <: val;
    }
  }
}

// Orchestrate concurrent system and start up all threads
unsafe int main(unsigned int argc, char* unsafe argv[argc]) {
  i2c_master_if i2c[1]; // interface to orientation
  chan c_ori, c_but, c_led;    // orientation and button channel

  par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10); // server thread providing orientation data
    on tile[0]: orientation(i2c[0], c_ori);
    on tile[0]: button(p_buttons, c_but);
    on tile[0]: led(p_leds, c_led);
    on tile[1]: distributor(c_ori, c_but, c_led); // thread to coordinate work on image
  }

  // currently the program will never stop, the io thread does not support graceful shutdown
  return 0;
}
