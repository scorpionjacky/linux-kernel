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

## The GDT

<p>
A vital part of the 386's various protection measures is the Global Descriptor Table,
otherwise called a GDT. The GDT defines base access privileges for certain parts of
memory. We can use an entry in the GDT to generate segment violation exceptions that
give the kernel an opportunity to end a process that is doing something it shouldn't.
Most modern operating systems use a mode of memory called "Paging" to do this: It is
alot more versatile and allows for higher flexibility. The GDT can also define if a
section in memory is executable or if it is infact, data. The GDT is also capable of
defining what are called Task State Segments (TSSes). A TSS is used in hardware-based
multitasking, and is not discussed here. Please note that a TSS is not the only way
to enable multitasking.
</p>

<p>
Note that GRUB already installs a GDT for you, but if we overwrite the area of memory
that GRUB was loaded to, we will trash the GDT and this will cause what is called a
'triple fault'. In short, it'll reset the machine. What we should do to prevent that
problem is to set up our own GDT in a place in memory that we know and can access.
This involves building our own GDT, telling the processor where it is, and finally
loading the processor's CS, DS, ES, FS, and GS registers with our new entries. The CS
register is also known as the Code Segment. The Code Segment tells the processor
which offset into the GDT that it will find the access privileges in which to execute
the current code. The DS register is the same idea, but it's not for code, it's the
Data segment and defines the access privileges for the current data. ES, FS, and GS
are simply alternate DS registers, and are not important to us.
</p>

<p>
The GDT itself is a list of 64-bit long entries. These entries define where in memory
that the allowed region will start, as well as the limit of this region, and the
access privileges associated with this entry. One common rule is that the first entry
in your GDT, entry 0, is known as the NULL descriptor. No segment register should be
set to 0, otherwise this will cause a General Protection fault, and is a protection
feature of the processor. The General Protection Fault and several other types of
'exceptions' will be explained in detail under the section on <a href="isrs.htm">
Interrupt Service Routines (ISRs)</a>.
</p>

<p>
Each GDT entry also defines whether or not the current segment that the processor is
running in is for System use (Ring 0) or for Application use (Ring 3). There are
other ring types, but they are not important. Major operating systems today only use
Ring 0 and Ring 3. As a basic rule, any application causes an exception when it tries
to access system or Ring 0 data. This protection exists to prevent an application
from causing the kernel to crash. As far as the GDT is concerned, the ring levels
here tell the processor if it's allowed to execute special privileged instructions.
Certain instructions are privileged, meaning that they can only be run in higher ring
levels. Examples of this are 'cli' and 'sti' which disable and enable interrupts,
respectively. If an application were allowed to use the assembly instructions 'cli'
or 'sti', it could effectively stop your kernel from running. You will learn more
about interrupts in later sections of this tutorial.
</p>

<p>
Each GDT entry's Access and Granularity fields can be defined as follows:
</p>

<table>
<tr valign="top">
<td>
<table>
<tr>
<td>
<table cols="25, 25, 25, 25, 100">
<tr>
<td width="25" align="center">7</td>
<td width="25" align="left">6</td>
<td width="25" align="right">5</td>
<td width="25" align="center">4</td>
<td width="50" align="left">3</td>
<td width="50" align="right">0</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table border="1" bordercolor="#808080" cols="25, 50, 25, 100">
<tr>
<td width="25">
P
</td>
<td width="50">
DPL
</td>
<td width="25">
DT
</td>
<td width="100">
Type
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
P - Segment is present? (1 = Yes)<br>
DPL - Which Ring (0 to 3)<br>
DT - Descriptor Type<br>
Type - Which type?<br>
</td>
</tr>
</table>				
</td>

<td>
<table cols="20">
<tr>
    <td width="20"></td>
</tr>
</table>
</td>

<td>				
<table>
<tr>
<td>
<table cols="25, 25, 25, 35, 50, 50">
<tr>
<td width="25" align="center">7</td>
<td width="25" align="center">6</td>
<td width="25" align="center">5</td>
<td width="35" align="center">4</td>
<td width="50" align="left">3</td>
<td width="50" align="right">0</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table border="1" bordercolor="#808080" cols="25, 25, 25, 25, 100">
<tr>
<td width="25">
G
</td>
<td width="25">
D
</td>
<td width="25">
0
</td>
<td width="25">
A
</td>
<td width="100">
Seg Len. 19:16
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
G - Granularity (0 = 1byte, 1 = 4kbyte)<br>
D - Operand Size (0 = 16bit, 1 = 32-bit)<br>
0 - Always 0<br>
A - Available for System (Always set to 0) <br>
</td>
</tr>
</table>				
</td>
</tr>
</table>

