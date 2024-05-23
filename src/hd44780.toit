// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import binary
import bytes show Buffer
import gpio

class Hd44780:

  static LCD-16x2 ::= 1
  static LCD-20x4 ::= 2

  static LCD-DATA_ ::=   1 // To write text to the display.
  static LCD-CMD_  ::=   0 // To send instructions to the display.

  /**
  This command sequence initializes the display to a 4-bit mode.

  The LCD may be in any of 3 modes:
  - 8-bit mode
  - 4-bit mode, waiting for the first nibble.
  - 4-bit mode, waiting for the second nibble.

  At any time, if the display is in 8-bit mode, but the pins d0-d3 aren't
    connected, then they are read as 0.

  If the display is in 8-bit mode, then it receives 4 commands. Three times 0x30, followed
    by 0x20.

  If the display is in 4-bit mode, waiting for the first nibble, then the first command 0x33
    sets the display to 8-bit mode. Then it receives another 0x30 command, followed by a 0x20
    command.

  If the display is in 4-bit mode, waiting for the second nibble, then the first
    nibble of $INIT-SEQ-1_ sends a 0x3 nibble, which finishes some command.
    The second nibble of the $INIT-SEQ-1_ starts a new command which is finished with the
    first nibble of the $INIT-SEQ-2_ yielding a full 0x33 command. Finally, the second
    nibble of the $INIT-SEQ-2_ is interpreted as 0x20 putting the display into 4-bit mode.
  */
  static INIT-SEQ-1_      ::=   0x33
  static INIT-SEQ-2_      ::=   0x32

  static TWO-ROWS-5BY8_   ::=   0x28 // Command for 2 row display with 5x8 pixel characters.
  static INC-AND-SCROLL_  ::=   0x06 // Increment cursor automatically.
  static DISP-CLEAR_      ::=   0x01
  static RETURN-HOME_     ::=   0x02

  static DISPLAY-CURSOR-CMD-BIT_ ::= 0b1000
  static DISPLAY-ON-BIT_         ::= 0b0100
  static CURSOR-ON-BIT_          ::= 0b0010
  static CURSOR-BLINK-BIT_       ::= 0b0001

  static SHIFT_   ::=   0x10
  static CURSOR_  ::=   0x00
  static DISPLAY_ ::=   0x08
  static LEFT_    ::=   0x00
  static RIGHT_   ::=   0x04

  static LINE-1_ ::=   0x80 // LCD RAM address for the 1st line.
  static LINE-2_ ::=   0xC0 // LCD RAM address for the 2nd line.
  static LINE-3_ ::=   0x94 // LCD RAM address for the 3rd line.
  static LINE-4_ ::=   0xD4 // LCD RAM address for the 4th line.

  rs_ /gpio.Pin
  en_ /gpio.Pin
  d4_ /gpio.Pin
  d5_ /gpio.Pin
  d6_ /gpio.Pin
  d7_ /gpio.Pin
  type_ /int  // One of $LCD_16x2 or $LCD_20x4

  /**
  Creates and initializes the display.
  The $type must be one of:
  - $LCD-16x2, or
  - $LCD-20x4

  Turns on the display, but disables the cursor.
  See $cursor for how to enable it.
  */
  constructor
      --rs /gpio.Pin
      --en /gpio.Pin
      --d4 /gpio.Pin
      --d5 /gpio.Pin
      --d6 /gpio.Pin
      --d7 /gpio.Pin
      --type /int = LCD-16x2:
    if type != LCD-16x2 and type != LCD-20x4: throw "INVALID_LCD_TYPE"

    rs.config --output
    en.config --output
    d4.config --output
    d5.config --output
    d6.config --output
    d7.config --output

    rs.set 0
    en.set 0
    d4.set 0
    d5.set 0
    d6.set 0
    d7.set 0

    rs_ = rs
    en_ = en
    d4_ = d4
    d5_ = d5
    d6_ = d6
    d7_ = d7
    type_ = type

    // Default initialization: 4-bit mode, 2 rows, with 5x8 pixel characters.
    write-command_ INIT-SEQ-1_      // Initialize and set to 4-bit mode.
    write-command_ INIT-SEQ-2_
    write-command_ TWO-ROWS-5BY8_   // Initializes 2 rows and 5x8 pixel characters.
    write-command_ INC-AND-SCROLL_  // Mode: Cursor increment and no scroll of display.
    on
    clear
    cursor --home

  /**
  Turns the display on without any cursor.

  Use $cursor to initialize the cursor.
  */
  on:
    write-command_ DISPLAY-CURSOR-CMD-BIT_ | DISPLAY-ON-BIT_

  /**
  Turns the display off.
  */
  off:
    write-command_ DISPLAY-CURSOR-CMD-BIT_

  /**
  Configures the cursor.

  If $off, then turns the cursor off.
  If $blinking, then sets the cursor to blinking.
  Otherwise turns the cursor on without blinking.

  The display is always turned on when calling this function.
  */
  cursor --on/bool=true --off/bool=(not on) --blinking/bool=false:
    command := DISPLAY-CURSOR-CMD-BIT_ | DISPLAY-ON-BIT_
    if off:           write-command_ command
    else if blinking:
      command |= CURSOR-BLINK-BIT_
      write-command_ command
    else:
      command |= CURSOR-ON-BIT_
      write-command_ command

  /**
  Moves the cursor back to the home position.
  */
  cursor --home -> none:
    write-command_ RETURN-HOME_

  /**
  Moves the cursor right or left by the given number of steps.
  */
  shift-cursor --left/bool=false --right/bool=(not left) steps/int=1 -> none:
    if steps < 0:
      steps = -steps
      right = not right
    direction := right ? RIGHT_ : LEFT_
    steps.repeat:
      write-command_ (SHIFT_ | CURSOR_ | direction)

  /**
  Moves the text on the display right or left by the given number of steps.
  */
  shift-display --left/bool=false --right/bool=(not left) steps/int=1 -> none:
    if steps < 0:
      steps = -steps
      right = not right
    direction := right ? RIGHT_ : LEFT_
    steps.repeat:
      write-command_ (SHIFT_ | DISPLAY_ | direction)

  /**
  Clears the display.
  */
  clear -> none:
    write-command_ DISP-CLEAR_

  /**
  Writes the given string or byte array.

  For strings, only the ASCII range works, since no translation of
    character codes is performed.
  For non-ASCII strings a call to $translate-to-rom-a-00 can be used to
    preprocess the string.
  */
  write str:
    str.do:
      write-data_ it

  /**
  Variant of $(write str).

  Places the cursor at $row and $column before emitting the string.
  */
  write str --row/int --column/int:
    place-cursor row column
    write str

  /**
  Moves the cursor to the given position.

  Rows and columns are 0-indexed.
  */
  place-cursor row/int column/int -> none:
    if type_ == LCD-16x2:
      if not (0 <= row <= 1 and 0 <= column <= 15): throw "INVALID_ROW_COLUMN"
    else if type_ == LCD-20x4:
      if not (0 <= row <= 4 and 0 <= column <= 20): throw "INVALID_ROW_COLUMN"
    else:
      unreachable

    command := ?
    if row == 0:      command = LINE-1_
    else if row == 1: command = LINE-2_
    else if row == 2: command = LINE-3_
    else:             command = LINE-4_

    command += column
    write-command_ command

  write-command_ byte:
    write-byte_ byte LCD-CMD_

  write-data_ byte:
    write-byte_ byte LCD-DATA_

  write-byte_ bits mode:
    rs_.set mode // Data mode: 1 for Data, 0 for Instructions.
    en_.set 0    // Ensure clock is low initially.

    // Upper nibble.
    d7_.set (bits >> 7) & 1
    d6_.set (bits >> 6) & 1
    d5_.set (bits >> 5) & 1
    d4_.set (bits >> 4) & 1
    strobe_

    // Lower nibble.
    d7_.set (bits >> 3) & 1
    d6_.set (bits >> 2) & 1
    d5_.set (bits >> 1) & 1
    d4_.set bits & 1
    strobe_

  strobe_:
    en_.set 1
    sleep --ms=1
    en_.set 0
    sleep --ms=1

  /**
  Translates a Unicode string to a series of bytes.

  The character mapping corresponds to the ROM code A00, which is ASCII with some
    Katakana and some Western European characters.
  If $with-descenders is true, then the prettier characters with descenders are
    preferred for 'g', 'j', 'p', 'q', and 'y'.  These can get too close to the
    lower line if used on the upper line.
  If the input string contains Unicode characters that are not supported by the
    display then the block is called.  It is given an integer Unicode code point
    and should return a list of bytes or a string that contains only supported characters.
  */
  static translate-to-rom-a-00 input/string --with-descenders/bool=false [on-unsupported] -> ByteArray:
    buffer := Buffer
    input.do: | c |
      if c:
        buffer.write
          unicode-to-1602_ c --with-descenders=with-descenders on-unsupported
    return buffer.bytes

  /**
  Translates a Unicode string to a series of bytes.

  The character mapping corresponds to the ROM code A00, which is ASCII with some
    Katakana and some Western European characters.
  If $with-descenders is true, then the prettier characters with descenders are
    preferred for 'g', 'j', 'p', 'q', and 'y'.  These can get too close to the
    lower line if used on the upper line.
  If the input string contains Unicode characters that are not supported by the
    display then it throws an exception.
  */
  static translate-to-rom-a-00 input/string --with-descenders/bool=false -> ByteArray:
    return translate-to-rom-a-00 input --with-descenders=with-descenders:
      throw "Unsupported code point: $it ('$(%c it)')"

  static unicode-to-1602_ c/int --with-descenders/bool=false [on-unsupported]-> ByteArray:
    if 0xff01 <= c <= 0xff5d:
      c += 0x21 - 0xff01  // Translate from halfwidth Roman Katakana range to ASCII range.

    code   := 0
    accent := 0

    if with-descenders and 'g' <= c <= 'y':
      index := c - 'g'
      // Use a binary mask with 1's where there are descenders.
        //  yxwvutsrqponmlkjihg
      if (0b1000000011000001001 >> index) & 1 != 0:
        code = c + 0x80
      else:
        code = c
    else if c < 0x100:
      code = LATIN-1-TABLE_[c]
    else if 0xff61 <= c <= 0xff9f:
      // Half-width Katakana range maps directly.
      code = c - 0xff61 + 0xa1
    else if 0x3000 <= c <= 0x300d:
      code = JAPANESE-PUNCTUATION-TABLE_[c - 0x3000]
    else if 0x309b <= c <= 0x30ff:
      // Map full width Katakana.
      code = KATAKANA-TABLE_[c - 0x309b]
      if code != 0:
        accent = DIACRITIC-TABLE_[c - 0x309b]
    else if 'Σ' <= c <= 'σ':
      code = GREEK-TABLE_[c - 'Σ']
    else if c == '→' or c == '￫':
      code = 0x7e
    else if c == '←' or c == '￩':
      code = 0x7f
    else if c == '√':  // Square root.
      code = 0xe8
    else if c == 'Ω':  // Ohm symbol.
      code = 0xf4
    else if c == '█':  // Solid block.
      code = 0xff

    // Unidentified or unsupported glyphs.

    //   0xe9   Superscript -1.
    //   0xeb   Superscript asterisk?
    //   0xf3   Strange squiggle.
    //   0xf8   x with overbar.
    //   0xfa   Smaller version of Japanese TI?
    //   0xfb   Unknown Japanese Katakana?
    //   0xfc   Unknown Japanese Katakana?

    if code != 0:
      if accent != 0:
        return #[code, accent]
      return #[code]

    fixed := on-unsupported.call c
    if fixed is string:
      return translate-to-rom-a-00 fixed: throw "String still unsupported after calling on_unsupported"
    return fixed as ByteArray

  static LATIN-1-TABLE_ ::= #[
      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,     // 0x00
      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,     // 0x10
      0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,  // 0x20
      0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,  // 0x30
      0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,  // 0x40
      0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0,    0x5d, 0x5e, 0x5f,  // 0x50
      0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,  // 0x60
      0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0,    0,     // 0x70
      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,     // 0x80
      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,     // 0x90
      0,    0,    0xec, 0xed, 0,    0x5c, 0,    0,    0,    0,    0,    0,    0,    0,    0,    0,     // 0xa0
      0xdf, 0,    0,    0,    0,    0xe4, 0,    0xa5, 0,    0,    0,    0,    0,    0,    0,    0,     // 0xb0
      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,     // 0xc0
      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0xe2,  // 0xd0
      0,    0,    0,    0,    0xe1, 0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,     // 0xe0
      0,    0xee, 0,    0,    0,    0,    0xef, 0xfd, 0,    0,    0,    0,    0xf5, 0,    0,    0x00]  // 0xf0

  static KATAKANA-TABLE_ ::= #[
                                                                        0xde, 0xdf, 0,    0,    0,     // 0x3090
      0,    0xa7, 0xb1, 0xa8, 0xb2, 0xa9, 0xb3, 0xaa, 0xb4, 0xab, 0xb5, 0xb6, 0xb6, 0xb7, 0xb7, 0xb8,  // 0x30a0
      0xb8, 0xb9, 0xb9, 0xba, 0xba, 0xbb, 0xbb, 0xbc, 0xbc, 0xbd, 0xbd, 0xbe, 0xbe, 0xbf, 0xbf, 0xc0,  // 0x30b0
      0xc0, 0xc1, 0xc1, 0xc1, 0xaf, 0xaf, 0xc3, 0xc3, 0xc4, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca,  // 0x30c0
      0xca, 0xca, 0xcb, 0xcb, 0xcb, 0xcc, 0xcc, 0xcc, 0xcd, 0xcd, 0xcd, 0xce, 0xce, 0xce, 0xcf, 0xd0,  // 0x30d0
      0xd1, 0xd2, 0xd3, 0xac, 0xd4, 0xad, 0xd5, 0xae, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xb8, 0xb8,  // 0x30e0
      0,    0,    0xa6, 0xdd, 0,    0,    0,    0,    0,    0,    0,    0xa5, 0xb0, 0,    0,    0x00]  // 0x30f0

  // Dakuten and handakuten.
  static DIACRITIC-TABLE_ ::= #[
                                                                        0,    0,    0,    0,    0,     // 0x3090
      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0xde, 0,    0xde, 0,     // 0x30A0
      0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,     // 0x30B0
      0xde, 0,    0xde, 0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0,    0,    0,    0,    0,     // 0x30C0
      0xde, 0xdf, 0,    0xde, 0xdf, 0,    0xde, 0xdf, 0,    0xde, 0xdf, 0,    0xde, 0xdf, 0,    0,     // 0x30D0
      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,     // 0x30E0
      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0x00]  // 0x30F0

  static JAPANESE-PUNCTUATION-TABLE_ ::= #[0, 0xa4, 0xa1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xa2, 0xa3]

  static GREEK-TABLE_ ::= #[
                  0xf6,       0,    0,    0, 0, // 0x03a3-0x3a7      Σ....
      0,    0xf4, 0,    0,    0,    0,    0, 0, // 0x03a8-0x03af  .Ω......
      0,    0xe0, 0xe2, 0,    0,    0xe3, 0, 0, // 0x03b0-0x03b7  .αβ..ε..
      0xf2, 0,    0,    0,    0xe4, 0,    0, 0, // 0x03b8-0x03bf  θ...μ...
      0xf7, 0xe6, 0,    0xe5]                   // 0x03c0-0x03c3  πρ.σ
