// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)
#include <stdint.h>
#include <stdio.h>
#include <platform.h>
#include <xs1.h>
#include "constants.h"
#include "io.h"
#include "world.h"

// interface ports to orientation
on tile[0]: port p_scl = XS1_PORT_1E;
on tile[0]: port p_sda = XS1_PORT_1F;
//  both of these must be on port 0
on tile[0]: in   port p_buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0]: out  port p_leds    = XS1_PORT_4F; //port to access xCore-200 LEDs


unsafe void worker(uint8_t index, streaming chanend above, streaming chanend below) {
  printf("worker[%d]: started\n", index);
  uint8_t val = 0;
  // strip of the owned world
  uint8_t world[BITNSLOTSM(WKHT + 2, WDWD + 2)];
  uint8_t (*unsafe worldp)[BITNSLOTSM(WKHT + 2, WDWD + 2)] = &world;
  uint8_t buffer[BITNSLOTSM(2, WDWD)];
  uint8_t hash[512];
  strip_t strip;
  // TODO: consider passing this in somehow
  uint32_t alivetotal;
  uint32_t alive = 0;

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

  blank_w(worldp);

  // Sync finished calculating hash
  above :> uint8_t _;
  below <: val;

  for (int i = 0; i < index; i++) {
    for (int j = 0; j < WKHT; j++) {
      below :> strip;
      above <: strip;
    }
  }
  for (int i = 0; i < WKHT; i++) {
    below :> strip;
    for (int c = 0; c < WDWD; c++) {
      set_w(worldp, i, c, isalive_s(&strip, 0, c));
    }
  }

  // loop sometime

  above :> uint8_t _;
  printworkerworld_w(worldp, 0);
  below <: val;

  while (1) {
    // sync strips
    if (index % 2 == 0) {
      // printf("worker[%d]: starting sync (above)\n", index);
      for (int c = 0; c < WDWD; c++) {
        set_s(&strip, 0, c, isalive_w(worldp, 0, c));
      }
      // printstrip_s(&strip);
      above <: strip;
      above :> strip;
      // printstrip_s(&strip);
      for (int c = 0; c < WDWD; c++) {
        set_w(worldp, -1, c, isalive_s(&strip, 0, c));
      }
      // printf("worker[%d]: synced with above\n", index);
      for (int c = 0; c < WDWD; c++) {
        set_s(&strip, 0, c, isalive_w(worldp, WKHT - 1, c));
      }
      // printstrip_s(&strip);
      below <: strip;
      below :> strip;
      // printstrip_s(&strip);
      for (int c = 0; c < WDWD; c++) {
        set_w(worldp, WKHT, c, isalive_s(&strip, 0, c));
      }
      // printf("worker[%d]: synced with below\n", index);
    } else {
      // printf("worker[%d]: starting sync (below)\n", index);
      below :> strip;
      // printstrip_s(&strip);
      for (int c = 0; c < WDWD; c++) {
        set_w(worldp, WKHT, c, isalive_s(&strip, 0, c));
      }
      for (int c = 0; c < WDWD; c++) {
        set_s(&strip, 0, c, isalive_w(worldp, WKHT - 1, c));
      }
      // printstrip_s(&strip);
      below <: strip;
      // printf("worker[%d]: synced with below\n", index);
      above :> strip;
      // printstrip_s(&strip);
      for (int c = 0; c < WDWD; c++) {
        set_w(worldp, -1, c, isalive_s(&strip, 0, c));
      }
      for (int c = 0; c < WDWD; c++) {
        set_s(&strip, 0, c, isalive_w(worldp, 0, c));
      }
      // printstrip_s(&strip);
      above <: strip;
      // printf("worker[%d]: synced with above\n", index);
    }

    // wrap
    for (int i = -1; i < WKHT + 1; i++) {
      set_w(worldp, i,   -1, isalive_w(worldp, i, WDWD - 1));
      set_w(worldp, i, WDWD, isalive_w(worldp, i,        0));
    }

    alive = 0;
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
    for (int r = 1; r < WKHT; r++) {
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
      set_w(worldp, WKHT - 1, c, BITTESTM(buffer, (WKHT - 1) % 2, c, WDWD));
    }

    above :> alivetotal;
    alivetotal += alive;
    // printworkerworld_w(worldp, 0);
    below <: alivetotal;
  }

  printf("worker[%d]: finished\n", index);
}

