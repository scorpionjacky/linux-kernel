# Knowledge Points with C/ASM

**definitions vs declarations**

A definition associates a name with an implementation of that name, which could be either data or code:
- A definition of a variable induces the compiler to reserve some space for that variable, and possibly fill that space with a particular value.
- A definition of a function induces the compiler to generate code for that function.

A declaration tells the C compiler that a definition of something (with a particular name) exists elsewhere in the program, probably in a different C file. (Note that a definition also counts as a declaration—it's a declaration that also happens to fill in the particular "elsewhere").

A variable or function can be declared any number of times, but it can be defined only once.

For variables, the definitions split into two sorts:
- global variables, which exist for the whole lifetime of the program ("static extent"), and which are usually accessible in lots of different functions
- local variables, which only exist while a particular function is being executed ("local extent") and are only accessible within that function

**static variables**

static global variables
- Limit the scope of the global variables to this file only

static local variables
- visible only in its enclosing scope, but the value is initialized only once and sustains across function calls. they exists for the lifetime of the program
- are allocated memory in data segment, not stack segment.
- are initialized as 0 if not initialized explicitly.
- In C, static variables can only be initialized using constant literals.
- Static variables should not be declared inside structure. The reason is C compiler requires the entire structure elements to be placed together (i.e.) memory allocation for structure members should be contiguous. It is possible to declare structure inside the function (stack segment) or allocate memory dynamically(heap segment) or it can be even global (BSS or data segment). Whatever might be the case, all structure members should reside in the same memory segment because the value for the structure element is fetched by counting the offset of the element from the beginning address of the structure. Separating out one member alone to data segment defeats the purpose of static variable and it is possible to have an entire structure as static.

**static functions**
- static functions is not visible outside of the file

**variable initialization**
- initialized variable
- non-initialized variable

**extern**

First, Let’s consider the use of extern in functions. It turns out that when a function is declared or defined, the extern keyword is implicitly assumed. When we write.

```c
int foo(int arg1, char arg2);
```

The compiler treats it as:

```c
extern int foo(int arg1, char arg2);
```

Since the extern keyword extends the function’s visibility to the whole program, the function can be used (called) anywhere in any of the files of the whole program, provided those files contain a declaration of the function. (With the declaration of the function in place, the compiler knows the definition of the function exists somewhere else and it goes ahead and compiles the file).

Now let’s consider the use of extern with variables. To begin with, how would you declare a variable without defining it?

```c
extern int var;
```

Here, an integer type variable called var has been declared (it hasn’t been defined yet, so no memory allocation for var so far). And we can do this declaration as many times as we want.

Now, how would you define var? You would do this:

```c
int var;
```
In this line, an integer type variable called var has been both declared and defined (remember that definition is the superset of declaration). Since this is a definition, the memory for var is also allocated.

We need to include the extern keyword explicitly when we want to declare variables without defining them. Also, as the extern keyword extends the visibility to the whole program, by using the extern keyword with a variable, we can use the variable anywhere in the program provided we include its declaration the variable is defined somewhere.

```c
int var; 
int main(void) 
{ 
   var = 10; 
   return 0; 
} 
```
This program compiles successfully. var is defined (and declared implicitly) globally.

```c
extern int var; 
int main(void) 
{ 
  return 0; 
} 
```
This program compiles successfully. Here var is declared only. Notice var is never used so no problems arise.

```c
extern int var; 
int main(void) 
{ 
  var = 10; 
  return 0; 
} 
```
This program throws an error in compilation because var is declared but not defined anywhere. Essentially, the var isn’t allocated any memory. And the program is trying to change the value to 10 of a variable that doesn’t exist at all.

```c
#include "somefile.h" 
extern int var; 
int main(void) 
{ 
 var = 10; 
 return 0; 
} 
```
Assuming that somefile.h contains the definition of var, this program will compile successfully.

```c
extern int var = 0; 
int main(void) 
{ 
 var = 10; 
 return 0; 
} 
```

Do you think this program will work? Well, here comes another surprise from C standards. They say that..if a variable is only declared and an initializer is also provided with that declaration, then the memory for that variable will be allocated–in other words, that variable will be considered as defined. Therefore, as per the C standard, this program will compile successfully and work.

Summary:
1. A declaration can be done any number of times but definition only once.
1. the extern keyword is used to extend the visibility of variables/functions.
1. Since functions are visible throughout the program by default, the use of extern is not needed in function declarations or definitions. Its use is implicit.
1. When extern is used with a variable, it’s only declared, not defined.
1. As an exception, when an extern variable is declared with initialization, it is taken as the definition of the variable as well.

**Memory Layout of C Programs**

https://www.geeksforgeeks.org/memory-layout-of-c-program/

**`register`**

https://www.geeksforgeeks.org/understanding-register-keyword

**`volatile`**

https://www.geeksforgeeks.org/understanding-volatile-qualifier-in-c

**`const`**

https://www.geeksforgeeks.org/const-qualifier-in-c

**Storage Classes in C**

https://www.geeksforgeeks.org/storage-classes-in-c

**Inline function**

Inline Function are those function whose definitions are small and be substituted at the place where its function call is happened. Function substitution is totally compiler choice.

link error for inline functions: https://www.geeksforgeeks.org/inline-function-in-c/

**function prototype, declare before use, default return type**

https://www.geeksforgeeks.org/importance-of-function-prototype-in-c

https://www.geeksforgeeks.org/g-fact-95

https://www.geeksforgeeks.org/implicit-return-type-int-c-language/

https://www.geeksforgeeks.org/what-is-the-purpose-of-a-function-prototype

**pointer to function**

Key: operator `()` takes priority over operator `*`

```c
int * ptrInteger;  /* a pointer */
int foo(int); /* a function with one int param and returns int */
int * foo(int); /* a function with one int param and returns a pointer to int */
int (*foo)(int); /* a pointer to function, wich take one int param and return int */
```

**va_list etc.**

https://softwareengineering.stackexchange.com/questions/232838/what-is-the-underlying-mechanism-behind-va-list-and-where-is-it-defined
