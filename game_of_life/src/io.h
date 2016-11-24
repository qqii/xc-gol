#include <stdint.h>

#include <platform.h>

#include "constants.h"

typedef enum Button {
  SW0, // no button, 15
  SW1, // 14
  SW2, // 13
} button_t;

const uint8_t D0   = 0b0000;
const uint8_t D2   = 0b0001;
const uint8_t D1_b = 0b0010;
const uint8_t D1_g = 0b0100;
const uint8_t D1_r = 0b1000;

typedef interface IOInterface {
  button_t getButtons();
  int getAccelerationX();
  int getAccelerationY();
  void setLEDs(uint8_t pattern);
} io_i;


void io(i2c_master_if client i2c, in port b, out port p, io_i server s) {
  i2c_regop_res_t result;
  int r;

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

  while (1) {
    select {
      case s.getButtons() -> button_t bs:
        b :> r;
        switch (r) {
          case 13:
            bs = SW2;
            break;
          case 14:
            bs = SW1;
            break;
          default:
            bs = SW0;
            break;
        }
        break;
      case s.setLEDs(uint8_t pattern):
        p <: pattern;
        break;
      case s.getAccelerationX() -> int x:
        x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);
        break;
      case s.getAccelerationY() -> int y:
        y = read_acceleration(i2c, FXOS8700EQ_OUT_Y_MSB);
        break;
    }
  }
}
