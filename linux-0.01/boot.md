# boot.s

6.1. Step Wise Refinement Of The 0.01 Kernel - Step 3

So now we enter the real “Journey To The Center Of The Code”.We will try to proceed in
the same order as that given in the above section on description of files.We will take each
of those files and will explain in the “necessary” detail, each of the functions and pieces of
code present in those files. You can expect a very good coverage of all pieces of code except
the file system - our description on file system code will be very meager as we are not much
knowledged and interested in that.We would also advice that the reader keep a copy of the
Hardware Bible (or any equivalent) and the 386 manuals nearby when going through the code
because that will help more in increasing the grasp of the code :-) Again, since the code is
not a very huge one like Minix, what we will do is to place our commentary inline with the
code - so you can find code and commentary intermixed!

6.1.1. linux/boot

We will be giving quite a detailed explanation about the files in this directory.

6.1.1.1. linux/boot/boot.s

```
1 
2 | So here goes boot.s
3 | boot.s
4 |
5 | boot.s is loaded at 0x7c00 by the bios-startup
6 | routines, and moves itself
7 | out of the way to address 0x90000, and jumps there.
8
```
* By 0x7c00, we mean the “combined” value after CS:IP. Remember that the x86 is still in the real mode.We
don’t remember what the exact values for CS and IP will be (if there are exact values), which is immaterial
also. Now why does it move itself to 0x90000 ? Well, it cant load itself in the “lower” address regions (like
0x0?) because the BIOS might store some information like the ISR table in low memory and we need the
help of BIOS to get the actual kernel image (the image names “system” we get after compilation) loaded into
memory. Also, it has to be well out of the way of the actual kernel image that gets loaded at 0x10000 to be
sure that the kernel does not over write the boot loader. Also, it has to be remembered that the BIOS chip has
address range within the first Mega Byte. So refer the Hardware manual, find the address range of the BIOS
chip and make sure that all the addresses where the boot loader images and the kernel image is loaded do
not overlap with the BIOS. For this the size of each of the image has also to be considered - the boot loader
is fixed at 512 bytes, the kernel as Linus says in his comment below will not be more than 512Kb :-)))

```
1 
2 | It then loads the system at 0x10000, using BIOS interrupts. Thereafter
3
```

* Again, it needs to be taken care that till the “full” kernel is not in memory, the BIOS’s information should
not be wiped off. So temporarily load the image at 0x10000.

```
1
2 | it disables all interrupts, moves the system down to 0x0000, changes
3
```

* Now that the whole image is in memory, we no longer need BIOS. So we can load the image wherever we
want and so we choose location 0x0.

```
1 
2 | to protected mode, and calls the start of system. System then must
3 | RE-initialize the protected mode in it’s own tables, and enable
4 | interrupts as needed.
5
```

* After the whole kernel is in memory, we have to switch to protected mode - in 0.01, this is also done by the
bootloader boot.s. It need not be done by the bootloader, the kernel can also do it. But the boot loader should
not forget that it is a “boot loader” and not the kernel. So it should do just the right amount of job. So it
just uses some dummy IDT, GDT etc.. and uses that to switch into the protected mode and jump to the kernel
code. Now the kernel code can decide how to map its memory, how do design the GDT etc.. independently of
the boot loader. so even if the kernel changes, the boot loader can be the same.

```
1 
2 | NOTE! currently system is at most 8*65536 bytes long.
3 | This should be no | problem, even in the future.
4 | want to keep it simple. This 512 kB | kernel size
5 | should be enough - in fact more would mean we’d have to move
6 | not just these start-up routines, but also do something about the cache-
7 | memory (block IO devices). The area left over in the lower 640 kB is meant
8 | for these. No other memory is assumed to be "physical", ie all memory
9 | over 1Mb is demand-paging. All addresses under 1Mb are guaranteed to match
10 | their physical addresses.
11 |
12
```

* More about paging in the further sections. Anyway, the gist of what is written above is that the kernel code
is within the first One Mega Byte and the mapping for Kernel code is one to one - that is an address 0x4012
referred inside the kernel will get translated to 0x4012 itself by the paging mechanism and similarly for
all addresses. But for user processes,we have mentioned in the section on paging that address 0x3134 may
correspond to “physical” address 0x200000 .

