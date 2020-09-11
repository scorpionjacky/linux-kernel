# Kernel Booting

The handover from the bootloader to the kernel necessarily involves some architecture-specific considerations such as memory addresses and register use. Consequently, the place to look is in the architecture-specific directories (`arch/*`). Furthermore, handover from the bootloader involves a precise register usage protocol which is likely to be implemented in assembler. The kernel even has different entry points for different bootloaders on some architectures.

For example, on x86, the entry point is in [`arch/x86/boot/header.S`](http://lxr.free-electrons.com/source/arch/x86/boot/header.S?v=3.16) (I don't know of other entry points, but I'm not sure that there aren't any). The real entry point is [the `_start` label at offset 512 in the binary](http://lxr.free-electrons.com/source/arch/x86/boot/header.S?v=3.16#L290). The 512 bytes before that can be used to make a [master boot record](http://en.wikipedia.org/wiki/Master_Boot_Record) for an IBM PC-compatible BIOS (in the old days, a kernel could boot that way, but now this part only displays an error message). The `_start` label starts some fairly long processing, in [real mode](http://en.wikipedia.org/wiki/Real_mode), first in assembly and [then](http://lxr.free-electrons.com/source/arch/x86/boot/header.S?v=3.16#L509) in [`main.c`](http://lxr.free-electrons.com/source/arch/x86/boot/main.c?v=3.16#L135). At some point the initialization code [switches to protected mode](http://lxr.free-electrons.com/source/arch/x86/boot/pm.c?v=3.16#L104). I think this is the point where decompression happens if the kernel is [compressed](http://lxr.free-electrons.com/source/arch/x86/boot/compressed/?v=3.16); then control reaches [`startup_32`](http://lxr.free-electrons.com/source/arch/x86/kernel/head_32.S?v=3.16#L80) or [`startup_64`](http://lxr.free-electrons.com/source/arch/x86/kernel/head_32.S?v=3.16#L45) in `arch/x86/kernel/head_*.S` depending on whether this is a 32-bit or 64-bit kernel. After more assembly, [`i386_start_kernel` in `head32.c`](http://lxr.free-electrons.com/source/arch/x86/kernel/head32.c?v=3.16#L32) or [`x86_64_start_kernel` in `head64.c`](http://lxr.free-electrons.com/source/arch/x86/kernel/head64.c?v=3.16#L140) is invoked. Finally, the architecture-independent [`start_kernel` function in `init/main.c`](http://lxr.free-electrons.com/source/init/main.c#L501) is invoked.

`start_kernel` is where the kernel starts preparing for the real world. When it starts, there is only a single CPU and some memory (with virtual memory, the MMU is already switched on at that point). The code there sets up memory mappins, initializes all the subsystems, sets up interrupt handlers, starts the scheduler so that threads can be created, starts interacting with peripherals, etc.

The kernel has other entry points than the bootloader: entry points when enabling a core on a multi-core CPU, interrupt handlers, system call handlers, fault handlers, …

Try looking at `start_kernel()` in [`/init/main.c`](http://lxr.free-electrons.com/source/init/main.c#L501). This is the function that is called by the boot-loader after it has setup some basic facilities such as memory paging.

For more context: [wikipedia Linux startup process](http://en.wikipedia.org/wiki/Linux_startup_process).

## Links

- [Kernel Boot Process](https://0xax.gitbooks.io/linux-insides/content/Booting/)
  - [@github](https://github.com/0xAX/linux-insides/tree/master/Booting)
- https://gilesbathgate.com/2008/04/01/how-to-write-an-operating-system/
  - https://gilesbathgate.com/2009/11/25/how-to-write-an-operating-system-part-2/
- http://mikeos.sourceforge.net/write-your-own-os.html
- http://comet.lehman.cuny.edu/jung/cmp426697/LinuxMM.pdf
- [JamesM's kernel development tutorials](http://www.jamesmolloy.co.uk/tutorial_html/)
- [create small disk image with large partitions](https://unix.stackexchange.com/questions/216570/how-do-i-create-small-disk-image-with-large-partitions)
- [An article](https://news.ycombinator.com/item?id=12182156)
- A minimal Multiboot Kernel, Series, in Rust
  - [Part 1: A minimal Multiboot Kernel](multiboot_1.md) ***This works!***
  - [Part 2: Entering Long Mode](multiboot_2.md)
  - [Updated Series](https://os.phil-opp.com/)
- [build kernel and boot using qemu and grub](https://www.cs.vu.nl/~herbertb/misc/writingkernels.txt)
  - Everything works but qemu can't really load kernel at stage 1.5.
  - Need to change `elf` to `elf64` for `nasm` compiling.
  - Get stage1, stage2, fat_stage_1.5 from [here](https://www.aioboot.com/en/grub-legacy/) (or directly [grub_0.97-29ubuntu66_amd64.deb](http://mirrors.kernel.org/ubuntu/pool/main/g/grub/grub_0.97-29ubuntu66_amd64.deb).
- cool example in 2010
  - https://github.com/rikusalminen/danjeros
  - issues with compiling. `ld` cannot find symbols on multiboot_header.o and start.o
- mkernel
  - [Kernel 101 – Let’s write a Kernel](https://github.com/arjun024/mkernel)
  - [Kernel 201 - Let’s write a Kernel with keyboard and screen support](https://github.com/arjun024/mkeykernel)
