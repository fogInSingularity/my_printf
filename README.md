# My printf implementation
This is tiny printf implementation that supports %%, %c, %s, %d, %b, %o and %x format specifiers.

## Usage
Add or link `my_printf.asm` to your project and include `my_printf.h`. That's it.
```c
int MyPrintf(const char* format, ...);
```
## Target
nasm for x86-64 linux
```bash
nasm -f elf64 my_printf.asm -o my_printf.o
```

## Format specifiers

The syntax for format specifier `%type`

### Supported types

| specifier | argument format |
|-----------|-----------------|
| `%`       |  %              |
| `c`       | char            |
| `s`       | string          |
| `d`       | decimal         |
| `b`       | binary          |
| `o`       | octal           |
| `x`       | hexadecimal     |


## Return value

Upon success returns number of chars written, if error occurred return error value <= 0

### Error values

| error             | value   |
|-------------------|---------|
| unknown specifier | `-1`    |
| null pointer      | `-2`    |
| float passed      | `-3`    |


## Compiler defines

take effect if defined:

| define          | effect            |
|-----------------|-------------------|
| `BIN_PREFIX_ON` | %b starts with 0b |
| `OCT_PREFIX_ON` | %o starts with 0o |
| `HEX_PREFIX_ON` | %x starts with 0x |

## Contact me
naumov.vn@phystech.edu