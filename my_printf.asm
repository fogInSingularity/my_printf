; %define BIN_PREFIX_ON 1
; %define OCT_PREFIX_ON 1
; %define HEX_PREFIX_ON 1

;================================================
; use of registers:
; rax = tmp
; rbx = count how many symbols where writen
; rcx = tmp
; rdx = tmp
; rsi = tmp
; rdi = tmp
; rbp = !
; rsp = !
; r8  = tmp (most of the time used for char)
; r9  = symbols in buf
; r10 = moving str pointer (1th arg)
; r11 = tmp
; r12 = pointer on arg in stack
; r13 = pass arg to table
; r14 = tmp
; r15 = tmp
;================================================

; //FIXME
;// ответить на вопрос по выызову функции
;// что происходит когда вызов функции
;// почему плачет 3 кремниевыми слезами

bits 64

SYS_WRITE               equ 0x1
STDOUT_DISCR            equ 0x1
BUFFER_SIZE_MP          equ 32
MIDDLE_BUF_SIZE_MP      equ 32

kMostSignifBit64        equ 0x8000000000000000

kErrorUnknownSpec_MyPrintf              equ -1
KErrorNullStr_MyPrintf                  equ -2
kErrorFloatPassedUnsupported_MyPrintf   equ -3

%macro TRY_TO_FLUSH_BUFFER_MY_PRINTF 0
        cmp r9, BUFFER_SIZE_MP - 1
        jb %%no_flush
                FLUSH_BUFFER_MY_PRINTF %1
        %%no_flush:
%endmacro

%macro FLUSH_BUFFER_MY_PRINTF 0
        push rcx
        push r11
        mov rax, SYS_WRITE
        mov rdi, STDOUT_DISCR
        lea rsi, [rbp - 40 - BUFFER_SIZE_MP]
        mov rdx, r9
        syscall
        add rbx, r9
        xor r9, r9
        pop r11
        pop rcx
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
        push rcx
        push r11
        mov rax, SYS_WRITE
        mov rdi, STDOUT_DISCR
        lea rsi, [rbp + r9 - 40 - BUFFER_SIZE_MP]
        mov rdx, BUFFER_SIZE_MP
        sub rdx, r9
        add rbx, rdx
        syscall
        mov r9, BUFFER_SIZE_MP
        pop r11
        pop rcx
%endmacro

%macro WRITE_TO_BUF_REV_MY_PRINTF 1
        mov byte [rbp + r9 - 41 - BUFFER_SIZE_MP], %1
        dec r9
%endmacro

;====================================================================
global MyPrintf
MyPrintf:
        push rbx
        push r12
        push r13
        push r14
        push r15

        push rbp
        mov rbp, rsp

        ; save args
        sub rsp, 6 * 8 + BUFFER_SIZE_MP ;+ MIDDLE_BUF_SIZE_MP
        and rsp, -16    ; stack alignment by 16 (for syscalls)

        mov qword [rbp - 8], r9
        mov qword [rbp - 16], r8
        mov qword [rbp - 24], rcx
        mov qword [rbp - 32], rdx
        mov qword [rbp - 40], rsi
        ; rbp - 48 - buf size = buffer
        ; rbp - 48 - buf size - middle buf size = middle buffer

        xor r9, r9      ; symbols in buffer
        mov r10, rdi    ; const char* str
        mov r15, rax    ; number of floats
        mov r12, rbp    ; pointer to arg in stack
        sub r12, 40

        test r15, r15   ; number of floats ? 0
        jne .error_float_passed_unsupported

        xor rbx, rbx
        .main_while_loop:
        mov r8b, byte [r10]
        test r8b, r8b
        je .break_main_while
                cmp r8b, '%'
                jne .if_prst ;
                        ; %
                        mov r8b, [r10 + 1]

                        ; cmp r8b, '%'
                        ; je .proc_spec

                        ; cmp r8b, 'b'
                        ; jb .errror_exit

                        ; cmp r8b, 'x'
                        ; ja .errror_exit


                        cmp r8b, '%'
                        je .proc_spec

                        mov rax, .default_spec

                        cmp r8b, 'b'
                        mov rcx, .error_invalid_spec
                        cmovb rax, rcx

                        cmp r8b, 'x'
                        mov rcx, .error_invalid_spec
                        cmova rax, rcx

                        jmp rax
                        .default_spec:

                        mov r13, [r12]
                        add r12, 8
                        ; fix r12 ------------------
                        lea rax, [rbp + 16 + 5 * 8]
                        cmp r12, rbp
                        cmove r12, rax
                        ; --------------------------

                        inc r10
                        movzx r8, byte [r10]
                        lea rax, [(r8 - 'b') * 8 + .jump_table]
                        inc r10
                        mov rax, [rax]
                        jmp rax
                .if_prst:

                ; write to buff
                WRITE_TO_BUFFER_MY_PRINTF{r8b}
                inc r10

                ; flush buf <- jump out table
                .try_to_flush:
                TRY_TO_FLUSH_BUFFER_MY_PRINTF
                jmp .main_while_loop
        .break_main_while:


        mov rax, rbx
        .errror_exit:
        FLUSH_BUFFER_MY_PRINTF

        mov rsp, rbp
        pop rbp
        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
