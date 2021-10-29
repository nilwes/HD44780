import expect show *

import hd44780 show *

main:
  // ASCII is not changed.
  expect_bytes_equal
    "foo".to_byte_array
    translate_to_rom_a_00 "foo"

  // Backslash is missing from the character ROM, so we
  // expect the error block to be called.
  expect_bytes_equal
    #[255]
    translate_to_rom_a_00 "\\": #[255]

  // The backslash is replaced by a Yen symbol in the pixel ROM.
  expect_bytes_equal
    "\\".to_byte_array
    translate_to_rom_a_00 "¥"

  HI := 0x80
  expect_bytes_equal
    #['j' + HI, 'u', 'm', 'p' + HI]
    translate_to_rom_a_00 "jump" --with_descenders

  alphabet := "abcdefghijklmnopqrstuvwxyz"
  descenders := ByteArray alphabet.size:
    c := alphabet[it]
    if c == 'j' or c == 'g' or c == 'p' or c == 'q' or c == 'y':
      c + HI
    else:
      c

  expect_bytes_equal
    descenders
    translate_to_rom_a_00 alphabet --with_descenders

  expect_bytes_equal
    "jump".to_byte_array
    translate_to_rom_a_00 "jump" --with_descenders=false

  // Yen-cent-pound.
  expect_bytes_equal
    #[0x5c, 0xec, 0xed]
    translate_to_rom_a_00 "¥¢£"

  // Katakana written in Katakana.
  expect_bytes_equal
    #[0xb6, 0xc0, 0xb6, 0xc5]
    translate_to_rom_a_00 "カタカナ"

  // Todo is to-to-voiced-symbol.
  expect_bytes_equal
    #[0xc4, 0xc4, 0xde]
    translate_to_rom_a_00 "トド"

  ho_bo_po_expected := #[0xce, 0xce, 0xde, 0xce, 0xdf]

  // Ho-bo-po is three times 0xce with following marks.
  expect_bytes_equal
    ho_bo_po_expected
    translate_to_rom_a_00 "ホボポ"

  // Ho-bo-po using combining unicode diacriticals
  ho_bo_po := "ホホ\u{309b}ホ\u{309c}"
  expect_bytes_equal
    ho_bo_po_expected
    translate_to_rom_a_00 ho_bo_po

  // The same in the half-width Katakana Unicode block.
  expect_bytes_equal
    ho_bo_po_expected
    translate_to_rom_a_00 "ﾎﾎﾞﾎﾟ"

  // Half-width ASCII
  expect_bytes_equal
    "AB!}".to_byte_array
    translate_to_rom_a_00 "ＡＢ！｝"

  // Both kinds of mu in the Greek block and the Western European block.
  expect_bytes_equal
    #[0xe4, 0xe4]
    translate_to_rom_a_00 "\u{03bc}\xb5"

  // Both capital Omega and the Ohm symbol.
  expect_bytes_equal
    #[0xf4, 0xf4]
    translate_to_rom_a_00 "\u{2126}\u{03a9}"

  // Both kinds of right and left arrow.
  expect_bytes_equal
    #[0x7e, 0x7e, 0x7f, 0x7f]
    translate_to_rom_a_00 "→￫←￩"

  expect_bytes_equal
    #[0xf6, 0xf4, 0xe0, 0xe2, 0xe3, 0xf2, 0xe4, 0xf7, 0xe6, 0xe5]
    translate_to_rom_a_00 "ΣΩαβεθμπρσ"

  // Vowel-lengthening dash-like symbol (Ramen Restaurant).
  expect_bytes_equal
    #[0xd7, 0xb0, 0xd2, 0xdd]
    translate_to_rom_a_00 "ラーメン"

  // Right-arrow-left-arrow.
  expect_bytes_equal
    #[0x7e, 0x7f]
    translate_to_rom_a_00 "→←"

  // German word with all umlauts and double S.
  expect_bytes_equal
    #['R', 0xf5, 'c', 'k', 'v', 'e', 'r', 'g', 'r', 0xef, 0xe2, 'e', 'r', 'u', 'n', 'g', 's', 'g', 'e', 'r', 0xe1, 't']
    translate_to_rom_a_00 "Rückvergrößerungsgerät"

  // Abuse the handakuten sign as a degree symbol.
  expect_bytes_equal
    #['2', '5', 0xdf, 'C']
    translate_to_rom_a_00 "25°C"

  // Use lower case umlauts to replace upper case umlauts.
  expect_bytes_equal
    translate_to_rom_a_00 "über"
    translate_to_rom_a_00 "Über":
      if it == 'Ü':
        "ü"
      else if it == 'Ä':
        "ä"
      else if it == 'Ö':
        "ö"

  // Use accent-less letters to replace é and è.
  expect_bytes_equal
    translate_to_rom_a_00 "ee"
    translate_to_rom_a_00 "èé":
      if it == 'è':
        "e"
      else if it == 'é':
        "e"
