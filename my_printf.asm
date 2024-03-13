; int my_prinf(const char* str, ...);
; rdi = str
; rsi, rdx, rcx, r8, r9, stack = va_args
; xmm0, .., xmm7 = float args
; rax = number of floats
bits 64

SYS_WRITE               equ 0x1
STDOUT_DISCR            equ 0x1
BUFFER_SIZE_MP          equ 32
MOST_SIGNIF_BIT_64      equ 0x8000000000000000
MOST_SIGNIF3_BIT_64     equ 0xe000000000000000
MOST_SIGNIF4_BIT_64     equ 0xf000000000000000
TOP_HALF                equ 0xffffffff00000000
TOP_HALF_AND_BIT        equ 0xffffffff80000000
MIDDLE_BIT_64           equ 0x0000000080000000

%macro TRY_TO_FLUSH_BUFFER_MY_PRINTF 0
        cmp r9, BUFFER_SIZE_MP - 1
        jb %%no_flush
                FLUSH_BUFFER_MY_PRINTF %1
        %%no_flush:
%endmacro

%macro FLUSH_BUFFER_MY_PRINTF 0
        mov rax, SYS_WRITE
        mov rdi, STDOUT_DISCR
        lea rsi, [rbp - 40 - BUFFER_SIZE_MP]
        mov rdx, r9
        syscall
        add rcx, r9
        xor r9, r9
%endmacro

%macro WRITE_TO_BUFFER_MY_PRINTF 1
        mov byte [rbp + r9 - 40 - BUFFER_SIZE_MP], %1
        inc r9
%endmacro

%macro TRY_TO_FLUSH_BUF_REV_MY_PRINTF 0
        test r9, r9
        jne %%no_flush
                FLUSH_BUFFER_MY_PRINTF %1
        %%no_flush:
%endmacro

%macro FLUSH_BUF_REV_MY_PRINTF 0
        mov rax, SYS_WRITE
        mov rdi, STDOUT_DISCR
        lea rsi, [rbp + r9 - 40 - BUFFER_SIZE_MP]
        mov rdx, BUFFER_SIZE_MP
        sub rdx, r9
        ; inc rdx
        ; inc rdx
        add rcx, rdx
        syscall
        mov r9, BUFFER_SIZE_MP
%endmacro

%macro WRITE_TO_BUF_REV_MY_PRINTF 1
        mov byte [rbp + r9 - 41 - BUFFER_SIZE_MP], %1
        dec r9
%endmacro

global my_printf
my_printf:
        push rbx
        push r12
        push r13
        push r14
        push r15

        push rbp
        mov rbp, rsp

        ; save args
        sub rsp, 5 * 8 + BUFFER_SIZE_MP

        mov qword [rbp - 8], r9
        mov qword [rbp - 16], r8
        mov qword [rbp - 24], rcx
        mov qword [rbp - 32], rdx
        mov qword [rbp - 40], rsi
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
                jne while_not_prst_my_printf ;//FIXME
                        ; %
                        mov r8b, [r10 + 1]
                        cmp r8b, '%'
                        je spec_proc_my_printf
                                mov r13, [r12]
                                add r12, 8
                                ; fix r12
                                lea rax, [rbp + 16 + 5 * 8]
                                cmp r12, rbp
                                cmove r12, rax
                                ; jne r12_good_my_printf
                                ;         lea r12, [rbp + 16 + 5 * 8]
                                ; r12_good_my_printf:
                                ;
                        spec_proc_my_printf:
                        inc r10
                        movzx r8, byte [r10]
                        lea rax, [r8 * 8]
                        add rax, jump_table_my_printf
                        inc r10
                        mov rax, [rax]
                        jmp rax
                while_not_prst_my_printf:

                ; write to buff
                WRITE_TO_BUFFER_MY_PRINTF{r8b}
                inc r10

                ; flush buf <- jump out table
                try_flush_my_printf:
                TRY_TO_FLUSH_BUFFER_MY_PRINTF
                jmp while_loop_printf
        while_break_my_printf:

        FLUSH_BUFFER_MY_PRINTF

        mov rax, rcx
        error_exit_my_printf:

        mov rsp, rbp
        pop rbp
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
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
        WRITE_TO_BUFFER_MY_PRINTF{'%'}
jmp try_flush_my_printf
;

; %c
char_jump_table_my_printf:
        WRITE_TO_BUFFER_MY_PRINTF{r13b}
jmp try_flush_my_printf
;

; %s
str_jump_table_my_printf:
        ; flush
        FLUSH_BUFFER_MY_PRINTF
        ; strlen
        xor r9, r9
        while_strlen_my_printf:
        inc r9
        mov r8b, [r13 + r9 - 1]
        test r8b, r8b
        jne while_strlen_my_printf
        dec r9
        ; strout:
        mov rax, SYS_WRITE
        mov rdi, STDOUT_DISCR
        mov rsi, r13
        mov rdx, r9     ; r9 here is from strlen
        syscall
        add rcx, r9
        xor r9, r9
jmp while_loop_printf   ; not try flush because buf already flused
;

