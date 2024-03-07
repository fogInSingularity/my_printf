; int my_prinf(const char* str, ...);
; rdi = str
; rsi, rdx, rcx, r8, r9, stack = va_args
; xmm0, .., xmm7 = float args
; rax = number of floats
SYS_WRITE       equ 0x1
STDOUT_DISCR    equ 0x1
BUFFER_SIZE_MP  equ 20

global my_printf
my_printf:
        ; sub rsp, 8
        push rbp
        mov rbp, rsp

        ; save args
        sub rsp, 5 * 8 + BUFFER_SIZE_MP
        mov qword [rbp - 8], r9
        mov qword [rbp - 16], r8
        mov qword [rbp - 24], rcx
        mov qword [rbp - 32], rdx
        mov qword [rbp - 40], rsi
        ; rbp - 41 ... rpp - 60 is buffer
        ; rbp - 40 - buf size = buffer

        xor r9, r9      ; symbols in buffer
        mov r10, rdi    ; const char* str
        mov r11, rax    ; number of floats
        mov r12, rbp    ; pointer to arg in stack
        sub r12, 40

        xor rcx, rcx
        while_loop_printf:
        mov r8b, byte [r10]
        test r8b, r8b
        je while_break_my_printf
                cmp r8b, '%'
                jne while_not_prst_my_printf
                        mov r13, [r12]
                        ; fix r12 //FIXME

                        ;
                        inc r10
                        movzx r8, byte [r10]
                        lea rax, [r8 * 8 + 1] ; i dont know why +1
                        add rax,  [jump_table_my_printf]
                        inc r10
                        mov rax, [rax]
                        jmp rax
                while_not_prst_my_printf:

                ; write to buff
                mov byte [rbp + r9 - 40 - BUFFER_SIZE_MP], r8b
                inc r9
                inc r10

                ; flush buf <- jump out table
                try_flush_my_printf:
                cmp r9, BUFFER_SIZE_MP - 1
                jb no_flush_my_printf
                        mov rax, SYS_WRITE
                        mov rdi, STDOUT_DISCR
                        lea rsi, [rbp - 40 - BUFFER_SIZE_MP]
                        mov rdx, r9
                        syscall
                        add rcx, r9
                        xor r9, r9
                no_flush_my_printf:
                jmp while_loop_printf
        while_break_my_printf:

        mov rax, SYS_WRITE
        mov rdi, STDOUT_DISCR
        lea rsi, [rbp - 40 - BUFFER_SIZE_MP]
        mov rdx, r9
        syscall
        add rcx, r9
        xor r9, r9

        error_exit_my_printf:

        mov rax, rcx
        mov rsp, rbp
        pop rbp
        ; add rsp, 8
        ret
; rax = tmp
; rbx = -
; rcx = count how many symbols where writen
; rdx = tmp
; rsi = tmp
; rdi = tmp
; rbp = dont use
; rsp = dont use
; r8  = tmp (most of the time used for char)
; r9  = symbols in buf
; r10 = moving str pointer (1th arg)
; r11 = number of floats
; r12 = pointer on arg in stack
; r13 = pass arg to table
; r14 = -
; r15 = -
; %%
percent_jump_table_my_printf:
        mov byte [rbp + r9 - 40 - BUFFER_SIZE_MP], '%'
        inc r9
jmp try_flush_my_printf

char_jump_table_my_printf:
        mov byte [rbp + r9 - 40 - BUFFER_SIZE_MP], r13b
        inc r9
jmp try_flush_my_printf

error_jump_table_my_printf:
        mov rax, -1
jmp error_exit_my_printf

jump_table_my_printf:
dq 36 dup       (error_jump_table_my_printf)
dq              percent_jump_table_my_printf
dq 60 dup       (error_jump_table_my_printf)
dq 'b'
dq              char_jump_table_my_printf
dq 'd'
dq 10 dup       (error_jump_table_my_printf)
dq 'o'
dq 3 dup        (error_jump_table_my_printf)
dq 's'
dq 4 dup        (error_jump_table_my_printf)
dq 'x'
dq 134 dup      (error_jump_table_my_printf)