ret
;====================================================================

; %% --------------------------------------------
.proc_spec:
        WRITE_TO_BUFFER_MY_PRINTF{'%'}
        inc r10
        inc r10
jmp .try_to_flush

; %c --------------------------------------------
.char_spec:
        WRITE_TO_BUFFER_MY_PRINTF{r13b}
jmp .try_to_flush

; %s --------------------------------------------
.str_spec: ;//FIXME
        test r13, r13
        je .error_null_str

        jmp .strlen     ; rcx = strlen
        .out_strlen:
        mov r14, rcx

        lea r8, [r9 + r14]
        cmp r8, BUFFER_SIZE_MP
        jb .str_fit_in_part_buf

        cmp r14, BUFFER_SIZE_MP
        jb .str_fit_in_buf

        jmp .str_dont_fit

        .back_to_str_spec:
jmp .main_while_loop   ; not try flush because buf already flused

; r13 = str
.strlen:
        mov rcx, r13
        .do_while_strlen:
                mov r8b, [rcx]
                inc rcx
                test r8b, r8b
        jne .do_while_strlen
        sub rcx, r13
        dec rcx
jmp .out_strlen

; r14 = strlen, r13 = arg (changes)
.str_fit_in_part_buf:
        test r14, r14
        je .skip_do_while_str_fit_prt
                .do_while_str_fit_prt:
                        mov r8b, [r13]
                        WRITE_TO_BUFFER_MY_PRINTF{r8b}
                        inc r13
                test r8b, r8b
                jne .do_while_str_fit_prt
        .skip_do_while_str_fit_prt:
jmp .back_to_str_spec

; r14 = strlen, r13 = arg (changes)
.str_fit_in_buf:
        FLUSH_BUFFER_MY_PRINTF
        jmp .str_fit_in_part_buf
jmp .back_to_str_spec

; r14 = strlen, r13 = arg
.str_dont_fit:
        FLUSH_BUFFER_MY_PRINTF
        mov rax, SYS_WRITE
        mov rdi, STDOUT_DISCR
        mov rsi, r13
        mov rdx, r14
        syscall
        add rbx, r14
jmp .back_to_str_spec

; %b --------------------------------------------
.bin_spec:
%ifdef BIN_PREFIX_ON
        WRITE_TO_BUFFER_MY_PRINTF{'0'}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF

        WRITE_TO_BUFFER_MY_PRINTF{'b'}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF
%endif

        mov r11, 1
jmp .general_base_2_spec

; %o --------------------------------------------
.oct_spec:
%ifdef OCT_PREFIX_ON
        WRITE_TO_BUFFER_MY_PRINTF{'0'}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF

        WRITE_TO_BUFFER_MY_PRINTF{'o'}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF
