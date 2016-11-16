#ifndef _TIMING_H_
#define _TIMING_H_

#include <stdint.h>
#include <stdio.h>

#include <platform.h>

typedef enum Timing {
  START,
  STOP,
  SHUTDOWN,
} timing_t;

void timing(chanend ch) {
  uint8_t running = 1;
  timing_t mess;

  timer t;
  uint32_t start = 0;
  uint32_t stop = 0;

  while (running) {
    ch :> mess;
    switch (mess) {
      case SHUTDOWN:
        running = 0;
        break;
      case START:
        t :> start;
        break;
      case STOP:
        t :> stop;
        printf("********************************\n%010lu0ns\n********************************\n", (stop - start));
        break;
    }
  }
}

#endif
