.global makematrix
.global resizematrix
.global copymatrix
.global freematrix
.global multiplymatrix
.global printmatrix
.global matrixstart
.global forcematrix
.global identitymatrix
.global beziermatrix
.global hermitematrix
.global blankmatrix
.global newl
.global one
.data
.align 16
matrixstart:
    .quad 0
format:
    .asciz "%f "
.align 16
newl:
    .asciz "\n"
.align 16
indices:
    .quad 0,4,8,12
one:
    .double 1.0
scalar:
    .double 1.0
identmatrix:
    .double 1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1
beziermatrix:
    .double -1,3,-3,1,3,-6,3,0,-3,3,0,0,1,0,0,0
hermitematrix:
    .double 2,-3,0,1,-2,3,0,0,1,-2,1,0,1,-1,0,0
blankmatrix:
    .double 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
//param order rdi, rsi, rdx, rcx, r8, r9
//return value in rax
.text
makematrix://makes a matrix with %rdi columns and %rsi rows, and returns its reference in %rax
    //columns put on the stack
    push %rdi//number of columns
    push %rsi
    movq $32, %rdi
    call malloc@PLT
    pop %rsi
    pop %rdi
    mov %rax, matrixstart(%rip)
    //allocate space for the matrix
    push %rdi
    push %rsi
    imul %rsi, %rdi
    shl $3, %rdi//length of array in bytes
    call malloc@PLT
    pop %rsi
    pop %rdi
    //populates fields of the matrix pseudo-struct properly
    movq matrixstart(%rip), %rcx
    movq %rax, (%rcx)
    movq %rdi, 8(%rcx)
    movq %rsi, 16(%rcx)
    movq $0, 24(%rcx)
    //sets return value
    movq matrixstart(%rip), %rax
    ret

resizematrix://adds %rsi columns to matrix %rdi, no return val
    movq %rdi, matrixstart(%rip)
    movq 8(%rdi), %rdx
    addq %rsi, %rdx
    movq %rdx, 8(%rdi)
    movq %rdx, %rsi
    shlq $5, %rsi
    movq (%rdi), %rdi
    call realloc@PLT
    movq matrixstart(%rip), %rdi
    movq %rax, (%rdi)
    ret

copymatrix://makes a deepcopy of matrix %rdi, returns the pointer to that new matrix
    mov %rdi, matrixstart(%rip)
    push %rdi
    mov 8(%rdi), %rdi
    mov $4, %rsi
    call makematrix
    pop %rbx
    push %rax
    //new matrix made, copy fields of pseudo-struct, find array addresses, and memcpy
    movq (%rax), %rdi
    movq (%rbx), %rsi
    movq 8(%rbx), %rdx
    imul 16(%rbx), %rdx
    shl $3, %rdx
    push %rdi
    call memcpy@PLT
    pop %rdi
    pop %rax
    mov 24(%rdi), %rdx
    mov %rdx, 24(%rax)
    ret

freematrix://frees the memory of matrix %rdi, no return value
    mov %rdi, matrixstart(%rip)
    movq (%rdi), %rdi
    call free@PLT//array freed
    movq matrixstart(%rip), %rdi
    call free@PLT//pseudo-struct freed
    ret

printmatrix://prints matrix %rdi, no return value
    mov %rdi, matrixstart(%rip)
    push %r14
    push %r13
    push %rbx
    sub $8, %rsp //align to the 16 byte boundary, there's a better way to do this
    mov $0, %r13
    poloop:
    mov matrixstart(%rip), %rcx
    cmp 16(%rcx), %r13
    je peloop
    mov $0, %r14
    piloop:
    mov %r14, %rax
    mov %r13, %rbx
    shl $2, %rax
    add %rax, %rbx
    mov matrixstart(%rip), %rcx
    movq (%rcx), %rdx
    movsd (%rdx,%rbx,8), %xmm0 //found double to print, set arguments to print it
    lea format(%rip), %rdi
    mov $1, %rax
    call printf@PLT
    inc %r14
    mov matrixstart(%rip), %rcx
    //loop stuff
    cmp 24(%rcx),%r14
    jl piloop
    inc %r13
    lea newl(%rip), %rdi
    mov $0, %rax
    call printf@PLT
    jmp poloop
    peloop:
    add $8, %rsp
    pop %rbx
    pop %r13
    pop %r14
    ret

identitymatrix:
    lea identmatrix(%rip), %rax
    call forcematrix
    ret

forcematrix://turns square matrix %rdi into an bezier matrix, matrix to force is in rax
    movq $4,8(%rdi)
    movq $4,24(%rdi)
    mov (%rdi),%rdi
    push %r14
    mov $0, %r14
    boloop:
    vmovups (%rax,%r14,8),%ymm0
    vmovupd %ymm0, (%rdi,%r14,8)
    add $4, %r14
    cmp $16, %r14
    jne boloop
    pop %r14
    ret

multiplymatrix: //multiplies matrix1 rdi, matrix2 rsi, stores resulting matrix in rsi, no return value
    vmovdqu indices(%rip), %ymm4
    vpcmpeqq %ymm8, %ymm8, %ymm8
    mov (%rdi),%rax
    vmovupd %ymm8, %ymm3
    vgatherqpd %ymm3, (%rax,%ymm4,8), %ymm0
    vmovupd %ymm8, %ymm3
    vgatherqpd %ymm3, 8(%rax,%ymm4,8), %ymm1
    vmovupd %ymm8, %ymm3
    vgatherqpd %ymm3, 16(%rax,%ymm4,8), %ymm2
    vmovupd %ymm8, %ymm5
    vgatherqpd %ymm5, 24(%rax,%ymm4,8), %ymm3

    mov 24(%rsi), %r10
    xor %rax, %rax
    xor %rcx, %rcx
    mov (%rsi), %rdx
    loop_layer_0:
    vmovupd (%rdx, %rcx), %ymm5
    //properly accumulate data

    vmulpd %ymm0, %ymm5, %ymm9
    vmulpd %ymm1, %ymm5, %ymm10
    vmulpd %ymm2, %ymm5, %ymm11
    vmulpd %ymm3, %ymm5, %ymm12
    vextractf128 $1, %ymm9, %xmm5
    vextractf128 $1, %ymm10, %xmm6
    vextractf128 $1, %ymm11, %xmm7
    vextractf128 $1, %ymm12, %xmm8
    vaddpd %xmm9, %xmm5, %xmm9
    vaddpd %xmm10, %xmm6, %xmm10
    vaddpd %xmm11, %xmm7, %xmm11
    vaddpd %xmm12, %xmm8, %xmm12
    vunpckhpd %xmm9, %xmm9, %xmm5
    vunpckhpd %xmm10, %xmm10, %xmm6
    vunpckhpd %xmm11, %xmm11, %xmm7
    vunpckhpd %xmm12, %xmm12, %xmm8
    vaddsd %xmm5, %xmm9, %xmm9
    vaddsd %xmm6, %xmm10, %xmm10
    vaddsd %xmm7, %xmm11, %xmm11
    vaddsd %xmm8, %xmm12, %xmm12
    vmovsd %xmm9,(%rdx,%rcx)
    vmovsd %xmm10,8(%rdx,%rcx)
    vmovsd %xmm11,16(%rdx,%rcx)
    vmovsd %xmm12,24(%rdx,%rcx)
    //loop stuff
    inc %rax
    add $32, %rcx
    cmp %r10,%rax
    jl loop_layer_0
    ret
