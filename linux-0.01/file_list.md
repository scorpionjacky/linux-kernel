# List of source files in 0.01 and 0.12

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
|Makefile.header   |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/Makefile.header)
|***boot***|
|Makefile   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/boot/Makefile) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/boot/Makefile)
|bootsect.S |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/boot/bootsect.s) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/boot/bootsect.s)
|head.s     |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/boot/head.s) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/boot/head.s)
|setup.S    |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/boot/setup.s)
|***init***|
|main.c     |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/init/main.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/init/main.c)
|***mm***|
|Makefile   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/mm/Makefile) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/mm/Makefile)
|memory.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/mm/memory.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/mm/memory.c)
|page.c     |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/mm/page.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/mm/page.c)
|swap.c     |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/mm/swap.c)
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
|tty_ioctl.c |  | <- | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/kernel/chr_drv/tty_ioctl.c)
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
|bitmap.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/bitmap.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/bitmap.c)
|block_dev.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/block_dev.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/block_dev.c)
|buffer.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/buffer.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/buffer.c)
|char_dev.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/char_dev.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/char_dev.c)
|exec.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/exec.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/exec.c)
|fcntl.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/fcntl.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/fcntl.c)
|file_dev.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/file_dev.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/file_dev.c)
|file_table.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/file_table.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/file_table.c)
|inode.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/inode.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/inode.c)
|ioctl.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/ioctl.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/ioctl.c)
|namei.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/namei.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/namei.c)
|open.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/open.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/open.c)
|pipe.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/pipe.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/pipe.c)
|read_write.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/read_write.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/read_write.c)
|select.c  |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/select.c)
|stat.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/stat.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/stat.c)
|super.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/super.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/super.c)
|sys_getdents.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/sys_getdents.c) | N/A
|truncate.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/truncate.c) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/fs/truncate.c)
|tty_ioctl.c   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/fs/tty_ioctl.c) | <-
|***lib***|
|Makefile   |  | [0.01](https://github.com/mariuz/linux-0.01/blob/master/lib/Makefile) | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/Makefile)
|\_exit.c   |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/_exit.c)
|close.c    |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/close.c)
|ctype.c    |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/ctype.c)
|debug.c    |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/debug.c)
|dup.c      |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/dup.c)
|errno.c    |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/errno.c)
|execve.c   |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/execve.c)
|malloc.c   |  | N/A | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/malloc.c)
|open.c     |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/open.c)
|setsid.c   |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/setsid.c)
|string.c   |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/string.c)
|wait.c     |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/wait.c)
|write.c    |  | - | [0.12](https://github.com/sky-big/Linux-0.12/blob/master/lib/write.c)
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
