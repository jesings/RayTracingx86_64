.global calc_rays
.data
    origin: .double 256, 256, 256, 0
    tolerance: .double .000001
    maxval: .double inf
    maskupper: .quad 0xffffffffffffffff,0xffffffffffffffff,0,0
.bss
.text
.macro broadcastdotproduct arg1, arg2, result
    vmulpd %ymm\arg1, %ymm\arg2, %ymm\arg1
    vextractf128 $1, %ymm\arg1, %xmm\arg2
    vaddpd %ymm\arg1, %ymm\arg2, %ymm\arg1
    vunpckhpd %xmm\arg1, %xmm\arg1, %xmm\arg2
    vaddsd %xmm\arg2, %xmm\arg1, %xmm\arg1
    vpbroadcastq %xmm\arg1, %ymm\result
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
    mov $-512, %rdi
    xcoords:
    xor %rsi, %rsi
    ycoords:

    //colory bois
    mov $4, %rdx//RECURSION DEPTH OF 4 YE :)
    push %rdi
    push %rsi
    inc %rdi
    
    vcvtsi2sd %rsi, %xmm0, %xmm0
    vpermq $0, %ymm0, %ymm0
    vcvtsi2sd %rdi, %xmm0, %xmm0
    vandpd maskupper(%rip), %ymm0, %ymm1
    vmovupd origin(%rip), %ymm0
    vaddpd %ymm1, %ymm0, %ymm0
    call normalize
    vmovupd %ymm0, %ymm1
    vmovupd origin(%rip), %ymm0
    call calc_ray
    vaddpd %ymm0, %ymm1, %ymm0
    vaddpd %ymm0, %ymm2, %ymm0

    vcvtsd2si %xmm0, %rax
    vpermq $0b1001, %ymm0, %ymm0
    vcvtsd2si %xmm0, %rcx
    vpermq $0b01, %ymm0, %ymm0
    vcvtsd2si %xmm0, %rdx
    sub $8, %rsp
    movq $0, (%rsp)
    clamp ax
    clamp cx
    clamp dx
    mov %ax, (%rsp)
    mov %cx, 1(%rsp)
    mov %dx, 2(%rsp)
    mov (%rsp), %r15
    add $8, %rsp

    pop %rsi
    pop %rdi

    mov %rdi, %r8
    mov %rsi, %r9
    add $512, %r8
    neg %r9
    imul $3, %r8
    lea data(%rip), %r10
    add %r10, %r8
    mov %al, (%r8, %r9)
    mov %cl, 1(%r8, %r9)
    mov %dl, 2(%r8, %r9)
    
    dec %rsi
    cmp $-512, %rsi
    jg ycoords
    inc %rdi
    test %rdi, %rdi
    jnz xcoords
    ret

