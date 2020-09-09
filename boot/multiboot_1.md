# Writing an OS in Rust (First Edition) Philipp Oppermann's blog

A minimal Multiboot Kernel

Aug 18, 2015

https://os.phil-opp.com/multiboot-kernel/

Table of Contents
- Overview
- Multiboot
- The Boot Code
- Building the Executable
- Creating the ISO
- Booting
- Build Automation
- What's next?
- Footnotes

No longer updated! You are viewing the a post of the first edition of “Writing an OS in Rust”, which is no longer updated. You can find the second edition here.
This post explains how to create a minimal x86 operating system kernel using the Multiboot standard. In fact, it will just boot and print OK to the screen. In subsequent blog posts we will extend it using the Rust programming language.

I tried to explain everything in detail and to keep the code as simple as possible. If you have any questions, suggestions or other issues, please leave a comment or create an issue on Github. The source code is available in a [repository](https://github.com/phil-opp/blog_os/tree/first_edition_post_1/src/arch/x86_64), too.

Note that this tutorial is written mainly for Linux. For some known problems on OS X see the comment section and this issue. If you want to use a virtual Linux machine, you can find instructions and a Vagrantfile in Ashley Willams's [x86-kernel repository](https://github.com/ashleygwilliams/x86-kernel).

🔗Overview

When you turn on a computer, it loads the BIOS from some special flash memory. The BIOS runs self test and initialization routines of the hardware, then it looks for bootable devices. If it finds one, the control is transferred to its bootloader, which is a small portion of executable code stored at the device's beginning. The bootloader has to determine the location of the kernel image on the device and load it into memory. It also needs to switch the CPU to the so-called protected mode because x86 CPUs start in the very limited real mode by default (to be compatible to programs from 1978).

We won't write a bootloader because that would be a complex project on its own (if you really want to do it, check out Rolling Your Own Bootloader). Instead we will use one of the many well-tested bootloaders out there to boot our kernel from a CD-ROM. But which one?

🔗Multiboot

Fortunately there is a bootloader standard: the Multiboot Specification. Our kernel just needs to indicate that it supports Multiboot and every Multiboot-compliant bootloader can boot it. We will use the Multiboot 2 specification (PDF) together with the well-known GRUB 2 bootloader.

To indicate our Multiboot 2 support to the bootloader, our kernel must start with a Multiboot Header, which has the following format:

|Field|Type|Value|
| -- | -- | -- |
|magic number|u32|`0xE85250D6`
|architecture|u32|`0` for i386, `4` for MIPS
|header length|u32|total header size, including tags
|checksum|u32|`-(magic + architecture + header_length)`
|tags|variable|
|end tag|(u16, u16, u32)|`(0, 0, 8)`

Converted to a x86 assembly file it looks like this (Intel syntax):

```asm
section .multiboot_header
header_start:
    dd 0xe85250d6                ; magic number (multiboot 2)
    dd 0                         ; architecture 0 (protected mode i386)
    dd header_end - header_start ; header length
    ; checksum
    dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start))

    ; insert optional multiboot tags here

    ; required end tag
    dw 0    ; type
    dw 0    ; flags
    dd 8    ; size
header_end:
```

If you don't know x86 assembly, here is some quick guide:

- the header will be written to a section named .multiboot_header (we need this later)
- header_start and header_end are labels that mark a memory location, we use them to calculate the header length easily
- dd stands for define double (32bit) and dw stands for define word (16bit). They just output the specified 32bit/16bit constant.
- the additional 0x100000000 in the checksum calculation is a small hack1 to avoid a compiler warning

We can already assemble this file (which I called multiboot_header.asm) using nasm. It produces a flat binary by default, so the resulting file just contains our 24 bytes (in little endian if you work on a x86 machine):

```
> nasm multiboot_header.asm
> hexdump -x multiboot_header
0000000    50d6    e852    0000    0000    0018    0000    af12    17ad
0000010    0000    0000    0008    0000
0000018
```

🔗The Boot Code

To boot our kernel, we must add some code that the bootloader can call. Let's create a file named boot.asm:

```asm
global start

section .text
bits 32
start:
    ; print `OK` to screen
    mov dword [0xb8000], 0x2f4b2f4f
    hlt
```

There are some new commands:

- global exports a label (makes it public). As start will be the entry point of our kernel, it needs to be public.
- the .text section is the default section for executable code
- bits 32 specifies that the following lines are 32-bit instructions. It's needed because the CPU is still in Protected mode when GRUB starts our kernel. When we switch to Long mode in the next post we can use bits 64 (64-bit instructions).
- the mov dword instruction moves the 32bit constant 0x2f4b2f4f to the memory at address b8000 (it prints OK to the screen, an explanation follows in the next posts)
- hlt is the halt instruction and causes the CPU to stop

Through assembling, viewing and disassembling we can see the CPU Opcodes in action:

```
> nasm boot.asm
> hexdump -x boot
0000000    05c7    8000    000b    2f4b    2f4f    00f4
000000b
> ndisasm -b 32 boot
00000000  C70500800B004B2F  mov dword [dword 0xb8000],0x2f4b2f4f
         -4F2F
0000000A  F4                hlt
```

🔗Building the Executable

To boot our executable later through GRUB, it should be an ELF executable. So we want nasm to create ELF object files instead of plain binaries. To do that, we simply pass the ‑f elf64 argument to it.

To create the ELF executable, we need to link the object files together. We use a custom linker script named linker.ld:

```link
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

Let's translate it:

- start is the entry point, the bootloader will jump to it after loading the kernel
- . = 1M; sets the load address of the first section to 1 MiB, which is a conventional place to load a kernel2
- the executable will have two sections: .boot at the beginning and .text afterwards
- the .text output section contains all input sections named .text
- Sections named .multiboot_header are added to the first output section (.boot) to ensure they are at the beginning of the executable. This is necessary because GRUB expects to find the Multiboot header very early in the file.
- So let's create the ELF object files and link them using our new linker script:

```bash
> nasm -f elf64 multiboot_header.asm
> nasm -f elf64 boot.asm
> ld -n -o kernel.bin -T linker.ld multiboot_header.o boot.o
```

It's important to pass the -n (or --nmagic) flag to the linker, which disables the automatic section alignment in the executable. Otherwise the linker may page align the .boot section in the executable file. If that happens, GRUB isn't able to find the Multiboot header because it isn't at the beginning anymore.

We can use objdump to print the sections of the generated executable and verify that the .boot section has a low file offset:

```bash
> objdump -h kernel.bin
kernel.bin:     file format elf64-x86-64

Sections:
Idx Name      Size      VMA               LMA               File off  Algn
  0 .boot     00000018  0000000000100000  0000000000100000  00000080  2**0
              CONTENTS, ALLOC, LOAD, READONLY, DATA
  1 .text     0000000b  0000000000100020  0000000000100020  000000a0  2**4
              CONTENTS, ALLOC, LOAD, READONLY, CODE
```

Note: The ld and objdump commands are platform specific. If you're not working on x86_64 architecture, you will need to cross compile binutils. Then use x86_64‑elf‑ld and x86_64‑elf‑objdump instead of ld and objdump.

🔗Creating the ISO

All PC BIOSes know how to boot from a CD-ROM, so we want to create a bootable CD-ROM image, containing our kernel and the GRUB bootloader's files, in a single file called an ISO. Make the following directory structure and copy the kernel.bin to the right place:

```
isofiles
└── boot
    ├── grub
    │   └── grub.cfg
    └── kernel.bin
```

The grub.cfg specifies the file name of our kernel and its Multiboot 2 compliance. It looks like this:

```
set timeout=0
set default=0

menuentry "my os" {
    multiboot2 /boot/kernel.bin
    boot
}
```

Now we can create a bootable image using the command:

```bash
grub-mkrescue -o os.iso isofiles
```

Note: grub-mkrescue causes problems on some platforms. If it does not work for you, try the following steps:

- try to run it with --verbose
- make sure xorriso is installed (xorriso or libisoburn package)
- If you're using an EFI-system, grub-mkrescue tries to create an EFI image by default. You can either pass -d /usr/lib/grub/i386-pc to avoid EFI or install the mtools package to get a working EFI image
- on some system the command is named grub2-mkrescue

🔗Booting

Now it's time to boot our OS. We will use QEMU:

```
qemu-system-x86_64 -cdrom os.iso
```

Notice the green OK in the upper left corner. If it does not work for you, take a look at the comment section.

Let's summarize what happens:

1. the BIOS loads the bootloader (GRUB) from the virtual CD-ROM (the ISO)
1. the bootloader reads the kernel executable and finds the Multiboot header
1. it copies the .boot and .text sections to memory (to addresses 0x100000 and 0x100020)
1. it jumps to the entry point (0x100020, you can obtain it through objdump -f)
1. our kernel prints the green OK and stops the CPU

You can test it on real hardware, too. Just burn the ISO to a disk or USB stick and boot from it.

🔗Build Automation

Right now we need to execute 4 commands in the right order every time we change a file. That's bad. So let's automate the build using a Makefile. But first we should create some clean directory structure for our source files to separate the architecture specific files:

```
…
├── Makefile
└── src
    └── arch
        └── x86_64
            ├── multiboot_header.asm
            ├── boot.asm
            ├── linker.ld
            └── grub.cfg
```

The Makefile looks like this (indented with tabs instead of spaces):

```make
arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))

