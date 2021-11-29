// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import binary
import bytes show Buffer
import gpio

LCD_DATA_        ::=   1 // ...if writing text to display
LCD_CMD_         ::=   0 // ...if sending instructions to display

INIT_SEQ_1_      ::=   0x33
INIT_SEQ_2_      ::=   0x32
TWO_ROWS_5BY8_   ::=   0x28 // Command for 2 row display with 5x8 pixel characters
DISP_OFF_        ::=   0x08
DISP_ON_         ::=   0x0F // Display on with blinking cursor
CURSOR_NOBLINK_  ::=   0x0E
CURSOR_OFF_      ::=   0x0C
INC_AND_SCROLL_  ::=   0x06 // Increment cursor automatically
DISP_CLEAR_      ::=   0x01
RETURN_HOME_     ::=   0x02

LCD_SHIFT_       ::=   0x10
LCD_CURSOR_      ::=   0x00
LCD_DISPLAY_     ::=   0x08
LCD_LEFT_        ::=   0x00
LCD_RIGHT_       ::=   0x04

LCD_LINE_1_      ::=   0x80 // LCD RAM address for the 1st line
LCD_LINE_2_      ::=   0xC0 // LCD RAM address for the 2nd line

rs_pin_ := 0
en_pin_ := 0
d4_pin_ := 0
d5_pin_ := 0
d6_pin_ := 0
d7_pin_ := 0

/// Deprecated. Use $lcd_init instead.
LCDinit RS EN D4 D5 D6 D7 cursor_enabled/int cursor_blink/int -> none:
  lcd_init RS EN D4 D5 D6 D7 --cursor_enabled=(cursor_enabled == 1) --cursor_blink=(cursor_blink == 1)

/**
Initializes the driver.
Takes incoming GPIO pins and assigns them to corresponding variables.
It also initializes the HD44780 to 4-bit mode, 2 rows with 5x8 pixel characters.
The cursor can be either:
Off.
On, but not blinking.
On, blinking.
*/
lcd_init RS EN D4 D5 D6 D7 --cursor_enabled/bool=false --cursor_blink/bool=false -> none:
  //Assign incoming pins
  rs_pin_ = RS
  en_pin_ = EN
  d4_pin_ = D4
  d5_pin_ = D5
  d6_pin_ = D6
  d7_pin_ = D7

  // Default initialization: 4-bit mode, 2 rows, with 5x8 pixel characters, blinking cursor at position (0,0)
  write_byte_ INIT_SEQ_1_     LCD_CMD_ // Initialize and set to 4-bit mode
  write_byte_ INIT_SEQ_2_     LCD_CMD_
  write_byte_ TWO_ROWS_5BY8_  LCD_CMD_ // Initializes 2 rows and 5x8 pixel characters
  write_byte_ DISP_ON_        LCD_CMD_ // Turn on display, with blinking cursor
  write_byte_ INC_AND_SCROLL_ LCD_CMD_ // Mode: Cursor increment and no scroll of display
  write_byte_ DISP_CLEAR_     LCD_CMD_ // Clear LCD
  write_byte_ RETURN_HOME_    LCD_CMD_ // Cursor home
  if cursor_enabled and cursor_blink:
    write_byte_ DISP_ON_ LCD_CMD_                       // Turn on display, with blinking cursor
  else if cursor_enabled and not cursor_blink:
    write_byte_ CURSOR_NOBLINK_ LCD_CMD_                // Turn on display, no cursor blink
  else if not cursor_enabled:
    write_byte_ CURSOR_OFF_ LCD_CMD_                    // Turn on display, no cursor

/// Deprecated. Use $lcd_write instead.
LCDwrite str row/int col/int -> none:
  lcd_write str row col

/**
Writes the given string or byte array to the LCD at the given position.
For strings, only the ASCII range works, since no translation of
  character codes is performed.
For non-ASCII strings a call to $translate_to_rom_a_00 can be used to
  preprocess the string.
*/
lcd_write str row/int col/int -> none:
  // Place cursor
  if row == 0:
    write_byte_ (LCD_LINE_1_ + col) LCD_CMD_
  else if row == 1:
    write_byte_ (LCD_LINE_2_ + col) LCD_CMD_
  else:
    throw "Error: Only two line displays are supported"

  str.do: write_byte_ it LCD_DATA_

