# Kernel Booting

The handover from the bootloader to the kernel necessarily involves some architecture-specific considerations such as memory addresses and register use. Consequently, the place to look is in the architecture-specific directories (`arch/*`). Furthermore, handover from the bootloader involves a precise register usage protocol which is likely to be implemented in assembler. The kernel even has different entry points for different bootloaders on some architectures.

For example, on x86, the entry point is in [`arch/x86/boot/header.S`](https://elixir.bootlin.com/linux/latest/source/arch/x86/boot/header.S) (I don't know of other entry points, but I'm not sure that there aren't any). The real entry point is [the `_start` label at offset 512 in the binary](https://elixir.bootlin.com/linux/latest/source/arch/x86/boot/header.S#L290). The 512 bytes before that can be used to make a [master boot record](http://en.wikipedia.org/wiki/Master_Boot_Record) for an IBM PC-compatible BIOS (in the old days, a kernel could boot that way, but now this part only displays an error message). The `_start` label starts some fairly long processing, in [real mode](http://en.wikipedia.org/wiki/Real_mode), first in assembly and [then](http://lxr.free-electrons.com/source/arch/x86/boot/header.S?v=3.16#L509) in [`main.c`](http://lxr.free-electrons.com/source/arch/x86/boot/main.c?v=3.16#L135). At some point the initialization code [switches to protected mode](http://lxr.free-electrons.com/source/arch/x86/boot/pm.c?v=3.16#L104). I think this is the point where decompression happens if the kernel is [compressed](http://lxr.free-electrons.com/source/arch/x86/boot/compressed/?v=3.16); then control reaches [`startup_32`](https://elixir.bootlin.com/linux/latest/source/arch/x86/boot/compressed/head_32.S#L80) or [`startup_64`](https://elixir.bootlin.com/linux/latest/source/arch/x86/boot/compressed/head_64.S#L45) in `arch/x86/kernel/head_*.S` depending on whether this is a 32-bit or 64-bit kernel. After more assembly, [`i386_start_kernel` in `head32.c`](https://elixir.bootlin.com/linux/latest/source/arch/x86/kernel/head32.c#L32) or [`x86_64_start_kernel` in `head64.c`](https://elixir.bootlin.com/linux/latest/source/arch/x86/kernel/head64.c#L140) is invoked. Finally, the architecture-independent [`start_kernel` function in `init/main.c`](https://elixir.bootlin.com/linux/latest/source/init/main.c#L501) is invoked.

`start_kernel` is where the kernel starts preparing for the real world. When it starts, there is only a single CPU and some memory (with virtual memory, the MMU is already switched on at that point). The code there sets up memory mappins, initializes all the subsystems, sets up interrupt handlers, starts the scheduler so that threads can be created, starts interacting with peripherals, etc.

The kernel has other entry points than the bootloader: entry points when enabling a core on a multi-core CPU, interrupt handlers, system call handlers, fault handlers, …

Try looking at `start_kernel()` in [`/init/main.c`](https://elixir.bootlin.com/linux/latest/source/init/main.c#L501). This is the function that is called by the boot-loader after it has setup some basic facilities such as memory paging.

For more context: [wikipedia Linux startup process](http://en.wikipedia.org/wiki/Linux_startup_process).

---

Best of the best: [Linux Insides](https://0xax.gitbooks.io/linux-insides/content/Booting/)

Some explaination on head.S here: [Inside the Linux boot process](https://developer.ibm.com/technologies/linux/articles/l-linuxboot/) May 31, 2006

Summary of POST, BIOS boot loading, GRUB 2 multi-stage loading.

https://opensource.com/article/17/2/linux-boot-and-startup

Everything explained here: https://en.wikipedia.org/wiki/Linux_startup_process, but seems using a little bit older kernel version?

https://gyires.inf.unideb.hu/GyBITT/20/ch02.html

---

Hardware: interrups, [pic](https://en.wikipedia.org/wiki/Programmable_interrupt_controller)/[apic](https://en.wikipedia.org/wiki/Advanced_Programmable_Interrupt_Controller)

[smp](http://download.xskernel.org/docs/processors/multiprocessing/smp.html), good stuff [there](http://download.xskernel.org)

[Linux SMP/Multicore](https://technolinchpin.wordpress.com/2015/11/05/linux-smp-and-multicore/) | [IBM Linux SMP](https://www.ibm.com/developerworks/library/l-linux-smp)

https://www.linuxsecrets.com/elinux-wiki/images/4/43/Understanding_And_Using_SMP_Multicore_Processors_Anderson.pdf

https://blog.acolyer.org/2016/04/26/the-linux-scheduler-a-decade-of-wasted-cores/

https://www.esol.com/embedded/multicore_manycore2.html

[QNX SMP](http://www.qnx.com/developers/docs/7.1/#com.qnx.doc.neutrino.sys_arch/topic/smp.html)

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_for_real_time/8/html/reference_guide/chap-hardware_interrupts

---

backup MBR:
`sudo dd if=/dev/sda of=mbr_old bs=512 count=1`

LBA-address of the kernel-image
`sudo hdparm --fibmap /boot/vmlinuz-3.4.6-2.fc17.x86_64`

Update the current_lba field of the boot file accordingly. *Note: The image can only be booted if the image file is NOT fragmented.*

```bash
nasm bootloader.asm -o bootloader.bin
sudo dd if=bootloader.bin of=/dev/sda bs=446 count=1
```

---

## Links

https://intermezzos.github.io/book/first-edition/creating-our-first-crate.html

http://www.osdever.net/tutorials/

https://github.com/perlun/cocos

long mode
- https://wiki.osdev.org/Setting_Up_Long_Mode#Detection_of_CPUID
- https://wiki.osdev.org/Entering_Long_Mode_Directly

https://www.bookstack.cn/read/tinyclub-elinux/dev_portals-Real_Time-Real_Time.md

[minimal bootloader](https://github.com/Stefan20162016/linux-insides-code/blob/master/bootloader.asm)

https://www.cs.rutgers.edu/~pxk/416/notes/
- https://www.cs.rutgers.edu/~pxk/416/notes/02-boot.html

[Linux Kernel Tracing](https://github.com/Stefan20162016/tracing)

[eduOS](https://rwth-os.github.io/eduOS/) -> [github](https://github.com/RWTH-OS/eduOS)

http://3zanders.co.uk/2017/10/13/writing-a-bootloader/

- https://github.com/egormkn/mbr-boot-manager
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

https://github.com/cirosantilli/x86-bare-metal-examples
