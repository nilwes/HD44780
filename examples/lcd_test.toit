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
  lcd_init RSpin ENpin D4pin D5pin D6pin D7pin --cursor_blink=false --cursor_enabled=false // Submit pins, and 0 0 for no cursor, no blink
  lcd_write  "toit" 0 6        // Write text on first line, third column
  sleep --ms=3000                     // Sleep for 3 secs

  2.repeat:
    lcd_shift_display --right=false 1   // Shift entire display two places to the left
    sleep --ms=200
  5.repeat:
    lcd_shift_display --right=true 1   // Shift entire display five places to the right
    sleep --ms=200
  3.repeat:
    lcd_shift_display --right=false 1   // Shift entire display two places to the left
    sleep --ms=200
  
  sleep --ms=1000
  
  
  lcd_write  "like a toiger" 1 1        // Write text on first line, third column
  sleep --ms=2000                     // Sleep for 3 secs

  5.repeat:
    lcd_shift_display --right=true 1   // Shift entire display five places to the right
    sleep --ms=200
  7.repeat:
    lcd_shift_display --right=false 1   // Shift entire display five places to the right
    sleep --ms=200
  2.repeat:
    lcd_shift_display --right=true 1   // Shift entire display five places to the right
    sleep --ms=200

  sleep --ms=2000
  lcd_clear                           // Clear display
  