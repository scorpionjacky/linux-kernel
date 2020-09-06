<asm | __asm__> [volotile | __volotile__] ("statements" [: [output] [: input [: clobbered]]]);

GNU C compiler i.e. GCC uses AT&T syntax

1. Register Naming: prefixed with %, for example %eax, %cl etc.
2. Ordering of operands: source(s) first, and destination last. For example, "mov %edx, %eax".
3. Operand Size: determined from the last character of the op-code name. b for (8-bit) byte, w for (16-bit) word, and l for (32-bit) long. For example, "movl %edx, %eax".
4. Immediate Operand: marked with a $ prefix, as in "addl $5, %eax", which means add immediate long value 5 to register %eax.
5. Memory Operands: "movl $bar, %ebx" puts the address of variable bar into register %ebx, while "movl bar, %ebx" puts the contents of variable bar into register %ebx.
6. Indexing: Indexing or indirection is done by enclosing the index register or indirection memory cell address in parentheses. For example, "movl 8(%ebp), %eax" (moves the contents at offset 8 from the cell pointed to by %ebp into register %eax).

*Note: In Intel's format `bar` gives pointer to the variable while `[bar]` gives its value.*

Examples

```c
/* moves the contents of ebx register to eax */
asm("movl %ebx, %eax");

/* moves the byte from ch to the memory pointed by ebx */
__asm__("movb %ch, (%ebx)"); 
```

```c
#include <stdio.h>

int main() {
    /* Add 10 and 20 and store result into register %eax */
    __asm__ ("movl $10, %eax;"
             "movl $20, %ebx;"
             "addl %ebx, %eax;"
    );

    /* Subtract 20 from 10 and store result into register %eax */
    __asm__ ("movl $10, %eax;"
             "movl $20, %ebx;"
             "subl %ebx, %eax;"
    );

    /* Multiply 10 and 20 and store result into register %eax */
    __asm__ ("movl $10, %eax;"
             "movl $20, %ebx;"
             "imull %ebx, %eax;"
    );

    return 0 ;
}
```

Compile it using "-g" option of GNU C compiler "gcc" to keep debugging information with the executable and then using GNU Debugger "gdb" to inspect the contents of CPU registers.


**Extended Assembly**

In extended assembly, we can also specify the operands. It allows us to specify the input registers, output registers and a list of clobbered registers.

```c
asm ("assembly code"
        : output operands                /* optional */
        : input operands                 /* optional */
        : list of clobbered registers    /* optional */
);
```

```c
asm ("movl %%eax, %0;" : "=r" ( val ));
```

In this example, the variable "val" is kept in a register, the value in register eax is copied onto that register, and the value of "val" is updated into the memory from this register.

When the "r" constraint is specified, gcc may keep the variable in any of the available General Purpose Registers. We can also specify the register names directly by using specific register constraints.

The register constraints are as follows :

```
+---+--------------------+
| r |    Register(s)     |
+---+--------------------+
| a |   %eax, %ax, %al   |
| b |   %ebx, %bx, %bl   |
| c |   %ecx, %cx, %cl   |
| d |   %edx, %dx, %dl   |
| S |   %esi, %si        |
| D |   %edi, %di        |
+---+--------------------+
```

```c
int no = 100, val ;
asm ("movl %1, %%ebx;"
     "movl %%ebx, %0;"
     : "=r" ( val )   /* output */
     : "r" ( no )     /* input */
     : "%ebx"         /* clobbered register */
 );
```

In the above example, "val" is the output operand, referred to by %0 and "no" is the input operand, referred to by %1. "r" is a constraint on the operands, which says to GCC to use any register for storing the operands.

Output operand constraint should have a constraint modifier "=" to specify the output operand in write-only mode. There are two %’s prefixed to the register name, which helps GCC to distinguish between the operands and registers. operands have a single % as prefix.

The clobbered register %ebx after the third colon informs the GCC that the value of %ebx is to be modified inside "asm", so GCC won't use this register to store any other value.

```c
int arg1, arg2, add ;
__asm__ ( "addl %%ebx, %%eax;"
        : "=a" (add)
        : "a" (arg1), "b" (arg2) );
```

Here "add" is the output operand referred to by register eax. And arg1 and arg2 are input operands referred to by registers eax and ebx respectively.

A complete example:

