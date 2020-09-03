# boot/head.s

## 功能描述 (from 0.12)

head.s 程序在被编译生成目标文件后会与内核其他程序的目标文件一起被链接成 system 模块， 并位于 system 模块的最前面开始部分。 这也就是为什么称其为头部(head)程序的原因。 system 模块将被放置
在磁盘上 setup 模块之后开始的扇区中，即从磁盘上第 6 个扇区开始放置。一般情况下 Linux 0.12 内核的 system 模块大约有 120KB 左右，因此在磁盘上大约占 240 个扇区。

从这里开始，内核完全都是在保护模式下运行了。 heads.s 汇编程序与前面汇编的语法格式不同，它采用的是 AT&T 的汇编语言格式，并且需要使用 GNU 的 gas 和 gld7进行编译连接。因此请注意代码中赋值的方向是从左到右。

这段程序实际上处于内存绝对地址 0 处开始的地方。这个程序的功能比较单一。首先它加载各个数据段寄存器，重新设置中断描述符表 IDT，共 256 项，并使各个表项均指向一个只报错误的哑中断子程序 ignore_int。 这个哑中断向量指向一个默认的“ ignore_int”处理过程（ boot/head.s， 150）。当发生了一个中断而又没有重新设置过该中断向量时就会显示信息“未知中断（ Unknown interrupt）”。这里对所有 256 项都进行设置可以有效防止出现一般保护性错误（ A gerneal protection fault） (异常 13)。 否则的话，如果设置的 IDT 少于 256 项，那么在一个要求的中断所指定的描述符项大于设置的最大描述符项时， CPU 就会产生一个一般保护出错（异常 13）。另外，如果硬件出现问题而没有把设备的向量放到数据总线上，此时 CPU 通常会从数据总线上读入全 1（ 0xff） 作为向量，因此会去读取 IDT 表中的第 256 项， 因此也会造成一般保护出错。

对于系统中需要使用的一些中断，内核会在其继续初始化的处理过程中（ init/main.c）重新设置这些中断的中断描述符项，让它们指向对应的实际处理过程。通常，异常中断处理过程（ int0 --int 31） 都在 traps.c 的初始化函数中进行了重新设置（ kernl/traps.c，第 185 行），而系统调用中断 int128 则在调度程序初始化函数中进行了重新设置（ kernel/sched.c，第 417 行）。

中断描述符表中每个描述符项也占 8 字节，其格式见图 6-9 所示。 其中， P 是段存在标志； DPL 是描述符的优先级。

图 6-9 中断描述符表 IDT 中的中断门描述符格式

在 head.s 程序中，中断门描述符中段选择符字段被设置为 0x0008，表示该哑中断服务处理程序 ignore_int 在内核代码中，而偏移值被设置为 ignore_int 中断服务处理程序在 head.s 程序中的偏移值。由于 head.s 程序被移动到从内存地址 0 开始处，因此该偏移值也就是中断处理子程序在内核代码段中的偏移值。由于内核代码段一直存在于内存中，并且特权级为 0（ 即 P=1， DPL=00）， 因此从图中可知中断门描述符的字节 5 和字节 4 的值应该是 0x8E00。

在设置好中断描述符表之后，本程序又重新设置了全局段描述符表 GDT。实际上新设置的 GDT 表与原来在 setup.s 程序中设置的 GDT 表描述符除了在段限长上有些区别以外（原为 8MB，现为 16MB），其他内容完全一样。当然我们也可以在 setup.s 程序中就把描述符的段限长直接设置成 16MB，然后直接把原 GDT 表移动到内存适当位置处。因此这里重新设置 GDT 的主要原因是为了把 GDT 表放在内存内核代码比较合理的地方。 而前面设置的 GDT 表处于内存 0x902XX 处。这个地方将在内核初始化后用作内存高速缓冲区的一部分。

*在当前的 Linux 操作系统中， gas 和 gld 已经分别更名为 as 和 ld。*

