SCRN_SEL  = 0x18
TSS0_SEL  = 0x20
LDT0_SEL  = 0x28
TSS1_SEL  = 0x30
LDT1_SEL  = 0x38

LATCH     = 1193000

.global startup_32
.text
startup_32:
  movl $0x10,%eax
  mov %ax,%ds

  lss init_stack,%esp

  call setup_idt
  call setup_gdt
  movl $0x10,%eax
  mov %ax,%ds
  mov %ax,%es
  mov %ax,%fs
  mov %ax,%gs
  lss init_stack,%esp

  movb $0x36, %al
  movl $0x43,%edx
  outb %al,%dx
  movl $LATCH,%eax

  movl $0x40,%edx
  outb %al,%dx
  movb %ah,%al
  outb %al,%dx
  
  movl $0x00080000,%eax
  movw $timer_interrupt,%ax
  movw $0x8E00,%dx
  
  movl $0x08,%ecx
  lea idt(,%ecx,8),%esi
  movl %eax,(%esi)
  movl %edx,4(%esi)
  movw $system_interrupt,%ax
  movw $0xef00,%dx
  movl $0x80,%ecx
  lea idt(,%ecx,8),%esi
  movl %eax,(%esi)
  movl %edx,4(%esi)

  pushfl
  andl $0xfffbfff,(%esp)
  popfl
  movl $TSS0_SEL,%eax
  ltr %ax
  movl $LDT0_SEL,%eax
  lldt %ax
  movl $0,current
  sti
  pushl $0x17
  pushl $init_stack
  pushfl
  pushl $0x0f
  pushl $task0
  iret

setup_gdt:
  lgdt lgdt_opcode
  ret

setup_idt:
  lea ignore_int,%edx
  movl $0x00080000,%eax
  movw %dx,%ax
  movw $0x8E00,%dx
  lea idt,%edi
  mov $256,%ecx
rp_idt:
  movl %eax,(%edi)
  movl %edx,4(%edi)
  addl $8,%edi
  dec %ecx
  jne rp_idt
  lidt lidt_opcode
  ret

write_char:
  push %gs
  pushl %ebx
  mov $SCRN_SEL,%ebx
  mov %bx,%gs
  movl scr_loc,%ebx
  shl $1,%ebx
  movb %al,%gs:(%ebx)
  shr $1,%ebx
  incl %ebx
  cmpl $2000,%ebx
  jb 1f
  movl $0,%ebx
1:
  movl %ebx,scr_loc
  popl %ebx
  pop %gs
  ret


.align 4
ignore_int:
  push %ds
  pushl %eax
  movl $0x10,%eax
  mov %ax,%ds
  movl $67,%eax
  call write_char
  popl %eax
  pop %ds
  iret


.align 4
timer_interrupt:
  push %ds
  pushl %eax
  movl $0x10,%eax
  mov %ax,%ds
  movb $0x20,%al
  outb %al,$0x20
  movl $1,%eax
  cmpl %eax,current
  je 1f
  movl %eax,current
  ljmp $TSS1_SEL,$0
  jmp 2f
1:
  movl $0,current
  ljmp $TSS0_SEL,$0
2:
  popl %eax
  pop %ds
  iret


.align 4
system_interrupt:
  push %ds
  pushl %edx
  pushl %ecx
  pushl %ebx
  pushl %eax
  movl $0x10,%edx
  mov %dx,%ds
  call write_char
  popl %eax
  popl %ebx
  popl %ecx
  popl %edx
  pop %ds
  iret


current:
  .long 0
scr_loc:
  .long 0

.align 4

lidt_opcode:

  .word 256*8-1
  .long idt

lgdt_opcode:

  .word (end_gdt-gdt)-1
  .long gdt

.align 8
idt:
  .fill 256,8,0
gdt:
  .quad 0x0000000000000000
  .quad 0x00c09a00000007ff
  .quad 0x00c09200000007ff
  .quad 0x00c0920b80000002
  .word 0x68,tss0,0xe900,0x0
  .word 0x40,ldt0,0xe200,0x0
  .word 0x68,tss1,0xe900,0x0
  .word 0x40,ldt1,0xe200,0x0

end_gdt:
  .fill 128,4,0

init_stack:
  .long init_stack
  .word 0x10


.align 8
ldt0:
  .quad 0x0000000000000000
  .quad 0x00c0fa00000003ff
  .quad 0x00c0f200000003ff

tss0:
  .long 0
  .long krn_stk0,0x10
  .long 0,0,0,0,0
  .long 0,0,0,0,0
  .long 0,0,0,0,0
  .long 0,0,0,0,0,0
  .long LDT0_SEL,0x8000000
  .fill 128,4,0
krn_stk0:


.align 8
ldt1:
  .quad 0x0000000000000000
  .quad 0x00c0fa00000003ff
  .quad 0x00c0f200000003ff
tss1:
  .long 0
  .long krn_stk1,0x10
  .long 0,0,0,0,0
  .long task1, 0x200
  .long 0,0,0,0
  .long usr_stk1,0,0,0
  .long 0x17,0x0f,0x17,0x17,0x17,0x17
  .long LDT1_SEL,0x8000000
  .fill 128,4,0
krn_stk1:


task0:


  movb $65,%al
  int $0x80
  movl $0xfff,%ecx
1:
  loop 1b
  jmp task0

task1:


  movb $66,%al
  int $0x80
  movl $0xfff,%ecx
1:
  loop 1b
  jmp task1

  .fill 128,4,0
usr_stk1:
