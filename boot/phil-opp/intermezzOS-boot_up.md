# Booting up

https://intermezzos.github.io/book/first-edition/booting-up.html

The x86 architecture maintains backwards compatibility throughout the years.

The first mode is called ‘real mode’. This is a 16 bit mode that the original x86 chips used. 

The second is ‘protected mode’. This 32 bit mode adds new things on top of real mode. It’s called ‘protected’ because real mode sort of let you do whatever you wanted, even if it was a bad idea. Protected mode was the first time that the hardware enabled certain kinds of protections that allow us to exercise more control around such things as RAM. We’ll talk more about those details later.

The final mode is called ‘long mode’, and it’s 64 bits.

> Well, that’s actually a lie: there str two. Initially, you’re not in long mode, you’re in ‘compatibility mode’. You see, when the industry was undergoing the transition from 32 to 64 bits, there were two options: the first was Intel’s Itanium 64-bit architecture. It did away with all of the stuff I just told you about. But that meant that programs had to be completely recompiled from scratch for the new chips. Intel’s big competitor, AMD, saw an opportunity here, and released a new set of chips called amd64. These chips were backwards compatible, and so you could run both 32 and 64 bit programs on them. Itanium wasn’t compelling enough to make the pain worth it, and so Intel released new chips that were compatible with amd64. The resulting architecture was then called x86_64, the one we’re using today. The moral of the story? Intel tried to save you from all of the stuff we’re about to do, but they failed. So we have to do it.


GRUB and Multiboot

By following the Multiboot specification, we can let GRUB load our kernel. The way that we do this is through a ‘header’. We’ll put some information in a format that multiboot specifies right at the start of our kernel. GRUB will read this information, and follow it to do the right thing.

One other advantage of using GRUB: it will handle the transition from real mode to protected mode for us, skipping the first step. We don’t even need to know anything about all of that old stuff. If you’re curious about the kinds of things you would have needed to know, put “A20 line” into your favorite search engine, and get ready to cry yourself to sleep.

Multiboot header

```asm
section .multiboot_header
header_start:
    dd 0xe85250d6                ; magic number
    dd 0                         ; protected mode code
    dd header_end - header_start ; header length

    ; checksum
    dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start))

    ; required end tag
    dw 0    ; type
    dw 0    ; flags
    dd 8    ; size
header_end:
```

You might wonder why we're subtracting these values from 0x100000000. To answer this we can look at what [the multiboot spec](http://nongnu.askapache.com/grub/phcoder/multiboot.pdf) says about the checksum value in the header:

The field `checksum` is a 32-bit unsigned value which, when added to the other magic fields (i.e. `magic`, `architecture` and `header_length`), must have a 32-bit unsigned sum of zero.

In other words:

checksum + magic_number + architecture + header_length = 0

We could try and "solve for" checksum like so:

checksum = -(magic_number + architecture + header_length)

But here's where it gets weird. Computers don't have an innate concept of negative numbers. Normally we get around this by using "signed integers", which is something we cover in an appendix. The point is we have an unsigned integer here, which means we're limited to representing only positive numbers. This means we can't literally represent -(magic_number + architecture + header_length) in our field.

If you look closely at the spec you'll notice it's strangely worded: it's asking for a value that when added to other values has a sum of zero. It's worded this way because integers have a limit to the size of numbers they can represent, and when you go over that size, the values wrap back around to zero. So 0xFFFFFFFF + 1 is.... 0x00000000. This is a hardware limitation: technically it's doing the addition correctly, giving us the 33-bit value 0x100000000, but we only have 32 bits to store things in so it can't actually tell us about that 1 in the most significant digit position! We're left with the rest of the digits, which spell out zero.

So what we can do here is "trick" the computer into giving us zero when we do the addition. Imagine for the sake of argument that magic_number + architecture + header_length somehow works out to be 0xFFFFFFFE. The number we'd add to that in order to make 0 would be 0x00000002. This is 0x100000000-0xFFFFFFFE, because 0x100000000 technically maps to 0 when we wrap around. So we replace 0xFFFFFFFE in our contrived example here with magic_number + architecture + header_length. This gives us: dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start))