接着检测 A20 地址线是否已开启。方法是将物理地址 0 开始处与 1MB 开始处的字节内容进行比较。 如果 A20 线没有开启，则在访问高于 1MB 物理内存地址时 CPU 实际上会循环访问（ 地址 MOD 1MB）地址处的内容，也即与访问从 0 地址开始对应字节的内容都相同。 如果检测下来发现没有开启， 则进入死循环。 否则程序将继续执行去测试 PC 机是否含有数学协处理器芯片（ 80287、 80387 或其兼容芯片），并在控制寄存器 CR0 中设置相应的标志位。

接着程序设置管理内存的分页处理机制，将页目录表放在绝对物理地址 0 开始处（也是本程序所处的物理内存位置，因此这段程序已执行部分将被覆盖掉）， 紧随后面会放置共可寻址 16MB 内存的 4 个页表， 并分别设置它们的表项。 页目录表项和页表项格式见图 6-10 所示。其中 P 是页面存在于内存标志；R/W 是读写标志； U/S 是用户/超级用户标志； A 是页面已访问标志； D 是页面内容已修改标志；最左边 20 比特是表项对应页面在物理内存中页面地址的高 20 比特位。

图 6-10 页目录表项和页表项结构

这里每个表项的属性标志都被设置成 0x07（ P=1、 U/S=1、 R/W=1），表示该页存在、用户可读写。 这样设置内核页表属性的原因是： CPU 的分段机制和分页管理都有保护方法。分页机制中页目录表和页表项中设置的保护标志（ U/S、 R/W）需要与段描述符中的特权级（ PL）保护机制一起组合使用。但段描述符中的 PL 起主要作用。 CPU 会首先检查段保护，然后再检查页保护。如果当前特权级 CPL < 3（例如 0），则说明 CPU 正在以超级用户（ Supervisor）身份运行。 此时所有页面都能访问，并可随意进行内存读写操作。如果 CPL = 3，则说明 CPU 正在以用户（ User）身份运行。此时只有属于 User 的页面（ U/S=1）可以访问，并且只有标记为可读写的页面（ W/R = 1）是可写的。 而此时属于超级用户的页面（ U/S=0）则既不可写、也不可以读。 由于内核代码有些特别之处，即其中包含有任务 0 和任务 1 的代码和数据。因此这里把页面属性设置为 0x7 就可以保证这两个任务代码能够在用户态下执行， 但却又不能随意访问内核资源。

最后， head.s 程序利用返回指令将预先放置在堆栈中的/init/main.c 程序的入口地址弹出，去运行 main() 程序。

## 程序执行结束后的内存映像 (0.12)

head.s 程序执行结束后， 内核代码就算已经正式完成了内存页目录和页表的设置，并重新设置了内核实际使用的中断描述符表 IDT 和全局描述符表 GDT。另外，代码还为软盘驱动程序开辟了 1KB 字节的缓冲区。此时 system 模块在内存中的详细映像见图 6-11 所示。

```
lib 模块代码
fs 模块代码
mm 模块代码
kernel 模块代码
main.c 程序代码
全局描述符表 gdt(2k)     --------
中断描述符表 idt(2k)             |
head.s 部分代码                 |
软盘缓冲区(1k)        0x5000-   |   head.s Code
内存页表 pg3(4k)      0x4000-   |
内存页表 pg2(4k)      0x3000-   |
内存页表 pg1(4k)      0x2000-   |
内存页表 pg0(4k)      0x1000-   |
内存页目录表(4k)       0x0000-   |
```
图 6-11 system 模块在内存中的映像示意图

## Source Code Dive-In

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
  lss _stack_start,%esp  # _stack_start -> ss:esp，设置系统堆栈。
  call setup_idt   # 调用设置中断描述符表子程序
  call setup_gdt   # 调用设置全局描述符表子程序
  movl $0x10,%eax # reload all the segment registers
  mov %ax,%ds   # after changing gdt. CS was already reloaded in ’setup_gdt’
  mov %ax,%es
  mov %ax,%fs   # 因为修改了GDT，所以需要重新装载所有的段寄存器。
  mov %ax,%gs   # CS代码段寄存器已经在 setup_gdt 中重新加载过了。
  lss _stack_start,%esp
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

*Then again modify the segment registers to reflect the “new” values in the GDT and IDT.*

