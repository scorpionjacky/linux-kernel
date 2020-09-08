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

kernel/asm.s + kernel/system_call.s + kernel/sys.c + kernel/traps.c: interrupt and exceptions registration

asm.s contains the low-level code for most hardware faults; page_exception is handled by the mm

## kernel/*

kernel
  - kernel/asm.s (in Linux 1.0, it is moved to sys_call.S; system_call.s is renamed to sys_call.S)
    - .globl divide_error,debug,nmi,int3,overflow,bounds,invalid_op
    - .globl device_not_available,double_fault,coprocessor_segment_overrun
    - .globl invalid_TSS,segment_not_present,stack_segment
    - .globl general_protection,coprocessor_error,reserved
  - console.c
    - #include <linux/sched.h>
    - #include <linux/tty.h>
    - #include <asm/io.h>
    - #include <asm/system.h>
    - #define SCREEN_START 0xb8000
    - #define SCREEN_END   0xc0000
    - #define LINES 25
    - #define COLUMNS 80
    - #define NPAR 16
    - extern void keyboard_interrupt(void);
    - unsigned char attr=0x07;
    - void csi_m(void){}
    - void con_write(struct tty_struct * tty){}
    - void con_init(void){}
  - kernel/exit.c (do_exit() referenced in traps.c)
    - #include <errno.h>
    - #include <signal.h>
    - #include <sys/wait.h>
    - #include <linux/sched.h>
    - #include <linux/kernel.h>
    - #include <linux/tty.h>
    - #include <asm/segment.h>
    - int sys_pause(void);
    - int sys_close(int fd);
    - void release(struct task_struct * p){}
    - void do_kill(long pid,long sig,int priv){}
    - int sys_kill(int pid,int sig){}
    - int do_exit(long code){}
    - int sys_exit(int error_code){}
    - int sys_waitpid(pid_t pid,int * stat_addr, int options){}
  - kernel/fork.c
    - #include <errno.h>
    - #include <linux/sched.h>
    - #include <linux/kernel.h>
    - #include <asm/segment.h>
    - #include <asm/system.h>
    - extern void write_verify(unsigned long address);
    - extern void memcpy(struct task_struct *, struct task_struct *, long int);
    - long last_pid=0;
    - void verify_area(void * addr,int size){}
    - int copy_mem(int nr,struct task_struct * p){}
    - int copy_process(...){}
    - int find_empty_process(void){}
  - kernel/hd.c
  - kernel/keyboard.s
    - .globl keyboard_interrupt
  - kernel/mktime.c (soly dependent on include/time.h)
    - #include <time.h>
    - long kernel_mktime(struct tm * tm) (used in main.c)
  - kernel/panic.c
    - #include <linux/kernel.h>
    - void panic(const char * s){	printk("Kernel panic: %s\n\r",s);	for(;;);}
  - kernel/printk.c
    - #include <stdarg.h>
    - #include <stddef.h>
    - #include <linux/kernel.h>
    - extern int vsprintf();
    - static char buf[1024];
    - int printk(const char *fmt, ...){}
  - kernel/rs_io.s
    - .globl rs1_interrupt,rs2_interrupt
  - kernel/sched.c
  - kernel/serial.c
    - #include <linux/tty.h>
    - #include <linux/sched.h>
    - #include <asm/system.h>
    - #include <asm/io.h>
    - #define WAKEUP_CHARS (TTY_BUF_SIZE/4)
    - extern void rs1_interrupt(void);
    - extern void rs2_interrupt(void);
    - void rs_init(void){}
    - void rs_write(struct tty_struct * tty){}
  - [sys.c](https://github.com/mariuz/linux-0.01/blob/master/kernel/sys.c)
    - #include <errno.h>
    - #include <linux/sched.h>
    - #include <linux/tty.h>
    - #include <linux/kernel.h>
    - #include <asm/segment.h>
    - #include <sys/times.h>
    - #include <sys/utsname.h>
    - int sys_ftime(){}
    - int sys_mknod(){}
    - int sys_break(){}
    - int sys_mount(){}
    - int sys_umount(){}
    - int sys_ustat(int dev,struct ustat * ubuf){}
    - int sys_ptrace(){}
    - int sys_stty(){}
    - int sys_gtty(){}
    - int sys_rename(){}
    - int sys_prof(){}
    - int sys_setgid(int gid){}
    - int sys_acct(){}
    - int sys_phys(){}
    - int sys_lock(){}
    - int sys_mpx(){}
    - int sys_ulimit(){}
    - int sys_time(long * tloc){}
    - int sys_setuid(int uid){}
    - int sys_stime(long * tptr){}
    - int sys_times(struct tms * tbuf){}
    - int sys_brk(unsigned long end_data_seg){}
    - int sys_setpgid(int pid, int pgid){}
    - int sys_getpgrp(void){}
    - int sys_setsid(void){}
    - int sys_oldolduname(void* v){}
    - int sys_uname(struct utsname * name){}
    - int sys_umask(int mask){}
    - int sys_null(int nr){}
  - [system_call.s](https://github.com/mariuz/linux-0.01/blob/master/kernel/system_call.s)
    - .globl system_call,sys_fork,timer_interrupt,hd_interrupt,sys_execve
    - uses `sys_call_table`, `sys_null`, `current`, `signal()`, `sig_fn()`
    - uses `EIP()`, `OLDESP()`, `verify_area`m `restorer()`
    - uses manyh more
  - traps.c
    - #include <string.h>
    - #include <linux/head.h> (uses idt)
      - typedef struct desc_struct {}
      - extern unsigned long pg_dir[1024];
      - extern desc_table idt,gdt;
      - #define GDT_NUL 0 | GDT_CODE 1 | GDT_DATA 2 | GDT_TMP 3
      - #define LDT_NUL 0 | LDT_CODE 1 | LDT_DATA 2
    - #include <linux/sched.h> (using *current)
    - #include <linux/kernel.h> (ignore it if we don't use printk())
      - void verify_area(void * addr,int count);
      - void panic(const char * str);
      - int printf(const char * fmt, ...);
      - int printk(const char * fmt, ...);
      - int tty_write(unsigned ch,char * buf,int count);
    - #include <asm/system.h>
    - #include <asm/segment.h>
    - void trap_init(void)
    - do_double_fault(long esp, long error_code){}
    - void do_general_protection(long esp, long error_code){}
    - void do_divide_error(long esp, long error_code){}
    - void do_int3(...){}
    - void do_nmi(long esp, long error_code){}
    - void do_debug(long esp, long error_code){}
    - void do_overflow(long esp, long error_code){}
    - void do_bounds(long esp, long error_code){}
    - void do_invalid_op(long esp, long error_code){}
    - void do_device_not_available(long esp, long error_code){}
    - void do_coprocessor_segment_overrun(long esp, long error_code){}
    - void do_invalid_TSS(long esp,long error_code){}
    - void do_segment_not_present(long esp,long error_code){}
    - void do_stack_segment(long esp,long error_code){}
    - void do_coprocessor_error(long esp, long error_code){}
    - void do_reserved(long esp, long error_code){}
    - void trap_init(void){
      - set_trap_gate(0,&divide_error);
      - set_trap_gate(1,&debug);
      - set_trap_gate(2,&nmi);
      - set_system_gate(3,&int3);	/* int3-5 can be called from all */
      - set_system_gate(4,&overflow);
      - set_system_gate(5,&bounds);
      - set_trap_gate(6,&invalid_op);
      - set_trap_gate(7,&device_not_available);
      - set_trap_gate(8,&double_fault);
      - set_trap_gate(9,&coprocessor_segment_overrun);
      - set_trap_gate(10,&invalid_TSS);
      - set_trap_gate(11,&segment_not_present);
      - set_trap_gate(12,&stack_segment);
      - set_trap_gate(13,&general_protection);
      - set_trap_gate(14,&page_fault);
      - set_trap_gate(15,&reserved);
      - set_trap_gate(16,&coprocessor_error);
      - for (i=17;i<32;i++)
        - set_trap_gate(i,&reserved);
  - kernel/tty_io.c
    - #include <ctype.h>
    - #include <errno.h>
    - #include <signal.h>
    - #define ALRMMASK (1<<(SIGALRM-1))
    - #include <linux/sched.h>
    - #include <linux/tty.h>
    - #include <asm/segment.h>
    - #include <asm/system.h>
    - struct tty_struct tty_table[] = {...}
    - struct tty_queue * table_list[]={...}
    - void tty_init(void)
      - rs_init();
      - con_init();
    - void tty_intr(struct tty_struct * tty, int signal){}
    - void copy_to_cooked(struct tty_struct * tty){}
    - int tty_read(unsigned channel, char * buf, int nr){}
    - int tty_write(unsigned channel, char * buf, int nr){}
    - void do_tty_interrupt(int tty){	copy_to_cooked(tty_table+tty);}
  - kernel/vsprintf.c
    - #include <stdarg.h>
    - #include <string.h>
    - #define is_digit(c)	((c) >= '0' && (c) <= '9')
    - #define ZEROPAD	1		/* pad with zero */
    - #define SIGN	2		/* unsigned/signed long */
    - #define PLUS	4		/* show plus */
    - #define SPACE	8		/* space if plus */
    - #define LEFT	16		/* left justified */
    - #define SPECIAL	32		/* 0x */
    - #define SMALL	64		/* use 'abcdef' instead of 'ABCDEF' */
    - #define do_div(n,base)
    - int vsprintf(char *buf, const char *fmt, va_list args){}


all symbols above are referenced in traps.c by trap.init(), and still needing &page_fault

## mm/*

mm
- mm/page.s (page.s contains the low-level page-exception code. the real work is done in mm.c)
  - .globl page_fault
  - call do_no_page (in mm.c)
  - call do_wp_page (in mm.c)
- mm/mm.c
  - #include <signal.h>
  - #include <linux/config.h>
  - #include <linux/head.h>
  - #include <linux/kernel.h>
  - #include <linux/mm.h>
  - #include <asm/system.h>
  - int do_exit(long code);
  - inline void invalidate(){}
  - #define LOW_MEM 0x100000 / #define LOW_MEM BUFFER_END
  - #define PAGING_MEMORY (HIGH_MEMORY - LOW_MEM)
  - #define PAGING_PAGES (PAGING_MEMORY/4096)
  - #define MAP_NR(addr) (((addr)-LOW_MEM)>>12)
  - inline void copy_page(unsigned long from,unsigned long to){}
  - unsigned long get_free_page(void){}
  - void free_page(unsigned long addr){}
  - int free_page_tables(unsigned long from,unsigned long size){}
  - int copy_page_tables(unsigned long from,unsigned long to,long size){}
  - unsigned long put_page(unsigned long page,unsigned long address){}
  - void un_wp_page(unsigned long * table_entry){}
  - void do_wp_page(unsigned long error_code,unsigned long address){}
  - void write_verify(unsigned long address){}
  - void do_no_page(unsigned long error_code,unsigned long address){}
  - void calc_mem(void){}

## fs/*

## others

include/const.h (who use it?)
- #define BUFFER_END 0x200000
- #define I_TYPE          0170000
- #define I_DIRECTORY	0040000
- #define I_REGULAR       0100000
- #define I_BLOCK_SPECIAL 0060000
- #define I_CHAR_SPECIAL  0020000
- #define I_NAMED_PIPE	0010000
- #define I_SET_UID_BIT   0004000
- #define I_SET_GID_BIT   0002000

include/[stdint.h](https://github.com/mariuz/linux-0.01/blob/master/include/stdint.h)
- #include <bits/wchar.h>
- #include <bits/wordsize.h>
- int8_t, int16_t, int32_t, int64_t, uint8_t, uint16_t, uint32_t, uint64_t
- int_least8_t, int_least16_t, int_least32_t, int_least64_t
- more ...
- used by include/sys/stat.h

include/ctype.h: independent

include/sys/types.h: independent
- pid_t, gid_t, mode_t, ushort, etc.
- struct ustat {}
- used by include/sys/stat.h, include/utime.h
- used by include/sys/times.h, include/sys/wait.h

include/sys/times.h
- struct tms {time_t tms_utime;	time_t tms_stime;	time_t tms_cutime;	time_t tms_cstime;};
- extern time_t times(struct tms * tp);

include/utime.h
  - #include <sys/types.h>
  - struct utimbuf {time_t actime;	time_t modtime;};
  - extern int utime(const char *filename, struct utimbuf *times);

kernel/mktime.c soly dependent on include/time.h
- kernel/mktime.c soly dependent on include/time.h
  - #include <time.h>
  - long kernel_mktime(struct tm * tm) (used in main.c)
- include/time.h
  - struct tm {}
  - and more

include/time.h ?????

include/errno.h + lib/errno.c:  int errno; (independent combined)

- include/stddef.h: (independent)
  - typedef long ptrdiff_t;
  - typedef unsigned long size_t;
  - #define NULL ((void *\)0)
  - #define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *\)0)->MEMBER)
- include/stdarg.h: (independent)
  - typedef char \*va_list;
  - va_start, va_end, va_arg
- include/string.h: (indepedent)
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

## lib/*

lib
- \_exit.c (void \_exit(int exit_code))
  - unistd.h
  - void \_exit(int exit_code)
- close.c (\_syscall1(int,close,int,fd))
  - unistd.h
  - \_syscall1(int,close,int,fd)
- ctype.c (signed char \_ctmp; unsigned char \_ctype[])
  - ctype.h
  - signed char \_ctmp;
  - unsigned char \_ctype[] = {...}
- dup.c (\_syscall1(int,dup,int,fd))
  - unistd.h
  - \_syscall1(int,dup,int,fd)
- errno.c (only one line)
  - int errno;
- execve.c
  - unistd.h
  - `_syscall3(int,execve,const char *,file,char **,argv,char **,envp)`
- open.c (`int open(const char * filename, int flag, ...)`)
  - unistd.h
  - stdarg.h
  - int open(const char * filename, int flag, ...) {...}
- setsid.c (\_syscall0(pid_t,setsid))
  - unistd.h
  - \_syscall0(pid_t,setsid)
- string.c
  - #define extern
  - #define inline
  - #define __LIBRARY__
  - #include <string.h> (independent, details see below)
- wait.c (`_syscall3(pid_t,waitpid,pid_t,pid,int *,wait_stat,int,options)`, `pid_t wait(int * wait_stat) {return waitpid(-1,wait_stat,0);}`)
  - \_syscall3(pid_t,waitpid,pid_t,pid,int *,wait_stat,int,options)
  - pid_t wait(int * wait_stat){	return waitpid(-1,wait_stat,0);}
  - unistd.h
  - sys/wait.h
    - [sys/types.h](https://github.com/mariuz/linux-0.01/blob/master/include/sys/types.h) (indepedent)
- write.c (`_syscall3(int,write,int,fd,const char *,buf,off_t,count)`)
  - unistd.h
  - \_syscall3(int,write,int,fd,const char *,buf,off_t,count)

## include/\*.h

include
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
