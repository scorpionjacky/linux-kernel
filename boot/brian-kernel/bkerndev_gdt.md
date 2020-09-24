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