.PHONY: all clean run iso

all: $(kernel)

clean:
	@rm -r build

run: $(iso)
	@qemu-system-x86_64 -cdrom $(iso)

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	@rm -r build/isofiles

$(kernel): $(assembly_object_files) $(linker_script)
	@ld -n -T $(linker_script) -o $(kernel) $(assembly_object_files)

# compile assembly files
build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@
```

Some comments (see the [Makefile tutorial] if you don't know make):

- the $(wildcard src/arch/$(arch)/*.asm) chooses all assembly files in the src/arch/$(arch)` directory, so you don't have to update the Makefile when you add a file
- the patsubst operation for assembly_object_files just translates src/arch/$(arch)/XYZ.asm to build/arch/$(arch)/XYZ.o
- the $< and $@ in the assembly target are automatic variables
- if you're using cross-compiled binutils just replace ld with x86_64‑elf‑ld

Now we can invoke make and all updated assembly files are compiled and linked. The make iso command also creates the ISO image and make run will additionally start QEMU.

🔗What's next?

In the next post we will create a page table and do some CPU configuration to switch to the 64-bit long mode.

🔗Footnotes

1 The formula from the table, -(magic + architecture + header_length), creates a negative value that doesn't fit into 32bit. By subtracting from 0x100000000 (= 2^(32)) instead, we keep the value positive without changing its truncated value. Without the additional sign bit(s) the result fits into 32bit and the compiler is happy :).

