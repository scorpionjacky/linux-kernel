# Self-Built 0.01

## what does main() do

```c
int main() {
  time_init();
  tty_init();
  trap_init();
  sched_init();
  buffer_init();
  hd_init();
  sti();
  move_to_user_mode();
  
  if (!fork()) {init();}
  
  //go check if some other task can run, and if not we return here.
  for(;;) pause(); 

  return 0;
}
```

## booting only

Starting from
- boot/bootsect.S
- boot/head.s
- init/main.c
    - An empty main() function 
    - `stack_start` global variable (from sched.c) 
    - `long user_stack` global variable (from sched.c) 
    - `PAGE_SIZE` macro (from linux/mm.h) 
- tools/build.c
    - for building boot system image
- Makefile

main.c

```c
// from linux/mm.h
#define PAGE_SIZE 4096

// from sched.c
long user_stack [ PAGE_SIZE>>2 ] ;

// from sched.c
struct {
        long * a;
        short b;
} stack_start = { & user_stack [PAGE_SIZE>>2] , 0x10 };

// from unistd.h
#define __NR_pause	29

int main(void) {
        //char* video_memory = (char*) 0xb8000;
        //*video_memory = 'X';
	for(;;) __asm__("int $0x80"::"a" (__NR_pause):);
	return 0;
}
```

Makefile

```make
AS86	=as86 -0 
CC86	=cc86 -0
LD86	=ld86 -0

AS	=as --32 
LD	=ld -m  elf_i386 
LDFLAGS	=-M -Ttext 0 -e startup_32
CC	=gcc
CFLAGS	=-Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -fno-stack-protector -fno-builtin -g -m32

ARCHIVES=
LIBS	=

.c.s:
	$(CC) $(CFLAGS) \
	-nostdinc -Iinclude -S -o $*.s $<
.s.o:
	$(AS) --32 -o $*.o $<
.c.o:
	$(CC) $(CFLAGS) \
	-nostdinc -Iinclude -c -o $*.o $<

all:	Image

Image: boot/boot tools/system tools/build
	objcopy  -O binary -R .note -R .comment tools/system tools/system.bin
	tools/build boot/boot tools/system.bin > Image
#	sync

tools/build: tools/build.c
	$(CC) $(CFLAGS) \
	-o tools/build tools/build.c
	#chmem +65000 tools/build

boot/boot:	boot/boot.s tools/system
	(echo -n "SYSSIZE = (";stat -c%s tools/system \
		| tr '\012' ' '; echo "+ 15 ) / 16") > tmp.s	
	cat boot/boot.s >> tmp.s
	$(AS86) -o boot/boot.o tmp.s
	rm -f tmp.s
	$(LD86) -s -o boot/boot boot/boot.o

boot/head.o: boot/head.s

tools/system:	boot/head.o init/main.o \
		$(ARCHIVES) $(LIBS)
	$(LD) $(LDFLAGS) boot/head.o init/main.o \
	$(ARCHIVES) \
	$(LIBS) \
	-o tools/system > System.map

clean:
	rm -f Image System.map tmp_make boot/boot core
	rm -f init/*.o boot/*.o tools/system tools/build tools/system.bin

```

Running `make` and the output:

```
$ make
as --32  --32 -o boot/head.o boot/head.s
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -fno-stack-protector -fno-builtin -g -m32 \
-nostdinc -Iinclude -c -o init/main.o init/main.c
ld -m  elf_i386  -M -Ttext 0 -e startup_32 boot/head.o init/main.o \
 \
 \
-o tools/system > System.map
(echo -n "SYSSIZE = (";stat -c%s tools/system \
        | tr '\012' ' '; echo "+ 15 ) / 16") > tmp.s
cat boot/boot.s >> tmp.s
as86 -0  -o boot/boot.o tmp.s
00286                                           /*
00287                                            * This procedure turns off the floppy drive motor, so
00288                                            * that we enter the kernel in a known state, and
00289                                            * don't have to worry about it later.
00290                                            */
00286                                           /*
00287                                            * This procedure turns off the floppy drive motor, so
00288                                            * that we enter the kernel in a known state, and
00289                                            * don't have to worry about it later.
00290                                            */
rm -f tmp.s
ld86 -0 -s -o boot/boot boot/boot.o
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -fno-stack-protector -fno-builtin -g -m32 \
-o tools/build tools/build.c
#chmem +65000 tools/build
objcopy  -O binary -R .note -R .comment tools/system tools/system.bin
tools/build boot/boot tools/system.bin > Image
Boot sector 452 bytes.
System 24756 bytes.
```

