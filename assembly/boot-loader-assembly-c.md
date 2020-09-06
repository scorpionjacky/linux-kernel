[Writing a boot loader in Assembly and C - Part 1](https://www.codeproject.com/Articles/664165/Writing-a-boot-loader-in-Assembly-and-C-Part)

`"C:\Program Files\qemu\qemu-system-x86_64.exe" -fda floppy.img  -boot a`

## Writing code in a C-Compiler

Example: test.c

```c
__asm__(".code16\n");
__asm__("jmpl $0x0000, $main\n");

void main() {
} 
```

File: test.ld

```
ENTRY(main);
SECTIONS
{
    . = 0x7C00;
    .text : AT(0x7C00)
    {
        *(.text);
    }
    .sig : AT(0x7DFE)
    {
        SHORT(0xaa55);
    }
} 
```
To compile:

```bash
gcc -c -g -Os -march=i686 -ffreestanding -Wall -Werror test.c -o test.o
ld -static -Ttest.ld -nostdlib --nmagic -o test.elf test.o
objcopy -O binary test.elf test.bin
```

```bash
gcc -c -g -Os -march=i686 -ffreestanding -Wall -Werror test.c -o test.o
```

What does each flag mean?
- -c: It is used to compile the given source code without linking.
- -g: Generates debug information to be used by GDB debugger.
- -Os: optimization for code size
- -march: Generates code for the specific CPU architecture (in our case i686)
- -ffreestanding: A freestanding environment is one in which the standard library may not exist, and program startup may not necessarily be at ‘main’.
- -Wall: Enable all compiler's warning messages. This option should always be used, in order to generate better code.
- -Werror: Enable warnings being treated as errors
- test.c: input source file name
- -o: generate object code
- test.o: output object code file name.

With all the above combinations of flags to the compiler, we try to generate object code which helps us in identifying errors, warnings and also produce much efficient code for the type of CPU. If you do not specify march=i686 it generates code for the machine type you have or else it on order to port it always better to specify which type of CPU are you targeting for.

```bash
ld -static -Ttest.ld -nostdlib --nmagic test.elf -o test.o
```

This is the command to invoke linker from the command prompt and I have explained below what are we trying to do with the linker.

What does each flag mean?
- -static: Do not link against shared libraries.
- -Ttest.ld: This feature permits the linker to follow commands from a linker script.
- -nostdlib: This feature permits the linker to generate code by linking no standard C library startup functions.
- --nmagic:This feature permits the linker to generate code without _start_SECTION and _stop_SECTION codes.
- test.elf: input file name(platform dependent file format to store executables Windows: PE, Linux: ELF)
- -o: generate object code
- test.o: output object code file name.

**What is a linker?**

It is the final stage of compilation. The ld(linker) takes one or more object files or libraries as input and combines them to produce a single (usually executable) file. In doing so, it resolves references to external symbols, assigns final addresses to procedures/functions and variables, and revises code and data to reflect new addresses (a process called relocation).

Also remember that we have no standard libraries and all fancy functions to use in our code.

```bash
objcopy -O binary test.elf test.bin
```

This command is used to generate platform independent code. Note that Linux stores executables in a different way than windows. Each have their own way storing files but we are just developing a small code to boot which does not depend on any operating system at the moment. So we are dependent on neither of those as we don't require an Operating system to run our code during boot time.

**Why use assembly statements inside a C program?**

In Real Mode, the BIOS functions can be easily accessed through software interrupts, using Assembly language instructions. This has lead to the usage of inline assembly in our C code.

**How to copy the executable code to a bootable device and then test it?**

To create a floppy disk image of 1.4mb size, type the following on the command prompt.

```bash
dd if=/dev/zero of=floppy.img bs=512 count=2880
```

To copy the code to the boot sector of the floppy disk image file, type the following on the command prompt.

```bash
dd if=test.bin of=floppy.img
```

To test the program type the following on the command prompt:

```bash
"C:\Program Files\qemu\qemu-system-x86_64.exe" -fda floppy.img  -boot a
```

Example: test2.c

*Note: We use `__volatile__` to hint the assembler not to modify our code and let it as it is.*

```c
__asm__(".code16\n");
__asm__("jmpl $0x0000, $main\n");

void main() {
     __asm__ __volatile__ ("movb $'X'  , %al\n");
     __asm__ __volatile__ ("movb $0x0e, %ah\n");
     __asm__ __volatile__ ("int $0x10\n");
}
```

Example: test3.c

```c
/*generate 16-bit code*/
__asm__(".code16\n");
/*jump boot code entry*/
__asm__("jmpl $0x0000, $main\n");

void main() {
     /*print letter 'H' onto the screen*/
     __asm__ __volatile__("movb $'H' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter 'e' onto the screen*/
     __asm__ __volatile__("movb $'e' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter 'l' onto the screen*/
     __asm__ __volatile__("movb $'l' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter 'l' onto the screen*/
     __asm__ __volatile__("movb $'l' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter 'o' onto the screen*/
     __asm__ __volatile__("movb $'o' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter ',' onto the screen*/
     __asm__ __volatile__("movb $',' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter ' ' onto the screen*/
     __asm__ __volatile__("movb $' ' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter 'W' onto the screen*/
     __asm__ __volatile__("movb $'W' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter 'o' onto the screen*/
     __asm__ __volatile__("movb $'o' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter 'r' onto the screen*/
     __asm__ __volatile__("movb $'r' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter 'l' onto the screen*/
     __asm__ __volatile__("movb $'l' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");

     /*print letter 'd' onto the screen*/
     __asm__ __volatile__("movb $'d' , %al\n");
     __asm__ __volatile__("movb $0x0e, %ah\n");
     __asm__ __volatile__("int  $0x10\n");
}
```

Example: test4.c

```c
/*generate 16-bit code*/
__asm__(".code16\n");
/*jump boot code entry*/
__asm__("jmpl $0x0000, $main\n");

/* user defined function to print series of characters terminated by null character */
void printString(const char* pStr) {
     while(*pStr) {
          __asm__ __volatile__ (
               "int $0x10" : : "a"(0x0e00 | *pStr), "b"(0x0007)
          );
          ++pStr;
     }
}

void main() {
     /* calling the printString function passing string as an argument */
     printString("Hello, World");
} 
```

## A mini-project to display rectangles

Example: test5.c
 
```c
/* generate 16 bit code                                                 */
__asm__(".code16\n");
/* jump to main function or program code                                */
__asm__("jmpl $0x0000, $main\n");

#define MAX_COLS     320 /* maximum columns of the screen               */
#define MAX_ROWS     200 /* maximum rows of the screen                  */

/* function to print string onto the screen                             */
/* input ah = 0x0e                                                      */
/* input al = <character to print>                                      */
/* interrupt: 0x10                                                      */
/* we use interrupt 0x10 with function code 0x0e to print               */
/* a byte in al onto the screen                                         */
/* this function takes string as an argument and then                   */
/* prints character by character until it founds null                   */
/* character                                                            */
void printString(const char* pStr) {
     while(*pStr) {
          __asm__ __volatile__ (
               "int $0x10" : : "a"(0x0e00 | *pStr), "b"(0x0007)
          );
          ++pStr;
     }
}

/* function to get a keystroke from the keyboard                        */
/* input ah = 0x00                                                      */
/* input al = 0x00                                                      */
/* interrupt: 0x10                                                      */
/* we use this function to hit a key to continue by the                 */
/* user                                                                                    */
void getch() {
     __asm__ __volatile__ (
          "xorw %ax, %ax\n"
          "int $0x16\n"
     );
}

/* function to print a colored pixel onto the screen                    */
/* at a given column and at a given row                                 */
/* input ah = 0x0c                                                      */
/* input al = desired color                                             */
/* input cx = desired column                                            */
/* input dx = desired row                                               */
/* interrupt: 0x10                                                      */
void drawPixel(unsigned char color, int col, int row) {
     __asm__ __volatile__ (
          "int $0x10" : : "a"(0x0c00 | color), "c"(col), "d"(row)
     );
}

/* function to clear the screen and set the video mode to               */
/* 320x200 pixel format                                                 */
/* function to clear the screen as below                                */
/* input ah = 0x00                                                      */
/* input al = 0x03                                                      */
/* interrupt = 0x10                                                     */
/* function to set the video mode as below                              */
/* input ah = 0x00                                                      */
/* input al = 0x13                                                      */
/* interrupt = 0x10                                                     */
void initEnvironment() {
     /* clear screen                                                    */
     __asm__ __volatile__ (
          "int $0x10" : : "a"(0x03)
     );
     __asm__ __volatile__ (
          "int $0x10" : : "a"(0x0013)
     );
}

/* function to print rectangles in descending order of                  */
/* their sizes                                                          */
/* I follow the below sequence                                          */
/* (left, top)     to (left, bottom)                                    */
/* (left, bottom)  to (right, bottom)                                   */
/* (right, bottom) to (right, top)                                      */
/* (right, top)    to (left, top)                                       */
void initGraphics() {
     int i = 0, j = 0;
     int m = 0;
     int cnt1 = 0, cnt2 =0;
     unsigned char color = 10;

     for(;;) {
          if(m < (MAX_ROWS - m)) {
               ++cnt1;
          }
          if(m < (MAX_COLS - m - 3)) {
               ++cnt2;
          }

          if(cnt1 != cnt2) {
               cnt1  = 0;
               cnt2  = 0;
               m     = 0;
               if(++color > 255) color= 0;
          }

          /* (left, top) to (left, bottom)                              */
          j = 0;
          for(i = m; i < MAX_ROWS - m; ++i) {
               drawPixel(color, j+m, i);
          }
          /* (left, bottom) to (right, bottom)                          */
          for(j = m; j < MAX_COLS - m; ++j) {
               drawPixel(color, j, i);
          }

          /* (right, bottom) to (right, top)                            */
          for(i = MAX_ROWS - m - 1 ; i >= m; --i) {
               drawPixel(color, MAX_COLS - m - 1, i);
          }
          /* (right, top)   to (left, top)                              */
          for(j = MAX_COLS - m - 1; j >= m; --j) {
               drawPixel(color, j, m);
          }
          m += 6;
          if(++color > 255)  color = 0;
     }
}

/* function is boot code and it calls the below functions               */
/* print a message to the screen to make the user hit the               */
/* key to proceed further and then once the user hits then              */
/* it displays rectangles in the descending order                       */
void main() {
     printString("Now in bootloader...hit a key to continue\n\r");
     getch();
     initEnvironment();
     initGraphics();
}
```

[Writing a boot loader in Assembly and C - Part 2](https://www.codeproject.com/Articles/668422/Writing-a-boot-loader-in-Assembly-and-C-Part-2)

[Writing a 16-bit dummy kernel in C/C++](https://www.codeproject.com/Articles/737545/Writing-a-bit-dummy-kernel-in-C-Cplusplus)
