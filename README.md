# linux-kernel

- Source Code
- Alternatives
- Ancient Code
- [Tools](#tools)
- [Others](#others)

## Source Code

- Linux
  - [@github](https://github.com/torvalds/linux), earliest version: tag [v2.6.28-rc7](https://github.com/torvalds/linux/tree/v2.6.28-rc7)
    - [2.6.28](https://github.com/torvalds/linux/tree/v2.6.28), [2.6.39](https://github.com/torvalds/linux/tree/v2.6.39)
    - [3.0](https://github.com/torvalds/linux/tree/v3.0), [3.2](https://github.com/torvalds/linux/tree/v3.2), [3.8](https://github.com/torvalds/linux/tree/v3.8)
    - [4.0](https://github.com/torvalds/linux/tree/v4.0), [4.3](https://github.com/torvalds/linux/tree/v4.3)
    - [5.0](https://github.com/torvalds/linux/tree/v5.0), [5.8](https://github.com/torvalds/linux/tree/v5.8)
  - [Kernels @kernel.org](https://mirrors.edge.kernel.org/pub/linux/kernel/)
  - [Linux kernel version history](https://en.wikipedia.org/wiki/Linux_kernel_version_history)
- old linux @kernel.googlesource
  - [2.6.11-3.10.108](https://kernel.googlesource.com/pub/scm/linux/kernel/git/wtarreau/linux-stable/+refs)
  - [0.01 - 1](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/)
- Linux Variations
  - [illumos](https://github.com/illumos/illumos-gate)
- Grub2 [@github](https://github.com/rhboot/grub2)

LXR
- [Missing Link Electronics](https://lxr.missinglinkelectronics.com/linux)
- https://elixir.bootlin.com/linux/0.01/source
- FreeBSD and Linux Kernel [Cross-Reference](http://fxr.watson.org/)
  - [Linux 2.6](http://fxr.watson.org/fxr/source/?v=linux-2.6)
- [Linux Cross Reference (LXR)](http://lxr.linux.no/)
- [TOMOYO Linux Cross Reference Linux](http://tomoyo.osdn.jp/cgi-bin/lxr/source)

## Linux Alternatives

https://en.wikipedia.org/wiki/Lions'_Commentary_on_UNIX_6th_Edition,_with_Source_Code

FreeBSD/OpenBSD

https://www.minix3.org/

https://pdos.csail.mit.edu/6.828/2012/xv6.html

FreeRTOS
- https://www.freertos.org/
- https://github.com/FreeRTOS/FreeRTOS

[GNU Hurd](https://github.com/joshumax/hurd)
  - [GNU Mach](https://github.com/flavioc/gnumach)

## KBuild

Linux Kernel Makefile [v5.8 @github[(https://github.com/torvalds/linux/blob/v5.8/Makefile)

KBuild
- [Linux Kernel Makefiles](https://www.kernel.org/doc/html/latest/kbuild/makefiles.html) @kernel.org
- https://opensource.com/article/18/10/kbuild-and-kconfig
- https://opensource.com/article/18/10/kbuild-and-kconfig

## Ancient Code

http://oldlinux.org/

https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/

Minimal Linux
- https://github.com/ivandavidov/minimal
- [Build and run minimal Linux / Busybox systems in Qemu](https://gist.github.com/chrisdone/02e165a0004be33734ac2334f215380e)
- https://github.com/cirosantilli/linux-kernel-module-cheat
- https://github.com/cirosantilli/runlinux
- https://github.com/ivandavidov/minimal
- [buildroot usage example](https://stackoverflow.com/questions/47557262/how-to-download-the-torvalds-linux-kernel-master-recompile-it-and-boot-it-wi/49349237)
- https://ops.tips/notes/booting-linux-on-qemu/
- https://linuxboot.org/
- DIY: Build a Custom Minimal Linux Distribution from Source: [part 1](https://www.linuxjournal.com/content/diy-build-custom-minimal-linux-distribution-source), [part2](https://www.linuxjournal.com/content/build-custom-minimal-linux-distribution-source-part-ii)

2.0
- https://github.com/kalamangga-net/linux-2.0

1.0
- https://github.com/kalamangga-net/linux-1.0

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
  - https://github.com/Original-Linux/Running_Linux0.11
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
  - https://github.com/l2cup/linux-0.01
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

## Major Websites

https://lwn.net/

## Documentation

https://wiki.gentoo.org/wiki/Main_Page

- https://jasonblog.github.io/note/index.html
- https://github.com/shichao-an/notes
  - https://notes.shichao.io/utlk/
- https://0xax.gitbooks.io/linux-insides/content/
  - https://github.com/0xAX/linux-insides

[coreboot](https://www.coreboot.org/)
  - [System76](https://system76.com/)
    - [Laptops with Coreboot Firmware](https://www.cyberciti.biz/open-source/modern-linux-laptops-with-coreboot-firmware-from-system76/)
    - System76 introduces [laptops with open source BIOS coreboot](https://opensource.com/article/19/11/coreboot-system76-laptops)
  - [Purism](https://puri.sm/)
  
-Booting
  - [UEFI... The Microsoft Kill Switch](https://learnlinuxandlibreoffice.org/1-why-switch-to-linux/1-4-uefi-the-microsoft-kill-switch)
  - [Linux startup process](https://en.wikipedia.org/wiki/Linux_startup_process)
  - [Stages of Linux booting process](https://www.crybit.com/linux-boot-process/) (January 6, 2019)
  - [An introduction to the Linux boot and startup processes](https://opensource.com/article/17/2/linux-boot-and-startup)
  - [Linux Boot Process Explained in Simple Steps](https://linoxide.com/booting/boot-process-of-linux-in-detail/)
  - [Linux Boot Process — Part 1](https://medium.com/@cloudchef/linux-boot-process-part-1-e8fea015dd66), [Part 2](https://medium.com/@cloudchef/linux-boot-process-part-2-bd7514913495)
  - [Linux Boot Process](https://medium.com/devops-world/linux-boot-process-39b58198b791)
  - [Understanding the Boot process — BIOS vs UEFI](https://linuxhint.com/understanding_boot_process_bios_uefi/)
  - [GUID Partition Table](https://en.wikipedia.org/wiki/GUID_Partition_Table#Operating_System_support_of_GPT)

Memory
  - [Memory Addressing](https://notes.shichao.io/utlk/ch2/), [@github](https://github.com/shichao-an/notes/blob/master/docs/utlk/ch2.md) ([UTLK](https://notes.shichao.io/utlk/))

1494|2006-11-07|5395338|ebooks1|A Heavily Commented Linux Kernel Source Code.(2004).cn.pdf|pack01|/preprocess|H:/eBooks/xpub/Pack01

- https://github.com/cirosantilli/linux-kernel-module-cheat
- [The Linux Kernel Archives](https://www.kernel.org)
  - https://www.kernel.org/doc/
  - https://www.kernel.org/doc/html/latest/
  - https://www.kernel.org/doc/Documentation/x86/
  - [Kernel Hacking Guides](https://www.kernel.org/doc/html/latest/kernel-hacking/index.html)
- [0xAX/linux-insides](https://github.com/0xAX/linux-insides)
- [kernelnewbies](https://kernelnewbies.org/Documents)
  - https://kernelnewbies.org/FirstKernelPatch
  - https://kernelnewbies.org/KernelProjects
- Packt: Mastering Linux Kernel Development.-.(Nov 2017).-.978-1785883057
- Packt.-.Mastering Embedded Linux Programming, 2ed.-.(Jun 2017).-.978-1787283282
- Packt: Linux Device Drivers Development Develop Customized Drivers for Embedded Linux (Oct 2017) 978-1785280009
- Pearson: Computer Systems: A Programmer's Perspective, 3E (Mar 2015)
- CRC.-.The Art of Linux Kernel Design Illustrating the Operating System Design Principle and Implementation (Apr 2014) 978-1466518032
- Apress.-.Linux Kernel Networking Implementation and Theory.-.(Dec 2013).-.978-1430261964
- Addison-Wesley.-.Linux Kernel Development, 3ed.-.(Jul 2010).-.978-0672329463
- Wrox: Professional Linux Kernel Architecture (2008) 978-0470343432
- Prentice Hall.-.Essential Linux Device Drivers.-.(2008).-.0132396556
- [The Linux Kernel Module Programming Guide](https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/docs/lkmpg/), or [pdf](https://tldp.org/LDP/lkmpg/2.6/lkmpg.pdf) (2001, 2007−05−18 ver 2.6.4)
- OReilly.-.Linux Kernel in a Nutshell A Desktop Quick Reference.-.(Dec 2006).-.978-0596100797
- [Understanding the Linux Kernel, 3E] (2005), kernel 2.6
  - Understanding the Linux Kernel, 2E (????), kernel 2.4
- Prentice Hall.-.The Linux Kernel Primer A Top-Down Approach for x86 and PowerPC Architectures.-.(2005).-.978-0131181632
- Novell.-.Linux Kernel Development, 2ed.-.(Jan 2005).-.978-0672327209
- Linux Device Drivers, 3ed, OReilly (Feb 2005) 978-0596005900
  - Linux Device Drivers, 2ed, OReilly (Jun 2001) 978-0596000080 [online](https://www.xml.com/ldd/chapter/book/index.html) kernel 2.4
  - Linux Device Drivers, OReilly, (Feb 1998) 9781565922921
- [Unreliable Guide To Hacking The Linux Kernel](https://www.kernel.org/doc/htmldocs/kernel-hacking)
- [Linux i386 Boot Code HOWTO](https://tldp.org/HOWTO/Linux-i386-Boot-Code-HOWTO/index.html) (2004-01-23) @tldp
- [Intel 80386 Reference Programmer's Manual](https://pdos.csail.mit.edu/6.828/2005/readings/i386/toc.htm)
- [The Linux kernel](https://www.win.tue.nl/~aeb/linux/lk/lk.html) Andries Brouwer, aeb@cwi.nl 2003-02-01
- [Linux Kernel 2.4 Internals](https://www.kernel.org/doc/mirror/lki-single.html) (Tigran Aivazian tigran@veritas.com 7 August 2002)
  - [Linux Kernel Internals](https://www.star.bnl.gov/~liuzx/lki/lki.html#toc1) (Tigran Aivazian tigran@veritas.com 20 December 2000)
- [Linux Kernel: Good beginners' tutorial](https://unix.stackexchange.com/questions/1003/linux-kernel-good-beginners-tutorial) @[unix.stackexchange](https://unix.stackexchange.com)
- [The Linux Kernel](https://tldp.org/LDP/tlk/tlk.html) @tldp
- [Linux Kernel Hackers' Guide](https://tldp.org/LDP/khg/HyperNews/get/khg.html) @tldp
- Tutorials
  - [Writing a Simple Operating System from Scratch](./doc/os-dev.md)
  - [os-tutorial](https://github.com/cfenollosa/os-tutorial) @github
  - [JamesM's kernel development tutorials](http://www.jamesmolloy.co.uk/tutorial_html/)
  - [Bran's kernel development tutorials](http://www.osdever.net/bkerndev/index.php)
  - [The little book about OS development](https://littleosbook.github.io/) (2005)
  - [Intel® 64 and IA-32 Architectures Software Developer Manuals](https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html)
  - [alt.os.development](https://groups.google.com/g/alt.os.development) (Google group)
  - [osdev.org](https://wiki.osdev.org/)
  - [osdever.net](http://www.osdever.net/tutorials/) (very old, up to 2003)
- [Commentary on the Sixth Edition UNIX Operating System](http://www.lemis.com/grog/Documentation/Lions/index.php)
- The Design of the UNIX Operating System
- wikipedia
  - [Linux kernel](https://en.m.wikipedia.org/wiki/Linux_kernel)
  - [Linux kernel interfaces](https://en.m.wikipedia.org/wiki/Linux_kernel_interfaces)
- xv6
  - https://www.cs.columbia.edu/~junfeng/13fa-w4118/lectures/
  - https://github.com/mit-pdos/xv6-public
  - https://pdos.csail.mit.edu/6.828/2018/xv6.html
- [Write your own operating system](http://mirror.freedoors.org/Geezer-2/osd/index.htm)
  - http://mirror.freedoors.org/Geezer-2/osd/boot/index.htm

Interview Questions
- https://www.careercup.com/page?pid=linux-kernel-interview-questions&sort=votes&n=2
- https://www.careercup.com/page?pid=linux-kernel-interview-questions
- https://play.google.com/store/apps/details?id=learn.LinuxKernelInterviewTopics&hl=en_US
- https://www.quora.com/If-I-want-to-work-as-kernel-developer-for-Google-should-I-focus-on-contributing-to-the-Linux-kernel-and-open-source-or-focus-on-problem-solving-and-algorithms-to-pass-a-Google-interview
  - [How can I get a job at ...](https://www.quora.com/How-can-I-get-a-job-at-Facebook-or-Google-in-6-months-I-need-a-concise-work-plan-to-build-a-good-enough-skill-set-Should-I-join-some-other-start-up-or-build-my-own-projects-start-up-Should-I-just-focus-on-practicing-data-structures-and-algorithms)
- https://android.googlesource.com/device/generic/brillo/+/master/docs/KernelDevelopmentGuide.md
- http://www.remword.com/kps_result/all_whole.html

[How to develop your own Boot Loader](https://www.codeproject.com/Articles/36907/How-to-develop-your-own-Boot-Loader)

[Tony Bai](https://tonybai.com)
  - [github home](https://github.com/bigwhite)
  - [图解git原理的几个关键概念](https://tonybai.com/2020/04/07/illustrated-tale-of-git-internal-key-concepts/)
  - [english](https://tonybai.com/2006/04/), [and](https://tonybai.com/2006/04/page/2/), [and](https://tonybai.com/2006/04/page/3/), [and](https://tonybai.com/2006/04/page/4/)
  - https://blog.csdn.net/myan/article/details/605113, https://tonybai.com/2006/04/page/12/
  - [C语言也重构](https://tonybai.com/2006/03/28/c-refactoring/)
  - [当数组作参数时](https://tonybai.com/2006/03/27/when-array-passed-as-arguments/)
  - [如果让我面试C程序员，我会问](https://tonybai.com/2006/03/26/interview-questions-for-c-programmer/)
  - [理解C复杂声明之'优先级规则'](https://tonybai.com/2006/03/26/understand-priority-rule-for-parse-c-declaration/)
  - ['right-left'规则再举例](https://tonybai.com/2006/03/26/another-example-for-c-right-left-rule/)
  - [GCC警告选项例解](https://tonybai.com/2006/03/14/explain-gcc-warning-options-by-examples/)
  - [Kernel 'head.S'](https://tonybai.com/2006/03/02/kernel-head/)
  - [Compressed 'head.S'](https://tonybai.com/2006/02/25/compressed-head/)
  - [Transfer to '32-bit'](https://tonybai.com/2006/02/17/transfer-to-32bit/)
  - [Outline 'memory layout'](https://tonybai.com/2006/02/15/outline-memory-layout/)
  - [Begin 'setup.S'](https://tonybai.com/2006/02/13/begin-setup/)
  - [Goto 'Bootstrap'](https://tonybai.com/2006/02/11/goto-bootstrap/)
  - [Inside the 'i386'](https://tonybai.com/2006/02/09/inside-the-i386/)
  - [Retired 'bootsect.S'](https://tonybai.com/2006/02/08/retired-bootsect/)
  - [打开汇编之门](https://tonybai.com/2005/11/12/open-the-gate-to-assembly-language/)
  - [也谈字节序问题](https://tonybai.com/2005/09/28/also-talk-about-byte-order/)
  - [从技术到管理的对话-Tony与Alex的对话系列](https://tonybai.com/2005/06/05/tony-alex-dialog-on-from-tech-to-management/)
  
https://jasonblog.github.io/note/linux_kernel/index.html

https://linux-kernel-labs.github.io/refs/heads/master/

https://www.cs.utexas.edu/users/ygz/378-03S/

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

https://www.cs.bham.ac.uk/~exr/lectures/

https://www.threatstack.com/blog/c-in-the-linux-kernel

[How Linux's Kernel Developers 'Make C Less Dangerous'](https://developers.slashdot.org/story/18/09/01/2311248/how-linuxs-kernel-developers-make-c-less-dangerous)
  - https://kernsec.org/wiki/index.php/Kernel_Self_Protection_Project

https://barrgroup.com/Embedded-Systems/Books/Embedded-C-Coding-Standard \
https://www.perforce.com/resources/qac/misra-c-cpp