2 We don't want to load the kernel to e.g. 0x0 because there are many special memory areas below the 1MB mark (for example the so-called VGA buffer at 0xb8000, that we use to print OK to the screen).

[Entering Long Mode »](https://os.phil-opp.com/entering-longmode/)

Comments (Archived)

Ali Shapal•vor 4 Jahren
great work in explaining how all the different pieces of hardware/software come together

Philipp Oppermann•vor 4 Jahren
Thank you!

Nitesh Chauhan•vor 4 Jahren
awesome... :) i am definitely trying this out today...

Georgiy Slobodenyuk•vor 4 Jahren
On mac OS X, for some reason,


dd - (0xe85250d6 + 0 + (header_end - header_start))
had no compiler warnings, while


dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start))
led to

multiboot_header.asm:7: warning: numeric constant 0x100000000 does not fit in 32 bits
Mac OS X 10.11.1
NASM version 0.98.40 (Apple Computer, Inc. build 11) compiled on Oct 5 2015

Philipp Oppermann•vor 4 Jahren
Well, that's unfortunate… Thank you for the hint, I opened an issue: https://github.com/phil-opp...

Philipp Oppermann•vor 4 Jahren
Did you try `brew install nasm` to upgrade to a 2.11.X version?

Arnaud Bailly•vor 4 Jahren
I found I had to do

nasm -felf64 boot.S

to generate correct code, after doing `brew install nasm`.

HTH

