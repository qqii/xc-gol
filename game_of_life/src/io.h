#ifndef _IO_H_
#define _IO_H_

#include <stdint.h>
#include <platform.h>

#include "i2c.h"

// constants for LEDs for setLEDs function
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
  int      getAccelerationX();        // getAcceleration will return a number between -180 and 180
  int      getAccelerationY();
  void     startTimer();              // subsiquent calls to startTimer will simply reset the timer
  uint32_t getElapsedTime();          // the timer will overflow after (2^32-1)*10 ns
} ui_if;

// thread for hw button, led and tilt sensor
void ui(i2c_master_if client i2c, in port button, out port led, ui_if server interf);

// thread for reading and writing the pgm
void io(char infname[], char outfname[], chanend ch);

#endif
