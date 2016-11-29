// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

#include <platform.h>
#include <xs1.h>

#include "i2c.h"
#include "pgmIO.h"

#include "constants.h"
#include "world.h"
#include "timing.h"

char hamming[256] = {
  0,1,1,2,1,2,2,3,1,2,
  2,3,2,3,3,4,1,2,2,3,
  2,3,3,4,2,3,3,4,3,4,
  4,5,1,2,2,3,2,3,3,4,
  2,3,3,4,3,4,4,5,2,3,
  3,4,3,4,4,5,3,4,4,5,
  4,5,5,6,1,2,2,3,2,3,
  3,4,2,3,3,4,3,4,4,5,
  2,3,3,4,3,4,4,5,3,4,
  4,5,4,5,5,6,2,3,3,4,
  3,4,4,5,3,4,4,5,4,5,
  5,6,3,4,4,5,4,5,5,6,
  4,5,5,6,5,6,6,7,1,2,
  2,3,2,3,3,4,2,3,3,4,
  3,4,4,5,2,3,3,4,3,4,
  4,5,3,4,4,5,4,5,5,6,
  2,3,3,4,3,4,4,5,3,4,
  4,5,4,5,5,6,3,4,4,5,
  4,5,5,6,4,5,5,6,5,6,
  6,7,2,3,3,4,3,4,4,5,
  3,4,4,5,4,5,5,6,3,4,
  4,5,4,5,5,6,4,5,5,6,
  5,6,6,7,3,4,4,5,4,5,
  5,6,4,5,5,6,5,6,6,7,
  4,5,5,6,5,6,6,7,5,6,
  6,7,6,7,7,8
  };

on tile[0]: port p_scl = XS1_PORT_1E;         //interface ports to orientation
on tile[0]: port p_sda = XS1_PORT_1F;
on tile[0]: in   port p_buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[1]: out  port p_leds    = XS1_PORT_4F; //port to access xCore-200 LEDs

#define FXOS8700EQ_I2C_ADDR 0x1E  //register addresses for orientation
#define FXOS8700EQ_XYZ_DATA_CFG_REG 0x0E
#define FXOS8700EQ_CTRL_REG_1 0x2A
#define FXOS8700EQ_DR_STATUS 0x0
#define FXOS8700EQ_OUT_X_MSB 0x1
#define FXOS8700EQ_OUT_X_LSB 0x2
#define FXOS8700EQ_OUT_Y_MSB 0x3
#define FXOS8700EQ_OUT_Y_LSB 0x4
#define FXOS8700EQ_OUT_Z_MSB 0x5
#define FXOS8700EQ_OUT_Z_LSB 0x6