```asm
   xorl %eax,%eax
1: incl %eax       # check that A20 really IS enabled
   movl %eax,0x000000  # loop forever if it isn't
   cmpl %eax,0x100000
   je 1b    # '1b'表示向后(backward)跳转到标号 1 去（ 33 行）
            # 若是'5f'则表示向前(forward)跳转到标号 5 去。
```

以上代码行用于测试 A20 地址线是否已经开启。采用的方法是向内存地址 0x000000 处写入任意一个数值，然后看内存地址 0x100000(1M)处是否也是这个数值。如果一直相同的话，就一直比较下去，也即死循环、死机。表示地址 A20 线没有选通，结果内核就不能使用 1MB 以上内存。

`1:` 是一个局部符号构成的标号。标号由符号后跟一个冒号组成。此时该符号表示活动位置计数（ Active location counter）的当前值，并可以作为指令的操作数。局部符号用于帮助编译器和编程人员临时使用一些名称。共有 10 个局部符号名，可在整个程序中重复使用。这些符号名使用名称'0'、 '1'、 ...、 '9'来引用。为了定义一个局部符号，需把标号写成'N:'形式（其中 N 表示一个数字）。为了引用先前最近定义的这个符号，需要写成'Nb'。为了引用一个局部标号的下一个定义，需要写成'Nf'，这里 N 是 10 个前向引用之一。上面'b'表示“ 向后（ backwards） ” ， 'f'表示“ 向前（ forwards） ” 。在汇编程序的某一处，我们最大可以向后/向前引用 10 个标号（最远第 10 个）。

下面这段程序用于检查数学协处理器芯片是否存在。 We depend on ET to be correct.

```asm
   movl %cr0,%eax         # check math chip
   andl $0x80000011,%eax  # Save PG,ET,PE
   testl $0x10,%eax
   jne 1f            # ET is set - 387 is present
   orl $4,%eax       # else set emulate bit
1: movl %eax,%cr0
   jmp after_page_tables
```

*Now the “jmp after_page_tables”. All the memory till the label after_page_tables will be used for paging and will be over written.*

Now let's sets up a idt with 256 entries pointing to ignore_int, interrupt gates. It then loads idt (using `lidt`). Everything that wants to install itself in the idt-table may do so themselves. Interrupts are enabled elsewhere, when we can be relatively sure everything is ok. This routine will be overwritten by the page tables.

中断描述符表中的项虽然也是 8 字节组成，但其格式与全局表中的不同，被称为门描述符(Gate Descriptor)。它的 0-1,6-7 字节是偏移量， 2-3 字节是选择符， 4-5 字节是一些标志。 这段代码首先在 edx、 eax 中组合设置出 8 字节默认的中断描述符值，然后在 idt 表每一项中都放置该描述符，共 256 项。 eax 含有描述符低 4 字节， edx 含有高 4 字节。内核在随后的初始化过程中会替换安装那些真正实用的中断描述符项。

```asm
setup_idt:
  lea ignore_int,%edx    # 将 ignore_int 的有效地址（偏移值）值 -> edx 寄存器
  movl $0x00080000,%eax  # 将选择符 0x0008 置入 eax 的高 16 位中
    # 偏移值的低 16 位置入 eax 的低 16 位中。此时 eax 含有门描述符低 4 字节的值
  movw %dx,%ax      # selector = 0x0008 = cs
    # 此时 edx 含有门描述符高 4 字节的值。
  movw $0x8E00,%dx  # interrupt gate - dpl=0, present
  lea _idt,%edi     # _idt 是中断描述符表的地址
  mov $256,%ecx
rp_sidt:
  movl %eax,(%edi)   # 将哑中断门描述符存入表中。
  movl %edx,4(%edi)  # eax 内容放到 edi+4 所指内存位置处
  addl $8,%edi       # edi 指向表中下一项
  dec %ecx
  jne rp_sidt
  lidt idt_descr     # 加载中断描述符表寄存器值
  ret
```

*The comments by Linus for this function are pretty self evident. The IDT with 256 entries is represented by the variable _idt. Now after initializing _idt with “ignore_int” (the actual interrupts will be initialized later at various points), the lidt instruction is used with idt_descr as parameter, whose format again can be
understood by looking into the manual.*

