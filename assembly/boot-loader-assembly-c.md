# Writing a boot loader in Assembly and C

[*Part 1*](https://www.codeproject.com/Articles/664165/Writing-a-boot-loader-in-Assembly-and-C-Part), 
[*Part 2*](https://www.codeproject.com/Articles/668422/Writing-a-boot-loader-in-Assembly-and-C-Part-2), 
[*Writing a 16-bit dummy kernel in C/C++*](https://www.codeproject.com/Articles/737545/Writing-a-bit-dummy-kernel-in-C-Cplusplus)


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

## Reading data from RAM

Example 1: test.S

Once our program is loaded by BIOS at 0x7c00, let us try to read data from offset 3 and 4 and then print them onto the screen.

```asm
.code16                   #generate 16-bit code
.text                     #executable code location
     .globl _start;
_start:                   #code entry point
     jmp  _boot           #jump to boot code
     data : .byte 'X'     #variable
     data1: .byte 'Z'     #variable
_boot:
     movw $0x07c0, %ax    #set ax = 0x07c0
     movw %ax    , %ds    #set ds = 16 * 0x07c0 = 0x7c00
     #Now we will copy the data at position 3 from 0x7c00:0x0000
     # and then print it onto the screen
     movb 0x02   , %al    #copy the data at 2nd position to %al
     movb $0x0e  , %ah
     int  $0x10
    #Now we will copy the data at position 4 from 0x7c00:0x0000
    # and then print it onto the screen
     movb 0x03   , %al    #copy the data at 3rd position to %al
     movb $0x0e  , %ah
     int  $0x10
#infinite loop
_freeze:
     jmp _freeze
     . = _start + 510     #mov to 510th byte from 0 pos
     .byte 0x55           #append boot signature
     .byte 0xaa           #append boot signature 
```

```bash
as test.S –o test.o
ld –Ttext=0x7c00 –oformat=binary boot.o –o boot.bin
dd if=/dev/zero of=floppy.img bs=512 count=2880
dd if=boot.bin of=floppy.img
````

Example 2: test2.S

Once our program is loaded by BIOS at 0x7c00, let us read a null terminated string from offset 2 and then print it.

```asm
.code16                                     #generate 16-bit code
.text                                       #executable code location
     .globl _start;
_start:                                     #code entry point
     jmp  _boot                             #jump to boot code
     data : .asciz "This is boot loader"    #variable
     #calls the printString function which
     #starts printing string from the position
     .macro mprintString start_pos          #macro to print string
          pushw %si
          movw  \start_pos, %si
          call  printString
          popw  %si
     .endm 
     printString:                           #function to print string
     printStringIn:
          lodsb
          orb %al   , %al
          jz  printStringOut
          movb $0x0e, %ah
          int  $0x10
          jmp  printStringIn
     printStringOut:
     ret
_boot:
     movw $0x07c0, %ax                      #set ax = 0x07c0
     movw %ax    , %ds                      #set ds = 16 * 0x07c0 = 0x7c00
     mprintString $0x02
_freeze:
     jmp _freeze
     . = _start + 510                       #mov to 510th byte from 0 pos
     .byte 0x55                             #append boot signature
     .byte 0xaa                             #append boot signature  
```

## Interaction with a floppy disk

As our mission in this article is to read data from a floppy disk, the only choice left to us as of now is to use BIOS Services in our program as during the boot time we are in Real Mode to interact with the floppy disk. We need to use BIOS Interrupts to achieve our task.

Which interrupts are we going to use?
- Interrupt 0x13
- Service code 0x02

How to access a floppy disk using the interrupt 0x13?
- AH = 0x02: To request BIOS to read a sector on a floppy we use below.
- CH = ‘N’: To request BIOS to read from the ‘N’th cylinder we use below.
- DH = ‘N’: To request BIOS to read from the ‘N’th head we use below.
- CL = ‘N’: To request BIOS to read ‘N’th sector we use below.
- AL = N: To request BIOS to read ‘N’ number of sectors we use below.
- Int 0x13: To interrupt the CPU to perform this activity we use below.

## Reading data from Floppy Disk

Example: test.S

Let us write a program to display the labels of few sectors.

```asm
.code16                       #generate 16-bit code
.text                         #executable code location
.globl _start;                #code entry point
_start:
     jmp _boot                #jump to the boot code to start execution
     msgFail: .asciz "something has gone wrong..." #message about erroneous operation
      #macro to print null terminated string
      #this macro calls function PrintString
     .macro mPrintString str
          leaw \str, %si
          call PrintString
     .endm
     #function to print null terminated string
     PrintString:
          lodsb
          orb  %al  , %al
          jz   PrintStringOut
          movb $0x0e, %ah
          int  $0x10
          jmp  PrintString
     PrintStringOut:
     ret
     #macro to read a sector from a floppy disk
     #and load it at extended segment
     .macro mReadSectorFromFloppy num
          movb $0x02, %ah     #read disk function
          movb $0x01, %al     #total sectors to read
          movb $0x00, %ch     #select cylinder zero
          movb $0x00, %dh     #select head zero
          movb \num, %cl      #start reading from this sector
          movb $0x00, %dl     #drive number
          int  $0x13          #interrupt cpu to get this job done now
          jc   _failure       #if fails then throw error
          cmpb $0x01, %al     #if total sectors read != 1
          jne  _failure       #then throw error
     .endm
     #display the string that we have inserted as the
     #identifier of the sector
     DisplayData:
     DisplayDataIn:
          movb %es:(%bx), %al
          orb  %al      , %al
          jz   DisplayDataOut
          movb $0x0e    , %ah
          int  $0x10
          incw %bx
          jmp  DisplayDataIn
     DisplayDataOut:
     ret
_boot:
     movw  $0x07c0, %ax       #initialize the data segment
     movw  %ax    , %ds       #to 0x7c00 location
     movw  $0x9000, %ax       #set ax = 0x9000
     movw  %ax    , %es       #set es = 0x9000 = ax
     xorw  %bx    , %bx       #set bx = 0
     mReadSectorFromFloppy $2 #read a sector from floppy disk
     call DisplayData         #display the label of the sector
     mReadSectorFromFloppy $3 #read 3rd sector from floppy disk
     call DisplayData         #display the label of the sector
_freeze:                      #infinite loop
     jmp _freeze              #
_failure:                     #
     mPrintString msgFail     #write error message and then
     jmp _freeze              #jump to the freezing point
     . = _start + 510         #mov to 510th byte from 0 pos
     .byte 0x55               #append first part of the boot signature
     .byte 0xAA               #append last part of the boot signature
_sector2:                     #second sector of the floppy disk
     .asciz "Sector: 2\n\r"   #write data to the begining of the sector
     . = _sector2 + 512       #move to the end of the second sector
_sector3:                     #third sector of the floppy disk
     .asciz "Sector: 3\n\r"   #write data to the begining of the sector
     . = _sector3 + 512       #move to the end of the third sector
```

```bash
as test.S -o test.o
ld -Ttext=0x0000 --oformat=binary test.o -o test.bin
dd if=test.bin of=floppy.img
```

If you open the test.bin in an hexadecimal editor you will find that I have embedded a label to sector 2 and 3.

What is the purpose of setting the extended segment?

First we read a sector into our program memory at 0x9000 and then start displaying the content of the sector. That is why we set the Extended segment to 0x9000.


## Writing a 16-bit dummy kernel in C/C++

[*Writing a 16-bit dummy kernel in C/C++*](https://www.codeproject.com/Articles/737545/Writing-a-bit-dummy-kernel-in-C-Cplusplus)

[source code](https://www.codeproject.com/KB/cpp/737545/sourcecode.rar)

Part 1:
- Write a program called kernel.c in C Language, making sure that all the extra functionality that I desired to is properly written in it.
Compile and save the executable as kernel.bin
- Now, copy the kernel.bin file to the bootable drive into second sector.

Part 2:
- In our boot-loader, all we can do is to load the second sector(kernel.bin) of the bootable drive into the RAM memory at address say 0x1000 and then jump to the location 0x1000 from 0x7c00 to start executing the kernel.bin file.


## Writing a FAT boot-loader

File Name: stage0.S

Below is the code snippet used to execute a kernel.bin file on a FAT formatted disk.

```asm
/*********************************************************************************
 *                                                                               *
 *                                                                               *
 *    Name       : stage0.S                                                      *
 *    Date       : 23-Feb-2014                                                   *
 *    Version    : 0.0.1                                                         *
 *    Source     : assembly language                                             *
 *    Author     : Ashakiran Bhatter                                             *
 *                                                                               *
 *    Description: The main logic involves scanning for kernel.bin file on a     *
 *                 fat12 formatted floppy disk and then pass the control to it   *
 *                 for its execution                                             *
 *    Usage      : Please read the readme.txt for more information               *
 *                                                                               *
 *                                                                               *
 *********************************************************************************/
.code16
.text
.globl _start;
_start:
     jmp _boot
     nop
     /*bios parameter block                           description of each entity       */
     /*--------------------                           --------------------------       */
     .byte 0x6b,0x69,0x72,0x55,0x58,0x30,0x2e,0x31    /* oem label                     */
     .byte 0x00,0x02                                  /* total bytes per sector        */
     .byte 0x01                                       /* total sectors per cluster     */
     .byte 0x01,0x00                                  /* total reserved sectors        */
     .byte 0x02                                       /* total fat tables              */
     .byte 0xe0,0x00                                  /* total directory entries       */
     .byte 0x40,0x0b                                  /* total sectors                 */
     .byte 0xf0                                       /* media description             */
     .byte 0x09,0x00                                  /* size in of each fat table     */
     .byte 0x02,0x01                                  /* total sectors per track       */
     .byte 0x02,0x00                                  /* total heads per cylinder      */
     .byte 0x00,0x00, 0x00, 0x00                      /* total hidden sectors          */
     .byte 0x00,0x00, 0x00, 0x00                      /* total big sectors             */
     .byte 0x00                                       /* boot drive identifier         */
     .byte 0x00                                       /* total unused sectors          */
     .byte 0x29                                       /* external boot signature       */
     .byte 0x22,0x62,0x79,0x20                        /* serial number                 */
     .byte 0x41,0x53,0x48,0x41,0x4b,0x49              /* volume label 6 bytes of 11    */
     .byte 0x52,0x41,0x4e,0x20,0x42                   /* volume label 5 bytes of 11    */
     .byte 0x48,0x41,0x54,0x54,0x45,0x52,0x22         /* file system type              */

     /* include macro functions */
     #include "macros.S"

/* begining of main code */
_boot:
     /* initialize the environment */
     initEnvironment 

     /* load stage2 */
     loadFile $fileStage2


/* infinite loop */
_freeze:
     jmp _freeze

/* abnormal termination of program */
_abort:
     writeString $msgAbort
     jmp _freeze

     /* include functions */
     #include "routines.S"

     /* user-defined variables */
     bootDrive : .byte 0x0000
     msgAbort  : .asciz "* * * F A T A L  E R R O R * * *"
     #fileStage2: .ascii "STAGE2  BIN"
     fileStage2: .ascii  "KERNEL  BIN"
     clusterID : .word 0x0000

     /* traverse 510 bytes from beginning */
     . = _start + 0x01fe

     /* append boot signature             */
     .word BOOT_SIGNATURE
```

This is the main loader file does the following.
- Initialize all the registers and set up the stack by calling initEnvironment macro.
- loadFile macro is called to load the kernel.bin file into the memory at address 0x1000:0000 and then pass control to it for further execution.

File Name: macros.S

This is a file which contains all the predefined macros and macro functions.

```asm
/*********************************************************************************          *                                                                               *
 *                                                                               *
 *    Name       : macros.S                                                      *
 *    Date       : 23-Feb-2014                                                   *
 *    Version    : 0.0.1                                                         *
 *    Source     : assembly language                                             *
 *    Author     : Ashakiran Bhatter                                             *
 *                                                                               *
 *                                                                               *
 *********************************************************************************/
/* predefined macros: boot loader                         */
#define BOOT_LOADER_CODE_AREA_ADDRESS                 0x7c00
#define BOOT_LOADER_CODE_AREA_ADDRESS_OFFSET          0x0000

/* predefined macros: stack segment                       */
#define BOOT_LOADER_STACK_SEGMENT                     0x7c00

#define BOOT_LOADER_ROOT_OFFSET                       0x0200
#define BOOT_LOADER_FAT_OFFSET                        0x0200

#define BOOT_LOADER_STAGE2_ADDRESS                    0x1000
#define BOOT_LOADER_STAGE2_OFFSET                     0x0000 

/* predefined macros: floppy disk layout                  */
#define BOOT_DISK_SECTORS_PER_TRACK                   0x0012
#define BOOT_DISK_HEADS_PER_CYLINDER                  0x0002
#define BOOT_DISK_BYTES_PER_SECTOR                    0x0200
#define BOOT_DISK_SECTORS_PER_CLUSTER                 0x0001

/* predefined macros: file system layout                  */
#define FAT12_FAT_POSITION                            0x0001
#define FAT12_FAT_SIZE                                0x0009
#define FAT12_ROOT_POSITION                           0x0013
#define FAT12_ROOT_SIZE                               0x000e
#define FAT12_ROOT_ENTRIES                            0x00e0
#define FAT12_END_OF_FILE                             0x0ff8

/* predefined macros: boot loader                         */
#define BOOT_SIGNATURE                                0xaa55

/* user-defined macro functions */
/* this macro is used to set the environment */
.macro initEnvironment
     call _initEnvironment
.endm
/* this macro is used to display a string    */
/* onto the screen                           */
/* it calls the function _writeString to     */
/* perform the operation                     */
/* parameter(s): input string                */
.macro writeString message
     pushw \message
     call  _writeString
.endm
/* this macro is used to read a sector into  */
/* the target memory                         */
/* It calls the _readSector function with    */
/* the following parameters                  */
/* parameter(s): sector Number               */
/*            address to load                */
/*            offset of the address          */
/*            Number of sectors to read      */
.macro readSector sectorno, address, offset, totalsectors
     pushw \sectorno
     pushw \address
     pushw \offset
     pushw \totalsectors
     call  _readSector
     addw  $0x0008, %sp
.endm
/* this macro is used to find a file in the  */
/* FAT formatted drive                       */
/* it calls readSector macro to perform this */
/* activity                                  */
/* parameter(s): root directory position     */
/*               target address              */
/*               target offset               */
/*               root directory size         */
.macro findFile file
     /* read fat table into memory */
     readSector $FAT12_ROOT_POSITION, $BOOT_LOADER_CODE_AREA_ADDRESS, $BOOT_LOADER_ROOT_OFFSET, $FAT12_ROOT_SIZE
     pushw \file
     call  _findFile
     addw  $0x0002, %sp
.endm
/* this macro is used to convert the given   */
/* cluster into a sector number              */
/* it calls _clusterToLinearBlockAddress to  */
/* perform this activity                     */
/* parameter(s): cluster number              */
.macro clusterToLinearBlockAddress cluster
     pushw \cluster
     call  _clusterToLinearBlockAddress
     addw  $0x0002, %sp
.endm
/* this macro is used to load a target file  */
/* into the memory                           */
/* It calls findFile and then loads the data */
/* of the respective file into the memory at */
/* address 0x1000:0x0000                     */
/* parameter(s): target file name            */
.macro loadFile file
     /* check for file existence */
     findFile \file

     pushw %ax
     /* read fat table into memory */
     readSector $FAT12_FAT_POSITION, $BOOT_LOADER_CODE_AREA_ADDRESS, $BOOT_LOADER_FAT_OFFSET, $FAT12_FAT_SIZE

     popw  %ax
     movw  $BOOT_LOADER_STAGE2_OFFSET, %bx
_loadCluster:
     pushw %bx
     pushw %ax
 
     clusterToLinearBlockAddress %ax
     readSector %ax, $BOOT_LOADER_STAGE2_ADDRESS, %bx, $BOOT_DISK_SECTORS_PER_CLUSTER

     popw  %ax
     xorw %dx, %dx
     movw $0x0003, %bx
     mulw %bx
     movw $0x0002, %bx
     divw %bx

     movw $BOOT_LOADER_FAT_OFFSET, %bx
     addw %ax, %bx
     movw $BOOT_LOADER_CODE_AREA_ADDRESS, %ax
     movw %ax, %es
     movw %es:(%bx), %ax
     orw  %dx, %dx
     jz   _even_cluster
_odd_cluster:
     shrw $0x0004, %ax
     jmp  _done 
_even_cluster:
     and $0x0fff, %ax
_done:
     popw %bx
     addw $BOOT_DISK_BYTES_PER_SECTOR, %bx
     cmpw $FAT12_END_OF_FILE, %ax
     jl  _loadCluster

     /* execute kernel */
     initKernel     
.endm
/* parameter(s): target file name            */
/* this macro is used to pass the control of */
/* execution to the loaded file in memory at */
/* address 0x1000:0x0000                     */
/* parameters(s): none                       */
.macro initKernel
     /* initialize the kernel */
     movw  $(BOOT_LOADER_STAGE2_ADDRESS), %ax
     movw  $(BOOT_LOADER_STAGE2_OFFSET) , %bx
     movw  %ax, %es
     movw  %ax, %ds
     jmp   $(BOOT_LOADER_STAGE2_ADDRESS), $(BOOT_LOADER_STAGE2_OFFSET)
.endm 
```

File Name: routines.S

```asm
/*********************************************************************************
 *                                                                               *
 *                                                                               *
 *    Name       : routines.S                                                    *
 *    Date       : 23-Feb-2014                                                   *
 *    Version    : 0.0.1                                                         *
 *    Source     : assembly language                                             *
 *    Author     : Ashakiran Bhatter                                             *
 *                                                                               *
 *                                                                               *
 *********************************************************************************/
/* user-defined routines */
/* this function is used to set-up the */
/* registers and stack as required     */
/* parameter(s): none                  */
_initEnvironment:
     pushw %bp
     movw  %sp, %bp
_initEnvironmentIn:
     cli
     movw  %cs, %ax
     movw  %ax, %ds
     movw  %ax, %es
     movw  %ax, %ss
     movw  $BOOT_LOADER_STACK_SEGMENT, %sp
     sti
_initEnvironmentOut:
     movw  %bp, %sp
     popw  %bp
ret

/* this function is used to display a string */
/* onto the screen                           */
/* parameter(s): input string                */
_writeString:
     pushw %bp
     movw  %sp   , %bp
     movw 4(%bp) , %si
     jmp  _writeStringCheckByte
_writeStringIn:
     movb $0x000e, %ah
     movb $0x0000, %bh
     int  $0x0010
     incw %si
_writeStringCheckByte:
     movb (%si)  , %al
     orb  %al    , %al
     jnz  _writeStringIn
_writeStringOut:
     movw %bp    , %sp
     popw %bp
ret

/* this function is used to read a sector    */
/* into the target memory                    */
/* parameter(s): sector Number               */
/*            address to load                */
/*            offset of the address          */
/*            Number of sectors to read      */
_readSector:
     pushw %bp
     movw %sp    , %bp

     movw 10(%bp), %ax
     movw $BOOT_DISK_SECTORS_PER_TRACK, %bx
     xorw %dx    , %dx
     divw %bx

     incw %dx
     movb %dl    , %cl

     movw $BOOT_DISK_HEADS_PER_CYLINDER, %bx
     xorw %dx    , %dx
     divw %bx

     movb %al    , %ch
     xchg %dl    , %dh

     movb $0x02  , %ah
     movb 4(%bp) , %al
     movb bootDrive, %dl
     movw 8(%bp) , %bx
     movw %bx    , %es
     movw 6(%bp) , %bx
     int  $0x13
     jc   _abort
     cmpb 4(%bp) , %al
     jc   _abort

     movw %bp    , %sp
     popw %bp
ret

/* this function is used to find a file in   */
/* the FAT formatted drive                   */
/* parameter(s): root directory position     */
/*               target address              */
/*               target offset               */
/*               root directory size         */
_findFile:
     pushw %bp
     movw  %sp   , %bp

     movw  $BOOT_LOADER_CODE_AREA_ADDRESS, %ax
     movw  %ax   , %es
     movw  $BOOT_LOADER_ROOT_OFFSET, %bx
     movw  $FAT12_ROOT_ENTRIES, %dx
     jmp   _findFileInitValues

_findFileIn:
     movw  $0x000b  , %cx
     movw  4(%bp)   , %si
     leaw  (%bx)    , %di
     repe  cmpsb
     je    _findFileOut
_findFileDecrementCount:
     decw  %dx
     addw  $0x0020, %bx
_findFileInitValues:
     cmpw  $0x0000, %dx
     jne   _findFileIn
     je    _abort
_findFileOut:
     addw  $0x001a  , %bx
     movw  %es:(%bx), %ax
     movw  %bp, %sp
     popw  %bp
ret

/* this function is used to convert the given*/
/* cluster into a sector number              */
/* parameter(s): cluster number              */
_clusterToLinearBlockAddress:
     pushw %bp
     movw  %sp    , %bp
     movw  4(%bp) , %ax
_clusterToLinearBlockAddressIn:
     subw  $0x0002, %ax
     movw  $BOOT_DISK_SECTORS_PER_CLUSTER, %cx
     mulw  %cx
     addw  $FAT12_ROOT_POSITION, %ax
     addw  $FAT12_ROOT_SIZE, %ax
_clusterToLinearBlockAddressOut:
     movw  %bp    , %sp
     popw  %bp
ret
```

File Name: stage0.ld

This file is used to link the stage0.object file during the link time.

```
/*********************************************************************************
 *                                                                               *
 *                                                                               *
 *    Name       : stage0.ld                                                     *
 *    Date       : 23-Feb-2014                                                   *
 *    Version    : 0.0.1                                                         *
 *    Source     : assembly language                                             *
 *    Author     : Ashakiran Bhatter                                             *
 *                                                                               *
 *                                                                               *
 *********************************************************************************/
SECTIONS
{
     . = 0x7c00;
     .text :
     {
          _ftext = .;
     } = 0
}
```

## Mini-Project - Writing a 16-bit Kernel

The below file is the source code of the dummy kernel that is being introduced as part of the testing process. All we have to do is to compile the source utilizing the make file and see if it gets loaded by the bootloader or not.

A splash screen with a dragon image is displayed in text and then a welcome screen followed by a command prompt is displayed for the user to type in anything.

There are no commands or utilities written in there to execute but just for our testing purpose this kernel is introduced which is worth nothing as of now.

File Name: kernel.c

```c
/*********************************************************************************
 *                                                                               *
 *                                                                               *
 *    Name       : kernel.c                                                      *
 *    Date       : 23-Feb-2014                                                   *
 *    Version    : 0.0.1                                                         *
 *    Source     : C                                                             *
 *    Author     : Ashakiran Bhatter                                             *
 *                                                                               *
 *    Description: This is the file that the stage0.bin loads and passes the     *
 *                 control of execution to it. The main functionality of this    *
 *                 program is to display a very simple splash screen and a       *
 *                 command prompt so that the user can type commands             *
 *    Caution    : It does not recognize any commands as they are not programmed *
 *                                                                               *
 *********************************************************************************/
/* generate 16 bit code                                                 */
__asm__(".code16\n");
/* jump to main function or program code                                */
__asm__("jmpl $0x1000, $main\n");

#define TRUE  0x01
#define FALSE 0x00

char str[] = "$> ";

/* this function is used to set-up the */
/* registers and stack as required     */
/* parameter(s): none                  */
void initEnvironment() {
     __asm__ __volatile__(
          "cli;"
          "movw $0x0000, %ax;"
          "movw %ax, %ss;"
          "movw $0xffff, %sp;"
          "cld;"
     );

     __asm__ __volatile__(
          "movw $0x1000, %ax;"
          "movw %ax, %ds;"
          "movw %ax, %es;"
          "movw %ax, %fs;"
          "movw %ax, %gs;"
     );
}

/* vga functions */
/* this function is used to set the   */
/* the VGA mode to 80*24              */
void setResolution() {
     __asm__ __volatile__(
          "int $0x10" : : "a"(0x0003)
     );
}

/* this function is used to clear the */
/* screen buffer by splitting spaces  */
void clearScreen() {
     __asm__ __volatile__ (
          "int $0x10" : : "a"(0x0200), "b"(0x0000), "d"(0x0000)
     );
     __asm__ __volatile__ (
          "int $0x10" : : "a"(0x0920), "b"(0x0007), "c"(0x2000)
     );
}

/* this function is used to set the   */
/* cursor position at a given column  */
/* and row                            */
void setCursor(short col, short row) {
     __asm__ __volatile__ (
          "int $0x10" : : "a"(0x0200), "d"((row <<= 8) | col)
     );
}

/* this function is used enable and   */
/* disable the cursor                 */
void showCursor(short choice) {
     if(choice == FALSE) {
          __asm__ __volatile__(
               "int $0x10" : : "a"(0x0100), "c"(0x3200)
          );
     } else {
          __asm__ __volatile__(
               "int $0x10" : : "a"(0x0100), "c"(0x0007)
          );
     }
}

/* this function is used to initialize*/
/* the VGA to 80 * 25 mode and then   */
/* clear the screen and set the cursor*/
/* position to (0,0)                  */
void initVGA() {
     setResolution();
     clearScreen();
     setCursor(0, 0);
}

/* io functions */
/* this function is used to get a chara*/
/* cter from keyboard with no echo     */
void getch() {
     __asm__ __volatile__ (
          "xorw %ax, %ax\n"
          "int $0x16\n"
     );
}

/* this function is same as getch()    */
/* but it returns the scan code and    */
/* ascii value of the key hit on the   */
/* keyboard                            */
short getchar() {
     short word;

     __asm__ __volatile__(
          "int $0x16" : : "a"(0x1000)
     );

     __asm__ __volatile__(
          "movw %%ax, %0" : "=r"(word)
     );

     return word;
}

/* this function is used to display the*/
/* key on the screen                   */
void putchar(short ch) {
     __asm__ __volatile__(
          "int $0x10" : : "a"(0x0e00 | (char)ch)
     );
}

/* this function is used to print the  */
/* null terminated string on the screen*/
void printString(const char* pStr) {
     while(*pStr) {
          __asm__ __volatile__ (
               "int $0x10" : : "a"(0x0e00 | *pStr), "b"(0x0002)
          );
          ++pStr;
     }
}

/* this function is used to sleep for  */
/* a given number of seconds           */
void delay(int seconds) {
     __asm__ __volatile__(
          "int $0x15" : : "a"(0x8600), "c"(0x000f * seconds), "d"(0x4240 * seconds)
     );
}

/* string functions */
/* this function isused to calculate   */
/* length of the string and then return*/
/* it                                  */
int strlength(const char* pStr) {
     int i = 0;

     while(*pStr) {
          ++i;
     }
     return i;
}

/* UI functions */
/* this function is used to display the */
/* logo                                 */
void splashScreen(const char* pStr) {
     showCursor(FALSE);
     clearScreen();
     setCursor(0, 9);
     printString(pStr);
     delay(10);
}

/* shell */
/* this function is used to display a   */
/* dummy command prompt onto the screen */
/* and it automatically scrolls down if */
/* the user hits return key             */
void shell() {
     clearScreen();
     showCursor(TRUE);
     while(TRUE) {
          printString(str);
          short byte;
          while((byte = getchar())) {
               if((byte >> 8)  == 0x1c) {
                    putchar(10);
                    putchar(13);
                    break;
               } else {
                    putchar(byte);
               }
          }
     }
}

/* this is the main entry for the kernel*/
void main() {
     const char msgPicture[] = 
             "                     ..                                              \n\r"
             "                      ++`                                            \n\r"
             "                       :ho.        `.-/++/.                          \n\r"
             "                        `/hh+.         ``:sds:                       \n\r"
             "                          `-odds/-`        .MNd/`                    \n\r"
             "                             `.+ydmdyo/:--/yMMMMd/                   \n\r"
             "                                `:+hMMMNNNMMMddNMMh:`                \n\r"
             "                   `-:/+++/:-:ohmNMMMMMMMMMMMm+-+mMNd`               \n\r"
             "                `-+oo+osdMMMNMMMMMMMMMMMMMMMMMMNmNMMM/`              \n\r"
             "                ```   .+mMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmho:.`         \n\r"
             "                    `omMMMMMMMMMMMMMMMMMMNMdydMMdNMMMMMMMMdo+-       \n\r"
             "                .:oymMMMMMMMMMMMMMNdo/hMMd+ds-:h/-yMdydMNdNdNN+      \n\r"
             "              -oosdMMMMMMMMMMMMMMd:`  `yMM+.+h+.-  /y `/m.:mmmN      \n\r"
             "             -:`  dMMMMMMMMMMMMMd.     `mMNo..+y/`  .   .  -/.s      \n\r"
             "             `   -MMMMMMMMMMMMMM-       -mMMmo-./s/.`         `      \n\r"
             "                `+MMMMMMMMMMMMMM-        .smMy:.``-+oo+//:-.`        \n\r"
             "               .yNMMMMMMMMMMMMMMd.         .+dmh+:.  `-::/+:.        \n\r"
             "               y+-mMMMMMMMMMMMMMMm/`          ./o+-`       .         \n\r"
             "              :-  :MMMMMMMMMMMMMMMMmy/.`                             \n\r"
             "              `   `hMMMMMMMMMMMMMMMMMMNds/.`                         \n\r"
             "                  sNhNMMMMMMMMMMMMMMMMMMMMNh+.                       \n\r"
             "                 -d. :mMMMMMMMMMMMMMMMMMMMMMMNh:`                    \n\r"
             "                 /.   .hMMMMMMMMMMMMMMMMMMMMMMMMh.                   \n\r"
             "                 .     `sMMMMMMMMMMMMMMMMMMMMMMMMN.                  \n\r"
             "                         hMMMMMMMMMMMMMMMMMMMMMMMMy                  \n\r"
             "                         +MMMMMMMMMMMMMMMMMMMMMMMMh                      ";
     const char msgWelcome[] = 
             "              *******************************************************\n\r"
             "              *                                                     *\n\r"
             "              *        Welcome to kirUX Operating System            *\n\r"
             "              *                                                     *\n\r"
             "              *******************************************************\n\r"
             "              *                                                     *\n\r" 
             "              *                                                     *\n\r"
             "              *        Author : Ashakiran Bhatter                   *\n\r"
             "              *        Version: 0.0.1                               *\n\r"
             "              *        Date   : 01-Mar-2014                         *\n\r"
             "              *                                                     *\n\r"
             "              ******************************************************";
     initEnvironment(); 
     initVGA();
     splashScreen(msgPicture);
     splashScreen(msgWelcome);

     shell(); 

     while(1);
}
```