Tom Smeding•vor 4 Jahren
If (in my case on Mac OS X) grub-mkrescue (after you've installed it) gives the error "grub-mkrescue: warning: Your xorriso doesn't support `--grub2-boot-info'.", you just need to install xorriso. You probably don't have it at all yet.

Tom Yandell•vor 4 Jahren
For me (running it in an ubuntu docker container), grub-mkrescue silently fails until you add the -v flag - only with that can you see the error about xorriso (took me a lot of head-scratching to figure it out).

Philipp Oppermann•vor 4 Jahren
Thanks, I added a note about `--verbose`.

Reid•vor 4 Jahren
Do you have any instructions on how you got grub built on OS X? Can't get it to build successfully for the x86_64-elf target and the default EFI target won't work with qemu...

Tom Smeding•vor 4 Jahren
What are your exact problems? IIRC I built it from source as well, but don't remember exactly what I fixed. Stuff did error here and there, I think...

Reid•vor 4 Jahren
./rs_decoder.h:2:Unknown pseudo-op: .macosx_version_min
./rs_decoder.h:2:Rest of line ignored. 1st junk character valued 49 (1).
clang: error: assembler command failed with exit code 1 (use -v to see invocation)
make[3]: *** [boot/i386/pc/lzma_decompress_image-startup_raw.o] Error 1

6 versteckt
emk1024•vor 4 Jahren
This is an awesome series of blog posts!

If you don't see a green "OK", look for a "GRUB" message. If you don't see "GRUB", then the weak link is probably grub-mkrescue. Two common failure modes:

1. If your grub-mkrescue isn't installed correctly, it may silently do nothing or make bad ISO files. Try mounting your ISO file to make sure that it has your kernel and grub.cfg.

2. If you run Linux on an EFI machine, grub-mkrescue will produce EFI boot images that don't work with BIOS-based systems like QEMU. To fix this, see this article, which recommends installing grub-pc-bin and running:

grub-mkrescue /usr/lib/grub/i386-pc -o myos.iso isodir
Philipp Oppermann•vor 4 Jahren
Thank you, I didn't know about the EFI issue...

Jon•vor 3 Jahren
Thanks, that second tip saved me.

Anonym•letztes Jahr
Thank you! This really helped.

Tom Yandell•vor 4 Jahren
On OSX and found I needed x86_64‑elf‑ld and x86_64‑elf‑objdump. With macports was as simple as:

> sudo port install x86_64-elf-gcc

Arnaud Bailly•vor 4 Jahren
This is definitely fun! I tried to do this from my Mac OS X (Yosemite) and could not properly boot my fresh ISO disk. Compilation works fine, I have installed a cross-compiler for x86_64-elf architecture, compiled grub following instructions here https://wiki.osdev.org/GRUB_...... I generate a correct ISO file (checked it by mounting using Disk Utility) but it does not boot and I cannot see the GRUB message.

Not sure how to troubleshoot this issue.... I suspect this might be a problem with incorrect format in grub as the last stage of compilation shows this message:

../grub/configure --build=x86_64-elf --target=x86_64-elf --disable-werror TARGET_CC=x86_64-elf-gcc TARGET_OBJCOPY=x86_64-elf-objcopy TARGET_STRIP=x86_64-elf-strip TARGET_NM=x86_64-elf-nm TARGET_RANLIB=x86_64-elf-ranlib LD_FLAGS=/usr/local/opt/flex/ CPP_FLAGS=/usr/local/opt/flex/include/

[..]

config.status: linking ../grub/include/grub/i386 to include/grub/cpu
config.status: linking ../grub/include/grub/i386/pc to include/grub/machine
config.status: executing depfiles commands
config.status: executing po-directories commands
config.status: creating po/POTFILES
config.status: creating po/Makefile
*******************************************************
GRUB2 will be compiled with following components:
Platform: i386-pc
With devmapper support: No (need libdevmapper header)
With memory debugging: No
With disk cache statistics: No
With boot time statistics: No
efiemu runtime: Yes
grub-mkfont: Yes
grub-mount: No (need FUSE headers)
starfield theme: No (No DejaVu found)
With libzfs support: No (need zfs library)
Build-time grub-mkfont: No (no fonts)
Without unifont (no build-time grub-mkfont)
With liblzma from -llzma (support for XZ-compressed mips images)
*******************************************************

I don't know what the i386-pc refer too, but if this is the target platform then it's probably incorrect. Note that I tried to boot using qemu-system-i386 but to no avail.

Regards,

Arnaud Bailly•vor 4 Jahren
Forget it: grub-mkrescue was not correctly installed so it failed to add needed boot files.

Thanks again for sharing this!

Chris Cerami•vor 4 Jahren
I'm having an issue where x86_64-elf-gcc isn't found when I try to configure grub, and when I checked I see that it's not included in binutils with the other x86_64-elf tools. How did get x86_64-elf-gcc on OS X?

Arnaud Bailly•vor 4 Jahren
It should be as simple as `brew install x86_64-elf-gcc x86_64-elf-binutils`

jcaudle•vor 4 Jahren
It's probably worth noting that you'll need to do `brew tap sevki/gcc_cross_compilers` or `brew tap alexcrichton/formula` to get these formulae. (Sevki's tap has newer cross compilers)

George•vor 4 Jahren
What would happen if we didn't put hlt? Would the cpu start reading random bytes and execute them as code? I tried without hlt and qemu seems to go into an infinite boot loop, but I'm just wondering what's going on.

Philipp Oppermann•vor 4 Jahren
Yes, that exactly what happens. The CPU simply tries to read the next instruction, even if it doesn't exist, until it causes some exception. QEMU can print these exceptions, the "Setup Rust" post explains how. I just tried it and it hits an Invalid Opcode exception at some point because some memory is no valid instruction.

Bonus: You can use GDB to disassemble the “code” behind the start label. You need to start `qemu-system-x86_64 -hda build/os-x86_64.iso -s -S` in one console and `gdb build/kernel-x86_64.bin` in another. Then you need the following gdb commands:

- `set architecture i386` because we are still in 32-bit mode
- `target remote :1234` to connect to QEMU
(- `disas /r start,+250` to disassemble the 250 bytes after the `start` label. Everything will be 0 as GRUB did not load our kernel yet)
- `break start` to set a breakpoint at `start`
- `continue` to continue execution until start is reached. Now the kernel is loaded and we can use
- `disas /r start,+250` to disassemble the 250 bytes after the `start` label

Then you can look at the faulting address you got from the QEMU debugging to see your invalid instruction. For me it seems to be an `add (%eax),%al` with the Opcode `02 00`.

George•vor 3 Jahren
I'm late in replying but just wanted to say thanks so much! It's really neat to learn about something that I used to believe only experts could get into.

Sanjiv•vor 4 Jahren
oh! What a wonderful article to read!

Philipp Oppermann•vor 4 Jahren
Thank you :)

Lifepillar•vor 4 Jahren
Nice post! I am on OS X, but I find it easier to use Linux for this assembly stuff. Using VirtualBox, I have created a minimal Debian machine running an SSH server and with a folder shared between the OS X host and the Debian guest. So, I may install all the needed tools and cross-compile in Debian and have the final .iso accessible in OS X (to use it with QEMU), all of this while working in Terminal.app as usual.

As a side note, I had to set LDEMULATION="elf_x86_64" before linking, because I was getting this error: `ld: i386:x86-64 architecture of input file `multiboot_header.o' is incompatible with i386 output`. This may be because I have used Debian's 32-bit PC netinst iso instead of the 64-bit version.

Philipp Oppermann•vor 4 Jahren
Thanks for sharing your experiences! There is an issue about Mac OS support, but it seems like using a virtual machine is the easiest way…

Robert Huang•vor 3 Jahren
Man this is too fucking awesome!

Dmitry Nikolayev•vor 3 Jahren
On my system and on some others grub-makerescue is actually called grub2-makerescue and should be represented accordingly in the makefile. Perhaps this merits a comment in the text since I was not alone (https://www.reddit.com/r/os... in spending some time trying to figure out what was happening after a rather meaningless error message from make.

Philipp Oppermann•vor 3 Jahren
Thanks! I opened an issue.

GW seo•vor 3 Jahren
When I run grub-mkrescue I got no output an just silence

after install xorriso I got error like this
-----
xorriso 1.3.2 : RockRidge filesystem manipulator, libburnia project.

Drive current: -outdev 'stdio:os.iso'

Media current: stdio file, overwriteable

Media status : is blank

Media summary: 0 sessions, 0 data blocks, 0 data, 861g free

Added to ISO image: directory '/'='/tmp/grub.pI5jyq'

xorriso : UPDATE : 276 files added in 1 seconds

Added to ISO image: directory '/'='/path/to/my/work/isofiles'

xorriso : FAILURE : Cannot find path '/efi.img' in loaded ISO image

xorriso : UPDATE : 280 files added in 1 seconds

xorriso : aborting : -abort_on 'FAILURE' encountered 'FAILURE'

-----

and I search for resolve this error, I arrive here[ https://bugs.archlinux.org/42334 ]

after isntall mtools, grub-mkrescue create os.iso

Phil•vor 3 Jahren
After creating the iso, I can boot to it on QEMU with no problem. Even burning it on to a disk and booting on a different machine works like a charm. However, I am having trouble getting it on to an USB thumb drive. I have tried packing it on to a USB with UNetbootin, but as soon as the UNetbootin screen appears after booting to the USB device, (The OS selection screen, giving you the options [Default] and [my_os]), nothing happens. I can select either of those options, but nothing happens.

EDIT: Got it to work using the command line tool dd!

Philipp Oppermann•vor 3 Jahren
I just wanted to suggest dd! For the record, the command is sudo dd if=build/os.iso of=/dev/sdX && sync where sdX is the device name of your USB stick. It overwrites everything on that device, so be careful to choose the correct device name.

Phil•vor 3 Jahren
Yes, I noticed that in the documentation, had me worried for a second ;-)

liveag•vor 3 Jahren
@phil_opp:disqus i created a GitHub repository where i work through your great guide step-by-step. It is located here: https://github.com/peacememories/rust-kernel-experiments
Please let me know if there are problems with the attribution. =)

Philipp Oppermann•vor 3 Jahren
Great! Let me know if you find any rough edges :).

