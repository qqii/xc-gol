#ifndef _IO_H_
#define _IO_H_

#include <stdint.h>
#include <platform.h>

#include "i2c.h"

#define D0   0b0000
#define D2   0b0001
#define D1_b 0b0010
#define D1_g 0b0100
#define D1_r 0b1000

typedef enum Button {
  SW0, // no button, 15
  SW1, // 14
  SW2, // 13
} button_t;

typedef interface UIInterface {
  void     setLEDs(uint8_t pattern);  // use the DX defines with |
  button_t getButtons();
  int      getAccelerationX();
  int      getAccelerationY();
  void     startTimer();
  uint32_t getElapsedTime();          // the timer will overflow after (2^32-1)*10 ns
} ui_if;

void ui(i2c_master_if client i2c, in port b, out port p, ui_if server s);

void io(char infname[], char outfname[], chanend ch);

#endif
