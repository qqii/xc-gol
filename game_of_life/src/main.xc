// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)
#include <stdint.h>
#include <stdio.h>
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
unsafe void distributor(chanend ori, chanend but) {
  // world
  uint8_t world[BITNSLOTSM(WDHT + 2, WDWD + 2)];        // entire world with border for wrap
  uint8_t buffer[BITNSLOTSM(2, WDWD)];
  uint8_t hash[512];
  uint8_t (*unsafe worldp)[BITNSLOTSM(WDHT + 2, WDWD + 2)] = &world;
  // world state
  uint32_t alive = 0;
  uintmax_t i;  // iterations
  // timer that overflows after (2^32-1)*10ns
  timer t;
  uint32_t start = 0;
  uint32_t stop = 0;

  t :> start;
  blank_w(worldp);
  // technically not needed
  // memset(hash, 0, 512);

  for (uint16_t i = 0; i < 512; i++) {
    // ihg fed cba
    // abc
    // def
    // ghi
    uint8_t neighbours = 0;
    uint8_t self = (i & 0b000010000) >> 4;

    neighbours += (i & 0b000000001) >> 0; // a
    neighbours += (i & 0b000000010) >> 1; // b
    neighbours += (i & 0b000000100) >> 2; // c
    neighbours += (i & 0b000001000) >> 3; // d
    // neighbours += (i & 0b000010000) >> 4; // e
    neighbours += (i & 0b000100000) >> 5; // f
    neighbours += (i & 0b001000000) >> 6; // g
    neighbours += (i & 0b010000000) >> 7; // h
    neighbours += (i & 0b100000000) >> 8; // i
    hash[i] = neighbours == 3 || (neighbours == 2 && self);
  }
  t :> stop;
  printf("Calculating hamming weights and hashes took: %d0\n", stop - start);

  printf("%s -> %s\n%dx%d -> %dx%d\nPress SW1 to load...\n", FILENAME_IN, FILENAME_OUT, IMHT, IMWD, WDHT, WDWD);

  // wait for SW1
  but :> uint8_t _;
  p_leds <: D1_g;
  // READ
  if (_openinpgm(FILENAME_IN, IMWD, IMHT)) {
    printf("Error openening %s for reading.\n.", FILENAME_IN);
    printf("Defaulting to a blank (or hardcoded) world...\n.");
  } else {
    // Read image line-by-line and send byte by byte to channel ch
    uint8_t line[IMWD]; // read in storage
    for (int r = 0; r < IMHT; r++) {
      _readinline(line, IMWD);
      for (int c = 0; c < IMWD; c++) {
        set_w(worldp, r + OFHT, c + OFWD, line[c]);
        alive += line[c] & 0b0001;
      }
    }
  }
  _closeinpgm();

  printworld_w(worldp);

  t :> start;
  for (i = 0; i < ITERATIONS; i++) {
    select {
      case ori :> uint8_t _:
        t :> stop;
        p_leds <: D1_r;
        printf("Iteration: %llu\t", i);
        printf("Elapsed Time (ns): %lu0\t", stop - start);
        printf("Alive Cells: %d\n", alive);
        ori :> uint8_t _;
        break;
      case but :> uint8_t _:
        p_leds <: D1_b;
        printworld_w(worldp);
        // SAVE
        if (_openinpgm(FILENAME_IN, WDWD, WDHT)) {
          printf("Error opening %s for saving.\n.", FILENAME_OUT);
          printf("Skipping save...\n.");
        } else {
          uint8_t line[WDWD]; // read in storage
          for (int r = 0; r < WDHT; r++) {
            for (int c = 0; c < WDWD; c++) {
              if (isalive_w(worldp, r, c)) {
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
            p_leds <: D0;
            break;
          case 1:
            p_leds <: D2;
            break;
        }
        break;
    }
    // do work
    alive = 0;
    // copy wrap
    set_w(worldp, -1,      -1, isalive_w(worldp, WDHT - 1, WDWD - 1));
    set_w(worldp, -1,    WDWD, isalive_w(worldp, WDHT - 1,        0));
    set_w(worldp, WDHT,    -1, isalive_w(worldp, 0,        WDWD - 1));
    set_w(worldp, WDHT,  WDWD, isalive_w(worldp, 0,               0));
    for (int i = 0; i < WDWD; i++) {
      set_w(worldp, -1,   i, isalive_w(worldp, WDHT - 1, i));
      set_w(worldp, WDHT, i, isalive_w(worldp, 0,        i));
    }
    for (int i = 0; i < WDWD; i++) {
      set_w(worldp, i,   -1, isalive_w(worldp, i, WDWD - 1));
      set_w(worldp, i, WDWD, isalive_w(worldp, i,        0));
    }
    // first row
    for (int c = 0; c < WDWD; c++) {
      if (hash[allbitfieldpacked_w(worldp, 0, c)]) {
        BITSETM(buffer, 0, c, WDWD);
        alive++;
      } else {
        BITCLEARM(buffer, 0, c, WDWD);
      }
    }
    // rest of the rows
    for (int r = 1; r < WDHT; r++) {
      // update row into buffer[r%2]
      for (int c = 0; c < WDWD; c++) {
        if (hash[allbitfieldpacked_w(worldp, r, c)]) {
          BITSETM(buffer, r % 2, c, WDWD);
          alive++;
        } else {
          BITCLEARM(buffer, r % 2, c, WDWD);
        }
      }
      // writeback from buffer[(r-1)%2]
      for (int c = 0; c < WDWD; c++) {
        set_w(worldp, r - 1, c, BITTESTM(buffer, (r + 1) % 2, c, WDWD));
      }
    }
    // put top and last result from buffer
    for (int c = 0; c < WDWD; c++) {
      set_w(worldp, WDHT - 1, c, BITTESTM(buffer, (WDHT - 1) % 2, c, WDWD));
    }
    // printworld_w(worldp);
  }

  t :> stop;
  printf("Iteration: %llu\t", i);
  printf("Elapsed Time (ns): %lu0\t", stop - start);
  printf("Alive Cells: %d\n", alive);
  printworld_w(worldp);
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
unsafe int main(void) {
  i2c_master_if i2c[1]; //interface to orientation
  chan c_ori, c_but;            // io channel

  par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10); // server thread providing orientation data
    on tile[0]: orientation(i2c[0], c_ori);
    on tile[0]: button(p_buttons, c_but);
    on tile[0]: distributor(c_ori, c_but);                 // thread to coordinate work on image
  }

  // currently the program will never stop, the io thread does not support graceful shutdown
  return 0;
}
