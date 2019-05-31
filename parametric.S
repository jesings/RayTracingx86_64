.global init_temps
.global free_temps
.global makecircle
.global makespline
.global tempmatrix4
.global tempmatrixX
.global tempmatrixG
.global pio2
.data
    .align 32
    pointo1: .double .05
    pointo2: .double .31415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679
    doublee: .double 6.28
    doublbe: .double 1
    staging: .double 0,0,0,0
    coords: .double 0,0
    radius: .double 0
    pio2: .double 1.570796326794896619231321691639751442098584699687552910487
.bss
    .align 32
    pointers: .quad 0,0
    tempmatrixG: .quad 0
    tempmatrixX: .quad 0
    tempmatrixY: .quad 0
    tempmatrix4: .quad 0
.text
init_temps://initializes temporary values in this file, tempmatrixX, tempmatrixY, tempmatrix4
    mov $4, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, tempmatrix4(%rip)
    mov $1, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, tempmatrixX(%rip)
    mov $1, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, tempmatrixY(%rip)
    ret
free_temps://frees temporary values in this file, tempmatrixX, tempmatrixY, tempmatrix4
    mov tempmatrix4(%rip), %rdi
    call freematrix
    mov tempmatrixX(%rip), %rdi
    call freematrix
    mov tempmatrixY(%rip), %rdi
    call freematrix
    ret
makecircle://Draws a circle on the screen xmm0,xmm1,xmm2 is the center x,y,z, the radius is in xmm3
    mov %rdi, tempmatrixG(%rip)//where the edge matrix is stored
    lea staging(%rip), %rax
    movsd %xmm0, (%rax)
    movsd %xmm1, 8(%rax)
    movsd %xmm2, 16(%rax)
    movsd %xmm3, radius(%rip)
    sub $32, %rsp
    movdqu %xmm12, (%rsp)
    xorpd %xmm12, %xmm12
    mkcircl://Loop over the many vertices in order to find the edges
    movsd %xmm12, %xmm0
    addsd pio2(%rip), %xmm0
    movsd %xmm12, 24(%rsp)
    call sin2
    movsd 24(%rsp),%xmm12
    movsd %xmm0, 16(%rsp)
    movsd %xmm12, %xmm0
    movsd %xmm12, 24(%rsp)
    call sin2
    movsd 24(%rsp),%xmm12
    movsd %xmm0, %xmm1
    movsd 16(%rsp), %xmm0
    lea staging(%rip), %rax//sin and cos find the points on the unit circle (x,y), analagous to the points on the new circle, that are to be the vertices
    mulsd radius(%rip), %xmm0
    addsd (%rax), %xmm0
    mulsd radius(%rip), %xmm1
    addsd 8(%rax), %xmm1//multiply each coord of the unit circle by the radius, getting x, y displacement from the center, then add them to the center in order to calculate the coordinates of each vertex
    lea coords(%rip), %rax
    movsd %xmm0, (%rax)
    movsd %xmm1, 8(%rax)
    addsd pointo2(%rip), %xmm12//find the next vertex, the 2nd endpoint of your lines
    movsd %xmm12, %xmm0
    xor %rax, %rax
    addsd pio2(%rip), %xmm0
    movsd %xmm12, 24(%rsp)
    call sin2
    movsd 24(%rsp),%xmm12
    movsd %xmm0, 16(%rsp)
    movsd %xmm12, %xmm0
    movsd %xmm12, 24(%rsp)
    call sin2
    movsd 24(%rsp),%xmm12
    movsd %xmm0, %xmm1
    movsd 16(%rsp), %xmm0
    lea staging(%rip), %rax
    mulsd radius(%rip), %xmm0
    addsd (%rax), %xmm0
    mulsd radius(%rip), %xmm1
    addsd 8(%rax), %xmm1//same as above increment

    movsd 16(%rax), %xmm2
    movsd %xmm2, %xmm5
    lea coords(%rip), %rax
    movsd (%rax), %xmm3
    movsd 8(%rax), %xmm4
    mov tempmatrixG(%rip), %rdi
    call addedge//put the proper values into the proper xmm registers, call addedge
    comisd doublee(%rip), %xmm12
    jbe mkcircl//jump if t (xmm12) is greater than 2π
    movdqu (%rsp), %xmm12//xmm12 is a caller saved register
    add $32, %rsp//reset the stack
    ret
