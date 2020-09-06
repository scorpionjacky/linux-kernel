# Writing a boot loader in Assembly and C

[*Part 1*](https://www.codeproject.com/Articles/664165/Writing-a-boot-loader-in-Assembly-and-C-Part), 
[*Part 2*](https://www.codeproject.com/Articles/668422/Writing-a-boot-loader-in-Assembly-and-C-Part-2)

What are registers?

Registers are like utilities of a microprocessor to store data temporarily and manipulate it as per our requirements. Suppose say if the user wants to add 3 with 2, the user asks the computer to store number 3 in one register and number 2 in more register and then add the contents of the these two registers and the result is placed in another register by the CPU which is the output that we desire to see. There are four types of registers and are listed below.

General purpose registers
- Segment registers
- Stack registers
- Index registers
- Let me brief you about each of the types.

General purpose registers: These are used to store temporary data required by the program during its lifecycle. Each of these registers is 16 bit wide or 2 bytes long.
- AX - the accumulator register
- BX - the base address register
- CX - the count register
- DX - the data register

Segment Registers: To represent a memory address to a microprocessor, there are two terms we need to be aware of:
- Segment: It is usually the beginning of the block of a memory.
- Offset: It is the index of memory block onto it.

Example: Suppose say, there is a byte whose value is 'X' that is present on a block of memory whose start address is 0x7c00 and the byte is located at the 10th position from the beginning. In this situation, We represent segment as 0x7c00 and the offset as 10.
The absolute address is 0x7c00 + 10.

There are four categories that I wanted to list out.
- CS - code segment
- SS - stack segment
- DS - data segment
- ES - extended segment

But there is always a limitation with these registers. You cannot directly assign an address to these registers. What we can do is, copy the address to a general purpose registers and then copy the address from that register to the segment registers. Example: To solve the problem of locating byte 'X', we do the following way

```asm
movw $0x07c0, %ax
movw %ax    , %ds
movw (0x0A) , %ax 
```

In our case what happens is
- set 0x07c0 * 16 in AX
- set DS = AX = 0x7c00
- set 0x7c00 + 0x0a to ax

Stack Registers:
- BP - base pointer
- SP - stack pointer

Index Registers:
- SI - source index register.
- DI - destination index register.
- AX: CPU uses it for arithmetic operations.
- BX: It can hold the address of a procedure or variable (SI, DI, and BP can also). And also perform arithmetic and data movement.
- CX: It acts as a counter for repeating or looping instructions.
- DX: It holds the high 16 bits of the product in multiply (also handles divide operations).
- CS: It holds base location for all executable instructions in a program.
- SS: It holds the base location of the stack.
- DS: It holds the default base location for variables.
- ES: It holds additional base location for memory variables.
- BP: It contains an assumed offset from the SS register. Often used by a subroutine to locate variables that were passed on the stack by a calling program.
- SP: Contains the offset of the top of the stack.
- SI: Used in string movement instructions. The source string is pointed to by the SI register.
- DI: Acts as the destination for string movement instructions.

What are interrupts?

To interrupt the ordinary flow of a program and to process events that require prompt response we use interrupts. The hardware of a computer provides a mechanism called interrupts to handle events. For example, when a mouse is moved, the mouse hardware interrupts the current program to handle the mouse movement (to move the mouse cursor, etc.) Interrupts cause control to be passed to an interrupt handler. Interrupt handlers are routines that process the interrupt. Each type of interrupt is assigned an integer number. At the beginning of physical memory, a table of interrupt vectors resides that contain the segmented addresses of the interrupt handlers. The number of interrupt is essentially an index into this table. We can also called as the interrupt as a service offered by BIOS.

Which interrupt service are we going to use in our programs?
- Bios interrupt 0x10.

## Writing code in an Assembler

What is a data type?

A data type is used to identify the characteristic of a data. Various data types are as below.
- byte (1 byte)
- word (2 byte)
- int (4 byte)
- ascii (group of bytes with out a null terminator)
- asciz (roup of bytes terminated with a null character)

Example: test.S  
 
```asm
.code16                   #generate 16-bit code
.text                     #executable code location
     .globl _start;
_start:                   #code entry point
     . = _start + 510     #mov to 510th byte from 0 pos
     .byte 0x55           #append boot signature
     .byte 0xaa           #append boot signature
```

- .code16: It is a directive or a command given to an assembler to generate 16-bit code rather than 32-bit ones. Why is this hint necessary? Remember that you will be using an operating system to utilize an assembler and a compiler to write boot loader code. However, I have also mentioned that an operating system works in 32 bit protected mode. So when you utilize assembler on a protected mode operating system, it’s configured by default to produce 32-bit code rather than 16-bit code, which does not serve the purpose, as we need 16-bit code. To avoid assembler and compilers generating 32-bit code, we use this directive.
- .text: The .text section contains the actual machine instructions, which make up your program.
- .globl _start: .global <symbol> makes the symbol visible to linker. If you define symbol in your partial program, its value is made available to other partial programs that are linked with it. Otherwise, symbol takes its attributes from a symbol of the same name from another file linked into the same program.
- _start: Entry to the main code and _start is the default entry point for the linker.
- . = _start + 510: traverse from beginning through 510th byte
- .byte 0x55: It is the first byte identified as a part of the boot signature.(511th byte)
- .byte 0xaa: It is the last byte identified as a part of the boot signature.(512th byte )

How to compile an assembly program?

```bash
as test.S -o test.o
ld –Ttext 0x7c00 --oformat=binary test.o –o test.bin
```

What does the above commands means to us anyway?
- as test.S –o test.o: this command converts the given assembly code into respective object code which is an intermediate code generated by the assembler before converting into machine code.
- The --oformat=binary switch tells the linker you want your output file to be a plain binary image (no startup code, no relocations, ...).
- The –Ttext 0x7c00 tells the linker you want your "text" (code segment) address to be loaded to 0x7c00 and thus it calculates the correct address for absolute addressing.

What is a boot signature?

Remember earlier I was briefing about boot record or boot sector loaded by BIOS program. How does BIOS recognize if a device contains a boot sector or not? To answer this, I can tell you that a boot sector is 512 bytes long and in 510th byte a symbol 0x55 is expected and in the 511th byte another symbol 0xaa is expected. So I verifies if the last two bytes of a boot sector are 0x55 and 0xaa and if it is then it identifies that sector as a boot sector and proceeds execution of the boot sector code or else it throws an error that the device is not bootable. Using a hexadecimal editor you can view the contents of the binary file in a more readable way and below is the snapshot for your reference when you view the file using the hexedit tool.

How to copy the executable code to a bootable device and then test it?

To create a floppy disk image of 1.4mb size, type the following on the command prompt.

```bash
dd if=/dev/zero of=floppy.img bs=512 count=2880
```

To copy the code to the boot sector of the floppy disk image file, type the following on the command prompt.

```bash
dd if=test.bin of=floppy.img
```

To test the program type the following on the command prompt

```bash
"C:\Program Files\qemu\qemu-system-x86_64.exe" -fda floppy.img  -boot a
```

Example: test2.S    

```asm
.code16                    #generate 16-bit code
.text                      #executable code location
     .globl _start;
_start:                    #code entry point

     movb $'X' , %al       #character to print
     movb $0x0e, %ah       #bios service code to print
     int  $0x10            #interrupt the cpu now

     . = _start + 510      #mov to 510th byte from 0 pos
     .byte 0x55            #append boot signature
     .byte 0xaa            #append boot signature 
```

Example: test3.S

```asm
.code16                  #generate 16-bit code
.text                    #executable code location
     .globl _start;

_start:                  #code entry point

     #print letter 'H' onto the screen
     movb $'H' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter 'e' onto the screen
     movb $'e' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter 'l' onto the screen
     movb $'l' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter 'l' onto the screen
     movb $'l' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter 'o' onto the screen
     movb $'o' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter ',' onto the screen
     movb $',' , %al
     movb $0x0e, %ah
     int  $0x10

     #print space onto the screen
     movb $' ' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter 'W' onto the screen
     movb $'W' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter 'o' onto the screen
     movb $'o' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter 'r' onto the screen
     movb $'r' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter 'l' onto the screen
     movb $'l' , %al
     movb $0x0e, %ah
     int  $0x10

     #print letter 'd' onto the screen
     movb $'d' , %al
     movb $0x0e, %ah
     int  $0x10

     . = _start + 510      #mov to 510th byte from 0 pos
     .byte 0x55            #append boot signature
     .byte 0xaa            #append boot signature 
```


Example: test4.S

Let us write an assembly program to print the letters “Hello, World” onto the screen. We will also try to define functions and macros through which we will try to print the string.

```asm
#generate 16-bit code
.code16

#hint the assembler that here is the executable code located
.text
.globl _start;
#boot code entry
_start:
      jmp _boot                           #jump to boot code
      welcome: .asciz "Hello, World\n\r"  #here we define the string

     .macro mWriteString str              #macro which calls a function to print a string
          leaw  \str, %si
          call .writeStringIn
     .endm

     #function to print the string
     .writeStringIn:
          lodsb
          orb  %al, %al
          jz   .writeStringOut
          movb $0x0e, %ah
          int  $0x10
          jmp  .writeStringIn
     .writeStringOut:
     ret

_boot:
     mWriteString welcome

     #move to 510th byte from the start and append boot signature
     . = _start + 510
     .byte 0x55
     .byte 0xaa  
```

What is a function?

A function is a block of code that has a name and it has a property that it is reusable.

What is a macro?

A macro is a fragment of code, which has been given a name. Whenever the name is used, it is replaced by the contents of the macro.

What is the difference between a macro and a function in terms of syntax?

To call a function we use the below syntax.

```
push <argument>
call <function name>
```

To call a macro we use the below syntax

`macroname <argument>`

But the calling and usage syntax of the macro is very simple when compared to that of a function. So I preferred to write a macro and use it instead of calling a function in the main code. You can refer to more materials online as to how to write assembly code on GNU Assembler.

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

## Introduction to Segmentation

**Code Segment (CS)**

It is one of the sections of a program in memory that contains the executable instructions. If you refer to my previous article, you will see the label .text where under which we intend to place the instructions to execute. When the program is loaded into memory, the instructions under section .text are placed into code segment. In CPU, we use CS register to refer to the code segment in memory.

**Data Segment (DS)**

It is one of the sections of a program in memory that contains variables both static and global by the programmer. We use DS register to refer to the data segment in memory.

**Stack Segment (SS)**

A programmer can use registers to store, modify and retrieve data during the scope of the program that he has written. As there are only a few registers available for a programmer to use during the run time of the program, there is always a chance that the program logic might get complicated, as there are only a few registers available for temporary use. Due to this, the programmer might always feel the need for a bigger place, which is more flexible in terms of storing, processing and retrieving data. The CPU designers have come up with a special segment called the stack segment. In order to store and retrieve data on stack segment, the programmer uses push and pop instructions. We use push instructions to pass arguments to functions as well. We use SS register to refer to the stack segment in memory. Also remember that stack grows downwards.

**Extended Segment (ES)**

The extended segment is normally used to load data that is much bigger than the size of the data that is stored in data segment. You will further see that I will try to load the data from the floppy on Extended segment. We use ES register to refer to the Extended Segment in memory.

How to set Segment registers?

```asm
movw $0x07c0, %ax
movw %ax, %ds 
```

Now DS becomes 0x7c00 (16 * AX). 

*Note that segment registers can be set only through general registers*



[Writing a boot loader in Assembly and C - Part 2](https://www.codeproject.com/Articles/668422/Writing-a-boot-loader-in-Assembly-and-C-Part-2)

[Writing a 16-bit dummy kernel in C/C++](https://www.codeproject.com/Articles/737545/Writing-a-bit-dummy-kernel-in-C-Cplusplus)