%endif
        mov r8, kMostSignifBit64
        and r8, r13
        rol r8, 1

        test r8, r8
        je .no_leading_1
                add r8, '0'

                WRITE_TO_BUFFER_MY_PRINTF{r8b}
                TRY_TO_FLUSH_BUFFER_MY_PRINTF
        .no_leading_1:
        shl r13, 1

        mov r11, 3
jmp .general_base_2_spec

; %x --------------------------------------------
.hex_spec:
%ifdef HEX_PREFIX_ON
        WRITE_TO_BUFFER_MY_PRINTF{'0'}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF

        WRITE_TO_BUFFER_MY_PRINTF{'x'}
        TRY_TO_FLUSH_BUFFER_MY_PRINTF
%endif

        mov r11, 4
jmp .general_base_2_spec

; base 2^n --------------------------------------

; r13 = arg, r11 = k in 2^k+1
.general_base_2_spec:
        lzcnt rcx, r13  ; rcx = zero leading bits
        mov rax, rcx
        xor rdx, rdx
        mov rsi, r11
        div rsi
        mov rdi, rax    ; rdi V
        ; mov rsi, rax    ; rsi = number of groups of zeors
        mul rsi ; ?
        mov rcx, rax

        shl r13, cl
        mov r14, rdi

        mov rax, 64
        xor rdx, rdx
        div r11

        neg r14
        add r14, rax
        ; r14 = number of groups

        ; mask:
        mov rcx, r11
        mov r15, kMostSignifBit64
        sar r15, cl
        shl r15, 1


        .while_loop_gen2k:
                mov r8, r13
                and r8, r15
                mov rcx, r11
                rol r8, cl

                mov r8b, [.conv_table + r8]
                WRITE_TO_BUFFER_MY_PRINTF{r8b}
                TRY_TO_FLUSH_BUFFER_MY_PRINTF

                mov rcx, r11
                shl r13, cl
        dec r14
        test r14, r14
        jne .while_loop_gen2k
jmp .try_to_flush

; %d --------------------------------------------
.dec_spec:
        movsx r13, r13d

        mov r8, r13
        mov rax, kMostSignifBit64
        test r8, rax
        je .if_minus_dec
                TRY_TO_FLUSH_BUFFER_MY_PRINTF
                WRITE_TO_BUFFER_MY_PRINTF{'-'}
                neg r13
        .if_minus_dec:
        FLUSH_BUFFER_MY_PRINTF

        mov r9, BUFFER_SIZE_MP
        .while_loop_dec:
                mov rax, r13
                mov rsi, 10
                xor rdx, rdx
                div rsi
                mov r8, rdx
                add r8, '0'
                mov r13, rax
                WRITE_TO_BUF_REV_MY_PRINTF{r8b}
        test r13, r13
        jne .while_loop_dec

        FLUSH_BUF_REV_MY_PRINTF
        xor r9, r9
jmp .main_while_loop

; error spec ------------------------------------
.error_invalid_spec:
        mov rax, kErrorUnknownSpec_MyPrintf
jmp .errror_exit

; error null ------------------------------------
.error_null_str:
        mov rax, KErrorNullStr_MyPrintf
jmp .errror_exit

; error float passed    ## unsupported ##   -----
.error_float_passed_unsupported:
        mov rax, kErrorFloatPassedUnsupported_MyPrintf
jmp .errror_exit
;====================================================================

.rodata:
.conv_table:    db '0123456789abcdef'

.jump_table:
dq                      .bin_spec
dq                      .char_spec
dq                      .dec_spec
dq 'o' - 'd' - 1 dup    (.error_invalid_spec)
dq                      .oct_spec
dq 's' - 'o' - 1 dup    (.error_invalid_spec)
dq                      .str_spec
dq 'x' - 's' - 1 dup    (.error_invalid_spec)
dq                      .hex_spec
