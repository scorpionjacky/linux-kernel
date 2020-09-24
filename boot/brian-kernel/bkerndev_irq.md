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