<p>
In our tutorial kernel, we will create a GDT with only 3 entries. Why 3? We need one
'dummy' descriptor in the beginning to act as our NULL segment for the processor's
memory protection features. We need one entry for the Code Segment, and finally, we
need one entry for the Data Segment registers. To tell the processor where our new
GDT table is, we use the assembly opcode 'lgdt'. 'lgdt' needs to be given a pointer
to a special 48-bit structure. This special 48-bit structure is made up of 16-bits
for the limit of the GDT (again, needed for protection so the processor can
immediately create a General Protection Fault if we want a segment whose offset
doesn't exist in the GDT), and 32-bits for the address of the GDT itself.
</p>

<p>
We can use a simple array of 3 entries to define our GDT. For our special GDT
pointer, we only need one to be declared. We call it 'gp'. Create a new file,
'gdt.c'. Get gcc to compile your 'gdt.c' by adding a line to your 'build.bat' as
outlined in previous sections of this tutorial. Once again, I remind you to add
'gdt.o' to the list of files that LD needs to link in order to create your kernel!
Analyse the following code which makes up the first half of 'gdt.c':
</p>

<pre class="code">
#include &lt system.h &gt

/* Defines a GDT entry. We say packed, because it prevents the
*  compiler from doing things that it thinks is best: Prevent
*  compiler "optimization" by packing */
struct gdt_entry
{
    unsigned short limit_low;
    unsigned short base_low;
    unsigned char base_middle;
    unsigned char access;
    unsigned char granularity;
    unsigned char base_high;
} __attribute__((packed));

/* Special pointer which includes the limit: The max bytes
*  taken up by the GDT, minus 1. Again, this NEEDS to be packed */
struct gdt_ptr
{
    unsigned short limit;
    unsigned int base;
} __attribute__((packed));

/* Our GDT, with 3 entries, and finally our special GDT pointer */
struct gdt_entry gdt[3];
struct gdt_ptr gp;

/* This will be a function in start.asm. We use this to properly
*  reload the new segment registers */
extern void gdt_flush();
</pre>
<pre class="codecaption">Managing your GDT with 'gdt.c'</pre>

<p>
You will notice that we added a declaration for a function that does not exist yet:
gdt_flush(). gdt_flush() is the function that actually tells the processor where
the new GDT exists, using our special pointer that includes a limit as seen above.
We need to reload new segment registers, and finally do a far jump to reload our
new code segment. Learn from this code, and add it to 'start.asm' right after the
endless loop after 'stublet' in the blank space provided:
</p>

<pre class="code">
; This will set up our new segment registers. We need to do
; something special in order to set CS. We do what is called a
; far jump. A jump that includes a segment as well as an offset.
; This is declared in C as 'extern void gdt_flush();'
global _gdt_flush     ; Allows the C code to link to this
extern _gp            ; Says that '_gp' is in another file
_gdt_flush:
    lgdt [_gp]        ; Load the GDT with our '_gp' which is a special pointer
    mov ax, 0x10      ; 0x10 is the offset in the GDT to our data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp 0x08:flush2   ; 0x08 is the offset to our code segment: Far jump!
flush2:
    ret               ; Returns back to the C code!
</pre>
<pre class="codecaption">Add these lines to 'start.asm'</pre>

<p>
It's not enough to actually reserve space in memory for a GDT. We need to write
values into each GDT entry, set the 'gp' GDT pointer, and then we need to call
gdt_flush() to perform the update. There is a special function which follows, called
'gdt_set_entry()', which does all the shifts to set each field in the given
GDT entry to the appropriate value using easy to use function arguments. You
must add the prototypes for these 2 functions (at very least we need
'gdt_install') into 'system.h' so that we can use them in 'main.c'. Analyse the
following code - it makes up the rest of 'gdt.c':
</p>
		
<pre class="code">
/* Setup a descriptor in the Global Descriptor Table */
void gdt_set_gate(int num, unsigned long base, unsigned long limit, unsigned char access, unsigned char gran)
{
    /* Setup the descriptor base address */
    gdt[num].base_low = (base & 0xFFFF);
    gdt[num].base_middle = (base >> 16) & 0xFF;
    gdt[num].base_high = (base >> 24) & 0xFF;

    /* Setup the descriptor limits */
    gdt[num].limit_low = (limit & 0xFFFF);
    gdt[num].granularity = ((limit >> 16) & 0x0F);

    /* Finally, set up the granularity and access flags */
    gdt[num].granularity |= (gran & 0xF0);
    gdt[num].access = access;
}

/* Should be called by main. This will setup the special GDT
*  pointer, set up the first 3 entries in our GDT, and then
*  finally call gdt_flush() in our assembler file in order
*  to tell the processor where the new GDT is and update the
*  new segment registers */
void gdt_install()
{
    /* Setup the GDT pointer and limit */
    gp.limit = (sizeof(struct gdt_entry) * 3) - 1;
    gp.base = &gdt;

    /* Our NULL descriptor */
    gdt_set_gate(0, 0, 0, 0, 0);

    /* The second entry is our Code Segment. The base address
    *  is 0, the limit is 4GBytes, it uses 4KByte granularity,
    *  uses 32-bit opcodes, and is a Code Segment descriptor.
    *  Please check the table above in the tutorial in order
    *  to see exactly what each value means */
    gdt_set_gate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF);

    /* The third entry is our Data Segment. It's EXACTLY the
    *  same as our code segment, but the descriptor type in
    *  this entry's access byte says it's a Data Segment */
    gdt_set_gate(2, 0, 0xFFFFFFFF, 0x92, 0xCF);

    /* Flush out the old GDT and install the new changes! */
    gdt_flush();
}
</pre>
<pre class="codecaption">Add this to 'gdt.c'. It does some of the dirty work relating to the GDT!
Don't forget the prototypes in 'system.h'!</pre>

<p>
Now that our GDT loading infrastructure is in place, and we compile and link it into
our kernel, we need to call gdt_install() in order to actually do our work! Open
'main.c' and add 'gdt_install();' as the very first line in your main() function.
The GDT needs to be one of the very first things that you initialize because as you
learned from this section of the tutorial, it's very important. You can now compile,
link, and send our kernel to our floppy disk to test it out. You won't see any visible
changes on the screen: this is an internal change. Onto the Interrupt Descriptor
Table (IDT)!
</p>

## The IDT

<p>
The Interrupt Descriptor Table, or IDT, is used in order to show the processor
what Interrupt Service Routine (ISR) to call to handle either an exception or
an 'int' opcode (in assembly). IDT entries are also called by Interrupt Requests
whenever a device has completed a request and needs to be serviced. Exceptions
and ISRs are explained in greater detail in the next section of this tutorial,
accessible <a href="isrs.htm">here</a>.
</p>

<p>
Each IDT entry is similar to that of a GDT entry. Both have hold a base address,
both hold an access flag, and both are 64-bits long. The major differences in
these two types of descriptors is in the meanings of these fields. In an IDT,
the base address specified in the descriptor is actually the address of the
Interrupt Service Routine that the processor should call when this interrupt is
'raised' (called). An IDT entry doesn't have a limit, instead it has a segment
that you need to specify. The segment must be the same segment that the given
ISR is located in. This allows the processor to give control to the kernel
through an interrupt that has occured when the processor is in a different ring
(like when an application is running).
</p>

<p>
The access flags of an IDT entry are also similar to a GDT entry's. There is a
field to say if the descriptor is actually present or not. There is a field for
the Descriptor Privilege Level (DPL) to say which ring is the highest number
that is allowed to use the given interrupt. The major difference is the rest of
the access flag definition. The lower 5-bits of the access byte is always set
to 01110 in binary. This is 14 in decimal. Here is a table to give you a better
graphical representation of the access byte for an IDT entry.
</p>

<table>
<tr>
<td>
<table cols="25, 25, 25, 25, 100">
<tr>
<td width="25" align="center">7</td>
<td width="25" align="left">6</td>
<td width="25" align="right">5</td>
<td width="25" align="left">4</td>
<td width="100" align="right">0</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table border="1" bordercolor="#808080" cols="25, 50, 125">
<tr>
<td width="25">
P
</td>
<td width="50">
DPL
</td>
<td width="125">
Always 01110 (14)
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
P - Segment is present? (1 = Yes)<br>
DPL - Which Ring (0 to 3)<br>
</td>
</tr>
</table>				

