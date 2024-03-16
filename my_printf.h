#ifndef MY_PRINTF_H_
#define MY_PRINTF_H_

int MyPrintf(const char* str, ...) __attribute__((format(printf, 1, 2)));
// expected register values:
// rdi = str
// rsi, rdx, rcx, r8, r9, stack = va_args
// xmm0, .., xmm7 = float args
// rax = number of floats

#endif // MY_PRINTF_H_