# boot/boot.s

`boot.s` is loaded at 0x7c00 by the bios-startup routines. It first moves itself out of the way to address 0x90000, and jumps there. It then loads the system at 0x10000, using BIOS interrupts. Thereafter it disables all interrupts, moves the system down to 0x0000, changes to protected mode, and calls the start of system. System then must RE-initialize the protected mode in its own tables, and enable interrupts as needed.


*By 0x7c00, we mean the “combined” value after CS:IP. Remember that the x86 is still in the real mode. We don’t remember what the exact values for CS and IP will be (if there are exact values), which is immaterial also. Now why does it move itself to 0x90000? Well, it cant load itself in the “lower” address regions (like 0x0?) because the BIOS might store some information like the ISR table in low memory and we need the help of BIOS to get the actual kernel image (the image names “system” we get after compilation) loaded into memory. Also, it has to be well out of the way of the actual kernel image that gets loaded at 0x10000 to be sure that the kernel does not overwrite the boot loader. Also, it has to be remembered that the BIOS chip has address range within the first Mega Byte. So refer the Hardware manual, find the address range of the BIOS chip and make sure that all the addresses where the boot loader images and the kernel image is loaded do not overlap with the BIOS. For this the size of each of the image has also to be considered - the boot loader is fixed at 512 bytes, the kernel as Linus says in his comment below will not be more than 512Kb :-)))*


*Why 0x10000? Again, it needs to be taken care that till the “full” kernel is not in memory, the BIOS’s information should not be wiped off. So temporarily load the image at 0x10000.*

*Now why 0x0? Now that the whole image is in memory, we no longer need BIOS. So we can load the image wherever we want and so we choose location 0x0.*

*After the whole kernel is in memory, we have to switch to protected mode - in 0.01, this is also done by the bootloader boot.s. It need not be done by the bootloader, the kernel could also do it. But the boot loader should not forget that it is a “boot loader” and not the kernel. So it should do just the right amount of job. So it just uses some dummy IDT, GDT etc.. and uses that to switch into the protected mode and jump to the kernel code. Now the kernel code can decide how to map its memory, how do design the GDT etc.. independently of the boot loader. so even if the kernel changes, the boot loader can be the same.*

NOTE! currently system is at most 8 * 65536 bytes long. This should be no problem, even in the future. want to keep it simple. This 512 kB kernel size should be enough - in fact more would mean we’d have to move not just these start-up routines, but also do something about the cache- memory (block IO devices). The area left over in the lower 640 kB is meant for these. No other memory is assumed to be "physical", ie all memory over 1Mb is demand-paging. All addresses under 1Mb are guaranteed to match their physical addresses.

*More about paging in the further sections. Anyway, the gist of what is written above is that the kernel code is within the first One Mega Byte and the mapping for Kernel code is one to one - that is an address 0x4012 referred inside the kernel will get translated to 0x4012 itself by the paging mechanism and similarly for all addresses. But for user processes, we have mentioned in the section on paging that address 0x3134 may correspond to “physical” address 0x200000.*

NOTE 1: The above is no longer valid in its entirety. cache-memory is allocated above the 1Mb mark as well as below. Otherwise it is mainly correct.

NOTE 2: The boot disk type must be set at compile-time, by setting the following equ. Having the boot-up procedure hunt for the right disk type is severe brain-damage. The loader has been made as simple as possible (had to, to get it in 512 bytes with the code to move to protected mode), and continuos read errors will result in a unbreakable loop. Reboot by hand. It loads pretty fast by getting whole sectors at a time whenever possible.

```asm
; 1.44Mb disks:
  sectors = 18
; 1.2Mb disks:
; sectors = 15
; 720kB disks:
; sectors = 9

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

BOOTSEG = 0x07c0
INITSEG = 0x9000
SYSSEG  = 0x1000      ; system loaded at 0x10000 (65536)
ENDSEG  = SYSSEG + SYSSIZE
```