/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from PGM file from path infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataInStream(chanend c_out)
{
  int res;
  uint8_t line[IMWD];
  printf("DataInStream: Start...\n");

  // Open PGM file
  res = _openinpgm(FILENAME_IN, IMWD, IMHT);
  if (res) {
    printf("DataInStream: Error openening %s\n.", FILENAME_IN);
    return;
  }

  // Read image line-by-line and send byte by byte to channel c_out
  for (int y = 0; y < IMHT; y++) {
    _readinline(line, IMWD);
    for (int x = 0; x < IMWD; x++) {
      c_out <: line[x];
      // printf( "-%4.1d ", line[ x ] ); //show image values
    }
    // printf( "\n" );
  }

  // Close PGM image file
  _closeinpgm();
  // printf( "DataInStream: Done...\n" );
  return;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Start your implementation by changing this function to implement the game of life
// by farming out parts of the image to worker threads who implement it...
// Currently the function just inverts the image

void button(in port b, chanend toDist) {
  uint8_t val;
  // detect sw1 one time
  while (1) {
    b when pinseq(15)  :> val;
    b when pinsneq(15) :> val;
    if (val == SW1) {
      toDist <: val;
      break;
    }
  }
  // detect subsiquent sw2
  while (1) {
    b when pinseq(15)  :> val;    // check that no button is pressed
    b when pinsneq(15) :> val;    // check if some buttons are pressed
    if (val == SW2) {
      toDist <: val;
    }
  }
}


//prints stuff
unsafe void print_world(char (*unsafe array)[IMWD / 8][IMHT], unsigned char (*unsafe counts)[IMHT], uint16_t (*unsafe workers)[WCOUNT]) {
  char* alive = "◼";
  char* dead = "◻"; // to 178
  unsigned char nextWorker = 0;

  printf("world: %dx%d\n", IMWD, IMHT);
  for (int r = 0; r < IMHT; r++) {
    for (int c = 0; c < IMWD/8; c++) {
      printf("%s %s %s %s %s %s %s %s ", (*array)[c][r] & 0b10000000 ? alive : dead,
                                 (*array)[c][r] & 0b01000000 ? alive : dead,
                                 (*array)[c][r] & 0b00100000 ? alive : dead,
                                 (*array)[c][r] & 0b00010000 ? alive : dead,
                                 (*array)[c][r] & 0b00001000 ? alive : dead,
                                 (*array)[c][r] & 0b00000100 ? alive : dead,
                                 (*array)[c][r] & 0b00000010 ? alive : dead,
                                 (*array)[c][r] & 0b00000001 ? alive : dead);
    }
    if ((*workers)[nextWorker] == r){
      printf(" %u - Worker %u\n", (*counts)[r], nextWorker);
      nextWorker++;
    }
    else{
      printf(" %u\n", (*counts)[r]);
    }
  }

  for(int I = nextWorker; I < WCOUNT; I++){
    printf("Worker %d not working (starting at %d)\n", I, (*workers)[I]);
  }
}

unsigned char gol(unsigned char surr){ 
  unsigned char count = 0; 
  while (surr != 0){ 
    surr = surr & (surr - 1); 
    count += 1; 
  } 
  return count; 
}

//returns whether a given cell will be alive. Takes absolute XY coordianates
unsafe unsigned char update(char (*unsafe array)[IMWD / 8][IMHT], uint16_t cellw, uint16_t cellh, char cellwp){
  unsigned char data = 0;
  unsigned char alive = 0;
  unsigned char self = ((*array)[cellw][cellh] & (1 << cellwp)) >> cellwp;
  unsigned char cellwpminus = cellwp - 1;

  uint16_t cellright = cellw + 1;
  uint16_t cellLeft = cellw - 1;

  uint16_t cellBelow = cellh + 1;
  uint16_t cellAbove = cellh - 1;

  if (cellw == (IMWD / 8) - 1){
    cellright = 0;
  }
  if (cellw == 0){
    cellLeft = (IMWD / 8) - 1;
  }

  if (cellh == IMHT - 1){
    cellBelow = 0;
  }
  if (cellh == 0){
    cellAbove = IMHT - 1;
  }

  
  if (cellwp == 0){ 
    //we're on the right hand border of a char
    data =      ((((*array)[cellw][cellAbove]       &   (3)                   )   << 1)        )              | //row above 
                ((((*array)[cellw][cellBelow]       &   (3)                   )   << 4)        )              | //row below 
                ((((*array)[cellw][cellh]           &   (2)                   )   << 6)        )              | //to the left
                ((((*array)[cellright][cellAbove]   &   (128)                 )       )    >> 7)              | //above and right
                ((((*array)[cellright][cellBelow]   &   (128)                 )   << 3)    >> 7)              | //below and right
                ((((*array)[cellright][cellh]       &   (128)                 )   << 6)    >> 7)              ; //mid and right
  } 
  else if (cellwp == 7){ 
    //or we're on the left hand side
    data =      ((((*array)[cellw][cellAbove]       &   (192                 ))       )    >> 6)              | //row above 
                ((((*array)[cellw][cellBelow]       &   (192                 ))   << 3)    >> 6)              | //row below 
                ((((*array)[cellw][cellh]           &   (64                  ))   << 6)    >> 6)              | //to the right 
                ((((*array)[cellLeft][cellAbove]    &   (1)                  ))   << 2)                       | //above and left 
                ((((*array)[cellLeft][cellBelow]    &   (1)                  ))   << 5)                       | //below and left
                ((((*array)[cellLeft][cellh]        &   (1)                  ))   << 7)                       ; //mid and left
  } 
  else{
    //bit wizardry
    //or we're in the middle 
    data =      ((((*array)[cellw][cellAbove]       &   (7 << (cellwpminus)  ))       )    >> cellwpminus)    | //row above 
                ((((*array)[cellw][cellBelow]       &   (7 << (cellwpminus)  ))   << 3)    >> cellwpminus)    | //row below 
                ((((*array)[cellw][cellh]           &   (2 << (cellwp)       ))   << 6)    >> cellwp)         |  //to the left 
                ((((*array)[cellw][cellh]           &   (1 << (cellwpminus)  ))   << 6)    >> cellwpminus)    ; //to the right 
  }

  alive = hamming[data];
  
  return alive == 3 || (alive == 2 && self);
}

unsafe void worker(char (*unsafe strips)[IMWD / 8][IMHT], char wnumber, char *unsafe fstart,
 char *unsafe fpause, char (*unsafe ffinshed)[WCOUNT], char *unsafe fstop,
 uint16_t (*unsafe startRows)[WCOUNT], unsigned char (*unsafe rowCounts)[IMHT]){

  uint16_t startRow;
  uint16_t endRow;

  uint16_t wset_mid = 0;
  unsigned char firstRow[IMWD / 8];
  unsigned char wset[IMWD / 8][2];
  int iteration = 0;

  uint16_t countQueue[2];
  uint16_t firstCount;
  unsigned char countQueueMid = 0;

  uint16_t amount = 0;
  (*ffinshed)[wnumber] = 0;

  while (!*fstart){
  }

  while(!*fstop){
    startRow = (*startRows)[wnumber];
    //see if our worker is even in use
    if (startRow != IMHT){

      //set the end row
      if (wnumber == WCOUNT - 1){
          endRow = IMHT;
      }
      else{
          endRow = (*startRows)[wnumber + 1];
      }

      //iterate through the rows
      for (uint16_t J = startRow; J < endRow; J++){

        //see if we can cheat
        if (iteration != 0 && (*rowCounts)[J] == 0){
          amount = 0;
          if (J == startRow){
            for(int R = 0; R < (IMWD / 8); R++){
              firstRow[R] = 0;
            }        
          }
          else{
            for(int R = 0; R < (IMWD / 8); R++){
              wset[R][wset_mid] = 0;
            }        
          }
        }
        //else do it properly
        else{
          amount = 0;
          for(uint16_t I = 0; I < (IMWD / 8); I++){
            unsigned char data = 0;
            for(int8_t W = 0; W < 8; W++){
              unsigned char cell = update(strips,I, J, W);
              data = data | cell << (7 - W);
              amount = amount + cell;
            }

            //update how many alive cells each row has
            // (*rowCounts)[J] = amount;

            //store the first row out of the way
            if (J == startRow){
              firstRow[I] = data;
            }
            //write to the working set
            else{
              wset[I][wset_mid] = data;
            }
          }
        }
        if (amount > 0){
          if (J == startRow){
            firstCount = 2;
          }
          //write to the working set
          else{
            countQueue[wset_mid] = 2;
          }
        }
        else{
          if (J == startRow){
            firstCount = 0;
          }
          //write to the working set
          else{
            countQueue[wset_mid] = 0;
          }
        }
        //update which row in the working set is current
        //Don't need to do it the first time because we haven't used it
        if (J > startRow){
          wset_mid = (wset_mid + 1) % 2;
        }
        
        // write back the working set to the array, except the first and last rows
        if (J > startRow + 1){
          for(uint16_t L = 0; L < IMWD / 8; L++){
            (*strips)[L][J - 1] = wset[L][wset_mid];
            (*rowCounts)[J - 1] = countQueue[wset_mid];
          }
        }
      }
      //say we've finished
      (*ffinshed)[wnumber] = 1;

      //wait until the previous worker has finished
      //SCREW PMOD
      if (wnumber == 0){
          while(!(*ffinshed)[WCOUNT - 1]){
          }
        }
        else{
          while(!(*ffinshed)[wnumber - 1]){
          }
        }

      //write the first and last rows
      //last could be written back earlier but whatever
      wset_mid = (wset_mid + 1) % 2;
      countQueueMid = (countQueueMid + 1) % 2;
      for(int I = 0; I < IMWD / 8; I++){
        (*strips)[I][endRow - 1] = wset[I][wset_mid];
        (*strips)[I][startRow] = firstRow[I];
      }
      (*rowCounts)[endRow - 1] = countQueue[wset_mid];
      (*rowCounts)[startRow] = firstCount;
    }
    else{
      (*ffinshed)[wnumber] = 1;
    }

    //reset the working set pointer
    //not sure if this actually need to happen
    wset_mid = 0;

    iteration++;

    //wait until the coordinator gives the go ahead for another round
    while((*ffinshed)[wnumber] || *fpause){
    }
  }
}


unsafe void distributor(chanend c_in, chanend c_out, chanend ori, chanend c_timing, chanend but)
{
  //data structure and flags
  char array[IMWD / 8][IMHT];
  char fstart = 0;
  char fpause = 1;
  char ffinshed[WCOUNT];
  char fstop = 0;
  uint16_t startRows[WCOUNT];
  unsigned char rowCounts[IMHT];

  timer t;
  uint32_t start;
  uint32_t stop;

  char val;
  uint8_t D1 = 1; // green flash state

  for (int I = 0; I < IMHT; I++){
    rowCounts[I] = 0;
  }

  //unsafe pointers, eeek
  char (*unsafe array_p)[IMWD / 8][IMHT] = &array;
  char volatile *unsafe fstart_p = &fstart;
  char *unsafe fpause_p = &fpause;
  char (*unsafe ffinshed_p)[WCOUNT] = &ffinshed;
  char *unsafe fstop_p = &fstop;
  uint16_t (*unsafe startRows_p)[WCOUNT] = &startRows; 
  unsigned char (*unsafe rowCounts_p)[IMHT] = &rowCounts;

  for(int I = 0; I < WCOUNT; I++){
    startRows[I] = I * IMHT / WCOUNT;
  }

  //Starting up and wait for tilting of the xCore-200 Explorer
  printf( "ProcessImage: Start, size = %dx%d\n", IMHT, IMWD );

  par{
    //create all the workers, and do some stuff as well in a sequential block
    worker(array_p, 0, fstart_p, fpause_p, ffinshed_p, fstop_p, startRows_p, rowCounts_p);
    worker(array_p, 1, fstart_p, fpause_p, ffinshed_p, fstop_p, startRows_p, rowCounts_p);
    worker(array_p, 2, fstart_p, fpause_p, ffinshed_p, fstop_p, startRows_p, rowCounts_p);
    worker(array_p, 3, fstart_p, fpause_p, ffinshed_p, fstop_p, startRows_p, rowCounts_p);
    worker(array_p, 4, fstart_p, fpause_p, ffinshed_p, fstop_p, startRows_p, rowCounts_p);
    worker(array_p, 5, fstart_p, fpause_p, ffinshed_p, fstop_p, startRows_p, rowCounts_p);
    worker(array_p, 6, fstart_p, fpause_p, ffinshed_p, fstop_p, startRows_p, rowCounts_p);
    {
      printf("Waiting for button press\n");
      but :> val;
      p_leds <: D2;
      printf( "Loading...\n" );
      for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD / 8; x++ ) { //go through each pixel per line
          unsigned char number = 0;
          for( int w = 7; w >= 0; w--){ //go through all bits in a byte
            unsigned char input = 0;
            c_in :> input;
            //bit wizardry (lite)
            number = number | ((input/255) << w);
          }
          array[x][y] = number;
        }
      }
      print_world(array_p, rowCounts_p, startRows_p);

      c_timing <: START;

      // printf("Loading Complete\n");
      *fstart_p = 1;

      //do iterations. This handles all but the last one
      //when ITERATIONS == 1 this doesn't get run
      for(int I = 1; I < ITERATIONS; I++){
        select {
          case ori :> val:
            t :> stop;
            p_leds <: D1_r;
            printf("Iteration: %llu\t", I);
            printf("Elapsed Time (ns): %lu0\t", stop - start);
            // printf("Alive Cells: %d\n", alive);
            ori :> val;
            break;
          case but :> val:
            p_leds <: D1_b;
            print_world(array_p, rowCounts_p, startRows_p);
            // SAVE
            for( int y = 0; y < IMHT; y++ ) {   //go through all lines
              for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
                unsigned char output = 255 * (((*array_p)[x/8][y] & (1 << (7 - x%8))) >> (7 - x%8));
                c_out <: (output);
              }
    
            }
            break;
          default:
            switch (D1) {
              case 0:
                p_leds <: D0;
                D1 = 1;
                break;
              case 1:
                p_leds <: D1_g;
                D1 = 0;
                break;
            }
            break;
        }
        int nfinished = 0;
        while (nfinished < WCOUNT){
          //wait until they're all finished
          nfinished = 0;
          for(int J = 0; J < WCOUNT; J++){
            nfinished += ffinshed[J];
          }
        }
        //handbrake on
        fpause = 1;

        //update the rows count to include nearby rows
        uint16_t totalRows = 0;

        // update the row counts to mark adjacent rows
        //do the top row

        for (int R = 0; R < IMHT; R++){
          if (rowCounts[R] > 1){
            rowCounts[(R + 1) % IMHT] += 1;
            rowCounts[((R - 1) % IMHT + IMHT) % IMHT] += 1;
          }
        }

        for (int R = 0; R < IMHT; R++){
          if (rowCounts[R] > 0){
            totalRows++;
            rowCounts[R] = 1;
          }
        }

        //start of load balancing calculations
        uint16_t currentCount = 0;
        unsigned char currentWorker = 1;



        //scan through until we hit the average and assign a worker
        //each time we do
        for(int R = 1; R < IMHT; R++){
          currentCount = currentCount + rowCounts[R];
          if (totalRows / WCOUNT == 0){
            if (currentCount > ((totalRows) / WCOUNT)){
              startRows[currentWorker] = R;
              currentWorker++;
              currentCount = 0;
            }
          }
          else{
            if (currentCount > ((totalRows + WCOUNT - 1) / WCOUNT)){
              startRows[currentWorker] = R;
              currentWorker++;
              currentCount = 0;
            }
          }
        }

        //assign any workers we didn't do yet
        if(currentWorker < WCOUNT){
          for(int W = currentWorker; W < WCOUNT; W++){
            if (startRows[W - 1] + (WCOUNT - W) > IMHT - 1){
              //if we've run out of space just tell the workers to miss this round
              startRows[W] = IMHT;
            }
            else{
              startRows[W] = startRows[W - 1] + (WCOUNT - W);
            }
          }
        }


        //unset the finished flags for all of them
        //so that they all go at the same time
        for(int J = 0; J < WCOUNT; J++){
          (*ffinshed_p)[J] = 0;
        }
        fpause = 0;

        //print sometimes, but rarely because it's super slow
        if (I % 1000 == 0){
          // printf("Finished iteration %d\n", I);
        }
      }

      //check that they're all finished for the last iteration
      int nfinished = 0;
      while (nfinished < WCOUNT){
        nfinished = 0;
        for(int J = 0; J < WCOUNT; J++){
          nfinished += ffinshed[J];
        }
      }

      c_timing <: STOP;
      // printf("Finished last iteration\n");

      c_timing <: SHUTDOWN;
      //this will actually gracefully shut them down
      fstop = 1;

      //write the output to the writer thread
      print_world(array_p, rowCounts_p, startRows_p);
      for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
          unsigned char output = 255 * (((*array_p)[x/8][y] & (1 << (7 - x%8))) >> (7 - x%8));
          c_out <: (output);
        }
      }
    }

  }
}

