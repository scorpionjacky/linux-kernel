# Bran's kernel development tutorial

## TOC

- [Introduction](#Introduction)
- [Getting Started](#getting-started)
- [The basic kernel](#the-basic-kernel)
- [Linking sources](#linking)
- [Printing onscreen](#screen)
- [The GDT](#the-gdt)
- [The IDT](#the-idt)
- [Writing ISRs](#isr)
- [IRQs and the PICs](#irqs-and-pics)
- [The PIT](#pit)
- [The Keyboard](#the-keyboard)
- [What's left?](#left)

## Introduction

<p>
Kernel development is not an easy task. This is a testament to your programming
expertise: To develop a kernel is to say that you understand how to create
software that interfaces with and manages the hardware. A kernel is designed to
be a central core to the operating system - the logic that manages the resources
that the hardware has to offer.
</p>

<p id="cputime">
One of the most important system resources that you need to manage is the
processor or CPU - this is in the form of allotting time for specific operations,
and possibly interrupting a task or process when it is time for another scheduled
event to happen. This implies multitasking. There is cooperative multitasking, in
which the program itself calls a 'yield' function when it wants to give up
processing time to the next runnable process or task. There is preemptive
multitasking, where the system timer is used to interrupt the current process to
switch to a new process: a form of forcive switch, this more guarantees that a
process can be given a chunk of time to run. There are several scheduling
algorithms used in order to find out what process will be run next. The simplest
of which is called 'Round Robin'. This is where you simply get the next process in
the list, and choose that to be runnable. A more complicated scheduler involves
'priorities', where certain higher-priority tasks are allowed more time to run
than a lower-priority task. Even more complicated still is a Real-time scheduler.
This is designed to guarantee that a certain process will be allowed at least a
set number of timer ticks to run. Ultimately, this number one resource calculates
to time.
</p>

<p id="memory">
The next most important resource in the system is fairly obvious: Memory. There
are some times where memory can be more precious than CPU time, as memory is
limited, however CPU time is not. You can either code your kernel to be memory-
efficient, yet require alot of CPU, or CPU efficient by using memory to store
caches and buffers to 'remember' commonly used items instead of looking them up.
The best approach would be a combination of the two: Strive for the best memory
usage, while preserving CPU time.
</p>

<p id="hardware">
The last resource that your kernel needs to manage are hardware resources. This
includes Interrupt Requests (IRQs), which are special signals that hardware
devices like the keyboard and hard disk can use to tell the CPU to execute a
certain routine to handle the data that these devices have ready. Another
hardware resource is Direct Memory Access (DMA) channels. A DMA channel allows a
device to lock the memory bus and transfer it's data directly into system memory
whenever it needs to, without halting the processor's execution. This is a good
way to improve performance on a system: a DMA-enabled device can transfer data
without bothering the CPU, and then can interrupt the CPU with an IRQ, telling it
that the data transfer is complete: Soundcards and ethernet cards are known for
using both IRQs and DMA channels. The third hardware resource is in the form of
an address, like memory, but it's an address on the I/O bus in the form of a
port. A device can be configured, read, or given data using it's I/O port(s). A
Device can use many I/O ports, typically in the form of ranges like ports 8
through 16, for example.
</p>

<h3>Overview</h3>

<p id="overview">
This tutorial was created in an attempt to show you, the reader, how to set up
the basics for a kernel. This involves:<br>
1)  Setting up your development environment<br>
2)  The basics: Setting the stage for GRUB<br>
3)  Linking in other files and calling main()<br>
4)  Printing to the screen<br>
5)  Setting up a custom Global Descriptor Table (GDT)<br>
6)  Setting up a custom Interrupt Descriptor Table (IDT)<br>
7)  Setting up Interrupt Service Routines (ISRs) to handle your Interrupts and IRQs<br>
8)  Remapping the Programmable Interrupt Controllers (PICs) to new IDT entries<br>
9)  Installing and servicing IRQs<br>
10) Managing the Programmable Interval Timer / System Clock (PIT)<br>
11) Managing Keyboard IRQs and Keyboard Data<br>
12) ...and the rest is up to you!<br>
</p>


## Getting Started

