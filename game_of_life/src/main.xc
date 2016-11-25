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

on tile[0]: port p_scl        = XS1_PORT_1E; //interface ports to orientation
on tile[0]: port p_sda        = XS1_PORT_1F;
//  both of these must be on port 0
on tile[0]: in   port p_buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0]: out  port p_leds    = XS1_PORT_4F; //port to access xCore-200 LEDs

// Start your implementation by changing this function to implement the game of life
// by farming out parts of the image to worker threads who implement it...
// Currently the function just inverts the image
void distributor(ui_if client c, chanend ch) {
  uint8_t val;
  uint8_t D1 = 1;
  world_t world = blank_w(new_ix(IMHT, IMWD));

  // Starting up and wait for tilting of the xCore-200 Explorer
  printf("%s -> %s\n%dx%d\nPress SW1 to load...\n", FILENAME_IN, FILENAME_OUT,
                                                    IMHT, IMWD);
  while (c.getButtons() != SW1);
  c.setLEDs(D2);

  // printf("Processing...\n");
  for (int y = 0; y < IMHT; y++) {  // go through all lines
    for (int x = 0; x < IMWD; x++) {  // go through each pixel per line
      ch :> val;  // read the pixel value
      world = set_w(world, new_ix(y, x), val);
    }
  }
  printworld_w(flip_w(world));

  c.startTimer();
  world = flip_w(world);
  for (uintmax_t i = 0; 1; i++) {
    if (D1) {
      c.setLEDs(D0);
    } else {
      c.setLEDs(D1_g);
    }
    D1 = !D1;

    for (int y = 0; y < IMHT; y++) {
      for (int x = 0; x < IMWD; x++) {
        ix_t ix = new_ix(y, x);
        world = set_w(world, ix, step_w(world, ix));
      }
    }
    world = flip_w(world);

    if (c.getButtons() == SW2) {
      c.setLEDs(D1_b);
      printworld_w(world);
      for (int y = 0; y < IMHT; y++) {
        for (int x = 0; x < IMWD; x++) {
          if (isalive_w(world, new_ix(y, x))) {
            val = ~0;
          } else {
            val = 0;
          }
          ch <: val;
        }
      }
    } else if (abs(c.getAccelerationX()) > TILT_THRESHOLD
            || abs(c.getAccelerationY()) > TILT_THRESHOLD) {
      c.setLEDs(D1_r);
      printf("Iteration: %llu\t", i);
      printf("Elapsed Time (ns): %lu0\t", c.getElapsedTime());
      // alive cells aren't stored anywhere, thus they need to be calculated when
      // asked. this may cause some delay on larger boards
      int alive = 0;
      for (int y = 0; y < IMHT; y++) {
        for (int x = 0; x < IMWD; x++) {
          if (isalive_w(world, new_ix(y, x))) {
            alive++;
          }
        }
      }
      printf("Alive Cells: %d\n", alive);
      // wait until untilt
      while (abs(c.getAccelerationX()) > UNTILT_THRESHOLD
          || abs(c.getAccelerationY()) > UNTILT_THRESHOLD);
    }
  }
}

// Orchestrate concurrent system and start up all threads
int main(void) {
  i2c_master_if i2c[1];               //interface to orientation
  ui_if c;
  chan c_io;    //extend your channel definitions here

  par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);     //server thread providing orientation data
    on tile[0]: ui(i2c[0], p_buttons, p_leds, c);
    on tile[0]: io(FILENAME_IN, FILENAME_OUT, c_io);
    on tile[0]: distributor(c, c_io);  //thread to coordinate work on image
  }

  return 0;
}