///////////////////////////////////////////////////////////////////////////////////////
// Write pixel stream from channel c_in to PGM image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream(chanend c_in) {
  int res;
  uint8_t line[IMWD];

  // Open PGM file
  printf("DataOutStream: Start...\n");
  res = _openoutpgm(FILENAME_OUT, IMWD, IMHT);
  if (res) {
    printf("DataOutStream: Error opening %s\n.", FILENAME_OUT);
    return;
  }

  //Compile each line of the image and write the image line-by-line
  for( int y = 0; y < IMHT; y++ ) {
    for( int x = 0; x < IMWD; x++ ) {
      c_in :> line[ x ];
      //printf( "-%4.1d ", line[ x ] ); //show image values
    }

    _writeoutline( line, IMWD );
    //printf( "\n" );
  }

  // Close the PGM image
  _closeoutpgm();
  printf("DataOutStream: Done...\n");
  return;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Initialise and  read orientation, send first tilt event to channel
//
/////////////////////////////////////////////////////////////////////////////////////////
void orientation(client interface i2c_master_if i2c, chanend toDist) {
  i2c_regop_res_t result;
  char status_data = 0;
  int tilted = 0;

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

  // Probe the orientation x-axis forever
  while (1) {
    // check until new orientation data is available
    do {
      status_data =
          i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
    } while (!status_data & 0x08);

    // get new x-axis tilt value
    int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);

    // send signal to distributor after first tilt
    if (!tilted) {
      if (x > 30) {
        tilted = 1 - tilted;
        toDist <: 1;
      }
    }
  }
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Orchestrate concurrent system and start up all threads
//
/////////////////////////////////////////////////////////////////////////////////////////
unsafe int main(void) {

  i2c_master_if i2c[1];               //interface to orientation

  chan c_inIO, c_outIO, c_control, c_timing;    //extend your channel definitions here
  chan c_but;            // io channel

  par {
    on tile[1]: distributor(c_inIO, c_outIO, c_control, c_timing, c_but);//thread to coordinate work on image
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing orientation data
    on tile[0]: orientation(i2c[0],c_control);        //client thread reading orientation data
    on tile[0]: DataInStream(c_inIO);          //thread to read in a PGM image
    on tile[0]: DataOutStream(c_outIO);       //thread to write out a PGM image
    on tile[0]: timing(c_timing);
    on tile[0]: button(p_buttons, c_but);
  }

  return 0;
}
