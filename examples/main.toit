// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import hd44780 show *
import gpio

EN_PIN ::= 12
RS_PIN ::= 13
D4_PIN ::= 18
D5_PIN ::= 17
D6_PIN ::= 16
D7_PIN ::= 15

main:
  display := Hd44780
      --en = gpio.Pin EN_PIN
      --rs = gpio.Pin RS_PIN
      --d4 = gpio.Pin D4_PIN
      --d5 = gpio.Pin D5_PIN
      --d6 = gpio.Pin D6_PIN
      --d7 = gpio.Pin D7_PIN

  // Write text on first line, 6th column.
  display.write  --row=0 --column=5
      Hd44780.translate_to_rom_a_00 "→toit←"  // Special characters requires translate_to_rom_a_00.
  sleep --ms=2000

  2.repeat:
    display.shift_display --left
    sleep --ms=200
  5.repeat:
    display.shift_display --right
    sleep --ms=200
  3.repeat:
    display.shift_display --left 1
    sleep --ms=200

  sleep --ms=1000

  display.write --row=1 --column=1  "like a toiger"
  sleep --ms=2000

  5.repeat:
    display.shift_display --right
    sleep --ms=200
  7.repeat:
    display.shift_display --left
    sleep --ms=200
  3.repeat:
    display.shift_display --right 1
    sleep --ms=200

  sleep --ms=2000
  display.clear
