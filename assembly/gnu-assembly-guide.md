# GNU Assembler and AT&T Syntax

[Registers](#x86-registers) | [Basics](#basics) | [Memory and Addressing](#memory) | [Instructions](#instructions) | [Calling Convention](#calling-convention)

Original Documents: [Intel-based](http://www.cs.virginia.edu/~evans/cs216/guides/x86.html) | [att-based](http://flint.cs.yale.edu/cs421/papers/x86-asm/asm.html)

## X86 Registers

32-bit: Exx; 64-bit: Rxx

General Purpose: EAX, EBX, ECX, EDX, ESI, EDI

Stack Pointer: ESP, EBP

[X86 Assembly/X86 Architecture](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture)

[Purpose](https://en.wikipedia.org/wiki/X86#Purpose) of the registers.

## Basics

| | |
| -- | -- |
|AT&T Syntax|  `mnemonic  source, destination` |
|Intel-syntax| `mnemonic  destination, source`|

**Register Reference**: %ax, %eax, %rax

All the labels and numeric constants used as *immediate operands* (i.e. not in an address calculation like `3(%eax,%ebx,8)`) are always prefixed by a dollar sign. When needed, hexadecimal notation can be used with the 0x prefix (e.g. $0xABC). Without the prefix, numbers are interpreted in the decimal basis.

**Literal Values**: constant number: `$100`, address of lable: `$_start`

<a id="memory"></a>
## Memory and Addressing Modes

### Declaring Static Data Regions

You can declare static data regions (analogous to global variables) in x86 assembly using special assembler directives for this purpose. Data declarations should be preceded by the .data directive. Following this directive, the directives .byte, .short, and .long can be used to declare one, two, and four byte data locations, respectively. To refer to the address of the data created, we can label them. Labels are very useful and versatile in assembly, they give names to memory locations that will be figured out later by the assembler or the linker. This is similar to declaring variables by name, but abides by some lower level rules. For example, locations declared in sequence will be located in memory next to one another.

Example declarations:

```asm
.data		
var:		
    .byte 64    /* Declare a byte, referred to as location var, containing the value 64. */
    .byte 10    /* Declare a byte with no label, containing the value 10. Its location is var + 1. */
x:		
    .short 42   /* Declare a 2-byte value initialized to 42, referred to as location x. */
y:		
    .long 30000 /* Declare a 4-byte value, referred to as location y, initialized to 30000. */
```

Unlike in high level languages where arrays can have many dimensions and are accessed by indices, arrays in x86 assembly language are simply a number of cells located contiguously in memory. An array can be declared by just listing the values, as in the first example below. For the special case of an array of bytes, string literals can be used. In case a large area of memory is filled with zeroes the .zero directive can be used.

Some examples:

```asm
s:		
    .long 1, 2, 3  /* Declare three 4-byte values, initialized to 1, 2, and 3.
                      The value at location s + 8 will be 3. */
barr:		
    .zero 10   /* Declare 10 bytes starting at location barr, initialized to 0. */
str:		
    .string "hello"  /* Declare 6 bytes starting at the address str initialized to
                      the ASCII character values for hello followed by a nul (0) byte. */
```


### Addressing Memory

Modern x86-compatible processors are capable of addressing up to 232 bytes of memory: memory addresses are 32-bits wide. In the examples above, where we used labels to refer to memory regions, these labels are actually replaced by the assembler with 32-bit quantities that specify addresses in memory. In addition to supporting referring to memory regions by labels (i.e. constant values), the x86 provides a flexible scheme for computing and referring to memory addresses: up to two of the 32-bit registers and a 32-bit signed constant can be added together to compute a memory address. One of the registers can be optionally pre-multiplied by 2, 4, or 8.

The addressing modes can be used with many x86 instructions (we'll describe them in the next section). Here we illustrate some examples using the mov instruction that moves data between registers and memory. This instruction has two operands: the first is the source and the second specifies the destination.

Some examples of mov instructions using address computations are:

```asm
# Load 4 bytes from the memory address in EBX into EAX
mov (%ebx), %eax

# Move the contents of EBX into the 4 bytes at memory address var
# (Note, var is a 32-bit constant)
mov %ebx, var(,1)

# Move 4 bytes at memory address ESI + (-4) into EAX
mov -4(%esi), %eax

# Move the contents of CL into the byte at address ESI+EAX
mov %cl, (%esi,%eax,1)

# Move the 4 bytes of data at address ESI+4*EBX into EDX
mov (%esi,%ebx,4), %edx

# Can only add register values
mov (%ebx,%ecx,-1), %eax

# At most 2 registers in address computation
mov %ebx, (%eax,%esi,%edi,1)
```

### Operation Suffixes

In general, the intended size of the of the data item at a given memory address can be inferred from the assembly code instruction in which it is referenced. For example, in all of the above instructions, the size of the memory regions could be inferred from the size of the register operand. When we were loading a 32-bit register, the assembler could infer that the region of memory we were referring to was 4 bytes wide. When we were storing the value of a one byte register to memory, the assembler could infer that we wanted the address to refer to a single byte in memory.

However, in some cases the size of a referred-to memory region is ambiguous. Consider the instruction mov $2, (%ebx). Should this instruction move the value 2 into the single byte at address EBX? Perhaps it should move the 32-bit integer representation of 2 into the 4-bytes starting at address EBX. Since either is a valid possible interpretation, the assembler must be explicitly directed as to which is correct. The size prefixes b, w, and l serve this purpose, indicating sizes of 1, 2, and 4 bytes respectively.

For example:

```asm
movb $2, (%ebx)	/* Move 2 into the single byte at the address stored in EBX. */
movw $2, (%ebx)	/* Move the 16-bit integer representation of 2 into the 2 bytes starting at the address in EBX. */
movl $2, (%ebx)     	/* Move the 32-bit integer representation of 2 into the 4 bytes starting at the address in EBX. */
```

## Instructions

Machine instructions generally fall into three categories: data movement, arithmetic/logic, and control-flow.

We use the following notation:

```
<reg32>  Any 32-bit register (%eax, %ebx, %ecx, %edx, %esi, %edi, %esp, or %ebp)
<reg16>  Any 16-bit register (%ax, %bx, %cx, or %dx)
<reg8>   Any 8-bit register (%ah, %bh, %ch, %dh, %al, %bl, %cl, or %dl)
<reg>    Any register
<mem>    A memory address (e.g., (%eax), 4+var(,1), or (%eax,%ebx,1))
<con32>  Any 32-bit immediate
<con16>  Any 16-bit immediate
<con8>   Any 8-bit immediate
<con>    Any 8-, 16-, or 32-bit immediate
```

In assembly language, all the labels and numeric constants used as immediate operands (i.e. not in an address calculation like 3(%eax,%ebx,8)) are always prefixed by a dollar sign. When needed, hexadecimal notation can be used with the 0x prefix (e.g. $0xABC). Without the prefix, numbers are interpreted in the decimal basis.


### Data Movement Instructions

**mov**

```
mov <reg>, <reg>
mov <reg>, <mem>
mov <mem>, <reg>
mov <con>, <reg>
mov <con>, <mem>
```

Direct memory-to-memory moves are not. In cases where memory transfers are desired, the source memory contents must first be loaded into a register, then can be stored to the destination memory address.

Examples
```asm
mov %ebx, %eax    # copy the value in EBX into EAX
movb $5, var(,1)  # store the value 5 into the byte at location var
```

**push**

Decrements ESP by 4, then places its operand into the contents of the 32-bit location at address (%esp). ESP (the stack pointer) is decremented by push since the x86 stack grows down — i.e. the stack grows from high addresses to lower addresses.

```
push <reg32>
push <mem>
push <con32>
```

Examples

```asm
push %eax     # push eax on the stack
push var(,1)  # push the 4 bytes at address var onto the stack
```

**pop**

Moves the 4 bytes located at memory location (%esp) into the specified register or memory location, and then increments ESP by 4.

```
pop <reg32>
pop <mem>
```

Examples

```asm
pop %edi    # pop the top element of the stack into EDI.
pop (%ebx)  # pop the top element of the stack into memory at the four bytes starting at location EBX.
```

**lea** — Load effective address

Places the *address* specified by its first operand into the register specified by its second operand. Note, the *contents* of the memory location are not loaded, only the effective address is computed and placed into the register. This is useful for obtaining a pointer to a memory region or to perform simple arithmetic operations.

`lea <mem>, <reg32>`

Examples

```asm
lea (%ebx,%esi,8), %edi   # the quantity EBX+8*ESI is placed in EDI.
lea val(,1), %eax         # the value val is placed in EAX.
```

### Arithmetic and Logic Instructions


**add**

Operants cannot both be memeory location.

```
add <reg>, <reg>
add <mem>, <reg>
add <reg>, <mem>
add <con>, <reg>
add <con>, <mem>
```

Examples

```asm
add $10, %eax    # EAX is set to EAX + 10
addb $10, (%eax) # add 10 to the single byte stored at memory address stored in EAX
```

**sub**

op2 - op1. Operants cannot both be memeory location.

```
sub <reg>, <reg>
sub <mem>, <reg>
sub <reg>, <mem>
sub <con>, <reg>
sub <con>, <mem>
```

Examples

```asm
sub %ah, %al    # AL is set to AL - AH
sub $216, %eax  # EAX = EAX = 216
```

**inc, dec**

```
inc <reg>
inc <mem>
dec <reg>
dec <mem>
```
Examples

```asm
dec %eax      # subtract one from the contents of EAX
incl var(,1)  # add one to the 32-bit integer stored at location var
```

**imul** — Integer multiplication

Multilple op1 and op2 and stores result to the last operand (op2 in 2-oprand form, op3 in 3-oprand form).

In 3-operand form, op1 must be a constant value. The last(result) operand must be a register.

```
imul <reg32>, <reg32>
imul <mem>, <reg32>
imul <con>, <reg32>, <reg32>
imul <con>, <mem>, <reg32>
```

Examples

```
# multiply the contents of EAX by the 32-bit contents of 
# the memory at location EBX. Store the result in EAX.
imul (%ebx), %eax

imul $25, %edi, %esi  # ESI = EDI * 25
```

**idiv** — Integer division

Divides the contents of the 64 bit integer `EDX:EAX` (constructed by viewing EDX as the most significant four bytes and EAX as the least significant four bytes) by the specified operand value. The quotient result of the division is stored into EAX, while the remainder is placed in EDX.

```
idiv <reg32>
idiv <mem>
```

Examples

```a    SM
# divide the contents of EDX:EAX by the contents of EBX. 
# Place the quotient in EAX and the remainder in EDX.
idiv %ebx

# divide the contents of EDX:EAS by the 32-bit value stored at the memory 
# location in EBX. Place the quotient in EAX and the remainder in EDX.
idivw (%ebx)
```

**and, or, xor*

```
and/or/xor <reg>, <reg>
and/or/xor <mem>, <reg>
and/or/xor <reg>, <mem>
and/or/xor <con>, <reg>
and/or/xor <con>, <mem>
```

Examples
```asm
and $0x0f, %eax  # clear all but the last 4 bits of EAX.
xor %edx, %edx   # set the contents of EDX to zero.
```

**not** — Bitwise logical not

Logically negates the operand contents (that is, flips all bit values in the operand).

```
not <reg>
not <mem>
```

Example
```asm
not %eax   # flip all the bits of EAX
```

**neg** — Negate

Performs the two's complement negation of the operand contents.

```
neg <reg>
neg <mem>
```

Example
```asm
neg %eax    # EAX = (- EAX)
```

**shl, shr** — Shift left and right

Shift op2 by op1 places (up to 31 places). Empty positions are filled with zeros. op1 can be either an 8-bit constant or the register CL. Shifts counts of greater then 31 are performed modulo 32.

```
shl/shr <con8>, <reg>
shl/shr <con8>, <mem>
shl/shr %cl, <reg>
shl/shr %cl, <mem>
```

Examples
```asm
# Multiply the value of EAX by 2 (if the most significant bit is 0)
shl $1, eax

# Store in EBX the floor of result of dividing the value of EBX by 2n 
# where n is the value in CL. Caution: for negative integers, 
# it is different from the C semantics of division!
shr %cl, %ebx
```

### Control Flow Instructions

The x86 processor maintains an instruction pointer (`EIP`) register that is a 32-bit value indicating the location in memory where the current instruction starts. Normally, it increments to point to the next instruction in memory begins after execution an instruction. The EIP register cannot be manipulated directly, but is updated implicitly by provided control flow instructions.

We use the notation <label> to refer to labeled locations in the program text. Labels can be inserted anywhere in x86 assembly code text by entering a label name followed by a colon. For example,

```asm
       mov 8(%ebp), %esi
begin:
       xor %ecx, %ecx
       mov (%esi), %eax
```

**jmp**

`jmp <lable>`

**j*condition*** — Conditional jump

These instructions are conditional jumps that are based on the status of a set of condition codes that are stored in a special register called the *machine status word*. The contents of the machine status word include information about the last arithmetic operation performed. For example, one bit of this word indicates if the last result was zero. Another indicates if the last result was negative. Based on these condition codes, a number of conditional jumps can be performed.

A number of the conditional branches are given names that are intuitively based on the last operation performed being a special compare instruction, `cmp` (see below). For example, conditional branches such as `jle` and `jne` are based on first performing a cmp operation on the desired operands.

```
je  <label> (jump when equal)
jne <label> (jump when not equal)
jz  <label> (jump when last result was zero)
jg  <label> (jump when greater than)
jge <label> (jump when greater than or equal to)
jl  <label> (jump when less than)
jle <label> (jump when less than or equal to)
```

Example
```asm
cmp %ebx, %eax
jle done
```
If ***EAX <= EBX***, jump to the label done. Otherwise, continue to the next instruction.

**cmp** — Compare

Compare the values of the two specified operands, setting the condition codes in the machine status word appropriately. This instruction is equivalent to the sub instruction, except the result of the subtraction is discarded instead of replacing the first operand.

```
cmp <reg>, <reg>
cmp <mem>, <reg>
cmp <reg>, <mem>
cmp <con>, <reg>
```

Example
```asm
cmpb $10, (%ebx)
jeq loop
```
If the byte stored at the memory location in EBX is equal to the integer constant 10, jump to the location labeled loop.

**call, ret** — Subroutine call and return

These instructions implement a subroutine call and return. The call instruction first pushes the current code location onto the hardware supported stack in memory (see the push instruction for details), and then performs an unconditional jump to the code location indicated by the label operand. Unlike the simple jump instructions, the call instruction saves the location to return to when the subroutine completes.
The ret instruction implements a subroutine return mechanism. This instruction first pops a code location off the hardware supported in-memory stack (see the pop instruction for details). It then performs an unconditional jump to the retrieved code location.

```
call <label>
ret
```

## Calling Convention

To allow separate programmers to share code and develop libraries for use by many programs, and to simplify the use of subroutines in general, programmers typically adopt a common *calling convention*. The calling convention is a protocol about how to call and return from routines. For example, given a set of calling convention rules, a programmer need not examine the definition of a subroutine to determine how parameters should be passed to that subroutine. Furthermore, given a set of calling convention rules, high-level language compilers can be made to follow the rules, thus allowing hand-coded assembly language routines and high-level language routines to call one another.

In practice, many calling conventions are possible. We will describe the widely used C language calling convention. Following this convention will allow you to write assembly language subroutines that are safely callable from C (and C++) code, and will also enable you to call C library functions from your assembly language code.

The C calling convention is based heavily on the use of the hardware-supported stack. It is based on the push, pop, call, and ret instructions. Subroutine parameters are passed on the stack. Registers are saved on the stack, and local variables used by subroutines are placed in memory on the stack. The vast majority of high-level procedural languages implemented on most processors have used similar calling conventions.

The calling convention is broken into two sets of rules. The first set of rules is employed by the caller of the subroutine, and the second set of rules is observed by the writer of the subroutine (the callee). It should be emphasized that mistakes in the observance of these rules quickly result in fatal program errors since the stack will be left in an inconsistent state; thus meticulous care should be used when implementing the call convention in your own subroutines.

```
  stack grows toward lower address

...

saved ESI              ESP
saved EDI
local variable 3
local variable 2
local variable 1   [ebp]-4
saved EBP              EBP
return address
parameter 1    [ebp]+8
parameter 2    [ebp]+12
parameter 3    [ebp]+16

...

  higher address
```

*Stack during Subroutine Call*


A good way to visualize the operation of the calling convention is to draw the contents of the nearby region of the stack during subroutine execution. The image above depicts the contents of the stack during the execution of a subroutine with three parameters and three local variables. The cells depicted in the stack are 32-bit wide memory locations, thus the memory addresses of the cells are 4 bytes apart. The first parameter resides at an offset of 8 bytes from the base pointer. Above the parameters on the stack (and below the base pointer), the call instruction placed the return address, thus leading to an extra 4 bytes of offset from the base pointer to the first parameter. When the ret instruction is used to return from the subroutine, it will jump to the return address stored on the stack.

### Caller Rules

To make a subrouting call, the caller should:
1. Before calling a subroutine, the caller should save the contents of certain registers that are designated caller-saved. The caller-saved registers are EAX, ECX, EDX. Since the called subroutine is allowed to modify these registers, if the caller relies on their values after the subroutine returns, the caller must push the values in these registers onto the stack (so they can be restore after the subroutine returns.
1. To pass parameters to the subroutine, push them onto the stack before the call. The parameters should be pushed in inverted order (i.e. last parameter first). Since the stack grows down, the first parameter will be stored at the lowest address (this inversion of parameters was historically used to allow functions to be passed a variable number of parameters).
1. To call the subroutine, use the call instruction. This instruction places the return address on top of the parameters on the stack, and branches to the subroutine code. This invokes the subroutine, which should follow the callee rules below.

After the subroutine returns (immediately following the call instruction), the caller can expect to find the return value of the subroutine in the register EAX. To restore the machine state, the caller should:
1. Remove the parameters from stack. This restores the stack to its state before the call was performed.
1. Restore the contents of caller-saved registers (EAX, ECX, EDX) by popping them off of the stack. The caller can assume that no other registers were modified by the subroutine.

Example

The code below shows a function call that follows the caller rules. The caller is calling a function myFunc that takes three integer parameters. First parameter is in EAX, the second parameter is the constant 216; the third parameter is in the memory location stored in EBX.

```asm
push (%ebx)    /* Push last parameter first */
push $216      /* Push the second parameter */
push %eax      /* Push first parameter last */

call myFunc    /* Call the function (assume C naming) */

add $12, %esp
```

Note that after the call returns, the caller cleans up the stack using the add instruction. We have 12 bytes (3 parameters * 4 bytes each) on the stack, and the stack grows down. Thus, to get rid of the parameters, we can simply add 12 to the stack pointer.

The result produced by `myFunc` is now available for use in the register EAX. The values of the caller-saved registers (ECX and EDX), may have been changed. If the caller uses them after the call, it would have needed to save them on the stack before the call and restore them after it.

### Callee Rules

The definition of the subroutine should adhere to the following rules at the beginning of the subroutine:

1. Push the value of EBP onto the stack, and then copy the value of ESP into EBP using the following instructions: \
    `push %ebp` \
    `mov  %esp, %ebp` \
This initial action maintains the base pointer, EBP. The base pointer is used by convention as a point of reference for finding parameters and local variables on the stack. When a subroutine is executing, the base pointer holds a copy of the stack pointer value from when the subroutine started executing. Parameters and local variables will always be located at known, constant offsets away from the base pointer value. We push the old base pointer value at the beginning of the subroutine so that we can later restore the appropriate base pointer value for the caller when the subroutine returns. Remember, the caller is not expecting the subroutine to change the value of the base pointer. We then move the stack pointer into EBP to obtain our point of reference for accessing parameters and local variables.
1. Next, allocate local variables by making space on the stack. Recall, the stack grows down, so to make space on the top of the stack, the stack pointer should be decremented. The amount by which the stack pointer is decremented depends on the number and size of local variables needed. For example, if 3 local integers (4 bytes each) were required, the stack pointer would need to be decremented by 12 to make space for these local variables (i.e., sub $12, %esp). As with parameters, local variables will be located at known offsets from the base pointer.
1. Next, save the values of the callee-saved registers that will be used by the function. To save registers, push them onto the stack. The callee-saved registers are EBX, EDI, and ESI (ESP and EBP will also be preserved by the calling convention, but need not be pushed on the stack during this step).

After these three actions are performed, the body of the subroutine may proceed. When the subroutine is returns, it must follow these steps:
1. Leave the return value in EAX.
1. Restore the old values of any callee-saved registers (EDI and ESI) that were modified. The register contents are restored by popping them from the stack. The registers should be popped in the inverse order that they were pushed.
1. Deallocate local variables. The obvious way to do this might be to add the appropriate value to the stack pointer (since the space was allocated by subtracting the needed amount from the stack pointer). In practice, a less error-prone way to deallocate the variables is to move the value in the base pointer into the stack pointer: `mov %ebp, %esp`. This works because the base pointer always contains the value that the stack pointer contained immediately prior to the allocation of the local variables.
1. Immediately before returning, restore the caller's base pointer value by popping EBP off the stack. Recall that the first thing we did on entry to the subroutine was to push the base pointer to save its old value.
1. Finally, return to the caller by executing a ret instruction. This instruction will find and remove the appropriate return address from the stack.

Note that the callee's rules fall cleanly into two halves that are basically mirror images of one another. The first half of the rules apply to the beginning of the function, and are commonly said to define the prologue to the function. The latter half of the rules apply to the end of the function, and are thus commonly said to define the epilogue of the function.

Example

Here is an example function definition that follows the callee rules:

```asm
  /* Start the code section */
  .text

  /* Define myFunc as a global (exported) function. */
  .globl myFunc
  .type myFunc, @function
myFunc:

  /* Subroutine Prologue */
  push %ebp      /* Save the old base pointer value. */
  mov %esp, %ebp /* Set the new base pointer value. */
  sub $4, %esp   /* Make room for one 4-byte local variable. */
  push %edi      /* Save the values of registers that the function */
  push %esi      /* will modify. This function uses EDI and ESI. */
  /* (no need to save EBX, EBP, or ESP) */

  /* Subroutine Body */
  mov 8(%ebp), %eax   /* Move value of parameter 1 into EAX. */
  mov 12(%ebp), %esi  /* Move value of parameter 2 into ESI. */
  mov 16(%ebp), %edi  /* Move value of parameter 3 into EDI. */

  mov %edi, -4(%ebp)  /* Move EDI into the local variable. */
  add %esi, -4(%ebp)  /* Add ESI into the local variable. */
  add -4(%ebp), %eax  /* Add the contents of the local variable */
                      /* into EAX (final result). */

  /* Subroutine Epilogue */
  pop %esi       /* Recover register values. */
  pop %edi
  mov %ebp, %esp /* Deallocate the local variable. */
  pop %ebp       /* Restore the caller's base pointer value. */
  ret
```

The subroutine prologue performs the standard actions of saving a snapshot of the stack pointer in EBP (the base pointer), allocating local variables by decrementing the stack pointer, and saving register values on the stack.

In the body of the subroutine we can see the use of the base pointer. Both parameters and local variables are located at constant offsets from the base pointer for the duration of the subroutines execution. In particular, we notice that since parameters were placed onto the stack before the subroutine was called, they are always located below the base pointer (i.e. at higher addresses) on the stack. The first parameter to the subroutine can always be found at memory location (EBP+8), the second at (EBP+12), the third at (EBP+16). Similarly, since local variables are allocated after the base pointer is set, they always reside above the base pointer (i.e. at lower addresses) on the stack. In particular, the first local variable is always located at (EBP-4), the second at (EBP-8), and so on. This conventional use of the base pointer allows us to quickly identify the use of local variables and parameters within a function body.

The function epilogue is basically a mirror image of the function prologue. The caller's register values are recovered from the stack, the local variables are deallocated by resetting the stack pointer, the caller's base pointer value is recovered, and the ret instruction is used to return to the appropriate code location in the caller.


---

## Instructions


**Memory Addressing**: `segment-override:signed-offset(base,index,scale)`

`%es:100(%eax,%ebx,2)` Note that the offsets and the scale should not be prefixed by '$'. 


```
GAS memory operand    NASM memory operand
------------------    -------------------

100                   [100]
%es:100               [es:100]
(%eax)                [eax]
(%eax,%ebx)           [eax+ebx]
(%ecx,%ebx,2)         [ecx+ebx*2]
(,%ebx,2)             [ebx*2]
-10(%eax)             [eax-10]
%ds:-10(%ebp)         [ds:ebp-10]
```

Example instructions,
```asm
mov	%ax,	100
mov	%eax,	-100(%eax)
```
The first instruction moves the value in register AX into offset 100 of the data segment register (by default), and the second one moves the value in eax register to [eax-100].




**Operand Sizes**

At times, especially when moving literal values to memory, it becomes neccessary to specify the size-of-transfer or the operand-size. For example the instruction,

```asm
mov	$10,	100
```
only specfies that the value 10 is to be moved to the memory offset 100, but not the transfer size. In NASM this is done by adding the casting keyword byte/word/dword etc. to any of the operands. In AT&T syntax, this is done by adding a suffix - b/w/l - to the instruction. For example,

```asm
movb	$10,	%es:(%eax)
```
moves a byte value 10 to the memory location [ea:eax], whereas,

```asm
movl	$10,	%es:(%eax)
```
moves a long value (dword) 10 to the same place.

A few more examples,

```asm
movl	$100, %ebx
pushl	%eax
popw	%ax
```

**Control Transfer Instructions**

jmp, call, ret

The possible types of branch addressing are - relative offset (label), register, memory operand, and segment-offset pointers. 

*Relative offsets*, are specified using labels.

```
GAS syntax			NASM syntax
==========			===========

jmp	   *100         jmp  near [100]
call   *100         call near [100]
jmp    *%eax        jmp  near eax
jmp    *%ecx        call near ecx
jmp    *(%eax)      jmp  near [eax]
call   *(%ebx)      call near [ebx]
ljmp   *100         jmp  far  [100]
lcall  *100         call far  [100]
ljmp   *(%eax)      jmp  far  [eax]
lcall  *(%ebx)      call far  [ebx]
ret                 retn
lret                retf
lret $0x100         retf 0x100
```

*Segment-offset* pointers are specified using the following format:

```asm
jmp	$segment, $offset
```

For example:

```asm
jmp	$0x10, $0x100000
```

## Section / Regions

.text
.data
.bss

Address are all relative offset to their sections respectivly.

Linked will put the same section from different objects together. For example, all code in text sections from different object files are put together, changing their relative offset. (see the mannual).



http://flint.cs.yale.edu/cs421/papers/x86-asm/asm.html

http://www.cs.yale.edu/homes/qcar/
