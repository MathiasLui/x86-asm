; x86-64 Windows executable; needs kernel32; stack growing down
section .data
    msg db "Hello, World!", 0Ah, 0      ; Null-terminated string
    msg_len equ $ - msg                 ; Length of the string (current address minus address of "msg" label)

section .text
    extern GetStdHandle, WriteConsoleA, ExitProcess ; Define imports
    global _start ; make _start label visible to linker

_start:
    and rsp, -16            ; Make sure our stack pointer is 16-byte aligned, assuming the machine uses two's complement (very likely)
    push rbp                ; Save old base pointer to be safe
    mov rbp, rsp            ; Now we have our very own stack
    sub rsp, 16             ; Make space for the count, additionally making sure we still align to 16 bytes
    mov byte [rbp-1], 8     ; This is the initial count of prints (can be 255 max in the current implementation (even tho we got 16 bytes) cause why the fuck not)
    cmp byte [rbp-1], 0
    jz short cleanup        ; If the count is already zero we don't print at all
print:
    ; Get handle for stdout
    mov rcx, -11                    ; STD_OUTPUT_HANDLE is defined by Windows as dword -11, rcx is first parameter in win x86-64
    call GetStdHandle               ; call GetStdHandle
    mov rbx, rax                    ; Save stdout handle (return value in rax) in rbx

    ; Set up args for writing
    mov rcx, rbx                    ; HANDLE hConsoleOutput:            Move console handle we just got into first parameter general purpose register (rcx)
    lea rdx, [rel msg]              ; VOID *lpBuffer:                   "load effective address" of our msg into rdx (second parameter)
    mov r8, msg_len                 ; DWORD nNumberOfCharsToWrite:      move our message length into the third register (r8)
    xor r9, r9                      ; LPDWORD lpNumberOfCharsWritten:   Just pass null -- this is OUT and optional, this line is probably as useless as me doing this
    
    ; Fifth argument needs to be on the stack, according to the docs it HAS to be NULL
    sub rsp, 16         ; make space for an 8 byte pointer on the stack (assuming stack is growing down, still 16-byte aligned)...
    mov qword [rsp], 0  ; ...and set the top 8 bytes to NULL so that we pass a NULL pointer (5th+ element on win64 is passed on stack)

    ; Write "Hello, World!" to console
    call WriteConsoleA              ; finally call print

    add rsp, 16                     ; We don't need NULL ptr anymore, we will make a new one if we print again 

    dec byte [rbp-1]                ; decrease print count
    jnz short print                 ; Jump back to print again, if count not yet 0

cleanup:
    ; fun epilogue, I don't think we need this, as ExitProcess should never return
    ;mov rsp, rbp    ; restore stack pointer
    ;pop rbp         ; restore old base pointer

    ; Important though: we crash if we don't make sure the stack is aligned
    and rsp, -16    ; AND with two's complement of 16 to align to 16 bytes (set lowest 4 bits of 64 bit address to 0)

    ; Exit process
    xor rcx, rcx                    ; Exit code 0
    call ExitProcess