## time_init()

We'll simply add two macros `CMOS_READ(addr)` and `BCD_TO_BIN(val)` and the function `time_init()` *back* to main.c, plus adding to main.c the global variable `unsigned long startup_time=0;` as defined in `sched.c`.

This also requires: 
- include/asm/io.h
- kernel/mktime.c
  - include/time.h

So we need to copy these files.

Makefile changes:
```
ARCHIVES=kernel/kernel.o

kernel/kernel.o:
	(cd kernel; make)

clean:
	rm -f Image System.map tmp_make boot/boot core
	rm -f init/*.o boot/*.o tools/system tools/build tools/system.bin
	(cd kernel;make clean)
```

We also need to add `kernel/Makefile`, modified to compile only for `mktime.o`.

```
#include <asm/io.h>
#include <time.h>

extern long kernel_mktime(struct tm * tm);

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

int main() {
	...
        time_init();
	...
}
```

List of files:
```
ls -R
.:
boot  include  init  kernel  Makefile  tools

./boot:
boot.s  head.s

./include:
asm  time.h

./include/asm:
io.h

./init:
main.c

./kernel:
Makefile  mktime.c

./tools:
build.c
```

build output:
```
$ make
as --32  --32 -o boot/head.o boot/head.s
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -fno-stack-protector -fno-builtin -g -m32 \
-nostdinc -Iinclude -c -o init/main.o init/main.c
(cd kernel; make)
make[1]: Entering directory '/home/ubuntu/linux_kernel/linux-dev/boot-init-time/kernel'
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -m32 -finline-functions -fno-stack-protector -nostdinc -fno-builtin -g -I../include \
-c -o mktime.o mktime.c
ld -m  elf_i386  -r -o kernel.o mktime.o
sync
make[1]: Leaving directory '/home/ubuntu/linux_kernel/linux-dev/boot-init-time/kernel'
ld -m  elf_i386  -M -Ttext 0 -e startup_32 boot/head.o init/main.o \
kernel/kernel.o \
 \
-o tools/system > System.map
(echo -n "SYSSIZE = (";stat -c%s tools/system \
        | tr '\012' ' '; echo "+ 15 ) / 16") > tmp.s
cat boot/boot.s >> tmp.s
as86 -0  -o boot/boot.o tmp.s
00286                                           /*
00287                                            * This procedure turns off the floppy drive motor, so
00288                                            * that we enter the kernel in a known state, and
00289                                            * don't have to worry about it later.
00290                                            */
00286                                           /*
00287                                            * This procedure turns off the floppy drive motor, so
00288                                            * that we enter the kernel in a known state, and
00289                                            * don't have to worry about it later.
00290                                            */
rm -f tmp.s
ld86 -0 -s -o boot/boot boot/boot.o
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -fno-stack-protector -fno-builtin -g -m32 \
-o tools/build tools/build.c
#chmem +65000 tools/build
objcopy  -O binary -R .note -R .comment tools/system tools/system.bin
tools/build boot/boot tools/system.bin > Image
Boot sector 452 bytes.
System 25392 bytes.
```

## sched_init()

sched.h
  - #include <linux/head.h>: uses ldt etc.
  - #include <linux/fs.h>: used only for `#define NR_OPEN 20`
  - #include <linux/mm.h>: used only for `#define PAGE_SIZE 4096`

sched.c
  - #include <linux/sched.h>
  - #include <linux/kernel.h>: `panic()` only
  - #include <signal.h>
    - #include <sys/types.h>
  - #include <linux/sys.h>: `fn_ptr sys_call_table[]`
  - #include <asm/system.h>
  - #include <asm/io.h>
  - #include <asm/segment.h>
  - system_call & timer_interrupt
    - kernel/system_call.s
      - .globl system_call,sys_fork,timer_interrupt,hd_interrupt,sys_execve
      - asm.s