This routines sets up a new gdt and loads it. Only two entries are currently built, the same ones that were built in init.s. The routine is VERY complicated at two whole lines, so this rather long comment is certainly needed :-). This routine will beoverwritten by the page tables.

```asm
setup_gdt:
  lgdt gdt_descr   # 加载全局描述符表寄存器(内容已设置好，见后面)
  ret

.org 0x1000  # 从偏移 0x1000 处开始是第 1 个页表（偏移 0 开始处将存放页表目录）
pg0:

.org 0x2000
pg1:

.org 0x3000
pg2:   # This is not used yet, but if you want to
       # expand past 8 Mb, you’ll have to use it.
.org 0x4000
```

*Let us explain a bit about the page directory and the page tables. The Intel architecture uses two levels of paging - one page directory and 1024 page tables. The page directory starts from 0x0 and extends till 0x1000 (4K). In 0.01, we use two page tables which start at 0x10000 (pg0) and 0x20000 (pg1) respectively. These page tables are respectively the first and second entries in the page directory. So we can see that the total memory that can be mapped by two page tables is 2 * 1024 pages = 8Mb (one page = 4K). Now the page table starting at 0x30000 till 0x40000 (pg2) is not in use in 0.01. Again, one point to be noted is that these page directory/tables are for use ONLY by the kernel. Each process will have to setup its’ own page directory and page tables (TODO: not very sure, will correct/confirm this later)*

下面这几个入栈操作用于为跳转到 init/main.c 中的 main()函数作准备工作。第 139 行上的指令在栈中压入了返回地址(标号 L6)，而第 140 行则压入了 main()函数代码的地址。当 head.s 最后在第 218 行执行 ret 指令时就会弹出 main()的地址，并把控制权转移到 init/main.c 程序中。 参见第 3 章中有关 C 函数调用机制的说明。

前面 3 个入栈 0 值分别表示 main 函数的参数 envp、 argv 指针和 argc，但 main()没有用到。 139 行的入栈操作是模拟调用 main 程序时将返回地址入栈的操作，所以如果 main.c 程序真的退出时，就会返回到这里的标号 L6 处继续执行下去，也即死循环。 140 行将 main.c 的地址压入堆栈，这样，在设置分页处理（ setup_paging）结束后执行'ret'返回指令时就会将 main.c 程序的地址弹出堆栈，并去执行 main.c 程序了。

```asm
after_page_tables:
  pushl $0   # These are the parameters to main :-)
  pushl $0   # 其中的'$'符号表示这是一个立即操作数。
  pushl $0
  pushl $L6     # return address for main, if it decides to.
  pushl $_main  # '_main'是编译程序对 main 的内部表示方法。
  jmp setup_paging
L6:
  jmp L6  # main should never return here, but added
          # just in case, so we know what happens.
```

* After setting up paging, we jump to main, where the actual “C” code for the kernel starts.

Below `ignore_int:` is the default interrupt "handler" :-)

```asm
.align 2
ignore_int:
  incb 0xb8000+160     # put something on the screen
  movb $2,0xb8000+161  # so that we know something
  iret                 # happened
```


*Note `.align` 是一汇编指示符。其含义是指存储边界对齐调整。 "2"表示把随后的代码或数据的偏移位置调整到地址值最后 2 比特位为零的位置（ 2^2） ，即按 4 字节方式对齐内存地址。不过现在 GNU as 直接时写出对齐的值而非 2 的次方值了。使用该指示符的目的是为了提高 32 位 CPU 访问内存中代码或数据的速度和效率。*

```asm
.align 2    # 按 4 字节方式对齐内存地址边界。
setup_paging:  # 首先对 ? 页内存（ 1 页目录 + 4 页页表）清零。
  movl $1024*3,%ecx  /* ? pages - pg_dir+4 page tables */
  xorl %eax,%eax
  xorl %edi,%edi  # pg_dir is at 0x000
  cld;rep;stosl   # eax 内容存到 es:edi 所指内存位置处，且 edi 增 4。
```

`Setup_paging`: This routine sets up paging by setting the page bit in cr0. The page tables are set up, identity-mapping the first 8MB. The pager assumes that no illegal addresses are produced (ie >4Mb on a 4Mb machine).

