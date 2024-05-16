// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import hd44780 show *
import gpio

EN-PIN ::= 12
RS-PIN ::= 13
D4-PIN ::= 18
D5-PIN ::= 17
D6-PIN ::= 16
D7-PIN ::= 15

main:
  display := Hd44780
      --en = gpio.Pin EN-PIN
      --rs = gpio.Pin RS-PIN
      --d4 = gpio.Pin D4-PIN
      --d5 = gpio.Pin D5-PIN
      --d6 = gpio.Pin D6-PIN
      --d7 = gpio.Pin D7-PIN

  // Write text on first line, 6th column.
  display.write  --row=0 --column=5
      Hd44780.translate-to-rom-a-00 "→toit←"  // Special characters requires translate_to_rom_a_00.
  sleep --ms=2000

  2.repeat:
    display.shift-display --left
    sleep --ms=200
  5.repeat:
    display.shift-display --right
    sleep --ms=200
  3.repeat:
    display.shift-display --left 1
    sleep --ms=200

  sleep --ms=1000

  display.write --row=1 --column=1  "like a toiger"
  sleep --ms=2000

  5.repeat:
    display.shift-display --right
    sleep --ms=200
  7.repeat:
    display.shift-display --left
    sleep --ms=200
  3.repeat:
    display.shift-display --right 1
    sleep --ms=200

  sleep --ms=2000
  display.clear
