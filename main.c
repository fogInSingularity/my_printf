#include <stdio.h>

// #include <stdio.h>
int my_printf(const char* str, ...);

int main(void) {
  unsigned long long bebra = 16;
  my_printf("%o", bebra);
  // unsigned long long zero = 0;
  // zero = ~zero;
  // printf("%x", -2);
  // printf("%llo", zero);

  // int check = my_printf("abc%c%b%s%%", 'l', bebra, "hello");
  // my_printf("a%c%s%b%%", 'a', "hello", bebra);

  // printf("my_printf ret: %d\n", check);

  return 0;
}