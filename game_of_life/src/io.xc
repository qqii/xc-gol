#include "io.h"

#include <stdint.h>
#include <stdio.h>
#include <platform.h>
#include "constants.h"

void led(out port p, streaming chanend toDist) {
  int val;

  while (1) {
    // simply fowards data from channel to led
    toDist :> val;
    p <: val;
  }
}

void orientation(client interface i2c_master_if i2c, chanend c_ori) {
  i2c_regop_res_t result;
  uint8_t status_data = 0;
  uint8_t tilted = 0;

  // Configure FXOS8700EQ
  result =
      i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
  if (i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01) != I2C_REGOP_SUCCESS) {
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

// currently if you hold down the button, it doesn't count that as a continuous
// press, this can be changed by removing the when clauses
void button(in port b, chanend c_but) {
  uint8_t val;

  // detect sw1 press one time
  while (1) {
    b when pinseq(15)  :> void;
    b when pinsneq(15) :> val;
    if (val == SW1) {
      c_but <: val;
      break;
    }
  }

  // detect subsiquent sw2 presses forever
  while (1) {
    b when pinseq(15)  :> void;   // check that no button is pressed
    b when pinsneq(15) :> val;    // check if some buttons are pressed
    if (val == SW2) {
      c_but <: val;
    }
  }
}
