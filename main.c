#include <stdio.h>

int my_printf(const char* str, ...) __attribute__((format(printf, 1, 2)));

int main(void) {
  int bebra = 0;
  bebra = my_printf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", -1, -1, "love", 3802, 100, 33, 127,
                                                                           -1, "love", 3802, 100, 33, 127);
  // my_printf("bebra%dbebra\n", bebra);
  return 0;
}