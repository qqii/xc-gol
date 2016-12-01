#ifndef _IO_H_
#define _IO_H_

#include "i2c.h"
#include "pgmIO.h"

// led thread simply fowards data from channel to led
void led(out port p, streaming chanend toDist);

// orientation thread sends any tilt or untilt
void orientation(client interface i2c_master_if i2c, chanend c_ori);

// button thread sends the first sw1 and any subsiquent sw2 presses
void button(in port b, chanend c_but);

#endif
