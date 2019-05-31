.global bresenham
.global bresenham2
.data
    .align 32
    colorR: .byte 255
    .align 8
    colorG: .byte 255 
    .align 8
    colorB: .byte 255
    .align 32
    _x: .quad 0
    y: .quad 0
    truncator: .double 1
.bss
    .align 32
    x0: .quad 0
    x1: .quad 0
    y0: .quad 0
    y1: .quad 0
.text
bresenham: //something like this: bresenham(int color,int x0,int x1, int y0, int y1, double z0, double z1), color is a hex value
#process arguments
    push %rbx
    mov %rdi, %rax
    movb %al, colorB(%rip)
    shr $8, %rax
    movb %al, colorG(%rip)
    shr $8, %rax
    movb %al, colorR(%rip)
    mov %rsi, x0(%rip)
    neg %rdx
    add $511, %rdx
    mov %rdx, y0(%rip)
    mov %rcx, x1(%rip)
    neg %r8
    add $511, %r8
    mov %r8, y1(%rip)
#handle wrong direction coords
    mov x0(%rip), %rcx
    cmp x1(%rip), %rcx
    jl noswap
    xchg x1(%rip), %rcx
    mov %rcx, x0(%rip)
    mov y0(%rip), %rcx
    xchg y1(%rip), %rcx
    mov %rcx, y0(%rip)
    movsd %xmm0, %xmm2
    movsd %xmm1, %xmm0
    movsd %xmm2, %xmm1
    noswap:
    mov y1(%rip), %r11
    sub y0(%rip), %r11
    mov %r11, %r10
    neg %r10
    cmovl %r10, %r11
    mov x1(%rip), %r10
    sub x0(%rip), %r10
    add %r11, %r10
    cvtsi2sd %r10, %xmm3
    vsubsd %xmm0, %xmm1, %xmm2
    vdivsd %xmm2, %xmm3, %xmm2
#assign x and y
    movq x0(%rip), %r8
    movq %r8, _x(%rip) //x = x-naught
    movq y0(%rip), %r8
    movq %r8, y(%rip) //y = y-naught
#assign a b and d
    movq y0(%rip), %rax
    subq y1(%rip), %rax//A = y-naught - y-one these needed to be negated for some reason...?
    movq x1(%rip), %rbx
    subq x0(%rip), %rbx//B = x-one - x-naught
#differentiate between octants
    cmp $0, %rax
    jl topq
    bottomq:
    cmp %rax, %rbx
    jg o7
    jmp o8
    topq:
    mov %rax, %rcx
    neg %rcx
    cmp %rcx,%rbx
    jg o1
    jmp o2
#A is rax, B is rbx, rdx is d (twice d actually)
o1:
    movq %rax,%rdx //d=2a+b
    salq %rdx
    addq %rbx, %rdx
    salq %rax
    salq %rbx //double a and b
    start1:
    mov x1(%rip), %rcx
    cmpq _x(%rip), %rcx
    jl _end
    call plot
    cmp $0,%rdx#check if y needs to be incremented
    jg ifninc1
    incq y(%rip)
    add %rbx, %rdx
    ifninc1:
    incq _x(%rip)
    add %rax, %rdx
    jmp start1
o2:
    neg %rax
    neg %rbx
    movq %rbx,%rdx //d=2b+a
    salq %rdx
    addq %rax, %rdx
    salq %rax
    salq %rbx //double a and b
    start2:
    mov y1(%rip), %rcx
    cmpq y(%rip), %rcx
    jl _end
    call plot
    cmp $0,%rdx#check if y needs to be incremented
    jg ifninc2
    incq _x(%rip)
    add %rax, %rdx
    ifninc2:
    incq y(%rip)
    add %rbx, %rdx
    jmp start2
o7:
    movq %rax,%rdx //d=2b-a
    salq %rdx
    subq %rbx, %rdx
    salq %rax
    salq %rbx //double a and b
    start7:
    mov x1(%rip), %rcx
    cmpq _x(%rip), %rcx
    jl _end
    call plot
    cmp $0,%rdx#check if y needs to be decremented
    jl ifninc7
    decq y(%rip)
    sub %rbx, %rdx
    ifninc7:
    incq _x(%rip)
    add %rax, %rdx
    jmp start7
