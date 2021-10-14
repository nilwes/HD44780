// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import binary
import gpio

LCD_DATA        ::=   1 // ...if writing text to display
LCD_CMD         ::=   0 // ...if sending instructions to display

INIT_SEQ_1      ::=   0x33
INIT_SEQ_2      ::=   0x32
TWO_ROWS_5BY8   ::=   0x28 // Command for 2 row display with 5x8 pixel characters
DISP_OFF        ::=   0x08
DISP_ON         ::=   0x0F // Display on with blinking cursor
CURSOR_NOBLINK  ::=   0x0E
CURSOR_OFF      ::=   0x0C
INC_AND_SCROLL  ::=   0x06 // Increment cursor automatically
DISP_CLEAR      ::=   0x01
RETURN_HOME     ::=   0x02

LCD_SHIFT       ::=   0x10
LCD_CURSOR      ::=   0x00
LCD_DISPLAY     ::=   0x08
LCD_LEFT        ::=   0x00
LCD_RIGHT       ::=   0x04

LCD_LINE_1      ::=   0x80 // LCD RAM address for the 1st line
LCD_LINE_2      ::=   0xC0 // LCD RAM address for the 2nd line

RSpin := 0
ENpin := 0
D4pin := 0
D5pin := 0
D6pin := 0
D7pin := 0

/* LCDinit takes incoming GPIO pins and assigns them to corresponding variables. 
It also initializes the HD44780 to 4-bit mode, 2 rows with 5x8 pixel characters.
Depending on input the cursor can be:
[0 0] -> OFF             
[1 0] -> ON, but not blinking              
[1 1] -> ON, and blinking */
LCDinit RS EN D4 D5 D6 D7 cursorEnabled cursorBlink:
  //Assign incoming pins
  RSpin = RS 
  ENpin = EN
  D4pin = D4 
  D5pin = D5
  D6pin = D6
  D7pin = D7

  // Default initialization: 4-bit mode, 2 rows, with 5x8 pixel characters, blinking cursor at position (0,0)
  writeByte INIT_SEQ_1     LCD_CMD // Initialize and set to 4-bit mode
  writeByte INIT_SEQ_2     LCD_CMD
  writeByte TWO_ROWS_5BY8  LCD_CMD // Initializes 2 rows and 5x8 pixel characters
  writeByte DISP_ON        LCD_CMD // Turn on display, with blinking cursor
  writeByte INC_AND_SCROLL LCD_CMD // Mode: Cursor increment and no scroll of display
  writeByte DISP_CLEAR     LCD_CMD // Clear LCD
  writeByte RETURN_HOME    LCD_CMD // Cursor home
  if (cursorEnabled == 1 and cursorBlink == 1):
    writeByte DISP_ON LCD_CMD                       // Turn on display, with blinking cursor
  else if (cursorEnabled == 1 and cursorBlink == 0):
    writeByte CURSOR_NOBLINK LCD_CMD                // Turn on display, no cursor blink
  else if cursorEnabled == 0:
    writeByte CURSOR_OFF LCD_CMD                    // Turn on display, no cursor

LCDwrite string row col:
  // Place cursor
  if row == 0:
    writeByte (LCD_LINE_1 + col) LCD_CMD
  else if row == 1:
    writeByte (LCD_LINE_2 + col) LCD_CMD
  else:
    print "Error: Only two line displays are supported"

  for i := 0 ; i < string.size ; i += 1:
    writeByte string[i] LCD_DATA

writeByte bits mode:
  RSpin.set mode // Data mode: 1 for Data, 0 for Instructions
  ENpin.set 0    //Ensure clock is low initially

  //Upper nibble
  D7pin.set 0
  D6pin.set 0
  D5pin.set 0
  D4pin.set 0
  if bits & 0x80 == 0x80:
    D7pin.set 1
  if bits & 0x40 == 0x40:
    D6pin.set 1
  if bits & 0x20 == 0x20:
    D5pin.set 1
  if bits & 0x10 == 0x10:
    D4pin.set 1

  strobe

  //Lower nibble
  D7pin.set 0
  D6pin.set 0
  D5pin.set 0
  D4pin.set 0
  if bits & 0x08 == 0x08:
    D7pin.set 1
  if bits & 0x04 == 0x04:
    D6pin.set 1
  if bits & 0x02 == 0x02:
    D5pin.set 1
  if bits & 0x01 == 0x01:
    D4pin.set 1

  strobe

LCDshiftCursor direction steps:
  for i := 0 ; i < steps ; i += 1: 
    if direction == "right":
      writeByte (LCD_SHIFT | LCD_CURSOR | LCD_RIGHT) LCD_CMD
    else:
      writeByte (LCD_SHIFT | LCD_CURSOR | LCD_LEFT)  LCD_CMD

LCDshiftDisplay direction steps:
  for i := 0 ; i < steps ; i += 1: 
    if direction == "right":
      writeByte (LCD_SHIFT | LCD_DISPLAY | LCD_RIGHT) LCD_CMD
    else:
      writeByte (LCD_SHIFT | LCD_DISPLAY | LCD_LEFT)  LCD_CMD

LCDcursorHome:
  writeByte RETURN_HOME LCD_CMD // Cursor home

LCDplaceCursor row col:
  // Place cursor
  if row == 0:
    writeByte (LCD_LINE_1 + col) LCD_CMD
  else if row == 1:
    writeByte (LCD_LINE_2 + col) LCD_CMD
  else:
    print "Error: Only two line displays are supported"

LCDclear:
  writeByte DISP_CLEAR LCD_CMD // Clear LCD

strobe: //Clock-in the instruction
  ENpin.set 1
  sleep --ms=1
  ENpin.set 0
  sleep --ms=1