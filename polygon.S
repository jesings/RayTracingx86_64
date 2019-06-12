.global addtri
.global surfacenormal
.global lightloc
.global lightcolor
.global viewvect
.global Ka
.global Kd
.global Ks
.global Kad
.global Kdd
.global Ksd

.data
    .align 32
    viewvect: .double 0, 0, 1, 0
    .align 32
    Ka: .double .1, .1, .1, 0
    .align 32
    Kd: .double .5, .5, .5, 0
    .align 32
    Ks: .double .5, .5, .5, 0
    .align 32
    Kys: .double 0, 0, 0, 0
    .align 32
    Kad: .double .1, .1, .1, 0
    .align 32
    Kdd: .double .5, .5, .5, 0
    .align 32
    Ksd: .double .5, .5, .5, 0
    .align 32
    lightloc: .double -.5, -.75, -1
    .align 32
    lightcolor: .double 255, 255, 255, 0
    .align 32
    surfacenormal: .double 0, 0, 0, 0
.bss
.text
addtri://vertices packed x,y,z in %ymm0, %ymm1, %ymm2
    mov trim(%rip), %rdi
    sub $64, %rsp
    vmovupd %ymm1, (%rsp)
    vmovupd %ymm2, 32(%rsp)
    vpermq $0b01, %ymm0, %ymm1
    vpermq $0b10, %ymm0, %ymm2
    call addpoint
    movsd 0(%rsp), %xmm0
    movsd 8(%rsp), %xmm1
    movsd 16(%rsp), %xmm2
    call addpoint
    movsd 32(%rsp), %xmm0
    movsd 40(%rsp), %xmm1
    movsd 48(%rsp), %xmm2
    call addpoint
    add $64, %rsp
    ret