<p>
Kernel development is a lengthy process of writing code, as well as debugging various
system components. This may seem to be a rather daunting task at first, however you
don't nessarily require a massive toolset to write your own kernel. This kernel
development tutorial deals mainly with using the Grand Unified Bootloader (GRUB) to
load your kernel into memory. GRUB needs to be directed to a protected mode binary
image: this 'image' is our kernel, which we will be building.
</p>

<p>
For this tutorial, you will need at the very least, a general knowledge of the C
programming language. X86 Assembler knowledge is highly recommended and beneficial as
it will allow you to manipulate specific registers inside your processor. This being
said, your toolset will need at the bare minimum, a C compiler that can generate
32-bit code, a 32-bit Linker, and an Assembler which is able to generate 32-bit x86
output.
</p>

<p>
For hardware, you must have a computer with a 386 or later processor (this includes
386, 486, 5x86, 6x86, Pentium, Athlon, Celeron, Duron, and such). It is preferable
that you have a secondary computer set up to be your testbed, right beside your
development machine. If you cannot afford a second computer, or simply do not have
the room for a second computer on your desk, you may either use a Virtual Machine
suite, or you may also use your development machine as the testbed (although this
leads to slower development time). Be prepared for many sudden reboots as you test
and debug your kernel on real hardware.
</p>

### Required Hardware for Testbed

<p>
- a 100% IBM Compatible PC with:<br>
- a 386-based processor or later (486 or later recommended)<br>
- 4MBytes of RAM<br>
- a VGA compatible video card with monitor<br>
- a Keyboard<br>
- a Floppy Drive<br>
(Yes, that's right! You don't even NEED a hard disk on the testbed!)
</p>

### Recommended Hardware for Development
<p>
- a 100% IBM Compatible PC with:<br>
- a Pentium II or K6 300MHz<br>
- 32MBytes of RAM<br>
- a VGA compatible videocard with monitor<br>
- a Keyboard<br>
- a Floppy drive<br>
- a Hard disk with enough space for all development tools and space for documents and source code<br>
- Microsoft Windows, or a flavour of Unix (Linux, FreeBSD)<br>
- an Internet connection to look up documents<br>
(A mouse is highly recommended)
</p>

### Toolset

**Compilers**
<p>
- The Gnu C Compiler (GCC) [Unix]<br>
- DJGPP (GCC for DOS/Windows) [Windows]<br>
</p>

**Assemblers**
<p>
- Netwide Assembler (NASM) [Unix/Windows]<br>
</p>

**Virtual Machines**

<p>
- VMWare Workstation 4.0.5 [Linux/Windows NT/2000/XP]<br>
- Microsoft VirtualPC [Windows NT/2000/XP]<br>
- Bochs [Unix/Windows]<br>
</p>

## The Basic Kernel

<p>
In this section of the tutorial, we will delve into a bit of assembler, learn
the basics of creating a linker script as well as the reasons for using one, and
finally, we will learn how to use a batch file to automate the assembling,
compiling, and linking of this most basic protected mode kernel. Please note that
at this point, the tutorial assumes that you have NASM and DJGPP installed on a
Windows or DOS-based platform. We also assume that you have a a minimal
understanding of the x86 Assembly language.
</p>

### The Kernel Entry

<p>
The kernel's entry point is the piece of code that will be executed FIRST when
the bootloader calls your kernel. This chunk of code is almost always written in
assembly language because some things, such as setting a new stack or loading
up a new GDT, IDT, or segment registers, are things that you simply cannot do in
your C code. In many beginner kernels as well as several other larger, more
professional kernels, will put all of their assembler code in this one file, and
put all the rest of the sources in several C source files.
</p>

<p>
If you know even a small amount of assembler, the actual code in this file should
be very straight forward. As far as code goes, all this file does is load up a new
8KByte stack, and then jump into an infinite loop. The stack is a small amount of
memory, but it's used to store or pass arguments to functions in C. It's also used
to hold local variables that you declare and use inside your functions. Any other
global variables are stored in the data and BSS sections. The lines between the
'mboot' and 'stublet' blocks make up a special signature that GRUB uses to verify
that the output binary that it's going to load is, infact, a kernel. Don't struggle
too hard to understand the multiboot header.
</p>

