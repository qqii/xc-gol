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
void distributor(chanend ori, chanend but) {
  uint8_t val;
  uint8_t D1 = 1; // green flash state
  uint8_t line[IMWD];
  timer t;
  uint32_t start = 0;
  uint32_t stop = 0;
  world_t world = blank_w();

  printf("%s -> %s\n%dx%d\nPress SW1 to load...\n", FILENAME_IN, FILENAME_OUT, IMHT, IMWD);
  // wait for SW1
  but :> val;
  p_leds <: D2;

  // READ
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

  // world = block_w(world, new_ix(1, 1));

  world = flip_w(world);

  printworld_w(world);
  // printworldcode_w(world, 1);

  t :> start;
  for (uintmax_t i = 0;; i++) {
    select {
      case ori :> val:
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
        ori :> val;
        break;
      case but :> val:
        p_leds <: D1_b;
        printworld_w(world);
        // SAVE
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
    for (int y = 0; y < IMHT; y++) {
      for (int x = 0; x < IMWD; x++) {
        ix_t ix = new_ix(y, x);
        world = set_w(world, ix, step_w(world, ix));
      }
    }
    world = flip_w(world);
    // printworld_w(world);
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

//
//   #define W 33
//   #define H 33
//
//   // bits bitarray[H][BITNSLOTS(W)];
//   bits bitarray[BITNSLOTSM(H, W)];
//   timer t;
//   uint32_t start;
//   uint32_t stop;
//
//   for (int i = 0; i < H; i++) {
//     for (int j = 0; j < H; j++) {
//       BITCLEARM(bitarray, i, j, H);
//     }
//   }
//
//   t :> start;
//   t :> stop;
//
//   printf("%d0\n", stop - start);
//   printf("%d, %d\n", sizeof(bits), 8);
//   // for (int i = 0, x = 0; i < 33; i++) {
//   //   for (int j = 0; j < 33; j++, x++) {
//   //     if (x % 2 == 0) {
//   //       BITSETM(bitarray, i, j, H);
//   //     }
//   //   }
//   // }
//
//   for (int i = 0; i < H; i++) {
//     for (int j = 0; j < W; j++) {
//       if (BITTESTM(bitarray, i, j, H)) {
//         BITCLEARM(bitarray, i, j, H);
//       } else {
//         BITSETM(bitarray, i, j, H);
//       }
//     }
//   }
//
//   for (int i = 0; i < 32; i++) {
//     BITCLEARM(bitarray, 0,   i,   H);
//     BITCLEARM(bitarray, i+1, 0,   H);
//     BITCLEARM(bitarray, i,   32,  H);
//     BITCLEARM(bitarray, 32,  i+1, H);
//   }
//
//   for (int i = 0; i < H; i++) {
//     for (int j = 0; j < W; j++) {
//       printf("%c", BITTESTM(bitarray, i, j, H) == 0 ? 219 : 176);
//     }
//     printf("\n");
//   }
//   BITTESTM(bitarray, 32, 32+7, H);

  // currently the program will never stop, the io thread does not support graceful shutdown

  return 0;
}