mopp•vor 3 Jahren
Thanks you for your great articles.
I have created my OS in Rust, and these are really useful for me.
I have been revising my OS based on your articles.
Also, I have been writing an article which is similar to your
http://mopp.github.io/articles/os/os00_intro

I added link into my articles to this website.
If you feel unpleasant, please tell me and I will remove it.

Thanks

Philipp Oppermann•vor 3 Jahren
Thanks! I don't speak Japanese, so I can only read the rough google translation. However, your article seems to be a really good and introduction to OS development!

mopp•vor 3 Jahren
Many thanks :)
I have been looking forward to your new articles !

Nick•vor 3 Jahren
I really enjoyed your accessible blog format and your awesome osdev tutorials!
I was inspired by your articles and decided to write my own :)
Let me know what you think.

http://tutorialsbynick.com/...

Thanks,
Nick

Philipp Oppermann•vor 3 Jahren
It's awesome! I really like that you start without a bootloader and interact with the BIOS directly in real mode. I never programmed at this level, so it was a really great read!

jpmrno•vor 3 Jahren
If having trouble installing Binutils or GRUB, here are some brew packages:

BINUTILS:
'brew install jpmrno/apps/crossyc --without-gcc'

GRUB (this will install everything needed):
'brew install jpmrno/apps/grub'