```
1 
2 | NOTE1 abouve is no longer valid in it’s entirety. cache-memory is allocated
3 | above the 1Mb mark as well as below. Otherwise it is mainly correct.
4 |
5 | NOTE 2! The boot disk type must be set at compile-time, by setting
6 | the following equ. Having the boot-up procedure hunt for the right
7 | disk type is severe brain-damage.
8 | The loader has been made as simple as possible (had to, to get it
9 | in 512 bytes with the code to move to protected mode), and continuos
10 | read errors will result in a unbreakable loop. Reboot by hand. It
11 | loads pretty fast by getting whole sectors at a time whenever possible.
12
13 | 1.44Mb disks:
14 sectors = 18
15 | 1.2Mb disks:
16 | sectors = 15
17 | 720kB disks:
18 | sectors = 9
19
20 .globl begtext, begdata, begbss, endtext, enddata, endbss
21 .text
22 begtext:
23 .data
24 begdata:
25 .bss
26 begbss:
27 .text
28
29 BOOTSEG = 0x07c0
30 INITSEG = 0x9000
31 SYSSEG = 0x1000 | system loaded at 0x10000 (65536).
32 ENDSEG = SYSSEG + SYSSIZE
33
```

`entry start` marks the beginning of code bootsect.s. The first instruction starts here, which is the first byte on the floppy.

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

Line 36 to line 44 performs `rep movw` macroinstruction which copies memory from location `ds:si` to `es:di`, which is from 0x07C0:0x0000 to 0x9000:0x0000. `(e)cx` is the register storing the copy size (or counter) used by `rep`, which is decremented by `rep` after each microinstruction loop, till 0. #256 is word corresponding to `movw` (which is 512 bytes),. Ref of [`REP MOVE` string instruction](https://patents.justia.com/patent/7802078).

`jmpi` is an inter-segment jump instruction (段间跳转), used in x86 real mode. This instruction set `cs` (code段地址) to `INITSEG`, and `ip` to `go` (段内偏移地址), and then the instruction at address INITSEG:go will be executed.

从下面开始， CPU 在已移动到 0x90000:go 位置处的代码中执行

    Addressing in real mode is for compatibility with the 8086 processor, 8086 is a 16-bit CPU (the data width of the ALU), and the 20-bit address bus can address 1M of memory space. The addressing mode: segment base address + offset mode. The segment base address is stored in CS, DS, ES and other segment registers, which is equivalent to the upper 16 bits of addressing, and the offset is provided by the internal 16-bit bus. To the external address bus, the segment base address and offset are combined into a 20-bit address to address the 1M physical address space.

    Synthesis method: the segment base address is shifted left by 4 bits, and then the offset address is added. But it is not a general addition. Because the base address of the previous segment has been shifted left by 4 bits to 20 bits (the lowest 4 bits are 0), and the offset is still 16 bits, so it is actually the segment base address and offset The upper 12 bits of the sum are added, and the lower 4 bits of the offset are unchanged. For example:
    
    0x8880:0x0440 = 0x88800 + 0x0440 = 0x88c40 (20-bit address of external bus)

    It can be seen that this so-called segmented memory management is not a pure base address plus offset method. It is said that Intel deceived everyone at the time.

```asm
go: 
  mov ax,cs
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov sp,#0x400
```

以上代码设置几个段寄存器，包括栈寄存器 ss 和 sp。注意段寄存器只能通过通用寄存器复制，所以需要`mov ax,cs`。栈指针 sp 只要指向远大于 512 字节偏移（即地址 0x90200） 处都可以。

```asm
8 mov ah,#0x03 | read cursor pos
9 xor bh,bh
10 int 0x10
11
12 mov cx,#24
13 mov bx,#0x0007 | page 0, attribute 7 (normal)
14 mov bp,#msg1
15 mov ax,#0x1301 | write string, move cursor
16 int 0x10
17
18 | ok, we’ve written the message, now
19 | we want to load the system (at 0x10000)
20
```

* Just to print a boot up message on the screen

```
1 
2 
3 mov ax,#SYSSEG
4 mov es,ax | segment of 0x010000
5 call read_it
6 call kill_motor
7 
8
```