<pre class="code">
; This is the kernel's entry point. We could either call main here,
; or we can use this to setup the stack or other nice stuff, like
; perhaps setting up the GDT and segments. Please note that interrupts
; are disabled at this point: More on interrupts later!
[BITS 32]
global start
start:
    mov esp, _sys_stack     ; This points the stack to our new stack area
    jmp stublet

; This part MUST be 4byte aligned, so we solve that issue using 'ALIGN 4'
ALIGN 4
mboot:
    ; Multiboot macros to make a few lines later more readable
    MULTIBOOT_PAGE_ALIGN	equ 1<<0
    MULTIBOOT_MEMORY_INFO	equ 1<<1
    MULTIBOOT_AOUT_KLUDGE	equ 1<<16
    MULTIBOOT_HEADER_MAGIC	equ 0x1BADB002
    MULTIBOOT_HEADER_FLAGS	equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO | MULTIBOOT_AOUT_KLUDGE
    MULTIBOOT_CHECKSUM	equ -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)
    EXTERN code, bss, end

    ; This is the GRUB Multiboot header. A boot signature
    dd MULTIBOOT_HEADER_MAGIC
    dd MULTIBOOT_HEADER_FLAGS
    dd MULTIBOOT_CHECKSUM
    
    ; AOUT kludge - must be physical addresses. Make a note of these:
    ; The linker script fills in the data for these ones!
    dd mboot
    dd code
    dd bss
    dd end
    dd start

; This is an endless loop here. Make a note of this: Later on, we
; will insert an 'extern _main', followed by 'call _main', right
; before the 'jmp $'.
stublet:
    jmp $


; Shortly we will add code for loading the GDT right here!


; In just a few pages in this tutorial, we will add our Interrupt
; Service Routines (ISRs) right here!



; Here is the definition of our BSS section. Right now, we'll use
; it just to store the stack. Remember that a stack actually grows
; downwards, so we declare the size of the data before declaring
; the identifier '_sys_stack'
SECTION .bss
    resb 8192               ; This reserves 8KBytes of memory here
_sys_stack:

</pre>
<pre class="codecaption">The kernel's entry file: 'start.asm'</pre>

<h3 id="linkerscript">The Linker Script</h3>

<p>
The Linker is the tool that takes all of our compiler and assembler output files
and links them together into one binary file. A binary file can have several
formats: Flat, AOUT, COFF, PE, and ELF are the most common. The linker we have
chosen in our toolset, if you can remember, was the LD linker. This is a very good
multi-purpose linker with an extensive feature set. There are versions of LD that
exist which can output a binary in any format that you wish. Regardless of what
format you choose, there will always be 3 'sections' in the output file. 'Text'
or 'Code' is the executable itself. The 'Data' section is for hardcoded values in
your code, such as when you declare a variable and set it to 5. The value of 5
would get stored in the 'Data' section. The last section is called the 'BSS'
section. The 'BSS' consists of uninitialized data; it stores any arrays that you
have not set any values to, for example. 'BSS' is a virtual section: It doesn't
exist in the binary image, but it exists in memory when your binary is loaded.
</p>

<p>
What follows is a file called an LD Linker Script. There are 3 major keywords
that might pop out in this linker script: OUTPUT_FORMAT will tell LD what kind
of binary image we want to create. To keep it simple, we will stick to a plain
"binary" image. ENTRY will tell the linker what object file is to be linked as
the very first file in the list. We want the compiled version of 'start.asm'
called 'start.o' to be the first object file linked, because that's where our
kernel's entry point is. The next line is 'phys'. This is not a keyword, but a
variable to be used in the linker script. In this case, we use it as a pointer
to an address in memory: a pointer to 1MByte, which is where our binary is to
be loaded to and run at. The 3rd keyword is SECTIONS. If you study this linker
script, you will see that if defines the 3 main sections: '.text', '.data',
and '.bss'. There are 3 variables defined also: 'code', 'data', 'bss', and 'end'.
Do not get confused by this: the 3 variables that you see are actually variables
that are in our startup file, start.asm. ALIGN(4096) ensures that each section
starts on a 4096byte boundary. In this case, that means that each section will
start on a separate 'page' in memory.
</p>