Hope it helps!

Antonio•vor 3 Jahren
Hi guys if you want to boot the kernel in VirtualBox just modify the grub cfg file by setting the following variable properly, check https://www.gnu.org/softwar... for the options.

GRUB_TERMINAL_OUTPUT

Andrii Zymohliad•vor 3 Jahren
This blog is just a treasure! I'm so happy that I found it. Thank you so much Phil!

By the way, my Arch Linux is booted in legacy BIOS mode (my BIOS doesn't even support EFI), but without '-d /usr/lib/grub/i386-pc/' grub-mkrescue didn't work for me.

P.S. Aside from this project, I think I will refer to your Makefile lot of times in future just to learn techniques that you used. I think it is the shortest example of so many Makefile best practices.

Philipp Oppermann•vor 3 Jahren
Thanks a lot! :)

Unfortunately I have no idea what's the problem here. I've never had this error.

Andrii Zymohliad•vor 3 Jahren
Ough.. probably you replied to first edition of my comment, but I didn't reload the page and didn't see your reply. Then I found my mistake (I put grub directory into the root of image, not into boot directory). And while thinking that nobody have seen my comment yet I edited it and removed the question about error. Sorry for my careless.

Philipp Oppermann•vor 3 Jahren
No worries! Good to hear that you could fix the error.

