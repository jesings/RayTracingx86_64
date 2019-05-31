.global addtri
.global drawtris
.global surfacenormal
.global lightloc
.global lightcolor
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
.macro store012
    movsd %xmm0, 96(%rsp)
    movsd %xmm1, 104(%rsp)
    movsd %xmm2, 112(%rsp)
    push %r8
    push %r9
    push %r10
.endm
.macro restore012
    pop %r10
    pop %r9
    pop %r8
    movsd 96(%rsp), %xmm0
    movsd 104(%rsp), %xmm1
    movsd 112(%rsp), %xmm2
.endm
drawtri://first point in ymm0, second point in ymm1, third point in ymm2, draws triangle
    push %r15
    sub $136,%rsp
    vmovups %ymm0,(%rsp)
    vmovups %ymm1,32(%rsp)
    vmovups %ymm2,64(%rsp)
    //cull backfaces
    call crossproduct//calculate cross product of 2 vectors
    call normalize//normalize resultant vectors
    vmovupd %ymm0, surfacenormal(%rip)
    lea surfacenormal(%rip), %rdi
    mov zeros(%rip), %rsi
    mov %rsi, 24(%rdi)
    vmovupd viewvect(%rip), %ymm1
    call dotproduct//take the dot product of the view vector and the normalized vector
    vmovsd zeros(%rip), %xmm8
    vcomisd %xmm8, %xmm0
    ja enddraw//cull if the resultant vector is facing backwards
    vmovupd Ka(%rip), %ymm0
    vmovupd Kd(%rip), %ymm1
    vmovupd Ks(%rip), %ymm2
    vmovupd lightloc(%rip), %ymm3
    vmovupd lightcolor(%rip), %ymm4
    call illumination

    vmovups (%rsp), %ymm0
    vmovups 32(%rsp), %ymm1
    vmovups 64(%rsp), %ymm2
    call bmt//sort points 1,2,3 by bottom,middle,top
    vmovups %ymm0, (%rsp)
    vmovups %ymm1, 32(%rsp)
    vmovups %ymm2, 64(%rsp)

    movsd (%rsp), %xmm4//x coords of these points in xmm 4,6,8
    movsd 32(%rsp), %xmm6
    movsd 64(%rsp), %xmm8
    cvtsd2si 8(%rsp), %r8//y coords of these points in registers r 8,9,10
    cvtsd2si 40(%rsp), %r9
    cvtsd2si 72(%rsp), %r10
    movsd 16(%rsp), %xmm0//z coords of these points in xmmm 0,1,2
    movsd 48(%rsp), %xmm1
    movsd 80(%rsp), %xmm2

    mov %r10, %r11
    sub %r8, %r11
    cvtsi2sd %r11, %xmm13//let xmm13 be the total difference in y
    vsubsd %xmm4, %xmm8, %xmm10
    vdivsd %xmm13, %xmm10, %xmm10//divide total difference in x by total difference in y, store in xmm 10 (This is the x step for the long side)
    vsubsd %xmm0, %xmm2, %xmm12
    vdivsd %xmm13, %xmm12, %xmm2//divide total difference in z by total difference in y, store in xmm2 (This is the z step for the long side)
    mov %r9, %r11
    sub %r8, %r11
    cvtsi2sd %r11, %xmm13//let xmm13 be the difference in y on the lower short side
    vsubsd %xmm4, %xmm6, %xmm11
    vdivsd %xmm13, %xmm11, %xmm11//divide lower difference in x by lower difference in y, store in xmm11 (the x step for the bottom leg)
    vsubsd %xmm0, %xmm1, %xmm12
    vdivsd %xmm13, %xmm12, %xmm13//divide lower difference in z by lower difference in y, store in xmm13 (the z step for the bottom leg)
    movsd %xmm4, %xmm3//have x counters at xmm4 and xmm3 for long leg and bottom leg respectively
    movsd %xmm0, %xmm1//have z counters at xmm0 and xmm1 for long leg and bottom leg respectively
 
    bottommiddleloop:
    cmp %r8, %r9
    jle bmiddletoploop//if we've reached the end of the bottom leg, go to top leg section
    mov %r15, %rdi//put variable guys for bresenham2
    cvtsd2si %xmm4, %rsi
    cvtsd2si %xmm3, %rdx
    mov %r8,  %rcx
    store012
    call bresenham2
    restore012
    inc %r8//inrcrement y counter
    vaddsd %xmm10, %xmm4, %xmm4//increment long leg x counter by long leg x step
    vaddsd %xmm11, %xmm3, %xmm3//increment lower leg x counter by lower leg x step
    vaddsd %xmm2, %xmm0, %xmm0//increment long leg z counter by long leg z step
    vaddsd %xmm13, %xmm1, %xmm1//increment lower leg z counter by lower leg z step
    jmp bottommiddleloop//loop
    bmiddletoploop:
    mov %r10, %r11
    sub %r9, %r11
    cvtsi2sd %r11, %xmm12//let xmm12 be the difference in y on the upper short side
    vsubsd %xmm6, %xmm8, %xmm11
    vdivsd %xmm12, %xmm11, %xmm11//divide upper difference in x by upper difference in y, store in xmm11 (the x step for the upper leg)
    movsd 48(%rsp), %xmm14
    movsd %xmm14, %xmm1//set long leg z counter to initial value (not really necessary)
    movsd 80(%rsp), %xmm15
    vsubsd %xmm14, %xmm15, %xmm13
    vdivsd %xmm12, %xmm13, %xmm13//divide lower difference in z by lower difference in y, store in xmm13 (the z step for the bottom leg)
    middletoploop:
    cmp %r9, %r10
    jle enddraw//if we've reached the end of the bottom leg, finish
    mov %r15, %rdi//put variable guys for bresenham2
    cvtsd2si %xmm4, %rsi
    cvtsd2si %xmm6, %rdx
    mov %r9, %rcx
    store012
    call bresenham2
    restore012
    inc %r9//inrcrement y counter
    vaddsd %xmm10, %xmm4, %xmm4//increment long leg x counter by long leg x step
    vaddsd %xmm11, %xmm6, %xmm6//increment upper leg x counter by upper leg x step
    vaddsd %xmm2, %xmm0, %xmm0//increment long leg z counter by long leg z step
    vaddsd %xmm13, %xmm1, %xmm1//increment upper leg z counter by upper leg z step
    jmp middletoploop//loop
    enddraw:
    add $136, %rsp
    pop %r15
    ret