unsafe void distributor(chanend ori, chanend but, streaming chanend above, streaming chanend below) {
  uint8_t val = 0;
  uint32_t alive = 0;
  strip_t strip;
  // timer that overflows after (2^32-1)*10ns
  timer t;
  uint32_t start = 0;
  uint32_t stop = 0;
  intmax_t i;

  below <: val;
  above :> uint8_t _;

  printf("distributor: all workers have finished calculating hash\n");

  printf("%s -> %s\n%dx%d -> %dx%d\nPress SW1 to load...\n", FILENAME_IN, FILENAME_OUT, IMHT, IMWD, WDHT, WDWD);

  // wait for SW1
  but :> uint8_t _;
  p_leds <: D1_g;

  if (_openinpgm(FILENAME_IN, IMWD, IMHT)) {
    printf("Error openening %s for reading.\n.", FILENAME_IN);
    printf("Defaulting to a blank (or hardcoded) world...\n.");
  } else {
    // Read image line-by-line and send byte by byte to channel ch
    uint8_t line[IMWD]; // read in storage

    for (int r = 0; r < IMHT; r++) {
      _readinline(line, IMWD);
      for (int c = 0; c < IMWD; c++) {
        set_s(&strip, 0, c, line[c]);
        alive += line[c] & 1;
      }
      // printstrip_s(&strip);
      above <: strip;
    }
  }
  _closeinpgm();


  below <: val;
  above :> uint8_t _;
  printf("distributor: starting...\n");

  t :> start;
  for (i = 0; i < ITERATIONS;) {
    select {
      case below :> strip:
        above <: strip;
        above :> strip;
        below <: strip;

        alive = 0;
        below <: alive;
        above :> alive;
        i++;
        switch (i % 2) {
          case 0:
          p_leds <: D0;
          break;
          case 1:
          p_leds <: D2;
          break;
        }
        break;
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
        // printworld_w(worldp);
        // // SAVE
        // if (_openinpgm(FILENAME_IN, WDWD, WDHT)) {
        //   printf("Error opening %s for saving.\n.", FILENAME_OUT);
        //   printf("Skipping save...\n.");
        // } else {
        //   uint8_t line[WDWD]; // read in storage
        //   for (int r = 0; r < WDHT; r++) {
        //     for (int c = 0; c < WDWD; c++) {
        //       if (isalive_w(worldp, r, c)) {
        //         line[c] = ~0;
        //       } else {
        //         line[c] = 0;
        //       }
        //     }
        //     _writeoutline(line, WDWD);
        //   }
        // }
        // _closeoutpgm();
        break;
    }
  }
  t :> stop;
  printf("Iteration: %llu\t", i);
  printf("Elapsed Time (ns): %lu0\t", stop - start);
  printf("Alive Cells: %d\n", alive);
}

// Orchestrate concurrent system and start up all threads
unsafe int main(void) {
  i2c_master_if i2c[1]; //interface to orientation
  chan c_ori, c_but;    // channels for io actions
  streaming chan c_wor[WORKERS + 1];

  par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10); // server thread providing orientation data
    on tile[0]: orientation(i2c[0], c_ori);
    on tile[0]: button(p_buttons, c_but);
    // on tile[0]: distributor(c_ori, c_but);
    on tile[0]: distributor(c_ori, c_but, c_wor[WORKERS], c_wor[0]); // thread to coordinate work on image
    par (uint8_t i = 0; i < WORKERS; i++) {
      on tile[1]: worker(i, c_wor[i], c_wor[i+1]);
    }
  }

  // currently the program will never stop, the io thread does not support graceful shutdown
  return 0;
}