Andrey Zloy•vor 3 Jahren
Just perfect. Thnx!

Кирилл Царёв•vor 3 Jahren
Why for the development of the core operation system, the language Rust? Why not C++? Does Rust have such opportunities as in C++?

Philipp Oppermann•vor 3 Jahren
Rust aims to be comparable to C++, both it terms of capabilities and in terms of performance. However, it has some great advantages over C++:

The greatest advantage of Rust is its memory safety. It prevents common bugs such as use after free or dangling pointers at compile time. So you get the safety of a garbage collected language, but without garbage collection. In fact, the safety guarantees go even further: The compiler also prevents data races and iterator invalidation bugs. So we should get a much safer kernel compared to C++.

(One caveat: Sometimes we need unsafe blocks for OS development, which weaken some safety guarantees. However, we try to use them only when it's absolutely needed and try to check them thoroughly.)

Another advantage of Rust is the great type system. It allows us to create powerful, generic abstractions, even for low level things such as page tables.

The tooling is great, too. Rust uses a package manager called “cargo”, which makes it easy to add various libraries to our project. Cargo automatically downloads the correct version and compiles/links it. Thus, we can use awesome libraries such as x86 easily.

Кирилл Царёв•vor 3 Jahren
Interesting... so what Rust is to replace C++, since he has so many advantages over C++?

Philipp Oppermann•vor 3 Jahren
so what Rust is to replace C++
Sorry, I don't understand this question. Could you rephrase it?

Andrey Zloy•vor 3 Jahren
Its easy to link kernel on Ubuntu 32-bit. Just need to add -m elf_x86_64 option to linker.
ld --nmagic -m elf_x86_64 -o kernel.bin -T linker.ld multiboot_header.o boot.o

Lonami•vor 2 Jahren
For anyone else struggling with "Boot failed: Could not read from CDROM (code 0009)", you need to install `grub-pc-bin` and then regenerate the .iso. Solution from here: http://intermezzos.github.io/book/appendix/troubleshooting.html#could-not-read-from-cdrom-code-0009.

By the way, I'm loving the tutorial style. Very clear, thank you!

Philipp Oppermann•vor 2 Jahren
Thanks so much!

Philip•letztes Jahr
I love you

skierpage•vor 2 Jahren
This is completely awesome!

YMMV but FWIW in Fedora 25, I needed to install three packages, `sudo dnf install nasm xorriso qemu-system-x86`. The last one installs fewer packages than installing "qemu" which adds two dozen ARM, m68k, S390, sparc, ... emulators as well 8-)

I find the example displays "OK" fine, but it erases the console before this so the boot messages disappear. I'm not sure if the fix lies in grub configuration or the qemu command line.

It is interesting to look at the contents of the CD-ROM image, though it mostly reveals the complexity of the GRUB bootloader. I used `mkdir temp_mount && sudo mount -t iso9660 -o loop os.iso temp_mount` then looked around in temp_mount.

Harry Rigg•vor 2 Jahren
I had 2 issues with making the iso. First, there was no output file, yet grub-mkrescue didn't complain, I fixed this by running "apt install xorriso" (Ubuntu). The other issue was that qemu couldn't read the cdrom (error 0009), fixed that one by running "apt install grub-pc-bin". Hope this helps some of you... and thanks for the awesome post Phil :)

Mrvan•letztes Jahr
How to shutdown?

Philipp Oppermann•letztes Jahr
See https://wiki.osdev.org/Shutdown

M. Wagner•letztes Jahr
The Makefile doesn't work for me. It gives only the error No rule to make target ' build/arch/x86_64/boot.o' needed by 'build/kernel-x86_64.bin'. I don't know what's going wrong....

