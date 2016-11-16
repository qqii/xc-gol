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

on tile[0]: port p_scl = XS1_PORT_1E;         //interface ports to orientation
on tile[0]: port p_sda = XS1_PORT_1F;

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
      printf( "-%4.1d ", line[ x ] ); //show image values
    }
    printf( "\n" );
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
uint16_t pmod(uint16_t i, uint16_t n) {
  return (i % n + n) % n;
}

//gets the value at an absolute XY coordianate
unsafe unsigned char getVal(char (*unsafe array)[IMWD / 8][IMHT], int x, int y){
  uint16_t cellw = pmod (x, IMWD) / 8;
  char cellwp = 7 - (pmod (x, IMWD) % 8);
  uint16_t cellh = pmod(y, IMHT);
  return ((*array)[cellw][cellh] & (1<< cellwp)) >> cellwp;
}

//prints stuff
unsafe void print_world(char (*unsafe array)[IMWD / 8][IMHT]) {
  char alive = 219;
  char dead = 176; // to 178

  printf("world: %dx%d\n", IMWD, IMHT);
  for (int r = 0; r < IMHT; r++) {
    for (int c = 0; c < IMWD/8; c++) {
      printf("%c%c%c%c%c%c%c%c", (*array)[c][r] & 0b10000000 ? alive : dead,
                                 (*array)[c][r] & 0b01000000 ? alive : dead,
                                 (*array)[c][r] & 0b00100000 ? alive : dead,
                                 (*array)[c][r] & 0b00010000 ? alive : dead,
                                 (*array)[c][r] & 0b00001000 ? alive : dead,
                                 (*array)[c][r] & 0b00000100 ? alive : dead,
                                 (*array)[c][r] & 0b00000010 ? alive : dead,
                                 (*array)[c][r] & 0b00000001 ? alive : dead);
    }
    printf("\n");
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
unsafe unsigned char update(char (*unsafe array)[IMWD / 8][IMHT], int x, int y){
  unsigned char data = 0;
  unsigned char alive = 0;
  uint16_t cellw = pmod (x, IMWD) / 8;
  char cellwp = 7 - (pmod (x, IMWD) % 8);
  uint16_t cellh = pmod(y, IMHT);
  unsigned char self = getVal(array, x, y);

  uint16_t cellright = pmod(cellw + 1, IMWD/8);
  uint16_t cellLeft = pmod(cellw - 1, IMWD/8);

  uint16_t cellBelow = pmod(cellh + 1, IMHT);
  uint16_t cellAbove = pmod(cellh - 1, IMHT);
  
  if (cellwp == 0){ 
    data = (((*array)[cellw][cellAbove] & (6>>(1))) << (1)) | //row above 
                ((8*((*array)[cellw][cellBelow] & (6>>(1)))) << (1)) | //row below 
                ((64*((*array)[cellw][cellh] & (4>>(1))))) | //left and right
                ((1*((*array)[cellright][cellAbove] & 128)) >> 7) |
                ((8*((*array)[cellright][cellBelow] & 128)) >> 7) |
                ((64*((*array)[cellright][cellh] & 128)) >> 7) ;
  } 
  else if (cellwp == 7){ 
    data = (((*array)[cellw][cellAbove] & (3<<(cellwp - 1))) >> (cellwp - 1)) | //row above 
                ((8*((*array)[cellw][cellBelow] & (3<<(cellwp - 1)))) >> (cellwp - 1)) | //row below 
                ((64*((*array)[cellw][cellh] & (1<<(cellwp - 1))) >> (cellwp - 1))) | //to the left and right 
                ((4*((*array)[cellLeft][cellAbove] & 1))) |
                ((32*((*array)[cellLeft][cellBelow] & 1))) |
                ((128*((*array)[cellLeft][cellh] & 1))) ;
  } 
  else{ 
    //bit wizardry 
    data = (((*array)[cellw][cellAbove] & (7<<(cellwp - 1))) >> (cellwp - 1)) | //row above 
                ((8*((*array)[cellw][cellBelow] & (7<<(cellwp - 1)))) >> (cellwp - 1)) | //row below 
                ((64*((*array)[cellw][cellh] & (2<<(cellwp)))) >> (cellwp)) |  //to the left 
                ((64*((*array)[cellw][cellh] & (1<<(cellwp - 1)))) >> (cellwp - 1)); //to the right 
  }

  alive = gol(data);
  // if (alive > 0){
  //   printf("%d,%d has %d live neighbours at %d\n", x, y, alive, data);
  // }
  
  if (self && alive < 2){
    return 0;
  }
  else if (self && (alive == 2 || alive == 3)){
    return 1;
  }
  else if (self && alive > 3){
    return 0;
  }
  else if (!self && alive == 3){
    return 1;
  }
  else{
    return 0;
  }
}


unsafe void worker(char (*unsafe strips)[IMWD / 8][IMHT], char wnumber, char *unsafe fstart, char *unsafe fpause, char (*unsafe ffinshed)[WCOUNT], char *unsafe fstop){
  uint16_t startRow = wnumber * IMHT / WCOUNT;
  uint16_t endRow = (wnumber + 1) * IMHT / WCOUNT;
  if (wnumber == (WCOUNT - 1)){
    endRow = IMHT;
  }

  uint16_t wset_mid = 0;
  unsigned char firstRow[IMWD / 8];
  unsigned char wset[IMWD / 8][2];
  int iteration = 0;

  (*ffinshed)[wnumber] = 0;

  while (!*fstart){
  }

  while(!*fstop){
    for (uint16_t J = startRow; J <= endRow; J++){
      for(uint16_t I = 0; I < (IMWD / 8); I++){
        unsigned char data = 0;
        for(int8_t W = 0; W < 8; W++){
          unsigned char cell = update(strips, 8 * I + W, J);
          data = data | cell << (7 - W);
        }
        //store the first row out of the way
        if (J == startRow){
          firstRow[I] = data;
        }
        //write to the working set
        else{
          wset[I][wset_mid] = data;
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
        }
      }
    }
    //say we've finished
    (*ffinshed)[wnumber] = 1;

    //wait until the previous worker finishes so we can put in the first row
    while(!(*ffinshed)[pmod(wnumber - 1, WCOUNT)]){
    }

    //write the first and last rows
    //last could be written back earlier but whatever
    for(int I = 0; I < IMWD / 8; I++){
      (*strips)[I][endRow - 1] = wset[I][wset_mid];
      (*strips)[I][startRow] = firstRow[I];
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

unsafe void distributor(chanend c_in, chanend c_out, chanend fromAcc, chanend c_timing)
{
  //data structure and flags
  char array[IMWD / 8][IMHT];
  char fstart = 0;
  char fpause = 1;
  char ffinshed[WCOUNT];
  char fstop = 0;

  //unsafe pointers, eeek
  char (*unsafe array_p)[IMWD / 8][IMHT] = &array;
  char *unsafe fstart_p = &fstart;
  char *unsafe fpause_p = &fpause;
  char (*unsafe ffinshed_p)[WCOUNT] = &ffinshed;
  char *unsafe fstop_p = &fstop;

  //Starting up and wait for tilting of the xCore-200 Explorer
  printf( "ProcessImage: Start, size = %dx%d\n", IMHT, IMWD );

  par{
    //create all the workers, and do some stuff as well in a sequential block
    worker(array_p, 0, fstart_p, fpause_p, ffinshed_p, fstop_p);
    worker(array_p, 1, fstart_p, fpause_p, ffinshed_p, fstop_p);
    worker(array_p, 2, fstart_p, fpause_p, ffinshed_p, fstop_p);
    worker(array_p, 3, fstart_p, fpause_p, ffinshed_p, fstop_p);
    worker(array_p, 4, fstart_p, fpause_p, ffinshed_p, fstop_p);
    worker(array_p, 5, fstart_p, fpause_p, ffinshed_p, fstop_p);
    worker(array_p, 6, fstart_p, fpause_p, ffinshed_p, fstop_p);
    {
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
      print_world(array_p);

      c_timing <: START;

      // printf("Loading Complete\n");
      *fstart_p = 1;

      //do iterations. This handles all but the last one
      //when ITERATIONS == 1 this doesn't get run
      for(int I = 1; I < ITERATIONS; I++){
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
      print_world(array_p);
      for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
          unsigned char output = 255 * getVal(array_p, x, y);
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
      printf( "-%4.1d ", line[ x ] ); //show image values
    }

    _writeoutline( line, IMWD );
    printf( "\n" );
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

  par {
    on tile[1]: distributor(c_inIO, c_outIO, c_control, c_timing);//thread to coordinate work on image
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing orientation data
    on tile[0]: orientation(i2c[0],c_control);        //client thread reading orientation data
    on tile[0]: DataInStream(c_inIO);          //thread to read in a PGM image
    on tile[0]: DataOutStream(c_outIO);       //thread to write out a PGM image
    on tile[0]: timing(c_timing);
  }

  return 0;
}
