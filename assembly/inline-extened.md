Whatever is inside the asm call will be placed as is in the assembly output generated by the C compiler. This assembly output is then fed to the assembler. This kind of inline assembly is good for doing things which can not be directly done using C, but we cant place these instructions modifying registers in the middle of the C code. Because compiler will just place this code in the assembly output and it will generate the assembly for the C code without knowing that you are messing up with the registers.

But if you write the content of a complete function using this statement it will work fine because you wont be messing up with the compiler generated asm code.

Lets see an example. Consider the following small program which calculates average of numbers in two arrays and stores the result in the third array.

```c
int numX[5] = {10,20,30,40,50};
int numY[5] = {20,30,40,50,60};
int res[5];
void avg()
{
    int i;
    for(i = 0; i < 5; ++i)
    {
        res[i] = (numX[i] + numY[i])/2;        
    }
} 
main()
{
    int i;
    avg();
    for(i =0; i <5 ; ++i)
    {
        printf("result[%d] = %d \n", i,res[i]);
    }
} 
```

Now we lets see how we can convert the division by two to asm using basic inline assembly.

```c
void avg()
{
    int i;
    for(i = 0; i < 5; ++i)
    {
        res[i] = (numX[i] + numY[i]);        
        asm("
          movl  -4(%ebp), %eax        ; move i to eax
          movl  _res(,%eax,4), %ebx   ; move res[i] to ebx
          sarl  %ebx              ; divide ebx by two by shifting right
          movl  %ebx, _res(,%ebx,4)   ; move ebx to res[i]
        ");
    }
}
```

When we compile this program and run it, it works fine and prints result same as the previous program. Here we are lucky that we are changing the value of register eax and ebx and compiler is not using them to store some variable across the loop.

Following is the asm for the avg function in the above case. Notice that the compiler puts the asm statements inside the `asm()` function as it is inside two directives /APP and /NO_APP

```asm
_avg:
 pushl %ebp
 movl %esp, %ebp
 subl $4, %esp
 movl $0, -4(%ebp)  #  i
L2:
 cmpl $4, -4(%ebp)  #  i
 jle L5
 jmp L1
L5:
 movl -4(%ebp), %ecx  #  i
 movl -4(%ebp), %edx  #  i
 movl -4(%ebp), %eax  #  i
 movl _numY(,%eax,4), %eax  #  numY
 addl _numX(,%edx,4), %eax  #  numX
 movl %eax, _res(,%ecx,4)  #  res
/APP
 
                movl  -4(%ebp), %eax
                movl  _res(,%eax,4), %ebx
                sarl  %ebx
                movl  %ebx, _res(,%eax,4)
        
/NO_APP
 leal -4(%ebp), %eax
 incl (%eax)  #  i
 jmp L2
L1:
 leave
 ret
```

Here we can see that ebx is not at all used while eax is loaded with the value of i each time in the loop. so our asm code doesnt interfere with the compiler generated code. Now lets try to compile the same program with -O2 optimizations. Following is the asm code generated.

```asm
_avg:
 pushl %ebp
 xorl %edx, %edx
 movl %esp, %ebp
 movl $_numY, %ecx
 pushl %esi
 movl $_res, %esi
 pushl %ebx
 movl $_numX, %ebx
L6:
 movl (%ecx,%edx,4), %eax  #  numY
 addl (%ebx,%edx,4), %eax  #  numX
 movl %eax, (%esi,%edx,4)  #  res
/APP
 
                movl  -4(%ebp), %eax
                movl  _res(,%eax,4), %ebx
                sarl  %ebx
                movl  %ebx, _res(,%eax,4)
        
/NO_APP
 incl %edx  #  i
 cmpl $4, %edx  #  i
 jle L6
 popl %ebx
 popl %esi
 popl %ebp
 ret
```

Here compiler has tried to optimize the code by moving many things out of the loop and keeping the values of variables into the registers. This program wont work and will give core dump. The reason is that compiler is using ebx register to keep the pointer to numX and we are changing the value of ebx in our inline asm code. Compiler unaware of what we have done to ebx still assumes that ebx will have the pointer to numX.

In gcc you can use extended asm for telling the compiler what you did in your inline asm code. Like what registers you made dirty. You can even ask compiler to put the value of some variables into some resgisters for you.

**The Extended Inline Assembly**

