// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include "pgmIO.h"
#include "i2c.h"

#include "world.h"

#define  IMHT 16                  //image height
#define  IMWD 16                  //image width
#define WCOUNT 2

typedef unsigned char uchar;      //using uchar as shorthand

on tile[0]: port p_scl = XS1_PORT_1E;         //interface ports to orientation
on tile[0]: port p_sda = XS1_PORT_1F;

char array[IMWD + 2][IMHT / 8 + 2];
char fstart = 0;
char fpause = 1;
char ffinshed[WCOUNT];

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
//
/////////////////////////////////////////////////////////////////////////////////////////
unsafe void distributor(chanend c_in, chanend c_out, chanend fromAcc, char 
(*strips)[IMWD / 8 + 2][IMHT + 2], char wnumber, char *fstart, char *fpause, char (*ffinshed)[WCOUNT])
{

  //Starting up and wait for tilting of the xCore-200 Explorer
  printf( "ProcessImage: Start, size = %dx%d\n", IMHT, IMWD );
  printf( "Waiting for Board Tilt...\n" );
  fromAcc :> int value;

  //Read in and do something with your image values..
  //This just inverts every pixel, but you should
  //change the image according to the "Game of Life"
  printf( "Loading...\n" );
  for( int y = 1; y < IMHT + 1; y++ ) {   //go through all lines
    for( int x = 1; x < IMWD + 1; x++ ) { //go through each pixel per line
      c_in :> array[x][y];
    }
  }

  par{

  }
  printf("Loading Complete\n");

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
    }
    _writeoutline( line, IMWD );
    printf( "DataOutStream: Line written...\n" );
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
unsigned char gol(unsigned char surr){
  unsigned char count = 0;
  while (surr != 0){
    surr = surr & (surr - 1);
    count += 1;
  }
  return count;
}

unsafe void worker(char (*strips)[IMWD / 8 + 2][IMHT + 2], char wnumber, char *fstart, char *fpause, char (*ffinshed)[WCOUNT]){
  uint16_t cellw;
  uint16_t cellh;
  unsigned char cellwp;
  unsigned char data;
  unsigned char result;
  char wset_mid = 1;
  char wset_loc = 1;
  char wset[IMWD / 8 + 2][2];

  while (!fstart){}

  for(uint16_t K = 0; K < IMWD / 8; K++){
    wset[K][wset_mid - 1] = *strips[K][wset_loc - 1];
    wset[K][wset_mid] = *strips[K][wset_loc];
    // wset[K][wset_mid + 1] = strips[K][wset_loc + 2]; 
  }
  while(1){
    for (uint16_t J = 1 + (wnumber * IMHT / WCOUNT); J < ((wnumber + 1) * IMHT / WCOUNT); J++){
      for(uint16_t I = 1; I < IMWD; I++){
        cellw = I / 8;
        cellwp = I % 8;
        cellh = J;
        if (cellwp == 0){
          data = (*strips[cellw][cellh - 1] & (7<<(7-cellwp))) |
                      (8*(*strips[cellw][cellh + 1] & (7<<(7-cellwp)))) |
                      (64*(*strips[cellw][cellh] & (5<<(7-cellwp))));
        }
        else if (cellwp == 8){
          data = (*strips[cellw][cellh - 1] & (7<<(7-cellwp))) |
                      (8*(*strips[cellw][cellh + 1] & (7<<(7-cellwp)))) |
                      (64*(*strips[cellw][cellh] & (5<<(7-cellwp))));
        }
        else{
          //bit wizardry
          data = (*strips[cellw][cellh - 1] & (7<<(7-cellwp))) | //row above
                      (8*(*strips[cellw][cellh + 1] & (7<<(7-cellwp)))) | //row below
                      (64*(*strips[cellw][cellh] & (5<<(7-cellwp)))); //to the left and right
        }
        result = gol(data);
        wset[cellw][wset_mid] = *strips[cellw][cellh] | (result<<(7 - cellwp));
      }
      //write back the working set
      wset_mid = (wset_mid + 1) % 2;
      for(uint16_t L = 0; L < IMWD / 8; L++){
        *strips[L][wset_loc - 1] = wset[L][(wset_mid + 1) % 2];
        wset[L][(wset_mid + 1) % 2] = 0;
      }
      wset_loc = wset_loc + 1;
    }
    *ffinshed[WCOUNT] = 1;
    while(fpause){}
  }
}
/////////////////////////////////////////////////////////////////////////////////////////
//
// Orchestrate concurrent system and start up all threads
//
/////////////////////////////////////////////////////////////////////////////////////////
unsafe int main(void) {

  i2c_master_if i2c[1];               //interface to orientation

  chan c_inIO, c_outIO, c_control;    //extend your channel definitions here

  par {
    on tile[1]:worker(&array, 0, &fstart, &fpause, &ffinshed);
    on tile[1]:worker(&array, 1, &fstart, &fpause, &ffinshed);
    on tile[1]: distributor(c_inIO, c_outIO, c_control, &array, 1, &fstart, &fpause, &ffinshed);//thread to coordinate work on image
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing orientation data
    on tile[0]: orientation(i2c[0],c_control);        //client thread reading orientation data
    on tile[0]: DataInStream(c_inIO);          //thread to read in a PGM image
    on tile[0]: DataOutStream(c_outIO);       //thread to write out a PGM image
  }

  return 0;
}