<p>
Create a new file in your kernel directory called 'idt.c'. Edit your 'build.bat'
file to add another line to make GCC also compile 'idt.c'. Finally, add 'idt.o'
to the ever growing list of files that LD needs to link together to create your
kernel. 'idt.c' will declare a packed structure that defines each IDT entry, the
special IDT pointer structure needed to load the IDT (similar to loading a GDT,
but alot less work!), and also declare an array of 256 IDT entries: This will
become our IDT.
</p>

<pre class="code">
#include &lt system.h &gt

/* Defines an IDT entry */
struct idt_entry
{
    unsigned short base_lo;
    unsigned short sel;        /* Our kernel segment goes here! */
    unsigned char always0;     /* This will ALWAYS be set to 0! */
    unsigned char flags;       /* Set using the above table! */
    unsigned short base_hi;
} __attribute__((packed));

struct idt_ptr
{
    unsigned short limit;
    unsigned int base;
} __attribute__((packed));

/* Declare an IDT of 256 entries. Although we will only use the
*  first 32 entries in this tutorial, the rest exists as a bit
*  of a trap. If any undefined IDT entry is hit, it normally
*  will cause an "Unhandled Interrupt" exception. Any descriptor
*  for which the 'presence' bit is cleared (0) will generate an
*  "Unhandled Interrupt" exception */
struct idt_entry idt[256];
struct idt_ptr idtp;

/* This exists in 'start.asm', and is used to load our IDT */
extern void idt_load();
</pre>
<pre class="codecaption">This is the beginning half of 'idt.c'. Defines the vital data structures!</pre>

<p>
Again, like 'gdt.c', you will notice that there is a declaration of a function
that physically exists in another file. 'idt_load' is written in assembly language
just like 'gdt_flush'. All 'idt_load' is is calling the 'lidt' assembly opcode
using our special IDT pointer which we create later in 'idt_install'. Open up
'start.asm', and add the following lines right after the 'ret' for '_gdt_flush':
</p>

<pre class="code">
; Loads the IDT defined in '_idtp' into the processor.
; This is declared in C as 'extern void idt_load();'
global _idt_load
extern _idtp
_idt_load:
    lidt [_idtp]
    ret
</pre>
<pre class="codecaption">Add this to 'start.asm'</pre>

<p>
Setting up each IDT entry is alot easier than building a GDT entry. We have an
'idt_set_gate' function which accepts the IDT entry number, the base address of
our Interrupt Service Routine, our Kernel Code Segment, and the access flags as
outlined in the table introduced above. Again, we have an 'idt_install' function
which sets up our special IDT pointer as well as clears out the IDT to a default
known state of cleared. Finally, we would load the IDT by calling 'idt_load'.
Please note that you can add ISRs to your IDT at any time after the IDT is loaded.
More about ISRs later.
</p>

<pre class="code">
/* Use this function to set an entry in the IDT. Alot simpler
*  than twiddling with the GDT ;) */
void idt_set_gate(unsigned char num, unsigned long base, unsigned short sel, unsigned char flags)
{
    /* We'll leave you to try and code this function: take the
    *  argument 'base' and split it up into a high and low 16-bits,
    *  storing them in idt[num].base_hi and base_lo. The rest of the
    *  fields that you must set in idt[num] are fairly self-
    *  explanatory when it comes to setup */
}

/* Installs the IDT */
void idt_install()
{
    /* Sets the special IDT pointer up, just like in 'gdt.c' */
    idtp.limit = (sizeof (struct idt_entry) * 256) - 1;
    idtp.base = &idt;

    /* Clear out the entire IDT, initializing it to zeros */
    memset(&idt, 0, sizeof(struct idt_entry) * 256);

    /* Add any new ISRs to the IDT here using idt_set_gate */

    /* Points the processor's internal register to the new IDT */
    idt_load();
}
</pre>

<pre class="codecaption">The rest of 'idt.c'. Try to figure out 'idt_set_gate'. It's easy!</pre>

<p>
Finally, be sure to add 'idt_set_gate' and 'idt_install' as function prototypes in
'system.h'. Remember that we need to call these functions from other files, like
'main.c'. Call 'idt_install' from inside our 'main()' function, right after the call
to 'gdt_install'. You should be able to compile your kernel without problems. Take
some time to experiment a bit with your new kernel. If you try to do an illegal
operation like dividing by zero, you will find that your machine will reset! We can
catch these 'exceptions' by installing Interrupt Service Routines in our new IDT.
</p>

<p>
If you got stuck writing 'idt_set_gate', you may find the solution to this section
of the tutorial <a href="../Sources/idt.c">here</a>.
</p>

<a id='isr'></a>
<h2>Interrupt Service Routines</h2>

<p>
Interrupt Service Routines, or ISRs, are used to save the current processor state
and set up the appropriate segment registers needed for kernel mode before the
kernel's C-level interrupt handler is called. This can all be handled in about 15
or 20 lines of assembly language, including calling our handler in C. We need to
also point the correct entry in the IDT to the correct ISR in order to handle the
right exception.
</p>

<p>
An Exception is a special case that the processor encounters when it cannot continue
normal execution. This could be something like dividing by zero: The result is an
unknown or non-real number, so the processor will cause an exception so that the
kernel can stop that process or task from causing any problems. If the processor
finds that a program is trying to access a piece of memory that it shouldn't, it will
cause a General Protection Fault. When you set up paging, the processor causes a Page
Fault, but this is recoverable: you can map a page in memory to the faulted address -
but that's for another tutorial.
</p>

<p>
The first 32 entries in the IDT correspond to Exceptions that can possibly be
generated by the processor, and therefore need to be handled. Some exceptions will
push another value onto the stack: an Error Code value which is specific to the
exception caused.
</p>

<table cols="100, 300, 100">
<tr>
<th width="100" align="left">
    Exception #
</th>
<th width="300" align="left">
    Description
</th>
<th width="100" align="left">
    Error Code?
</th>
</tr>
<tr>
<td width="100">0</td>
<td width="300">Division By Zero Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">1</td>
<td width="300">Debug Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">2</td>
<td width="300">Non Maskable Interrupt Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">3</td>
<td width="300">Breakpoint Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">4</td>
<td width="300">Into Detected Overflow Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">5</td>
<td width="300">Out of Bounds Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">6</td>
<td width="300">Invalid Opcode Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">7</td>
<td width="300">No Coprocessor Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">8</td>
<td width="300">Double Fault Exception</td>
<td width="100">Yes</td>
</tr>
<tr>
<td width="100">9</td>
<td width="300">Coprocessor Segment Overrun Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">10</td>
<td width="300">Bad TSS Exception</td>
<td width="100">Yes</td>
</tr>
<tr>
<td width="100">11</td>
<td width="300">Segment Not Present Exception</td>
<td width="100">Yes</td>
</tr>
<tr>
<td width="100">12</td>
<td width="300">Stack Fault Exception</td>
<td width="100">Yes</td>
</tr>
<tr>
<td width="100">13</td>
<td width="300">General Protection Fault Exception</td>
<td width="100">Yes</td>
</tr>
<tr>
<td width="100">14</td>
<td width="300">Page Fault Exception</td>
<td width="100">Yes</td>
</tr>
<tr>
<td width="100">15</td>
<td width="300">Unknown Interrupt Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">16</td>
<td width="300">Coprocessor Fault Exception</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">17</td>
<td width="300">Alignment Check Exception (486+)</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">18</td>
<td width="300">Machine Check Exception (Pentium/586+)</td>
<td width="100">No</td>
</tr>
<tr>
<td width="100">19 to 31</td>
<td width="300">Reserved Exceptions</td>
<td width="100">No</td>
</tr>