<pre class="code">
OUTPUT_FORMAT("binary")
ENTRY(start)
phys = 0x00100000;
SECTIONS
{
  .text phys : AT(phys) {
    code = .;
    *(.text)
    *(.rodata)
    . = ALIGN(4096);
  }
  .data : AT(phys + (data - code))
  {
    data = .;
    *(.data)
    . = ALIGN(4096);
  }
  .bss : AT(phys + (bss - code))
  {
    bss = .;
    *(.bss)
    . = ALIGN(4096);
  }
  end = .;
}</pre><pre class="codecaption">The Linker Script: 'link.ld'</pre>

<h3 id="build">Assemble and Link!</h3>
<p>
Now, we must assemble 'start.asm' as well as use the linker script, 'link.ld' shown
above, to create our kernel's binary for GRUB to load. The simplest way to do this
in Unix is to create a makefile script to do the assembling, compiling, and linking
for you, however, most of the people here including myself, use a flavour of Windows.
Here, we can create a batch file. A batch file is simply a collection of DOS commands
that you can execute with one command: the name of the batch file itself. Even
simpler: you just need to double-click the batch file in order to compile your kernel
under windows.
</p>

<p>
Shown below is the batch file we will use for this tutorial. 'echo' is a DOS command
that will say the following text on the screen. 'nasm' is our assembler that we use:
we compile in aout format, because LD needs a known format in order to resolve symbols
in the link process. This assembles the file 'start.asm' into 'start.o'. The 'rem'
command means 'remark'. This is a comment: it's in the batch file, but it doesn't
actually mean anything to the computer. 'ld' is our linker. The '-T' argument tells LD
that a linker script follows. '-o' means the output file follows. Any other arguments
are understood as files that we need to link together and resolve in order to create
kernel.bin. Lastly, the 'pause' command will display "Press a key to continue..." on
the screen and wait for us to press a key so that we can see what our assembler or
linker gives out onscreen in terms of syntax errors.
</p>

<pre class="code">
echo Now assembling, compiling, and linking your kernel:
nasm -f aout -o start.o start.asm
rem Remember this spot here: We will add 'gcc' commands here to compile C sources

rem This links all your files. Remember that as you add *.o files, you need to
rem add them after start.o. If you don't add them at all, they won't be in your kernel!
ld -T link.ld -o kernel.bin start.o
echo Done!
pause
</pre>
<pre class="codecaption">Our builder batch file: 'build.bat'</pre>

<a id="linking"></a>
## Creating Main and Linking C Sources

<p>
In normal C programming practice, the function main() is your normal program entry
point. In order to try to keep your normal programming practices and familiarize
yourself with kernel development, this tutorial will keep the main() function the
entry point for your C code. As you remember in the previous section of this
tutorial, we tried to keep minimal assembler code. In later sections, we will have
to go back into 'start.asm' in order to add Interrupt Service Routines to call C
functions.
</p>

<p>
In this section of the tutorial, we will attempt to create a 'main.c' as well as a
header file to include some common function prototypes: 'system.h'. 'main.c' will
also contain the function main() which will serve as your C entry point. As a rule
in kernel development, we should not normally return from main(). Many Operating
Systems get main to initialize the kernel and subsystems, load the shell application,
and then finally main() will sit in an idle loop. The idle loop is used in a
multitasking system when there are no other tasks that need to be run. Here is an
example 'main.c' with the basic main, as well as the function bodies for functions
that we will need in the next part of the tutorial.
</p>

<pre class="code">
#include &lt system.h &gt

/* You will need to code these up yourself!  */
unsigned char *memcpy(unsigned char *dest, const unsigned char *src, int count)
{
    /* Add code here to copy 'count' bytes of data from 'src' to
    *  'dest', finally return 'dest' */
}

unsigned char *memset(unsigned char *dest, unsigned char val, int count)
{
    /* Add code here to set 'count' bytes in 'dest' to 'val'.
    *  Again, return 'dest' */
}