`entry start` marks the beginning of code of bootsect.s. The first instruction starts here, which is the first byte on the floppy.

```asm
entry start
start:
  mov ax,#BOOTSEG
  mov ds,ax
  mov ax,#INITSEG
  mov es,ax
  mov cx,#256
  sub si,si
  sub di,di
  rep
  movw
  jmpi go,INITSEG
```

The bootloader copies “itself”, 512 bytes, from 0x07C0 (BOOTSEG) to 0x90000 (INITSEG), aka copies itself from `ds:si` to `es:di` `(e)cs` times (512 bytes).

`rep movw` macroinstruction copies memory from location `ds:si` to `es:di`, which is from 0x07C0:0x0000 to 0x9000:0x0000. `(e)cx` is the register storing the copy size (or counter) used by `rep`, which is decremented by `rep` after each microinstruction loop, till 0. #256 is word corresponding to `movw` (which is 512 bytes),. Ref of [`REP MOVE` string instruction](https://patents.justia.com/patent/7802078).

`jmpi` is an inter-segment jump instruction (段间跳转), used in x86 real mode. This instruction set `cs` (code段地址) to `INITSEG`, and `ip` to `go` (段内偏移地址), and then the instruction at address INITSEG:go will be executed.

从下面开始， CPU 在已移动到 0x90000:go 位置处的代码中执行

