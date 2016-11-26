// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)
#include <stdlib.h>
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
void distributor(chanend ch) {
  uint8_t val;
  uint8_t D1 = 1; // green flash state
  uint8_t line[IMWD];
  timer t;
  uint32_t start = 0;
  uint32_t stop = 0;
  world_t world = blank_w(new_ix(IMHT, IMWD));

  printf("%s -> %s\n%dx%d\nPress SW1 to load...\n", FILENAME_IN, FILENAME_OUT, IMHT, IMWD);
  // wait for SW1
  while (1) {
    p_buttons when pinseq(15)  :> val;    // check that no button is pressed
    p_buttons when pinsneq(15) :> val;    // check if some buttons are pressed
    if (val == SW1) {
      break;
    }
  }
  p_leds <: D2;

  // read
  val = _openinpgm(FILENAME_IN, IMWD, IMHT);
  if (val) {
    printf("DataInStream: Error openening %s\n.", FILENAME_IN);
    return;
  }
  // Read image line-by-line and send byte by byte to channel ch
  for (int y = 0; y < IMHT; y++) {
    _readinline(line, IMWD);
    for (int x = 0; x < IMWD; x++) {
      world = set_w(world, new_ix(y, x), line[x]);
    }
  }
  _closeinpgm();

  printworld_w(flip_w(world));

  t :> start;
  world = flip_w(world);
  for (uintmax_t i = 0; 1; i++) {
    select {
      case ch :> val:
        t :> stop;
        p_leds <: D1_r;
        printf("Iteration: %llu\t", i);
        printf("Elapsed Time (ns): %lu0\t", stop - start);
        int alive = 0;
        for (int y = 0; y < IMHT; y++) {
          for (int x = 0; x < IMWD; x++) {
            if (isalive_w(world, new_ix(y, x))) {
              alive++;
            }
          }
        }
        printf("Alive Cells: %d\n", alive);
        ch :> val;
        break;
      case p_buttons when pinsneq(15) :> val:
        // save
        if (val == SW2) {
          p_leds <: D1_b;
          printworld_w(world);
          val = _openoutpgm(FILENAME_OUT, IMWD, IMHT);
          if (val) {
            printf("DataOutStream: Error opening %s\n.", FILENAME_OUT);
            return;
          }
          for (int y = 0; y < IMHT; y++) {
            for (int x = 0; x < IMWD; x++) {
              if (isalive_w(world, new_ix(y, x))) {
                line[x] = ~0;
              } else {
                line[x] = 0;
              }
            }
            _writeoutline(line, IMWD);
          }
          _closeoutpgm();
        }
        p_buttons when pinseq(15)  :> val;
        break;
      default:
        // display green led
        switch (D1) {
          case 0:
            p_leds <: D0;
            D1 = 1;
            break;
          case 1:
            p_leds <: D1_g;
            D1 = 0;
            break;
        }
        break;
    }

    // do work
    for (int y = 0; y < IMHT; y++) {
      for (int x = 0; x < IMWD; x++) {
        ix_t ix = new_ix(y, x);
        world = set_w(world, ix, step_w(world, ix));
      }
    }
    world = flip_w(world);
  }
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
    // int y = read_acceleration(i2c, FXOS8700EQ_OUT_Y_MSB);

    // send signal to distributor after first tilt
    if (tilted) {
      if (x*x < UNTILT_THRESHOLD * UNTILT_THRESHOLD) {
        toDist <: tilted;
        tilted = 0;
      }
    } else {
      if (x*x > TILT_THRESHOLD * TILT_THRESHOLD) {
        toDist <: tilted;
        tilted = 1;
      }
    }
  }
}

// Orchestrate concurrent system and start up all threads
int main(void) {
  i2c_master_if i2c[1]; //interface to orientation
  chan c_ori;            // io channel

  par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10); // server thread providing orientation data
    on tile[0]: orientation(i2c[0], c_ori);
    on tile[0]: distributor(c_ori);                 // thread to coordinate work on image
  }

  // currently the program will never stop, the io thread does not support graceful shutdown

  return 0;
}
