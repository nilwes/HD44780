// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import binary
import bytes show Buffer
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

/// Deprecated.
LCDinit RS/int EN/int D4/int D5/int D6/int D7/int cursor_enabled/int cursor_blink/int -> none:
  lcd_init RS EN D4 D5 D6 D7 --cursor_enabled=(cursor_enabled == 1) --cursor_blink=(cursor_blink == 1)

/**
Takes incoming GPIO pins and assigns them to corresponding variables. 
It also initializes the HD44780 to 4-bit mode, 2 rows with 5x8 pixel characters.
The cursor can be either:
Off.
On, but not blinking.
On, blinking.
*/
lcd_init RS/int EN/int D4/int D5/int D6/int D7/int --cursor_enabled/bool=false --cursor_blink/bool=false -> none:
  //Assign incoming pins
  RSpin = RS 
  ENpin = EN
  D4pin = D4 
  D5pin = D5
  D6pin = D6
  D7pin = D7

  // Default initialization: 4-bit mode, 2 rows, with 5x8 pixel characters, blinking cursor at position (0,0)
  write_byte_ INIT_SEQ_1     LCD_CMD // Initialize and set to 4-bit mode
  write_byte_ INIT_SEQ_2     LCD_CMD
  write_byte_ TWO_ROWS_5BY8  LCD_CMD // Initializes 2 rows and 5x8 pixel characters
  write_byte_ DISP_ON        LCD_CMD // Turn on display, with blinking cursor
  write_byte_ INC_AND_SCROLL LCD_CMD // Mode: Cursor increment and no scroll of display
  write_byte_ DISP_CLEAR     LCD_CMD // Clear LCD
  write_byte_ RETURN_HOME    LCD_CMD // Cursor home
  if cursor_enabled and cursor_blink:
    write_byte_ DISP_ON LCD_CMD                       // Turn on display, with blinking cursor
  else if cursor_enabled and not cursor_blink:
    write_byte_ CURSOR_NOBLINK LCD_CMD                // Turn on display, no cursor blink
  else if not cursor_enabled:
    write_byte_ CURSOR_OFF LCD_CMD                    // Turn on display, no cursor

/// Deprecated.
LCDwrite str row/int col/int -> none:
  lcd_write str row col

/**
Writes the given string or byte array to the LCD at the given position.
For strings, only the ASCII range will work, since no translation of
  character codes is performed.
For non-ASCII strings a call to $translate_to_rom_a_00 can be used to
  preprocess the string.
*/
lcd_write str row/int col/int -> none:
  // Place cursor
  if row == 0:
    write_byte_ (LCD_LINE_1 + col) LCD_CMD
  else if row == 1:
    write_byte_ (LCD_LINE_2 + col) LCD_CMD
  else:
    throw "Error: Only two line displays are supported"

  for i := 0 ; i < str.size ; i += 1:
    write_byte_ str[i] LCD_DATA

write_byte_ bits mode:
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

  strobe_

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

  strobe_

/// Deprecated.
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
  for i := 0 ; i < steps ; i++:
    if right:
      write_byte_ (LCD_SHIFT | LCD_CURSOR | LCD_RIGHT) LCD_CMD
    else:
      write_byte_ (LCD_SHIFT | LCD_CURSOR | LCD_LEFT)  LCD_CMD

/// Deprecated.
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
  for i := 0 ; i < steps ; i += 1: 
    if right:
      write_byte_ (LCD_SHIFT | LCD_DISPLAY | LCD_RIGHT) LCD_CMD
    else:
      write_byte_ (LCD_SHIFT | LCD_DISPLAY | LCD_LEFT)  LCD_CMD

/// Deprecated
LCDcursorHome:
  write_byte_ RETURN_HOME LCD_CMD // Cursor home

/**
Move cursor back to the home position.
*/
lcd_cursor_home -> none:
  write_byte_ RETURN_HOME LCD_CMD // Cursor home