</table>

<p>
As mentioned earlier, some exceptions push an error code onto the stack. To decrease
the complexity, we handle this by pushing a dummy error code of 0 onto the stack for
any ISR that doesn't push an error code already. This keeps a uniform stack frame. To
track which exception is firing, we also push the interrupt number on the stack. We
use the assembler opcode 'cli' to disable interrupts and prevent an IRQ from firing,
which could possibly otherwise cause conflicts in our kernel. To save space in the
kernel and make a smaller binary output file, we get each ISR stub to jump to a
common 'isr_common_stub'. The 'isr_common_stub' will save the processor state on the
stack, push the current stack address onto the stack (gives our C handler the stack),
call our C 'fault_handler' function, and finally restore the state of the stack. Add
this code to 'start.asm' in the provided space, filling out all 32 ISRs:
</p>

<pre class="code">
; In just a few pages in this tutorial, we will add our Interrupt
; Service Routines (ISRs) right here!
global _isr0
global _isr1
global _isr2
...                ; Fill in the rest here!
global _isr30
global _isr31

;  0: Divide By Zero Exception
_isr0:
    cli
    push byte 0    ; A normal ISR stub that pops a dummy error code to keep a
                   ; uniform stack frame
    push byte 0
    jmp isr_common_stub

;  1: Debug Exception
_isr1:
    cli
    push byte 0
    push byte 1
    jmp isr_common_stub
    
...                ; Fill in from 2 to 7 here!

;  8: Double Fault Exception (With Error Code!)
_isr8:
    cli
    push byte 8        ; Note that we DON'T push a value on the stack in this one!
                   ; It pushes one already! Use this type of stub for exceptions
                   ; that pop error codes!
    jmp isr_common_stub

...                ; You should fill in from _isr9 to _isr31 here. Remember to
                   ; use the correct stubs to handle error codes and push dummies!

; We call a C function in here. We need to let the assembler know
; that '_fault_handler' exists in another file
extern _fault_handler

; This is our common ISR stub. It saves the processor state, sets
; up for kernel mode segments, calls the C-level fault handler,
; and finally restores the stack frame.
isr_common_stub:
    pusha
    push ds
    push es
    push fs
    push gs
    mov ax, 0x10   ; Load the Kernel Data Segment descriptor!
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov eax, esp   ; Push us the stack
    push eax
    mov eax, _fault_handler
    call eax       ; A special call, preserves the 'eip' register
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    popa
    add esp, 8     ; Cleans up the pushed error code and pushed ISR number
    iret           ; pops 5 things at once: CS, EIP, EFLAGS, SS, and ESP!
</pre>

<pre class="codecaption">Add this to 'start.asm' in the spot we indicated in "The Basic Kernel"</pre>

<p>
Create yourself a new file called 'isrs.c'. Once again, remember to add the
appropriate line to get GCC to compile the file in 'build.bat'. Add the file 'isrs.o'
to LD's list of files so that it gets linked into the kernel. 'isrs.c' is rather
straight-forward: declare our regular #include line, declare the prototypes of each
of the ISRs from inside 'start.asm', point the IDT entry to the correct ISR, and
finally, create an interrupt handler in C to service all of our exceptions
generically. I'll leave it up to you to fill in the holes here:
</p>

<pre class="code">
#include &lt system.h &gt

/* These are function prototypes for all of the exception
*  handlers: The first 32 entries in the IDT are reserved
*  by Intel, and are designed to service exceptions! */
extern void isr0();
extern void isr1();
extern void isr2();

...                             /* Fill in the rest of the ISR prototypes here */

extern void isr29();
extern void isr30();
extern void isr31();

/* This is a very repetitive function... it's not hard, it's
*  just annoying. As you can see, we set the first 32 entries
*  in the IDT to the first 32 ISRs. We can't use a for loop
*  for this, because there is no way to get the function names
*  that correspond to that given entry. We set the access
*  flags to 0x8E. This means that the entry is present, is
*  running in ring 0 (kernel level), and has the lower 5 bits
*  set to the required '14', which is represented by 'E' in
*  hex. */
void isrs_install()
{
    idt_set_gate(0, (unsigned)isr0, 0x08, 0x8E);
    idt_set_gate(1, (unsigned)isr1, 0x08, 0x8E);
    idt_set_gate(2, (unsigned)isr2, 0x08, 0x8E);
    idt_set_gate(3, (unsigned)isr3, 0x08, 0x8E);

    ...                         /* Fill in the rest of these ISRs here */

    idt_set_gate(30, (unsigned)isr30, 0x08, 0x8E);
    idt_set_gate(31, (unsigned)isr31, 0x08, 0x8E);
}

/* This is a simple string array. It contains the message that
*  corresponds to each and every exception. We get the correct
*  message by accessing like:
*  exception_message[interrupt_number] */
unsigned char *exception_messages[] =
{
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    
    ...                         /* Fill in the rest here from our Exceptions table */
    
    "Reserved",
    "Reserved"
};

/* All of our Exception handling Interrupt Service Routines will
*  point to this function. This will tell us what exception has
*  happened! Right now, we simply halt the system by hitting an
*  endless loop. All ISRs disable interrupts while they are being
*  serviced as a 'locking' mechanism to prevent an IRQ from
*  happening and messing up kernel data structures */
void fault_handler(struct regs *r)
{
    /* Is this a fault whose number is from 0 to 31? */
    if (r->int_no < 32)
    {
        /* Display the description for the Exception that occurred.
        *  In this tutorial, we will simply halt the system using an
        *  infinite loop */
        puts(exception_messages[r->int_no]);
        puts(" Exception. System Halted!\n");
        for (;;);
    }
}
</pre>
<pre class="codecaption">The contents of 'isrs.c'</pre>