`$ nasm -f elf64 multiboot_header.asm`


```asm
global start

section .text
bits 32
start:
    mov word [0xb8000], 0x0248 ; H
    hlt
```

`bits 32`: GRUB will boot us into protected mode, aka 32-bit mode. So we have to specify that directly. Our Hello World will only be in 32 bits. We’ll transition from 32-bit mode to 64-bit mode later.

> "Memory mapping" is one of the fundamental techniques used in computer engineering to help the CPU know how to talk to all the different physical components of a computer. The CPU itself is just a weird little machine that moves numbers around. It's not of any use to humans on its own: it needs to be connected to devices like RAM, hard drives, a monitor, and a keyboard. The way the CPU does this is through a bus, which is a huge pipeline of wires connecting the CPU to every single device that might have data the CPU needs. There's one wire per bit (since a wire can store a 1 or a 0 at any given time). A 32-bit bus is literally 32 wires in parallel that run from the CPU to a bunch of devices like Christmas lights around a house.

> There are two buses that we really care about in a computer: the address bus and the data bus. There's also a third signal that lets all the devices know whether the CPU is requesting data from an input (reading, like from the keyboard) or sending data to an output (writing, like to the monitor via the video card). The address bus is for the CPU to send location information, and the data bus is for the CPU to either write data to or read data from that location. Every device on the computer has a unique hard coded numerical location, or "address", literally determined by how the thing is wired up at the factory. In the case of an input/read operation, when it sends 0x1001A003 out on the address bus and the control signal notifies every device that it's a read operation, it's asking, "What is the data currently stored at location 0x1001A003?" If the keyboard happens to be identified by that particular address, and the user is pressing SPACE at this time, the keyboard says, "Oh, you're talking to me!" and sends back the ASCII code 0x00000020 (for "SPACE") on the data bus.

> What this means is that memory on a computer isn't just representing things like RAM and your hard drive. Actual human-scale devices like the keyboard and mouse and video card have their own memory locations too. But instead of writing a byte to a hard drive for storage, the CPU might write a byte representing some color and symbol to the monitor for display. There's an industry standard somewhere that says video memory must live in the address range beginning 0xb8000. In order for computers to be able to work out of the box, this means that the BIOS needs to be manufactured to assume video lives at that location, and the motherboard (which is where the bus is all wired up) has to be manufactured to route a 0xb8000 request to the video card. It's kind of amazing this stuff works at all! Anyway, "memory mapped hardware", or "memory mapping" for short, is the name of this technique.

The ‘word’ keyword in the context of x86_64 assembly specifically refers to 2 bytes, or 16 bits of data. This is for reasons of backwards compatibility.


Linking it together

```
ENTRY(start)

SECTIONS {
    . = 1M;

    .boot :
    {
        /* ensure that the multiboot header is at the beginning */
        *(.multiboot_header)
    }

    .text :
    {
        *(.text)
    }
}
```

`ENTRY(start)`: sets the ‘entry point’ for this executable. In our case, we called our entry point by the name people use: `start`.

`. = 1M;`: putting sections at the one megabyte mark. This is the conventional place to put a kernel, at least to start. Below one megabyte is all kinds of memory-mapped stuff. Remember the VGA stuff? It wouldn’t work if we mapped our kernel’s code to that part of memory... garbage on the screen!

`  .boot :`: create a section named boot. And inside of it... `*(.multiboot_header)` goes every section named `multiboot_header`.

Similar to `.text:` and `*(.text)`.

`$ ld --nmagic --output=kernel.bin --script=linker.ld multiboot_header.o boot.o`

Making an ISO

See the Makefile

The grub config file grub.cfg:

```
set timeout=0
set default=0

menuentry "intermezzOS" {
    multiboot2 /boot/kernel.bin
    boot
}
```

```
isofiles/
└── boot
    ├── grub
    │   └── grub.cfg
    └── kernel.bin
```

`$ grub-mkrescue -o os.iso isofiles`

`$ qemu-system-x86_64 -cdrom os.iso`

Automate it with `Makefile`.
