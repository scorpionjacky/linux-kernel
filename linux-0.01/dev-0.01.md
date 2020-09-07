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

int main(void) {
        //char* video_memory = (char*) 0xb8000;
        //*video_memory = 'X';
	//for(;;) pause();
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

https://blogs.oracle.com/d/inline-functions-in-c

https://elinux.org/Extern_Vs_Static_Inline
