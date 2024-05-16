// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the TESTS_LICENSE file.

import expect show *
import hd44780 show *

main:
  // ASCII is not changed.
  expect-bytes-equal
    "foo".to-byte-array
    Hd44780.translate-to-rom-a-00 "foo"

  // Backslash is missing from the character ROM, so we
  // expect the error block to be called.
  expect-bytes-equal
    #[255]
    Hd44780.translate-to-rom-a-00 "\\": #[255]

  // The backslash is replaced by a Yen symbol in the pixel ROM.
  expect-bytes-equal
    "\\".to-byte-array
    Hd44780.translate-to-rom-a-00 "¥"

  HI := 0x80
  expect-bytes-equal
    #['j' + HI, 'u', 'm', 'p' + HI]
    Hd44780.translate-to-rom-a-00 "jump" --with-descenders

  alphabet := "abcdefghijklmnopqrstuvwxyz"
  descenders := ByteArray alphabet.size:
    c := alphabet[it]
    if c == 'j' or c == 'g' or c == 'p' or c == 'q' or c == 'y':
      c + HI
    else:
      c

  expect-bytes-equal
    descenders
    Hd44780.translate-to-rom-a-00 alphabet --with-descenders

  expect-bytes-equal
    "jump".to-byte-array
    Hd44780.translate-to-rom-a-00 "jump" --with-descenders=false

  // Yen-cent-pound.
  expect-bytes-equal
    #[0x5c, 0xec, 0xed]
    Hd44780.translate-to-rom-a-00 "¥¢£"

  // Katakana written in Katakana.
  expect-bytes-equal
    #[0xb6, 0xc0, 0xb6, 0xc5]
    Hd44780.translate-to-rom-a-00 "カタカナ"

  // Todo is to-to-voiced-symbol.
  expect-bytes-equal
    #[0xc4, 0xc4, 0xde]
    Hd44780.translate-to-rom-a-00 "トド"

  ho-bo-po-expected := #[0xce, 0xce, 0xde, 0xce, 0xdf]

  // Ho-bo-po is three times 0xce with following marks.
  expect-bytes-equal
    ho-bo-po-expected
    Hd44780.translate-to-rom-a-00 "ホボポ"

  // Ho-bo-po using combining unicode diacriticals
  ho-bo-po := "ホホ\u{309b}ホ\u{309c}"
  expect-bytes-equal
    ho-bo-po-expected
    Hd44780.translate-to-rom-a-00 ho-bo-po

  // The same in the half-width Katakana Unicode block.
  expect-bytes-equal
    ho-bo-po-expected
    Hd44780.translate-to-rom-a-00 "ﾎﾎﾞﾎﾟ"

  // Half-width ASCII
  expect-bytes-equal
    "AB!}".to-byte-array
    Hd44780.translate-to-rom-a-00 "ＡＢ！｝"

  // Both kinds of mu in the Greek block and the Western European block.
  expect-bytes-equal
    #[0xe4, 0xe4]
    Hd44780.translate-to-rom-a-00 "\u{03bc}\xb5"

  // Both capital Omega and the Ohm symbol.
  expect-bytes-equal
    #[0xf4, 0xf4]
    Hd44780.translate-to-rom-a-00 "\u{2126}\u{03a9}"

  // Both kinds of right and left arrow.
  expect-bytes-equal
    #[0x7e, 0x7e, 0x7f, 0x7f]
    Hd44780.translate-to-rom-a-00 "→￫←￩"

  expect-bytes-equal
    #[0xf6, 0xf4, 0xe0, 0xe2, 0xe3, 0xf2, 0xe4, 0xf7, 0xe6, 0xe5]
    Hd44780.translate-to-rom-a-00 "ΣΩαβεθμπρσ"

  // Vowel-lengthening dash-like symbol (Ramen Restaurant).
  expect-bytes-equal
    #[0xd7, 0xb0, 0xd2, 0xdd]
    Hd44780.translate-to-rom-a-00 "ラーメン"

  // Right-arrow-left-arrow.
  expect-bytes-equal
    #[0x7e, 0x7f]
    Hd44780.translate-to-rom-a-00 "→←"

  // German word with all umlauts and double S.
  expect-bytes-equal
    #['R', 0xf5, 'c', 'k', 'v', 'e', 'r', 'g', 'r', 0xef, 0xe2, 'e', 'r', 'u', 'n', 'g', 's', 'g', 'e', 'r', 0xe1, 't']
    Hd44780.translate-to-rom-a-00 "Rückvergrößerungsgerät"

  // Abuse the handakuten sign as a degree symbol.
  expect-bytes-equal
    #['2', '5', 0xdf, 'C']
    Hd44780.translate-to-rom-a-00 "25°C"

  // Use lower case umlauts to replace upper case umlauts.
  expect-bytes-equal
    Hd44780.translate-to-rom-a-00 "über"
    Hd44780.translate-to-rom-a-00 "Über":
      if it == 'Ü':
        "ü"
      else if it == 'Ä':
        "ä"
      else if it == 'Ö':
        "ö"

  // Use accent-less letters to replace é and è.
  expect-bytes-equal
    Hd44780.translate-to-rom-a-00 "ee"
    Hd44780.translate-to-rom-a-00 "èé":
      if it == 'è':
        "e"
      else if it == 'é':
        "e"
