.global pr
.data
.align 16
strResult: .zero 4# string buffer to store results
.align 32
message: .asciz  "P6 512 512 255\n"
.text
pr://move filename into %rdi
#open file
    mov $2, %rax
    mov $65, %rsi                # open for writing and CREAT flag
    mov $0777, %rdx
    syscall
    mov %rax, %rdi

#write initial string to file (header) 
    mov $1, %rax
    lea message(%rip), %rsi          # address of string to output
    mov $15, %rdx               # number of bytes
    syscall

    lea data(%rip), %rsi
    mov $786432, %rdx
    mov $1, %rax
    syscall

    mov $3, %rax
    syscall
    ret
