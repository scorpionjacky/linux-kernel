# linux-kernel

- Source Code
- Ancient Code
- [Tools](#tools)
- [Others](#others)

## Source Code

Current
- https://github.com/torvalds/linux

## Ancient Code

http://oldlinux.org/

0.12
- Build OK
  - https://github.com/sky-big/Linux-0.12
    - download disk image file [oldlinux.org](http://oldlinux.org/Linux.old/bochs/linux-0.11-devel-040923.zip)
    - qemu-system-x86_64.exe -fda Image -boot a -hda linux-0.11-devel-040923\hdc-0.11-new.img
- Cannot Build
  - https://github.com/huawenyu/oldlinux
    - also has asm code for boot/
  - https://github.com/ultraji/linux-0.12
  - https://github.com/honyyang/Linux-0.12
- Other
  - https://blog.csdn.net/qq_42138566/article/details/89765781
- Info
  - https://gunkies.org/wiki/Linux_0.12

0.11
- Build OK
  - https://github.com/yuan-xy/Linux-0.11
    - download disk image file [oldlinux.org](http://oldlinux.org/Linux.old/bochs/linux-0.11-devel-040923.zip)
    - qemu-system-x86_64.exe -fda Image -boot a -hda linux-0.11-devel-040923\hdc-0.11-new.img
- Others
  - https://github.com/voidccc/linux0.11
  - https://github.com/huawenyu/oldlinux
  - https://github.com/bolanlaike/Linux-0.01
- Info
  - https://gunkies.org/wiki/Linux_0.11

0.01
- Build OK
  - https://github.com/mariuz/linux-0.01
    - with some additional changes to 0.01 remake 3.5
  - https://github.com/YWHyuk/linux-kernel-0.01
    - change Makefile `Image` to:
      - dd bs=512 count=2880 if=/dev/zero of=floppy.img
      - dd bs=32 if=boot/boot of=floppy.img skip=1 conv=notrunc
      - dd bs=512 if=tools/system of=floppy.img skip=8 seek=1 conv=notrunc
      - sync
- Others
  - https://github.com/issamabd/linux-0.01-remake
  - https://github.com/liudonghua123/linux-0.01
  - [Linux 0.01 News](http://draconux.free.fr/os_dev/linux0.01_news.html) (Linux 0.01 remake)


0.00
- Working Examples
  - https://github.com/Yibo-Li/linux-0.00 (tested)
  - https://github.com/voidccc/linux0.00
    - need to change kernel.s with the following line:
      - `.global startup_32`
    - `qemu-system-x86_64.exe -drive format=raw,file=C:\dev\linux_os\Image.img,index=0,if=floppy`
- Not Working
  - https://github.com/issamabd/linux-0.00
    - has two branches
    - Won't compile
  - http://gunkies.org/wiki/Linux_0.00
- Not Tested
  - https://github.com/174high/Linux-0.00
- Otheres
  - Google [linux 0.00 github](https://www.google.com/search?q=linux+0.00+github&oq=linux+0.00+github)


## Tools

[gcc, libstdc++, glibc, binutils](https://www.reddit.com/r/linuxquestions/comments/1tghjd/what_is_the_relationship_between_gcc_libstdc/)

[GNU Tools](https://www.gnu.org/manual/manual.html)
  - [Make](https://www.gnu.org/software/make/manual/)
  - [Automake](https://www.gnu.org/software/automake/manual/)
  - [Binutils](https://sourceware.org/binutils/)
    - [*as*](https://sourceware.org/binutils/docs-2.35/as/index.html) (*gas*)
      - [@github](https://github.com/gitGNU/gnu_as)
      - [A primer on x86 assembly with GNU assembler](https://gist.github.com/AVGP/85037b51856dc7ebc0127a63d6a601fa)
  - [GCC](https://gcc.gnu.org/) (GNU Compiler Collection)
    - [@github](https://github.com/gcc-mirror/gcc) (mirror)

NASM (Netwide Assembler)
  - [Home](https://www.nasm.us/)
  - [@github](https://github.com/netwide-assembler/nasm)

MGW (Minimalist GNU for Windows)
  - [Home](http://www.mingw.org/)

## Language Reference

### C

- [Static Variables in C - GeeksforGeeks](https://www.geeksforgeeks.org/static-variables-in-c/)
- http://faculty.cs.niu.edu/~freedman/241/241notes/
  - http://faculty.cs.niu.edu/~freedman/241/241notes/241var2.htm
- http://www.mathcs.emory.edu/~cheung/Courses/255/Syllabus/1-C-intro/
  - [scope of static variables](http://www.mathcs.emory.edu/~cheung/Courses/255/Syllabus/1-C-intro/scope-static.html)
  - [extern](http://www.mathcs.emory.edu/~cheung/Courses/255/Syllabus/1-C-intro/scope.html)

## Others

1494|2006-11-07|5395338|ebooks1|A Heavily Commented Linux Kernel Source Code.(2004).cn.pdf|pack01|/preprocess|H:/eBooks/xpub/Pack01

- [The Linux Kernel Archives](https://www.kernel.org)
  - https://www.kernel.org/doc/
  - https://www.kernel.org/doc/html/latest/
  - https://www.kernel.org/doc/Documentation/x86/
  - [Kernel Hacking Guides](https://www.kernel.org/doc/html/latest/kernel-hacking/index.html)
- [0xAX/linux-insides](https://github.com/0xAX/linux-insides)
- Packt.-.Mastering Linux Kernel Development.-.(Nov 2017).-.978-1785883057
- Packt.-.Linux Device Drivers Development Develop Customized Drivers for Embedded Linux.-.(Oct 2017).-.978-1785280009
- CRC.-.The Art of Linux Kernel Design Illustrating the Operating System Design Principle and Implementation.-.(Apr 2014).-.978-1466518032
- Apress.-.Linux Kernel Networking Implementation and Theory.-.(Dec 2013).-.978-1430261964
- Addison-Wesley.-.Linux Kernel Development, 3ed.-.(Jul 2010).-.978-0672329463
- Prentice Hall.-.Essential Linux Device Drivers.-.(2008).-.0132396556
- OReilly.-.Linux Kernel in a Nutshell A Desktop Quick Reference.-.(Dec 2006).-.978-0596100797
- [Understanding the Linux Kernel, 3E] (2005)
- Prentice Hall.-.The Linux Kernel Primer A Top-Down Approach for x86 and PowerPC Architectures.-.(2005).-.978-0131181632
- Novell.-.Linux Kernel Development, 2ed.-.(Jan 2005).-.978-0672327209
- Linux Device Drivers, 3ed, OReilly (Feb 2005) 978-0596005900
  - Linux Device Drivers, 2ed, OReilly (Jun 2001) 978-0596000080
  - Linux Device Drivers, OReilly, (Feb 1998) 9781565922921
- [Linux i386 Boot Code HOWTO](https://tldp.org/HOWTO/Linux-i386-Boot-Code-HOWTO/index.html) (2004-01-23) @tldp
- [Linux Kernel 2.4 Internals](https://www.kernel.org/doc/mirror/lki-single.html) (Tigran Aivazian tigran@veritas.com 7 August 2002)
  - [Linux Kernel Internals](https://www.star.bnl.gov/~liuzx/lki/lki.html#toc1) (Tigran Aivazian tigran@veritas.com 20 December 2000)
- [Linux Kernel: Good beginners' tutorial](https://unix.stackexchange.com/questions/1003/linux-kernel-good-beginners-tutorial) @[unix.stackexchange](https://unix.stackexchange.com)
- [The Linux Kernel](https://tldp.org/LDP/tlk/tlk.html) @tldp
- [Linux Kernel Hackers' Guide](https://tldp.org/LDP/khg/HyperNews/get/khg.html) @tldp
- wikipedia
  - [Linux kernel](https://en.m.wikipedia.org/wiki/Linux_kernel)
  - [Linux kernel interfaces](https://en.m.wikipedia.org/wiki/Linux_kernel_interfaces)

[Write your own operating system](http://mirror.freedoors.org/Geezer-2/osd/index.htm)
- http://mirror.freedoors.org/Geezer-2/osd/boot/index.htm

https://eecs.wsu.edu/~cs460/cs560/booting
- https://eecs.wsu.edu/~cs460/cs560/booting.pdf

[bootsect.s Retired since v2.6](https://tonybai.com/2006/02/08/retired-bootsect/)

https://titanwolf.org/Network/Articles/Article?AID=7a69544f-e37f-4c3f-a294-842743dbd987#gsc.tab=0


https://blog.lse.epita.fr/2014/10/01/uefi-boot-stub-in-linux.html

https://0xax.gitbooks.io/linux-insides/content/Booting/

https://en.wikipedia.org/wiki/Linux_kernel

https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/

https://github.com/cfenollosa/os-tutorial

Chinese
- https://blog.csdn.net/chengwenyang/article/details/77417830
- https://blog.csdn.net/chenpu5887/article/details/100627321?utm_medium=distribute.pc_relevant.none-task-blog-title-8&spm=1001.2101.3001.4242

Syscalls
- https://en.wikipedia.org/wiki/System_call
- http://www.cpu2.net/linuxabi.html
- [How does a system call translate to CPU instructions?](https://stackoverflow.com/questions/5570893/how-does-a-system-call-translate-to-cpu-instructions)
- [The Definitive Guide to Linux System Calls](ps://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/) (Apr 2016)

xv6
- https://www.cs.columbia.edu/~junfeng/13fa-w4118/lectures/
- https://github.com/mit-pdos/xv6-public

https://jasonblog.github.io/note/qemu/72.html

https://50linesofco.de/post/2018-02-28-writing-an-x86-hello-world-bootloader-with-assembly


https://en.wikibooks.org/wiki/X86_Assembly/Bootloaders

Linux Kernel Internals (20 December 2000)
- https://www.star.bnl.gov/~liuzx/lki/lki.html
- https://www.star.bnl.gov/~liuzx/lki/lki-1.html

http://beefchunk.com/documentation/sys-programming/bootstraps/PC_Bootstrap_Loader_Programming_Tutorial.html

VeraCrypt is a free open source disk encryption software for Windows, Mac OSX and Linux.
- https://www.veracrypt.fr/en/Home.html
- https://www.veracrypt.fr/code/VeraCrypt/tree/src/Boot/Windows/BootSector.asm?id=a630fae22ce0c942af9abdff28b87609909012d2
- https://www.veracrypt.fr/code/VeraCrypt/tree/src/Boot/

GeeksOS 
- https://www.cs.umd.edu/~hollings/cs412/s03/prog1/

https://www.howtogeek.com/howto/31632/what-is-the-linux-kernel-and-what-does-it-do/