```c
#include <stdio.h>

int main() {

    int arg1, arg2, add, sub, mul, quo, rem ;

    printf( "Enter two integer numbers : " );
    scanf( "%d%d", &arg1, &arg2 );

    /* Perform Addition, Subtraction, Multiplication & Division */
    __asm__ ( "addl %%ebx, %%eax;" : "=a" (add) : "a" (arg1) , "b" (arg2) );
    __asm__ ( "subl %%ebx, %%eax;" : "=a" (sub) : "a" (arg1) , "b" (arg2) );
    __asm__ ( "imull %%ebx, %%eax;" : "=a" (mul) : "a" (arg1) , "b" (arg2) );

    __asm__ ( "movl $0x0, %%edx;"
              "movl %2, %%eax;"
              "movl %3, %%ebx;"
               "idivl %%ebx;" : "=a" (quo), "=d" (rem) : "g" (arg1), "g" (arg2) );

    printf( "%d + %d = %d\n", arg1, arg2, add );
    printf( "%d - %d = %d\n", arg1, arg2, sub );
    printf( "%d * %d = %d\n", arg1, arg2, mul );
    printf( "%d / %d = %d\n", arg1, arg2, quo );
    printf( "%d %% %d = %d\n", arg1, arg2, rem );

    return 0 ;
}
```

**Volatile**

`volatile` dictates that assembly statements must execute where we put it, (i.e. must not be moved out of a loop as an optimization).

Examples with the Greatest Common Divisor using well known Euclid's Algorithm ( honoured as first algorithm).

```c
#include <stdio.h>

int gcd( int a, int b ) {
    int result ;
    /* Compute Greatest Common Divisor using Euclid's Algorithm */
    __asm__ __volatile__ ( 
        "movl %1, %%eax;"
        "movl %2, %%ebx;"
        "CONTD: cmpl $0, %%ebx;"
        "je DONE;"
        "xorl %%edx, %%edx;"
        "idivl %%ebx;"
        "movl %%ebx, %%eax;"
        "movl %%edx, %%ebx;"
        "jmp CONTD;"
        "DONE: movl %%eax, %0;" : "=g" (result) : "g" (a), "g" (b)
    );

    return result ;
}

int main() {
    int first, second ;
    printf( "Enter two integers : " ) ;
    scanf( "%d%d", &first, &second );

    printf( "GCD of %d & %d is %d\n", first, second, gcd(first, second) ) ;

    return 0 ;
}
```

Examples which use FPU (Floating Point Unit) Instruction Set.

 simple floating point arithmetic:
 
 ```c
 #include <stdio.h>

int main() {

    float arg1, arg2, add, sub, mul, div ;

    printf( "Enter two numbers : " );
    scanf( "%f%f", &arg1, &arg2 );

    /* Perform floating point Addition, Subtraction, Multiplication & Division */
    __asm__ ( "fld %1;"
              "fld %2;"
              "fadd;"
              "fstp %0;" : "=g" (add) : "g" (arg1), "g" (arg2) ) ;

    __asm__ ( "fld %2;"
              "fld %1;"
              "fsub;"
              "fstp %0;" : "=g" (sub) : "g" (arg1), "g" (arg2) ) ;

    __asm__ ( "fld %1;"
              "fld %2;"
              "fmul;"
              "fstp %0;" : "=g" (mul) : "g" (arg1), "g" (arg2) ) ;

    __asm__ ( "fld %2;"
              "fld %1;"
              "fdiv;"
              "fstp %0;" : "=g" (div) : "g" (arg1), "g" (arg2) ) ;

    printf( "%f + %f = %f\n", arg1, arg2, add );
    printf( "%f - %f = %f\n", arg1, arg2, sub );
    printf( "%f * %f = %f\n", arg1, arg2, mul );
    printf( "%f / %f = %f\n", arg1, arg2, div );

    return 0 ;
}
 ```
 
trigonometrical functions like sin and cos:

