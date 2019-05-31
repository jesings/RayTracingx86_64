.global makebox
.global makesphere
.global maketorus
.set resolution,512
.set rresolution,resolution*resolution
.set rresolution2,rresolution*2
.data
    .align 32
    storage: .zero 64
    pointy3: .double 6.28318530718
    pointo3: .double 0
    negone: .double -1
.bss
.text
.macro twosides a,b,c//draws two sides of a box
    vmovapd %ymm4, %ymm0
    vaddpd %ymm\b, %ymm4, %ymm2
    vaddpd %ymm\c, %ymm4, %ymm1
    vaddpd %ymm\b, %ymm4, %ymm3
    vaddpd %ymm\c, %ymm3, %ymm3
    call quadrilateralface
    vaddpd %ymm4, %ymm\a, %ymm0
    vaddpd %ymm\b, %ymm4, %ymm1
    vaddpd %ymm\a, %ymm1, %ymm1
    vaddpd %ymm\c, %ymm4, %ymm2
    vaddpd %ymm\a, %ymm2, %ymm2
    vaddpd %ymm\b, %ymm4, %ymm3
    vaddpd %ymm\c, %ymm3, %ymm3
    vaddpd %ymm\a, %ymm3, %ymm3
    call quadrilateralface
.endm
.macro entertrig
    push %rdi
    push %rsi
    push %rax
.endm
.macro exittrig
    pop %rax
    pop %rsi
    pop %rdi
.endm
makebox://X,Y,Z in xmm0-2, h,w,d in xmm3-5
    //½ box
    sub $32, %rsp
    vsubsd %xmm5, %xmm2, %xmm8
    movsd %xmm8, 16(%rsp)
    vsubsd %xmm4, %xmm1, %xmm8
    movsd %xmm8, 8(%rsp)
    movsd %xmm0, (%rsp)
    movsd %xmm5, 24(%rsp)
    vxorpd %ymm7, %ymm7, %ymm7
    movsd 24(%rsp), %xmm7
    vpermq $0b11001111, %ymm7, %ymm7
    movsd %xmm4, 24(%rsp)
    vxorpd %ymm6, %ymm6, %ymm6
    movsd 24(%rsp), %xmm6
    vpermq $0b11110011, %ymm6, %ymm6
    movsd %xmm3, 24(%rsp)
    vxorpd %ymm5, %ymm5, %ymm5
    movsd 24(%rsp), %xmm5
    vmovups (%rsp), %ymm4
    add $32, %rsp
    //front and back
    twosides 7,5,6
    //top and bottom
    twosides 6,7,5
    //sides
    twosides 5,6,7
    ret
quadrilateralface://draws quadrilateral for a box
    sub $176, %rsp
    vmovups %ymm1, (%rsp)
    vmovups %ymm2, 24(%rsp)
    vmovups %ymm3, 48(%rsp)
    vmovups %ymm4, 72(%rsp)
    vmovups %ymm5, 96(%rsp)
    vmovups %ymm6, 120(%rsp)
    vmovups %ymm7, 144(%rsp)
    vmovups 24(%rsp), %ymm1
    vmovups (%rsp), %ymm2
    call addtri
    vmovups (%rsp), %ymm0
    vmovups 24(%rsp), %ymm1
    vmovups 48(%rsp), %ymm2
    call addtri
    vmovups 72(%rsp), %ymm4
    vmovups 96(%rsp), %ymm5
    vmovups 120(%rsp), %ymm6
    vmovups 144(%rsp), %ymm7
    add $176, %rsp
    ret
quadrilateral://draws quadrilateral for another kind of shape
    sub $80, %rsp
    vmovups %ymm1, (%rsp)
    vmovups %ymm2, 24(%rsp)
    vmovups %ymm3, 48(%rsp)
    vmovups %ymm1, %ymm4
    vmovups %ymm0, %ymm1
    vmovups %ymm4, %ymm1
    call addtri
    vmovups (%rsp), %ymm1
    vmovups 24(%rsp), %ymm0
    vmovups 48(%rsp), %ymm2
    call addtri
    add $80, %rsp
    ret
