section .data
    prompt      db  "editor> ", 0
    prompt_len  equ $ - prompt

    filename    db "out.txt", 0
    msg_buffer  times 1024 db 0     ; max 1024 bytes

section .bss
    msg_len     resq 1              ; length of the curr line

section .text
    global _start

_start:
    ; buff length = 0
    mov qword [msg_len], 0

print_prompt:
    ; write(stdout, prompt, prompt_len)
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

read_loop:
    ; read(0, buf, 1)
    mov rax, 0
    mov rdi, 0          ; stdin
    lea rsi, [rsp - 8]  ; temp 1-byte read buffer
    mov rdx, 1
    syscall

    ; check what was read
    mov al, byte [rsp - 8]

    cmp al, 0x04        ; Ctrl+D (End)
    je  exit_program

    cmp al, 10          ; Enter key
    je  save_to_file

    cmp al, 0x7f        ; Backspace
    je  handle_backspace

    ; Add to buffer
    mov rcx, [msg_len]
    cmp rcx, 1024
    jae read_loop       ; buffer full

    mov byte [msg_buffer + rcx], al
    inc rcx
    mov [msg_len], rcx

    jmp read_loop

handle_backspace:
    mov rcx, [msg_len]
    test rcx, rcx
    jz read_loop

    dec rcx
    mov [msg_len], rcx

    ; move cursor back, overwrite with space, and move back again
    ; write("\b \b", 3)
    mov rax, 1
    mov rdi, 1
    mov rsi, backspace_seq
    mov rdx, 3
    syscall
    jmp read_loop

backspace_seq:
    db 8, 32, 8  ; "\b \b"

save_to_file:
    ; open("out.txt", O_WRONLY|O_CREAT|O_TRUNC, 0644)
    mov rax, 2
    mov rdi, filename
    mov rsi, 0x241    ; O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0o644
    syscall
    mov rbx, rax      ; save fd

    ; write(fd, buffer, msg_len)
    mov rax, 1
    mov rdi, rbx
    mov rsi, msg_buffer
    mov rdx, [msg_len]
    syscall

    ; close(fd)
    mov rax, 3
    mov rdi, rbx
    syscall

    jmp exit_program

exit_program:
    mov rax, 60
    xor rdi, rdi
    syscall