unsigned short *memsetw(unsigned short *dest, unsigned short val, int count)
{
    /* Same as above, but this time, we're working with a 16-bit
    *  'val' and dest pointer. Your code can be an exact copy of
    *  the above, provided that your local variables if any, are
    *  unsigned short */
}

int strlen(const char *str)
{
    /* This loops through character array 'str', returning how
    *  many characters it needs to check before it finds a 0.
    *  In simple words, it returns the length in bytes of a string */
}

/* We will use this later on for reading from the I/O ports to get data
*  from devices such as the keyboard. We are using what is called
*  'inline assembly' in these routines to actually do the work */
unsigned char inportb (unsigned short _port)
{
    unsigned char rv;
    __asm__ __volatile__ ("inb %1, %0" : "=a" (rv) : "dN" (_port));
    return rv;
}

/* We will use this to write to I/O ports to send bytes to devices. This
*  will be used in the next tutorial for changing the textmode cursor
*  position. Again, we use some inline assembly for the stuff that simply
*  cannot be done in C */
void outportb (unsigned short _port, unsigned char _data)
{
    __asm__ __volatile__ ("outb %1, %0" : : "dN" (_port), "a" (_data));
}

/* This is a very simple main() function. All it does is sit in an
*  infinite loop. This will be like our 'idle' loop */
void main()
{
    /* You would add commands after here */

    /* ...and leave this loop in. There is an endless loop in
    *  'start.asm' also, if you accidentally delete this next line */
    for (;;);
}
</pre>
<pre class="codecaption">'main.c': Our kernel's small, yet important beginnings</pre>

<p>
Before compiling this, we need to add 2 lines into 'start.asm'. We need to let NASM
know that main() is in an 'external' file and we need to call main() from the
assembly file, also. Open 'start.asm', and look for the line that says 'stublet:'.
Immediately after that line, add the lines:
</p>

<pre class="code">
extern _main
call _main</pre>

<p>
Now wait just a minute. Why are there leading underscores for '_main', when in C,
we declared it as 'main'? The compiler gcc will put an underscore in front of all
of the function and variable names when it compiles. Therefore, to reference a
function or variable from our assembly code, we must add an underscore to the
function name if the function is in a C source file!.
</p>

<p>
This is actually good enough to compile 'as is', however we are still missing our
'system.h'. Simply create a blank text file named 'system.h'. Add all the function
prototypes for memcpy, memset, memsetw, strlen, inportb, and outportb to this file.
It is wise to use macros to prevent an include file, or 'header' file from
declaring things more than once using some nice #ifndef, #define, and #endif
tricks. We will include this file in each C source file in this tutorial. This will
define each function that you can use in your kernel. Feel free to expand upon this
library with anything you think you will need. Observe:
</p>

<pre class="code">
#ifndef __SYSTEM_H
#define __SYSTEM_H

/* MAIN.C */
extern unsigned char *memcpy(unsigned char *dest, const unsigned char *src, int count);
extern unsigned char *memset(unsigned char *dest, unsigned char val, int count);
extern unsigned short *memsetw(unsigned short *dest, unsigned short val, int count);
extern int strlen(const char *str);
extern unsigned char inportb (unsigned short _port);
extern void outportb (unsigned short _port, unsigned char _data);

#endif
</pre>
<pre class="codecaption">Our global include file: 'system.h'</pre>

<p>
Next, we need to find out how to compile this. Open your 'build.bat' from the previous
section in this tutorial, and add the following line to compile your 'main.c'. Please
note that this assumes that 'system.h' is in an 'include' directory in your kernel
sources directory. This command executes the compiler 'gcc'. Among the various arguments
passed in, there is '-Wall' which gives you warnings about your code. '-nostdinc' along
with '-fno-builtin' means that we aren't using standard C library functions. '-I./include'
tells the compiler that our headers are in the 'include' directory inside the current.
'-c' tells gcc to compile only: No linking yet! Remembering from the previous section in
this tutorial, '-o main.o' is the output file that the compiler is to make, with the last
argument, 'main.c'. In short, compile 'main.c' into 'main.o' with options best for kernels.
</p>

<img src="tip.png">Right click the batch file and select 'edit' to edit it!

