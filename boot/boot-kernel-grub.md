## multibook

https://os.phil-opp.com/multiboot-kernel/

## An article

https://news.ycombinator.com/item?id=12182156

**cool example in 2010**

https://github.com/rikusalminen/danjeros

**build kernel and boot using qemu and grub**

https://www.cs.vu.nl/~herbertb/misc/writingkernels.txt

Change elf to elf64 for nasm compiling.

Get stage1, stage2, fat_stage_1.5 from [here](https://www.aioboot.com/en/grub-legacy/) (or directly [grub_0.97-29ubuntu66_amd64.deb](http://mirrors.kernel.org/ubuntu/pool/main/g/grub/grub_0.97-29ubuntu66_amd64.deb).

Everything works but qemu can't really load kernel at stage 1.5.