The syntax of extended inline asm is similar to the basic inline asm except that it allows specification of input registers, output registers and clobbered space (registers and memory .

The syntax is `asm ( "statements" : output : input : clobbered);`

statements - The asm statements \
output - input constraint-name pairs "constraint" (name), separated by commas. \
input - ouput constraint-name pairs "constraint" (name), separated by commas. \
clobbered - comma separated list of registers clobbered. If you write to memory then "memory" has to inluded as one of the clobbered values. This is to tell gcc that we might have changed some value in the memory which gcc thought it had in a register, It is equivalent to clobbering all of the registers.

The outputs and inputs are referenced by numbers beginning with %0 inside asm statements. The numbering is done based on the order they appear. First numbers are given to output registers and then to input registers.

The constraints for input/output are :-

```
g - let the compiler decide which register to use for the variable
q - load into any available register from eax, ebx, ecx, edx
r - same as q but includes esi and edi
a - load into the eax register
b - load into the ebx register
c - load into the ecx register
d - load into the edx register
f - load into the floating point register
D - load into the edi register
S - load into the esi register
```

For output the contraints are prefixed by "=". The registers can also be accessed directly inside the asm statements, but in extended asm they are prefixed by two % instead of single % like %%eax , %%edx etc.

Lets do the same example function using extended inline asm

```c
void avg()
{
    int i;
    for(i = 0; i < 5; ++i)
    {
        res[i] = (numX[i] + numY[i]);       
        asm("sarl  %1
      movl %1, %0": "=r"(res[i]) :"r" (res[i]), "memory");            
    }
}
```

Here we are telling compiler to load res[i] in any register and we can refer that register using %0. The asm generated in this case is following.

```asm
_avg:
 pushl %ebp
 xorl %edx, %edx
 movl %esp, %ebp
 movl $_res, %ecx
 pushl %esi
 movl $_numX, %esi
 pushl %ebx
 movl $_numY, %ebx
L6:
 movl (%ebx,%edx,4), %eax  #  numY
 addl (%esi,%edx,4), %eax  #  numX
 movl %eax, (%ecx,%edx,4)  #  res
/APP
 sarl  %eax
        movl %eax, %eax
/NO_APP
 movl %eax, (%ecx,%edx,4)  #  res
 incl %edx  #  i
 cmpl $4, %edx  #  i
 jle L6
 popl %ebx
 popl %esi
 popl %ebp
 ret
```

Lets see some more examples. In above example the input and output were same so we can tell this to compiler using a contraint "0" as follows.

```c
void avg()
{
    int i;
    for(i = 0; i < 5; ++i)
    {
        res[i] = (numX[i] + numY[i]);       
        asm("sarl  %0 ": "=r"(res[i]) :"0" (res[i]), "memory");            
    }
}
```

The asm generated for this case is

```asm
_avg:
 pushl %ebp
 xorl %edx, %edx
 movl %esp, %ebp
 movl $_res, %ecx
 pushl %esi
 movl $_numX, %esi
 pushl %ebx
 movl $_numY, %ebx
L6:
 movl (%ebx,%edx,4), %eax  #  numY
 addl (%esi,%edx,4), %eax  #  numX
 movl %eax, (%ecx,%edx,4)  #  res
/APP
 sarl  %eax
/NO_APP
 movl %eax, (%ecx,%edx,4)  #  res
 incl %edx  #  i
 cmpl $4, %edx  #  i
 jle L6
 popl %ebx
 popl %esi
 popl %ebp
 ret
```

We can write the addition part as follows in extended asm

```c
void avg()
{
    int i;
    for(i = 0; i < 5; ++i)
    {
        asm("movl  %1, %0
             addl  %2, %0 "
             : "=r" (res[i]) :"r" (numX[i]), "r" (numY[i]): "memory" );  
        asm("sarl  %0" : "=r"(res[i]) :"0" (res[i]));            
    }
}
```

Here we load numX[i] in %1, numY[i] in %2 and the output i.e res[i] is represented as %0. The asm generated in this case is as follows

```asm
_avg:
 pushl %ebp
 xorl %ecx, %ecx
 movl %esp, %ebp
 pushl %edi
 pushl %esi
 movl $_numX, %edi
 pushl %ebx
 movl $_numY, %esi
 movl $_res, %ebx
L6:
 movl (%edi,%ecx,4), %eax  #  numX
 movl (%esi,%ecx,4), %edx  #  numY
/APP
 movl  %eax, %eax
             addl  %edx, %eax 
/NO_APP
 movl %eax, (%ebx,%ecx,4)  #  res
/APP
 sarl  %eax
/NO_APP
 movl %eax, (%ebx,%ecx,4)  #  res
 incl %ecx  #  i
 cmpl $4, %ecx  #  i
 jle L6
 popl %ebx
 popl %esi
 popl %edi
 popl %ebp
 ret
```

```c
void avg()
{
    int i;
    for(i = 0; i < 5; ++i)
    {
        asm("movl  %1, %0
             addl  %2, %0 
             sarl  %0 "
             : "=r" (res[i]) :"r" (numX[i]), "r" (numY[i]): "memory" );  
    }
}
```

The asm generated in this case is as follows

```asm
_avg:
 pushl %ebp
 xorl %ecx, %ecx
 movl %esp, %ebp
 pushl %edi
 pushl %esi
 movl $_numX, %edi
 pushl %ebx
 movl $_numY, %esi
 movl $_res, %ebx
L6:
 movl (%edi,%ecx,4), %eax  #  numX
 movl (%esi,%ecx,4), %edx  #  numY
/APP
 movl  %eax, %eax
             addl  %edx, %eax 
             sarl  %eax 
/NO_APP
 movl %eax, (%ebx,%ecx,4)  #  res
 incl %ecx  #  i
 cmpl $4, %ecx  #  i
 jle L6
 popl %ebx
 popl %esi
 popl %edi
 popl %ebp
 ret
```

Conclusion

Using extended inline asm of gcc we can write the inline asm code very easily. It provides for easy accessing of local and global variables so you dont have to care about the stack. And you can put inline asm code anywhere between the C code without worrying that you might destroy the asm generated by compiler for the C code.

In my next article I will be talking about the MMX instructions and how to build your own easy to use macros using extended asm for MMX instructions.