```bash
cp ../../mariuz-0.01/linux-0.01/include/asm/segment.h include/asm/
cp ../../mariuz-0.01/linux-0.01/include/asm/system.h include/asm/
cp ../../mariuz-0.01/linux-0.01/include/linux/head.h include/linux/
cp ../../mariuz-0.01/linux-0.01/include/linux/sys.h include/linux/
#cp ../../mariuz-0.01/linux-0.01/include/linux/kernel.h include/linux/
cp ../../mariuz-0.01/linux-0.01/include/sys/types.h include/sys/
cp ../../mariuz-0.01/linux-0.01/include/signal.h include/
cp ../../mariuz-0.01/linux-0.01/include/linux/sched.h include/linux/
cp ../../mariuz-0.01/linux-0.01/include/string.h include/
cp ../../mariuz-0.01/linux-0.01/kernel/sched.c kernel/
cp ../../mariuz-0.01/linux-0.01/kernel/system_call.s kernel/
cp ../../mariuz-0.01/linux-0.01/kernel/asm.s kernel/
cp ../../mariuz-0.01/linux-0.01/kernel/traps.c kernel/
cp ../../mariuz-0.01/linux-0.01/kernel/sys.c kernel/
cp ../../mariuz-0.01/linux-0.01/include/errno.h include/
cp ../../mariuz-0.01/linux-0.01/include/sys/times.h include/sys/
cp ../../mariuz-0.01/linux-0.01/include/sys/utsname.h include/sys/
```

include/linux/fs.h: #define NR_OPEN 20

include/linux/mm.h: #define PAGE_SIZE 4096

kernel/traps.c: comment out calls to printk()

Modify sched.c:

```c
//#include <linux/kernel.h>
//#include <linux/sys.h>
```
and comment out calls to `panic`

kernel/Makefile: add sched.o system_call.o asm.o

main.c

remove the following (added by time_init()):
```c
// from linux/mm.h
#define PAGE_SIZE 4096

// from sched.c
long user_stack [ PAGE_SIZE>>2 ] ;

// from sched.c
struct {
        long * a;
        short b;
} stack_start = { & user_stack [PAGE_SIZE>>2] , 0x10 };

// in sched.c
unsigned long startup_time=0;
```

add the following to main.c:

```c
extern long startup_time;

```


## trap_init()


