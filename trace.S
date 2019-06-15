.global calc_rays
.data
    origin: .double 256, 256, 256, 0
    tolerance: .double 1e-12
    directionupdate: .double .01, .01, .01, 0
    maxval: .double inf
    maskupper: .quad 0xffffffffffffffff,0xffffffffffffffff,0,0
    uppergood: .double 0,0,-256,0
    four: .double 4
    negonehalf: .double -.5
.bss
.text
.macro crossprod//points packed in ymm0, ymm1
    vpermq $0b11001001, %ymm0, %ymm2
    vpermq $0b11010010, %ymm1, %ymm3
    vmulpd %ymm2, %ymm3, %ymm2
    vpermq $0b11010010, %ymm0, %ymm0
    vpermq $0b11001001, %ymm1, %ymm1
    vfmsub213pd %ymm2, %ymm1, %ymm0
.endm
.macro dotprod//stuff in ymm0, ymm1
    vmulpd %ymm0, %ymm1, %ymm0
    vextractf128 $1, %ymm0, %xmm1
    vaddpd %ymm0, %ymm1, %ymm0
    vunpckhpd %xmm0, %xmm0, %xmm1
    vaddsd %xmm1, %xmm0, %xmm0
.endm
.macro broadcastdotproduct arg1, arg2, result
    vmulpd %ymm\arg1, %ymm\arg2, %ymm\arg1
    vextractf128 $1, %ymm\arg1, %xmm\arg2
    vaddpd %ymm\arg1, %ymm\arg2, %ymm\arg1
    vunpckhpd %xmm\arg1, %xmm\arg1, %xmm\arg2
    vaddsd %xmm\arg2, %xmm\arg1, %xmm\arg1
    vpbroadcastq %xmm\arg1, %ymm\result
    vandpd mask(%rip), %ymm\result, %ymm\result
.endm
.macro clamp regname
    mov $0xff, %rdi
    cmpq $0xff, %r\regname
    cmovg %rdi, %r\regname
    xor %rdi, %rdi
    cmpq $0, %r\regname
    cmovl %rdi, %r\regname
.endm
calc_rays:
    xor %rdi, %rdi
    xcoords:
    xor %rsi, %rsi
    ycoords:

    //colory bois
    mov $4, %rdx//RECURSION DEPTH OF 4 YE :)
    push %rdi
    push %rsi
    sub $256, %rdi
    sub $256, %rsi
    
    vcvtsi2sd %rsi, %xmm0, %xmm0
    vpermq $0, %ymm0, %ymm0
    vcvtsi2sd %rdi, %xmm0, %xmm0
    vandpd maskupper(%rip), %ymm0, %ymm0
    vorpd uppergood(%rip), %ymm0, %ymm0
    call normalize
    vmovupd %ymm0, %ymm1
    vmovupd origin(%rip), %ymm0
    vmovupd lightcolor(%rip),%ymm2
    vaddpd directionupdate(%rip), %ymm0, %ymm0
    call calc_ray
    vaddpd %ymm0, %ymm1, %ymm0
    vaddpd %ymm0, %ymm2, %ymm0

    vcvtsd2si %xmm0, %rax
    vpermq $0b1001, %ymm0, %ymm0
    vcvtsd2si %xmm0, %rcx
    vpermq $0b01, %ymm0, %ymm0
    vcvtsd2si %xmm0, %rdx
    clamp ax
    clamp cx
    clamp dx
    pop %rsi
    pop %rdi

    mov %rsi, %r8
    mov %rdi, %r9
    neg %r8
    add $512, %r8
    sal $9, %r8
    add %r9, %r8
    imul $3, %r8
    lea data(%rip), %r10
    mov %al, (%r10, %r8)
    mov %cl, 1(%r10, %r8)
    mov %dl, 2(%r10, %r8)
    
    inc %rsi
    cmp $512, %rsi
    jl ycoords
    inc %rdi
    cmp $512, %rdi
    jl xcoords
    ret