<pre class="code">
gcc -Wall -O -fstrength-reduce -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o main.o main.c
</pre>
<pre class="codecaption">Add this line to 'build.bat'</pre>

<p>
Don't forget to follow the instructions we left in 'build.bat'! You need to add 'main.o'
to the list of object files that need to be linked to create your kernel! Finally, if
you are stuck creating our accessory functions like memcpy, a solution 'main.c' is
shown <a href="../Sources/main.c">here</a>.
</p>

<a id='screen'></a>
## Printing to the Screen

<p>
Now, we will try to print to the screen. In order to print to the screen, we need a
way to manage scrolling the screen as needed, also. It might be nice to allow for
different colors on the screen as well. Fortunately, a VGA video card makes it
rather simple: It gives us a chunk of memory that we write both attribute byte and
character byte pairs in order to show information on the screen. The VGA controller
will take care of automatically drawing the updated changes on the screen.
Scrolling is managed by our kernel software. This is technically our first driver,
that we will write right now.
</p>

<p>
As mentioned, above, the text memory is simply a chunk of memory in our address
space. This buffer is located at 0xB8000, in physical memory. The buffer is of the
datatype 'short', meaning that each item in this text memory array takes up 16-bits,
rather than the usual 8-bits that you might expect. Each 16-bit element in the text
memory buffer can be broken into an 'upper' 8-bits and a 'lower' 8-bits. The lower
8 bits of each element tells the display controller what character to draw on the
screen. The upper 8-bits is used to define the foreground and background colors of
which to draw the character.
</p>

<table>
<tr>
<td>
<table cols="50,50,50,50,100,100">
<tr>
<td width="50" align="left">
15
</td>
<td width="50" align="right">
12
</td>
<td width="50" align="left">
11
</td>
<td width="50" align="right">
8
</td>
<td width="100" align="left">
7
</td>
<td width="100" align="right">
0
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table cols="100, 100, 200" border="1" bordercolor="#808080">
<tr>
<td width="100" align="center">
Backcolor
</td>
<td width="100" align="center">
Forecolor
</td>
<td width="200" align="center">
Character
</td>
</tr>
</table>
</td>
</tr>
</table>

<p>
The upper 8-bits of each 16-bit text element is called an 'attribute byte', and the
lower 8-bits is called the 'character byte'. As you can see from the above table,
mapping out the parts of each 16-bit text element, the attribute byte gets broken
up further into 2 different 4-bit chunks: 1 representing background color and 1
representing foreground color. Now, because of the fact that only 4-bits define
each color, there can only be a maximum of 16 different colors to choose from (Using
the equation (num bits ^ 2) - 4^2 = 16). Below is a table of the default 16-color
palette.
</p>

<table cols="50, 200, 50, 200">
<tr>
<th align="left" width="50">Value</th>
<th align="left" width="200">Color</th>
<th align="left" width="50">Value</th>
<th align="left" width="200">Color</th>
</tr>
<tr>
<td width="50">
0
</td>
<td width="200">
<font color="black">BLACK</font>
</td>
<td width="50">
8
</td>
<td width="200">
<font color="#444444">DARK GREY</font>
</td>
</tr>
<tr>
<td width="50">
1
</td>
<td width="200">
<font color="#0000FF">BLUE</font>
</td>
<td width="50">
9
</td>
<td width="200">
<font color="#3399FF">LIGHT BLUE</font>
</td>
</tr>
<tr>
<td width="50">
2
</td>
<td width="200">
<font color="#00FF00">GREEN</font>
</td>
<td width="50">
10
</td>
<td width="200">
<font color="#99FF66">LIGHT GREEN</font>
</td>
</tr>
<tr>
<td width="50">
3
</td>
<td width="200">
<font color="#00FFFF">CYAN</font>
</td>
<td width="50">
11
</td>
<td width="200">
<font color="#CCFFFF">LIGHT CYAN</font>
</td>
</tr>
<tr>
<td width="50">
4
</td>
<td width="200">
<font color="#FF0000">RED</font>
</td>
<td width="50">
12
</td>
<td width="200">
<font color="#FF6600">LIGHT RED</font>
</td>
</tr>
<tr>
<td width="50">
5
</td>
<td width="200">
<font color="#CC0099">MAGENTA</font>
</td>
<td width="50">
13
</td>
<td width="200">
<font color="#FF66FF">LIGHT MAGENTA</font>
</td>
</tr>
<tr>
<td width="50">
6
</td>
<td width="200">
<font color="#663300">BROWN</font>
</td>
<td width="50">
14
</td>
<td width="200">
<font color="#CC6600">LIGHT BROWN</font>
</td>
</tr>
<tr>
<td width="50">
7
</td>
<td width="200">
<font color="#CCCCCC">LIGHT GREY</font>
</td>
<td width="50">
15
</td>
<td width="200">
<font color="white">WHITE</font>
</td>
</tr>