write_byte_ bits mode:
  rs_pin_.set mode // Data mode: 1 for Data, 0 for Instructions
  en_pin_.set 0    //Ensure clock is low initially

  //Upper nibble
  d7_pin_.set 0
  d6_pin_.set 0
  d5_pin_.set 0
  d4_pin_.set 0
  if bits & 0x80 == 0x80:
    d7_pin_.set 1
  if bits & 0x40 == 0x40:
    d6_pin_.set 1
  if bits & 0x20 == 0x20:
    d5_pin_.set 1
  if bits & 0x10 == 0x10:
    d4_pin_.set 1

  strobe_

  //Lower nibble
  d7_pin_.set 0
  d6_pin_.set 0
  d5_pin_.set 0
  d4_pin_.set 0
  if bits & 0x08 == 0x08:
    d7_pin_.set 1
  if bits & 0x04 == 0x04:
    d6_pin_.set 1
  if bits & 0x02 == 0x02:
    d5_pin_.set 1
  if bits & 0x01 == 0x01:
    d4_pin_.set 1

  strobe_

/// Deprecated. Use $lcd_shift_cursor instead.
LCDshiftCursor direction/string steps/int -> none:
  if direction == "right":
    lcd_shift_cursor --right steps
  else:
    lcd_shift_cursor --right=false steps

/**
Moves the cursor right or left by the given number of steps.
*/
lcd_shift_cursor --right/bool=true steps/int -> none:
  if steps < 0:
    steps = -steps
    right = not right
  direction := right ? LCD_RIGHT_ : LCD_LEFT_
  steps.repeat:
    write_byte_ (LCD_SHIFT_ | LCD_CURSOR_ | direction) LCD_CMD_

/// Deprecated. Use $lcd_shift_display instead.
LCDshiftDisplay direction/string steps/int -> none:
  if direction == "right":
    lcd_shift_display --right steps
  else:
    lcd_shift_display --right=false steps

/**
Moves the text on the display right or left by the given number of steps.
*/
lcd_shift_display --right/bool=true steps/int -> none:
  if steps < 0:
    steps = -steps
    right = not right
  direction := right ? LCD_RIGHT_ : LCD_LEFT_
  steps.repeat:
    write_byte_ (LCD_SHIFT_ | LCD_DISPLAY_ | direction) LCD_CMD_

/// Deprecated. Use $lcd_cursor_home instead.
LCDcursorHome:
  lcd_cursor_home

/**
Move cursor back to the home position.
*/
lcd_cursor_home -> none:
  write_byte_ RETURN_HOME_ LCD_CMD_ // Cursor home

/// Deprecated. Use $lcd_place_cursor instead.
LCDplaceCursor row/int col/int -> none:
  lcd_place_cursor row col

/**
Moves the cursor to the given position.
*/
lcd_place_cursor row/int col/int -> none:
  // Place cursor
  if row == 0:
    write_byte_ (LCD_LINE_1_ + col) LCD_CMD_
  else if row == 1:
    write_byte_ (LCD_LINE_2_ + col) LCD_CMD_
  else:
    throw "Error: Only two line displays are supported"

/// Deprecated. Use $lcd_clear instead.
LCDclear:
  lcd_clear

lcd_clear -> none:
  write_byte_ DISP_CLEAR_ LCD_CMD_ // Clear LCD

strobe_: //Clock in the instruction
  en_pin_.set 1
  sleep --ms=1
  en_pin_.set 0
  sleep --ms=1

/**
Translates a Unicode string to a series of bytes.
The character mapping corresponds to the ROM code A00, which is ASCII with some
  Katakana and some Western European characters.
If $with_descenders is true, then the prettier characters with descenders are
  preferred for 'g', 'j', 'p', 'q', and 'y'.  These can get too close to the
  lower line if used on the upper line.
If the input string contains Unicode characters that are not supported by the
  display then the block is called.  It is given an integer Unicode code point
  and should return a list of bytes or a string that contains only supported characters.
*/
translate_to_rom_a_00 input/string --with_descenders/bool=false [on_unsupported] -> ByteArray:
  buffer := Buffer
  input.do: | c |
    if c:
      buffer.write
        unicode_to_1602_ c --with_descenders=with_descenders on_unsupported
  return buffer.bytes

/**
Translates a Unicode string to a series of bytes.
The character mapping corresponds to the ROM code A00, which is ASCII with some
  Katakana and some Western European characters.
If $with_descenders is true, then the prettier characters with descenders are
  preferred for 'g', 'j', 'p', 'q', and 'y'.  These can get too close to the
  lower line if used on the upper line.
If the input string contains Unicode characters that are not supported by the
  display then it throws an exception.
*/
translate_to_rom_a_00 input/string --with_descenders/bool=false -> ByteArray:
  return translate_to_rom_a_00 input --with_descenders=with_descenders:
    throw "Unsupported code point: $it ('$(%c it)')"

