# HD44780
Toit driver for the HD44780 LCD controller. The driver works with 16x2 LCDs.

## Usage

A simple usage example.

```
import hd44780 as display

main:
  ...
  display.lcd_write "Hello World!" 0 0
```
For special characters you may need to call `translate_to_rom_a_00`
```
text := display.translate_to_rom_a_00 "100°C"
display.lcd_write text 0 0
```

See the `examples` folder for more examples.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/nilwes/HD44780/issues