<p>
Wait, we have a new structure here as an argument to 'fault_handler': struct
'regs'. In this case, 'regs' is a way of showing the C code what the stack
frame looks like. Remember that in 'start.asm' that we push a pointer to the
stack onto the stack itself: this is so that we may be able to retrieve any
error codes and interrupt numbers from the handlers themselves. This design is
what allows us to use the same C handler for each different ISR and still be
able to tell which exception or interrupt actually happened.
</p>

<pre class="code">
/* This defines what the stack looks like after an ISR was running */
struct regs
{
    unsigned int gs, fs, es, ds;      /* pushed the segs last */
    unsigned int edi, esi, ebp, esp, ebx, edx, ecx, eax;  /* pushed by 'pusha' */
    unsigned int int_no, err_code;    /* our 'push byte #' and ecodes do this */
    unsigned int eip, cs, eflags, useresp, ss;   /* pushed by the processor automatically */ 
};
</pre>
<pre class="codecaption">Defines a stack frame pointer argument. Add this to 'system.h'</pre>

<p>
Open 'system.h' and add the definition to struct 'regs' as well as the function
prototype for 'isrs_install' so that we can call it from in 'main.c'. Finally,
call 'isrs_install' from in our 'main' function, right after we install our new
IDT. It would be a good idea to test out the exception handlers in our kernel now.<br>
<br>
OPTIONAL: In 'main', add some tester code that will divide a number by zero. As
soon as the processor encounters this, the processor will generate a "Divide By
Zero" Exception, and you will see that appear on the screen! When you test
that, and it works, you can delete your exception causing code (the
'putch(myvar / 0);' line, or whatever you decide to write.
</p>

<p>
You may find the complete solution to 'start.s' <a href="../Sources/start.asm">
here</a>, and the complete solution to 'isrs.c' <a href="../Sources/isrs.c">here</a>.
</p>

## IRQs and PICs

<p>
Interrupt Requests or IRQs are interrupts that are raised by hardware devices. Some
devices generate an IRQ when they have data ready to be read, or when they finish a
command like writing a buffer to disk, for example. It's safe to say that a device
will generate an IRQ whenever it wants the processor's attention. IRQs are generated
by everything from network cards and sound cards to your mouse, keyboard, and serial
ports.
</p>

<p>
Any IBM PC/AT Compatible computer (anything with a 286 and later processor) has 2
chips that are used to manage IRQs. These 2 chips are known as the Programmable
Interrupt Controllers or PICs. These PICs also go by the name '8259'. One 8259 acts
as the 'Master' IRQ controller, and one is the 'Slave' IRQ controller. The slave is
connected to IRQ2 on the master controller. The master IRQ controller is connected
directly to the processor itself, to send signals. Each PIC can handle 8 IRQs. The
master PIC handles IRQs 0 to 7, and the slave PIC handles IRQs 8 to 15. Remember
that the slave controller is connected to the primary controller through IRQ2: This
means that every time an IRQ from 8 to 15 occurs, IRQ2 fires at exactly the same
time.
</p>

<p>
When a device signals an IRQ, remember that an interrupt is generated, and the CPU
pauses whatever it's doing to call the ISR to handle the corresponding IRQ. The CPU
then performs whatever necessary action (like reading from the keyboard, for example),
and then it must tell the PIC that the interrupt came from that the CPU has finished
executing the correct routine. The CPU tells the right PIC that the interrupt is
complete by writing the command byte 0x20 in hex to the command register for that PIC.
The master PIC's command register exists at I/O port 0x20, while the slave PIC's
command register exists at I/O port 0xA0.
</p>

<p>
Before we get into writing our IRQ management code, we need to also know that IRQ0 to
IRQ7 are originally mapped to IDT entries 8 through 15. IRQ8 to IRQ15 are mapped to
IDT entries 0x70 through 0x78. If you remember the previous section of this tutorial,
IDT entries 0 through 31 are reserved for exceptions. Fortunately, the Interrupt
Controllers are 'programmable': You can change what IDT entries that their IRQs are
mapped to. For this tutorial, we will map IRQ0 through IRQ15 to IDT entries 32 through
47. To start us off, we must add some ISRs to 'start.asm' in order to service our
interrupts:
</p>

<pre class="code">
global _irq0
...                ; You complete the rest!
global _irq15

; 32: IRQ0
_irq0:
    cli
    push byte 0    ; Note that these don't push an error code on the stack:
                   ; We need to push a dummy error code
    push byte 32
    jmp irq_common_stub

...                ; You need to fill in the rest!

; 47: IRQ15
_irq15:
    cli
    push byte 0
    push byte 47
    jmp irq_common_stub

extern _irq_handler

; This is a stub that we have created for IRQ based ISRs. This calls
; '_irq_handler' in our C code. We need to create this in an 'irq.c'
irq_common_stub:
    pusha
    push ds
    push es
    push fs
    push gs
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov eax, esp
    push eax
    mov eax, _irq_handler
    call eax
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    popa
    add esp, 8
    iret
</pre>
<pre class="codecaption">Add this chunk of code to 'start.asm'</pre>

<p>
Just like each section of this tutorial before this one, we need to create a new
file called 'irq.c'. Edit 'build.bat' to add the appropriate line to get GCC to
compile to source, and also remember to add a new object file to get LD to link
into our kernel.
</p>

<pre class="code">
#include &lt system.h &gt

/* These are own ISRs that point to our special IRQ handler
*  instead of the regular 'fault_handler' function */
extern void irq0();
...                    /* Add the rest of the entries here to complete the declarations */
extern void irq15();

/* This array is actually an array of function pointers. We use
*  this to handle custom IRQ handlers for a given IRQ */
void *irq_routines[16] =
{
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0
};

/* This installs a custom IRQ handler for the given IRQ */
void irq_install_handler(int irq, void (*handler)(struct regs *r))
{
    irq_routines[irq] = handler;
}

/* This clears the handler for a given IRQ */
void irq_uninstall_handler(int irq)
{
    irq_routines[irq] = 0;
}

/* Normally, IRQs 0 to 7 are mapped to entries 8 to 15. This
*  is a problem in protected mode, because IDT entry 8 is a
*  Double Fault! Without remapping, every time IRQ0 fires,
*  you get a Double Fault Exception, which is NOT actually
*  what's happening. We send commands to the Programmable
*  Interrupt Controller (PICs - also called the 8259's) in
*  order to make IRQ0 to 15 be remapped to IDT entries 32 to
*  47 */
void irq_remap(void)
{
    outportb(0x20, 0x11);
    outportb(0xA0, 0x11);
    outportb(0x21, 0x20);
    outportb(0xA1, 0x28);
    outportb(0x21, 0x04);
    outportb(0xA1, 0x02);
    outportb(0x21, 0x01);
    outportb(0xA1, 0x01);
    outportb(0x21, 0x0);
    outportb(0xA1, 0x0);
}

/* We first remap the interrupt controllers, and then we install
*  the appropriate ISRs to the correct entries in the IDT. This
*  is just like installing the exception handlers */
void irq_install()
{
    irq_remap();

    idt_set_gate(32, (unsigned)irq0, 0x08, 0x8E);
    ...          /* You need to add the rest! */
    idt_set_gate(47, (unsigned)irq15, 0x08, 0x8E);
}

/* Each of the IRQ ISRs point to this function, rather than
*  the 'fault_handler' in 'isrs.c'. The IRQ Controllers need
*  to be told when you are done servicing them, so you need
*  to send them an "End of Interrupt" command (0x20). There
*  are two 8259 chips: The first exists at 0x20, the second
*  exists at 0xA0. If the second controller (an IRQ from 8 to
*  15) gets an interrupt, you need to acknowledge the
*  interrupt at BOTH controllers, otherwise, you only send
*  an EOI command to the first controller. If you don't send
*  an EOI, you won't raise any more IRQs */
void irq_handler(struct regs *r)
{
    /* This is a blank function pointer */
    void (*handler)(struct regs *r);

    /* Find out if we have a custom handler to run for this
    *  IRQ, and then finally, run it */
    handler = irq_routines[r->int_no - 32];
    if (handler)
    {
        handler(r);
    }

    /* If the IDT entry that was invoked was greater than 40
    *  (meaning IRQ8 - 15), then we need to send an EOI to
    *  the slave controller */
    if (r->int_no >= 40)
    {
        outportb(0xA0, 0x20);
    }

    /* In either case, we need to send an EOI to the master
    *  interrupt controller too */
    outportb(0x20, 0x20);
}
</pre>

<pre class="codecaption">The contents of 'irq.c'</pre>

<p>
In order to actually install the IRQ handling ISRs, we need to call 'irq_install'
from inside the 'main' function in 'main.c'. Before you add the call, you need to
add function prototypes to 'system.h' for 'irq_install', 'irq_install_handler', and
'irq_uninstall_handler'. 'irq_install_handler' is used for allowing us to install a
special custom IRQ sub handler for our device under a given IRQ. In a later section,
we will use 'irq_install_handler' to install a custom IRQ handler for both the
System Clock (The PIT - IRQ0) and the Keyboard (IRQ1). Add 'irq_install' to the
'main' function in 'main.c', right after we install our exception ISRs. Immediately
following that line, it's safe to allow IRQs to happen. Add the line:<br>
__asm__ __volatile__ ("sti");
</p>

<p>
Congratulations, you have now followed how to step by step create a simple kernel
that is capable of handling IRQs and Exceptions. An IDT is installed, along with a
custom GDT to replace the original one loaded by GRUB. If you have understood all
that is mentioned up until this point, you have passed one of the biggest hurdles
associated with Operating System development. Most hobbyist OS developers do not
successfully get past installing ISRs and an IDT. Next, we will learn about the
simplest device to use an IRQ: The Programmable Interval Timer (PIT).
</p>

<a id="pit"></a>
## The PIT: A System Clock

<p>
The Programmable Interval Timer (PIT, model 8253 or 8254), also called the System
Clock, is a very useful chip for accurately generating interrupts at regular time
intervals. The chip itself has 3 channels: Channel 0 is tied to is tied to IRQ0,
to interrupt the CPU at predictable and regular times, Channel 1 is system specific,
and Channel 2 is connected to the system speaker. As you can see, this single chip
offers several very important services to the system.
</p>

<p>
The only channels that you should every be concerned with are Channels 0 and 2. You
may use Channel 2 in order to make the computer beep. In this section of the
tutorial, we are only concerned with Channel 0 - mapped to IRQ0. This single channel
of the timer will allow you to accurately schedule new processes later on, as well
as allow the current task to wait for a certain period of time (as will be
demonstrated shortly). By default, this channel of the timer is set to generate an
IRQ0 18.222 times per second. It is the IBM PC/AT BIOS that defaults it to this. A
reader of this tutorial has informed me that this 18.222Hz tick rate was used in order
for the tick count to cycle at 0.055 seconds. Using a 16-bit timer tick counter, the
counter will overflow and wrap around to 0 once every hour.
</p>

<p>
To set the rate at which channel 0 of the timer fires off an IRQ0, we must use our
outportb function to write to I/O ports. There is a Data register for each of the
timer's 3 channels at 0x40, 0x41, and 0x42 respectively, and a Command register at
0x43. The data rate is actually a 'divisor' register for this device. The timer will
divide it's input clock of 1.19MHz (1193180Hz) by the number you give it in the data
register to figure out how many times per second to fire the signal for that
channel. You must first select the channel that we want to update using the command
register before writing to the data/divisor register. What is shown in the following
two tables is the bit definitions for the command register, as well as some timer
modes.
</p>

<table>
<tr>
<td width="300" valign="top">
<table>
<tr>
<td>
<table cols="25, 25, 25, 25, 50, 25, 25">
<tr>
<td width="25" align="left">7</td>
<td width="25" align="right">6</td>
<td width="25" align="left">5</td>
<td width="25" align="right">4</td>
<td width="50" align="left">3</td>
<td width="25" align="right">1</td>
<td width="25" align="center">0</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table border="1" bordercolor="#808080" cols="50, 50, 75, 25">
<tr>
<td width="50">CNTR</td>
<td width="50">RW</td>
<td width="75">Mode</td>
<td width="25">BCD</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
CNTR - Counter # (0-2)<br>
RW - Read Write mode<br>
(1 = LSB, 2 = MSB, 3 = LSB then MSB)<br>
Mode - See right table<br>
BCD - (0 = 16-bit counter,<br>
1 = 4x BCD decade counters)
</td>
</tr>
</table>				
</td>
<td>
<table border="1" bordercolor="#808080">
<tr>
<th>Mode</th>
<th>Description</th>
</tr>
<tr>
<td>0</td>
<td>Interrupt on terminal count</td>
</tr>
<tr>
<td>1</td>
<td>Hardware Retriggerable one shot</td>
</tr>
<tr>
<td>2</td>
<td>Rate Generator</td>
</tr>
<tr>
<td>3</td>
<td>Square Wave Mode</td>
</tr>
<tr>
<td>4</td>
<td>Software Strobe</td>
</tr>
<tr>
<td>5</td>
<td>Hardware Strobe</td>
</tr>
</table>
</td>
</tr>
</table>
<b>Bit definitions for 8253 and 8254 chip's Command Register located at 0x43</b>

<p>
To set channel 0's Data register, we need to select counter 0 and some modes in the
Command register first. The divisor value we want to write to the Data register is
a 16-bit value, so we will need to transfer both the MSB (Most Significant Byte)
and LSB (Least Significant Byte) to the data register. This is a 16-bit value, we
aren't sending data in BCD (Binary Coded Decimal), so the BCD field should be set
to 0. Finally, we want to generate a Square Wave: Mode 3. The resultant byte that
we should set in the Command register is 0x36. The above 2 paragraphs and tables
can be summed up into this function. Use it if you wish, we won't use it in this
tutorial to keep things simple. For accurate and easy timekeeping, I recommend
setting to 100Hz in a real kernel.
</p>

<pre class="code">
void timer_phase(int hz)
{
    int divisor = 1193180 / hz;       /* Calculate our divisor */
    outportb(0x43, 0x36);             /* Set our command byte 0x36 */
    outportb(0x40, divisor & 0xFF);   /* Set low byte of divisor */
    outportb(0x40, divisor >> 8);     /* Set high byte of divisor */
}
</pre>
<pre class="codecaption">Not bad, eh?</pre>

<p>
Create a file called 'timer.c', and add it to your 'build.bat' as you've been shown
in the previous sections of this tutorial. As you analyse the following code, you
will see that we keep track of the amount of ticks that the timer has fired. This
can be used as a 'system uptime counter' as your kernel gets more complicated. The
timer interrupt here simply uses the default 18.222Hz to figure out when it should
display a simple "One second has passed" message every second. If you decide to use
the 'timer_phase' function in your code, you should change the 'timer_ticks % 18 ==
0' line in 'timer_handler' to 'timer_ticks % 100 == 0' instead. You could set the
timer phase from any function in the kernel, however I recommend setting it in
'timer_install' if anything, to keep things organized.
</p>

<pre class="code">
#include &lt system.h &gt

/* This will keep track of how many ticks that the system
*  has been running for */
int timer_ticks = 0;

/* Handles the timer. In this case, it's very simple: We
*  increment the 'timer_ticks' variable every time the
*  timer fires. By default, the timer fires 18.222 times
*  per second. Why 18.222Hz? Some engineer at IBM must've
*  been smoking something funky */
void timer_handler(struct regs *r)
{
    /* Increment our 'tick count' */
    timer_ticks++;

    /* Every 18 clocks (approximately 1 second), we will
    *  display a message on the screen */
    if (timer_ticks % 18 == 0)
    {
        puts("One second has passed\n");
    }
}

/* Sets up the system clock by installing the timer handler
*  into IRQ0 */
void timer_install()
{
    /* Installs 'timer_handler' to IRQ0 */
    irq_install_handler(0, timer_handler);
}
</pre>
<pre class="codecaption">Example of using the system timer: 'timer.c'</pre>

<p>
    Remember to add a call to 'timer_install' in the 'main' function in 'main.c'.
    Having trouble? Remember to add a function prototype of 'timer_install' to
    'system.h'! The next bit of code is more of a demonstration of what you can do
    with the system timer. If you look carefully, this simple function waits in a
    loop until the given time in 'ticks' or timer phases has gone by. This is
    almost the same as the standard C library's function 'delay', depending on your
    timer phase that you set:
</p>

<pre class="code">
/* This will continuously loop until the given time has
*  been reached */
void timer_wait(int ticks)
{
    unsigned long eticks;

    eticks = timer_ticks + ticks;
    while(timer_ticks < eticks);
}
</pre>
<pre class="codecaption">If you wish, add this to 'timer.c' and a prototype to 'system.h'</pre>

<p>
Next, we will discuss how to use the keyboard. This involves installing a custom
IRQ handler just like this tutorial, with hardware I/O on each interrupt.
</p>

## The Keyboard

<p>
A keyboard is the most common way for a user to give a computer input, therefore
it is vital that you create a driver of some sort for handling and managing the
keyboard. When you get down to it, getting the basics of the keyboard isn't too
bad. Here we will show the basics: how to get a key when it is pressed, and how
to convert what's called a 'scancode' to standard ASCII characters that we can
understand properly.
</p>

<p>
A scancode is simply a key number. The keyboard assigns a number to each key on
the keyboard; this is your scancode. The scancodes are numbered generally from
top to bottom and left to right, with some minor exceptions to keep layouts
backwards compatible with older keyboards. You must use a lookup table (an array
of values) and use the scancode as the index into this table. The lookup table
is called a keymap, and will be used to translate scancodes into ASCII values
rather quickly and painlessly. One last note about a scancode before we head into
code is that if bit 7 is set (test with 'scancode & 0x80'), then this is the
keyboard's way of telling us that a key was just released. Create yourself a 'kb.h'
and do all your standard proceedures like adding a line for GCC and adding a file
to LD's command line.
</p>

<pre class="code">
/* KBDUS means US Keyboard Layout. This is a scancode table
*  used to layout a standard US keyboard. I have left some
*  comments in to give you an idea of what key is what, even
*  though I set it's array index to 0. You can change that to
*  whatever you want using a macro, if you wish! */
unsigned char kbdus[128] =
{
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8',	/* 9 */
  '9', '0', '-', '=', '\b',	/* Backspace */
  '\t',			/* Tab */
  'q', 'w', 'e', 'r',	/* 19 */
  't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',	/* Enter key */
    0,			/* 29   - Control */
  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',	/* 39 */
 '\'', '`',   0,		/* Left shift */
 '\\', 'z', 'x', 'c', 'v', 'b', 'n',			/* 49 */
  'm', ',', '.', '/',   0,				/* Right shift */
  '*',
    0,	/* Alt */
  ' ',	/* Space bar */
    0,	/* Caps lock */
    0,	/* 59 - F1 key ... > */
    0,   0,   0,   0,   0,   0,   0,   0,
    0,	/* < ... F10 */
    0,	/* 69 - Num lock*/
    0,	/* Scroll Lock */
    0,	/* Home key */
    0,	/* Up Arrow */
    0,	/* Page Up */
  '-',
    0,	/* Left Arrow */
    0,
    0,	/* Right Arrow */
  '+',
    0,	/* 79 - End key*/
    0,	/* Down Arrow */
    0,	/* Page Down */
    0,	/* Insert Key */
    0,	/* Delete Key */
    0,   0,   0,
    0,	/* F11 Key */
    0,	/* F12 Key */
    0,	/* All other keys are undefined */
};		</pre>
<pre class="codecaption">Sample keymap. Add this array to your 'kb.c'</pre>

<p>
Converting a scancode to an ASCII value is easy with this:<br><br>
mychar = kbdus[scancode];<br><br>
Note that although we leave comments for the function keys and shift/control/alt,
we leave them as 0's in the array: You need to think up some random values such
as ASCII values that you normally wouldn't use so that you can trap them. I'll
leave this up to you, but you should keep a global variable to be used as a key
status variable. This keystatus variable will have 1 bit set for ALT, one for
CONTROL, and one for SHIFT. It's also a good idea to have one for CAPSLOCK,
NUMLOCK, and SCROLLLOCK. This tutorial will explain how to set the keyboard lights,
but we will leave it up to you to actually write the code for it.
</p>

<p>
The keyboard is attached to the computer through a special microcontroller chip on
your mainboard. This keyboard controller chip has 2 channels: one for the keyboard,
and one for the mouse. Also note that it is through this keyboard controller chip
that you would enable the A20 address line on the processor to allow you to access
memory past the 1MByte mark (GRUB enables this, you don't need to worry about it).
The keyboard controller, being a device accessible by the system, has an address on
the I/O bus that we can use for access and control. The keyboard controller has 2
main registers: a Data register at 0x60, and a Control register at 0x64. Anything
that the keyboard wants to send the computer is stored into the Data register.
The keyboard will raise IRQ1 whenever it has data for us to read. Observe:
</p>

<pre class="code">
/* Handles the keyboard interrupt */
void keyboard_handler(struct regs *r)
{
    unsigned char scancode;

    /* Read from the keyboard's data buffer */
    scancode = inportb(0x60);

    /* If the top bit of the byte we read from the keyboard is
    *  set, that means that a key has just been released */
    if (scancode & 0x80)
    {
        /* You can use this one to see if the user released the
        *  shift, alt, or control keys... */
    }
    else
    {
        /* Here, a key was just pressed. Please note that if you
        *  hold a key down, you will get repeated key press
        *  interrupts. */

        /* Just to show you how this works, we simply translate
        *  the keyboard scancode into an ASCII value, and then
        *  display it to the screen. You can get creative and
        *  use some flags to see if a shift is pressed and use a
        *  different layout, or you can add another 128 entries
        *  to the above layout to correspond to 'shift' being
        *  held. If shift is held using the larger lookup table,
        *  you would add 128 to the scancode when you look for it */
        putch(kbdus[scancode]);
    }
}
</pre>
<pre class="codecaption">This might look intimidating, but it's 80% comments ;) Add to 'kb.c'</pre>

<p>
As you can see, the keyboard will generate an IRQ1 telling us that it has data
ready for us to grab. The keyboard's data register exists at 0x60. When the IRQ
happens, we call this handler which reads from port 0x60. This data that we read
is the keyboard's scancode. For this example, we check if the key was pressed or
released. If it was just pressed, we translate the scancode to ASCII, and print
that character out with one line. Write a 'keyboard_install' function that calls
'irq_install_handler' to install the custom keyboard handler for
'keyboard_handler' to IRQ1. Be sure to make a call to 'keyboard_install' from
inside 'main'.
</p>

<p>
In order to set the lights on your keyboard, you must send the keyboard controller
a command. There is a specific proceedure for sending the keyboard a command. You
must first wait for the keyboard controller to let you know when it's not busy. To
do this, you read from the Control register (When you read from it, it's called a
Status register) in a loop, breaking out when the keyboard isn't busy:<br><br>
if ((inportb(0x64) & 2) == 0) break;
</p>

<p>
After that loop, you may write the command byte to the Data register. You don't
write to the control register itself except for in special cases. To set the
lights on the keyboard, you first send the command byte 0xED using the described
method, then you send the byte that says which lights are to be on or off. This
byte has the following format: Bit0 is Scroll lock, Bit1 is Num lock, and Bit2
is Caps lock.
</p>

<p>
Now that you have basic keyboard support, you may wish to expand upon the code.
This section on the keyboard was more to show you how to do the basics rather than
give an extremely detailed overview of all of the keyboard controller's functions.
Note that you use the keyboard controller to enable and handle the PS/2 mouse port.
The auxilliary channel on the keyboard controller manages the PS/2 mouse. Up to
this point we have a kernel that can draw to the screen, handle exceptions, handle
IRQs, handle the timer, and handle the keyboard. Click to find what's next in store
for your kernel development.
</p>

<a id="left"></a>
<h2>What's Left</h2>

<p>
What you do next to your kernel is completely up to you. The next thing you should
think of writing is a memory manager. A memory manager will allow you to grab
chunks of memory so that you can dynamically allocate and free memory as you need
it. Using a memory manager, you can use more complicated data structures such as
linked lists and binary trees to allow for more efficient storage and manipulation
of data. It's also a way of preventing applications from writing to kernel pages,
which is a feature of protection.
</p>

<p>
It's possible to write a VGA driver, also. Using a VGA driver, you can set up
different graphics modes in your kernel, allowing higher resolutions and graphical
display options such as buttons and images. If you want to go further, you could
eventually look into VESA video modes for high color and higher resolutions.
</p>

<p>
You could eventually write a device interface which would allow you to load or
unload kernel 'modules' as you need them. Add support for filesystems and disk
drives so that you can access files off disks and open applications.
</p>

<p>
It's very possible that you add multitasking support and design scheduling algorithms
to give certain tasks higher priority and longer time to run according to what the
application is designed to run at. The multitasking system closely relies on your
memory manager to give each task a separate space in memory.
</p>

<h3>Example kernel online source tree</h3>

<p>
<img src="asm_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/start.asm">start.asm</a><br>
<img src="c_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/gdt.c">gdt.c</a><br>
<img src="c_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/idt.c">idt.c</a><br>
<img src="c_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/irq.c">irq.c</a><br>
<img src="c_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/isrs.c">isrs.c</a><br>
<img src="c_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/kb.c">kb.c</a><br>
<img src="c_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/main.c">main.c</a><br>
<img src="c_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/scrn.c">scrn.c</a><br>
<img src="c_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/timer.c">timer.c</a><br>
<img src="h_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/include/system.h">include/system.h</a><br>
<img src="ld_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/link.ld">link.ld</a><br>
<img src="bat_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/build.bat">build.bat</a><br>
<img src="disk_icon.PNG"><a href="http://www.osdever.net/bkerndev/Sources/dev_kernel_grub.img">dev_kernel_grub.img</a><br>
</p>

<p>Get the whole tutorial and example kernel <a href="http://www.osdever.net/bkerndev/bkerndev.zip">here</a> (110KBytes).</p>

<p>
I hope that this tutorial has given you a more thorough understanding of some of the
various low-level items involved in creating a kernel: a driver for your processor
and memory.
</p>
