#ifndef _WORKER_H_
#define _WORKER_H_

#include "world.h"

// worker thread for calculating the world in strips
unsafe void worker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist, chanend toNextWorker, chanend fromLastWorker);

// thread for last worker, doesn't take a chanend toNextWorker
unsafe void lastWorker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], int wnumber, chanend toDist, chanend fromLastWorker);

#endif