[system calls](https://tldp.org/LDP/khg/HyperNews/get/syscall/syscall86.html) from [Linux Kernel Hackers' Guide](https://tldp.org/LDP/khg/HyperNews/get/khg.html), or [mirro](http://mirrors.kernel.org/LDP/)

[A small trail through the Linux kernel](https://www.win.tue.nl/~aeb/linux/vfs/trail.html)

https://blog.packagecloud.io/eng/2016/04/05/the-definitive-guide-to-linux-system-calls/

https://linux-kernel-labs.github.io/refs/heads/master/lectures/syscalls.html

What do we do?

traps.c:
- change die() to do nothing (avoid using printk())
  - this avoids using printk()
  - this also avoids referencing `*current` from sched.c
- comment out include for sched.h, kernel.h, string.h
- do_int3(): comment out calls to printk()

kernel/Makefile:
- add asm.o, traps.o for compilation

```bash
cp ../../mariuz-0.01/linux-0.01/include/asm/segment.h include/asm/
cp ../../mariuz-0.01/linux-0.01/include/asm/system.h include/asm/
cp ../../mariuz-0.01/linux-0.01/include/linux/head.h linux
# cp ../../mariuz-0.01/linux-0.01/include/string.h include/
cp ../../mariuz-0.01/linux-0.01/kernel/traps.c kernel/
cp ../../mariuz-0.01/linux-0.01/kernel/asm.s kernel/
```

main.c
- add trap_init() to main() function

```c
// from sched.h
extern void trap_init(void);
```


## tty_init()

`cp ../mariuz*/*/include/asm/io.h include/asm`

Now the next one is `tty_ini()`:
- kernel/tty_io.c
  - include/ctype.h
    - lib/ctype.c
  - errno.h
    - extern int errno;
  - signal.h  ???
    - include/sys/types.h
  - linux/sched.h  (references `task_struct *task|*current`)
    - linux/head.h (file descriptors, ldt, gdt, etc)
    - linux/fs.h
    - linux/mm.h
  - linux/tty.h
   - include/termios.h (independent)
  - asm/segment.h (indepedent)
  - asm/system.h (indepedent)
  - kernel/rs_io.s (globl rs1_interrupt,rs2_interrupt)
  - kernel/console.c
    - linux/sched.h ??? what's for
    - linux/tty.h
    - asm/io.h
    - asm/system.h
    - kernel/keyboard.s (.globl keyboard_interrupt) (independent)

```bash
cp ../../mariuz-0.01/linux-0.01/kernel/tty_io.c kernel/
cp ../../mariuz-0.01/linux-0.01/kernel/rs_io.s kernel/
cp ../../mariuz-0.01/linux-0.01/kernel/console.c kernel/
cp ../../mariuz-0.01/linux-0.01/kernel/keyboard.s kernel/
cp ../../mariuz-0.01/linux-0.01/include/asm/segment.h include/asm/
cp ../../mariuz-0.01/linux-0.01/include/asm/system.h include/asm/
cp ../../mariuz-0.01/linux-0.01/include/linux/tty.h include/linux/
cp ../../mariuz-0.01/linux-0.01/include/termios.h include/
cp ../../mariuz-0.01/linux-0.01/include/linux/head.h include/linux/

#cp ../../mariuz-0.01/linux-0.01/include/signal.h include/
#cp ../../mariuz-0.01/linux-0.01/include/sys/types.h include/sys/

cp ../../mariuz-0.01/linux-0.01/include/ctype.h include/
cp ../../mariuz-0.01/linux-0.01/lib/ctype.c lib/
cp ../../mariuz-0.01/linux-0.01/include/errno.h include/
cp ../../mariuz-0.01/linux-0.01/lib/errno.c lib/
cp ../../mariuz-0.01/linux-0.01/lib/Makefile lib/
```

customized signal.h:

```c
#define SIGINT           2
#define SIGALRM         14
```

customized fs.h:
```c
#define NR_OPEN 20
```

create a customized include/linux/sched.h:

```c
#include <linux/head.h>
#include <linux/fs.h>

#ifndef NULL
#define NULL    ((void *)0)
#endif

#define NR_TASKS 64

#define TASK_RUNNING		0
#define TASK_INTERRUPTIBLE	1
#define TASK_UNINTERRUPTIBLE	2
#define TASK_ZOMBIE		3
#define TASK_STOPPED		4

typedef int (*fn_ptr)();

struct i387_struct {
	long	cwd;
	long	swd;
	long	twd;
	long	fip;
	long	fcs;
	long	foo;
	long	fos;
	long	st_space[20];	/* 8*10 bytes for each FP-reg = 80 bytes */
};

struct tss_struct {
	long	back_link;	/* 16 high bits zero */
	long	esp0;
	long	ss0;		/* 16 high bits zero */
	long	esp1;
	long	ss1;		/* 16 high bits zero */
	long	esp2;
	long	ss2;		/* 16 high bits zero */
	long	cr3;
	long	eip;
	long	eflags;
	long	eax,ecx,edx,ebx;
	long	esp;
	long	ebp;
	long	esi;
	long	edi;
	long	es;		/* 16 high bits zero */
	long	cs;		/* 16 high bits zero */
	long	ss;		/* 16 high bits zero */
	long	ds;		/* 16 high bits zero */
	long	fs;		/* 16 high bits zero */
	long	gs;		/* 16 high bits zero */
	long	ldt;		/* 16 high bits zero */
	long	trace_bitmap;	/* bits: trace 0, bitmap 16-31 */
	struct i387_struct i387;
};

struct task_struct {
/* these are hardcoded - don't touch */
	long state;	/* -1 unrunnable, 0 runnable, >0 stopped */
	long counter;
	long priority;
	long signal;
	fn_ptr sig_restorer;
	fn_ptr sig_fn[32];
/* various fields */
	int exit_code;
	unsigned long end_code,end_data,brk,start_stack;
	long pid,father,pgrp,session,leader;
	unsigned short uid,euid,suid;
	unsigned short gid,egid,sgid;
	long alarm;
	long utime,stime,cutime,cstime,start_time;
	unsigned short used_math;
/* file system info */
	int tty;		/* -1 if no tty, so it must be signed */
	unsigned short umask;
	struct m_inode * pwd;
	struct m_inode * root;
	unsigned long close_on_exec;
	struct file * filp[NR_OPEN];
/* ldt for this task 0 - zero 1 - cs 2 - ds&ss */
	struct desc_struct ldt[3];
/* tss for this task */
	struct tss_struct tss;
};

#define INIT_TASK \
/* state etc */	{ 0,15,15, \
/* signals */	0,NULL,{(fn_ptr) 0,}, \
/* ec,brk... */	0,0,0,0,0, \
/* pid etc.. */	0,-1,0,0,0, \
/* uid etc */	0,0,0,0,0,0, \
/* alarm */	0,0,0,0,0,0, \
/* math */	0, \
/* fs info */	-1,0133,NULL,NULL,0, \
/* filp */	{NULL,}, \
	{ \
		{0,0}, \
/* ldt */	{0x9f,0xc0fa00}, \
		{0x9f,0xc0f200}, \
	}, \
/*tss*/	{0,PAGE_SIZE+(long)&init_task,0x10,0,0,0,0,(long)&pg_dir,\
	 0,0,0,0,0,0,0,0, \
	 0,0,0x17,0x17,0x17,0x17,0x17,0x17, \
	 _LDT(0),0x80000000, \
		{} \
	}, \
}

#define FIRST_TSS_ENTRY 4
#define FIRST_LDT_ENTRY (FIRST_TSS_ENTRY+1)
#define _TSS(n) ((((unsigned long) n)<<4)+(FIRST_TSS_ENTRY<<3))
#define _LDT(n) ((((unsigned long) n)<<4)+(FIRST_LDT_ENTRY<<3))

extern void schedule(void);
extern struct task_struct *task[NR_TASKS];
extern struct task_struct *last_task_used_math;
extern struct task_struct *current;
extern long volatile jiffies;

extern void interruptible_sleep_on(struct task_struct ** p);
extern void wake_up(struct task_struct ** p);
```

create a customized kernel/sched.c:

```c
#include <linux/sched.h>

#include <asm/system.h>
#include <asm/io.h>
#include <asm/segment.h>

// from linux/mm.h
#define PAGE_SIZE 4096

union task_union {
	struct task_struct task;
	char stack[PAGE_SIZE];
};

static union task_union init_task = {INIT_TASK,};

void interruptible_sleep_on(struct task_struct **p)
{
	struct task_struct *tmp;

	if (!p)
		return;
	//if (current == &(init_task.task))
	//	panic("task[0] trying to sleep");
	tmp=*p;
	*p=current;
repeat:	current->state = TASK_INTERRUPTIBLE;
	schedule();
	if (*p && *p != current) {
		(**p).state=0;
		goto repeat;
	}
	*p=NULL;
	if (tmp)
		tmp->state=0;
}

void wake_up(struct task_struct **p)
{
	if (p && *p) {
		(**p).state=0;
		*p=NULL;
	}
}
```

main.c

```c
#include <linux/tty.h>

int main() {
	...
	tty_init();
	...
}
```

Makefile

```make
LIBS    =lib/lib.a

lib/lib.a:
	(cd lib; make)

clean:
        rm -f Image System.map tmp_make boot/boot core
        rm -f init/*.o boot/*.o tools/system tools/build tools/system.bin
        (cd kernel;make clean)
        (cd lib;make clean)
```

kernel/Makefile

```make
OBJS  =mktime.o tty_io.o console.o keyboard.o rs_io.o sched.o
```

Make lib/Makefile to compile only for errno.o and ctype.o.

build output:
```
$ make
(cd lib; make)
make[1]: Entering directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/lib'
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -m32 -finline-functions -fno-stack-protector -nostdinc -fno-builtin -g -I../include \
-c -o ctype.o ctype.c
make[1]: *** No rule to make target 'errono.o', needed by 'lib.a'.  Stop.
make[1]: Leaving directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/lib'
Makefile:56: recipe for target 'lib/lib.a' failed
make: *** [lib/lib.a] Error 2
ubuntu@ip-172-24-68-210:~/linux_kernel/linux-dev/tty-init$ vi lib/Makefile
ubuntu@ip-172-24-68-210:~/linux_kernel/linux-dev/tty-init$ vi lib/Makefile
ubuntu@ip-172-24-68-210:~/linux_kernel/linux-dev/tty-init$ ls lib
ctype.c  ctype.o  errno.c  Makefile
ubuntu@ip-172-24-68-210:~/linux_kernel/linux-dev/tty-init$ vi lib/Makefile
ubuntu@ip-172-24-68-210:~/linux_kernel/linux-dev/tty-init$ make clean
rm -f Image System.map tmp_make boot/boot core
rm -f init/*.o boot/*.o tools/system tools/build tools/system.bin
(cd kernel;make clean)
make[1]: Entering directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel'
rm -f core *.o *.a tmp_make
for i in *.c;do rm -f `basename $i .c`.s;done
make[1]: Leaving directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel'
(cd lib;make clean)
make[1]: Entering directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/lib'
rm -f core *.o *.a tmp_make
for i in *.c;do rm -f `basename $i .c`.s;done
make[1]: Leaving directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/lib'
ubuntu@ip-172-24-68-210:~/linux_kernel/linux-dev/tty-init$ make
as --32  --32 -o boot/head.o boot/head.s
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -fno-stack-protector -fno-builtin -g -m32 \
-nostdinc -Iinclude -c -o init/main.o init/main.c
(cd kernel; make)
make[1]: Entering directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel'
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -m32 -finline-functions -fno-stack-protector -nostdinc -fno-builtin -g -I../include \
-c -o mktime.o mktime.c
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -m32 -finline-functions -fno-stack-protector -nostdinc -fno-builtin -g -I../include \
-c -o tty_io.o tty_io.c
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -m32 -finline-functions -fno-stack-protector -nostdinc -fno-builtin -g -I../include \
-c -o console.o console.c
as --32 -o keyboard.o keyboard.s
as --32 -o rs_io.o rs_io.s
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -m32 -finline-functions -fno-stack-protector -nostdinc -fno-builtin -g -I../include \
-c -o sched.o sched.c
ld -m  elf_i386  -r -o kernel.o mktime.o tty_io.o console.o keyboard.o rs_io.o sched.o
sync
make[1]: Leaving directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel'
(cd lib; make)
make[1]: Entering directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/lib'
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -m32 -finline-functions -fno-stack-protector -nostdinc -fno-builtin -g -I../include \
-c -o ctype.o ctype.c
gcc -Wall -O -std=gnu89 -fstrength-reduce -fomit-frame-pointer -m32 -finline-functions -fno-stack-protector -nostdinc -fno-builtin -g -I../include \
-c -o errno.o errno.c
ar rcs lib.a ctype.o errno.o
sync
make[1]: Leaving directory '/home/ubuntu/linux_kernel/linux-dev/tty-init/lib'
ld -m  elf_i386  -M -Ttext 0 -e startup_32 boot/head.o init/main.o \
kernel/kernel.o \
lib/lib.a \
-o tools/system > System.map
kernel/kernel.o: In function `tty_init':
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:96: undefined reference to `rs_init'
kernel/kernel.o: In function `tty_intr':
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:108: undefined reference to `task'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:108: undefined reference to `task'
kernel/kernel.o: In function `tty_read':
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:204: undefined reference to `current'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:209: undefined reference to `jiffies'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:210: undefined reference to `jiffies'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:215: undefined reference to `current'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:219: undefined reference to `current'
kernel/kernel.o: In function `sleep_if_empty':
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:114: undefined reference to `current'
kernel/kernel.o: In function `tty_read':
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:239: undefined reference to `jiffies'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:240: undefined reference to `jiffies'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:250: undefined reference to `current'
kernel/kernel.o: In function `sleep_if_full':
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:124: undefined reference to `current'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:124: undefined reference to `current'
kernel/kernel.o: In function `tty_write':
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:266: undefined reference to `current'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/tty_io.c:289: undefined reference to `schedule'
kernel/kernel.o: In function `interruptible_sleep_on':
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/sched.c:27: undefined reference to `current'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/sched.c:28: undefined reference to `current'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/sched.c:29: undefined reference to `schedule'
/home/ubuntu/linux_kernel/linux-dev/tty-init/kernel/sched.c:30: undefined reference to `current'
kernel/kernel.o:(.data+0xcac): undefined reference to `rs_write'
kernel/kernel.o:(.data+0x190c): undefined reference to `rs_write'
Makefile:47: recipe for target 'tools/system' failed
make: *** [tools/system] Error 1
```

https://blogs.oracle.com/d/inline-functions-in-c

https://elinux.org/Extern_Vs_Static_Inline