calc_ray://ray origin packed in ymm0, NORMALIZED ray vector packed in ymm1
    push %rbp
    mov %rsp, %rbp
    dec %rdx

    vmovupd %ymm0, %ymm10
    vmovupd %ymm1, %ymm11
    mov trim(%rip), %r10
    mov 24(%r10), %r11
    mov (%r10), %r10
    sal $5, %r11//okay this is the byte length of the list
    add %r11, %r10//end of list here
    neg %r11

    sub $65536, %rsp
    mov $-65536, %r12

    sub $128, %rsp
    vpcmpeqd %ymm7, %ymm7, %ymm7
    vpsrld $1, %ymm7, %ymm7
    vpcmpeqw %ymm8, %ymm8, %ymm8
    vpsllq $54, %ymm8, %ymm8
    vpsrlq $2, %ymm8, %ymm8

    vmovupd (%r10,%r11), %ymm0
    vmovupd 24(%r10,%r11), %ymm1
    vmovupd 48(%r10,%r11), %ymm2
    vandpd mask(%rip), %ymm0, %ymm0
    vandpd mask(%rip), %ymm1, %ymm1
    vandpd mask(%rip), %ymm2, %ymm2

    vsubpd %ymm0, %ymm1, %ymm7
    vmovupd %ymm7,(%rsp)
    vsubpd %ymm0, %ymm2, %ymm7
    vmovupd %ymm7,32(%rsp)
    vmovupd %ymm0, 64(%rsp)

    each_tri:

    vmovupd %ymm11, %ymm0
    vsubpd 32(%rsp), %ymm1, %ymm1
    call crossproduct
    vmovupd %ymm0, %ymm4
    vmovupd %ymm5, %ymm0

    vmovupd %ymm4, %ymm1
    call dotproduct

    vandpd %ymm7, %ymm0, %ymm1
    vcomisd tolerance(%rip), %xmm1
    jb no_add_ray

    vdivsd %xmm0, %xmm8, %xmm5
    vsubpd 64(%rsp), %ymm10, %ymm0
    vmovupd %ymm4, %ymm1
    call dotproduct
    vmulsd %xmm5, %xmm0, %xmm9
    vcomisd %xmm8, %xmm9
    jnb no_add_ray
    vpxor %xmm1, %xmm1, %xmm1
    vcomisd %xmm1, %xmm9
    jna no_add_ray

    vsubpd 64(%rsp), %ymm10, %ymm0
    vmovupd (%rsp), %ymm1
    call crossproduct
    vmovupd %ymm0, %ymm6
    vmovupd %ymm11, %ymm1
    call dotproduct
    vmulpd %ymm0, %ymm5, %ymm0

    vpxor %xmm1, %xmm1, %xmm1
    vcomisd %xmm1, %xmm0
    jna no_add_ray
    vaddpd %ymm0, %ymm9, %ymm1
    vcomisd %xmm8, %xmm1
    jnb no_add_ray

    vmovupd 32(%rsp), %ymm0
    vmovupd %ymm6, %ymm1
    call dotproduct
    vmulpd %ymm0, %ymm5, %ymm0
    vcomisd tolerance(%rip), %xmm0
    jb no_add_ray
    
    vpbroadcastq %xmm0, %ymm0
    vmulpd %ymm11, %ymm0, %ymm0
    vaddpd %ymm10, %ymm0, %ymm0

    //GET A WHOLE BUNCH OF GARBAGE STORED & PUT INTO RIGHT PLACES
    vmovupd %ymm0, (%rbp, %r12)
    add $32, %r12

    no_add_ray:

    add $96, %r11
    js each_tri
    add $128, %rsp

    cmp $-65536, %r12
    je endoftheline

    
    add $65536, %r12
    xor %r11, %r11

    vmovsd maxval(%rip), %xmm2
    each_intersect:
    vmovupd -65536(%rbp, %r11),%ymm0
    call magnitude
    vcomisd %xmm2, %xmm0
    jnb regular
    vmovsd %xmm0, %xmm0, %xmm2
    vmovupd -65536(%rbp, %r11),%ymm3
    regular:

    add $32, %r11
    cmp %r11, %r12
    jg each_intersect

    test %r11, %r11
    jz endoftheline

    //get surface normal
    vmovupd %ymm2, %ymm12
    //first thing is reflected ray
    vmovupd %ymm11, %ymm0
    vsubpd 32(%rsp), %ymm1, %ymm1
    call crossproduct
    call normalize//here's our normal
    vmovupd %ymm0, %ymm10

    //get angle to light(s)

    //for light in light sources, starting out with one
    vmovupd lightloc(%rip), %ymm0
    call normalize
    vmovupd %ymm0, %ymm3
    vmovupd Ka(%rip), %ymm0 
    vmovupd Kd(%rip), %ymm1
    vmovupd Ks(%rip), %ymm2
    vmulpd %ymm0, %ymm4, %ymm0//ambient light done
    vmulpd %ymm1, %ymm4, %ymm1
    //dot product and broadcast
    vmovupd %ymm10, %ymm5
    vmovupd %ymm3, %ymm6
    broadcastdotproduct 5, 6, 5
    vmulpd %ymm1, %ymm6, %ymm1//diffuse light done

    //specular calcs
    vmulpd %ymm4, %ymm2, %ymm2
    vmulpd twos(%rip), %ymm10, %ymm5
    vmulpd surfacenormal(%rip), %ymm5, %ymm5
    vsubpd %ymm3, %ymm5, %ymm5
    vmovupd viewvect(%rip), %ymm6
    broadcastdotproduct 6, 5, 5
    vcmppd $0x1D, zeros(%rip), %ymm5, %ymm6
    vandnpd %ymm5, %ymm6, %ymm5
    vmulpd %ymm5, %ymm5, %ymm5
    vmulpd %ymm5, %ymm5, %ymm5
    vmulpd %ymm5, %ymm2, %ymm2//specular light done
    vcmppd $0x1D, zeros(%rip), %ymm1, %ymm6
    vandpd %ymm1, %ymm6, %ymm1

    test %rdx, %rdx//to make sure stuff
    jz endoftheline

    sub $96, %rsp
    vmovupd %ymm0, (%rsp)
    vmovupd %ymm1, 32(%rsp)
    vmovupd %ymm2, 64(%rsp)//light stored

    vmovupd %ymm10, %ymm0
    vmovupd %ymm11, %ymm0
    call dotproduct
    vmulsd twos(%rip), %xmm0, %xmm0
    vpbroadcastq %xmm0, %ymm0
    vmulpd %ymm0, %ymm11, %ymm0
    vsubpd %ymm11, %ymm0, %ymm1//new ray
    call calc_ray

    vaddpd (%rsp), %ymm0, %ymm0
    vaddpd 32(%rsp), %ymm1, %ymm1
    vaddpd 64(%rsp), %ymm2, %ymm2//light vectors ready to propogate up the call stack
    endoftheline:
    mov %rbp, %rsp
    pop %rbp
    ret
    /*aytrace( ray )
      P = closest intersection
      color_local = ShadowRay(light1, P)+......+ ShadowRayShadowRay((lightNlightN,,P)P)
      color_reflect = raytrace(reflected_ray)
      color_refract = raytrace(refracted_ray)
      color = color_local + kre*color_reflect+ + kra*color_refract
      return( color )
      */
ooaeofjidsaodjasff:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    hlt
