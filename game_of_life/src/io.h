#ifndef _IO_H_
#define _IO_H_

#include <platform.h>
#include "i2c.h"
#include "pgmIO.h"

void orientation(client interface i2c_master_if i2c, chanend toDist);
void button(in port b, chanend toDist);

#endif