/// Deprecated
LCDplaceCursor row/int col/int -> none:
  lcd_place_cursor row col

/**
Move cursor to a given position.
*/
lcd_place_cursor row/int col/int -> none:
  // Place cursor
  if row == 0:
    write_byte_ (LCD_LINE_1 + col) LCD_CMD
  else if row == 1:
    write_byte_ (LCD_LINE_2 + col) LCD_CMD
  else:
    throw "Error: Only two line displays are supported"

/// Deprecated.
LCDclear:
  write_byte_ DISP_CLEAR LCD_CMD // Clear LCD

lcd_clear -> none:
  write_byte_ DISP_CLEAR LCD_CMD // Clear LCD

strobe_: //Clock in the instruction
  ENpin.set 1
  sleep --ms=1
  ENpin.set 0
  sleep --ms=1

/**
Translate a Unicode string to a series of bytes.
The character mapping corresponds to the ROM code A00, which is ASCII with some
  Katakana and some Western European characters.
If $with_descenders is true, then the prettier characters with descenders are
  preferred for 'g', 'j', 'p', 'q', and 'y'.  These can get too close to the
  lower line if used on the upper line.
If the input string contains Unicode characters that are not supported by the
  display then the block is called.  It is given an integer Unicode code point
  and should return a list of bytes or a string contains only supported characters.
*/
translate_to_rom_a_00 input/string --with_descenders/bool=false [on_unsupported] -> ByteArray:
  buffer := Buffer
  input.do: | c |
    if c:
      buffer.write
        unicode_to_1602_ c --with_descenders=with_descenders on_unsupported
  return buffer.bytes

