# HD44780
Toit driver for the HD44780 LCD controller. The driver works with 16x2 LCDs.

Example
=======

import .hd44780
import gpio

RSpin := gpio.Pin.out 13
ENpin := gpio.Pin.out 12
D4pin := gpio.Pin.out 18
D5pin := gpio.Pin.out 17
D6pin := gpio.Pin.out 16
D7pin := gpio.Pin.out 15

main:
  LCDinit   RSpin ENpin D4pin D5pin D6pin D7pin 1 1 // Submit pins, and 0 0 for no cursor, no blink
  LCDwrite  "#reallytoit" 0 2 // Write text on first line, third column
  sleep --ms=3000             // Sleep for 3 secs
  LCDshiftDisplay "right" 2   // Shift entire display two places to the right
  sleep --ms=3000             // Sleep for 3 secs
  LCDclear                    // Clear display
  
  
Bugs and Feature Requests
=========================
Bugs and feature requests should be directed to nils@toit.io
