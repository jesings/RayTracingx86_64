.global crossproduct
.global dotproduct
.global normalize
.global deg2rad
.global cos2
.global sin2
.global exponent
.global illumination
.global zeros
.global sinarg
.global cosarg
.global ambient
.global mask
.global magnitude
.global twos
.data
    .align 32
    pi: .double 3.141592658979
    ambient: .double 50, 50, 50, 0
    zeros: .double -0.0, -0.0, -0.0, -0.0
    twos: .double 2.0, 2.0, 2.0, 2.0
    negtwo: .double -2.0
    negsix: .double -6.0
    twentyfour: .double 24.0
    onetwenty: .double 120.0
    eightyoneninetytwo: .double 8192
    viewvector: .double 0,0,1,0
    sinarg: .double 0
    cosarg: .double 0
    mask: .quad 0xffffffffffffffff,0xffffffffffffffff,0xffffffffffffffff,0
.bss
.text
crossproduct://points packed in ymm0, ymm1
    vpermq $0b11001001, %ymm0, %ymm2
    vpermq $0b11010010, %ymm1, %ymm3
    vmulpd %ymm2, %ymm3, %ymm2
    vpermq $0b11010010, %ymm0, %ymm3
    vpermq $0b11001001, %ymm1, %ymm1
    vmulpd %ymm3, %ymm1, %ymm3
    vsubpd %ymm3, %ymm2, %ymm0
    ret
dotproduct://stuff in ymm0, ymm1
    vmulpd %ymm0, %ymm1, %ymm0
    vandpd mask(%rip), %ymm0, %ymm0
    vextractf128 $1, %ymm0, %xmm1
    vaddpd %ymm0, %ymm1, %ymm0
    vunpckhpd %xmm0, %xmm0, %xmm1
    vaddsd %xmm1, %xmm0, %xmm0
    ret
magnitude://stuff in ymm0
    vandpd mask(%rip), %ymm0, %ymm0
    vmulpd %ymm0, %ymm0, %ymm0
    vextractf128 $1, %ymm0, %xmm1
    vaddpd %ymm0, %ymm1, %ymm0
    vunpckhpd %xmm0, %xmm0, %xmm1
    vaddsd %xmm1, %xmm0, %xmm0
    vsqrtsd %xmm0, %xmm0, %xmm0
    ret
normalize://stuff in ymm0
    sub $32, %rsp
    vmovupd %ymm0, (%rsp)
    call magnitude
    vpbroadcastq %xmm0, %ymm1
    vmovupd (%rsp), %ymm0
    vdivpd %ymm1, %ymm0, %ymm0
    add $32, %rsp
    ret
deg2rad://converts degrees to radians
    movsd pi(%rip), %xmm1
    mulsd %xmm1, %xmm0
    mov   $180, %rax
    cvtsi2sd %rax, %xmm1
    divsd %xmm1, %xmm0
    ret
sin2:
    vmulsd eightyoneninetytwo(%rip), %xmm0, %xmm0
    vcvtsd2si %xmm0, %rdi
    lea sintable(%rip), %rsi
    mov %rdi, %rax
    add $51472, %rax
    cmp $0,%rdi
    cmovl %rax, %rdi
    vmovsd (%rsi,%rdi,8),%xmm0
    ret
cos2:
    vmulsd eightyoneninetytwo(%rip), %xmm0, %xmm0
    vcvtsd2si %xmm0, %rdi
    lea costable(%rip), %rsi
    mov %rdi, %rax
    add $51472, %rax
    cmp $0,%rdi
    cmovl %rax, %rdi
    vmovsd (%rsi,%rdi,8),%xmm0
    ret
