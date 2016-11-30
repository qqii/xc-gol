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

// interface ports to orientation
on tile[0]: port p_scl = XS1_PORT_1E;
on tile[0]: port p_sda = XS1_PORT_1F;
//  both of these must be on port 0
on tile[0]: in   port p_buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0]: out  port p_leds    = XS1_PORT_4F; //port to access xCore-200 LEDs

// main concurrent thread
void distributor(chanend ori, chanend but) {
  uint8_t world[BITSLOTSP(WDHT, WDWD)];
  uint8_t hamming[16];
  uint8_t hash[65536];

  memset(world, 0, BITSLOTSP(WDHT, WDWD));
  memset(hamming, 0, 16);
  memset(hash, 0, 65536 * 2);

  timer t;
  uint32_t start;
  uint32_t end;

  t :> start;

  for (uint8_t i = 0; i < 16; i++) {
    hamming[i] += i & 0b0001;
    hamming[i] += (i & 0b0010) >> 1;
    hamming[i] += (i & 0b0100) >> 2;
    hamming[i] += (i & 0b1000) >> 3;
  }

  for (uint32_t i = 0; i < 65536; i++) {
    uint8_t chunk[BITSLOTSP(4, 4)];
    uint8_t result[BITSLOTSP(2, 2)];

    BITSET4(chunk, i & 0b11111111, 0, 0, 4);
    BITSET4(chunk, i >> 8, 2, 0, 4);

    // printf("chunk %d:\n", i);
    // for (int r = 0; r < 4; r++) {
    //   for (int c = 0; c < 4; c++) {
    //     printf("%c", BITTESTP(chunk, r, c, 4) ? 219 : 176);
    //   }
    //   printf("\n");
    // }

    for (uint8_t r = 0; r < 2; r++) {
      for (uint8_t c = 0; c < 2; c++) {
        uint8_t neighbours = 0;

        neighbours += BITTESTP(chunk, r + 1 - 1, c + 1 - 1, 4);
        neighbours += BITTESTP(chunk, r + 1 - 1, c + 1    , 4);
        neighbours += BITTESTP(chunk, r + 1 - 1, c + 1 + 1, 4);
        neighbours += BITTESTP(chunk, r + 1,     c + 1 - 1, 4);
        neighbours += BITTESTP(chunk, r + 1,     c + 1 + 1, 4);
        neighbours += BITTESTP(chunk, r + 1 + 1, c + 1 - 1, 4);
        neighbours += BITTESTP(chunk, r + 1 + 1, c + 1    , 4);
        neighbours += BITTESTP(chunk, r + 1 + 1, c + 1 - 1, 4);

        if (neighbours == 3 || (neighbours == 2 && BITTESTP(chunk, r + 1, c + 1, 4))) {
          BITSETP(result, r, c, 2);
        } else {
          BITCLEARP(result, r, c, 2);
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
  t :> end;
  printf("%d0\n", end - start);

  BITSETP(world, 0, 0, WDWD);
  BITSETP(world, 1, 1, WDWD);

  printf("BITSLOTSP(h, w) = %d\n", BITSLOTSP(WDHT, WDWD));
  for (int r = 0; r < WDHT; r++) {
    for (int c = 0; c < WDWD; c++) {
      // printf("(%02d,%02d)", (r / 2) * BITSLOTW(W), (c / 2) / 2);
      printf("%c", BITTESTP(world, r, c, WDWD) ? 219 : 176);
    }
    printf("\n");
  }

  //
  // uint8_t D1 = 1; // green flash state
  // // timer that overflows after (2^32-1)*10ns
  // timer t;
  // uint32_t start = 0;
  // uint32_t stop = 0;
  // // world
  // bit world[BITNSLOTSM(WDHT + 2, WDWD + 2)];
  // memset(world, 0, BITNSLOTSM(WDHT + 2, WDWD + 2));
  // uint32_t alive = 0;
  // bit buffer[BITNSLOTSM(2, WDWD)];
  //
  // printf("%s -> %s\n%dx%d -> %dx%d\nPress SW1 to load...\n", FILENAME_IN, FILENAME_OUT, IMHT, IMWD, WDHT, WDWD);
  // // wait for SW1
  // but :> uint8_t _;
  // p_leds <: D2;
  // // READ
  // if (_openinpgm(FILENAME_IN, IMWD, IMHT)) {
  //   printf("Error openening %s for reading.\n.", FILENAME_IN);
  //   printf("Defaulting to a blank (or hardcoded) world...\n.");
  // } else {
  //   // Read image line-by-line and send byte by byte to channel ch
  //   uint8_t line[IMWD]; // read in storage
  //   for (int r = OFHT; r < IMHT; r++) {
  //     _readinline(line, IMWD);
  //     for (int c = OFWD; c < IMWD; c++) {
  //       set_w(world, r, c, line[c]);
  //     }
  //   }
  // }
  // _closeinpgm();
  //
  // // world = random_w(world, 0, 0, WDHT, WDWD, 0);
  // // world = randperlin_w(world, 0, 0, WDHT, WDWD, 0, 0, 0.1, 4, 0);
  // printworld_w(world);
  // // printworldcode_w(world, 1);
  //
  // t :> start;
  // for (uintmax_t i = 0; i < ITERATIONS; i++) {
  //   select {
  //     case ori :> uint8_t _:
  //       t :> stop;
  //       p_leds <: D1_r;
  //       printf("Iteration: %llu\t", i);
  //       printf("Elapsed Time (ns): %lu0\t", stop - start);
  //       printf("Alive Cells: %d\n", alive);
  //       ori :> uint8_t _;
  //       break;
  //     case but :> uint8_t _:
  //       p_leds <: D1_b;
  //       printworld_w(world);
  //       // SAVE
  //       if (_openinpgm(FILENAME_IN, IMWD, IMHT)) {
  //         printf("Error opening %s for saving.\n.", FILENAME_OUT);
  //         printf("Skipping save...\n.");
  //       } else {
  //         uint8_t line[IMWD]; // read in storage
  //         for (int y = 0; y < IMHT; y++) {
  //           for (int x = 0; x < IMWD; x++) {
  //             if (isalive_w(world, y, x)) {
  //               line[x] = ~0;
  //             } else {
  //               line[x] = 0;
  //             }
  //           }
  //           _writeoutline(line, IMWD);
  //         }
  //       }
  //       _closeoutpgm();
  //       break;
  //     default:
  //       switch (D1) {
  //         case 0:
  //           p_leds <: D0;
  //           D1 = 1;
  //           break;
  //         case 1:
  //           p_leds <: D1_g;
  //           D1 = 0;
  //           break;
  //       }
  //       break;
  //   }
  //   // do work
  //   alive = 0;
  //   // copy wrap
  //   set_w(world, -1,      -1, isalive_w(world,WDHT - 1, WDWD - 1));
  //   set_w(world, -1,    WDWD, isalive_w(world,WDHT - 1,        0));
  //   set_w(world, WDHT,    -1, isalive_w(world,0,        WDWD - 1));
  //   set_w(world, WDHT,  WDWD, isalive_w(world,0,               0));
  //   for (int i = 0; i < WDWD; i++) {
  //     set_w(world, -1,   i, isalive_w(world, WDHT - 1, i));
  //     set_w(world, WDHT, i, isalive_w(world, 0,        i));
  //   }
  //   for (int i = 0; i < WDWD; i++) {
  //     set_w(world, i,   -1, isalive_w(world, i, WDWD - 1));
  //     set_w(world, i, WDWD, isalive_w(world, i,        0));
  //   }
  //   // first row
  //   for (int c = 0; c < WDWD; c++) {
  //     bit ns = mooreneighbours_w(world, 0, c);
  //     if (ns == 3 || (ns == 2 && isalive_w(world, 0, c))) {
  //       BITSETM(buffer, 0, c, WDWD);
  //       alive++;
  //     } else {
  //       BITCLEARM(buffer, 0, c, WDWD);
  //     }
  //   }
  //   // rest of the rows
  //   for (int r = 1; r < WDHT; r++) {
  //     // update row into buffer[r%2]
  //     for (int c = 0; c < WDWD; c++) {
  //       bit ns = mooreneighbours_w(world, r, c);
  //       if (ns == 3 || (ns == 2 && isalive_w(world, r, c))) {
  //         BITSETM(buffer, r % 2, c, WDWD);
  //         alive++;
  //       } else {
  //         BITCLEARM(buffer, r % 2, c, WDWD);
  //       }
  //     }
  //     // writeback from buffer[(r-1)%2]
  //     for (int c = 0; c < WDWD; c++) {
  //       set_w(world, r - 1, c, BITTESTM(buffer, (r + 1) % 2, c, WDWD));
  //     }
  //   }
  //   // put top and last result from buffer
  //   for (int c = 0; c < WDWD; c++) {
  //     set_w(world, WDHT - 1, c, BITTESTM(buffer, (WDHT - 1) % 2, c, WDWD));
  //   }
  //   // printworld_w(world);
  // }
  // t :> stop;
  // printf("Elapsed Time (ns): %lu0\t", stop - start);
  // printworld_w(world);
}

// Initialise and  read orientation, send first tilt event to channel
void orientation(client interface i2c_master_if i2c, chanend toDist) {
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
        toDist <: tilted;
        tilted = 0;
      }
    } else {
      if (x > TILT_THRESHOLD) {
        toDist <: tilted;
        tilted = 1;
      }
    }
  }
}

void button(in port b, chanend toDist) {
  uint8_t val;
  // detect sw1 one time
  while (1) {
    b when pinseq(15)  :> void;
    b when pinsneq(15) :> val;
    if (val == SW1) {
      toDist <: val;
      break;
    }
  }
  // detect subsiquent sw2
  while (1) {
    b when pinseq(15)  :> void;   // check that no button is pressed
    b when pinsneq(15) :> val;    // check if some buttons are pressed
    if (val == SW2) {
      toDist <: val;
    }
  }
}

// Orchestrate concurrent system and start up all threads
unsafe int main(unsigned int argc, char* unsafe argv[argc]) {
  i2c_master_if i2c[1]; // interface to orientation
  chan c_ori, c_but;    // orientation and button channel

  par {
    // on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10); // server thread providing orientation data
    // on tile[0]: orientation(i2c[0], c_ori);
    // on tile[0]: button(p_buttons, c_but);
    on tile[0]: distributor(c_ori, c_but); // thread to coordinate work on image
  }

  // currently the program will never stop, the io thread does not support graceful shutdown
  return 0;
}
