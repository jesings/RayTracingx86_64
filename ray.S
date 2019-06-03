.data
    origin: .double 256, 256, 256
.bss
.text
calc_rays:
    xor %rdi, %rdi
    xcoords:
    xor %rsi, %rsi
    ycoords:

    mov $4, %rdx//RECURSION DEPTH OF 4 YE :)
    push %rdi
    push %rsi
    call calc_ray
    pop %rsi
    pop %rdi

    inc %rsi
    cmp $512, %rsi
    jl ycoords
    inc %rdi
    cmp $512, %rdi
    jl xcoords
    ret
calc_ray://x coord in rdi, y coord in rsi
    mov trimatrix(%rip), %r10
    mov 24(%r10), %r11
    sal $5, %r11//okay this is the byte length of the list
    add %r11, %r10//end of list here
    neg %r11
    sub $32, %rsp
    each_tri://yikes
    vmovupd (%r10,%r11), %ymm0
    vmovupd 24(%r10,%r11), %ymm1
    vmovupd 48(%r10,%r11), %ymm2
    vandpd mask(%rip), %ymm0, %ymm0
    vandpd mask(%rip), %ymm1, %ymm1
    vandpd mask(%rip), %ymm2, %ymm2
    call crossproduct
    call normalize//plane normal
    comiss 
    vmovupd %ymm0, (%rsp)
    vcvtsi2sd %rdi, %xmm0
    vcvtsi2sd %rsi, %xmm1
    vandpd mask(%rip), %ymm0, %ymm0
    vandpd mask(%rip), %ymm1, %ymm1
    vpermq $11001111, %ymm1, %ymm1
    vmovupd origin(%rip),%ymm2
    vsubpd %ymm1, %ymm2, %ymm2
    vsubpd %ymm0, %ymm2, %ymm2
    vmovupd %ymm2, %ymm0
    call normalize
    //ray direction
    vmovupd (%rsp), %ymm1
    call dotproduct
    vmovupd %ymm0, %ymm1
    //find plane intersect: (N*R₀+D)/(N*Rd)
    vmovsd (%rsp), %xmm0
    vmovupd %ymm1, (%rsp)
    vmovupd (%r10,%r11), %ymm1
    vsubpd origin(%rip), %ymm1, %ymm1
    call dotproduct
    vdivsd (%rsp), %xmm0, %xmm0





    test %rdx, %rdx//if recursion depth has reached 0
    jz no_recurse
    dec %rdx
    call calc_ray
    no_recurse:


    add $96, %r11
    js each_tri
    add $32, %rsp
    
    ret
    /*aytrace( ray )
      P = closest intersection
      color_local = ShadowRay(light1, P)+......+ ShadowRayShadowRay((lightNlightN,,P)P)
      color_reflect = raytrace(reflected_ray)
      color_refract = raytrace(refracted_ray)
      color = color_local + kre*color_reflect+ + kra*color_refract
      return( color )
      */
