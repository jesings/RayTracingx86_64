.global cspush
.global cspop
.global cstop
.data
    .align 32
    cstop: .quad 0//top of coordinate system stack
.text
cspush://push to coordinate system stack
    mov $16, %rdi
    call malloc@PLT
    push %rax
    mov cstop(%rip), %rax
    mov (%rax),%rdi
    call copymatrix
    mov %rax, %rdx
    pop %rax
    mov %rdx, (%rax)
    mov cstop(%rip), %rsi
    mov %rsi, 8(%rax)
    mov %rax, cstop(%rip)
    ret
cspop://pop from coordinate system stack
    mov cstop(%rip), %rdi
    mov (%rdi), %rdi
    call freematrix
    mov cstop(%rip), %rdi
    mov 8(%rdi), %rsi
    mov %rsi, cstop(%rip)
    call free@PLT
    ret
