# 6.4 head.s 程序

## 6.4.1功能描述

head.s 程序在被编译生成目标文件后会与内核其他程序的目标文件一起被链接成 system 模块， 并位于 system 模块的最前面开始部分。 这也就是为什么称其为头部(head)程序的原因。 system 模块将被放置在磁盘上 setup 模块之后开始的扇区中，即从磁盘上第 6 个扇区开始放置。一般情况下 Linux 0.12 内核的 system 模块大约有 120KB 左右，因此在磁盘上大约占 240 个扇区。

从这里开始，内核完全都是在保护模式下运行了。 heads.s 汇编程序与前面汇编的语法格式不同，它采用的是 AT&T 的汇编语言格式，并且需要使用 GNU 的 gas 和 gld7进行编译连接。因此请注意代码中赋值的方向是从左到右。

这段程序实际上处于内存绝对地址 0 处开始的地方。这个程序的功能比较单一。首先它加载各个数据段寄存器，重新设置中断描述符表 IDT，共 256 项，并使各个表项均指向一个只报错误的哑中断子程序 ignore_int。 这个哑中断向量指向一个默认的“ ignore_int”处理过程（ boot/head.s， 150）。当发生了一个中断而又没有重新设置过该中断向量时就会显示信息“未知中断（ Unknown interrupt）”。这里对所有256 项都进行设置可以有效防止出现一般保护性错误（ A gerneal protection fault） (异常 13)。 否则的话，如果设置的 IDT 少于 256 项，那么在一个要求的中断所指定的描述符项大于设置的最大描述符项时， CPU 就会产生一个一般保护出错（异常 13）。另外，如果硬件出现问题而没有把设备的向量放到数据总线上，此时 CPU 通常会从数据总线上读入全 1（ 0xff） 作为向量，因此会去读取 IDT 表中的第 256 项， 因此也会造成一般保护出错。

对于系统中需要使用的一些中断，内核会在其继续初始化的处理过程中（ init/main.c）重新设置这些中断的中断描述符项，让它们指向对应的实际处理过程。通常，异常中断处理过程（ int0 --int 31） 都在traps.c 的初始化函数中进行了重新设置（ kernl/traps.c，第 185 行），而系统调用中断 int128 则在调度程序初始化函数中进行了重新设置（ kernel/sched.c，第 417 行）。

中断描述符表中每个描述符项也占 8 字节，其格式见图 6-9 所示。 其中， P 是段存在标志； DPL 是描述符的优先级。

中断门（ Interrupt Gate）
过程入口点偏移值 31..16 P DPL 0 1 1 1 0 0
段选择符 过程入口点偏移值 15..0

