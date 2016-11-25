// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <platform.h>
#include <xs1.h>

#include "constants.h"
#include "world.h"
#include "io.h"

// interface ports to orientation
on tile[0]: port p_scl        = XS1_PORT_1E;
on tile[0]: port p_sda        = XS1_PORT_1F;
//  both of these must be on port 0
on tile[0]: in   port p_buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0]: out  port p_leds    = XS1_PORT_4F; //port to access xCore-200 LEDs

// main concurrent thread
unsafe void distributor(ui_if client c, chanend ch) {
  uint8_t val;
  uint8_t D1 = 1;
  world_t world;
  blank_w(&world, new_ix(IMHT, IMWD));

  printf("%s -> %s\n%dx%d\nPress SW1 to load...\n", FILENAME_IN, FILENAME_OUT,
                                                    IMHT, IMWD);
  // wait for SW1
  while (c.getButtons() != SW1);
  c.setLEDs(D2);

  for (int y = 0; y < IMHT; y++) {
    for (int x = 0; x < IMWD; x++) {
      ch :> val;  // read the pixel value
      set_w(&world, new_ix(y, x), val);
    }
  }
  flip_w(&world);
  printworld_w(&world);

  c.startTimer();
  // flip_w(world);
  for (uintmax_t i = 0; 1; i++) {
    // display green led
    if (D1) {
      c.setLEDs(D0);
    } else {
      c.setLEDs(D1_g);
    }
    // alternate on and off
    D1 = !D1;

    // do work
    for (int y = 0; y < IMHT; y++) {
      for (int x = 0; x < IMWD; x++) {
        ix_t ix = new_ix(y, x);
        uint8_t step = step_w(&world, ix);
        set_w(&world, ix, step);
      }
    }
    flip_w(&world);

    // SW2 to write
    if (c.getButtons() == SW2) {
      c.setLEDs(D1_b);
      printworld_w(&world);
      for (int y = 0; y < IMHT; y++) {
        for (int x = 0; x < IMWD; x++) {
          if (isalive_w(&world, new_ix(y, x))) {
            val = ~0;
          } else {
            val = 0;
          }
          ch <: val;
        }
      }
    } else {
      // tilt to pause and print infomation
      if (abs(c.getAccelerationX()) > TILT_THRESHOLD || abs(c.getAccelerationY()) > TILT_THRESHOLD) {
        c.setLEDs(D1_r);
        printf("Iteration: %llu\t", i);
        printf("Elapsed Time (ns): %lu0\t", c.getElapsedTime());
        // alive cells aren't stored anywhere, thus they need to be calculated when asked
        // this may cause some delay on larger boards
        int alive = 0;
        for (int y = 0; y < IMHT; y++) {
          for (int x = 0; x < IMWD; x++) {
            if (isalive_w(&world, new_ix(y, x))) {
              alive++;
            }
          }
        }
        printf("Alive Cells: %d\n", alive);
        // wait until untilt
        while (abs(c.getAccelerationX()) > UNTILT_THRESHOLD || abs(c.getAccelerationY()) > UNTILT_THRESHOLD);
      }
    }
  }
}

// Orchestrate concurrent system and start up all threads
unsafe int main(void) {
  i2c_master_if i2c[1]; //interface to orientation
  ui_if c;              // ui interface
  chan c_io;            // io channel

  par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10); // server thread providing orientation data
    on tile[0]: ui(i2c[0], p_buttons, p_leds, c);     // all in one ui thread for buttons, leds and tilt
    on tile[0]: io(FILENAME_IN, FILENAME_OUT, c_io);  // file io thread
    on tile[1]: distributor(c, c_io);                 // thread to coordinate work on image
  }

  // currently the program will never stop, the io thread does not support graceful shutdown

  return 0;
}