```c
#include <stdio.h>

float sinx( float degree ) {
    float result, two_right_angles = 180.0f ;
    /* Convert angle from degrees to radians and then calculate sin value */
    __asm__ __volatile__ ( "fld %1;"
                            "fld %2;"
                            "fldpi;"
                            "fmul;"
                            "fdiv;"
                            "fsin;"
                            "fstp %0;" : "=g" (result) : 
				"g"(two_right_angles), "g" (degree)
    ) ;
    return result ;
}

float cosx( float degree ) {
    float result, two_right_angles = 180.0f, radians ;
    /* Convert angle from degrees to radians and then calculate cos value */
    __asm__ __volatile__ ( "fld %1;"
                            "fld %2;"
                            "fldpi;"
                            "fmul;"
                            "fdiv;"
                            "fstp %0;" : "=g" (radians) : 
				"g"(two_right_angles), "g" (degree)
    ) ;
    __asm__ __volatile__ ( "fld %1;"
                            "fcos;"
                            "fstp %0;" : "=g" (result) : "g" (radians)
    ) ;
    return result ;
}

float square_root( float val ) {
    float result ;
    __asm__ __volatile__ ( "fld %1;"
                            "fsqrt;"
                            "fstp %0;" : "=g" (result) : "g" (val)
    ) ;
    return result ;
}

int main() {
    float theta ;
    printf( "Enter theta in degrees : " ) ;
    scanf( "%f", &theta ) ;

    printf( "sinx(%f) = %f\n", theta, sinx( theta ) );
    printf( "cosx(%f) = %f\n", theta, cosx( theta ) );
    printf( "square_root(%f) = %f\n", theta, square_root( theta ) ) ;

    return 0 ;
}
```

**Accessing Local Variables**

Local variables as well as function parameters are allocated on the stack. In inline asm you can access those local variables either using frame pointer register(ebp) or directly the stack pointer.

Local variables are on the negative side of the stack pointer while function parameters are on the positive side of the stack pointer. Space for local variables is reserved on the stack in the order that they are declared.

Parameters are pushed onto the stack from right to left and are referenced relative to the base pointer (ebp) at four byte intervals beginning with a displacement of 8.

Example of a C function:

```c
void doNothing(int a, int b)
{
    int y = 5;
    int z = 9; 
    y += b;
    z += a;
    return;
}
```

Following asm code is generated by the compiler (without optimizations)

```asm
_doNothing:
 pushl %ebp
 movl %esp, %ebp
 subl $8, %esp
 movl $5, -4(%ebp)
 movl $9, -8(%ebp)
 movl 12(%ebp), %edx
 leal -4(%ebp), %eax
 addl %edx, (%eax)
 movl 8(%ebp), %edx
 leal -8(%ebp), %eax
 addl %edx, (%eax)
 leave
 ret
```

The stack looks something like this

```
z	-8
	-7
	-6
	-5
y	-4
	-3
	-2
	-1
	ebp
	1
	2
	3
	4
	5
	6
	7
a	8
	9
	10
	11
b	12
	13
	14
	15
```

Following asm code is generated if we tell compiler not to use ebp (-fomit-frame-pointer)

```asm
_doNothing:
 subl $8, %esp
 movl $5, 4(%esp)
 movl $9, (%esp)
 movl 16(%esp), %edx
 leal 4(%esp), %eax
 addl %edx, (%eax)
 movl 12(%esp), %edx
 movl %esp, %eax
 addl %edx, (%eax)
 addl $8, %esp
 ret
```

In this case stack looks something like this

```
z	esp
	1
	2
	3
y	4
	5
	6
	7
	8
	9
	10
	11
a	12
	13
	14
	15
b	16
	17
	18
	19
```

**Referencing memory**

The format for 32-bit addressing in Intel syntax is segreg: [base + index * scale + immed32] while the same in AT&T syntax is segreg: immed32 (base, index, scale). The formula to calculate the address is (immed32 + base + index * scale) in the segment pointed by segment register. You can use 386-protected mode to just use eax, ebx, ecx, edx, edi, esi as six general purpose registers (ignoring the segment register). ebp can also be used as a general purpose register if -fomit-frame-pointer option is used while compiling.

| | AT&T | Intel |
| -- | -- | -- |
|Addressing a global variable | \_x | [\_x] |
|De-Referencing a pointer in a register | (%eax) | [eax]
|Array of integers | \_array (,%eax, 4) | [eax\*4 + array]
|Addressing a variable offset by a value in a register | \_x(%eax) | [eax + \_x]
|Addressing a variable offset by an immediate value assuming that variable is stored in eax |1(%eax) | [eax + 1]

