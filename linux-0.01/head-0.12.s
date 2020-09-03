.text
.globl idt,gdt,pg_dir,tmp_floppy_area
pg_dir:

.globl startup_32
startup_32:
	movl $0x10, %eax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	lss stack_start, %esp
	call setup_idt
	call setup_gdt
	movl $0x10, %eax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs

	lss stack_start, %esp

	xorl %eax, %eax
1:	incl %eax

	movl %eax, 0x000000
	cmpl %eax, 0x100000
	je 1b

	movl %cr0, %eax
	andl $0x80000011, %eax

	orl $2, %eax
	movl %eax, %cr0
	call check_x87
	jmp after_page_tables

check_x87:
	fninit
	fstsw %ax
	cmpb $0, %al
	je 1f
	movl %cr0, %eax
	xorl $6, %eax
	movl %eax, %cr0
	ret

.align 2
1:	.byte 0xDB,0xE4
	ret

setup_idt:
	lea ignore_int, %edx
	movl $0x00080000, %eax
	movw %dx, %ax
	movw $0x8E00, %dx

	lea idt, %edi
	mov $256, %ecx
rp_sidt:
	movl %eax, (%edi)
	movl %edx, 4(%edi)
	addl $8, %edi
	dec %ecx
	jne rp_sidt
	lidt idt_descr
	ret

setup_gdt:
	lgdt gdt_descr
	ret

.org 0x1000
pg0:

.org 0x2000
pg1:

.org 0x3000
pg2:

.org 0x4000
pg3:

.org 0x5000

tmp_floppy_area:
	.fill 1024,1,0

after_page_tables:
	pushl $0
	pushl $L6
	pushl $main
	jmp setup_paging
L6:
	jmp L6

int_msg:
	.asciz "Unknown interrupt\n\r"

.align 2
ignore_int:
	pushl %eax
	pushl %ecx
	pushl %edx
	push %ds
	push %es
	push %fs
	movl $0x10, %eax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	pushl $int_msg
	call printk
	popl %eax
	pop %fs
	pop %es
	pop %ds
	popl %edx
	popl %ecx
	popl %eax
	iret

.align 2
setup_paging:
	movl $1024 * 5, %ecx
	xorl %eax, %eax
	xorl %edi, %edi
	cld;rep;stosl

	movl $pg0 + 7, pg_dir
	movl $pg1 + 7, pg_dir + 4
	movl $pg2 + 7, pg_dir + 8
	movl $pg3 + 7, pg_dir + 12

	movl $pg3 + 4092, %edi
	movl $0xfff007, %eax

	std
1:	stosl
	subl $0x1000, %eax
	jge 1b
	cld

	xorl %eax, %eax
	movl %eax, %cr3

	movl %cr0, %eax
	orl $0x80000000, %eax
	movl %eax, %cr0
	ret

.align 2
.word 0

idt_descr:
	.word 256 * 8 - 1
	.long idt
.align 2
.word 0

gdt_descr:
	.word 256 * 8 - 1
	.long gdt

	.align 8
idt:	.fill 256, 8, 0

gdt:
	.quad 0x0000000000000000
	.quad 0x00c09a0000000fff
	.quad 0x00c0920000000fff
	.quad 0x0000000000000000
	.fill 252, 8, 0
