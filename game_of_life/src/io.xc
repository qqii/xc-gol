#include "io.h"

#include <stdint.h>
#include <stdio.h>
#include <xs1.h>
#include "i2c.h"
#include "constants.h"

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