calc_ray://ray origin packed in ymm0, NORMALIZED ray vector packed in ymm1, light color packed in ymm2
    //test color
    push %rbp
    mov %rsp, %rbp
    dec %rdx
    vpxor %ymm9, %ymm9, %ymm9

    vmovupd %ymm0, %ymm10
    vmovupd %ymm1, %ymm11
    vmovupd %ymm2, %ymm6
    vmovupd %ymm11, %ymm0
    call normalize
    vmovupd %ymm0, %ymm11
    mov trim(%rip), %r10
    mov 32(%r10), %rcx
    mov 24(%r10), %r11
    mov %r11, %r13
    mov (%r10), %r10
    sal $5, %r11//okay this is the byte length of the list
    add %r11, %r10//end of list here
    add %r11, %rcx
    neg %r11

    sub $256, %rsp
    vpcmpeqw %ymm7, %ymm7, %ymm7
    vpsllq $54, %ymm7, %ymm7
    vpsrlq $2, %ymm7, %ymm7
    vmovsd maxval(%rip), %xmm8
    test %r13, %r13
    jz notris

    each_tri://moller trumbore ray triangle intersection
    vmovupd mask(%rip), %ymm3
    vandpd (%r10,%r11),   %ymm3, %ymm0
    vandpd 32(%r10,%r11), %ymm3, %ymm1
    vandpd 64(%r10,%r11), %ymm3, %ymm2//vertices stored here very temporarily

    vmovupd %ymm0, 64(%rsp)
    vsubpd %ymm0, %ymm1, %ymm1
    vmovupd %ymm1,(%rsp)
    vsubpd %ymm0, %ymm2, %ymm1
    vmovupd %ymm1,32(%rsp)

    vmovupd %ymm11, %ymm0
    crossprod//direction ray x v2v0
    vmovupd %ymm0, %ymm15//pvec temporarily in ymm15
    vmovupd (%rsp), %ymm1
    dotprod
    vmovupd %ymm0, %ymm12//determinant in ymm12
    vcomisd tolerance(%rip), %xmm0
    jb no_add_ray//cull backfaces and near-0 determinant values

    vdivsd %xmm12, %xmm7, %xmm13//inverse determinant in  xmm13

    vsubpd 64(%rsp), %ymm10, %ymm5//tvec in ymm5
    vmovupd %ymm15, %ymm0
    vmovupd %ymm5, %ymm1
    dotprod
    vmulsd %xmm13, %xmm0, %xmm14//u in xmm14

    vcomisd zeros(%rip), %xmm14
    jna no_add_ray
    vcomisd %xmm7, %xmm14
    jnb no_add_ray//cull no-intersect from u

    vmovupd %ymm5, %ymm0
    vmovupd (%rsp), %ymm1
    crossprod
    vmovupd %ymm0, %ymm5//qvec in ymm5

    vmovupd %ymm11, %ymm1
    dotprod
    vmulsd %xmm0, %xmm13, %xmm15//v in in xmm15

    vcomisd zeros(%rip), %xmm15
    jna no_add_ray
    vaddsd %xmm14, %xmm15, %xmm0
    vcomisd %xmm7, %xmm0
    jnb no_add_ray//cull no-intersect from v, v+u

    vmovupd 32(%rsp), %ymm0
    vmovupd %ymm5, %ymm1
    dotprod
    vmulsd %xmm0, %xmm13, %xmm0
    
    vcomisd %xmm8, %xmm0
    jnb no_add_ray
    vmovsd %xmm0, %xmm0, %xmm8
    vmovupd (%rsp), %ymm0
    vmovupd 32(%rsp), %ymm1
    crossprod
    vmovupd %ymm0, %ymm9
    mov %r11, %r12
    add %rcx, %r12

    no_add_ray:
    add $96, %r11
    js each_tri
    notris:
    mov spherem(%rip), %r10
    mov 32(%r10), %rcx
    mov 24(%r10), %r11
    test %r11, %r11
    jz nospheres
    mov (%r10), %r10
    sal $5, %r11//okay this is the byte length of the list
    add %r11, %r10//end of list here
    add %r11, %rcx
    neg %r11
    each_sphere:
    vmovupd mask(%rip), %ymm3
    vandpd (%r10,%r11), %ymm3, %ymm5//ymm5 is center
    vmovsd (%rcx,%r11), %xmm3//xmm3 is radius
    vmulsd %xmm3, %xmm3, %xmm3//xmm3 is radius2

    vsubpd %ymm10, %ymm5, %ymm12//ymm12 is L

    vmovupd %ymm12, %ymm0
    vmovupd %ymm11, %ymm1
    dotprod
    vmovsd %xmm0, %xmm0, %xmm13//tca in xmm13

    vmulsd %xmm13, %xmm13, %xmm14
    vmovupd %ymm12, %ymm0
    vmovupd %ymm12, %ymm1
    dotprod
    vsubsd %xmm14, %xmm0, %xmm14//d2 in xmm14
    vcomisd %xmm3, %xmm14
    ja no_circle_ray
    vsubsd %xmm14, %xmm3, %xmm2
    vsqrtsd %xmm2, %xmm2, %xmm2
    vsubsd %xmm2, %xmm13, %xmm4
    vaddsd %xmm2, %xmm13, %xmm2
    vminsd %xmm4, %xmm2, %xmm0
    vmaxsd %xmm4, %xmm2, %xmm1

    vcomisd zeros(%rip), %xmm0
    ja goodjob
    vcomisd zeros(%rip), %xmm1
    jb no_circle_ray
    vmovsd %xmm1, %xmm1, %xmm0
    goodjob:
    vcomisd %xmm8, %xmm0
    jnb no_circle_ray
    vmovsd %xmm0, %xmm0, %xmm8

    vpbroadcastq %xmm0, %ymm0
    vmulpd %ymm0, %ymm11, %ymm1
    vaddpd %ymm10, %ymm1, %ymm1
    vsubpd %ymm5, %ymm1, %ymm9
    mov 8(%rcx, %r11), %r12

    no_circle_ray:
    add $32, %r11
    js each_sphere
    nospheres:

    vcomisd maxval(%rip), %xmm8
    jnb endoftheline

    vmovupd %ymm9, %ymm0
    call normalize
    vmovupd %ymm0, %ymm9
    //for light in light sources, starting out with one
    //store registers
    vmovupd %ymm6, 96(%rsp)
    vmovupd %ymm9, 128(%rsp)
    vmovupd %ymm10, 160(%rsp)
    vmovupd %ymm11, 192(%rsp)
    vmovupd %ymm8, 224(%rsp)
    vpbroadcastq %xmm8, %ymm8//calculate direction of shadow ray
    vmulpd %ymm9, %ymm8, %ymm8
    vaddpd %ymm8, %ymm10, %ymm10
    vmovupd lightloc(%rip), %ymm1
    vxorpd zeros(%rip), %ymm1, %ymm1
    vmulpd directionupdate(%rip), %ymm1, %ymm0
    vaddpd %ymm0, %ymm10, %ymm0
    push %r12
    call shadow_ray
    pop %r12
    vmovupd 96(%rsp), %ymm6
    vmovupd 128(%rsp), %ymm9
    vmovupd 160(%rsp), %ymm10
    vmovupd 192(%rsp), %ymm11
    vmovupd 224(%rsp), %ymm8
    test %rax, %rax
    jnz inshadow//should just skip to next light source
    add $8, %rsp

    vmovupd (%r12), %ymm0
    vmovupd %ymm0, Ka(%rip)
    vmovupd 32(%r12), %ymm0
    vmovupd %ymm0, reflectivity(%rip)
    vmovupd 64(%r12), %ymm0
    vmovupd %ymm0, refractivity(%rip)

    vpcmpeqw %ymm7, %ymm7, %ymm7
    vpsllq $54, %ymm7, %ymm7
    vpsrlq $2, %ymm7, %ymm7
    vpcmpeqw %ymm13, %ymm13, %ymm13
    vpsllq $63, %ymm13, %ymm13
    vpsrlq $1, %ymm13, %ymm13//twos in place

    vmovupd lightloc(%rip), %ymm0
    call normalize
    vmovupd %ymm0, %ymm5

    //surface normal is in ymm9 first thing is reflected ray
    vmovupd %ymm9, %ymm1
    broadcastdotproduct 0,1,12

    vmovupd lightloc(%rip), %ymm0
    call normalize
    vmovupd %ymm0, %ymm14

    vmovupd Ka(%rip), %ymm0
    vmovupd refractivity(%rip), %ymm8
    vsubpd  %ymm7, %ymm1, %ymm1

    vmulpd %ymm0, %ymm6, %ymm0//ambient light done

    vmovupd %ymm9, %ymm7
    vmovupd %ymm14, %ymm2
    broadcastdotproduct 7, 2, 15
    vmulpd %ymm15, %ymm1, %ymm1
    vmulpd %ymm1, %ymm6, %ymm1
    vcmppd $0x1D, zeros(%rip), %ymm1, %ymm3
    vandpd %ymm3, %ymm1, %ymm1//diffuse light done

    vmulpd %ymm15, %ymm13, %ymm2//2(L*N)
    vmulpd %ymm2, %ymm9, %ymm2//2(L*N)N
    vsubpd %ymm14, %ymm9, %ymm2//2(L*N)N-L
    vmulpd %ymm11, %ymm2, %ymm2
    vcmppd $0x1D, zeros(%rip), %ymm2, %ymm3
    vandpd %ymm3, %ymm2, %ymm2//diffuse light done
    vmulpd %ymm2, %ymm2, %ymm2
    vmulpd %ymm2, %ymm2, %ymm2
    vmulpd reflectivity(%rip), %ymm2, %ymm2
    vmulpd %ymm6, %ymm2, %ymm2

    test %rdx, %rdx//to make sure stuff
    jz almostover

    vmovupd %ymm0, (%rsp)
    vmovupd %ymm1, 32(%rsp)
    vmovupd %ymm2, 64(%rsp)

    vpbroadcastq %xmm8, %ymm8
    vmulpd %ymm9, %ymm8, %ymm8
    vaddpd %ymm8, %ymm10, %ymm10
    vmovupd reflectivity(%rip), %ymm8
    vmulpd %ymm8,%ymm6,%ymm2
    vmovupd %ymm9, %ymm3
    vmulpd %ymm9, %ymm13, %ymm1
    broadcastdotproduct 11, 9, 4
    vmulpd %ymm4, %ymm1, %ymm1
    vsubpd %ymm1, %ymm3, %ymm1
    vmulpd directionupdate(%rip), %ymm1, %ymm11
    vaddpd %ymm11, %ymm10, %ymm0
    call calc_ray

    vaddpd (%rsp), %ymm0, %ymm0
    vaddpd 32(%rsp), %ymm1, %ymm1
    vaddpd 64(%rsp), %ymm2, %ymm2 //light vectors ready to propogate up the call stack
    almostover:
    mov %rbp, %rsp
    pop %rbp
    ret
    endoftheline:
    vpxor %ymm0, %ymm0, %ymm0
    vpxor %ymm1, %ymm1, %ymm1
    vpxor %ymm2, %ymm2, %ymm2
    mov %rbp, %rsp
    pop %rbp
    ret
    inshadow:
    vpxor %ymm0, %ymm0, %ymm0
    vpxor %ymm1, %ymm1, %ymm1
    vpxor %ymm2, %ymm2, %ymm2
    mov %rbp, %rsp
    pop %rbp
    ret
 shadow_ray:
    push %rbp
    mov %rsp, %rbp

    vmovupd %ymm0, %ymm10
    vmovupd %ymm1, %ymm11
    mov trim(%rip), %r10
    mov 24(%r10), %r11
    mov %r11, %r13
    mov (%r10), %r10
    sal $5, %r11//okay this is the byte length of the list
    add %r11, %r10//end of list here
    neg %r11

    sub $256, %rsp

    vpcmpeqw %ymm7, %ymm7, %ymm7
    vpsllq $54, %ymm7, %ymm7
    vpsrlq $2, %ymm7, %ymm7
    test %r13, %r13
    jz notris_shadow

    each_tri_shadow://moller trumbore ray triangle intersection
    vmovupd mask(%rip), %ymm3
    vandpd (%r10,%r11),   %ymm3, %ymm0
    vandpd 32(%r10,%r11), %ymm3, %ymm1
    vandpd 64(%r10,%r11), %ymm3, %ymm2//vertices stored here very temporarily

    vmovupd %ymm0, 64(%rsp)
    vsubpd %ymm0, %ymm1, %ymm1
    vmovupd %ymm1,(%rsp)
    vsubpd %ymm0, %ymm2, %ymm1
    vmovupd %ymm1,32(%rsp)

    vmovupd %ymm11, %ymm0
    crossprod//direction ray x v2v0
    vmovupd %ymm0, %ymm15//pvec temporarily in ymm15
    vmovupd (%rsp), %ymm1
    dotprod
    vmovupd %ymm0, %ymm12//determinant in ymm12
    vcomisd tolerance(%rip), %xmm0
    jb no_intersect//cull backfaces and near-0 determinant values
    vdivsd %xmm12, %xmm7, %xmm13//inverse determinant in  xmm13
    vsubpd 64(%rsp), %ymm10, %ymm5//tvec in ymm5
    vmovupd %ymm15, %ymm0
    vmovupd %ymm5, %ymm1
    dotprod
    vmulsd %xmm13, %xmm0, %xmm14//u in xmm14

    vcomisd zeros(%rip), %xmm14
    jna no_intersect
    vcomisd %xmm7, %xmm14
    jnb no_intersect//cull no-intersect from u

    vmovupd %ymm5, %ymm0
    vmovupd (%rsp), %ymm1
    crossprod
    vmovupd %ymm0, %ymm5//qvec in ymm5

    vmovupd %ymm11, %ymm1
    dotprod
    vmulsd %xmm0, %xmm13, %xmm15//v in in xmm15

    vcomisd zeros(%rip), %xmm15
    jna no_intersect
    vaddsd %xmm14, %xmm15, %xmm0
    vcomisd %xmm7, %xmm0
    jnb no_intersect//cull no-intersect from v, v+u

    yes_intersect:
    mov %rbp, %rsp
    pop %rbp
    mov $1, %rax
    ret

    no_intersect:
    add $96, %r11
    js each_tri_shadow

    notris_shadow:
    mov spherem(%rip), %r10
    mov 32(%r10), %rcx
    mov 24(%r10), %r11
    mov %r11, %r13
    test %r11, %r11
    jz no_spheres_shadow
    mov (%r10), %r10
    sal $5, %r11//okay this is the byte length of the list
    add %r11, %r10//end of list here
    add %r11, %rcx
    neg %r11
    test %r13, %r13
    jz no_spheres_shadow
    each_sphere_shadow:
    vmovupd mask(%rip), %ymm3
    vandpd (%r10,%r11), %ymm3, %ymm5//ymm5 is center
    vmovsd (%rcx,%r11), %xmm3//xmm3 is radius
    vmulsd %xmm3, %xmm3, %xmm3//xmm3 is radius2

    vsubpd %ymm10, %ymm5, %ymm12//ymm12 is L

    vmovupd %ymm12, %ymm0
    vmovupd %ymm11, %ymm1
    dotprod
    vmovsd %xmm0, %xmm0, %xmm13//tca in xmm13

    vmulsd %xmm13, %xmm13, %xmm14
    vmovupd %ymm12, %ymm0
    vmovupd %ymm12, %ymm1
    dotprod
    vsubsd %xmm14, %xmm0, %xmm14//d2 in xmm14
    vcomisd %xmm3, %xmm14
    ja no_circle_ray_shadow

    vsubsd %xmm14, %xmm3, %xmm2
    vsqrtsd %xmm2, %xmm2, %xmm2
    vsubsd %xmm2, %xmm13, %xmm4
    vaddsd %xmm2, %xmm13, %xmm2
    vminsd %xmm4, %xmm2, %xmm0
    vmaxsd %xmm4, %xmm2, %xmm1

    vcomisd zeros(%rip), %xmm0
    ja goodjob
    vcomisd zeros(%rip), %xmm1
    jb no_circle_ray
    
    jmp yes_intersect
    no_circle_ray_shadow:
    add $32, %r11
    js each_sphere_shadow

    no_spheres_shadow:
    mov %rbp, %rsp
    pop %rbp
    mov $0, %rax
    ret
