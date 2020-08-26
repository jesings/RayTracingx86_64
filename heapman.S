#define MINBSIZE 0x1000 //64 kb superblock?
#define METADATASIZE 20
.global initheap
.global alloc
.global afree
.global deinitheap
.data
.firstblock:
.quad 0 //pointer to first freechain block

.text
initheap:
  movq $9, %rax //mmap
  xorq %rdi, %rdi //null out addr for kernel to direct
  movq $MINBSIZE, %rsi //alloc minimum blocksize
  movl $0x3, %edx //PROT_READ | PROT_WRITE
  movl $0x22, %r10d //MAP_ANON | MAP_PRIVATE
  movl $-1, %r8d //portable code requires fd to be -1
  xorq %r9, %r9 //portable code requires offset of 0
  syscall
  //address in rax
  movq %rax, .firstblock(%rip)
  movq $0, (%rax) //pointer to next block
  movl $MINBSIZE - METADATASIZE, 8(%rax) //size of block
  movl $METADATASIZE, 12(%rax) //amount used up in block
  movl $0, 16(%rax) //number of allocations in block
  ret

alloc: //size of allocation in edi
  movq .firstblock(%rip), %rsi

  .allocltop:
  movl 8(%rsi), %eax //size of block
  movl 12(%rsi), %ecx //amount used up in block
  subl %ecx, %eax
  cmpl %edi, %eax
  jge .allocfromlink
  movq (%rsi), %rax
  testq %rax, %rax
  jz .allocnewblock
  movq (%rsi), %rsi
  jmp .allocltop

  .allocfromlink:
  leaq (%rsi, %rcx), %rax
  addl %edi, 12(%rsi)
  incl 16(%rsi)
  ret

  .allocnewblock:
  subq $16, %rsp
  movq %rsi, -16(%rsp)
  movl %edi, -4(%rsp)
  movq $MINBSIZE, %rdx

  movq $9, %rax //mmap
  leaq METADATASIZE(%rdi), %rsi //alloc size + 20 bytes
  cmpl $MINBSIZE - METADATASIZE, %edi
  cmovl %rdx, %rsi //alloc 16 mb block if less
  movl %esi, -8(%rsp)
  xorq %rdi, %rdi //null out addr for kernel to direct
  movl $0x3, %edx //PROT_READ | PROT_WRITE
  movl $0x22, %r10d //MAP_ANON | MAP_PRIVATE
  movl $-1, %r8d //portable code requires fd to be -1
  xorq %r9, %r9 //portable code requires offset of 0
  syscall

  movq $0, (%rax) //add block to free chain
  movq -8(%rsp), %rcx //amount alloced, and amount used
  movq %rcx, 8(%rax)
  movl $1, 16(%rax)
  movq -16(%rsp), %rsi
  movq %rax, (%rsi)
  addq $16, %rsp
  addq $METADATASIZE, %rax
  ret

afree: //pointer to free in rdi
  movq .firstblock(%rip), %rsi

  .freeltop:
  movq %rdi, %rdx
  subq %rsi, %rdx
  cmpl 8(%rsi), %edx
  jb .freefromlink
  movq (%rsi), %rsi
  jmp .freeltop

  .freefromlink:
  movl 16(%rsi), %eax
  decl %eax
  testl %eax, %eax
  jnz .freenofblock
  movl $METADATASIZE, 12(%rsi)
  .freenofblock:
  movl %eax, 16(%rsi)
  ret
deinitheap:
  movq .firstblock(%rip), %rdi

  .deinittop:
  mov $11, %rax //munmap
  movl 8(%rdi), %esi
  movq (%rdi), %rdx
  pushq %rdx
  syscall
  popq %rdi
  test %rdi, %rdi
  jnz .deinittop
  ret
