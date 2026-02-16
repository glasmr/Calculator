global _start

;define constants 
SYS_WRITE   equ     0x01;
SYS_READ    equ     0x0;
STDOUT      equ     0x01;
STDIN       equ     0x0;
SYS_EXIT    equ     0x3c


section .data
welcome         db  'Welcome to my ASM 4 function Calcuator!', 0xa; 'define byte' for string plus \n
welcome_len     equ $-welcome; get len of variable
enter_first     db  'Enter the first number: ', 0x0; 'define byte' for string plus null terminator
enter_first_len equ $-enter_first;
enter_sec       db  'Enter the second number: ', 0x0;
enter_sec_len   equ $-enter_sec;
ascii_error     db  'ASCII Error, entered value must be a digit!', 0xa; 
ascii_e_len     equ $-ascii_error;
get_op_welcome  db  'Enter operator ( + | - | * | / ): ', 0x0;
get_op_wel_len  equ $-get_op_welcome;
get_op_retry    db  'Please enter a valid operator!', 0xa;
get_op_ret_len  equ $-get_op_retry;

section .bss
input_buf       resq    2; reserve 1 quadword (16 bytes)
output_str      resq    2; reserve 1 quadword (8 bytes)
first_num       resq    1; reserve 1 quadword (8 bytes)
sec_num         resq    1; reserve 1 quadword (8 bytes)
result_num      resq    1; 
operator        resb    1;
garbage_byte    resb    1;

section .text

_start:
    mov rax, SYS_WRITE;
    mov rdi, STDOUT;
    mov rsi, welcome;
    mov rdx, welcome_len;
    syscall;
    
    ;get first input
    xor rdi, rdi; rdi set 0
    call get_input;
    mov [first_num], rax;

    mov rdi, 1; set rdi to 1, for second input
    call get_input;
    mov [sec_num], rax;

    call get_calc_operator;
    call calculate_result;

    ;zero output buffer
    mov rdi, output_str;
    mov rsi, 2; 2 qwords to clear
    call zero_buf

    ;display output
    mov rdi, [result_num];
    call convert_int_to_ascii
    mov rax, SYS_WRITE;
    mov rdi, STDOUT;
    mov rsi, output_str;
    mov rdx, 16;
    syscall;

    ;display \n
    mov rax, SYS_WRITE;
    mov rdi, STDOUT;
    mov rsi, 0x0a;
    mov rdx, 1;
    syscall;
    
    mov rax, SYS_EXIT;
    mov rdi, 0;
    syscall;

get_input: ;rdi, 0 = first input, !0 = second input
    ;prologue
    push rbp; push stack base pointer to stack
    mov rbp, rsp; move sp to bp
    push rdi;

    ;write input buf
    mov rax, SYS_WRITE; 
    mov rdi, STDOUT; 
    pop r8;
    cmp r8, 0;
    jnz second_input;
    mov rsi, enter_first; 
    mov rdx, enter_first_len;
    jmp input_end;
    second_input:
    mov rsi, enter_sec; 
    mov rdx, enter_sec_len;
    input_end:
    syscall;

    ;read 16 bytes to input buf
    mov rdi, input_buf;
    mov rsi, 2;
    call zero_buf;
    
    mov rax, SYS_READ;
    mov rdi, STDIN;
    mov rsi, input_buf;
    mov rdx, 16;
    syscall;

    mov rdi, input_buf; move input buf (ascii vals) into rdi for function call
    call convert_ascii_to_int; call convert ascii to int
    ;mov [first_num], rax; move returned value from function into first_num var;

    ;epilogue
    pop rbp; 
    ret;

convert_ascii_to_int: ;int convert_ascii_to_int(const char* buf), rdi: char* buf
    push rbp;
    mov rbp, rsp;
    xor rax, rax; return value
    mov rcx, 15; loop counter
    xor r11, r11;
    loop_start:
        movzx r8, byte[rdi]; move value of rdi  toget value in buf
        cmp r8, 0xa; compare value in r8, to newline
        je loop_end; jump if equal to loop end
        cmp r8, 0x2d; check if '-'
        jz handle_neg;
        cmp r8, 0x30; check if ascii digit is less than '0' 
        jl ascii_digit_error;
        cmp r8, 0x39;
        jg ascii_digit_error;

         ;total = total * 10 + (current_digit_char - '0')
        sub r8, '0'; current_chat - '0'
        imul rax, 10; total * 10 
        add rax, r8; (total * 10) + (char - '0')
        ;
        inc rdi; //move to next address in buf
        dec rcx; dec loop counter
        jnz loop_start; jump to loop start if not zero
    loop_end:

    cmp r11, 1;
    jz neg_rax;
    negative_handled:

    pop rbp;
    ret;

    handle_neg:
        mov r11, 1;set r11 to 1 if '-'
        inc rdi; 
        jmp loop_start;
    neg_rax:
        neg rax; SET RAX TO NEG
        jmp negative_handled;
    ascii_digit_error:
        mov rax, SYS_WRITE;
        mov rdi, STDOUT;
        mov rsi, ascii_error;
        mov rdx, ascii_e_len;
        syscall;
        
        mov rax, SYS_EXIT; TERMINATE program
        mov rdi, -1;
        syscall;
        


