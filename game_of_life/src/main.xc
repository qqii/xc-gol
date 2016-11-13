// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include "pgmIO.h"
#include "i2c.h"

#include "world.h"

#define  IMHT 16                  //image height
#define  IMWD 16                //image width
#define WCOUNT 4
#define ITERATIONS 1

typedef unsigned char uchar;      //using uchar as shorthand

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
  char infname[] = "test.pgm";     //put your input image path here
  int res;
  uchar line[ IMWD ];
  printf( "DataInStream: Start...\n" );

  //Open PGM file
  res = _openinpgm( infname, IMWD, IMHT );
  if( res ) {
    printf( "DataInStream: Error openening %s\n.", infname );
    return;
  }

  //Read image line-by-line and send byte by byte to channel c_out
  for( int y = 0; y < IMHT; y++ ) {
    _readinline( line, IMWD );
    for( int x = 0; x < IMWD; x++ ) {
      c_out <: line[ x ];
      printf( "-%4.1d ", line[ x ] ); //show image values
    }
    printf( "\n" );
  }

  //Close PGM image file
  _closeinpgm();
  printf( "DataInStream: Done...\n" );
  return;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Start your implementation by changing this function to implement the game of life
// by farming out parts of the image to worker threads who implement it...
// Currently the function just inverts the image
//inline 
uint16_t pmod(uint16_t i, uint16_t n) {
  return (i % n + n) % n;
}

unsigned char gol(unsigned char surr){
  unsigned char count = 0;
  while (surr != 0){
    surr = surr & (surr - 1);
    count += 1;
  }
  return count;
}

unsafe unsigned char getVal(char (*unsafe array)[IMWD / 8][IMHT], int x, int y){
  uint16_t cellw = pmod (x, IMWD) / 8;
  char cellwp = 7 - (x % 8);
  uint16_t cellh = pmod(y, IMHT);
  // printf("Getting cell %d:%d, %d\n", cellw, cellwp, cellh);
  return ((*array)[cellw][cellh] & (1<< cellwp)) >> cellwp;
}

unsafe unsigned char update(char (*unsafe array)[IMWD / 8][IMHT], int x, int y){
  unsigned char alive = 0;
  unsigned char self = getVal(array, x, y);
  alive += getVal(array, x - 1, y - 1);
  alive += getVal(array, x, y - 1);
  alive += getVal(array, x + 1, y - 1);
  alive += getVal(array, x - 1, y);
  alive += getVal(array, x + 1, y);
  alive += getVal(array, x - 1, y + 1);
  alive += getVal(array, x, y + 1);
  alive += getVal(array, x + 1, y + 1);
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
    return 255;
  }
}


unsafe void worker(char (*unsafe strips)[IMWD / 8][IMHT], char wnumber, char *unsafe fstart, char *unsafe fpause, char (*unsafe ffinshed)[WCOUNT]){
  // unsigned char data;
  // unsigned char result;
  uint16_t wset_mid = 0;
  uint16_t wset_loc = 0;
  unsigned char wset[IMWD / 8][2];

  uint16_t voodoo = 0;

  while (!*fstart || voodoo == 3){
    voodoo = voodoo + 1 % 3;
    // printf("Worker %d waiting to start\n", wnumber);
  }


  for(uint16_t K = 0; K < IMWD / 8; K++){
    wset[K][wset_mid] = *strips[K][wset_loc];
    wset[K][wset_mid + 1] = (*strips)[K][pmod(wset_loc - 1, IMHT)];
  }

  while(1){
    // printf("Worker %d starting iteration\n", wnumber);
    for (uint16_t J = 0 + (wnumber * IMHT / WCOUNT); J < ((wnumber + 1) * IMHT / WCOUNT); J++){
      for(uint16_t I = 0; I < (IMWD / 8); I++){
        unsigned char data = 0;
        for(int8_t W = 0; W < 8; W++){
          unsigned char cell = update(strips, 8 * I + W, J);
          data = data | cell << (7 - W);
          //  printf("Worker %d checking cell %d:%d,%d\n", wnumber, I, W, J);
        }
        wset[I][wset_mid] = data;
      }
      //write back the working set
      wset_mid = (wset_mid + 1) % 2;
      for(uint16_t L = 0; L < IMWD / 8; L++){
        (*strips)[L][pmod(wset_loc - 1, IMHT)] = wset[L][(wset_mid + 1) % 2];
        wset[L][(wset_mid + 1) % 2] = 0;
      }
      wset_loc = wset_loc + 1;
    }
    // printf("Worker %d almost finished iteration\n", wnumber);
    (*ffinshed)[wnumber] = 1;
    //printf("Worker %d finished iteration\n", wnumber);
    while(*fpause == 1){
      voodoo = voodoo + 1 % 3;
      // printf("Worker %d waiting for next iteration\n", wnumber);
    }
  }
}