NOTE! Although all physical memory should be identity mapped by this routine, only the kernel page functions use the >1Mb addresses directly. All "normal" functions use just the lower 1Mb, or the local data space, which will be mapped to some other place - mm keeps track of that.

For those with more memory than 8 Mb - tough luck. I’ve not got it, why should you :-) The source is here. Change it. (Seriously - it shouldn’t be too difficult. Mostly change some constants etc. I left it at 8Mb, as my machine even cannot be extended past that (ok, but it was cheap :-) I’ve tried to show which constants to change by having some kind of marker at them (search for "8Mb"), but I won’t guarantee that’s all :-( )

这个子程序通过设置控制寄存器 cr0 的标志（ PG 位 31）来启动对内存的分页处理功能，并设置各个页表项的内容，以恒等映射前 16 MB 的物理内存。分页器假定不会产生非法的地址映射（也即在只有 4Mb 的机器上设置出大于 4Mb 的内存地址）。

注意！尽管所有的物理地址都应该由这个子程序进行恒等映射，但只有内核页面管理函数能直接使用>1Mb 的地址。所有“普通”函数仅使用低于 1Mb 的地址空间，或者是使用局部数据空间，该地址空间将被映射到其他一些地方去 -- mm（内存管理程序）会管理这些事的。

对于那些有多于 8Mb 内存的家伙 – 真是太幸运了，我还没有，为什么你会有。代码就在这里，对它进行修改吧。（实际上，这并不太困难的。通常只需修改一些常数等。我把它设置6.4 head.s 程序为 8Mb，因为我的机器再怎么扩充甚至不能超过这个界限（当然，我的机器是很便宜的）。我已经通过设置某类标志来给出需要改动的地方（搜索“ 16Mb” ） ，但我不能保证作这些改动就行了）。


上面英文注释第 2 段的含义是指在机器物理内存中大于 1MB 的内存空间主要被用于主内存区。 主内存区空间由 mm 模块管理。它涉及到页面映射操作。内核中所有其他函数就是这里指的一般（普通）函数。若要使用主内存区的页面，就需要使用 get_free_page()等函数获取。 因为主内存区中内存页面是共享资源，必须有程序进行统一管理以避免资源争用和竞争。

在内存物理地址 0x0 处开始存放 1 页页目录表和 4 页页表。页目录表是系统所有进程公用的，而这里的 4 页页表则属于内核专用，它们一一映射线性地址起始 16MB 空间范围到物理内存上。对于新建的进程，系统会在主内存区为其申请页面存放页表。另外， 1 页内存长度是 4096 字节。

*Fill the page directory, pg0 and pg1 with zeroes!!*

```asm
  movl $pg0+7,_pg_dir   /* set present bit/user r/w */
  movl $pg1+7,_pg_dir+4 /* --------- " " ---------- */
```

上面 2 句设置页目录表中的项。 因为我们（内核）共有 2 个页表， 所以只需设置 2 项。 页目录项的结构与页表中项的结构一样， 4 个字节为 1 项。参见上面 113 行下的说明。 例如"$pg0+7"表示： 0x00001007，是页目录表中的第 1 项。 则第 1 个页表所在的地址 = 0x00001007 & 0xfffff000 = 0x1000； 第 1 个页表的属性标志 = 0x00001007 & 0x00000fff = 0x07，表示该页存在、用户可读写。

*Fill the first two entries of the page directory with pointers to pg0 and pg1 and the necessary bits for paging (which again can be found from the manuals).*

```asm
   movl $pg1+4092,%edi  # edi -> 最后一页的最后一项
   movl $0x7ff007,%eax   /* 8Mb - 4096 + 7 (r/w user,p) */
   std       # 方向位置位， edi 值递减(4 字节)
1: stosl    /* fill pages backwards - more efficient :-) */
   subl $0x1000,%eax  # 每填写好一项，物理地址值减 0x1000
   jge 1b    # 如果小于 0 则说明全添写好了
```

上面填写 2 个页表中所有项的内容，共有： 2(页表)*1024(项/页表)=2048 项(0 - 0x7ff)，也即能映射物理内存 2048*4Kb = 8Mb。 每项的内容是：当前项所映射的物理内存地址 + 该页的标志（这里均为 7）。 填写使用的方法是从最后一个页表的最后一项开始按倒退顺序填写。 每一个页表中最后一项在表中的位置是 1023*4 = 4092。因此最后一页的最后一项的位置就是$pg1+4092。

*Now the page tables has to be filled with the physical address corresponding to the virtual address that the page table entry represents. For example, the value in the last entry of the second page table pg1 should represent the starting address of the “last” page in the physical memory whose starting address is 8Mb - 4096 (one page = 4096 bytes). Again, the second last entry of pg1 should be the starting address of the second last physical memory page = 8Mb - 4096 -4096. (4096 = 0x10000). Again, the necessary bits for paging purposes (7 = r/w user, p) are also added to the address - refer manuals.*


```asm
  xorl %eax,%eax   # pg_dir is at 0x0000
  movl %eax,%cr3   # cr3 - page directory start
  movl %cr0,%eax
  orl $0x80000000,%eax
  movl %eax,%cr0   # set paging (PG) bit
  ret      # this also flushes prefetch-queue
```

现在设置页目录表基址寄存器 cr3，指向页目录表。 cr3 中保存的是页目录表的物理地址， 然后再设置启动使用分页处理（ cr0 的 PG 标志，位 31）

在改变分页处理标志后要求使用转移指令刷新预取指令队列。 这里用的是返回指令 ret。 该返回指令的另一个作用是将 140 行压入堆栈中的 main 程序的地址弹出，并跳转到/init/main.c 程序去运行。本程序到此就真正结束了。

* Set the Kernel page directory to start at 0x0 and then turn on paging!

```asm
.align 2    # 按 4 字节方式对齐内存地址边界
  .word 0   # 这里先空出 2 字节，这样 224 行上的长字是 4 字节对齐的
idt_descr:
  .word 256*8-1      # idt contains 256 entries
  .long _idt
.align 2
  .word 0
gdt_descr:
  .word 256*8-1  # so does gdt (note that that’s any)
  .long _gdt     # magic number, but it works for me :^)

.align 3   # 按 8（2^3）字节方式对齐内存地址边界
_idt: .fill 256,8,0     # idt is uninitialized # 256 项，每项 8 字节，填 0。

_gdt:
  .quad 0x0000000000000000 /* NULL descriptor */
  .quad 0x00c09a00000007ff /* 8Mb */
  .quad 0x00c09200000007ff /* 8Mb */
  .quad 0x0000000000000000 /* TEMPORARY - don’t use */
  .fill 252,8,0    /* space for LDT’s and TSS’s etc */
```

`idt_descr` 是加载中断描述符表寄存器 idtr 的指令 lidt 要求的 6 字节操作数。前 2 字节是 idt 表的限长，后 4 字节是 idt 表在线性地址空间中的 32 位基地址。

`gdt_descr` 是加载全局描述符表寄存器 gdtr 的指令 lgdt 要求的 6 字节操作数。前 2 字节是 gdt 表的限长， 后 4 字节是 gdt 表的线性基地址。这里全局表长度设置为 2KB 字节（ 0x7ff 即可） ，因为每 8 字节组成一个描述符项，所以表中共可有 256 项。符号_gdt 是全局表在本程序中的偏移位置，见 234 行。

`_gdt` 是全局描述符表。 其前 4 项分别是： 空项（不用）、代码段描述符、数据段描述符、系统调用段描述符， 其中系统调用段描述符并没有派用处， Linus 当时可能曾想把系统调用代码放在这个独立的段中。 后面还预留了 252 项的空间，用于放置新创建任务的局部描述符(LDT)和对应的任务状态段 TSS 的描述符。

(0-nul, 1-cs, 2-ds, 3-syscall, 4-TSS0, 5-LDT0, 6-TSS1, 7-LDT1, 8-TSS2 etc...)

*The GDT has at present, just three entries. The NULL descriptor, the Code Segment and the Data Segment- these two segments are for use by the kernel and so it covers the entire address from 0x0 to 8Mb which is again directly mapped to the first 8Mb of phyisical memory by the kernel page tables.*