unicode_to_1602_ c/int --with_descenders/bool=false [on_unsupported]-> ByteArray:
  if 0xff01 <= c <= 0xff5d:
    c += 0x21 - 0xff01  // Translate from halfwidth Roman Katakana range to ASCII range.

  code   := 0
  accent := 0

  if with_descenders and 'g' <= c <= 'y':
    index := c - 'g'
    // Use a binary mask with 1's where there are descenders.
      //  yxwvutsrqponmlkjihg
    if (0b1000000011000001001 >> index) & 1 != 0:
      code = c + 0x80
    else:
      code = c
  else if c < 0x100:
    code = LATIN_1_TABLE_[c]
  else if 0xff61 <= c <= 0xff9f:
    // Half-width Katakana range maps directly.
    code = c - 0xff61 + 0xa1
  else if 0x3000 <= c <= 0x300d:
    code = JAPANESE_PUNCTUATION_TABLE_[c - 0x3000]
  else if 0x309b <= c <= 0x30ff:
    // Map full width Katakana.
    code = KATAKANA_TABLE_[c - 0x309b]
    if code != 0:
      accent = DIACRITIC_TABLE_[c - 0x309b]
  else if 'Σ' <= c <= 'σ':
    code = GREEK_TABLE_[c - 'Σ']
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

  fixed := on_unsupported.call c
  if fixed is string:
    return translate_to_rom_a_00 fixed: throw "String still unsupported after calling on_unsupported"
  return fixed as ByteArray

LATIN_1_TABLE_ ::= #[
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

KATAKANA_TABLE_ ::= #[
                                                                      0xde, 0xdf, 0,    0,    0,     // 0x3090
    0,    0xa7, 0xb1, 0xa8, 0xb2, 0xa9, 0xb3, 0xaa, 0xb4, 0xab, 0xb5, 0xb6, 0xb6, 0xb7, 0xb7, 0xb8,  // 0x30a0
    0xb8, 0xb9, 0xb9, 0xba, 0xba, 0xbb, 0xbb, 0xbc, 0xbc, 0xbd, 0xbd, 0xbe, 0xbe, 0xbf, 0xbf, 0xc0,  // 0x30b0
    0xc0, 0xc1, 0xc1, 0xc1, 0xaf, 0xaf, 0xc3, 0xc3, 0xc4, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca,  // 0x30c0
    0xca, 0xca, 0xcb, 0xcb, 0xcb, 0xcc, 0xcc, 0xcc, 0xcd, 0xcd, 0xcd, 0xce, 0xce, 0xce, 0xcf, 0xd0,  // 0x30d0
    0xd1, 0xd2, 0xd3, 0xac, 0xd4, 0xad, 0xd5, 0xae, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xb8, 0xb8,  // 0x30e0
    0,    0,    0xa6, 0xdd, 0,    0,    0,    0,    0,    0,    0,    0xa5, 0xb0, 0,    0,    0x00]  // 0x30f0

// Dakuten and handakuten.
DIACRITIC_TABLE_ ::= #[
                                                                      0,    0,    0,    0,    0,     // 0x3090
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0xde, 0,    0xde, 0,     // 0x30A0
    0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,     // 0x30B0
    0xde, 0,    0xde, 0xde, 0,    0xde, 0,    0xde, 0,    0xde, 0,    0,    0,    0,    0,    0,     // 0x30C0
    0xde, 0xdf, 0,    0xde, 0xdf, 0,    0xde, 0xdf, 0,    0xde, 0xdf, 0,    0xde, 0xdf, 0,    0,     // 0x30D0
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,     // 0x30E0
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0x00]  // 0x30F0

JAPANESE_PUNCTUATION_TABLE_ ::= #[0, 0xa4, 0xa1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xa2, 0xa3]

GREEK_TABLE_ ::= #[
                0xf6,       0,    0,    0, 0, // 0x03a3-0x3a7      Σ....
    0,    0xf4, 0,    0,    0,    0,    0, 0, // 0x03a8-0x03af  .Ω......
    0,    0xe0, 0xe2, 0,    0,    0xe3, 0, 0, // 0x03b0-0x03b7  .αβ..ε..
    0xf2, 0,    0,    0,    0xe4, 0,    0, 0, // 0x03b8-0x03bf  θ...μ...
    0xf7, 0xe6, 0,    0xe5]                   // 0x03c0-0x03c3  πρ.σ
