.global draw
.global edgem
.global trim
.global spherem
.global name
.global parsefd
.global half
.global data
.global minval
.data
    .align 32
    x: .quad 0
    half: .double .5
    .align 32
    name: .asciz "./image.ppm"
    .align 32
    parsefile: .asciz "./script"
    .align 32
    minval: .double -inf
    bnlen: .quad 0
    convert: .asciz "convert"
    .align 32
    delay: .asciz "-delay"
    .align 32
    delaytime: .asciz "3"
    .align 32
    execpath: .quad 0,0,0
    animationlp: .zero 4096
    basefactor: .double 1, 1, 1, 0
.bss
    .align 32
    data: .zero 1048576
    .align 32
    edgem: .quad 0
    drawm: .quad 0
    trim: .quad 0
    spherem: .quad 0
    parsefd: .quad 0
.text
draw:
    call initheap

    mov $10, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, edgem(%rip)//make tiny dummy edge matrix

    mov $8192, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, trim(%rip)//make tiny dummy trimatrix

    mov $8192, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, spherem(%rip)//make tiny dummy spherematrix

    mov $4, %rdi
    mov $4, %rsi
    call makematrix
    push %rax
    mov 32(%rax), %rcx
    vmovupd basefactor(%rip), %ymm0
    vmovupd %ymm0, (%rcx)
    mov %rax, %rdi
    call identitymatrix//make identity coordinate stack matrix
    mov $16, %rdi
    call alloc@PLT
    mov %rax, cstop(%rip)
    pop %rdi
    mov %rdi, (%rax)

    call init_temps//initialize temporary values

    xor %rax, %rax
    nextop:
    push %rax
    mov $0, %rdx//0th pass
    call handleop
    pop %rax
    inc %rax
    cmp lastop(%rip), %rax
    jl nextop

    xor %rax, %rax
    nextop1:
    push %rax
    mov $1, %rdx//1st pass
    call handleop
    pop %rax
    inc %rax
    cmp lastop(%rip), %rax
    jl nextop1

    mov num_frames(%rip), %rcx
    test %rcx, %rcx
    jz nofrills

    lea basename(%rip), %rdi
    call mstrlen
    mov %rax, bnlen(%rip)
    movl $0x702E3030, (%rdi, %rax)
    movw $0x6D70, 4(%rdi, %rax)
    xor %rcx, %rcx
    frameloop:
    push %rcx
    call setknobs
    xor %rax, %rax
    nextop2:
    push %rax
    mov $2, %rdx//2nd pass
    call handleop
    pop %rax
    inc %rax
    cmp lastop(%rip), %rax
    jl nextop2
    lea basename(%rip), %rdi
    mov (%rsp), %rcx //get first 2 letters from A (0) to P (15), for a pseudo hex format
    mov %rcx, %rdx
    and $0b1111, %rcx
    and $0b11110000, %rdx
    shr $4, %rdx
    addb $0x41, %cl
    addb $0x41, %dl //dl is first digit from 0 to 15, cl is second digit
    mov bnlen(%rip), %rax
    mov %dl, (%rdi, %rax)
    mov %cl, 1(%rdi, %rax)
    call saveit
    lea data(%rip), %rdi
    xor %rax, %rax
    mov $131072, %rcx
    rep stosq
    mov trim(%rip), %rdi
    mov edgem(%rip), %rsi
    movq $0, 24(%rdi)
    movq $0, 24(%rsi)
    mov spherem(%rip), %rdi
    movq $0, 24(%rdi)
    call cspop
    pop %rcx
    inc %rcx
    cmp num_frames(%rip), %rcx
    jl frameloop

    mov edgem(%rip), %rdi
    call freematrix//free edge matrix

    mov trim(%rip), %rdi
    call freematrix//free trimatrix

    csstackstillanim:
    call cspop//free last item on coordinate stack
    cmpq $0, cstop(%rip)
    jne csstackstillanim
    call free_temps

    lea basename(%rip), %rdi
    mov bnlen(%rip), %rax
    movw $0x02a, (%rdi, %rax)
    sub $32, %rsp
    xor %rsi, %rsi
    xor %rdx, %rdx
    mov %rsp, %rcx
    call glob@PLT

    lea basename(%rip), %rdi
    mov bnlen(%rip), %rax
    movl $0x6669672E, 0(%rdi, %rax)

    movb $0x00, 4(%rdi, %rax)

    mov (%rsp),%rcx
    mov %rcx, execpath(%rip)
    lea animationlp(%rip), %rdi
    mov 8(%rsp), %rsi
    rep movsq
    mov execpath(%rip), %rcx
    lea convert(%rip), %rdi
    lea execpath(%rip), %rsi
    mov %rdi, (%rsi)
    lea delay(%rip), %rdi
    mov %rdi, 8(%rsi)
    lea delaytime(%rip), %rdi
    mov %rdi, 16(%rsi)
    lea basename(%rip), %rdi
    mov %rdi, 24(%rsi, %rcx,8)

    mov $57, %rax
    syscall
    test %rax, %rax
    jnz animover

    lea convert(%rip), %rdi
    lea execpath(%rip), %rsi

    call execvp@PLT
    
    mov %rsp, %rdi
    call globfree@PLT
    animover:
    mov $61, %rax
    mov $-1, %rdi
    xor %rsi, %rsi
    xor %rdx, %rdx
    xor %rcx, %rcx
    syscall
    add $32, %rsp
    jmp endfrills

    nofrills:

    xor %rax, %rax
    nextop2n:
    push %rax
    mov $2, %rdx//0th pass
    call handleop
    pop %rax
    inc %rax
    cmp lastop(%rip), %rax
    jl nextop2n

    mov edgem(%rip), %rdi
    call freematrix//free edge matrix

    mov trim(%rip), %rdi
    call freematrix//free trimatrix

    mov spherem(%rip), %rdi
    call freematrix
    csstackstill:
    call cspop//free last item on coordinate stack
    cmpq $0, cstop(%rip)
    jne csstackstill
    call free_temps
    endfrills:
    call deinitheap
    ret
