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
  display := hd44780  

  display.lcd_init RSpin ENpin D4pin D5pin D6pin D7pin --lcd_type="20x4" --cursor_blink=false --cursor_enabled=false

  display.lcd_write  (display.translate_to_rom_a_00 "→toit←") 2 5  // Write text on third line, 6th column.

  sleep --ms=2000                                                  // Special characters requires call to method translate_to_rom_a_00.

  2.repeat:
    display.lcd_shift_display --right=false 1 
    sleep --ms=200
  5.repeat:
    display.lcd_shift_display --right=true 1  
    sleep --ms=200
  3.repeat:
    display.lcd_shift_display --right=false 1 
    sleep --ms=200
  
  sleep --ms=1000  
  
  display.lcd_write  "like a toiger" 1 1     
  sleep --ms=2000                    

  5.repeat:
    display.lcd_shift_display --right=true 1 
    sleep --ms=200
  6.repeat:
    display.lcd_shift_display --right=false 1
    sleep --ms=200
  3.repeat:
    display.lcd_shift_display --right=true 1 
    sleep --ms=200

  sleep --ms=2000
  display.lcd_clear                          
  