* Here is where we read the kernel image from the floppy disk and load it to 0x10000. The routine read_it will be explained later.

```
1 
2 | if the read went well we get current cursor position ans save it for
3 | posterity.
4 
5 mov ah,#0x03 | read cursor pos
6 xor bh,bh
7 int 0x10 | save it in known place, con_init fetches
8 mov [510],dx | it from 0x90510.
9
10 | now we want to move to protected mode ...
11
12 cli | no interrupts allowed !
13
14 | first we move the system to it’s rightful place
15
16 mov ax,#0x0000
17 cld | ’direction’=0, movs moves forward
18 do_move:
19 mov es,ax | destination segment
20 add ax,#0x1000
21 cmp ax,#0x9000
22 jz end_move
23 mov ds,ax | source segment
24 sub di,di
25 sub si,si
26 mov cx,#0x8000
27 rep
28 movsw
29 j do_move
30
31
```

* Finally, we copy the kernel from 0x10000 to 0x0!!

```
1 
2 | then we load the segment descriptors
3 
4 end_move:
5 
6 mov ax,cs | right, forgot this at first. didn’t work :-)
7 mov ds,ax
8 lidt idt_48 | load idt with 0,0
9 lgdt gdt_48 | load gdt with whatever appropriate
10
11
```

* Prepare ourselves to switch to the protected mode. For this, GDT and IDT has to be initialized. We have a
dummy IDT and GDT called idt_48 and gdt_48 respectively which enables us to jump to the protected mode.

```
1 
2 | that was painless, now we enable A20
3 
4 call empty_8042
5 mov al,#0xD1 | command write
6 out #0x64,al
7 call empty_8042
8 mov al,#0xDF | A20 on
9 out #0x60,al
10 call empty_8042
11
12
```

* Refer to the hardware Manual about this A20 (Address Line 20) line controlled by the Keyboard controller.
Actually, the A20 line is used in real mode in 32 bit systems to get access to more memory even when in
real mode - the key board controller can be made to drive this Address Line 20 high in order to access more
memory above the 1Mb limit. But then why not ask the keyboard controller to introduce an A21, A22 etc... :-)
so that we can go on accessing the entire 4Gb memory range even when in real mode ? Well, we don’t have
any answer to this as of now (We will add something here if we get to know the answer later). But remember
that this A20 extension will allow the “extra” memory to be accessed only as data and not as an executable
memory area because it is NOT the processor who is driving the A20 line, but it is the keyboard controller
who has to be programmed via I/O registers to drive the A20.

```
1 2
| well, that went ok, I hope. Now we have to reprogram the interrupts :-(
3 | we put them right after the intel-reserved hardware interrupts, at
4 | int 0x20-0x2F. There they won’t mess up anything. Sadly IBM really
5 | messed this up with the original PC, and they haven’t been able to
6 | rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f,
7 | which is used for the internal hardware interrupts as well. We just
8 | have to reprogram the 8259’s, and it isn’t fun.
9
10 mov al,#0x11 | initialization sequence
11 out #0x20,al | send it to 8259A-1
12 .word 0x00eb,0x00eb | jmp $+2, jmp $+2
13 out #0xA0,al | and to 8259A-2
14 .word 0x00eb,0x00eb
15 mov al,#0x20 | start of hardware int’s (0x20)
16 out #0x21,al
17 .word 0x00eb,0x00eb
18 mov al,#0x28 | start of hardware int’s 2 (0x28)
19 out #0xA1,al
20 .word 0x00eb,0x00eb
21 mov al,#0x04 | 8259-1 is master
22 out #0x21,al
23 .word 0x00eb,0x00eb
24 mov al,#0x02 | 8259-2 is slave
25 out #0xA1,al
26 .word 0x00eb,0x00eb
27 mov al,#0x01 | 8086 mode for both
43Chapter 6. Journey to the Center of the Code
28 out #0x21,al
29 .word 0x00eb,0x00eb
30 out #0xA1,al
31 .word 0x00eb,0x00eb
32 mov al,#0xFF | mask off all interrupts for now
33 out #0x21,al
34 .word 0x00eb,0x00eb
35 out #0xA1,al
36
37 | well, that certainly wasn’t fun :-(. Hopefully it works, and we don’t
38 | need no steenking BIOS anyway (except for the initial loading :-).
39 | The BIOS-routine wants lots of unnecessary data, and it’s less
40 | "interesting" anyway. This is how REAL programmers do it.
41 |
42
```

