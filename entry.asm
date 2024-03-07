section .text

global  _start

extern  main

_start:
        call main

        mov rax, 0x1
        mov rdi, 0x1
        mov rsi, ExitMsg
        mov rdx, ExitMsgLen
        syscall

        mov rax, 0x3c
        xor rdi, rdi
        syscall

section .data

ExitMsg:        db "Called main successfully", 0x0a
ExitMsgLen      equ $ - ExitMsg