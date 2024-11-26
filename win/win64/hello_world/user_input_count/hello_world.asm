; x86-64 Windows executable; depends on kernel32; stack growing down
%define STD_INPUT_HANDLE -10
%define STD_OUTPUT_HANDLE -11

section .data
    world_msg db "Hello, World!", 0Ah, 0    ; Null-terminated string with newline
    world_msg_len equ $ - world_msg         ; Length of the string (current address minus address of "msg" label)
    count_msg db "Count: ", 0               ; No newline
    count_msg_len equ $ - count_msg
    count_buf db 32 dup(0)
    count_buf_len equ $ - count_buf
    count_buf_bytes_read dd 0 

section .text
    extern GetStdHandle, WriteConsoleA, ReadConsoleA, ExitProcess ; Define imports
    global _start ; make _start label visible to linker

_start:
    ; prepare
    and rsp, -16            ; Make sure our stack pointer is 16-byte aligned, assuming the machine uses two's complement (very likely)
    push rbp                ; Save old base pointer to be safe
    mov rbp, rsp            ; Now we have our very own stack
    sub rsp, 32             ; Make space for the count (rbp-4), stdOutHandle (rbp-12), stdInHandle (rbp-20), nothing (rbp-24), generic null-ptr (rbp-32), additionally making sure we still align to 16 bytes (likely because of SSE)
    ; Section: Ask for count
    ; 1. Get handle for stdout
    mov rcx, STD_OUTPUT_HANDLE  ; STD_OUTPUT_HANDLE is defined by Windows as dword -11, rcx is first parameter in win x86-64
    call GetStdHandle
    mov [rbp-12], rax           ; Save output handle on the stack for later, not in register because we assume they're volatile...
    ; 2. Set up args for print
    mov rcx, rax                ; 1. arg ...and pass to function as well
    lea rdx, [rel count_msg]    ; 2. arg
    mov r8, count_msg_len       ; 3. arg
    xor r9, r9                  ; 4. arg
    mov qword [rsp], 0          ; 5. arg on top of stack (same as rbp-32) -- it HAS to be a NULL pointer according to Microsoft
    ; 3. Ask for count
    call WriteConsoleA          ; "Count: "
    ; Section: Fetch the actual count
    ; 1. Get handle for stdin
    mov rcx, STD_INPUT_HANDLE
    call GetStdHandle
    mov [rbp-20], rax           ; Save stdin handle
    ; 2. Set up args for read
    mov rcx, rax                        ; 1. arg stdin handle
    lea rdx, [rel count_buf]            ; 2. arg OUT buffer
    mov r8, count_buf_len               ; 3. arg DWORD number of chars to read (buffer len)
    lea r9, [rel count_buf_bytes_read]  ; 4. arg LPDWORD IN OPTIONAL number of chars read
                                        ; 5. arg pass on stack, has to be NULL for ANSI mode according to Microsoft, we'll use our trusty (already existing) rbp-32 (WARN: this has to be the top of the stack)
    ; 3. Call read
    call ReadConsoleA
    lea rax, [rel count_buf_bytes_read] ; Load DWORD pointer of bytes read into rax
    mov eax, [rax]                      ; Dereference rax and put actual value into eax (to fit DWORD)
    ; 4. Set up args for int parsing
    lea rcx, [rel count_buf]
    lea rax, [rel count_buf_bytes_read] ; Load pointer...
    mov rdx, [rax]                      ; ...and dereference it
    ; 5. Parse input as int
    call parse_int
    cmp rax, 0
    jz cleanup
    ; Int could be parsed
    ; Set the count
    mov dword [rbp-4], r8d              ; This is the initial count of prints (can be uint32 max in the current implementation (even tho we got 16 bytes) cause why the fuck not)
    cmp dword [rbp-4], 0
    jz cleanup                          ; If the count is already zero we don't print at all