makespline://xmm0-7: x0,y0,x1,y1,x2,y2,x3,y3 - Works for both bezier and hermite, function to make matrix stored in rsi
    mov %rsi, tempmatrixG(%rip)
    mov tempmatrixX(%rip), %rsi
    mov (%rsi), %rsi
    movsd %xmm0, 0(%rsi)//put x coordinates in the xcoord matrix
    movsd %xmm2, 8(%rsi)
    movsd %xmm4, 16(%rsi)
    movsd %xmm6, 24(%rsi)
    mov tempmatrixY(%rip), %rsi
    mov (%rsi), %rsi
    movsd %xmm1, 0(%rsi)//put y coordinates in the ycoord matrix
    movsd %xmm3, 8(%rsi)
    movsd %xmm5, 16(%rsi)
    movsd %xmm7, 24(%rsi)
    push %rdi
    mov tempmatrix4(%rip), %rdi
    mov tempmatrixG(%rip), %rax
    call forcematrix
    mov tempmatrix4(%rip), %rdi
    mov tempmatrixX(%rip), %rsi
    call multiplymatrix
    mov tempmatrix4(%rip), %rdi
    mov tempmatrixY(%rip), %rsi
    call multiplymatrix//multiply matrixes in order to get proper coefficients into x and y matrices
    pop %rdi
    mov tempmatrixX(%rip), %r8
    mov tempmatrixY(%rip), %r9
    mov (%r8), %r8
    mov (%r9), %r9
    sub $16, %rsp
    movdqu %xmm12, (%rsp)
    xorpd %xmm12, %xmm12

    lea staging(%rip), %rdx//set initial points of the curve
    vmovups (%r8),%ymm1
    call cubic
    movsd %xmm0, (%rdx)
    vmovups (%r9),%ymm1
    call cubic
    movsd %xmm0, 8(%rdx)
    bezl://loop over the points of the curve
    lea staging(%rip), %rdx
    movsd (%rdx), %xmm0
    movsd %xmm0, 16(%rdx)
    movsd 8(%rdx), %xmm0
    movsd %xmm0, 24(%rdx)
    addsd pointo1(%rip), %xmm12
    vmovups (%r8),%ymm1
    call cubic
    movsd %xmm0, (%rdx)
    vmovups (%r9),%ymm1
    call cubic
    movsd %xmm0, 8(%rdx)

    movsd (%rdx), %xmm0
    movsd 8(%rdx), %xmm1
    movsd zeros(%rip), %xmm2
    movsd 16(%rdx), %xmm3
    movsd 24(%rdx), %xmm4
    movsd zeros(%rip), %xmm5
    push %rdi
    push %r8
    push %r9
    call addedge//add edges for each point on the curve
    pop %r9
    pop %r8
    pop %rdi
    comisd doublbe(%rip), %xmm12
    jbe bezl
    movdqu (%rsp), %xmm12
    add $16, %rsp
    ret
cubic://%xmm12 is t, others packed in %ymm1, returns sum in %xmm0
    movsd %xmm12, %xmm0
    vpermq $0b11100000, %ymm0, %ymm0
    mulsd %xmm12, %xmm0
    vpermq $0b11000100, %ymm0, %ymm0
    mulsd %xmm12, %xmm0
    vpermq $0b00100100, %ymm0, %ymm0
    movlps one(%rip), %xmm0
    vpermq $0b00011011, %ymm0, %ymm0
    vmulpd %ymm0, %ymm1, %ymm1
    vhaddpd %ymm1, %ymm1, %ymm0
    vpermq $0b11011000, %ymm0, %ymm0
    vhaddpd %ymm0, %ymm0, %ymm0
    ret
