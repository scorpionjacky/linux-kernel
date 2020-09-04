# Self-Built 0.11

https://blogs.oracle.com/d/inline-functions-in-c

https://elinux.org/Extern_Vs_Static_Inline

```
include/
const.h    indepedent
ctype.h    indepedent
dirent.h   linux/fs.h, stdint.h; some functions [opendir, closedir, dirent]
elf.h      stdint.h, otherwise seems independent
errno.h    indepedent
fcntl.h    sys/types.h, extern fun: creat/fcntl/open
signal.h   sys/types.h, some functions [signal,raise,kill,sigaddset,sigdelset,sigemptyset,sigfillset,sigismember,sigpending,sigprocmask,sigsuspend,sigaction]
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
head.h      indepedent, desc_table[256], some extern: extern desc_table idt,gdt; extern unsigned long pg_dir[1024];
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

include/sys/types.h  self-complete

`tools` folder is easy to compile
`lib` filder is easy to compile
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
