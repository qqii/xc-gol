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
void distributor(chanend ori, chanend but) {
  uint8_t val;
  uint8_t D1 = 1; // green flash state
  uint8_t line[IMWD]; // read in storage
  // timer that overflows after (2^32-1)*10ns
  timer t;
  uint32_t start = 0;
  uint32_t stop = 0;
  // world
  world_t world = blank_w();
  uint32_t alive = 0;
  bit buffer[BITNSLOTSM(3, IMWD)];

  printf("%s -> %s\n%dx%d -> %dx%d\nPress SW1 to load...\n", FILENAME_IN, FILENAME_OUT, IMHT, IMWD, WDHT, WDWD);
  // wait for SW1
  but :> val;
  p_leds <: D2;
  // READ
  val = _openinpgm(FILENAME_IN, IMWD, IMHT);
  if (val) {
    printf("Error openening %s for reading.\n.", FILENAME_IN);
    printf("Defaulting to a blank (or hardcoded) world...\n.");
  } else {
    // Read image line-by-line and send byte by byte to channel ch
    for (int r = OFHT; r < IMHT; r++) {
      _readinline(line, IMWD);
      for (int c = OFWD; c < IMWD; c++) {
        set_w(world, r, c, line[c]);
      }
    }
  }
  _closeinpgm();

  // world = random_w(world, 0, 0, WDHT, WDWD, 0);
  // world = randperlin_w(world, 0, 0, WDHT, WDWD, 0, 0, 0.1, 4, 0);
  printworld_w(world);
  // printworldcode_w(world, 1);

  t :> start;
  for (uintmax_t i = 0; i < 1024; i++) {
    select {
      case ori :> val:
        t :> stop;
        p_leds <: D1_r;
        printf("Iteration: %llu\t", i);
        printf("Elapsed Time (ns): %lu0\t", stop - start);
        printf("Alive Cells: %d\n", alive);
        ori :> val;
        break;
      case but :> val:
        p_leds <: D1_b;
        printworld_w(world);
        // SAVE
        val = _openoutpgm(FILENAME_OUT, WDWD, WDHT);
        if (val) {
          printf("Error opening %s for saving.\n.", FILENAME_OUT);
          printf("Skipping save...\n.");
        } else {
          for (int y = 0; y < IMHT; y++) {
            for (int x = 0; x < IMWD; x++) {
              if (isalive_w(world, y, x)) {
                line[x] = ~0;
              } else {
                line[x] = 0;
              }
            }
            _writeoutline(line, IMWD);
          }
        }
        _closeoutpgm();
        break;
      default:
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
    alive = 0;
    // copy wrap
    set_w(world, -1,      -1, isalive_w(world,IMHT - 1, IMWD - 1));
    set_w(world, -1,    IMWD, isalive_w(world,IMHT - 1,        0));
    set_w(world, IMHT,    -1, isalive_w(world,0,        IMWD - 1));
    set_w(world, IMHT,  IMWD, isalive_w(world,0,               0));
    for (int i = 0; i < IMWD; i++) {
      set_w(world, -1,   i, isalive_w(world, IMHT - 1, i));
      set_w(world, IMHT, i, isalive_w(world, 0,        i));
    }
    for (int i = 0; i < IMWD; i++) {
      set_w(world, i,   -1, isalive_w(world, i, IMWD - 1));
      set_w(world, i, IMWD, isalive_w(world, i,        0));
    }
    // write top result to buffer[2]
    // calculate row 1 into buffer[1]
    for (int c = 0; c < WDWD; c++) {
      if (step_w(world, 0, c)) {
        BITSETM(buffer, 2, c, WDWD);
        alive++;
      } else {
        BITCLEARM(buffer, 2, c, WDWD);
      }
    }
    // rest of the rows
    for (int r = 1; r < WDHT; r++) {
      // update row into buffer[r%2] and writeback from buffer[(r-1)%2]
      // if (step_w(world, r, 0)) {
      //   BITSETM(buffer, r % 2, 0, WDWD);
      //   alive++;
      // } else {
      //   BITCLEARM(buffer, r % 2, 0, WDWD);
      // }
      for (int c = 0; c < WDWD; c++) {
        if (step_w(world, r, c)) {
          BITSETM(buffer, r % 2, c, WDWD);
          alive++;
        } else {
          BITCLEARM(buffer, r % 2, c, WDWD);
        }
      }
      for (int c = 0; c < WDWD; c++) {
        set_w(world, r - 1, c, BITTESTM(buffer, (r - 1) % 2, c, WDWD));
      }
      // set_w(world, r - 1, WDWD - 1, BITTESTM(buffer, (r - 1) % 2, WDWD - 1, WDWD));
    }
    // put top and last result from buffer
    for (int c = 0; c < WDWD; c++) {
      set_w(world, 0, c, BITTESTM(buffer, 2, c, IMWD));
      set_w(world, WDHT - 1, c, BITTESTM(buffer, (IMHT - 1) % 2, c, IMWD));
    }
    // printworld_w(world);
  }
  t :> stop;
  printf("Elapsed Time (ns): %lu0\t", stop - start);
  printworld_w(world);
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
    b when pinseq(15)  :> val;
    b when pinsneq(15) :> val;
    if (val == SW1) {
      toDist <: val;
      break;
    }
  }
  // detect subsiquent sw2
  while (1) {
    b when pinseq(15)  :> val;    // check that no button is pressed
    b when pinsneq(15) :> val;    // check if some buttons are pressed
    if (val == SW2) {
      toDist <: val;
    }
  }
}
// Orchestrate concurrent system and start up all threads
int main(void) {
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
