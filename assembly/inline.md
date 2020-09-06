<asm | __asm__> [volotile | __volotile__] ("statements" [: [output] [: input [: clobbered]]]);

GNU C compiler i.e. GCC uses AT&T syntax

1. Register Naming: prefixed with %, for example %eax, %cl etc.
2. Ordering of operands: source(s) first, and destination last. For example, "mov %edx, %eax".
3. Operand Size: determined from the last character of the op-code name. b for (8-bit) byte, w for (16-bit) word, and l for (32-bit) long. For example, "movl %edx, %eax".
4. Immediate Operand: marked with a $ prefix, as in "addl $5, %eax", which means add immediate long value 5 to register %eax.
5. Memory Operands: "movl $bar, %ebx" puts the address of variable bar into register %ebx, while "movl bar, %ebx" puts the contents of variable bar into register %ebx.
6. Indexing: Indexing or indirection is done by enclosing the index register or indirection memory cell address in parentheses. For example, "movl 8(%ebp), %eax" (moves the contents at offset 8 from the cell pointed to by %ebp into register %eax).