</table>

<p>
Finally, to access a particular index in memory, there is an equation that we must use.
The text mode memory is a simple 'linear' (or flat) area of memory, but the  video
controller makes it appear to be an 80x25 matrix of 16-bit values. Each line of text
is sequential in memory; they follow eachother. We therefore try to break up the screen
into horizontal lines. The best way to do this is to use the following equation:<br><br>
index = (y_value * width_of_screen) + x_value;<br><br>
This equation shows that to access the index in the text memory array for say (3, 4),
we would use the equation to find that 4 * 80 + 3 is 323. This means that to draw to
location (3, 4) on the screen, we need to write to do something similar to this:<br><br>
unsigned short *where = (unsigned short *)0xB8000 + 323;<br>
*where = character | (attribute << 8);
</p>

<p>
Following now is 'scrn.c', which is where all of our functions dealing with the screen
will be. We include our 'system.h' file so that we can use outportb, memcpy, memset,
memsetw, and strlen. The scrolling method that we use is rather interesting: We take
a chunk of text memory starting at line 1 (NOT line 0), and copy it over top of line 0.
This basically moves the entire screen up one line. To complete the scroll, we erase
the last line of text by writing spaces with our attribute bytes. The putch function
is possibly the most complicated function in this file. It is also the largest, because
it needs to handle any newlines ('\n'), carriage returns ('\r'), and backspaces ('\b').
Later, if you wish, you may handle the alarm character ('\a' - ASCII character 7),
which is only supposed to do a short beep when it is encountered. I have included a
function to set the screen colors also (settextcolor) if you wish.
</p>

<pre class="code">
#include &lt system.h &gt

/* These define our textpointer, our background and foreground
*  colors (attributes), and x and y cursor coordinates */
unsigned short *textmemptr;
int attrib = 0x0F;
int csr_x = 0, csr_y = 0;

/* Scrolls the screen */
void scroll(void)
{
    unsigned blank, temp;

    /* A blank is defined as a space... we need to give it
    *  backcolor too */
    blank = 0x20 | (attrib << 8);

    /* Row 25 is the end, this means we need to scroll up */
    if(csr_y >= 25)
    {
        /* Move the current text chunk that makes up the screen
        *  back in the buffer by a line */
        temp = csr_y - 25 + 1;
        memcpy (textmemptr, textmemptr + temp * 80, (25 - temp) * 80 * 2);

        /* Finally, we set the chunk of memory that occupies
        *  the last line of text to our 'blank' character */
        memsetw (textmemptr + (25 - temp) * 80, blank, 80);
        csr_y = 25 - 1;
    }
}

/* Updates the hardware cursor: the little blinking line
*  on the screen under the last character pressed! */
void move_csr(void)
{
    unsigned temp;

    /* The equation for finding the index in a linear
    *  chunk of memory can be represented by:
    *  Index = [(y * width) + x] */
    temp = csr_y * 80 + csr_x;

    /* This sends a command to indicies 14 and 15 in the
    *  CRT Control Register of the VGA controller. These
    *  are the high and low bytes of the index that show
    *  where the hardware cursor is to be 'blinking'. To
    *  learn more, you should look up some VGA specific
    *  programming documents. A great start to graphics:
    *  http://www.brackeen.com/home/vga */
    outportb(0x3D4, 14);
    outportb(0x3D5, temp >> 8);
    outportb(0x3D4, 15);
    outportb(0x3D5, temp);
}

