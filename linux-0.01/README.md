- [2.0](https://github.com/kalamangga-net/linux-2.0)
- [1.0](https://github.com/kalamangga-net/linux-1.0)
- [0.12](https://github.com/sky-big/Linux-0.12)
- [0.11](https://github.com/yuan-xy/Linux-0.11)

The last version with bootsect.S, setup.S and video.S in the source code Repository is [2.6.22](https://kernel.googlesource.com/pub/scm/linux/kernel/git/wtarreau/linux-stable/+/refs/tags/v2.6.22).

bootsect.S was in as86 in [2.2](https://github.com/mpe/linux-fullhistory/tree/v2.2.0-orig) and [2.3](https://github.com/heesub/davej) (DEVELOPMENT kernel), in gas in [2.4.0](https://github.com/mpe/linux-fullhistory/tree/v2.4.0-orig)

bootsect.S and setup.S are real-mode 16-bit code programs that use Intel's assembly language syntax and require the 8086 assembly compiler and linker as86 and ld86. However, head.s uses an AT&T assembly syntax format and runs in protected mode, which needs to be compiled with GNU's as (gas) assembler.

The main reason why Linus Torvalds used two assemblers at the time was that for Intel x86 processors, the GNU assembly compiler in 1991 only supported i386 and later 32-bit CPU code instructions. It is not supported to generate 16-bit code programs that run in real mode. Until 1994, the GNU as assembler began to support the .code16 directive for compiling 16-bit code (See the "Writing 16-Bit Codes" of the "80386 Related Features" section in the GNU Assembler manual.). Starting with kernel 2.4.X, the bootsect.S and setup.S programs began to be uniformly written using GNU as.

release notes: [0.01](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/RELNOTES-0.01), [0.12](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/RELNOTES-0.12), [0.95](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/RELNOTES-0.95), [0.95a](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/RELNOTES-0.95a), [0.97](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/RELNOTES-0.97), [0.99.11](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/+/v0.99-pl11), [others](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/old-versions/), [kernel.googlesource.com](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/)

old linux @kernel.googlesource
- [2.6.11-3.10.108](https://kernel.googlesource.com/pub/scm/linux/kernel/git/wtarreau/linux-stable/+refs)
- [0.01 - 1](https://kernel.googlesource.com/pub/scm/linux/kernel/git/nico/archive/)

[original 0.01](https://github.com/mariuz/linux-0.01)

[0.01 remake](http://draconux.free.fr/os_dev/linux0.01.html), [code @github](https://github.com/liudonghua123/linux-0.01)

[Kernel 0.01 Walkthrough](https://kernelnewbies.org/Kernel001WalkThrough)

[Linux old kernels](https://mirrors.edge.kernel.org/pub/linux/kernel/Historic/)

[Linux-0.01 kernel building on ubuntu hardy](https://mapopa.blogspot.com/2008/09/linux-0.html)

[Linux 0.01 News](http://draconux.free.fr/os_dev/linux0.01_news.html)

https://virtuallyfun.com/wordpress/2010/08/13/linux-0-00-0-11-on-qemu/

Working examples
- [qemu-images @]oldlinux.org(http://www.oldlinux.org/Linux.old/qemu-images/)

https://blog.csdn.net/chengwenyang/article/details/77417830
