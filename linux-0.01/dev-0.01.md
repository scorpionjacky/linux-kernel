# Self-Built 0.01

## include/asm/*

Header files in `include/asm` all all aseembly code and are indepedent and foundamental. They will be included in the source tree.

**include/asm/*** : all `__asm__` code
- io.h
    - Macros: outb(value,port), inb(port), outb_p(value,port), inb_p(port)
- memory.h
    - Macro: memcpy(dest,src,n)
- segment.h: extern inline functions
    - unsigned char get_fs_byte(const char * addr)
    - unsigned short get_fs_word(const unsigned short * addr)
    - unsigned long get_fs_long(const unsigned long * addr)
    - void put_fs_byte(char val,char * addr)
    - void put_fs_word(short val, unsigned short * addr)
    - void put_fs_long(unsigned long val,unsigned long * addr)
    - void put_fs_long64(unsigned long val,unsigned long long * addr)
- system.h
    - move_to_user_mode()
    - sti(), cli(), nop(), iret()
    - set_intr_gate(n,addr), set_trap_gate(n,addr), set_system_gate(n,addr)
    - set_tss_desc(n,addr), set_ldt_desc(n,addr)

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

## lib

lib
- \_exit.c (void \_exit(int exit_code))
  - unistd.h
- close.c (\_syscall1(int,close,int,fd))
  - unistd.h
- ctype.c (signed char \_ctmp; unsigned char \_ctype[])
  - ctype.h
- dup.c (\_syscall1(int,dup,int,fd))
  - unistd.h
- errno.c (int errno;)
- execve.c (`_syscall3(int, execve, const char*, file, char**, argv, char**, envp)`)
  - unistd.h
- open.c (`int open(const char * filename, int flag, ...)`)
  - unistd.h
  - stdarg.h
- setsid.c (\_syscall0(pid_t,setsid))
  - unistd.h
- string.c
  - string.h (independent, details see below)
- wait.c (`_syscall3(pid_t,waitpid,pid_t,pid,int *,wait_stat,int,options)`, `pid_t wait(int * wait_stat) {return waitpid(-1,wait_stat,0);}`)
  - unistd.h
  - sys/wait.h
    - [sys/types.h](https://github.com/mariuz/linux-0.01/blob/master/include/sys/types.h) (indepedent)
- write.c (`_syscall3(int,write,int,fd,const char *,buf,off_t,count)`)
  - unistd.h

- ctype.h: only tied to ctype.c
- stdarg.h: (independent)
- string.h: (indepedent)
  - #define NULL ((void *) 0)
  - typedef unsigned int size_t;
  - extern char * strerror(int errno);
  - extern inline char * strcpy(char * dest,const char *src)
  - extern inline char * strncpy(char * dest,const char *src,int count)
  - extern inline char * strcat(char * dest,const char * src)
  - extern inline char * strncat(char * dest,const char * src,int count)
  - extern inline int strcmp(const char * cs,const char * ct)
  - extern inline int strncmp(const char * cs,const char * ct,int count)
  - extern inline char * strchr(const char * s,int c)
  - extern inline char * strrchr(const char * s,int c)
  - extern inline int strspn(const char * cs, const char * ct)
  - extern inline int strcspn(const char * cs, const char * ct)
  - extern inline char * strpbrk(const char * cs,const char * ct)
  - extern inline char * strstr(const char * cs,const char * ct)
  - extern inline int strlen(const char * s)
  - extern char * ___strtok;
  - extern inline char * strtok(char * s,const char * ct)
  - extern inline void * memcpy(void * dest,const void * src, int n)
  - extern inline void * memmove(void * dest,const void * src, int n)
  - extern inline int memcmp(const void * cs,const void * ct,int count)
  - extern inline void * memchr(const void * cs,char c,int count)
  - extern inline void * memset(void * s,int c,int count)
- [unistd.h](https://github.com/mariuz/linux-0.01/blob/master/include/unistd.h)
  - #define STDIN_FILENO	0
  - #define STDOUT_FILENO	1
  - #define STDERR_FILENO	2
  - #define NULL ((void *)0)
  - sys/stat.h
    - sys/types.h
    - stdint.h (independent)
      - bits/wchar.h, bits/wordsize.h
    - fs/stat.c
      - *more includes*
  - sys/times.h
    - sys/types.h
    - struct tms {}
    - extern time_t times(struct tms * tp);
  - sys/utsname.h
    - struct utsname {...}
    - extern int uname (struct utsname *__name);
  - utime.h
  - dirent.h
  - #define __NR_setup , up to 221, used only by init, to get system going
  - ...
  - #define _syscall0(type,name)
  - #define _syscall1(type,name,atype,a)
  - #define _syscall2(type,name,atype,a,btype,b)
  - #define _syscall3(type,name,atype,a,btype,b,ctype,c)
  - extern int errno;
  - a lot of Unix standard function protocols
- sys/wait.h

Basically all header files in include/sys and include/bits have been referenced above:
- include/sys
  - stat.h
  - times.h
  - types.h
  - utsname.h
  - wait.h
- bits
  - wchar.h
  - wordsize.h

lib/string.c + include/string.h are completely independent

`include/asm/*.h` are completely independent

`include/bits/wchar.h` and `include/bits/wordsize.h` are completely independent, and only used by `include/stdint.h`.

`include/errno.h` and `lib/errno.c` are completely independent.

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

extern void schedule(void);
extern struct task_struct *task[NR_TASKS];
extern struct task_struct *last_task_used_math;
extern struct task_struct *current;
extern long volatile jiffies;
```

create a customized kernel/sched.c:

```c
#include <linux/sched.h>

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
	if (current == &(init_task.task))
		panic("task[0] trying to sleep");
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

Make lib/Makefile to compile only for errono.o and ctype.o.


https://blogs.oracle.com/d/inline-functions-in-c

https://elinux.org/Extern_Vs_Static_Inline
