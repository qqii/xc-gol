#ifndef _WORKER_H_
#define _WORKER_H_

#include "world.h"

unsafe void worker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist, chanend toNextWorker, chanend fromLastWorker);
unsafe void lastWorker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist, chanend fromLastWorker);

#endif
