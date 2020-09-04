# Self-Built 0.11

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