; %b
bin_jump_table_my_printf:
        mov r8b, '0'
        WRITE_TO_BUFFER_MY_PRINTF{r8b}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF

        mov r8b, 'b'
        WRITE_TO_BUFFER_MY_PRINTF{r8b}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF

        mov r8, rcx     ; r8 here just tmp
        lzcnt rcx, r13
        shl r13, cl
        mov r14, rcx
        mov rcx, r8

        neg r14
        add r14, 64
        ; r14 = number of sugn bits

        do_while_loop_bin_table_my_printf:
                mov r8, r13
                mov rax, MOST_SIGNIF_BIT_64
                and r8, rax
                rol r8, 1
                add r8, '0'

                WRITE_TO_BUFFER_MY_PRINTF{r8b}
                TRY_TO_FLUSH_BUFFER_MY_PRINTF

                shl r13, 1
        dec r14
        test r14, r14
        jne do_while_loop_bin_table_my_printf
jmp try_flush_my_printf
;

; %o
oct_jump_table_my_printf:
        mov r8b, '0'
        WRITE_TO_BUFFER_MY_PRINTF{r8b}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF

        mov r8b, 'o'
        WRITE_TO_BUFFER_MY_PRINTF{r8b}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF

        mov r8, MOST_SIGNIF_BIT_64
        and r8, r13
        rol r8, 1

        test r8, r8
        je no_leading_one_oct_table_my_printf
                add r8, '0'

                WRITE_TO_BUFFER_MY_PRINTF{r8b}
                TRY_TO_FLUSH_BUFFER_MY_PRINTF
        no_leading_one_oct_table_my_printf:
        shl r13, 1

        mov r8, rcx     ; r8 here just tmp
        lzcnt rcx, r13  ; number of leading zeroes
        mov rax, rcx
        xor rdx, rdx
        mov rsi, 3
        div rsi
        mov rdi, rax    ; rdi = number of triples
        mul rsi         ; rax = bits to shift
        mov rcx, rax
        shl r13, cl     ; r13 = arg shifted to needed pos
        mov r14, rdi    ; r14 = number of triples removed
        mov rcx, r8

        ; 21 triples

        neg r14
        add r14, 21

        do_while_loop_oct_table_my_printf:
                mov r8, r13
                mov rax, MOST_SIGNIF3_BIT_64
                and r8, rax
                rol r8, 3
                add r8, '0'
                ; output
                WRITE_TO_BUFFER_MY_PRINTF{r8b}
                TRY_TO_FLUSH_BUFFER_MY_PRINTF
                ;
                shl r13, 3
        dec r14
        test r14, r14
        jne do_while_loop_oct_table_my_printf
jmp try_flush_my_printf
;

; %x
hex_jump_table_my_printf:
        mov r8b, '0'
        WRITE_TO_BUFFER_MY_PRINTF{r8b}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF

        mov r8b, 'x'
        WRITE_TO_BUFFER_MY_PRINTF{r8b}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF

        mov r8, rcx
        lzcnt rcx, r13
        mov r14, rcx
        shr r14, 2

        shr rcx, 2
        shl rcx, 2
        shl r13, cl
        mov rcx, r8

        neg r14
        add r14, 16

        do_while_loop_hex_table_my_printf:
                mov r8, r13
                mov rax, MOST_SIGNIF4_BIT_64
                and r8, rax
                rol r8, 4

                mov rax, '0'
                mov rdx, 'a' - 10
                cmp r8, 10
                cmovae rax, rdx

                add r8, rax

                WRITE_TO_BUFFER_MY_PRINTF{r8b}
                TRY_TO_FLUSH_BUFFER_MY_PRINTF

                shl r13, 4
        dec r14
        test r14, r14
        jne do_while_loop_hex_table_my_printf
jmp try_flush_my_printf
;

; %d
dec_jump_table_my_printf:
        mov r8, TOP_HALF_AND_BIT
        mov rax, r13
        and rax, r8
        mov r8, MIDDLE_BIT_64
        movsx rdx, r13d

        cmp rax, r8
        cmove r13, rdx
        ; jne fuck_32_bit_dec_my_printf
        ;         movsx r13, r13d
        ; fuck_32_bit_dec_my_printf:

        mov r8, r13
        mov rax, MOST_SIGNIF_BIT_64
        test r8, rax
        je no_minus_dec_my_printf
                TRY_TO_FLUSH_BUFFER_MY_PRINTF
                WRITE_TO_BUFFER_MY_PRINTF{'-'}
                neg r13
        no_minus_dec_my_printf:
        FLUSH_BUFFER_MY_PRINTF

        mov r9, BUFFER_SIZE_MP
        do_while_loop_dec_table_my_printf:
                mov rax, r13
                mov rsi, 10
                xor rdx, rdx
                div rsi
                mov r8, rdx
                add r8, '0'
                mov r13, rax
                WRITE_TO_BUF_REV_MY_PRINTF{r8b}
        test r13, r13
        jne do_while_loop_dec_table_my_printf

        FLUSH_BUF_REV_MY_PRINTF
        xor r9, r9
jmp while_loop_printf
;

; error
error_jump_table_my_printf:
        mov rax, -1
jmp error_exit_my_printf
;

.rodata:
jump_table_my_printf:
dq 37 dup               (error_jump_table_my_printf)
dq                      percent_jump_table_my_printf
dq 60 dup               (error_jump_table_my_printf)
dq                      bin_jump_table_my_printf
dq                      char_jump_table_my_printf
dq                      dec_jump_table_my_printf
dq 'o' - 'd' - 1 dup    (error_jump_table_my_printf)
dq                      oct_jump_table_my_printf
dq 's' - 'o' - 1 dup    (error_jump_table_my_printf)
dq                      str_jump_table_my_printf
dq 'x' - 's' - 1 dup    (error_jump_table_my_printf)
dq                      hex_jump_table_my_printf
dq 134 dup              (error_jump_table_my_printf) ; // FIXME - above
