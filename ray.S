.data
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
    each_tri://yikes

    test %rdx, %rdx//if recursion depth has reached 0
    jz no_recurse
    dec %rdx
    call calc_ray
    no_recurse:

    add $96, %r11
    js each_tri
    
    ret
    /*aytrace( ray )
      P = closest intersection
      color_local = ShadowRay(light1, P)+......+ ShadowRayShadowRay((lightNlightN,,P)P)
      color_reflect = raytrace(reflected_ray)
      color_refract = raytrace(refracted_ray)
      color = color_local + kre*color_reflect+ + kra*color_refract
      return( color )
      */