* Well, we know that the IBM PC series uses the Intel 8259 interrupt controller which can handle upto 8 (or
15 in cascaded mode) interrupts with varios forms of priority etc. On getting an interrupt from 8259, the x86
identifies the source of the interrupt be reading a value from one of the registers of 8259. If that value is say
xy, then the x86 issues a software interrupt “int xy” to execute the ISR for that interrupt source. Again in the
32 bite x86 series, the first 32 software interrupts are “reserved” by Intel for uses like excepetions such as
divide by zero (not very sure, refer the Intel manual). So we program the 8259 with values starting from 0x20
(ie 32) corresponding to interrupt line 0 on the 8259.

```
1 2
| Well, now’s the time to actually move into protected mode. To make
3 | things as simple as possible, we do no register set-up or anything,
4 | we let the gnu-compiled 32-bit programs do that. We just jump to
5 | absolute address 0x00000, in 32-bit protected mode.
6 
7 mov ax,#0x0001 | protected mode (PE) bit
8 lmsw ax | This is it!
9 jmpi 0,8 | jmp offset 0 of segment 8 (cs)
10
11
```

* And finally, we move to protected mode by setting the bit 0 of the concerned register (name we forgot!!) using
the lmsw instruction. Also, the Intel manual states that the transition to protected mode will be complete only
with a jump instruction following that! So we jump to offset 0 in Code Segment number 8 which has been set
to start from absolute physical address 0x0 (again, note that all this code is part of the boot loader and so is
running from 0x90000). Now what does this mean ? What is the code at 0x0 ? It is the 0.01 Kernel Code!!!!!
So we finally start executing the kernel code and we never come back to the bootloader code unless we do a
reset and the kernel has to be loaded again :-(

```
1 2
| This routine checks that the keyboard command queue is empty
3 | No timeout is used - if this hangs there is something wrong with
4 | the machine, and we probably couldn’t proceed anyway.
5 empty_8042:
6 .word 0x00eb,0x00eb
7 in al,#0x64 | 8042 status port
8 test al,#2 | is input buffer full?
9 jnz empty_8042 | yes - loop
10 ret
11
44Chapter 6. Journey to the Center of the Code
12 | This routine loads the system at address 0x10000, making sure
13 | no 64kB boundaries are crossed. We try to load it as fast as
14 | possible, loading whole tracks whenever we can.
15 |
16 | in: es - starting address segment (normally 0x1000)
17 |
18 | This routine has to be recompiled to fit another drive type,
19 | just change the "sectors" variable at the start of the file
20 | (originally 18, for a 1.44Mb drive)
21 |
22
```

* This particular piece of code below seems to appear complicated to many - so let us give a pseudo language
description of the control transfer that happens below. /* We copy the kernel using es:[bx] indexing mode.
We start with es = 0x0 and bx = 0x0, we go on incrementing bx till bx = 0xffff. Then we add 0x1000 es and
again make bx = 0x0. Now, why do we add 0x1000 to es ? - we know that the x86 addressing is es * 4 + bx.
Now bx has already used all the four bits (0xffff). So to avoid overlap of address (and thus overwriting the
code/data), we need to ensure that es * 4 has always the lower four bits as zero. Now if the number is 0x?000,
then number * 4 is always 0x?0000. */ es = 0x0; bx = 0x0; sread = 1; /* We have already read the first sector
which is the bootloader */ head = track = 0; /* We have two heads */ /* Assume we are reading from track
number “track”, head number “head” and that we have already read “sread” sectors on this track. Also
assume that the last segment that we will need to use (depending on the size of the image) is ENDSEG. We
will explain how to calculate this later */ die: some error occured while reading from the floppy, loop here for
ever !! rp_read: if (es = ENDSEG) we have loaded the full kernel into memory, return to the point where
we were called ok1_read: Calculate the number of sectors that can be read into the remaining area in the
current segment (es). ok2_read: Now call read_track which will use the BIOS routines to load the requested
number of sectors into es:[bx]. if (all the sectors in the current track has NOT been loaded into memory)
goto ok3_readif (all the sectors in the current track has been loaded into memory) this means we have
read a full track. So find out which head needs to be used for the next read (head = 0 or 1). if (head is 1) then
we have to read the “other side” of the same track. Go to ok3_readelse if (head is 0) then we have to read
from the first head of the “next track”. Fall through to ok4_readok4_read: Increment the value of “track”
variable. ok3_read: Update the value of “sread” variable with the number of sectors read till now. if (there
is more space in the current segment) goto rp_readelse es = es + 0x1000; bx = 0x0; goto rp_readNow
one question is “even if there is space left in the current segment, ie bx 0xffff, what happens if the space
left in the current segment is not enough to hold one sector of data ?”. The answer is that such a situation
will not arise because the sector size is 512 bytes and the segment size is a multiple of 512. Now we will give
short comments in between where things are not clear.

```
1 2
sread: .word 1 | sectors read of current track
3 head: .word 0 | current head
4 track: .word 0 | current track
5 read_it:
6 mov ax,es
7 test ax,#0x0fff
8 die: jne die | es must be at 64kB boundary
9 xor bx,bx | bx is starting address within segment
10 rp_read:
11 mov ax,es
12 cmp ax,#ENDSEG | have we loaded all yet?
13 jb ok1_read
14 ret
15
```

* How do we find out ENDSEG ? Well, what we used to do was to compile an image with some value for
SYSSIZE (ENDSEG = SYSSEG + SYSSIZE) and after compilation, see what the size of the image is and
calculate SYSSIZE accordingly and recompile!! Well, this is possible because the compilation time is too
less. What would be done is to find out the location in the image where this SYSSIZE is used and just use
some small C program to overwrite that location with the value of the SYSSIZE calculated from the final
image.

```
1 
2 ok1_read:
3 mov ax,#sectors
4 sub ax,sread
5 mov cx,ax
6 shl cx,#9
7
```

* shl cx,#9 multiplies cx by 512 - the size of the sector.

```
1 2
add cx,bx
3 jnc ok2_read
4 je ok2_read
5 xor ax,ax
6 sub ax,bx
7
```

* We want to find how many bytes are “left” in the current segment. For this, what we should do is 0x10000 - bx which is effectively 0x0 - bx !!!

```
1 2
shr ax,#9
3
```

* Convert bytes to sectors

```
1 2
ok2_read:
3 call read_track
4 mov cx,ax
5 add ax,sread
6 cmp ax,#sectors
7 jne ok3_read
8 mov ax,#1
9 sub ax,head
10 jne ok4_read
11 inc track
12 ok4_read:
13 mov head,ax
14 xor ax,ax
15 ok3_read:
16 mov sread,ax
17 shl cx,#9
18 add bx,cx
19 jnc rp_read
20 mov ax,es
21 add ax,#0x1000
22 mov es,ax
23 xor bx,bx
24 jmp rp_read
25
26
```

* Rest of the code above can be directly mapped to what we have written in the pseudo code.

```
1 
2 read_track:
3 push ax
4 push bx
5 push cx
6 push dx
7 mov dx,track
8 mov cx,sread
9 inc cx
10 mov ch,dl
11 mov dx,head
12 mov dh,dl
13 mov dl,#0
14 and dx,#0x0100
15 mov ah,#2
16 int 0x13
17 jc bad_rt
18 pop dx
19 pop cx
20 pop bx
21 pop ax
22 ret
23 bad_rt: mov ax,#0
24 mov dx,#0
25 int 0x13
26 pop dx
27 pop cx
28 pop bx
29 pop ax
30 jmp read_track
31
32 /*
33 * This procedure turns off the floppy drive motor, so
34 * that we enter the kernel in a known state, and
35 * don’t have to worry about it later.
36 */
37 kill_motor:
38 push dx
39 mov dx,#0x3f2
40 mov al,#0
41 outb
42 pop dx
43 ret
44
45 gdt:
46 .word 0,0,0,0 | dummy
47
48 .word 0x07FF | 8Mb - limit=2047 (2048*4096=8Mb)
49 .word 0x0000 | base address=0
50 .word 0x9A00 | code read/exec
47Chapter 6. Journey to the Center of the Code
51 .word 0x00C0 | granularity=4096, 386
52
53 .word 0x07FF | 8Mb - limit=2047 (2048*4096=8Mb)
54 .word 0x0000 | base address=0
55 .word 0x9200 | data read/write
56 .word 0x00C0 | granularity=4096, 386
57
58
```

* This is the “dummy” gdts that we were speaking about. This just maps the lower 8Mb of addresses to the
lower 8Mb of physical memory (by setting base address = 0x0 and limit = 8Mb). We create two gdt entries
one for code segment and one for data segment as we can find from the read/exec and read/write attributes.
The code segment is entry number 1 (assuming to start from 0), but with the first few extra bits in the segment
descriptor for indicating priority level etc.., the code segment will be actually 8 when it gets loaded into cs.
Again, refer to the intel manual to find out how exactly the entry number 1 becomes 8 when loaded into cs.
Similarly, you can find out what will be the value of a segment descriptor for the data segment, the data
segment entry being number 2. The exact layout of the hex values can be understood only by reading the Intel manuals.

```
1 2
idt_48:
3 .word 0 | idt limit=0
4 .word 0,0 | idt base=0L
5 6
```

* We believe the interrupts are disabled as of now and so we don’t need a proper IDT. That explains all
the zeroes in idt_48 above. The values in idt_48 are loaded into the register pointing to the IDT using lidt
instruction. Again, what each of those zeroes mean will have to be understood by going through the Intel Manual.

```
1 2
gdt_48:
3 .word 0x800 | gdt limit=2048, 256 GDT entries
4 .word gdt,0x9 | gdt base = 0X9xxxx
5 6
```

* This is for presenting all gdt related info in the fashion expected by the lgdt instruction.

```
1 2
msg1:
3 .byte 13,10
4 .ascii "Loading system ..."
5 .byte 13,10,13,10
6 7
```

* Modify the above to print your own message :0)