.macro swapit a,b,c,d,e
    vcomisd %xmm\d, %xmm\c
    jb \e
    vmovups \a(%rsp), %ymm3
    vmovups \b(%rsp), %ymm4
    vmovups %ymm4, \a(%rsp)
    vmovups %ymm3, \b(%rsp)
    movsd %xmm\c, %xmm3
    movsd %xmm\d, %xmm\c
    movsd %xmm3, %xmm\d
    \e:
.endm
bmt: //finds bottom, middle, and top points of all the 3 ymm registers
    sub $136, %rsp
    vmovups %ymm0,(%rsp)
    vmovups %ymm1,32(%rsp)
    vmovups %ymm2,64(%rsp)
    vpermq $0b01, %ymm0, %ymm0
    vpermq $0b01, %ymm1, %ymm1
    vpermq $0b01, %ymm2, %ymm2
    swapit 32,64,1,2,twolower
    swapit 0,32,0,1,onelower
    swapit 32,64,1,2,zerolower
    vmovups (%rsp), %ymm0
    vmovups 32(%rsp), %ymm1
    vmovups 64(%rsp), %ymm2
    add $136, %rsp
    ret
drawtris://draws all triangles in the trimatrix
    mov trim(%rip), %rdi
    mov 24(%rdi), %rax
    mov (%rdi), %rdi
    sub $3, %rax
    trisl:
    mov %rax, %rcx
    sal $2, %rcx
    vmovupd (%rdi,%rcx,8), %ymm0
    add $4, %rcx
    vmovupd (%rdi,%rcx,8), %ymm1
    add $4, %rcx
    vmovupd (%rdi,%rcx,8), %ymm2
    push %rax
    push %rcx
    push %rdi
    call drawtri
    pop %rdi
    pop %rcx
    pop %rax
    sub $3, %rax
    cmp $0, %rax
    jge trisl
    ret