print:
    ; Set up args for writing
    mov rcx, [rbp-12]               ; HANDLE hConsoleOutput:            Move console handle we just got into first parameter general purpose register (rcx)
    lea rdx, [rel world_msg]        ; VOID *lpBuffer:                   "load effective address" of our msg into rdx (second parameter)
    mov r8, world_msg_len           ; DWORD nNumberOfCharsToWrite:      move our message length into the third register (r8)
    xor r9, r9                      ; LPDWORD lpNumberOfCharsWritten:   Just pass null -- this is OUT and optional, this line is probably as useless as me doing this
    
    ; Fifth argument should still be on the stack (rbp-32) -- generic NULL pointer
    ; Write "Hello, World!" to console
    call WriteConsoleA              ; finally call print

    dec dword [rbp-4]               ; decrease print count
    jnz print                       ; Jump back to print again, if count not yet 0

cleanup:
    ; fun epilogue, I don't think we need this, as ExitProcess should never return
    ;mov rsp, rbp    ; restore stack pointer
    ;pop rbp         ; restore old base pointer

    ; Important though: we crash if we don't make sure the stack is aligned
    and rsp, -16    ; AND with two's complement of 16 to align to 16 bytes (set lowest 4 bits of 64 bit address to 0)

    ; Exit process
    xor rcx, rcx                    ; Exit code 0
    call ExitProcess

; Parses an unsigned int (in decimal form) from a string, ignoring non-numbers in the process
; This means "a b4 c2 0\r\n" will be parsed as 420, it also assumes everything passed is in order
; RCX: Pointer to string
; RDX: Length of string
; OUT R8d: The parsed int32, if any, otherwise 0
; OUT RAX: Non-zero if successful
%define BASE 10
parse_int:
    ; Leaf function, we don't care about stack alignment, we're above that /hj
    push rbp                ; Save base pointer
    mov rbp, rsp            ; Make new frame
    sub rsp, 1              ; Make space for current parse char
    push rbx                ; Preserve rbx value just-in-case as we are not allowed to change it, part of it will be used later
    mov r11, rdx            ; R11 will now hold the str len instead of RDX, as RDX might get overwritten by math operations
    xor r8d, r8d            ; Zero-out final result
    xor r10, r10            ; Bit of a hack maybe? I'll set this to non-zero if we find at least one number in this string
    ; Security check
    test r11, r11           ; Compare count...
    jg detected_parsable    ; Start parsing
    ; Here we realize we have no text to parse
    jmp done_parse          ; ...and short-circuit
detected_parsable:
    ; We got something to parse
    xor r9, r9              ; Zero-out counter...
    xor eax, eax            ; ...and accumulator for the first multiplication
next_char:
    mov bl, [rcx+r9]        ; Load next char into bl (no multiplying of course, since 7-bit ascii are stored in 1 byte)
    cmp bl, 30h             ; 30h = '0'
    jl check_next           ; We are below numbers
    cmp bl, 39h             ; 39h = '9'
    jg check_next           ; We are above numbers
    ; We *should* be certain we have a number here, so set the flag
    mov r10, 1              ; Set to non-zero to indicate a success, using it because RAX is in use
    sub bl, '0'             ; Get numeric value by calculating the offset to the char '0' (let's repurpose bl)
    ; We'll use (result = 0; result = result * BASE + number_val)
    mov eax, BASE           ; rax will be our base
    mul r8d                 ; First rax = result * BASE
    mov r8d, eax            ; Then result = rax
    movzx ebx, bl           ; Match the size of bl from 8 to 32 bits of r8d so we can add them
    add r8d, ebx            ; Then result += number_val
check_next:
    inc r9                  ; Increment index
    cmp r9, r11             ; Compare current index with str len
    jl next_char            ; If still in string go to next char
done_parse:
    mov rax, r10            ; Set return value
    ; Restore
    pop rbx
    mov rsp, rbp
    pop rbp
    ret