Philipp Oppermann•letztes Jahr
It seems like there is some problem with this lines:

build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
  
Do you have a file named build/arch/x86_64/boot.asm? For debugging, you could use explicit names instead of the wildcards (%):

build/arch/$(arch)/boot.o: src/arch/$(arch)/boot.asm
  
(Note that you need to copy this rule for every .asm file without wildcards.)

Anonym•letztes Jahr
I'm interested whether it would run on actual hardware, with a real CD. I doubt anyone tried it though...

Philipp Oppermann•letztes Jahr
Yes, it works on real hardware! If not, please file an issue.

Dendyard•letztes Jahr
Lot of tutorials together. Thanks man (y)

Darryl Rees•letztes Jahr
This is incredible, just fantastic..

I did have a couple of hiccups following along using Win10 WSL on a UEFI PC, maybe these details can be folded in to the tutorial?

1) Couldn't boot QEMU with emulated video device

warning: TCG doesn't support requested feature: CPUID.01H:ECX.vmx [bit 5]

  Could not initialize SDL(No available video device) - exiting
  
Solution: Use -curses option for qemu

qemu-system-x86_64 -curses -cdrom os-x86_64.iso

2) Could not boot from ISO (on a UEFI system)

  Booting from DVD/CD...

   Boot failed: Could not read from CDROM (code 0004)

                         Booting from ROM...
  
Solution: sudo -S apt-get install grub-pc-bin

Naad•letztes Jahr
I am having the same issue as you have mentioned in number one. It says warning: TCG doesn't support requested feature: CPUID.01H:ECX.vmx [bit 5] And it is not printing out OK, I tried with the -curses option for qemu but not working.

Myst•letztes Jahr
I'm trying to do this, but I can't get the OK to actually display and I've kind of ran out of ideas. Trying to run with QEMU on Arch Linux.

Things I've tried: Adding the multiboot tag that should tell grub I want a text mode, 80x25. Just gives me a black screen, instead of saying "Booting 'my os'"

Switching grub to text mode with every possible switch I can find that looks related, with and without ^. Just gives me a black screen for all of them too. I can confirm my code actually seems to be executed - or, at least, hits the hlt instruction. Just that there's no output, which makes me think VGA problems, hence me trying all of the above. That seems to leave trying to parse the multiboot header or something, and that seems like... something I don't really want to try to do in assembly, including pushing it over assembly? I don't really want to move unless this works, though, because I see you still are using text mode extensively further on. :/

Myst•letztes Jahr
...Never mind. I just figured out, and it was a very tiny mistake. I accidentally typed 0xb800 instead of 0xb8000, so, of course, no output ever because I was copying to the wrong region of memory.

Person•letztes Jahr
RIP windows users

Anonym•vor 11 Monaten
Hi. Thanks for write, but i have an error when i run it in qemu - "error: no multiboot header found, error: you need to load kernel first". Whats wrong?

Philipp Oppermann•vor 11 Monaten
It means that GRUB couldn't find a multiboot header at the beginning of your kernel. So either your multiboot header is invalid (maybe a typo somewhere?) or it is not at the beginning of the file (is your linker script correct? did you use the --nmagic flag?).

Anonym•vor 11 Monaten
I just found this and it is great. Clear, practical explanations without fuss but that don't hide what's going on. That's perfect for how I like my tech explanations

Philipp Oppermann•vor 11 Monaten
Thanks so much!

Aswani Kumar•vor 11 Monaten
Thank you so much for the article. It is of great help to understand the basics of developing OS. Especially the in hand experience.

Philipp Oppermann•vor 11 Monaten
Thanks! Glad that it's useful to you :)

Fabio•vor 10 Monaten
Thank you for this series, it's exceptional! Clear, deep into details, and fascinating :)

Philipp Oppermann•vor 10 Monaten
Thank you :)

Anonym•vor 7 Monaten
For anyone trying to push themselves into using the GNU assembler (i.e. as), if you're getting "no multiboot header" errors with QEMU, put the line:

.align 8

before the end tags.

windows technical support•vor 5 Monaten
is it possible to manipulate the windows kernel. Which language is used in developing windows kernel?

© 2017. All rights reserved. Contact
