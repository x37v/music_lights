/*
 *
 *Midi triggered MaxM I2C commands using Teensy 2.0 USBMIDI
 *
 * 
 * BlinkM connections to Teensy
 * -----------------------------
 * PWR - -- gnd -- black -- Gnd
 * PWR + -- +5V -- red   -- 5V
 * I2C d -- SDA -- green -- D1 on a Teensy 2.0
 * I2C c -- SCK -- blue  -- D0 on a Teensy 2.0
 * 
 *
 * 2011 Jesse Mejia, Alex Norman
 *
 *
 * CC 1 -> fade out time light 1
 * CC 2 -> fade out time light 2
 * CC 3 -> fade out time light 3
 *
 * CC 7 -> fade out time global
 * CC 8 -> fade in time global
 *
 */



#include "Wire.h"
#include "BlinkM_funcs.h"

const byte light = 2;
const byte my_note = 64 + light;
const byte my_channel = 16;
const byte light_addr = 0x09;
const byte my_fade_out_num = my_note - 63;
const byte global_fade_out_num = 7;
const byte global_fade_in_num = 8;

byte fade_in_time = 32;
byte fade_out_time = 64;

//#define DEBUG 1

// set this if you're plugging a BlinkM directly into an Arduino,
// into the standard position on analog in pins 2,3,4,5
// otherwise you can set it to false or just leave it alone
const boolean BLINKM_ARDUINO_POWERED = false;
int ledPin = 11;
//#define num_blinkms 13
#define num_blinkms 1
#define blinkm_start_addr 9

const int CMD_START_BYTE = 0x01;

//int blinkm_addr = 0x09;

byte serInStr[32];  // array that will hold the serial input string

void note_on(byte chan, byte note, byte vel);
void note_off(byte chan, byte note, byte vel);
void cc_callback(byte chan, byte num, byte value);

void setup() {
   //Serial.begin(31250); 

   //Use ledPin to flash when we get stuff  
   pinMode(ledPin, OUTPUT); 
   digitalWrite(ledPin, HIGH);

   delay(300);
   BlinkM_begin();

   usbMIDI.setHandleNoteOff(note_off);
   usbMIDI.setHandleNoteOn(note_on);
   usbMIDI.setHandleControlChange(cc_callback);

   // set all BlinkMs to known state
   for( int i=0; i<num_blinkms; i++) {
      BlinkM_stopScript( blinkm_start_addr + i );
      BlinkM_fadeToRGB( blinkm_start_addr + i, 0,0,0); // fade to black
   }
   //Serial.print("BlinkMCylon ready\n");
   delay(300);
}

void loop() { 
   //BlinkM_fadeToRGB(addr0, 0x00,0x00,0xFF); // fade to an RGB
   usbMIDI.read();
}

void cc_callback(byte chan, byte num, byte value) {
   if (chan != my_channel)
      return;
   if (num == my_fade_out_num || num == global_fade_out_num) 
      fade_out_time = 128 - value;
   else if (num == global_fade_in_num) 
      fade_in_time = 128 - value;
}

void note_on(byte chan, byte note, byte vel) {
   if (chan != my_channel || note != my_note)
      return;
   if (vel == 0) {
      note_off(chan, note, 0);
   } else {
      BlinkM_begin(); // init BlinkM funcs
      BlinkM_setFadeSpeed(light_addr, fade_in_time);
      BlinkM_fadeToHSB(light_addr, vel << 1, 0xff, 0xff);
   }
}

void note_off(byte chan, byte note, byte vel) {
   if (chan != my_channel || note != my_note)
      return;
   BlinkM_begin(); // init BlinkM funcs
   BlinkM_setFadeSpeed(light_addr, fade_out_time);
   BlinkM_fadeToHSB(light_addr, 0x00, 0x00, 0x00);
}

