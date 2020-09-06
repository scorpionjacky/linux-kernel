# Self-Built 0.11

`boot` + `init\main.c`, with main.c clearn with empty main() and start_start glocal variable (from sched.c) is easy to compile



```bash
$ ls -R

cp ../mariuz*/*/include/asm/io.h include/asm
```

Files:

```
- boot
    boot.s
    head.s
- include
    - asm
        io.h
    - linux
        mm.h
    time.h
- init
    main.c
- kernel
    Makefile
    mktime.c
- tools
    build.c
Makefile    
```


header files

*Note: '-': the same, 'N/A': not exists*, '?': check if the sname, Dep: include other headers

|Folder  |Dep |0.01|0.12|
|--       |:--:|:--:|:--:|
|***include***  |
|aout.h   |   | NA | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/aout.h)
|const.h  |   | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/const.h)
|ctype.h  |   | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/ctype.h)
|dirent.h | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/dirent.h) | N/A |
|elf.h    | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/elf.h) | N/A |
|errno.h  |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/errno.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/errno.h) |
|fcntl.h  | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/fcntl.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/fcntl.h) |
|signal.h | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/signal.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/signal.h) |
|stdarg.h |   | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/stdarg.h) |
|stddef.h |   | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/stddef/.h) |
|stdint.h | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/stdint.h) | N/A |
|string.h |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/string.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/string.h) |
|termios.h | Y | ?[0.01](https://github.com/mariuz/linux-0.01/blob/master/include/termios.h) | ?[0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/termios.h) |
|time.h   | ? | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/time.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/time.h) |
|unistd.h | ? | ?[0.01](https://github.com/mariuz/linux-0.01/blob/master/include/unistd.h) | ?[0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/unistd.h) |
|utime.h  | Y | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/utime.h) |
|***include/asm***|
|io.h      |   | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/asm/io.h)
|memory.h  |   | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/asm/memory.h)
|segment.h  |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/asm/segment.h) | ?[0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/asm/segment.h)
|system.h  |   | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/include/asm/system.h)
|***include/bits***|
|wchar.h    |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/asm/wchar.h) | N/A
|wordsize.h |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/include/asm/wordsize.h) | N/A
|***include/linux***|
|config.h   |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/linux/config.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/config.h)
|fdreg.h    |   | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/fdreg.h)
|fs.h       | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/linux/fs.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/fs.h)
|hdreg.h    |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/linux/hdreg.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/hdreg.h)
|head.h     |   | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/head.h)
|kernel.h   |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/linux/kernel.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/kernel.h)
|math_emu.h | Y | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/math_emu.h)
|mm.h       |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/linux/mm.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/mm.h)
|sched.h    | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/linux/sched.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/sched.h)
|sys.h      | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/linux/sys.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/sys.h)
|tty.h      | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/linux/tty.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/linux/tty.h)
|***include/sys***|
|param.h    |   | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/sys/param.h)
|resource.h | Y | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/sys/resource.h)
|stat.h     | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/sys/stat.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/sys/stat.h)
|times.h    | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/sys/times.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/sys/times.h)
|types.h    |   | [0.01](https://github.com/mariuz/linux-0.01/blob/master/sys/types.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/sys/types.h)
|utsname.h  | /Y| [0.01](https://github.com/mariuz/linux-0.01/blob/master/sys/utsname.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/sys/utsname.h)
|wait.h     | Y | [0.01](https://github.com/mariuz/linux-0.01/blob/master/sys/wait.h) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/sys/wait.h)
|***/***|
|Makefile   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/Makefile) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/Makefile)
|Makefile.header   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/Makefile.header) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/Makefile.header)
|***init***|
|main.c     |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/init/main.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/init/main.c)
|***mm***|
|Makefile   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/mm/Makefile) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/mm/Makefile)
|memory.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/mm/memory.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/mm/memory.c)
|page.c     |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/mm/page.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/mm/page.c)
|swap.c     |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/mm/swap.c)
|***boot***|
|Makefile   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/boot/Makefile) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/boot/Makefile)
|bootsect.S |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/boot/bootsect.s) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/boot/bootsect.s)
|head.s     |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/boot/head.s) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/boot/head.s)
|setup.S    |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/boot/setup.s)
|***kernel***|
|Makefile   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/Makefile) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/Makefile)
|asm.s      |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/asm.s) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/asm.s)
|console.c  |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/console.c) | <-
|exit.c     |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/exit.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/exit.c)
|fork.c     |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/fork.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/fork.c)
|hd.c       |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/hd.c) | <-
|keyboard.s |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/keyboard.s) | <-
|mktime.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/mktime.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/mktime.c)
|panic.c    |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/panic.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/panic.c)
|printk.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/printk.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/printk.c)
|rs_io.c    |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/rs_io.c) | <-
|sched.c    |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/sched.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/sched.c)
|serial.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/serial.c) | <-
|signal.c   |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/signal.c)
|sys.c      |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/sys.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/sys.c)
|sys_call.s |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/system_call.s) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/sys_call.s)
|traps.c    |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/traps.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/traps.c)
|tty_io.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/tty_io.c) | <-
|vsprintf.c |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/kernel/vsprintf.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/vsprintf.c)
|***kernel/blk_drv***|
|Makefile   |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/blk_drv/Makefile)
|blk.h      |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/blk_drv/blk.h)
|floppy.c   |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/blk_drv/floppy.c)
|hd.c       |  | <- | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/blk_drv/hd.c)
|ll_rw_blk.c |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/blk_drv/ll_rw_blk.c)
|ramdisk.c  |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/blk_drv/ramdisk.c)
|***kernel/chr_drv***|
|Makefile   |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/chr_drv/Makefile)
|console.c  |  | <- | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/chr_drv/console.c)
|keyboard.s |  | <- | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/chr_drv/keyboard.s)
|pty.c      |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/chr_drv/pty.c)
|rs_io.c    |  | <- | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/chr_drv/rs_io.c)
|serial.c   |  | <- | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/chr_drv/serial.c)
|tty_io.c   |  | <- | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/chr_drv/tty_io.c)
|tty_ioctl.c |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/chr_drv/tty_ioctl.c)
|***kernel/math***|
|Makefile   |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/Makefile)
|add.c      |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/add.c)
|compare.c  |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/compare.c)
|convert.c  |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/convert.c)
|div.c      |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/div.c)
|ea.c       |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/ea.c)
|error.c    |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/error.c)
|get_put.c  |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/get_put.c)
|math_emulate.c |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/math_emulate.c)
|mul.c      |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/math/mul.c)
|***fs***|
|Makefile   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/Makefile) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/Makefile)
|***lib***|
|Makefile   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/lib/Makefile) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/Makefile)
|***tools***|
|build.c    |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/tools/build.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/tools/build.c)
|build.sh   |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/tools/build.sh)

```
include/
const.h    indepedent
ctype.h    indepedent
dirent.h   linux/fs.h, stdint.h; some functions [opendir, closedir, dirent]
elf.h      stdint.h, otherwise seems independent
errno.h    indepedent
fcntl.h    sys/types.h, extern fun: creat/fcntl/open
signal.h   sys/types.h, some functions [signal,raise,kill,sigaddset,sigdelset,sigemptyset,
                       sigfillset,sigismember,sigpending,sigprocmask,sigsuspend,sigaction]
stdarg.h   indepedent
stddef.h   indepedent
stdint.h   bits/wchar.h, bits/wordsize.h
string.h   extern char * strerror(int errno);;   a lot of extern inline functions
termios.h  lot of extern functions
time.h     some functions
unistd.h   extern int errno;  lot of unctons
utime.h    sys/types.h, extern int utime()

include/asm
io.h       indepedent, outb(), inb(), outb_p(), inb_p()
memory.h   indepedent
segment.h  indepedent, single macro: #define memcpy()
system.h   indepedent, macros for assembly

include/bits
wchar.h     indepedent
wordsize.h  indepedent

include/linux
config.h    indepedent
fs.h        sys/types.h, lot of extern var and func
hdreg.h     indepedent, AT-hd-controller
head.h      indepedent, desc_table[256], extern desc_table idt,gdt; 
                                 extern unsigned long pg_dir[1024];
kernel.h    indepedent, verify_area(), panic(), printf(), printk(), tty_write()
mm.h        indepedent
sched.h     linux/head.h, linux/fs.h, linux/mm.h, externs, macros
sys.h       indepedent, syscalls
tty.h       termios.h, externs and funcs

include/sys
stat.h     sys/types.h, stdint.h; extern funs [chmod, fstat64, mkdir, mkfifo, stat64]; extern mode_t umask()
times.h    sys/types.h; extern time_t times()
types.h    indepedent
utsname.h  extern int uname ()
wait.h     sys/types.h; pid_t wait(), pid_t waitpid()
```


```
lib/*:     independent
tools/*:   independent
mm
memory.c  signal.h, linux/(config.h,head.h,kernel.h,mm.h), asm/system.h
page.c    independent, assembly: .globl page_fault
```

```
kernel
asm.s       independent
console.c   linux/sched.h, linux/tty.h, asm/(io.h, system.h)
exit.c      errno.h, signal.h, sys/wait.h, linux/(sched.h, kernel.h, tty.h), asm/segment.h
fork.c      errno.h, linux/(sched.h, kernel.h), asm/(segment.h, system.h)
hd.c        linux/(config.h,sched.h,kernel.h,fs.h,hdreg.h), asm/(io.h,system.h,segment.h)
keyboard.s  .globl keyboard_interrupt
mktime.c    independent
panic.c     linux/kernel.h
printk.c    stdarg.h,stddef.h, linux/kernel.h; uses vsprintf(); uses tty_write() from tty_io.c
rs_io.s     .globl rs1_interrupt,rs2_interrupt
sched.c     signal.h, linux/(sched.h,kernel.h,sys.h), asm/(io.h,system.h,segment.h)
serial.c    linux/(sched.h,tty.h), asm/(io.h,system.h)
sys.c       errno.h, linux/(sched.h,kernel.h,tty.h), asm/segment.h, sys/(times.h,utsname.h)
system_call.s  .globl system_call,sys_fork,timer_interrupt,hd_interrupt,sys_execve
traps.c     string.h, linux/(sched.h,kernel.h,head.h), asm/(system.h,segment.h)
tty_io.c    ctype.h, errno.h, signal.h, linux/(sched.h,tty.h), asm/(system.h,segment.h)
vsprintf.c  independent; stdarg.h, string.h
```

```
fs
bitmap.c     string.h, linux/(sched.h,kernel.h)
block_dev.c  errno.h, linux/(fs.h,kernel.h), asm/segment.h
buffer.c     linux/(config.h,sched.h,kernel.h), asm/system.h
char_dev.c   errno.h, linux/(sched.h,kernel.h)
exec.c       errno.h, elf.h, sys/stat.h, linux/(sched.h,kernel.h,fs.h,mm.h), asm/segment.h
fcntl.c      errno.h, string.h, fcntl.h, linux/(sched.h,kernel.h), asm/segment.h, sys/stat.h
file_dev.c   errno.h, fcntl.h, linux/(sched.h,kernel.h), asm/segment.h
file_table.c   linux/fs.h; struct file file_table[NR_FILE];
inode.c      string.h, linux/(sched.h,kernel.h,mm.h), asm/system.h
ioctl.c      errno.h, string.h, linux/sched.h, sys/stat.h
namei.c      errno.h, string.h, fcntl.h, const.h, sys/stat.h, linux/(sched.h,kernel.h), asm/segment.h
open.c       errno.h, string.h, fcntl.h, utime.h, sys/(types.h, stat.h), linux/(sched.h,kernel.h,tty.h), asm/segment.h
pipe.c       signal.h, , linux/(sched.h,mm.h), asm/segment.h
read_write.c  errno.h, sys/(types.h, stat.h), linux/(sched.h,kernel.h), asm/segment.h
stat.c       errno.h, sys/stat.h, linux/(sched.h,kernel.h,fs.h), asm/segment.h
super.c      linux/(config.h,sched.h,kernel.h)
sys_getdents.c  errno.h, dirent.h, sys/stat.h, linux/(sched.h,kernel.h,mm.h), asm/segment.h
truncate.c   sys/stat.h, linux/sched.h
tty_ioctl.c  errno.h, termios.h, linux/(sched.h,kernel.h,tty.h), asm/(system.h,segment.h)
```

main.c

```c
#include <linux/mm.h>  // to use PAGE_SIZE
#include <time.h> // to use struct tm
#include <asm/io.h> // to user out_p, inb_p

//#include <linux/kernel.h>

// from kernel/printk.c
static char buf[1024];

// from sched.c
long user_stack [ PAGE_SIZE>>2 ] ;

// from sched.c
struct {
        long * a;
        short b;
} stack_start = { & user_stack [PAGE_SIZE>>2] , 0x10 };

#define CMOS_READ(addr) ({ \
outb_p(0x80|addr,0x70); \
inb_p(0x71); \
})

#define BCD_TO_BIN(val) ((val)=((val)&15) + ((val)>>4)*10)

// in sched.c
unsigned long startup_time=0;

static void time_init(void)
{
        struct tm time;

        do {
                time.tm_sec = CMOS_READ(0);
                time.tm_min = CMOS_READ(2);
                time.tm_hour = CMOS_READ(4);
                time.tm_mday = CMOS_READ(7);
                time.tm_mon = CMOS_READ(8)-1;
                time.tm_year = CMOS_READ(9);
        } while (time.tm_sec != CMOS_READ(0));
        BCD_TO_BIN(time.tm_sec);
        BCD_TO_BIN(time.tm_min);
        BCD_TO_BIN(time.tm_hour);
        BCD_TO_BIN(time.tm_mday);
        BCD_TO_BIN(time.tm_mon);
        BCD_TO_BIN(time.tm_year);
        startup_time = kernel_mktime(&time);

}

void dummy_test_entrypoint() {
}

int main(void) {
        char* video_memory = (char*) 0xb8000;
        *video_memory = 'X';

        time_init();
}
```

https://blogs.oracle.com/d/inline-functions-in-c

https://elinux.org/Extern_Vs_Static_Inline