/**
Translate a Unicode string to a series of bytes.
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
  if with_descenders:
    if c == 'g'        : return #[0xe7]
    if c == 'j'        : return #[0xea]
    if c == 'p'        : return #[0xf0]
    if c == 'q'        : return #[0xf1]
    if c == 'y'        : return #[0xf9]
  if ' ' <= c <= '['   : return #[c]
  if c == '¥'          : return #[0x5c]  // Yen.
  if ']' <= c <= '}'   : return #[c]
  if c == '→'          : return #[0x7e]  // Left arrow.
  if c == '←'          : return #[0x7f]  // Right arrow.
  if c == '。'         : return #[0xa1]  // Ideographic full stop.
  if c == '「'         : return #[0xa2]  // Left corner bracket.
  if c == '」'         : return #[0xa3]  // Right corner bracket.
  if c == '、'         : return #[0xa4]  // Ideographic comma.
  if c == '·'          : return #[0xa5]  // Medium high dot.
  if c == 'ヲ'         : return #[0xa6]  // Katakana WO.
  if 'ァ' <= c <= 'ォ' : return #[0xa7 + (c - 'ァ') >> 1]  // Katakana small vowels.
  if 'ア' <= c <= 'オ' : return #[0xb1 + (c - 'ア') >> 1]  // Katakana large vowels.
  if c == 'ヮ'         : return #[0xb8]  // Katakana small wa.
  if c == 'ャ'         : return #[0xac]  // Katakana small ya.
  if c == 'ュ'         : return #[0xad]  // Katakana small yu.
  if c == 'ョ'         : return #[0xae]  // Katakana small yo.
  if c == 'ツ'         : return #[0xaf]  // Katakana TU.
  if c == 'ヅ'         : return #[0xaf, 0xbe]  // Katakana DU.
  if c == 'カ'         : return #[0xb6]  // Katakana KA.
  if c == 'ガ'         : return #[0xb6, 0xbe]  // Katakana GA.
  if c == 'キ'         : return #[0xb7]  // Katakana KI.
  if c == 'ギ'         : return #[0xb7, 0xbe]  // Katakana GI.
  if c == 'ワ'         : return #[0xb8]  // Katakana WA.
  if 'ク' <= c <= 'ド':
    // Katakana KU, KE, KO, SA, SI, SU, SE, SO, TA, TI, TU, TE, TO, and their voiced versions.
    if c >= 'ッ': c--  // Skip small tu letter.
    if c & 1 == 1:
      // Unvoiced.
      return #[((c - 'ク') >> 1) + 0xb8]
    else:
      // Voiced.
      return #[((c - 'グ') >> 1) + 0xb8, 0xde]
  if 'ナ' <= c <= 'ノ' : return #[c - 'ナ' + 0xc5]        // Katakana NA, NI, NU, NE, NO.
  if 'ハ' <= c <= 'ポ' :
    // Katakana HA, HI, HU, HE, HO, and the B- and P- versions.
    vowel := (c - 'ハ') / 3
    diacritic := (c - 'ハ') % 3
    if diacritic == 0:
      return #[0xca + vowel]
    else:
      return #[0xca + vowel, 0xdd + diacritic]
  if 'マ' <= c <= 'モ' : return #[c - 'マ' + 0xcf]        // Katakana MA, MI, MU, ME, MO.
  if c == 'ヤ'         : return #[0xd4]  // Katakana YA.
  if c == 'ユ'         : return #[0xd5]  // Katakana YU.
  if c == 'ヨ'         : return #[0xd6]  // Katakana YO.
  if 'ラ' <= c <= 'ロ' : return #[c - 'ラ' + 0xd7]        // Katakana RA, RI, RU, RE, RO.
  if c == 'ワ'         : return #[0xdc]  // Katakana WA.
  if c == 'ン'         : return #[0xdd]  // Katakana N.
  if c == 'α'          : return #[0xe0]  // Greek alpha lower case.
  if c == 'ä'          : return #[0xe1]  // A-umlaut.
  if c == 'β'          : return #[0xe2]  // Greek beta lower case.
  if c == 'ß'          : return #[0xe2]  // German double s.
  if c == 'ε'          : return #[0xe3]  // Greek epsilon lower case.
  if c == 'µ'          : return #[0xe4]  // Greek mu lower case.
  if c == 'σ'          : return #[0xe5]  // Greek sigma lower case.
  if c == 'ρ'          : return #[0xe6]  // Greek rho lower case. 
                           //   #[0xe7]  // g with descender.
  if c == '√'          : return #[0xe8]  // Square root.
                           //   #[0xe9]  // Superscript -1
                           //   #[0xea]  // j with descender.
                           //   #[0xeb]  // Superscript asterisk?
  if c == '¢'          : return #[0xec]  // Cent.
  if c == '£'          : return #[0xed]  // Pound.
  if c == 'ñ'          : return #[0xee]  // N-tilde.
  if c == 'ö'          : return #[0xef]  // O-umlaut.
                           //   #[0xf0]  // p with descender.
                           //   #[0xf1]  // q with descender.
  if c == 'θ'          : return #[0xf2]  // Greek theta lower case.
                           //   #[0xf3]  // Strange squiggle
  if c == 'Ω'          : return #[0xf4]  // Greek omega upper case.
  if c == 'Ω'          : return #[0xf4]  // Ohm symbol.
  if c == 'ü'          : return #[0xf5]  // U-umlaut.
  if c == 'Σ'          : return #[0xf6]  // Greek sigma upper case.
  if c == 'π'          : return #[0xf7]  // Greek pi lower case.
                           //   #[0xf8]  // x with overbar.
                           //   #[0xf9]  // y with descender.
                           //   #[0xfa]  // Smaller version of Japanese TI?
                           //   #[0xfb]  // Unknown Japanese Katakana.
                           //   #[0xfc]  // Unknown Japanese Katakana.
  if c == '÷'          : return #[0xfd]  // Division symbol.
                           //   #[0xfe]  // Unused.
  if c == '█'          : return #[0xff]  // Solid block.
  fixed := on_unsupported.call c
  if fixed is string:
    return unicode_to_1602_ c: throw "String still unsupported after calling on_unsupported"
  return fixed as ByteArray
