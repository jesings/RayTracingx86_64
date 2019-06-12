.global addpoint
.global addedge
.text
addpoint:
    // %rdi is matrix, x0:%xmm0, y0:%xmm1, z0:%xmm2, this function adds a point x,y,z,1 to a matrix
    mov 24(%rdi),%rdx
    cmp %rdx, 8(%rdi)
    jg nomemexpand
    push %rdi
    sub $48, %rsp
    vmovsd %xmm0,(%rsp)
    vmovsd %xmm1,8(%rsp)
    vmovsd %xmm2,16(%rsp)
    vmovsd %xmm3,24(%rsp)
    vmovsd %xmm4,32(%rsp)
    vmovsd %xmm5,40(%rsp)
    mov $1024, %rsi
    call resizematrix
    vmovsd (%rsp), %xmm0
    vmovsd 8(%rsp), %xmm1
    vmovsd 16(%rsp), %xmm2
    vmovsd 24(%rsp), %xmm3
    vmovsd 32(%rsp), %xmm4
    vmovsd 40(%rsp), %xmm5
    add $48, %rsp
    pop %rdi
    nomemexpand:
    mov 24(%rdi), %rax
    shl $5, %rax
    mov (%rdi),%rdx
    movsd %xmm0, (%rdx,%rax)
    movsd %xmm1, 8(%rdx,%rax)
    movsd %xmm2, 16(%rdx,%rax)
    movsd one(%rip), %xmm0
    movsd %xmm0, 24(%rdx,%rax)
    incq 24(%rdi)
    ret
addedge:
    //matrix is in %rdi, x0:%xmm0,y0:%xmm1,z0:%xmm2,x1:%xmm3,y1:%xmm4,z1:%xmm5, this function adds an edge [x,y,z,1],[x,y,z,1] to a matrix
    call addpoint
    movsd %xmm3, %xmm0
    movsd %xmm4, %xmm1
    movsd %xmm5, %xmm2
    call addpoint
    ret
