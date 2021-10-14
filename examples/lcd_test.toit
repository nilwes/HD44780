// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import ..src.hd44780
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
  sleep --ms=3000
  LCDclear                    // Clear display
  