.macro handlematrixtrig a, b, c, d, e//do some grunt work trigonometry for the torus and sphere
    vmulsd pointo3(%rip), %xmm0, %xmm0
    vmulsd pointo3(%rip), %xmm1, %xmm1
    movsd %xmm0, 8(%rsp)
    movsd %xmm1, 16(%rsp)
    mov tempmatrix4(%rip), %rdi
    lea blankmatrix(%rip), %rax
    call forcematrix
    movsd 8(%rsp), %xmm0
    call sin2
    movsd %xmm0, 24(%rsp)
    movsd 8(%rsp), %xmm0
    call cos2
    mov tempmatrix4(%rip), %rdi
    mov (%rdi), %rdi
    mov one(%rip), %rax
    mov %rax, \a(%rdi)
    movsd %xmm0, \b(%rdi)
    movsd %xmm0, \c(%rdi)
    movsd 24(%rsp), %xmm0
    movsd %xmm0, \d(%rdi)
    vxorpd %ymm1, %ymm1, %ymm1
    vsubsd %xmm0, %xmm1, %xmm0
    movsd %xmm0, \e(%rdi)
    movsd 16(%rsp), %xmm0
    call sin2
    movsd %xmm0, 24(%rsp)
    movsd 16(%rsp), %xmm0
    call cos2
.endm
roundmatrix://0-resolution phi in rdi, 0-resolution theta in rsi, radius is in %xmm3, generates the points for a sphere
    sub $32, %rsp
    movsd %xmm3, (%rsp)
    vcvtsi2sd %rsi, %xmm0, %xmm0
    vcvtsi2sd %rdi, %xmm1, %xmm1
    handlematrixtrig 0,40,80,48,72
    mov tempmatrixX(%rip), %rdi
    mov (%rdi), %rdi
    vmulsd (%rsp), %xmm0, %xmm0
    movsd %xmm0, (%rdi)
    movsd 24(%rsp), %xmm0
    vmulsd (%rsp), %xmm0, %xmm0
    movsd %xmm0, 8(%rdi)
    movq $0, 16(%rdi)
    movq $0, 24(%rdi)
    mov tempmatrix4(%rip), %rdi
    mov tempmatrixX(%rip), %rsi
    call multiplymatrix
    add $32, %rsp
    ret
.macro doquad a,b,c,d//draws a quadrilateral from a set of points for a sphere or triangle
    vmovupd \a(%rax, %rdx,8), %ymm0
    vmovupd \b(%rax, %rdx,8), %ymm1
    vmovupd \c(%rax, %rdx,8), %ymm2
    vmovupd \d(%rax, %rdx,8), %ymm3
    push %rax
    push %rdx
    call quadrilateral
    pop %rdx
    pop %rax
    add $4, %rdx
.endm
.macro dotri a,b,c//draws a triangle from a set of points for a sphere or triangle
    vmovupd \a(%rax, %rdx,8), %ymm0
    vmovupd \b(%rax, %rdx,8), %ymm1
    vmovupd \c(%rax, %rdx,8), %ymm2
    push %rax
    push %rdx
    call addtri
    pop %rdx
    pop %rax
    add $4, %rdx
.endm
.macro callmatrix matrix//handles lots of trimatrix grunt work
    push %rax
    push %rcx
    mov %rdi, %rdx
    mov %rax, %rdi
    mov %rcx, %rsi
    call \matrix
    pop %rcx
    pop %rax
    mov tempmatrixX(%rip), %rdi
    mov (%rdi), %r8
    movsd (%rsp), %xmm0
    movsd 8(%rsp), %xmm1
    movsd 16(%rsp), %xmm2
    vaddsd (%r8), %xmm0, %xmm0
    movsd %xmm0, (%r8)
    vaddsd 8(%r8), %xmm1, %xmm1
    movsd %xmm1, 8(%r8)
    vaddsd 16(%r8), %xmm2, %xmm2
    movsd %xmm2, 16(%r8)
    vmovupd (%r8), %ymm0
    mov tempmatrixG(%rip), %rdx
    mov %rax, %r8
    imul $resolution, %r8
    add %rcx, %r8
    sal $2, %r8
    vmovupd %ymm0, (%rdx, %r8, 8)
    inc %rcx
    cmp $resolution, %rcx
.endm
gensphere://generates the points for a sphere in roundmatrix, does stuff with them
    mov $resolution, %r8
    vcvtsi2sd %r8, %xmm8, %xmm8
    vmovsd pointy3(%rip), %xmm7
    vdivsd %xmm8, %xmm7, %xmm7
    vmovsd %xmm7, pointo3(%rip)
    sub $32, %rsp
    movsd %xmm0, (%rsp)
    movsd %xmm1, 8(%rsp)
    movsd %xmm2, 16(%rsp)
    movsd %xmm3, 24(%rsp)
    mov $rresolution, %rdi
    mov $32, %rsi
    call calloc@PLT
    mov %rax,tempmatrixG(%rip)
    xor %rax, %rax
    startrot:
    xor %rcx, %rcx
    startcirc:
    movsd 24(%rsp), %xmm3
    callmatrix roundmatrix
    jne startcirc
    inc %rax
    cmp $resolution, %rax
    jne startrot
    add $32, %rsp
    mov tempmatrixG(%rip), %rax
    ret
