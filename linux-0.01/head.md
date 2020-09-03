# linux/boot/head.s

This file contains code for three main items before the kernel can start functioning as a fully multitasking one: *GDT*, *IDT* and *paging* has to be initialized.

`head.s` contains the 32-bit startup code.

NOTE!!! Startup happens at absolute address 0x00000000, which is also where the page directory will exist. The startup code will be overwritten by the page directory.

*We jump to startup_32 from boot.s. The comment says that the “startup” code will be overwritten by the page tables - what does that mean ? The code below to setup the GDT and IDT are not needed after the setup is done. So after that code is executed, four pages of memory starting from 0x0 are used for paging purposes as page directory and page tables. That is what we mean by “overwriting” the code.*

```asm
.text
.globl _idt,_gdt,_pg_dir
_pg_dir:    ! page directory will be here

startup_32:
  movl $0x10,%eax
  mov %ax,%ds
  mov %ax,%es
  mov %ax,%fs
  mov %ax,%gs
  lss _stack_start,%esp
  call setup_idt   # 调用设置中断描述符表子程序
  call setup_gdt   # 调用设置全局描述符表子程序
```

*Note: 对于 GNU 汇编，每个直接操作数要以'$'开始，否则表示地址。 每个寄存器名都要以'%'开头， eax 表示是 32 位的 ax 寄存器。*

*Till this point, we are relying on the GDT which was setup in boot.s (direct memory mapping). 0x10 is the Data Segment.*

再次注意!! 这里已经处于 32 位运行模式，因此这里$0x10 现在是一个选择符。这里的移动指令会把相应描述符内容加载进段寄存器中。有关选择符的说明请参见第 4 章。这里$0x10 的含义是： 请求特权级为 0(位 0-1=0)、选择全局描述符表(位 2=0)、选择表中第 2 项(位 3-15=2)。它正好指向表中的数据段描述符项（描述符的具体数值参见前面 setup.s 中 575--578 行）。

上面代码的含义是：设置 ds,es,fs,gs 为 setup.s 中构造的内核数据段的选择符=0x10（ 对应全局段描述符表第 3 项）， 并将堆栈放置在 stack_start 指向的 user_stack 数组区， 然后使用本程序后面定义的新中断描述符表（ 232 行） 和全局段描述表（ 234—238 行） 。 新全局段描述表中初始内容与 setup.s 中的基本一样，仅段限长从 8MB 修改成了 16MB。 stack_start 定义在 kernel/sched.c， 82--87 行。它是指向 user_stack 数组末端的一个长指针。第 23 行设置这里使用的栈，姑且称为系统栈。但在移动到任务 0 执行（ init/main.c 中 137 行）以后该栈就被用作任务 0 和任务 1 共同使用的用户栈了。