o8:
    movq %rax,%rdx //d=2a-b
    salq %rdx
    subq %rbx, %rdx
    salq %rax
    salq %rbx //double a and b
    start8:
    mov y1(%rip), %rcx
    cmpq y(%rip), %rcx
    jg _end
    call plot
    cmp $0,%rdx#check if y needs to be incremented
    jg ifninc8
    incq _x(%rip)
    add %rax, %rdx
    ifninc8:
    decq y(%rip)
    sub %rbx, %rdx
    jmp start8
    _end:
    pop %rbx
    ret
plot:
#plot x,y,z!!!
    cmpq $512, _x(%rip)
    jae pltdone
    cmpq $512, y(%rip)
    jae pltdone
    mov y(%rip), %r8//this will be the index
    sal $9, %r8
    add _x(%rip), %r8
    mov %r8, %r9
    lea zbuffer(%rip), %rcx

    push %rax//hacky pseudo-smoothing
    vmulsd truncator(%rip), %xmm0, %xmm0
    cvtsd2si %xmm0, %rax
    cvtsi2sd %rax, %xmm0
    vdivsd truncator(%rip), %xmm0, %xmm0
    pop %rax

    comisd (%rcx, %r9,8), %xmm0
    jb pltdone
    push %r8
    imul $3, %r8
    lea data(%rip),%rcx
    add %rcx, %r8
//color the pixel :)
    movzbw colorR(%rip), %cx
    movb %cl, 0(%r8)
    movzbw colorG(%rip), %cx
    movb %cl, 1(%r8)
    movzbw colorB(%rip), %cx
    movb %cl, 2(%r8)
    pop %r8
    shr $2, %r8
    lea zbuffer(%rip),%rcx
    movsd %xmm0, (%rcx, %r9,8)
//Plotting done 
    pltdone:
    addsd %xmm2, %xmm0
    ret
bresenham2: //something like this: bresenham(int color,int x0,int x1, int y, double z0, double z1), color is a hex value LINES HAVE TO BE VERTICAL
    neg %rcx
    add $511, %rcx//get proper y coord, by making it go from the bottom rather than the top
    cmp $511, %rcx
    ja endb2//if the y coordinate is greater than 511 (higher than the drawing window) don't draw 
    cmp %rsi, %rdx
    jge noswap2
    xchg %rsi, %rdx
    sub $8, %rsp
    movsd %xmm0, (%rsp)
    movsd %xmm1, %xmm0
    movsd (%rsp), %xmm1
    add $8, %rsp
    noswap2://If x2>x1, swap xs and zs
    mov %edi, %eax//put color into rax register for storage in places
    lea data(%rip), %rdi//find proper destination
    imul $512,%rcx//get y coord offset
    add %rsi, %rcx
    mov %rdx, %r8
    sub %rsi, %r8
    cvtsi2sd %r8, %xmm2//store x difference
    vsubsd %xmm0, %xmm1, %xmm1
    vdivsd %xmm2, %xmm1, %xmm1//divide z difference by x difference to get z step
    lea zbuffer(%rip), %r9//get destination into r9
    startb2://loop
    cmp %rsi, %rdx
    jl endb2//if we've done all the xs, end
    cmp $511, %rsi
    jg endb2//if our x is to the right of the view screen, end
    cmp $0, %rsi
    jl oof//if our x has yet to reach the view screen, continue until it does, if it ever does

    push %rax//hacky pseudo-smoothing
    vmulsd truncator(%rip), %xmm0, %xmm0
    cvtsd2si %xmm0, %rax
    cvtsi2sd %rax, %xmm0
    vdivsd truncator(%rip), %xmm0, %xmm0
    pop %rax

    vcomisd (%r9,%rcx,8),%xmm0
    jna oof//if our z coordinate is too great, don't draw, continue to next pixel
    vmovsd %xmm0, (%r9,%rcx,8)//put z into z buffer
    push %rax
    push %rcx
    imul $3,%rcx
    mov 3(%rdi,%rcx), %r10b
    mov %eax, (%rdi,%rcx)//put pixel color in location
    mov %r10b, 3(%rdi,%rcx)
    pop %rcx
    pop %rax
    oof:
    inc %rcx//increment x draw location
    inc %rsi//increment x
    vaddsd %xmm1, %xmm0, %xmm0//increment z by z step
    jmp startb2//loop
    endb2:
    ret