convert_int_to_ascii: ;void convert_int_to_ascii(int n); rdi: int n, writes directly to output buf
    push rbp;
    mov rbp, rsp;

    mov rax, rdi; load value into rax passed to function (out int to convert)
    lea rsi, output_str; load output_str address to rsi
    cmp rax, 0;
    jl handle_negative;
    handle_neg_return:
    mov rcx, 10; load divistor, 10 since its a base 10 number
    xor rbx, rbx; set bx to zero, will be counter
    ascii_divide_loop:
        xor rdx, rdx; set rdx zero
        idiv rcx; singed divide, quotent in rax, remaider in rdx
        push rdx; push remainder to stack.
        inc rbx;
        cmp rax, 0;
        jnz ascii_divide_loop;
    ;POP digits from stack in revser order
    mov rcx, rbx; set rcx to number of digits, this register allows 'loop' to work below (counter)
    ascii_digit_loop:
        pop rax; pop last digit from stack into rax
        add rax, 48; add 48, or '0' to rax
        mov [rsi], rax; move value at rax into location pointed to by rsi
        inc rsi; increment rsi
        loop ascii_digit_loop; loop, using rcx as counter automatically 
    
    pop rbp;
    ret;
    handle_negative:
        mov byte [rsi], 0x2d;
        inc rsi;
        neg rax;
        jmp handle_neg_return;

zero_buf:; zero buf, pointer to buf in rdi, n qwords rsi
    push rbp;
    mov rbp, rsp;
    push rax;
    push rcx;

    xor rax, rax;
    mov rcx, rsi; move num bytes into rcx
    ;shr rcx, 2; divide by 4 by shifting right 2 bits, to get n dwords (4 bytes) 

    rep stosq; repreat stosd ecx times
    pop rcx;
    pop rax;
    pop rbp;
    ret;


zero_input_buf: 
    push rbp;
    mov rbp, rsp;

    mov rcx, 16; set loop coumter
    push rdi; push old val od rdi
    mov rdi, input_buf; move *input_buf to rdi
    zero_in_buf_loop:; zero each byte
        mov byte [rdi], 0;
        inc rdi;
        loop zero_in_buf_loop;
    
    pop rdi; restore rdi
    pop rbp; restore rbp
    ret;

discard_garbage_input:
    ;loop over input until we hit \n char
    push rbp;
    mov rbp, rsp;

    push rax;
    push rdi;
    push rsi;
    push rdx;
    loop_discard_garbage:
        ;read in bytes until \n 
        mov rax, SYS_READ;
        mov rdi, STDIN;
        mov rsi, garbage_byte;
        mov rdx, 1;
        syscall;
        cmp byte [garbage_byte], 0x0a;
        jne loop_discard_garbage;
    pop rdx;
    pop rsi;
    pop rdi;
    pop rax;

    pop rbp;
    ret;

get_calc_operator:
    push rbp;
    mov rbp, rsp;
    ; write message 
    valid_operator_retry:
    mov rax, SYS_WRITE;
    mov rdi, STDOUT;
    mov rsi, get_op_welcome;
    mov rdx, get_op_wel_len;
    syscall;

    ;get input, first value
    mov byte [operator], 0;
    mov rax, SYS_READ;
    mov rdi, STDIN;
    mov rsi, operator;
    mov rdx, 1;
    syscall;

    ;discard grabage input
    call discard_garbage_input;

    cmp byte [operator], 0x2b; check if '+'
    je valid_operator;
    cmp byte [operator], 0x2d; check if '-'
    je valid_operator;
    cmp byte [operator], 0x2a; check if '*'
    je valid_operator;
    cmp byte [operator], 0x2f; check if '/'
    je valid_operator;
    jne valid_operator_err_msg;

    valid_operator:

    pop rbp;
    ret;

    valid_operator_err_msg:
        mov rax, SYS_WRITE;
        mov rdi, STDOUT;
        mov rsi, get_op_retry;
        mov rdx, get_op_ret_len;
        syscall;
        jmp valid_operator_retry;


calculate_result:
    push rbp;
    mov rbp, rsp;

    cmp byte [operator], 0x2b; check if '+'
    je addition;
    cmp byte [operator], 0x2d; check if '-'
    je subtraction;
    cmp byte [operator], 0x2a; check if '*'
    je multiplication;
    cmp byte [operator], 0x2f; check if '/'
    je division;

    addition:
    xor rax, rax;
    mov rax, [first_num];
    add rax, [sec_num];
    mov qword [result_num], rax;
    jmp calculation_done;

    subtraction:
    xor rax, rax;
    mov rax, [first_num];
    sub rax, [sec_num];
    mov qword [result_num], rax;
    jmp calculation_done;

    multiplication:
    xor rax, rax;
    mov rax, [first_num]; 
    imul rax, [sec_num];
    mov qword [result_num], rax;
    jmp calculation_done;

    division: ;only interger division
    xor rax, rax;
    ;xor rdx, rdx;
    mov rax, [first_num]; 
    mov rbx, [sec_num];
    cmp rbx, 0x00;
    jz calculation_done;
    cqo; sign extend rax into rdx 
    idiv rbx;
    mov qword [result_num], rax;

    calculation_done:
    xor rdx, rdx;

    pop rbp;
    ret;