unsafe void distributor(chanend c_in, chanend c_out, chanend fromAcc)
{
  char array[IMWD / 8][IMHT];
  char fstart = 0;
  char fpause = 1;
  char ffinshed[WCOUNT];

  char (*unsafe array_p)[IMWD / 8][IMHT] = &array;
  char *unsafe fstart_p = &fstart;
  char *unsafe fpause_p = &fpause;
  char (*unsafe ffinshed_p)[WCOUNT] = &ffinshed;

  //Starting up and wait for tilting of the xCore-200 Explorer
  printf( "ProcessImage: Start, size = %dx%d\n", IMHT, IMWD );
  printf( "Waiting for Board Tilt...\n" );
  fromAcc :> int value;

  //Read in and do something with your image values..
  //This just inverts every pixel, but you should
  //change the image according to the "Game of Life"
  par{
    worker(array_p, 0, fstart_p, fpause_p, ffinshed_p);
    worker(array_p, 1, fstart_p, fpause_p, ffinshed_p);
    worker(array_p, 2, fstart_p, fpause_p, ffinshed_p);
    worker(array_p, 3, fstart_p, fpause_p, ffinshed_p);
    // worker(array_p, 4, fstart_p, fpause_p, ffinshed_p);
    // worker(array_p, 5, fstart_p, fpause_p, ffinshed_p);
    // worker(array_p, 6, fstart_p, fpause_p, ffinshed_p);
    // worker(array_p, 7, fstart_p, fpause_p, ffinshed_p);
    {
      printf( "Loading...\n" );
      for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD / 8; x++ ) { //go through each pixel per line
          unsigned char number = 0;
          for( int w = 7; w >= 0; w--){
            unsigned char input = 0;
            c_in :> input;
            number = number | ((input/255) << w); 
          }
          array[x][y] = number;
        }
      }

      printf("Loading Complete\n");
      *fstart_p = 1;

      for(int I = 0; I < ITERATIONS; I++){
        fpause = 1;
        int nfinished = 0;
        while (nfinished < WCOUNT){
          nfinished = 0;
          for(int J = 0; J < WCOUNT; J++){
            nfinished += (*ffinshed_p)[J];
          }
        }
        //printf("%d Workers Finished on iteration %d\n", nfinished, I);
        for(int J = 0; J < WCOUNT; J++){
          (*ffinshed_p)[J] = 0;
        }
        if (I % 10000 == 0){
          printf("Finished iteration %d\n", I);
        }
        // printf("Ready to unpause workers\n");
        if (I != ITERATIONS - 1){
          *fpause_p = 0;
        }
        // printf("Pause flag set to %d\n", *fpause_p);
      }


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
void DataOutStream(chanend c_in)
{
  char outfname[] = "testout.pgm"; //put your output image path here
  int res;
  uchar line[ IMWD ];

  //Open PGM file
  printf( "DataOutStream: Start...\n" );
  res = _openoutpgm( outfname, IMWD, IMHT );
  if( res ) {
    printf( "DataOutStream: Error opening %s\n.", outfname );
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

  //Close the PGM image
  _closeoutpgm();
  printf( "DataOutStream: Done...\n" );
  return;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Initialise and  read orientation, send first tilt event to channel
//
/////////////////////////////////////////////////////////////////////////////////////////
void orientation( client interface i2c_master_if i2c, chanend toDist) {
  i2c_regop_res_t result;
  char status_data = 0;
  int tilted = 0;

  // Configure FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }

  // Enable FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_CTRL_REG_1, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }

  //Probe the orientation x-axis forever
  while (1) {

    //check until new orientation data is available
    do {
      status_data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
    } while (!status_data & 0x08);

    //get new x-axis tilt value
    int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);

    //send signal to distributor after first tilt
    if (!tilted) {
      if (x>30) {
        tilted = 1 - tilted;
        toDist <: 1;
      }
    }
  }
}

//this will do the calculation, we just need to pack our 8 surrounding cells into a char


/////////////////////////////////////////////////////////////////////////////////////////
//
// Orchestrate concurrent system and start up all threads
//
/////////////////////////////////////////////////////////////////////////////////////////
unsafe int main(void) {

  i2c_master_if i2c[1];               //interface to orientation

  chan c_inIO, c_outIO, c_control;    //extend your channel definitions here

  par {
    on tile[1]: distributor(c_inIO, c_outIO, c_control);//thread to coordinate work on image
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing orientation data
    on tile[0]: orientation(i2c[0],c_control);        //client thread reading orientation data
    on tile[0]: DataInStream(c_inIO);          //thread to read in a PGM image
    on tile[0]: DataOutStream(c_outIO);       //thread to write out a PGM image
  }

  return 0;
}