/* Clears the screen */
void cls()
{
    unsigned blank;
    int i;

    /* Again, we need the 'short' that will be used to
    *  represent a space with color */
    blank = 0x20 | (attrib << 8);

    /* Sets the entire screen to spaces in our current
    *  color */
    for(i = 0; i < 25; i++)
        memsetw (textmemptr + i * 80, blank, 80);

    /* Update out virtual cursor, and then move the
    *  hardware cursor */
    csr_x = 0;
    csr_y = 0;
    move_csr();
}

/* Puts a single character on the screen */
void putch(unsigned char c)
{
    unsigned short *where;
    unsigned att = attrib << 8;

    /* Handle a backspace, by moving the cursor back one space */
    if(c == 0x08)
    {
        if(csr_x != 0) csr_x--;
    }
    /* Handles a tab by incrementing the cursor's x, but only
    *  to a point that will make it divisible by 8 */
    else if(c == 0x09)
    {
        csr_x = (csr_x + 8) & ~(8 - 1);
    }
    /* Handles a 'Carriage Return', which simply brings the
    *  cursor back to the margin */
    else if(c == '\r')
    {
        csr_x = 0;
    }
    /* We handle our newlines the way DOS and the BIOS do: we
    *  treat it as if a 'CR' was also there, so we bring the
    *  cursor to the margin and we increment the 'y' value */
    else if(c == '\n')
    {
        csr_x = 0;
        csr_y++;
    }
    /* Any character greater than and including a space, is a
    *  printable character. The equation for finding the index
    *  in a linear chunk of memory can be represented by:
    *  Index = [(y * width) + x] */
    else if(c >= ' ')
    {
        where = textmemptr + (csr_y * 80 + csr_x);
        *where = c | att;	/* Character AND attributes: color */
        csr_x++;
    }

    /* If the cursor has reached the edge of the screen's width, we
    *  insert a new line in there */
    if(csr_x >= 80)
    {
        csr_x = 0;
        csr_y++;
    }

    /* Scroll the screen if needed, and finally move the cursor */
    scroll();
    move_csr();
}

/* Uses the above routine to output a string... */
void puts(unsigned char *text)
{
    int i;

    for (i = 0; i < strlen(text); i++)
    {
        putch(text[i]);
    }
}

/* Sets the forecolor and backcolor that we will use */
void settextcolor(unsigned char forecolor, unsigned char backcolor)
{
    /* Top 4 bytes are the background, bottom 4 bytes
    *  are the foreground color */
    attrib = (backcolor << 4) | (forecolor & 0x0F)
}

/* Sets our text-mode VGA pointer, then clears the screen for us */
void init_video(void)
{
    textmemptr = (unsigned short *)0xB8000;
    cls();
}
</pre>
<pre class="codecaption">Printing to the screen: 'scrn.c'</pre>

<p>
Next, we need to compile this into our kernel. To do that, you need to edit
'build.bat' in order to add a new gcc compile command. Simply copy the command in
'build.bat' that corresponds to 'main.c' and paste it right afterwards. In our newly
pasted line, change 'main' to 'scrn'. Again, don't forget to add 'scrn.o' to the
list of files that LD needs to link! Before we can use these in main, you must add
the function prototypes for putch, puts, cls, init_video, and settextcolor into
'system.h'. Don't forget the 'extern' keyword and the semicolons as these are each
function prototypes:
</p>

<pre class="code">
extern void cls();
extern void putch(unsigned char c);
extern void puts(unsigned char *str);
extern void settextcolor(unsigned char forecolor, unsigned char backcolor);
extern void init_video();
</pre>
<pre class="codecaption">Add these to 'system.h' so we can call these from 'main.c'</pre>

<p>
Now, it's safe to use our new screen printing functions in out main function. Open
'main.c' and add a line that calls init_video(), and finally a line that calls puts,
passing it a string: puts("Hello World!"); Finally, save all your changes, double
click 'build.bat' to make your kernel, debugging any syntax errors. Copy your
'kernel.bin' to your GRUB floppy disk, and if all went well, you should now have a
kernel that prints 'Hello World!' on a black screen in white text!
</p>