```
1 2
.text
3 endtext:
4 .data
5 enddata:
6 .bss
7 endbss:
8
```

6.1.1.2. linux/boot/head.s

Now let us look into head.s. This file contains code for three main items before the kernel can
start functioning as a fully multitasking one. The GDT, IDT and paging has to be initialized.
So here goes...

```
1 2
/*
3 * head.s contains the 32-bit startup code.
4 *
5 * NOTE!!! Startup happens at absolute address 0x00000000, which is also wher
6 * the page directory will exist. The startup code will be overwritten by
7 * the page directory.
8 */
9
```

* We jump to startup_32 from boot.s. The comment says that the “startup” code will be overwritten by the
page tables - what does that mean ? The code below to setup the GDT and IDT are not needed after the setup
is done. So after that code is executed, four pages of memory starting from 0x0 are used for paging purposes
as page directory and page tables. That is what we mean by “overwriting” the code.

```
1 2
.text
3 .globl _idt,_gdt,_pg_dir
4 _pg_dir:
5 startup_32:
6 movl $0x10,%eax
7 mov %ax,%ds
8 mov %ax,%es
9 mov %ax,%fs
10 mov %ax,%gs
11
```

* Till this point, we are relying on the GDT which was setup in boot.s (direct memory mapping). 0x10 is the
Data Segment.

```
1 2
lss _stack_start,%esp
3
```

* We will need stacks for function calls. So we setup the ess and esp using values from the structure stack_start
which is declared in kernel/sched.c. Again, the format of the structure will be understood only by looking into
the intel manual and seeing what is the format of the argument for lss and what lss does!

```
1 2
call setup_idt
3 call setup_gdt
4
```

* Now setup IDT and GDT according to the preferences of the kernel.

```
1 2
movl $0x10,%eax # reload all the segment registers
3 mov %ax,%ds # after changing gdt. CS was already
4 mov %ax,%es # reloaded in ’setup_gdt’
5 mov %ax,%fs
6 mov %ax,%gs
7 lss _stack_start,%esp
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