![中断描述符表 IDT 中的中断门描述符格式](https://alex.dzyoba.com/img/idt-descriptor.png)

图 6-9 中断描述符表 IDT 中的中断门描述符格式

在 head.s 程序中，中断门描述符中段选择符字段被设置为 0x0008，表示该哑中断服务处理程序 ignore_int 在内核代码中，而偏移值被设置为 ignore_int 中断服务处理程序在 head.s 程序中的偏移值。由于 head.s 程序被移动到从内存地址 0 开始处，因此该偏移值也就是中断处理子程序在内核代码段中的偏移值。由于内核代码段一直存在于内存中，并且特权级为 0（ 即 P=1， DPL=00）， 因此从图中可知中断门描述符的字节 5 和字节 4 的值应该是 0x8E00。

在设置好中断描述符表之后，本程序又重新设置了全局段描述符表 GDT。实际上新设置的 GDT 表与原来在 setup.s 程序中设置的 GDT 表描述符除了在段限长上有些区别以外（原为 8MB，现为 16MB），其他内容完全一样。当然我们也可以在 setup.s 程序中就把描述符的段限长直接设置成 16MB，然后直接把原 GDT 表移动到内存适当位置处。因此这里重新设置 GDT 的主要原因是为了把 GDT 表放在内存内核代码比较合理的地方。 而前面设置的 GDT 表处于内存 0x902XX 处。这个地方将在内核初始化后用作内存高速缓冲区的一部分。

*7 在当前的 Linux 操作系统中， gas 和 gld 已经分别更名为 as 和 ld。*


接着检测 A20 地址线是否已开启。方法是将物理地址 0 开始处与 1MB 开始处的字节内容进行比较。如果 A20 线没有开启，则在访问高于 1MB 物理内存地址时 CPU 实际上会循环访问（ 地址 MOD 1MB）地址处的内容，也即与访问从 0 地址开始对应字节的内容都相同。 如果检测下来发现没有开启， 则进入死循环。 否则程序将继续执行去测试 PC 机是否含有数学协处理器芯片（ 80287、 80387 或其兼容芯片），并在控制寄存器 CR0 中设置相应的标志位。

接着程序设置管理内存的分页处理机制，将页目录表放在绝对物理地址 0 开始处（也是本程序所处的物理内存位置，因此这段程序已执行部分将被覆盖掉）， 紧随后面会放置共可寻址 16MB 内存的 4 个页表， 并分别设置它们的表项。 页目录表项和页表项格式见图 6-10 所示。其中 P 是页面存在于内存标志；R/W 是读写标志； U/S 是用户/超级用户标志； A 是页面已访问标志； D 是页面内容已修改标志；最左边 20 比特是表项对应页面在物理内存中页面地址的高 20 比特位。


页帧地址（ Page Frame Address） D A
位 31...12 AVL 0 0

https://0xax.gitbooks.io/linux-insides/content/Theory/linux-theory-1.html

图 6-10 页目录表项和页表项结构

这里每个表项的属性标志都被设置成 0x07（ P=1、 U/S=1、 R/W=1），表示该页存在、用户可读写。这样设置内核页表属性的原因是： CPU 的分段机制和分页管理都有保护方法。分页机制中页目录表和页表项中设置的保护标志（ U/S、 R/W）需要与段描述符中的特权级（ PL）保护机制一起组合使用。但段描述符中的 PL 起主要作用。 CPU 会首先检查段保护，然后再检查页保护。如果当前特权级 CPL < 3（例如 0），则说明 CPU 正在以超级用户（ Supervisor）身份运行。 此时所有页面都能访问，并可随意进行内存读写操作。如果 CPL = 3，则说明 CPU 正在以用户（ User）身份运行。此时只有属于 User 的页面（ U/S=1）可以访问，并且只有标记为可读写的页面（ W/R = 1）是可写的。 而此时属于超级用户的页面（ U/S=0）则既不可写、也不可以读。 由于内核代码有些特别之处，即其中包含有任务 0 和任务 1 的代码和数据。因此这里把页面属性设置为 0x7 就可以保证这两个任务代码能够在用户态下执行， 但却又不能随意访问内核资源。

最后， head.s 程序利用返回指令将预先放置在堆栈中的/init/main.c 程序的入口地址弹出，去运行 main() 程序。

6.4.2代码注释

程序 6-3 linux/boot/head.s

```asm
/* 

head.s contains the 32-bit startup code.

NOTE!!! Startup happens at absolute address 0x00000000, which is also where
the page directory will exist. The startup code will be overwritten by
the page directory.
*/

.text
.globl _idt,_gdt,_pg_dir,_tmp_floppy_area
_pg_dir:     # 页目录将会存放在这里。
# 再次注意!! 这里已经处于 32 位运行模式，因此这里$0x10 现在是一个选择符。这里的移动指令
# 会把相应描述符内容加载进段寄存器中。有关选择符的说明请参见第 4 章。这里$0x10 的含义是：
# 请求特权级为 0(位 0-1=0)、选择全局描述符表(位 2=0)、选择表中第 2 项(位 3-15=2)。它正好
# 指向表中的数据段描述符项（描述符的具体数值参见前面 setup.s 中 575--578 行） 。
# 下面代码的含义是：设置 ds,es,fs,gs 为 setup.s 中构造的内核数据段的选择符=0x10（ 对应全局
# 段描述符表第 3 项）， 并将堆栈放置在 stack_start 指向的 user_stack 数组区， 然后使用本程序
# 后面定义的新中断描述符表（ 232 行） 和全局段描述表（ 234—238 行） 。 新全局段描述表中初始
# 内容与 setup.s 中的基本一样，仅段限长从 8MB 修改成了 16MB。 stack_start 定义在
# kernel/sched.c， 82--87 行。它是指向 user_stack 数组末端的一个长指针。第 23 行设置这里
# 使用的栈，姑且称为系统栈。但在移动到任务 0 执行（ init/main.c 中 137 行）以后该栈就被用作
# 任务 0 和任务 1 共同使用的用户栈了。

startup_32: # 18-22 行设置各个数据段寄存器。
  movl $0x10,%eax # 对于 GNU 汇编，每个直接操作数要以'$'开始，否则表示地址。
# 每个寄存器名都要以'%'开头， eax 表示是 32 位的 ax 寄存器。
  mov %ax,%ds
  mov %ax,%es
  mov %ax,%fs
  mov %ax,%gs
  lss _stack_start,%esp   # 表示_stack_startss:esp，设置系统堆栈。
# stack_start 定义在 kernel/sched.c， 82--87 行。
  call setup_idt # 调用设置中断描述符表子程序(67--93 行)。
  call setup_gdt # 调用设置全局描述符表子程序(95--107 行)。
  movl $0x10,%eax # reload all the segment registers
  mov %ax,%ds # after changing gdt. CS was already
  mov %ax,%es # reloaded in 'setup_gdt'
  mov %ax,%fs # 因为修改了 GDT，所以需要重新装载所有的段寄存器。
  mov %ax,%gs # CS 代码段寄存器已经在 setup_gdt 中重新加载过了。
# 由于段描述符中的段限长从 setup.s 中的 8MB 改成了本程序设置的 16MB（见 setup.s 567-578 行
# 和本程序后面的 235-236 行），因此这里必须再次对所有段寄存器执行重加载操作。另外，通过
# 使用 bochs 仿真软件跟踪观察，如果不对 CS 再次执行加载，那么在执行到 26 行时 CS 代码段不可
# 见部分中的限长还是 8MB。这样看来应该重新加载 CS。但是由于 setup.s 中的内核代码段描述符
# 与本程序中重新设置的代码段描述符仅是段限长不同，其余部分完全一样。 所以 8MB 的段限长在
# 内核初始化阶段不会有问题。另外， 在以后内核执行过程中段间跳转指令会重新加载 CS， 所以这
# 里没有加载它并不会导致以后内核出错。
# 针对该问题，目前内核中就在第 25 行之后添加了一条长跳转指令： 'ljmp $(__KERNEL_CS),$1f'，
# 跳转到第 26 行来确保 CS 确实又被重新加载。
  lss _stack_start,%esp6.4 head.s 程序

# 32-36 行用于测试 A20 地址线是否已经开启。采用的方法是向内存地址 0x000000 处写入任意
# 一个数值，然后看内存地址 0x100000(1M)处是否也是这个数值。如果一直相同的话，就一直
# 比较下去，也即死循环、死机。表示地址 A20 线没有选通，结果内核就不能使用 1MB 以上内存。
#
# 33 行上的'1:'是一个局部符号构成的标号。标号由符号后跟一个冒号组成。此时该符号表示活动
# 位置计数（ Active location counter）的当前值，并可以作为指令的操作数。局部符号用于帮助
# 编译器和编程人员临时使用一些名称。共有 10 个局部符号名，可在整个程序中重复使用。这些符号
# 名使用名称'0'、 '1'、 ...、 '9'来引用。为了定义一个局部符号，需把标号写成'N:'形式（其中 N
# 表示一个数字）。为了引用先前最近定义的这个符号，需要写成'Nb'。为了引用一个局部标号的
# 下一个定义，需要写成'Nf'，这里 N 是 10 个前向引用之一。上面'b'表示“ 向后（ backwards） ” ，
# 'f'表示“ 向前（ forwards） ” 。在汇编程序的某一处，我们最大可以向后/向前引用 10 个标号
#（最远第 10 个）。

   xorl %eax,%eax
1: incl %eax # check that A20 really IS enabled
   movl %eax,0x000000 # loop forever if it isn't
   cmpl %eax,0x100000
   je 1b # '1b'表示向后(backward)跳转到标号 1 去（ 33 行）。
# 若是'5f'则表示向前(forward)跳转到标号 5 去。
37 /*
38 * NOTE! 486 should set bit 16, to check for write-protect in supervisor
39 * mode. Then it would be unnecessary with the "verify_area()"-calls.
40 * 486 users probably want to set the NE (#5) bit also, so as to use
41 * int 16 for math errors.
42 */
/*
* 注意! 在下面这段程序中， 486 应该将位 16 置位，以检查在超级用户模式下的写保护,
* 此后 "verify_area()" 调用就不需要了。 486 的用户通常也会想将 NE(#5)置位，以便
* 对数学协处理器的出错使用 int 16。
*/
# 上面原注释中提到的 486 CPU 中 CR0 控制寄存器的位 16 是写保护标志 WP（ Write-Protect），
# 用于禁止超级用户级的程序向一般用户只读页面中进行写操作。该标志主要用于操作系统在创建
# 新进程时实现写时复制（ copy-on-write）方法。
# 下面这段程序（ 43-65）用于检查数学协处理器芯片是否存在。方法是修改控制寄存器 CR0，在
# 假设存在协处理器的情况下执行一个协处理器指令，如果出错的话则说明协处理器芯片不存在，
# 需要设置 CR0 中的协处理器仿真位 EM（位 2），并复位协处理器存在标志 MP（位 1）。
43 movl %cr0,%eax # check math chip
44 andl $0x80000011,%eax # Save PG,PE,ET
45 /* "orl $0x10020,%eax" here for 486 might be good */
46 orl $2,%eax # set MP
47 movl %eax,%cr0
48 call check_x87
49 jmp after_page_tables # 跳转到 135 行。
50
51 /*
52 * We depend on ET to be correct. This checks for 287/387.
53 */
/*
* 我们依赖于 ET 标志的正确性来检测 287/387 存在与否。
*/
# 下面 fninit 和 fstsw 是数学协处理器（ 80287/80387） 的指令。6.4 head.s 程序
253
# finit 向协处理器发出初始化命令，它会把协处理器置于一个未受以前操作影响的已知状态，设置
# 其控制字为默认值、清除状态字和所有浮点栈式寄存器。非等待形式的这条指令（ fninit） 还会让
# 协处理器终止执行当前正在执行的任何先前的算术操作。 fstsw 指令取协处理器的状态字。 如果系
# 统中存在协处理器的话，那么在执行了 fninit 指令后其状态字低字节肯定为 0。
54 check_x87:
55 fninit # 向协处理器发出初始化命令。
56 fstsw %ax # 取协处理器状态字到 ax 寄存器中。
57 cmpb $0,%al # 初始化后状态字应该为 0，否则说明协处理器不存在。
58 je 1f /* no coprocessor: have to set bits */
59 movl %cr0,%eax # 如果存在则向前跳转到标号 1 处，否则改写 cr0。
60 xorl $6,%eax /* reset MP, set EM */
61 movl %eax,%cr0
62 ret
# .align 是一汇编指示符。其含义是指存储边界对齐调整。 "2"表示把随后的代码或数据的偏移位置
# 调整到地址值最后 2 比特位为零的位置（ 2^2） ，即按 4 字节方式对齐内存地址。不过现在 GNU as
# 直接时写出对齐的值而非 2 的次方值了。使用该指示符的目的是为了提高 32 位 CPU 访问内存中代码
# 或数据的速度和效率。
# 下面的两个字节值是 80287 协处理器指令 fsetpm 的机器码。其作用是把 80287 设置为保护模式。
# 80387 无需该指令，并且将会把该指令看作是空操作。
63 .align 2
64 1: .byte 0xDB,0xE4 /* fsetpm for 287, ignored by 387 */ # 287 协处理器码。
65 ret
66
67 /*
68 * setup_idt
69 *
70 * sets up a idt with 256 entries pointing to
71 * ignore_int, interrupt gates. It then loads
72 * idt. Everything that wants to install itself
73 * in the idt-table may do so themselves. Interrupts
74 * are enabled elsewhere, when we can be relatively
75 * sure everything is ok. This routine will be over-
76 * written by the page tables.
77 */
/*
* 下面这段是设置中断描述符表子程序 setup_idt
*
* 将中断描述符表 idt 设置成具有 256 个项，并都指向 ignore_int 中断门。然后加载中断
* 描述符表寄存器(用 lidt 指令)。真正实用的中断门以后再安装。当我们在其他地方认为一切
* 都正常时再开启中断。该子程序将会被页表覆盖掉。
*/
# 中断描述符表中的项虽然也是 8 字节组成，但其格式与全局表中的不同，被称为门描述符
# (Gate Descriptor)。它的 0-1,6-7 字节是偏移量， 2-3 字节是选择符， 4-5 字节是一些标志。
# 这段代码首先在 edx、 eax 中组合设置出 8 字节默认的中断描述符值，然后在 idt 表每一项中
# 都放置该描述符，共 256 项。 eax 含有描述符低 4 字节， edx 含有高 4 字节。内核在随后的初始
# 化过程中会替换安装那些真正实用的中断描述符项。
78 setup_idt:
79 lea ignore_int,%edx # 将 ignore_int 的有效地址（偏移值）值edx 寄存器
80 movl $0x00080000,%eax # 将选择符 0x0008 置入 eax 的高 16 位中。6.4 head.s 程序
254
81 movw %dx,%ax /* selector = 0x0008 = cs */
# 偏移值的低 16 位置入 eax 的低 16 位中。此时 eax 含有
# 门描述符低 4 字节的值。
82 movw $0x8E00,%dx /* interrupt gate - dpl=0, present */
83 # 此时 edx 含有门描述符高 4 字节的值。
84 lea _idt,%edi # _idt 是中断描述符表的地址。
85 mov $256,%ecx
86 rp_sidt:
87 movl %eax,(%edi) # 将哑中断门描述符存入表中。
88 movl %edx,4(%edi) # eax 内容放到 edi+4 所指内存位置处。
89 addl $8,%edi # edi 指向表中下一项。
90 dec %ecx
91 jne rp_sidt
92 lidt idt_descr # 加载中断描述符表寄存器值。
93 ret
94
95 /*
96 * setup_gdt
97 *
98 * This routines sets up a new gdt and loads it.
99 * Only two entries are currently built, the same
100 * ones that were built in init.s. The routine
101 * is VERY complicated at two whole lines, so this
102 * rather long comment is certainly needed :-).
103 * This routine will beoverwritten by the page tables.
104 */
/*
* 设置全局描述符表项 setup_gdt
* 这个子程序设置一个新的全局描述符表 gdt，并加载。此时仅创建了两个表项，与前
* 面的一样。该子程序只有两行，“非常的”复杂，所以当然需要这么长的注释了。
* 该子程序将被页表覆盖掉。
*/
105 setup_gdt:
106 lgdt gdt_descr # 加载全局描述符表寄存器(内容已设置好，见 234-238 行)。
107 ret
108
109 /*
110 * I put the kernel page tables right after the page directory,
111 * using 4 of them to span 16 Mb of physical memory. People with
112 * more than 16MB will have to expand this.
113 */
/* Linus 将内核的内存页表直接放在页目录之后，使用了 4 个表来寻址 16 MB 的物理内存。
* 如果你有多于 16 Mb 的内存，就需要在这里进行扩充修改。
*/
# 每个页表长为 4KB（ 1 页内存页面），而每个页表项需要 4 个字节，因此一个页表共可以存放
# 1024 个表项。如果一个页表项寻址 4KB 的地址空间，则一个页表就可以寻址 4 MB 的物理内存。
# 页表项的格式为：项的前 0-11 位存放一些标志，例如是否在内存中(P 位 0)、读写许可(R/W 位 1)、
# 普通用户还是超级用户使用(U/S 位 2)、是否修改过(是否脏了)(D 位 6)等；表项的位 12-31 是
# 页框地址，用于指出一页内存的物理起始地址。
114 .org 0x1000 # 从偏移 0x1000 处开始是第 1 个页表（偏移 0 开始处将存放页表目录）。
115 pg0:
1166.4 head.s 程序
255
117 .org 0x2000
118 pg1:
119
120 .org 0x3000
121 pg2:
122
123 .org 0x4000
124 pg3:
125
126 .org 0x5000 # 定义下面的内存数据块从偏移 0x5000 处开始。
127 /*
128 * tmp_floppy_area is used by the floppy-driver when DMA cannot
129 * reach to a buffer-block. It needs to be aligned, so that it isn't
130 * on a 64kB border.
131 */
/* 当 DMA（直接存储器访问）不能访问缓冲块时，下面的 tmp_floppy_area 内存块
* 就可供软盘驱动程序使用。其地址需要对齐调整，这样就不会跨越 64KB 边界。
*/
132 _tmp_floppy_area:
133 .fill 1024,1,0 # 共保留 1024 项，每项 1 字节，填充数值 0。
134
# 下面这几个入栈操作用于为跳转到 init/main.c 中的 main()函数作准备工作。第 139 行上的指令
# 在栈中压入了返回地址(标号 L6)，而第 140 行则压入了 main()函数代码的地址。当 head.s 最后
# 在第 218 行执行 ret 指令时就会弹出 main()的地址，并把控制权转移到 init/main.c 程序中。
# 参见第 3 章中有关 C 函数调用机制的说明。
# 前面 3 个入栈 0 值分别表示 main 函数的参数 envp、 argv 指针和 argc，但 main()没有用到。
# 139 行的入栈操作是模拟调用 main 程序时将返回地址入栈的操作，所以如果 main.c 程序
# 真的退出时，就会返回到这里的标号 L6 处继续执行下去，也即死循环。 140 行将 main.c 的地址
# 压入堆栈，这样，在设置分页处理（ setup_paging）结束后执行'ret'返回指令时就会将 main.c
# 程序的地址弹出堆栈，并去执行 main.c 程序了。
135 after_page_tables:
136 pushl $0 # These are the parameters to main :-)
137 pushl $0 # 这些是调用 main 程序的参数（指 init/main.c）。
138 pushl $0 # 其中的'$'符号表示这是一个立即操作数。
139 pushl $L6 # return address for main, if it decides to.
140 pushl $_main # '_main'是编译程序对 main 的内部表示方法。
141 jmp setup_paging # 跳转至第 198 行。
142 L6:
143 jmp L6 # main should never return here, but
144 # just in case, we know what happens.
# main 程序绝对不应该返回到这里。不过为了以防万一，
# 所以添加了该语句。这样我们就知道发生什么问题了。
145
146 /* This is the default interrupt "handler" :-) */
/* 下面是默认的中断“向量句柄”  */
147 int_msg:
148 .asciz "Unknown interrupt\n\r" # 定义字符串“未知中断(回车换行)”。
149 .align 2 # 按 4 字节方式对齐内存地址。
150 ignore_int:
151 pushl %eax
152 pushl %ecx
153 pushl %edx
154 push %ds # 这里请注意！！ ds,es,fs,gs 等虽然是 16 位的寄存器，但入栈后6.4 head.s 程序
256
155 push %es # 仍然会以 32 位的形式入栈，也即需要占用 4 个字节的堆栈空间。
156 push %fs
157 movl $0x10,%eax # 置段选择符（使 ds,es,fs 指向 gdt 表中的数据段）。
158 mov %ax,%ds
159 mov %ax,%es
160 mov %ax,%fs
161 pushl $int_msg # 把调用 printk 函数的参数指针（地址）入栈。注意！若 int_msg
162 call _printk # 前不加'$'，则表示把 int_msg 符号处的长字（ 'Unkn'）入栈。
163 popl %eax # 该函数在/kernel/printk.c 中。 '_printk'是 printk 编译后模块中
164 pop %fs # 的内部表示法。
165 pop %es
166 pop %ds
167 popl %edx
168 popl %ecx
169 popl %eax
170 iret # 中断返回（把中断调用时压入栈的 CPU 标志寄存器（ 32 位）值也弹出）。
171
172
173 /*
174 * Setup_paging
175 *
176 * This routine sets up paging by setting the page bit
177 * in cr0. The page tables are set up, identity-mapping
178 * the first 16MB. The pager assumes that no illegal
179 * addresses are produced (ie >4Mb on a 4Mb machine).
180 *
181 * NOTE! Although all physical memory should be identity
182 * mapped by this routine, only the kernel page functions
183 * use the >1Mb addresses directly. All "normal" functions
184 * use just the lower 1Mb, or the local data space, which
185 * will be mapped to some other place - mm keeps track of
186 * that.
187 *
188 * For those with more memory than 16 Mb - tough luck. I've
189 * not got it, why should you :-) The source is here. Change
190 * it. (Seriously - it shouldn't be too difficult. Mostly
191 * change some constants etc. I left it at 16Mb, as my machine
192 * even cannot be extended past that (ok, but it was cheap :-)
193 * I've tried to show which constants to change by having
194 * some kind of marker at them (search for "16Mb"), but I
195 * won't guarantee that's all :-( )
196 */
/*
* 这个子程序通过设置控制寄存器 cr0 的标志（ PG 位 31）来启动对内存的分页处理功能，
* 并设置各个页表项的内容，以恒等映射前 16 MB 的物理内存。分页器假定不会产生非法的
* 地址映射（也即在只有 4Mb 的机器上设置出大于 4Mb 的内存地址）。
*
* 注意！尽管所有的物理地址都应该由这个子程序进行恒等映射，但只有内核页面管理函数能
* 直接使用>1Mb 的地址。所有“普通”函数仅使用低于 1Mb 的地址空间，或者是使用局部数据
* 空间，该地址空间将被映射到其他一些地方去 -- mm（内存管理程序）会管理这些事的。
*
* 对于那些有多于 16Mb 内存的家伙 – 真是太幸运了，我还没有，为什么你会有。代码就在
* 这里，对它进行修改吧。（实际上，这并不太困难的。通常只需修改一些常数等。我把它设置6.4 head.s 程序
257
* 为 16Mb，因为我的机器再怎么扩充甚至不能超过这个界限（当然，我的机器是很便宜的）。
* 我已经通过设置某类标志来给出需要改动的地方（搜索“ 16Mb” ） ，但我不能保证作这些
* 改动就行了）。
*/
# 上面英文注释第 2 段的含义是指在机器物理内存中大于 1MB 的内存空间主要被用于主内存区。
# 主内存区空间由 mm 模块管理。它涉及到页面映射操作。内核中所有其他函数就是这里指的一般
#（普通）函数。若要使用主内存区的页面，就需要使用 get_free_page()等函数获取。 因为主内
# 存区中内存页面是共享资源，必须有程序进行统一管理以避免资源争用和竞争。
#
# 在内存物理地址 0x0 处开始存放 1 页页目录表和 4 页页表。页目录表是系统所有进程公用的，而
# 这里的 4 页页表则属于内核专用，它们一一映射线性地址起始 16MB 空间范围到物理内存上。对于
# 新建的进程，系统会在主内存区为其申请页面存放页表。另外， 1 页内存长度是 4096 字节。
197 .align 2 # 按 4 字节方式对齐内存地址边界。
198 setup_paging: # 首先对 5 页内存（ 1 页目录 + 4 页页表）清零。
199 movl $1024*5,%ecx /* 5 pages - pg_dir+4 page tables */
200 xorl %eax,%eax
201 xorl %edi,%edi /* pg_dir is at 0x000 */
# 页目录从 0x000 地址开始。
202 cld;rep;stosl # eax 内容存到 es:edi 所指内存位置处，且 edi 增 4。
# 下面 4 句设置页目录表中的项。 因为我们（内核）共有 4 个页表， 所以只需设置 4 项。
# 页目录项的结构与页表中项的结构一样， 4 个字节为 1 项。参见上面 113 行下的说明。
# 例如"$pg0+7"表示： 0x00001007，是页目录表中的第 1 项。
# 则第 1 个页表所在的地址 = 0x00001007 & 0xfffff000 = 0x1000；
# 第 1 个页表的属性标志 = 0x00001007 & 0x00000fff = 0x07，表示该页存在、用户可读写。
203 movl $pg0+7,_pg_dir /* set present bit/user r/w */
204 movl $pg1+7,_pg_dir+4 /* --------- " " --------- */
205 movl $pg2+7,_pg_dir+8 /* --------- " " --------- */
206 movl $pg3+7,_pg_dir+12 /* --------- " " --------- */
# 下面 6 行填写 4 个页表中所有项的内容，共有： 4(页表)*1024(项/页表)=4096 项(0 - 0xfff)，
# 也即能映射物理内存 4096*4Kb = 16Mb。
# 每项的内容是：当前项所映射的物理内存地址 + 该页的标志（这里均为 7）。
# 填写使用的方法是从最后一个页表的最后一项开始按倒退顺序填写。 每一个页表中最后一项在表中
# 的位置是 1023*4 = 4092。因此最后一页的最后一项的位置就是$pg3+4092。
207 movl $pg3+4092,%edi # edi最后一页的最后一项。
208 movl $0xfff007,%eax /* 16Mb - 4096 + 7 (r/w user,p) */
# 最后 1 项对应物理内存页面的地址是 0xfff000，
# 加上属性标志 7，即为 0xfff007。
209 std # 方向位置位， edi 值递减(4 字节)。
210 1: stosl /* fill pages backwards - more efficient :-) */
211 subl $0x1000,%eax # 每填写好一项，物理地址值减 0x1000。
212 jge 1b # 如果小于 0 则说明全添写好了。
# 现在设置页目录表基址寄存器 cr3，指向页目录表。 cr3 中保存的是页目录表的物理地址， 然后
# 再设置启动使用分页处理（ cr0 的 PG 标志，位 31）
213 xorl %eax,%eax /* pg_dir is at 0x0000 */ # 页目录表在 0x0000 处。
214 movl %eax,%cr3 /* cr3 - page directory start */
215 movl %cr0,%eax
216 orl $0x80000000,%eax # 添上 PG 标志。
217 movl %eax,%cr0 /* set paging (PG) bit */
218 ret /* this also flushes prefetch-queue */6.4 head.s 程序
258
# 在改变分页处理标志后要求使用转移指令刷新预取指令队列。 这里用的是返回指令 ret。
# 该返回指令的另一个作用是将 140 行压入堆栈中的 main 程序的地址弹出，并跳转到/init/main.c
# 程序去运行。本程序到此就真正结束了。
219
220 .align 2 # 按 4 字节方式对齐内存地址边界。
221 .word 0 # 这里先空出 2 字节，这样 224 行上的长字是 4 字节对齐的。
! 下面是加载中断描述符表寄存器 idtr 的指令 lidt 要求的 6 字节操作数。前 2 字节是 idt 表的限长，
! 后 4 字节是 idt 表在线性地址空间中的 32 位基地址。
222 idt_descr:
223 .word 256*8-1 # idt contains 256 entries # 共 256 项，限长=长度 - 1。
224 .long _idt
225 .align 2
226 .word 0
! 下面加载全局描述符表寄存器 gdtr 的指令 lgdt 要求的 6 字节操作数。前 2 字节是 gdt 表的限长，
! 后 4 字节是 gdt 表的线性基地址。这里全局表长度设置为 2KB 字节（ 0x7ff 即可） ，因为每 8 字节
! 组成一个描述符项，所以表中共可有 256 项。符号_gdt 是全局表在本程序中的偏移位置，见 234 行。
227 gdt_descr:
228 .word 256*8-1 # so does gdt (not that that's any # 注： not  note
229 .long _gdt # magic number, but it works for me :^)
230
231 .align 3 # 按 8（ 2^3）字节方式对齐内存地址边界。
232 _idt: .fill 256,8,0 # idt is uninitialized # 256 项，每项 8 字节，填 0。
233
# 全局描述符表。 其前 4 项分别是： 空项（不用）、代码段描述符、数据段描述符、系统调用段描述符，
# 其中系统调用段描述符并没有派用处， Linus 当时可能曾想把系统调用代码放在这个独立的段中。
# 后面还预留了 252 项的空间，用于放置新创建任务的局部描述符(LDT)和对应的任务状态段 TSS
# 的描述符。
# (0-nul, 1-cs, 2-ds, 3-syscall, 4-TSS0, 5-LDT0, 6-TSS1, 7-LDT1, 8-TSS2 etc...)
234 _gdt: .quad 0x0000000000000000 /* NULL descriptor */
235 .quad 0x00c09a0000000fff /* 16Mb */ # 0x08，内核代码段最大长度 16MB。
236 .quad 0x00c0920000000fff /* 16Mb */ # 0x10，内核数据段最大长度 16MB。
237 .quad 0x0000000000000000 /* TEMPORARY - don't use */
238 .fill 252,8,0 /* space for LDT's and TSS's etc */ # 预留空间。
```

## 6.4.3其他信息

6.4.3.1 程序执行结束后的内存映像

head.s 程序执行结束后， 内核代码就算已经正式完成了内存页目录和页表的设置，并重新设置了内核实际使用的中断描述符表 IDT 和全局描述符表 GDT。另外，代码还为软盘驱动程序开辟了 1KB 字节的缓冲区。此时 system 模块在内存中的详细映像见图 6-11 所示。

```
lib 模块代码
fs 模块代码
mm 模块代码
kernel 模块代码
main.c 程序代码
全局描述符表 gdt(2k)   --------
中断描述符表 idt(2k)           |
head.s 部分代码                |
软盘缓冲区(1k)       0x5000-   |  head.s
内存页表pg3(4k)      0x4000-   |
内存页表pg2(4k)      0x3000-   |
内存页表pg1(4k)      0x2000-   |
内存页表pg0(4k)      0x1000-   |
内存页目录表(4k)     0x0000-   |
```

图 6-11 system 模块在内存中的映像示意图

6.4.3.2 Intel 32 位保护运行机制

理解这段程序的关键是真正了解 Intel 80X86 32 位保护模式的运行机制。为了与 8086 CPU 兼容， 80X86 的保护模式运行机制被设计得比较复杂。 有关对保护模式运行机制的详细描述请参见第 4 章，这里用实模式和保护模式对照比较的方式对保护运行机制作一简要介绍。

CPU 在实模式方式运行时，段寄存器用来放置一个内存段的基地址（例如 0x9000）， 内存段的大小固定为 64KB。因此该段内可以寻址最多 64KB 的内存。但当进入保护模式运行方式时，此时段寄存器中放置的并不是内存中的某个段基地址值，而是指定描述符表中该段对应的描述符项的选择符。 在这个8 字节的描述符中含有该段线性地址的‘段’基地址和段的长度，以及其他一些描述该段特征的比特位。因此此时所寻址的内存位置是这个段基地址址加上当前偏移值来指定。 当然，此时所寻址的实际物理内存地址还需要经过内存页面处理管理机制进行变换后才能得到。简言之， 32 位保护模式下的内存寻址方式需要拐个弯， 即需要使用描述符表中的描述符和内存页管理来确定。

针对不同用途，描述符表分为三种：全局描述符表（ GDT）、中断描述符表（ IDT）和局部描述符表（ LDT）。当 CPU 运行在保护模式下，某一时刻 GDT 和 IDT 分别只能有一个，分别由寄存器 GDTR 和IDTR 指定它们的表基址。 局部表的个数可以有 0 个或最多 8191 个，这由 GDT 表中未用项数和所设计的具体系统确定。在某一个时刻，当前 LDT 表的基址由 LDTR 寄存器的内容指定，并且 LDTR 的内容使用 GDT 中某个描述符来加载，即 LDT 也是由 GDT 中的描述符来指定。

通常来说，内核对于每个任务（进程）使用一个 LDT。在运行时，程序可以使用 GDT 中的描述符以及当前任务的 LDT 中的描述符。对于 Linux 0.12 内核来说同时可以有 64 个任务在执行，因此 GDT 表中最多有 64 个 LDT 表的描述符项存在。

中断描述符表 IDT 的结构与 GDT 类似，在 Linux 内核中它正好位于 GDT 表的前面。共含有 256 项8 字节的描述符。但每个描述符项的格式与 GDT 的不同，其中存放着相应中断过程的偏移值（ 0-1， 6-7 字节）、所处段的选择符值（ 2-3 字节）和一些标志（ 4-5 字节）。

图 6-12 是 Linux 内核中所使用的描述符表在内存中的示意图。图中， 每个任务在 GDT 中占有两个描述符项。 GDT 表中的 LDT0 描述符项是第一个任务（进程）的局部描述符表的描述符， TSS0 是第一个任务的任务状态段（ TSS）的描述符。每个 LDT 中含有三个描述符，其中第一个不用，第二个是任务代码段的描述符，第三个是任务数据段和堆栈段的描述符。当 DS 段寄存器中是第一个任务的数据段选择符时， DS:ESI 即指向该任务数据段中的某个数据。

```
                                  DS:段限长
                                --------------|  
                                              |
                                              |   数据段
                                              |
ESI 寄存器        数据项            DS:ESI  ---|
                                    DS:0

DS 段寄存器        数据&堆栈段描述符
CS 段寄存器        任务代码段描述符           局部描述符表 LDT0
                  描述符(NULL)
                  
                  
                  LDTn 描述符
                  TSSn 描述符
                  ...
                  LDT2 描述符
                  TSS2 描述符
                  LDT1 描述符                  全局描述符表 GDT
                  TSS1 描述符                  共 256 个描述符
LDTR 寄存器        LDT0 描述符
                  TSS0 描述符
                  系统段描述符(未用)
                  内核数据段描述符
                  内核代码段描述符
                  描述符(NULL)
GDTR 寄存器                         00000000
```

图 6-12 Linux 内核使用描述符表的示意图。

6.4.3.3 伪指令 align

在第 3 章介绍汇编器时我们已经对 align 伪指令进行了说明。这里我们再总结一下。使用伪指令 `.align` 的作用是在编译时指示编译器填充位置计数器（类似指令计数器）到一个指定的内存边界处。目的是为了提高 CPU 访问内存中代码或数据的速度和效率。其完整格式为：

`.align val1, val2, val3`

其中第 1 个参数值 val1 是所需要的对齐值；第 2 个是填充字节指定的值。填充值可以省略。若省略则编译器使用 0 值填充。第 3 个可选参数值 val3 用来指明最大用于填充或跳过的直接数。如果进行边界对齐会超过 val3 指定的最大字节数，那么就根本不进行对齐操作。如果需要省略第 2 个参数 val2 但还是需要使用第 3 个参数 val3，那么只需要放置两个逗号即可。

对于现在使用 ELF 目标格式的程序，第 1 个参数 val1 是需要对齐的字节数。例如， '.align 8'表示调整位置计数器直到它指在 8 的倍数边界上。如果已经在 8 的倍数边界上，那么编译器就不用改变了。但对于我们这里使用 a.out 目标格式的系统来说，第 1 个参数 val1 是指定低位 0 比特的个数，即 2 的次方数（ 2^Val1）。例如前面程序 head.s 中的'.align 3'就表示位置计数器需要位于 8 的倍数边界上。同样，如果已经在 8 的倍数边界上，那么该伪指令什么也不做。 GNU as（ gas） 对这两个目标格式的不同处理方法是由于 gas 为了模仿各种体系结构系统上自带的汇编器的行为而形成的。

6.5 本章小结

引导加载程序 bootsect.S 将 setup.s 代码和 system 模块加载到内存中，并且分别把自己和 setup.s 代码移动到物理内存 0x90000 和 0x90200 处后，就把执行权交给了 setup 程序。其中 system 模块的首部包含有 head.s 代码。

setup 程序的主要作用是利用 ROM BIOS 的中断程序获取机器的一些基本参数，并保存在 0x90000 开始的内存块中，供后面程序使用。同时把 system 模块往下移动到物理地址 0x00000 开始处，这样， system 中的 head.s 代码就处在 0x00000 开始处了。然后加载描述符表基地址到描述符表寄存器中，为进行 32 位保护模式下的运行作好准备。接下来对中断控制硬件进行重新设置，最后通过设置机器控制寄存器 CR0 并跳转到 system 模块的 head.s 代码开始处，使 CPU 进入 32 位保护模式下运行。

Head.s 代码的主要作用是初步初始化中断描述符表中的 256 项门描述符，检查 A20 地址线是否已经打开，测试系统是否含有数学协处理器。然后初始化内存页目录表，为内存的分页管理作好准备工作。最后跳转到 system 模块中的初始化程序 init/main.c 中继续执行。

下一章的主要内容就是详细描述 init/main.c 程序的功能和作用。
```