gentorus://generates the points for a torus
    mov $resolution, %r8
    vcvtsi2sd %r8, %xmm8, %xmm8
    vmovsd pointy3(%rip), %xmm7
    vdivsd %xmm8, %xmm7, %xmm7
    vmovsd %xmm7, pointo3(%rip)
    movsd %xmm0, %xmm5
    .set alloclen,rresolution+resolution
    mov $alloclen, %rdi
    mov $32, %rsi
    call calloc@PLT
    mov %rax,tempmatrixG(%rip)
    xor %rax, %rax
    startrotd:
    xor %rcx, %rcx
    cvtsi2sd %rax, %xmm6
    startdonut:
    cvtsi2sd %rcx, %xmm7

    vmulsd pointo3(%rip), %xmm6 , %xmm0
    entertrig
    call cos2
    exittrig
    movsd %xmm0, %xmm8
    vmulsd pointo3(%rip), %xmm7 , %xmm0
    entertrig
    call cos2
    exittrig
    vmulsd %xmm3, %xmm0, %xmm0
    vaddsd %xmm4, %xmm0, %xmm0
    vmulsd %xmm8, %xmm0, %xmm8
    vaddsd %xmm5, %xmm8, %xmm8
#x = cos(2*M_PI * rot) * (r1 * cos(2*M_PI * circ) + r2) + cx;
    vmulsd pointo3(%rip), %xmm7 , %xmm0
    entertrig
    call sin2
    exittrig
    vmulsd %xmm0, %xmm3, %xmm0
    vaddsd %xmm0, %xmm1, %xmm9
#y = r1 * sin(2*M_PI * circ) + cy;
    vmulsd pointo3(%rip), %xmm6, %xmm0
    entertrig
    call sin2
    exittrig
    vmulsd negone(%rip), %xmm0, %xmm0
    movsd %xmm0, %xmm10
    vmulsd pointo3(%rip), %xmm7 , %xmm0
    entertrig
    call cos2
    exittrig
    vmulsd %xmm3, %xmm0, %xmm0
    vaddsd %xmm4, %xmm0, %xmm0
    vmulsd %xmm10, %xmm0, %xmm10
    vaddsd %xmm2, %xmm10, %xmm10
#z = -1*sin(2*M_PI * rot) * (r1 * cos(2*M_PI * circ) + r2) + cz;
    sub $32, %rsp
    movsd %xmm8, (%rsp)
    movsd %xmm9, 8(%rsp)
    movsd %xmm10, 16(%rsp)
    vmovupd (%rsp), %ymm8
    add $32, %rsp
    mov %rax, %r8
    imul $resolution, %r8
    add %rcx, %r8
    shl $2, %r8
    mov tempmatrixG(%rip), %rdi
    vmovupd %ymm8, (%rdi, %r8,8)

    inc %rcx
    cmp $resolution, %rcx
    jne startdonut
    inc %rax
    cmp $resolution, %rax
    jle startrotd
    mov tempmatrixG(%rip), %rax
ret
.set perlayer,resolution*4
.set pergradation,perlayer*8
.set next,32
.set last,pergradation+next
.set end2,rresolution*4
.set end3,rresolution*4-4
maketorus://matrix-ifies the tris for a torus
    push %r15
    mov %rdi, %r15
    call gentorus
    xor %rdx, %rdx
    twohunnid2:
    doquad 0,next,pergradation,last
    cmp $end3, %rdx
    jl twohunnid2
    mov %rax, %rdi
    call free@PLT
    pop %r15
    ret
makesphere://matrix-ifies the tris for a sphere
    mov %rdi, %r15
    push %r15
    call gensphere
    mov $0, %rdx
    cap:
    dotri last, pergradation, 0
    .set endcap,perlayer-4
    cmp $endcap, %rdx
    jl cap
    body:
    doquad 0,next,pergradation,last
    .set ending,rresolution2-perlayer
    cmp $ending, %rdx
    jl body
    foot:
    dotri 0,next,pergradation
    cmp $rresolution2, %rdx
    jl foot
    mov %rax, %rdi
    call free@PLT
    pop %r15
ret
