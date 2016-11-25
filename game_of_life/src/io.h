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

typedef interface UIInterface {
  int getAccelerationX();
  int getAccelerationY();
  button_t getButtons();
  void setLEDs(uint8_t pattern);
  void startTimer();
  uint32_t getElapsedTime();
} ui_if;

void ui(i2c_master_if client i2c, in port b, out port p, ui_if server s) {
  i2c_regop_res_t result;
  int r;
  timer t;
  uint32_t start = 0;

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
        // b when pinsneq(15) :> r;
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
      case s.startTimer():
        t :> start;
        break;
      case s.getElapsedTime() -> uint32_t et:
        t :> et;
        et -= start;
        break;
    }
  }
}

void io(char infname[], char outfname[], chanend ch) {
  int res;
  uint8_t line[IMWD];

  // Open PGM file
  res = _openinpgm(infname, IMWD, IMHT);
  if (res) {
    printf("DataInStream: Error openening %s\n.", infname);
    return;
  }

  // Read image line-by-line and send byte by byte to channel ch
  for (int y = 0; y < IMHT; y++) {
    _readinline(line, IMWD);
    for (int x = 0; x < IMWD; x++) {
      ch <: line[x];
    }
  }

  _closeinpgm();

  while (1) {
    // Open PGM file
    res = _openoutpgm(outfname, IMWD, IMHT);
    if (res) {
      printf("DataOutStream: Error opening %s\n.", outfname);
      return;
    }

    // Compile each line of the image and write the image line-by-line
    for (int y = 0; y < IMHT; y++) {
      for (int x = 0; x < IMWD; x++) {
        ch :> line[x];
      }
      _writeoutline(line, IMWD);
    }

    _closeoutpgm();
  }
}