> Addressing in real mode is for compatibility with the 8086 processor, 8086 is a 16-bit CPU (the data width of the ALU), and the 20-bit address bus can address 1M of memory space. The addressing mode: segment base address + offset mode. The segment base address is stored in CS, DS, ES and other segment registers, which is equivalent to the upper 16 bits of addressing, and the offset is provided by the internal 16-bit bus. To the external address bus, the segment base address and offset are combined into a 20-bit address to address the 1M physical address space.
> 
> Synthesis method: the segment base address is shifted left by 4 bits, and then the offset address is added. But it is not a general addition. Because the base address of the previous segment has been shifted left by 4 bits to 20 bits (the lowest 4 bits are 0), and the offset is still 16 bits, so it is actually the segment base address and offset The upper 12 bits of the sum are added, and the lower 4 bits of the offset are unchanged. For example:
> 
> 0x8880:0x0440 = 0x88800 + 0x0440 = 0x88c40 (20-bit address of external bus)
> 
> It can be seen that this so-called segmented memory management is not a pure base address plus offset method. It is said that Intel deceived everyone at the time.
> 
>> **The addressing problem of 8086/8088**
>>
>> Both 8088 and 80286 are 16-bit CPUs. Why did Intel warn IBM and Gates? In the end what happened?
>>
>> To understand what happened, we have to look at the inside of the processor and we will see huge differences. First, you find a piece of 8088 CPU, grind the packaging, grind it to the CPU silicon wafer, put it under the microscope, you will see the internal structure of 8086/88, it is not a new design at all, but two 8085 running in parallel (8 bits) There are a little more microprocessors.
>>
>> Each 8085 has its own 8-bit data and 16-bit addressing capabilities. Combining two 8-bit data registers to pretend to be a 16-bit register is easy. In fact, there is nothing new. The RCA COSMAC microprocessor uses 16 8-bit registers, which can be used as internal 8-bit or 16-bit registers. You can have up to 16 8-bit registers or 8 16-bit registers or Any combination of the two. Now, a common IC factory in China can be easily designed.
>>
>> Probably due to the limitation of the production process at that time, the 8088 can only have 40 feet. Intel's design "elite" left and right thought, determined 20 address lines (1M addressing space), and 16 data lines have to be 20. There are 16 multiplexes in the address line (time-sharing multiplex, that is, one will be the address line and the other will be the data line. For this, you can read the timing part of the 8088 chip manual, or read the 8052 microcontroller books, Its address lines and data lines are also multiplexed).
>>
>> To the essence of the problem, the two 8085 in 8088 each have a set of 16-bit addressing registers, how to let them address 20-bit 1M address? In fact, it is very simple to put them together to form 32-bit addressing. If that is the case, then many of the troubles may be gone (such as A20 door), but those elites at that time may think that 32-bit addressing (4G address space) Is it nonsense, it is estimated that the earth disappeared and not use so much memory? Besides, the boss is too tight, so they use two 8085 on a piece of hardware to achieve a very good method-segmentation:
>>
>> They divided the 1024K address space into 16-byte segments, a total of 64K segments, using a 16-bit addressing register of 8085 as the address offset register (so the length of the segment is 64K), and another 16-bit addressing register of 8085 As a segment address register for a 16-byte segment, note that he does not store the address of the 16-byte segment, but the serial number of the 16-byte segment (0, 1, ... 65535).
>>
>> The advantage of this is that as long as a shifter and a 20-bit adder are added between two 8085 CPUs, 20-bit address addressing can be completed-a 8085 address register (segment address-is 16 bytes) The number of the segment) is shifted by 4 bits to the left (* 16 = the first address of the 16-byte segment), plus another address register of 8085, haha! You can pay the boss, the production cost is low, the design speed is fast, and if you have money, don't grab it is a grandson! As for the future, . . .
>>
>> - [段寄存器”的故事[转]（彻底搞清内存段/elf段/实模式保护模式以及段寄存器）](https://www.cnblogs.com/johnnyflute/p/3564894.html) or [Here](https://www.jianshu.com/p/d83bf4aa2262)
>> - [Linux内存寻址之分段机制](https://www.jianshu.com/p/e899de3ccafe)
>> - [linux内存管理---虚拟地址、逻辑地址、线性地址、物理地址的区别（一）](https://blog.csdn.net/yusiguyuan/article/details/9664887)
>> - [Intel 64架构5级分页和5级EPT白皮书](https://www.jianshu.com/p/8d19b485617e)

Below 代码设置几个段寄存器，包括栈寄存器 ss 和 sp。注意段寄存器只能通过通用寄存器复制，所以需要`mov ax,cs`。栈指针 sp 只要指向远大于 512 字节偏移（即地址 0x90200） 处都可以。

```asm
go: 
  mov ax,cs
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov sp,#0x400
```

Now print a boot up message on the screen ...

```asm
  mov ah,#0x03 ; read cursor pos
  xor bh,bh
  int 0x10

  mov cx,#24
  mov bx,#0x0007 ; page 0, attribute 7 (normal)
  mov bp,#msg1
  mov ax,#0x1301 ; write string, move cursor
  int 0x10
```

The instructions below read the kernel image from the floppy disk and load it to 0x10000 (64KB). `es` 存放 system 的段地址。 `read_it` 读磁盘上 system 模块， `es` 为输入参数。 `kill_motor` 关闭驱动器马达，这样就可以知道驱动器的状态了。The routine `read_it` and `kill_motor` will be explained later.

```asm
  mov ax,#SYSSEG  ; 0x1000
  mov es,ax       ; segment of 0x010000
  call read_it
  call kill_motor
```


If the read went well we get current cursor position and save it for posterity. The BIOS interrupt get current cursor position to `dx`, and we save it to 0x9000:510. Later con_init fetches from this location.

```asm
  mov ah,#0x03
  xor bh,bh
  int 0x10
  mov [510],dx
```

Now we want to move to protected mode... First, diable interrups (`cli`). Then move the system to it’s rightful place.

*`cld` (Clear Direction Flag) clears the DF flag in the EFLAGS register. When the DF flag is set to 0, string operations increment the index registers (ESI and/or EDI).*

bootsect 引导程序会把 system 模块读入到内存 0x10000（ 64KB） 开始的位置。由于当时假设 system 模块最大长度不会超过 0x80000（ 512KB） ，即其末端不会超过内存地址 0x90000，所以 bootsect 会把自己移动到 0x90000 开始的地方，并把 setup 加载到它的后面。下面这段程序的用途是再把整个 system 模块移动到 0x00000 位置，即把从 0x10000 到 0x8ffff 的内存数据块（ 512KB）整块地向内存低端移动了 0x10000（ 64KB） 字节。

`es:di` 是目的地址(初始为 0x0:0x0), `ds:si` 是源地址(初始为 0x1000:0x0), `cx` 移动 0x8000 字（ 64KB 字节）。

```asm
  cli

  mov ax,#0x0000
  cld   ; ’direction’=0, movs moves forward
do_move:
  mov es,ax  ; destination segment
  add ax,#0x1000
  cmp ax,#0x9000
  jz end_move
  mov ds,ax  ; source segment
  sub di,di
  sub si,si
  mov cx,#0x8000
  rep
  movsw
  j do_move
end_move:
```

Finally, we copied the kernel from 0x10000 to 0x0!!

Let's prepare ourselves to switch to the protected mode. For this, GDT and IDT has to be initialized. We have a dummy IDT and GDT called idt_48 and gdt_48 respectively which enables us to jump to the protected mode.

We'll first load the segment descriptors ...

```asm
  mov ax,cs   ; right, forgot this at first. didn’t work :-)
  mov ds,ax
  lidt idt_48 ; load idt with 0,0
  lgdt gdt_48 ; load gdt with whatever appropriate
```

Now we enable A20. 

为了能够访问和使用 1MB 以上的物理内存，我们需要首先开启 A20 地址线。参见本程序列表后有关 A20 信号线的说明。关于所涉及的一些端口和命令，可参考 kernel/chr_drv/keyboard.S 程序后对键盘接口的说明。至于机器是否真正开启了 A20 地址线，我们还需要在进入保护模式之后（能访问 1MB 以上内存之后）在测试一下。这个工作放在了 head.S 程序中（ 32--36 行）。

`call empty_8042` 测试 8042 状态寄存器，等待输入缓冲器空。 只有当输入缓冲器为空时才可以对其执行写命令。

```asm
  call empty_8042
  mov al,#0xD1      ; 0xD1 命令码-表示要写数据到8042 的 P2 端口。
  out #0x64,al      ; P2 端口位 1 用于 A20 线的选通。
  call empty_8042   ; 等待输入缓冲器空，看命令是否被接受。
  mov al,#0xDF      ; A20 on! 选通 A20 地址线的参数。
  out #0x60,al      ; 数据要写到 0x60 口。
  call empty_8042   ; 若此时输入缓冲器为空，则表示 A20 线已经选通。
```

* Refer to the hardware Manual about this A20 (Address Line 20) line controlled by the Keyboard controller.
Actually, the A20 line is used in real mode in 32 bit systems to get access to more memory even when in
real mode - the keyboard controller can be made to drive this Address Line 20 high in order to access more
memory above the 1Mb limit. But then why not ask the keyboard controller to introduce an A21, A22 etc... :-)
so that we can go on accessing the entire 4Gb memory range even when in real mode? Well, we don’t have
any answer to this as of now (We will add something here if we get to know the answer later). But remember
that this A20 extension will allow the “extra” memory to be accessed only as data and not as an executable
memory area because it is NOT the processor who is driving the A20 line, but it is the keyboard controller
who has to be programmed via I/O registers to drive the A20.

Well, that went ok, I hope. Now we have to reprogram the interrupts :-(

We put them right after the intel-reserved hardware interrupts, at int 0x20-0x2F. There they won’t mess up anything. Sadly IBM really messed this up with the original PC, and they haven’t been able to rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f, which is used for the internal hardware interrupts as well. We just have to reprogram the 8259’s, and it isn’t fun.

希望以上一切正常。现在我们必须重新对中断进行编程 :-( 我们将它们放在正好处于 Intel 保留的硬件中断后面，即 int 0x20--0x2F。在那里它们不会引起冲突。 不幸的是 IBM 在原 PC 机中搞糟了，以后也没有纠正过来。 如此 PC 机 BIOS 把中断放在了 0x08--0x0f，这些中断也被用于内部硬件中断。所以我们就必须重新对 8259 中断控制器进行编程，这一点都没意思。

PC 机使用 2 个可编程中断控制器 8259A 芯片，关于 8259A 的编程方法请参见本程序后的介绍。 第 162 行上定义的两个字（ 0x00eb）是直接使用机器码表示的两条相对跳转指令，起延时作用。 0xeb 是直接近跳转指令的操作码，带 1 个字节的相对位移值。因此跳转范围是-127 到 127。 CPU 通过把这个相对位移值加到 EIP 寄存器中就形成一个新的有效地址。 执行时所花费的 CPU 时钟周期数是 7 至 10 个。 0x00eb 表示跳转位移值是 0 的一条指令，因此还是直接执行下一条指令。 这两条指令共可提供 14--20 个 CPU 时钟周期的延迟时间。 因为在 as86 中没有表示相应指令的助记符， 因此 Linus 在一些汇编程序中就直接使用机器码来表示这种指令。另外， 每个空操作指令 NOP 的时钟周期数是 3 个，因此若要达到相同的延迟效果就需要 6 至 7 个 NOP 指令。

8259 芯片主片端口是 0x20-0x21，从片端口是 0xA0-0xA1。输出值 0x11 表示初始化命令开始，它是 ICW1 命令字，表示边沿触发、多片 8259 级连、最后要发送 ICW4 命令字。

*Note: Linux 系统硬件中断号被设置成从 0x20 开始。参见表 3-2：硬件中断请求信号与中断号对应表。*

```asm
  mov al,#0x11   ; initialization sequence
  out #0x20,al   ; send it to 8259A-1 (8259A 主芯片)
  .word 0x00eb,0x00eb  | jmp $+2, jmp $+2 ! '$'表示当前指令的地址，
  out #0xA0,al   ; and to 8259A-2 (8259A 从芯片)
  .word 0x00eb,0x00eb
  mov al,#0x20   ; start of hardware int’s (0x20)
  out #0x21,al   ; 送主芯片 ICW2 命令字，设置起始中断号，要送奇端口。
  .word 0x00eb,0x00eb
  mov al,#0x28   ; start of hardware int’s 2 (0x28)
  out #0xA1,al   ; 送从芯片 ICW2 命令字，从芯片的起始中断号。
  .word 0x00eb,0x00eb
  mov al,#0x04   ; 8259-1 is master
  out #0x21,al   ; 送主芯片 ICW3 命令字，主芯片的 IR2 连从芯片 INT。 参见代码列表后的说明。
  .word 0x00eb,0x00eb
  mov al,#0x02   ; 8259-2 is slave
  out #0xA1,al   ; 送从芯片 ICW3 命令字，表示从芯片的 INT 连到主芯片的 IR2 引脚上。
  .word 0x00eb,0x00eb
  mov al,#0x01   ; 8086 mode for both
  out #0x21,al   ; 送主芯片 ICW4 命令字。 8086 模式；普通 EOI、非缓冲方式，需发送指令来复位。初始化结束，芯片就绪。
  .word 0x00eb,0x00eb
  out #0xA1,al   ; 送从芯片 ICW4 命令字，内容同上。
  .word 0x00eb,0x00eb
  mov al,#0xFF   ; mask off all interrupts for now
  out #0x21,al   ; 屏蔽主芯片所有中断请求。
  .word 0x00eb,0x00eb
  out #0xA1,al   ; 屏蔽从芯片所有中断请求。
```

Well, that certainly wasn’t fun :-(. Hopefully it works, and we don’t need no steenking BIOS anyway (except for the initial loading :-).

The BIOS-routine wants lots of unnecessary data, and it’s less "interesting" anyway. This is how REAL programmers do it.

Well, we know that the IBM PC series uses the Intel 8259 interrupt controller which can handle upto 8 (or 15 in cascaded mode) interrupts with varios forms of priority etc. On getting an interrupt from 8259, the x86 identifies the source of the interrupt be reading a value from one of the registers of 8259. If that value is say xy, then the x86 issues a software interrupt “int xy” to execute the ISR for that interrupt source. Again in the 32 bite x86 series, the first 32 software interrupts are “reserved” by Intel for uses like excepetions such as divide by zero (not very sure, refer the Intel manual). So we program the 8259 with values starting from 0x20 (ie 32) corresponding to interrupt line 0 on the 8259.

Well, now’s the time to actually move into protected mode. To make things as simple as possible, we do no register set-up or anything, we let the gnu-compiled 32-bit programs do that. We just jump to absolute address 0x00000, in 32-bit protected mode.

哼，上面这段编程当然没劲:-(，但希望这样能工作，而且我们也不再需要乏味的 BIOS 了（除了初始加载:-)。 BIOS 子程序要求很多不必要的数据，而且它一点都没趣。那是“真正”的程序员所做的事。

好了，现在是真正开始进入保护模式的时候了。为了把事情做得尽量简单，我们并不对寄存器内容进行任何设置。我们让 gnu 编译的 32 位程序去处理这些事。在进入 32 位保护模式时我们仅是简单地跳转到绝对地址 0x00000 处。

下面设置并进入 32 位保护模式运行。首先加载机器状态字(lmsw-Load Machine Status Word)，也称控制寄存器 CR0，其比特位 0 置 1 将导致 CPU 切换到保护模式，并且运行在特权级 0 中，即当前特权级 CPL=0。此时段寄存器仍然指向与实地址模式中相同的线性地址处（在实地址模式下线性地址与物理内存地址相同）。在设置该比特位后，随后一条指令必须是一条段间跳转指令以用于刷新 CPU 当前指令队列。因为 CPU 是在执行一条指令之前就已从内存读取该指令并对其进行解码。然而在进入保护模式以后那些属于实模式的预先取得的指令信息就变得不再有效。而一条段间跳转指令就会刷新 CPU 的当前指令队列，即丢弃这些无效信息。另外，在 Intel 公司的手册上建议 80386 或以上 CPU 应该使用指令“mov cr0,ax”切换到保护模式。 lmsw 指令仅用于兼容以前的 286 CPU。

```asm
  mov ax,#0x0001 ; protected mode (PE) bit
  lmsw ax        ; This is it!
  jmpi 0,8       ; jmp offset 0 of segment 8 (cs)
```

我们已经将 system 模块移动到 0x00000 开始的地方，所以上句中的偏移地址是 0。而段值 8 已经是保护模式下的段选择符了，用于选择描述符表和描述符表项以及所要求的特权级。段选择符长度为 16 位（ 2 字节）；位 0-1 表示请求的特权级 0--3，但 Linux 操作系统只用到两级： 0 级（内核级）和 3 级（用户级）；位 2 用于选择全局描述符表（ 0）还是局部描述符表(1)；位 3-15 是描述符表项的索引，指出选择第几项描述符。所以段选择符 8（ 0b0000,0000,0000,1000）表示请求特权级 0、使用全局描述符表 GDT 中第 2 个段描述符项，该项指出代码的基地址是 0（参见 571 行），因此这里的跳转指令就会去执行 system 中的代码。

And finally, we move to protected mode by setting the bit 0 of the concerned register (name we forgot!!) using the lmsw instruction. Also, the Intel manual states that the transition to protected mode will be complete only with a jump instruction following that! So we jump to offset 0 in Code Segment number 8 which has been set to start from absolute physical address 0x0 (again, note that all this code is part of the boot loader and so is running from 0x90000). Now what does this mean ? What is the code at 0x0 ? It is the 0.01 Kernel Code!!!!! So we finally start executing the kernel code and we never come back to the bootloader code unless we do a reset and the kernel has to be loaded again :-(

This routine below checks that the keyboard command queue is empty. No timeout is used - if this hangs there is something wrong with the machine, and we probably couldn’t proceed anyway.

下面这个子程序检查键盘命令队列是否为空。这里不使用超时方法 - 如果这里死机，则说明 PC 机有问题，我们就没有办法再处理下去了。 只有当输入缓冲器为空时（键盘控制器状态寄存器位 1 = 0）才可以对其执行写命令。

```asm
empty_8042:
  .word 0x00eb,0x00eb
  in al,#0x64    ; 8042 status port 读 AT 键盘控制器状态寄存器。
  test al,#2     ; is input buffer full? 测试位 1，输入缓冲器满？
  jnz empty_8042 ; yes - loop
  ret
```

This routine (`read_it`) loads the system at address 0x10000, making sure no 64kB boundaries are crossed. We try to load it as fast as possible, loading whole tracks whenever we can.

in:es - starting address segment (normally 0x1000)

This routine has to be recompiled to fit another drive type, just change the "sectors" variable at the start of the file (originally 18, for a 1.44Mb drive)

This particular piece of code below seems to appear complicated to many - so let us give a pseudo language description of the control transfer that happens below. 

We copy the kernel using es:[bx] indexing mode. We start with es = 0x0 and bx = 0x0, we go on incrementing bx till bx = 0xffff. Then we add 0x1000 es and again make bx = 0x0. Now, why do we add 0x1000 to es ? - we know that the x86 addressing is es * 4 + bx. Now bx has already used all the four bits (0xffff). So to avoid overlap of address (and thus overwriting the code/data), we need to ensure that es * 4 has always the lower four bits as zero. Now if the number is 0x?000, then number * 4 is always 0x?0000. 

`es = 0x0; bx = 0x0; sread = 1;` We have already read the first sector which is the bootloader.

`head = track = 0;` We have two heads.

Assume we are reading from track number “track”, head number “head” and that we have already read “sread” sectors on this track. Also assume that the last segment that we will need to use (depending on the size of the image) is ENDSEG. We will explain how to calculate this later

`die:` some error occured while reading from the floppy, loop here for ever !! 

`rp_read:` if (es = ENDSEG) we have loaded the full kernel into memory, return to the point where we were called ok1_read: Calculate the number of sectors that can be read into the remaining area in the current segment (es). 

`ok2_read:` Now call read_track which will use the BIOS routines to load the requested number of sectors into es:[bx]. if (all the sectors in the current track has NOT been loaded into memory) 

goto ok3_read if (all the sectors in the current track has been loaded into memory) this means we have read a full track. So find out which head needs to be used for the next read (head = 0 or 1). if (head is 1) then we have to read the “other side” of the same track. 

Go to ok3_read else if (head is 0) then we have to read from the first head of the “next track”. 

Fall through to ok4_readok4_read: Increment the value of “track” variable. ok3_read: Update the value of “sread” variable with the number of sectors read till now. if (there is more space in the current segment) 

goto rp_read else es = es + 0x1000; bx = 0x0; goto rp_readNow one question is “even if there is space left in the current segment, ie bx 0xffff, what happens if the space left in the current segment is not enough to hold one sector of data ?”. The answer is that such a situation will not arise because the sector size is 512 bytes and the segment size is a multiple of 512. Now we will give short comments in between where things are not clear.

```asm
sread: .word 1   ; sectors read of current track
head:  .word 0   ; current head
track: .word 0   ; current track

read_it:
  mov ax,es
  test ax,#0x0fff
die: 
  jne die        ; es must be at 64kB boundary
  xor bx,bx      ; bx is starting address within segment
rp_read:
  mov ax,es
  cmp ax,#ENDSEG ; have we loaded all yet?
  jb ok1_read
  ret
```

*How do we find out ENDSEG ? Well, what we used to do was to compile an image with some value for SYSSIZE (ENDSEG = SYSSEG + SYSSIZE) and after compilation, see what the size of the image is and calculate SYSSIZE accordingly and recompile!! Well, this is possible because the compilation time is too less. What would be done is to find out the location in the image where this SYSSIZE is used and just use some small C program to overwrite that location with the value of the SYSSIZE calculated from the final image.*

```asm
ok1_read:
  mov ax,#sectors
  sub ax,sread
  mov cx,ax
  shl cx,#9  ; multiplies cx by 512 - the size of the sector
  add cx,bx
  jnc ok2_read
  je ok2_read
  xor ax,ax
  sub ax,bx
  shr ax,#9
```

*We want to find how many bytes are “left” in the current segment. For this, what we should do is 0x10000 - bx which is effectively 0x0 - bx !!!*

*Convert bytes to sectors*

```asm
ok2_read:
  call read_track
  mov cx,ax
  add ax,sread
  cmp ax,#sectors
  jne ok3_read
  mov ax,#1
  sub ax,head
  jne ok4_read
  inc track
ok4_read:
  mov head,ax
  xor ax,ax
ok3_read:
  mov sread,ax
  shl cx,#9
  add bx,cx
  jnc rp_read
  mov ax,es
  add ax,#0x1000
  mov es,ax
  xor bx,bx
  jmp rp_read
```

*Rest of the code above can be directly mapped to what we have written in the pseudo code.*

```asm
read_track:
  push ax
  push bx
  push cx
  push dx
  mov dx,track
  mov cx,sread
  inc cx
  mov ch,dl
  mov dx,head
  mov dh,dl
  mov dl,#0
  and dx,#0x0100
  mov ah,#2
  int 0x13
  jc bad_rt
  pop dx
  pop cx
  pop bx
  pop ax
  ret
bad_rt: 
  mov ax,#0
  mov dx,#0
  int 0x13
  pop dx
  pop cx
  pop bx
  pop ax
  jmp read_track
```

*This procedure turns off the floppy drive motor, so that we enter the kernel in a known state, and don’t have to worry about it later.*

```asm
kill_motor:
  push dx
  mov dx,#0x3f2
  mov al,#0
  outb
  pop dx
  ret

gdt:
  .word 0,0,0,0 ; dummy

  .word 0x07FF ; 8Mb - limit=2047 (2048*4096=8Mb)
  .word 0x0000 ; base address=0
  .word 0x9A00 ; code read/exec
  .word 0x00C0 ; granularity=4096, 386

  .word 0x07FF ; 8Mb - limit=2047 (2048*4096=8Mb)
  .word 0x0000 ; base address=0
  .word 0x9200 ; data read/write
  .word 0x00C0 ; granularity=4096, 386
```

*This is the “dummy” gdts that we were speaking about. This just maps the lower 8Mb of addresses to the lower 8Mb of physical memory (by setting base address = 0x0 and limit = 8Mb). We create two gdt entries one for code segment and one for data segment as we can find from the read/exec and read/write attributes. The code segment is entry number 1 (assuming to start from 0), but with the first few extra bits in the segment descriptor for indicating priority level etc.., the code segment will be actually 8 when it gets loaded into cs. Again, refer to the intel manual to find out how exactly the entry number 1 becomes 8 when loaded into cs. Similarly, you can find out what will be the value of a segment descriptor for the data segment, the data segment entry being number 2. The exact layout of the hex values can be understood only by reading the Intel manuals.*

```asm
idt_48:
  .word 0    ; idt limit=0
  .word 0,0  ; idt base=0L
```

*We believe the interrupts are disabled as of now and so we don’t need a proper IDT. That explains all the zeroes in idt_48 above. The values in idt_48 are loaded into the register pointing to the IDT using lidt instruction. Again, what each of those zeroes mean will have to be understood by going through the Intel Manual.*

```asm
gdt_48:
  .word 0x800     ; gdt limit=2048, 256 GDT entries
  .word gdt,0x9   ; gdt base = 0X9xxxx
```

*This is for presenting all gdt related info in the fashion expected by the lgdt instruction.*

```asm
msg1:
  .byte 13,10
  .ascii "Loading system ..."
  .byte 13,10,13,10
```

*Modify the above to print your own message :0)*

```asm
.text
endtext:
.data
enddata:
.bss
endbss:
```
