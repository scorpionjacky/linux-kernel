**include/asm/\***

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
