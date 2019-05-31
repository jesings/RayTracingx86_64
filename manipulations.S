.global genrotate
.global rotatez
.global rotatey
.global rotatex
.global genmanipulate
.global dilate
.global transform
.data
.bss
    .align 32
_matrixstart:
    .quad 0
.text
genmanipulate://performs an manipulation (either scaling or translation) specified in rax to matrix specified in rdi
    push %r12
    mov %rdi, _matrixstart(%rip)
    mov $4, %rdi
    mov $4, %rsi
    push %rax
    call makematrix
    mov %rax, %r12
    pop %rax
    mov %r12, %rdi
    movsd %xmm0,(%rsp)
    push %rax
    call identitymatrix
    pop %rax
    movsd (%rsp),%xmm0
    mov (%r12), %rdi
    call *%rax
    mov %r12, %rdi
    mov _matrixstart(%rip), %rsi
    mov 24(%rsi), %rax
    xchg %rax, 24(%rdi)
    mov  %rax, 24(%rsi)
    mov (%rsi), %rax
    xchg %rax, (%rdi)
    mov  %rax, (%rsi)
    call multiplymatrix
    mov %r12, %rdi
    call freematrix
    pop %r12
    ret
dilate://takes 3 params, x,y,z dilation in %xmm0-2, takes matrix in %rdi
    movsd %xmm0, (%rdi)
    movsd %xmm1, 40(%rdi)
    movsd %xmm2, 80(%rdi)
    ret
transform://takes 3 params, x,y,z offset in %xmm0-2, takes matrix in %rdi
    movsd %xmm0, 96(%rdi)
    movsd %xmm1, 104(%rdi)
    movsd %xmm2, 112(%rdi)
    movq one(%rip), %r8
    movq %r8, 120(%rdi)
    ret
.macro rotall a,b,c,d//the code in common for each rotation
    movsd %xmm0, \a(%rdi)
    movsd 16(%rsp), %xmm0
    movsd %xmm0, \b(%rdi)
    movsd 16(%rsp), %xmm1
    xorpd %xmm0, %xmm0
    subsd %xmm1, %xmm0
    movsd %xmm0, \c(%rdi)
    movsd 24(%rsp), %xmm0
    movsd %xmm0, \d(%rdi)
.endm
rotatez://takes 1 param, rotates about the z axis
    rotall 0,8,32,40
    ret
rotatex://takes 1 param, rotates about the x axis
    rotall 40,48,72,80
    ret
rotatey://takes 1 param, rotates about the y axis
    rotall 0,64,16,80
    ret
genrotate://rotates around axis specified in rax, matrix specified in rdi
    push %r12
    mov %rdi, _matrixstart(%rip)
    sub $24, %rsp
    push %rax
    movsd %xmm0, 8(%rsp)
    call sin2
    movsd %xmm0, 16(%rsp)
    movsd 8(%rsp), %xmm0
    call cos2
    movsd %xmm0, 24(%rsp)
    mov $4, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, %r12
    mov %rax, %rdi
    call identitymatrix
    mov (%r12), %rdi
    movsd 24(%rsp), %xmm0
    pop %rax
    call *%rax
    mov %r12, %rdi
    mov _matrixstart(%rip), %rsi
    mov 24(%rsi), %rax
    xchg %rax, 24(%rdi)
    mov  %rax, 24(%rsi)
    mov (%rsi), %rax
    xchg %rax, (%rdi)
    mov %rax, (%rsi)
    call multiplymatrix
    mov %r12, %rdi
    call freematrix
    add $24, %rsp
    pop %r12
    ret
