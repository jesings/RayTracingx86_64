.global addtri
.global surfacenormal
.global lightloc
.global lightcolor
.global Ka
.global Kad
.global reflectivity
.global reflectivityd
.global refractivity
.global refractivityd
.global addsphere

.data
    .align 32
    Ka: .double .1, .1, .1, 0
    reflectivity: .double .375, .375, .375, 0
    refractivity: .double 0, 0, 0, 0
    Kad: .double .1, .1, .1, 0
    refractivityd: .double 0, 0, 0, 0
    reflectivityd: .double .375, .375, .375, 0
    lightloc: .double 1, 1, 1, 0
    lightcolor: .double 200, 200, 200, 0
    surfacenormal: .double 0, 0, 0, 0
    lastone: .double 0, 0, 0, 1
    indices: .quad 0,4,8,12
.bss
.text
.macro cspeek//Peek at the top of the coordinate system stack
    mov cstop(%rip), %rdi
    mov (%rdi), %rdi
.endm
.macro translatept a
    vmulpd %ymm3, %ymm\a, %ymm7
    vmulpd %ymm4, %ymm\a, %ymm8
    vmulpd %ymm5, %ymm\a, %ymm9
    vmulpd %ymm6, %ymm\a, %ymm10
    vextractf128 $1, %ymm7, %xmm11
    vextractf128 $1, %ymm8, %xmm12
    vextractf128 $1, %ymm9, %xmm13
    vextractf128 $1, %ymm10, %xmm14
    vaddpd %xmm7, %xmm11, %xmm7
    vaddpd %xmm8, %xmm12, %xmm8
    vaddpd %xmm9, %xmm13, %xmm9
    vaddpd %xmm10, %xmm14, %xmm10
    vunpckhpd %xmm7, %xmm7, %xmm11
    vunpckhpd %xmm8, %xmm8, %xmm12
    vunpckhpd %xmm9, %xmm9, %xmm13
    vunpckhpd %xmm10, %xmm10, %xmm14
    vaddsd %xmm7, %xmm11, %xmm11
    vaddsd %xmm8, %xmm12, %xmm12
    vaddsd %xmm9, %xmm13, %xmm13
    vaddsd %xmm10, %xmm14, %xmm14
    sub $32, %rsp
    vmovsd %xmm11,(%rsp)
    vmovsd %xmm12,8(%rsp)
    vmovsd %xmm13,16(%rsp)
    vmovsd %xmm14,24(%rsp)
    vmovupd (%rsp), %ymm\a
    add $32, %rsp
.endm
addtri://vertices packed x,y,z in %ymm0, %ymm1, %ymm2
    vmovupd indices(%rip), %ymm7
    vpcmpeqq %ymm8, %ymm8, %ymm8
    cspeek
    mov (%rdi), %rdi
    vmovupd %ymm8, %ymm9
    vgatherqpd %ymm9, (%rdi,%ymm7,8), %ymm3
    vmovupd %ymm8, %ymm9
    vgatherqpd %ymm9, 8(%rdi,%ymm7,8), %ymm4
    vmovupd %ymm8, %ymm9
    vgatherqpd %ymm9, 16(%rdi,%ymm7,8), %ymm5
    vmovupd %ymm8, %ymm9
    vgatherqpd %ymm9, 24(%rdi,%ymm7,8), %ymm6
    vmovupd mask(%rip), %ymm10
    vandpd %ymm10, %ymm0, %ymm0
    vandpd %ymm10, %ymm1, %ymm1
    vandpd %ymm10, %ymm2, %ymm2
    vmovupd lastone(%rip), %ymm10
    vorpd %ymm10, %ymm0, %ymm0
    vorpd %ymm10, %ymm1, %ymm1
    vorpd %ymm10, %ymm2, %ymm2
    translatept 0
    translatept 1
    translatept 2
    mov trim(%rip), %rdi
    //add them directly
    mov 24(%rdi),%rax

    add $3, 24(%rdi)
    mov 24(%rdi),%rdx
    //lets ignore increasing matrix size bc ray tracing slow, and big matrix at start
    mov %rdx, %rax
    sub $3, %rax
    shl $5, %rax
    mov (%rdi),%rdx
    vmovupd %ymm0, (%rdx,%rax)
    vmovupd %ymm1, 32(%rdx,%rax)
    vmovupd %ymm2, 64(%rdx,%rax)

    mov 32(%rdi), %rdx
    vmovupd Ka(%rip),%ymm0
    vmovupd %ymm0, (%rdx,%rax)
    vmovupd reflectivity(%rip),%ymm0
    vmovupd %ymm0, 32(%rdx,%rax)
    vmovupd refractivity(%rip),%ymm0
    vmovupd %ymm0, 64(%rdx,%rax)
    ret
addsphere:
    mov spherem(%rip), %rdi
    mov 24(%rdi), %rdx
    incq 24(%rdi)
    mov (%rdi), %rsi
    shl $5, %rdx
    mov 32(%rdi), %rcx
    push %rdi
    cspeek
    mov 32(%rdi), %r8
    vmulsd (%r8), %xmm3, %xmm3
    pop %rdi
    vmovq %xmm3, (%rcx,%rdx)

    vmovsd %xmm0, (%rsi, %rdx)
    vmovsd %xmm1, 8(%rsi, %rdx)
    vmovsd %xmm2, 16(%rsi, %rdx)
    vmovsd one(%rip), %xmm5
    vmovsd %xmm5, 24(%rsi, %rdx)
    vmovupd (%rsi, %rdx), %ymm0

    vmovupd indices(%rip), %ymm7
    vpcmpeqq %ymm8, %ymm8, %ymm8
    cspeek
    mov (%rdi), %rdi
    vmovupd %ymm8, %ymm9
    vgatherqpd %ymm9, (%rdi,%ymm7,8), %ymm3
    vmovupd %ymm8, %ymm9
    vgatherqpd %ymm9, 8(%rdi,%ymm7,8), %ymm4
    vmovupd %ymm8, %ymm9
    vgatherqpd %ymm9, 16(%rdi,%ymm7,8), %ymm5
    vmovupd %ymm8, %ymm9
    vgatherqpd %ymm9, 24(%rdi,%ymm7,8), %ymm6
    translatept 0
    vmovupd %ymm0, (%rsi, %rdx)

    sub $24, %rsp
    push %rdx
    mov $96, %rdi
    call malloc@PLT
    pop %rdx
    add $24, %rsp
    mov spherem(%rip), %rdi
    mov 32(%rdi), %rsi
    mov %rax, 8(%rsi,%rdx)

    vmovupd Ka(%rip), %ymm0
    vmovupd %ymm0, (%rax)
    vmovupd reflectivity(%rip), %ymm0
    vmovupd %ymm0, 32(%rax)
    vmovupd refractivity(%rip), %ymm0
    vmovupd %ymm0, 64(%rax)
    ret