> ***LDS/LES/LFS/LGS/LSS: Load Far Pointer***
>
> Loads a far pointer (segment selector and offset) from the second operand (source operand) into a segment register and the first operand (destination operand). The source operand specifies a 48-bit or a 32-bit pointer in memory depending on the current setting of the operand-size attribute (32 bits or 16 bits, respectively). The instruction opcode and the destination operand specify a segment register/general-purpose register pair. The 16-bit segment selector from the source operand is loaded into the segment register specified with the opcode (DS, SS, ES, FS, or GS). The 32-bit or 16-bit offset is loaded into the register specified with the destination operand.
>
> If one of these instructions is executed in protected mode, additional information from the segment descriptor pointed to by the segment selector in the source operand is loaded in the hidden part of the selected segment register.
>
> Also in protected mode, a null selector (values 0000 through 0003) can be loaded into DS, ES, FS, or GS registers without causing a protection exception. (Any subsequent reference to a segment whose corresponding segment register is loaded with a null selector, causes a generalprotection exception (#GP) and no memory reference to the segment occurs.)

*We will need stacks for function calls. So we setup the ess and esp using values from the structure stack_start which is declared in kernel/sched.c. Again, the format of the structure will be understood only by looking into the intel manual and seeing what is the format of the argument for lss and what lss does!*

*Then we setup IDT and GDT according to the preferences of the kernel.*

```
1 2
  movl $0x10,%eax # reload all the segment registers
  mov %ax,%ds   # after changing gdt. CS was already reloaded in ’setup_gdt’
  mov %ax,%es
  mov %ax,%fs   # 因为修改了GDT，所以需要重新装载所有的段寄存器。
  mov %ax,%gs   # CS代码段寄存器已经在 setup_gdt 中重新加载过了。
  lss _stack_start,%esp
8
```

* Again modify the segment registers to reflect the “new” values in the GDT and IDT.

```
1 
2 xorl %eax,%eax
3 1: incl %eax # check that A20 really IS enabled
4 movl %eax,0x000000
5 cmpl %eax,0x100000
6 je 1b
7 movl %cr0,%eax # check math chip
8 andl $0x80000011,%eax # Save PG,ET,PE
9 testl $0x10,%eax
10 jne 1f # ET is set - 387 is present
11 orl $4,%eax # else set emulate bit
12 1: movl %eax,%cr0
13 jmp after_page_tables
14
```

* Now the “jmp after_page_tables”. All the memory till the label after_page_tables will be used for paging
and will be over written.

```
1 
2 
3 /*
4 * setup_idt
5 *
6 * sets up a idt with 256 entries pointing to
7 * ignore_int, interrupt gates. It then loads
8 * idt. Everything that wants to install itself
9 * in the idt-table may do so themselves. Interrupts
10 * are enabled elsewhere, when we can be relatively
11 * sure everything is ok. This routine will be over-
12 * written by the page tables.
13 */
14 setup_idt:
15 lea ignore_int,%edx
16 movl $0x00080000,%eax
17 movw %dx,%ax /* selector = 0x0008 = cs */
18 movw $0x8E00,%dx /* interrupt gate - dpl=0, present */
19
20 lea _idt,%edi
21 mov $256,%ecx
22 rp_sidt:
23 movl %eax,(%edi)
24 movl %edx,4(%edi)
25 addl $8,%edi
26 dec %ecx
50Chapter 6. Journey to the Center of the Code
27 jne rp_sidt
28 lidt idt_descr
29 ret
30
31
```

* The comments by Linus for this function are pretty self evident. The IDT with 256 entries is represented
by the variable _idt. Now after initializing _idt with “ignore_int” (the actual interrupts will be initialized
later at various points), the lidt instruction is used with idt_descr as parameter, whose format again can be
understood by looking into the manual.

```
1 2
/*
3 * setup_gdt
4 *
5 * This routines sets up a new gdt and loads it.
6 * Only two entries are currently built, the same
7 * ones that were built in init.s. The routine
8 * is VERY complicated at two whole lines, so this
9 * rather long comment is certainly needed :-).
10 * This routine will beoverwritten by the page tables.
11 */
12 setup_gdt:
13 lgdt gdt_descr
14 ret
15
16 .org 0x1000
17 pg0:
18
19 .org 0x2000
20 pg1:
21
22 .org 0x3000
23 pg2: # This is not used yet, but if you
24 # want to expand past 8 Mb, you’ll have
25 # to use it.
26 .org 0x4000
27
```

* Let us explain a bit about the page directory and the page tables. The Intel architecture uses two levels of
paging - one page directory and 1024 page tables. The page directory starts from 0x0 and extends till 0x1000
(4K). In 0.01, we use two page tables which start at 0x10000 (pg0) and 0x20000 (pg1) respectively. These
page tables are respectively the first and second entries in the page directory. So we can see that the total
memory that can be mapped by two page tables is 2 * 1024 pages = 8Mb (one page = 4K). Now the page
table starting at 0x30000 till 0x40000 (pg2) is not in use in 0.01.Again, one point to be noted is that these
page directory/tables are for use ONLY by the kernel. Each process will have to setup its’ own page directory
and page tables (TODO:not very sure, will correct/confirm this later)

```
1 
2 after_page_tables:
3 pushl $0 # These are the parameters to main :-)
4 pushl $0
5 pushl $0
6 pushl $L6 # return address for main, if it decides to.
7 pushl $_main
8 jmp setup_paging
9 L6:
10 jmp L6 # main should never return here, but
11 # just in case, we know what happens.
12
```

* After setting up paging, we jump to main, where the actual “C” code for the kernel starts.

```
1 2 3
/* This is the default interrupt "handler" :-) */
4 .align 2
5 ignore_int:
6 incb 0xb8000+160 # put something on the screen
7 movb $2,0xb8000+161 # so that we know something
8 iret # happened
9
10
11 /*
12 * Setup_paging
13 *
14 * This routine sets up paging by setting the page bit
15 * in cr0. The page tables are set up, identity-mapping
16 * the first 8MB. The pager assumes that no illegal
17 * addresses are produced (ie >4Mb on a 4Mb machine).
18 *
19 * NOTE! Although all physical memory should be identity
20 * mapped by this routine, only the kernel page functions
21 * use the >1Mb addresses directly. All "normal" functions
22 * use just the lower 1Mb, or the local data space, which
23 * will be mapped to some other place - mm keeps track of
24 * that.
25 *
26 * For those with more memory than 8 Mb - tough luck. I’ve
27 * not got it, why should you :-) The source is here. Change
28 * it. (Seriously - it shouldn’t be too difficult. Mostly
29 * change some constants etc. I left it at 8Mb, as my machine
30 * even cannot be extended past that (ok, but it was cheap :-)
31 * I’ve tried to show which constants to change by having
32 * some kind of marker at them (search for "8Mb"), but I
33 * won’t guarantee that’s all :-( )
34 */
35 .align 2
36 setup_paging:
37 movl $1024*3,%ecx
38 xorl %eax,%eax
39 xorl %edi,%edi /* pg_dir is at 0x000 */
40 cld;rep;stosl
41
```

* Fill the page directory, pg0 and pg1 with zeroes!!

```
1 2
movl $pg0+7,_pg_dir /* set present bit/user r/w */
52Chapter 6. Journey to the Center of the Code
3 movl $pg1+7,_pg_dir+4 /* --------- " " -------
-- */
4
```

* Fill the first two entries of the page directory with pointers to pg0 and pg1 and the necessary bits for paging
(which again can be found from the manuals).

```
1 
2 movl $pg1+4092,%edi
3 movl $0x7ff007,%eax /* 8Mb - 4096 + 7 (r/w user,p) */
4 std
5 1: stosl /* fill pages backwards - more efficient :-) */
6 subl $0x1000,%eax
7 jge 1b
8
```

* Now the page tables has to be filled with the physical address corresponding to the virtual address that the
page table entry represents. For example, the value in the last entry of the second page table pg1 should
represent the starting address of the “last” page in the physical memory whose starting address is 8Mb -
4096 (one page = 4096 bytes). Again, the second last entry of pg1 should be the starting address of the
second last physical memory page = 8Mb - 4096 -4096. (4096 = 0x10000). Again, the necessary bits for
paging purposes (7 = r/w user, p) are also added to the address - refer manuals.

```
1 2
xorl %eax,%eax /* pg_dir is at 0x0000 */
3 movl %eax,%cr3 /* cr3 - page directory start */
4 movl %cr0,%eax
5 orl $0x80000000,%eax
6 movl %eax,%cr0 /* set paging (PG) bit */
7 ret /* this also flushes prefetch-queue */
8
```

* Set the Kernel page directory to start at 0x0 and then turn on paging!

```
1 2
.align 2
3 .word 0
4 idt_descr:
5 .word 256*8-1 # idt contains 256 entries
6 .long _idt
7 .align 2
8 .word 0
9 gdt_descr:
10 .word 256*8-1 # so does gdt (not that that’s any
11 .long _gdt # magic number, but it works for me :^)
12
13 .align 3
14 _idt: .fill 256,8,0 # idt is uninitialized
15
16 _gdt: .quad 0x0000000000000000 /* NULL descriptor */
17 .quad 0x00c09a00000007ff /* 8Mb */
18 .quad 0x00c09200000007ff /* 8Mb */
19 .quad 0x0000000000000000 /* TEMPORARY - don’t use */
20 .fill 252,8,0 /* space for LDT’s and TSS’s etc */
21
```

* The GDT has at present, just three entries. The NULL descriptor, the Code Segment and the Data Segment
- these two segments are for use by the kernel and so it covers the entire address from 0x0 to 8Mb which is
again directly mapped to the first 8Mb of phyisical memory by the kernel page tables.
