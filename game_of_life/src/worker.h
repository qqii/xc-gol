#ifndef _WORKER_H_
#define _WORKER_H_

#include "world.h"

// worker thread for calculating the world in strips
unsafe void worker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], uint8_t wnumber, streaming chanend toDist, streaming chanend toNextWorker, streaming chanend fromLastWorker);

// thread for last worker, doesn't take a chanend toNextWorker
unsafe void lastWorker(bit (*unsafe world)[BITSLOTSP(WDHT + 4, WDWD + 4)], uint8_t wnumber, streaming chanend toDist, streaming chanend fromLastWorker);

#endif
