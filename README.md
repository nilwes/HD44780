# HD44780
Toit driver for the HD44780 LCD controller. The driver works with 16x2 and 20x4 LCDs.

## Usage

A simple usage example.

```
import hd44780 show *

main:
  ...
  display := Hd44780
  display.write "Hello World!"
```
For special characters you may need to call `translate_to_rom_a_00`
```
text := Hd44780.translate_to_rom_a_00 "100°C"
display.write --row=0 --column=0 text
```

See the `examples` folder for more examples.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/nilwes/HD44780/issues
