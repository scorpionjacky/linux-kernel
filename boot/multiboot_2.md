# Writing an OS in Rust (First Edition) Philipp Oppermann's blog

Entering Long Mode

Aug 25, 2015 (updated on Oct 29, 2015)

https://os.phil-opp.com/entering-longmode/

Table of Contents

- Some Tests
- Creating a Stack
- Multiboot check
- CPUID check
- Long Mode check
- Putting it together
- Paging
- Set Up Identity Paging
- Enable Paging
- The Global Descriptor Table
- Loading the GDT
- What's next?
- Footnotes

No longer updated! You are viewing the a post of the first edition of “Writing an OS in Rust”, which is no longer updated. You can find the second edition [here](https://os.phil-opp.com/second-edition/).

In the [previous post](https://os.phil-opp.com/multiboot-kernel/) we created a minimal multiboot kernel. It just prints `OK` and hangs. The goal is to extend it and call 64-bit [Rust](https://www.rust-lang.org/) code. But the CPU is currently in [protected mode](https://en.wikipedia.org/wiki/Protected_mode) and allows only 32-bit instructions and up to 4GiB memory. So we need to set up *Paging* and switch to the 64-bit [long mode](https://en.wikipedia.org/wiki/Long_mode) first.

I tried to explain everything in detail and to keep the code as simple as possible. If you have any questions, suggestions, or issues, please leave a comment or create an issue on Github. The source code is available in a [repository](https://github.com/phil-opp/blog_os/tree/first_edition_post_2/src/arch/x86_64), too.

🔗Some Tests

To avoid bugs and strange errors on old CPUs we should check if the processor supports every needed feature. If not, the kernel should abort and display an error message. To handle errors easily, we create an error procedure in `boot.asm`. It prints a rudimentary `ERR: X` message, where X is an error code letter, and hangs:

```asm
; Prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte  [0xb800a], al
    hlt
```

At address `0xb8000` begins the so-called [VGA text buffer](https://en.wikipedia.org/wiki/VGA-compatible_text_mode). It's an array of screen characters that are displayed by the graphics card. A [future post](https://os.phil-opp.com/printing-to-screen/) will cover the VGA buffer in detail and create a Rust interface to it. But for now, manual bit-fiddling is the easiest option.

A screen character consists of a 8 bit color code and a 8 bit [ASCII](https://en.wikipedia.org/wiki/ASCII) character. We used the color code `4f` for all characters, which means white text on red background. `0x52` is an ASCII `R`, `0x45` is an `E`, `0x3a` is a `:`, and `0x20` is a space. The second space is overwritten by the given ASCII byte. Finally the CPU is stopped with the `hlt` instruction.

Now we can add some check functions. A function is just a normal label with an `ret` (return) instruction at the end. The `call` instruction can be used to call it. Unlike the `jmp` instruction that just jumps to a memory address, the `call` instruction will push a return address to the stack (and the `ret` will jump to this address). But we don't have a stack yet. The [stack pointer](https://stackoverflow.com/a/1464052/866447) in the esp register could point to some important data or even invalid memory. So we need to update it and point it to some valid stack memory.

🔗Creating a Stack

To create stack memory we reserve some bytes at the end of our `boot.asm`:

```asm
...
section .bss
stack_bottom:
    resb 64
stack_top:
```

A stack doesn't need to be initialized because we will `pop` only when we `push`ed before. So storing the stack memory in the executable file would make it unnecessary large. By using the [.bss](https://en.wikipedia.org/wiki/.bss) section and the `resb` (reserve byte) command, we just store the length of the uninitialized data (= 64). When loading the executable, GRUB will create the section of required size in memory.

To use the new stack, we update the stack pointer register right after `start`:

```asm
global start

section .text
bits 32
start:
    mov esp, stack_top

    ; print `OK` to screen
    ...
```

We use `stack_top` because the stack grows downwards: A `push eax` subtracts 4 from `esp` and does a `mov [esp], eax` afterwards (`eax` is a general purpose register).

Now we have a valid stack pointer and are able to call functions. The following check functions are just here for completeness and I won't explain details. Basically they all work the same: They will check for a feature and jump to `error` if it's not available.

🔗Multiboot check

We rely on some Multiboot features in the next posts. To make sure the kernel was really loaded by a Multiboot compliant bootloader, we can check the `eax` register. According to the Multiboot specification ([PDF](https://nongnu.askapache.com/grub/phcoder/multiboot.pdf)), the bootloader must write the magic value `0x36d76289` to it before loading a kernel. To verify that we can add a simple function:

```asm
check_multiboot:
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "0"
    jmp error
```

We use the `cmp` instruction to compare the value in `eax` to the magic value. If the values are equal, the `cmp` instruction sets the zero flag in the [FLAGS register](https://en.wikipedia.org/wiki/FLAGS_register). The `jne` (“jump if not equal”) instruction reads this zero flag and jumps to the given address if it's not set. Thus we jump to the `.no_multiboot` label if `eax` does not contain the magic value.

In `no_multiboot`, we use the `jmp` (“jump”) instruction to jump to our error function. We could just as well use the `call` instruction, which additionally pushes the return address. But the return address is not needed because `error` never returns. To pass `0` as error code to the `error` function, we move it into `al` before the jump (`error` will read it from there).

🔗CPUID check

[CPUID](https://wiki.osdev.org/CPUID) is a CPU instruction that can be used to get various information about the CPU. But not every processor supports it. CPUID detection is quite laborious, so we just copy a detection function from the [OSDev wiki](https://wiki.osdev.org/Setting_Up_Long_Mode#Detection_of_CPUID):

```asm
check_cpuid:
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. If we can flip it, CPUID is available.

    ; Copy FLAGS in to EAX via stack
    pushfd
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushfd
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the
    ; ID bit back if it was ever flipped).
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit
    ; wasn't flipped, and CPUID isn't supported.
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "1"
    jmp error
```

Basically, the `CPUID` instruction is supported if we can flip some bit in the [FLAGS register](https://en.wikipedia.org/wiki/FLAGS_register). We can't operate on the flags register directly, so we need to load it into some general purpose register such as `eax` first. The only way to do this is to push the `FLAGS` register on the stack through the `pushfd` instruction and then pop it into `eax`. Equally, we write it back through `push ecx` and `popfd`. To flip the bit we use the `xor` instruction to perform an [exclusive OR](https://en.wikipedia.org/wiki/Exclusive_or). Finally we compare the two values and jump to `.no_cpuid` if both are equal (`je` – “jump if equal”). The `.no_cpuid` code just jumps to the `error` function with error code `1`.

Don't worry, you don't need to understand the details.

🔗Long Mode check

Now we can use CPUID to detect whether long mode can be used. I use code from [OSDev](https://wiki.osdev.org/Setting_Up_Long_Mode#x86_or_x86-64) again:

```asm
check_long_mode:
    ; test if extended processor info in available
    mov eax, 0x80000000    ; implicit argument for cpuid
    cpuid                  ; get highest supported argument
    cmp eax, 0x80000001    ; it needs to be at least 0x80000001
    jb .no_long_mode       ; if it's less, the CPU is too old for long mode

    ; use extended info to test if long mode is available
    mov eax, 0x80000001    ; argument for extended processor info
    cpuid                  ; returns various feature bits in ecx and edx
    test edx, 1 << 29      ; test if the LM-bit is set in the D-register
    jz .no_long_mode       ; If it's not set, there is no long mode
    ret
.no_long_mode:
    mov al, "2"
    jmp error
```

Like many low-level things, CPUID is a bit strange. Instead of taking a parameter, the `cpuid` instruction implicitly uses the `eax` register as argument. To test if long mode is available, we need to call `cpuid` with `0x80000001` in `eax`. This loads some information to the `ecx` and `edx` registers. Long mode is supported if the 29th bit in `edx` is set. [Wikipedia](https://en.wikipedia.org/wiki/CPUID#EAX.3D80000001h:_Extended_Processor_Info_and_Feature_Bits) has detailed information.

If you look at the assembly above, you'll probably notice that we call `cpuid` twice. The reason is that the CPUID command started with only a few functions and was extended over time. So old processors may not know the `0x80000001` argument at all. To test if they do, we need to invoke `cpuid` with `0x80000000` in `eax` first. It returns the highest supported parameter value in `eax`. If it's at least `0x80000001`, we can test for long mode as described above. Else the CPU is old and doesn't know what long mode is either. In that case, we directly jump to `.no_long_mode` through the `jb` instruction (“jump if below”).

🔗Putting it together

We just call these check functions right after start:

```asm
global start

section .text
bits 32
start:
    mov esp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    ; print `OK` to screen
    ...
```

When the CPU doesn't support a needed feature, we get an error message with an unique error code. Now we can start the real work.

🔗Paging

*Paging* is a memory management scheme that separates virtual and physical memory. The address space is split into equal sized pages and a page table specifies which virtual page points to which physical page. If you never heard of paging, you might want to look at the paging introduction ([PDF](http://pages.cs.wisc.edu/~remzi/OSTEP/vm-paging.pdf)) of the [Three Easy Pieces](http://pages.cs.wisc.edu/~remzi/OSTEP/) OS book.

In long mode, x86 uses a page size of 4096 bytes and a 4 level page table that consists of:

- the Page-Map Level-4 Table (PML4),
- the Page-Directory Pointer Table (PDP),
- the Page-Directory Table (PD),
- and the Page Table (PT).

As I don't like these names, I will call them P4, P3, P2, and P1 from now on.

Each page table contains 512 entries and one entry is 8 bytes, so they fit exactly in one page (`512*8 = 4096`). To translate a virtual address to a physical address the CPU1 will do the following2:

> Note 1: In the x86 architecture, the page tables are hardware walked, so the CPU will look at the table on its own when it needs a translation. Other architectures, for example MIPS, just throw an exception and let the OS translate the virtual address.

> Note 2: Image source: Wikipedia, with modified font size, page table naming, and removed sign extended bits. The modified file is licensed under the Creative Commons Attribution-Share Alike 3.0 Unported license.

![translation of virtual to physical addresses in 64 bit mode](https://os.phil-opp.com/entering-longmode/X86_Paging_64bit.svg)

1. Get the address of the P4 table from the CR3 register
1. Use bits 39-47 (9 bits) as an index into P4 (2^9 = 512 = number of entries)
1. Use the following 9 bits as an index into P3
1. Use the following 9 bits as an index into P2
1. Use the following 9 bits as an index into P1
1. Use the last 12 bits as page offset (2^12 = 4096 = page size)

But what happens to bits 48-63 of the 64-bit virtual address? Well, they can't be used. The “64-bit” long mode is in fact just a 48-bit mode. The bits 48-63 must be copies of bit 47, so each valid virtual address is still unique. For more information see [Wikipedia](https://en.wikipedia.org/wiki/X86-64#Virtual_address_space_details).

An entry in the P4, P3, P2, and P1 tables consists of the page aligned 52-bit *physical* address of the frame or the next page table and the following bits that can be OR-ed in:

|Bit(s)|Name|Meaning|
|0|present|the page is currently in memory
|1|writable|it's allowed to write to this page
|2|user accessible|if not set, only kernel mode code can access this page
|3|write through caching|writes go directly to memory
|4|disable cache|no cache is used for this page
|5|accessed|the CPU sets this bit when this page is used
|6|dirty|the CPU sets this bit when a write to this page occurs
|7|huge page/null|must be 0 in P1 and P4, creates a 1GiB page in P3, creates a 2MiB page in P2
|8|global|page isn't flushed from caches on address space switch (PGE bit of CR4 register must be set)
|9-11|available|can be used freely by the OS
|52-62|available|can be used freely by the OS
|63|no execute|forbid executing code on this page (the NXE bit in the EFER register must be set)

🔗Set Up Identity Paging

When we switch to long mode, paging will be activated automatically. The CPU will then try to read the instruction at the following address, but this address is now a virtual address. So we need to do *identity mapping*, i.e. map a physical address to the same virtual address.

The `huge page` bit is now very useful to us. It creates a 2MiB (when used in P2) or even a 1GiB page (when used in P3). So we could map the first *gigabytes* of the kernel with only one P4 and one P3 table by using 1GiB pages. Unfortunately 1GiB pages are relatively new feature, for example Intel introduced it 2010 in the [Westmere architecture](https://en.wikipedia.org/wiki/Westmere_(microarchitecture)#Technology). Therefore we will use 2MiB pages instead to make our kernel compatible to older computers, too.

To identity map the first gigabyte of our kernel with 512 2MiB pages, we need one P4, one P3, and one P2 table. Of course we will replace them with finer-grained tables later. But now that we're stuck with assembly, we choose the easiest way.

We can add these two tables at the beginning3 of the `.bss` section:

> Note 3: Page tables need to be page-aligned as the bits 0-11 are used for flags. By putting these tables at the beginning of `.bss`, the linker can just page align the whole section and we don't have unused padding bytes in between.

```asm
...

section .bss
align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
stack_bottom:
    resb 64
stack_top:
```

The `resb` command reserves the specified amount of bytes without initializing them, so the 8KiB don't need to be saved in the executable. The `align 4096` ensures that the page tables are page aligned.

When GRUB creates the `.bss` section in memory, it will initialize it to `0`. So the `p4_table` is already valid (it contains 512 non-present entries) but not very useful. To be able to map 2MiB pages, we need to link P4's first entry to the `p3_table` and P3's first entry to the the `p2_table`:

```asm
set_up_page_tables:
    ; map first P4 entry to P3 table
    mov eax, p3_table
    or eax, 0b11 ; present + writable
    mov [p4_table], eax

    ; map first P3 entry to P2 table
    mov eax, p2_table
    or eax, 0b11 ; present + writable
    mov [p3_table], eax

    ; TODO map each P2 entry to a huge 2MiB page
    ret
```

We just set the present and writable bits (0b11 is a binary number) in the aligned P3 table address and move it to the first 4 bytes of the P4 table. Then we do the same to link the first P3 entry to the p2_table.

Now we need to map P2's first entry to a huge page starting at 0, P2's second entry to a huge page starting at 2MiB, P2's third entry to a huge page starting at 4MiB, and so on. It's time for our first (and only) assembly loop:

```asm
set_up_page_tables:
    ...
    ; map each P2 entry to a huge 2MiB page
    mov ecx, 0         ; counter variable

.map_p2_table:
    ; map ecx-th P2 entry to a huge page that starts at address 2MiB*ecx
    mov eax, 0x200000  ; 2MiB
    mul ecx            ; start address of ecx-th page
    or eax, 0b10000011 ; present + writable + huge
    mov [p2_table + ecx * 8], eax ; map ecx-th entry

    inc ecx            ; increase counter
    cmp ecx, 512       ; if counter == 512, the whole P2 table is mapped
    jne .map_p2_table  ; else map the next entry

    ret
```

Maybe I should first explain how an assembly loop works. We use the ecx register as a counter variable, just like i in a for loop. After mapping the ecx-th entry, we increase ecx by one and jump to .map_p2_table again if it's still smaller than 512.

To map a P2 entry we first calculate the start address of its page in eax: The ecx-th entry needs to be mapped to ecx * 2MiB. We use the mul operation for that, which multiplies eax with the given register and stores the result in eax. Then we set the present, writable, and huge page bits and write it to the P2 entry. The address of the ecx-th entry in P2 is p2_table + ecx * 8, because each entry is 8 bytes large.

Now the first gigabyte (512 * 2MiB) of our kernel is identity mapped and thus accessible through the same physical and virtual addresses.

🔗Enable Paging

To enable paging and enter long mode, we need to do the following:

write the address of the P4 table to the CR3 register (the CPU will look there, see the paging section)
long mode is an extension of Physical Address Extension (PAE), so we need to enable PAE first
Set the long mode bit in the EFER register
Enable Paging
The assembly function looks like this (some boring bit-moving to various registers):

```asm
enable_paging:
    ; load P4 to cr3 register (cpu uses this to access the P4 table)
    mov eax, p4_table
    mov cr3, eax

    ; enable PAE-flag in cr4 (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; set the long mode bit in the EFER MSR (model specific register)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; enable paging in the cr0 register
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret
```

The or eax, 1 << X is a common pattern. It sets the bit X in the eax register (<< is a left shift). Through rdmsr and wrmsr it's possible to read/write to the so-called model specific registers at address ecx (in this case ecx points to the EFER register).

Finally we need to call our new functions in start:

```asm
...
start:
    mov esp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    call set_up_page_tables ; new
    call enable_paging     ; new

    ; print `OK` to screen
    mov dword [0xb8000], 0x2f4b2f4f
    hlt
...
```

To test it we execute make run. If the green OK is still printed, we have successfully enabled paging!

🔗The Global Descriptor Table

After enabling Paging, the processor is in long mode. So we can use 64-bit instructions now, right? Wrong. The processor is still in a 32-bit compatibility submode. To actually execute 64-bit code, we need to set up a new Global Descriptor Table. The Global Descriptor Table (GDT) was used for Segmentation in old operating systems. I won't explain Segmentation but the Three Easy Pieces OS book has good introduction (PDF) again.

Today almost everyone uses Paging instead of Segmentation (and so do we). But on x86, a GDT is always required, even when you're not using Segmentation. GRUB has set up a valid 32-bit GDT for us but now we need to switch to a long mode GDT.

A GDT always starts with a 0-entry and contains an arbitrary number of segment entries afterwards. A 64-bit entry has the following format:

Bit(s)	Name	Meaning
0-41	ignored	ignored in 64-bit mode
42	conforming	the current privilege level can be higher than the specified level for code segments (else it must match exactly)
43	executable	if set, it's a code segment, else it's a data segment
44	descriptor type	should be 1 for code and data segments
45-46	privilege	the ring level: 0 for kernel, 3 for user
47	present	must be 1 for valid selectors
48-52	ignored	ignored in 64-bit mode
53	64-bit	should be set for 64-bit code segments
54	32-bit	must be 0 for 64-bit segments
55-63	ignored	ignored in 64-bit mode
We need one code segment, a data segment is not necessary in 64-bit mode. Code segments have the following bits set: descriptor type, present, executable and the 64-bit flag. Translated to assembly the long mode GDT looks like this:

```asm
section .rodata
gdt64:
    dq 0 ; zero entry
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; code segment
```

We chose the .rodata section here because it's initialized read-only data. The dq command stands for define quad and outputs a 64-bit constant (similar to dw and dd). And the (1<<43) is a bit shift that sets bit 43.

🔗Loading the GDT

To load our new 64-bit GDT, we have to tell the CPU its address and length. We do this by passing the memory location of a special pointer structure to the lgdt (load GDT) instruction. The pointer structure looks like this:

```asm
gdt64:
    dq 0 ; zero entry
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; code segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64
```

The first 2 bytes specify the (GDT length - 1). The $ is a special symbol that is replaced with the current address (it's equal to .pointer in our case). The following 8 bytes specify the GDT address. Labels that start with a point (such as .pointer) are sub-labels of the last label without point. To access them, they must be prefixed with the parent label (e.g., gdt64.pointer).

Now we can load the GDT in start:

```asm
start:
    ...
    call enable_paging

    ; load the 64-bit GDT
    lgdt [gdt64.pointer]

    ; print `OK` to screen
    ...
```

When you still see the green OK, everything went fine and the new GDT is loaded. But we still can't execute 64-bit code: The code selector register cs still has the values from the old GDT. To update it, we need to load it with the GDT offset (in bytes) of the desired segment. In our case the code segment starts at byte 8 of the GDT, but we don't want to hardcode that 8 (in case we modify our GDT later). Instead, we add a .code label to our GDT, that calculates the offset directly from the GDT:

```asm
section .rodata
gdt64:
    dq 0 ; zero entry
.code: equ $ - gdt64 ; new
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; code segment
.pointer:
    ...
```

We can't just use a normal label here, since we need the table offset. We calculate this offset using the current address $ and set the label to this value using equ. Now we can use gdt64.code instead of 8 and this label will still work if we modify the GDT.

In order to finally enter the true 64-bit mode, we need to load cs with gdt64.code. But we can't do it through mov. The only way to reload the code selector is a far jump or a far return. These instructions work like a normal jump/return but change the code selector. We use a far jump to a long mode label:

```asm
global start
extern long_mode_start
...
start:
    ...
    lgdt [gdt64.pointer]

    jmp gdt64.code:long_mode_start
...
```

The actual long_mode_start label is defined as extern, so it's part of another file. The jmp gdt64.code:long_mode_start is the mentioned far jump.

I put the 64-bit code into a new file to separate it from the 32-bit code, thereby we can't call the (now invalid) 32-bit code accidentally. The new file (I named it long_mode_init.asm) looks like this:

```asm
global long_mode_start

section .text
bits 64
long_mode_start:
    ; print `OKAY` to screen
    mov rax, 0x2f592f412f4b2f4f
    mov qword [0xb8000], rax
    hlt
```

You should see a green OKAY on the screen. Some notes on this last step:

As the CPU expects 64-bit instructions now, we use bits 64
We can now use the extended registers. Instead of the 32-bit eax, ebx, etc. we now have the 64-bit rax, rbx, …
and we can write these 64-bit registers directly to memory using mov qword (quad word)
Congratulations! You have successfully wrestled through this CPU configuration and compatibility mode mess :).

🔗One Last Thing

Above, we reloaded the code segment register cs with the new GDT offset. However, the data segment registers ss, ds, es, fs, and gs still contain the data segment offsets of the old GDT. This isn't necessarily bad, since they're ignored by almost all instructions in 64-bit mode. However, there are a few instructions that expect a valid data segment descriptor or the null descriptor in those registers. An example is the the iretq instruction that we'll need in the Returning from Exceptions post.

To avoid future problems, we reload all data segment registers with null:

```asm
long_mode_start:
    ; load 0 into all data segment registers
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; print `OKAY` to screen
    ...
```

🔗What's next?

It's time to finally leave assembly behind and switch to Rust. Rust is a systems language without garbage collections that guarantees memory safety. Through a real type system and many abstractions it feels like a high-level language but can still be low-level enough for OS development. The next post describes the Rust setup.

🔗Footnotes
1
In the x86 architecture, the page tables are hardware walked, so the CPU will look at the table on its own when it needs a translation. Other architectures, for example MIPS, just throw an exception and let the OS translate the virtual address.

2
Image source: Wikipedia, with modified font size, page table naming, and removed sign extended bits. The modified file is licensed under the Creative Commons Attribution-Share Alike 3.0 Unported license.

3
Page tables need to be page-aligned as the bits 0-11 are used for flags. By putting these tables at the beginning of .bss, the linker can just page align the whole section and we don't have unused padding bytes in between.

« A minimal Multiboot Kernel	Set Up Rust »
Comments (Archived)
Daniel•vor 4 Jahren
Hi, thank you for the blog posts, finding them really accessible and interesting.

The test_long_mode function doesn't look quite right:

```asm
test_long_mode:
  mov eax, 0x80000000     ; Set the A-register to 0x80000000.
  cpuid                               ; CPU identification.
  cmp eax, 0x80000001     ; Compare the A-register with 0x80000001.
  jb .no_long_mode           ; It is less, there is no long mode.
  mov eax, 0x80000000     ; Set the A-register to 0x80000000.
  cpuid                               ; CPU identification.
  cmp eax, 0x80000001     ; Compare the A-register with 0x80000001.
  jb .no_long_mode           ; It is less, there is no long mode.
  ret

^ should probaly be (according to your linked OSDEV page):


test_long_mode:
  mov eax, 0x80000000      ; Set the A-register to 0x80000000.
  cpuid                                ; CPU identification.
  cmp eax, 0x80000001      ; Compare the A-register with 0x80000001.
  jb .no_long_mode            ; It is less, there is no long mode.
  mov eax, 0x80000001      ; Set the A-register to 0x80000001.
  cpuid                                ; CPU identification.
  test edx, 1 << 29              ; Test if the LM-bit, which is bit 29, is set in the D-register.
  jz .no_long_mode             ; They aren't, there is no long mode.
  ret
```

Philipp Oppermann•vor 4 Jahren
You're right, thank you! I created an Github issue and will fix it soon: https://github.com/phil-opp...

Daniel Ferguson•vor 4 Jahren
Thank you! For any further issues I run into would you prefer I posted to the github page?

I ran into another snag, at the end of the paging setup section (just before the GDT section) you state:

"To test it we execute make run. If the green OK is still printed, we have successfully enabled paging!"

I'm assuming (based on trying it out) it would not be bootable at that stage, though it may in some way be down to the specifics of my setup or mistakes on my part.

When run with qemu it repeatedly restarts and doesn't reach an 'OK' boot.
Removing the `enable_paging` call allows the OS to boot properly, though the paging will not be set up. Further forwards, once the GDT is implemented, the OS once more boots without a hitch.

I checked out the repo and stripped out the later steps to compensate for any errors I made in copying.

Thanks again for these posts.

Philipp Oppermann•vor 4 Jahren
Post issues wherever you want (and thank you for doing it).

Hmm, I can't reproduce it on my machine. I checked out commit 457a613 (see link below) and it ran without problems. Could you try the code from this commit?

Link to 457a613: https://github.com/phil-opp...

Daniel Ferguson•vor 4 Jahren
Apologies, I did a quick diff against that commit (which runs fine) and found I missed the `align 4096` in `section .bss`. Putting that in fixed it (you did include it in this post), fault is all mine.

Thanks again!

emk1024•vor 4 Jahren
This is fun!

Continuing my saga of trying to get this running under Ubuntu 14.04 LTS on a MacBook Pro, if you find that enabling long paging causes an infinite reboot cycle (triple fault?) in QEMU, then you might want to check your qemu-system-x86_64 version. Version 2.0 will reboot infinitely as soon as you try to turn on paging. Version 2.1.2, however, works fine.

Is this perhaps a problem with huge pages? Would it help to add another feature test?

In order to prevent more debugging fun, I've downloaded and built your blog_os repo, and I can now see it print "Hello world", so it should be smooth sailing from here. :-)

Once again, thank you for a cool series of blog posts! Are there any OS development books that you recommend for ideas on further enhancing this basic system?

Philipp Oppermann•vor 4 Jahren
You're right, support for 1GB pages was introduced in QEMU 2.1 in 2014. Intel CPUs support it since Westmere (2010).

There is indeed a way to test support: CPUID 0x80000001, EDX bit 26. But I'm not quite sure if it's good to rely on such a "new" feature at all... Maybe I change it to use 2MB pages instead...

I opened an issue for it. Thank you very much for the hint!

Edit: Updated the code and article to use 2MiB pages instead of 1GiB pages. It now works on my old PC from 2005 again :).

Philipp Oppermann•vor 4 Jahren
Are there any OS development books that you recommend for ideas on further enhancing this basic system?
Well, there is the Three Easy Pieces book I linked in the post, which gives a theoretical overview over different OS concepts. Then there's the little book about OS development, which is more practical and contains C example code. Of course there are many paid books, too.

Besides books, the OSDev Wiki is also a good resource for many topics. Looking at the source of e.g. Redox can be helpful, too.

For exotical ideas, I really like the concept of Phantom OS and Rust's memory safety might allow something similar… We'll see ;)

Tom Smeding•vor 4 Jahren
There's still some text in the article referring to the gigabyte page, like "Now the first gigabyte of our kernel is identity mapped", but otherwise, immense thanks for this article; even though I'm not going to use Rust, these two articles actually got me up and running in long mode *without* hassle!

Philipp Oppermann•vor 4 Jahren
That's correct, actually. We mapped the first gigabyte through 512 2MiB pages instead of one 1GiB page. So the outcome is the same but the code is more complicated...

But I see that this can cause confusion, so I will clarify it.

Tom Smeding•vor 4 Jahren
Oh of course, silly me :P

3 versteckt
Tobias Schottdorf•vor 4 Jahren
> An entry in the P4, P3, P2, and P1 tables consists of the page aligned 52-bit physical address of the page/next page table and the following bits that can be OR-ed in:

I can't quite make sense of that - so the physical addresses which are available to virtual addressing are only 52bit (instead of all 64bit)? There appear to be 24 flags which can be or'ed in, but wouldn't that necessitate overwriting parts of the physical address (52bit + 22bit > 64bit) of the page/page table?

Philipp Oppermann•vor 4 Jahren
The key is that the physical addresses are page aligned. The last 12 bits are thus guaranteed to be 0 and can be used to store some flags. So there are 24 bits for the various flags and 52-12=40 bits for the aligned physical address.

Nicholas Platt•vor 3 Jahren
I'm confused about this as well. Why say "52-bit physical address" if the address is only 40 bits? Is it because the address is between sets of flags? Meaning, do the table entries really look like this?

+-------+----------------------------------------+-------+
| flags | physical address (frame or next table) | flags |
+-------+----------------------------------------+-------+
 63      51                                       11     0
Can you check my understanding:

* Virtual addresses are effectively 48 bits:
    * Highest 16 bits are sign extension of 48th bit
    * Next 36 bits are used to navigate the paging tables
    * Lowest 12 bits are used as offset from physical address
      found in P1

* Physical addresses are effectively 40 bits and page aligned

* Paging table entries are 64 bits:
    * Highest 12 bits are flags
    * Next 40 bits are the physical address of a table or frame
    * Lowest 12 bits are flags
Thus physical addresses identify the start of each aligned frame, and virtual addresses identify the location within the frame.

Philipp Oppermann•vor 3 Jahren
The physical address is 52 bits. It is possible to address up to 2^52 bytes of memory with it. Operating systems without paging (e.g. MS-DOS) directly use the physical address to access memory. And so do we before we enable paging.

As soon as we enable paging, the CPU uses the memory management unit (MMU) to translate used addresses (“virtual addresses”) to the real memory addresses. These virtual addresses are effectively 48 bits on x86_64 and behave exactly as you stated.

So why are only 40 physical address bits stored in the page table? The reason is that the physical memory is split into page sized chunks, which are called frames. The first frame starts at physical address 0, the second frame at physical address 4096, and so on. Thus the physical address of a frame is always page aligned. There are still non-page-aligned physical addresses but they can't be the start of a frame.

So the lowest 12 bits of a valid physical frame address are always 0. We don't need to store anything if we know that it is always 0. Thus these bits can be used to store useful information instead (flags in our case).

I hope this helps in clearing up your confusion.

Nicholas Platt•vor 3 Jahren
Thanks, this has indeed become more clear as I've worked with it. I wrote (and just revised due to better understanding) a detailed comment and that helped nail it down for me.

In case it's not clear to anyone else, the reason the lower bits are always 0 is because 4096 = 0x1000.

Another question then: since we're aligning on 2mib pages here (0x200000), can we access the extra few bits (21 vs 12)?

I'll try this myself once I'm allocating pages.

Edit:
It seems like this idea works. I added the following lines after the paging table setup and didn't encounter any processor exceptions:

; try writing within reserved address space,
; in a middle entry of P4
mov eax, (1 << 31)
or [p4_table + (256*8)], eax
I guess this works, just be sure you're acting on a 2mib page and not a 4kib page.

Philipp Oppermann•vor 3 Jahren
That's an interesting question! The AMD manual says no in section 5.3.4 in Figure 5-25 on page 135. The bits between 13 and 20 are marked as “Reserved, must be zero”. So it seems like a general protection fault occurs then.

Your example works because you only set a bit of a non-present page. AFAIK all bits of non-present pages are available to the OS (except the present bit). If you want to test it, you can set a bit between 13 and 20 in the currently used P2 table. The P3 and P4 table entries still need 40bits for storing the physical address of the next table since page tables only need to be 4KiB aligned.

Ahmed Charles•vor 4 Jahren
You should probably mention that setting bit 16 in cr0 turns on write protection for read only pages, even in kernel mode.

Philipp Oppermann•vor 4 Jahren
Good catch! I copied the code from my experimental kernel and it seems like I have missed that… I'm not quite sure if I should keep and explain it, or just remove it. What do you think?

I opened an issue for this.

Wink Saville•vor 3 Jahren
Philipp,

Just an FYI, In my baremetal-x86_64 repo I ported your boot.asm to boot.gas.S so I could use the code with gnu Assembler.

Philipp Oppermann•vor 3 Jahren
Nice! You are porting it to C?

Wink Saville•vor 3 Jahren
Yes I'm using boot to launch my C based system, your code was the best and most straight forward code to get to long mode that I've seen. I found your code though Eric Kidd's posts to the rust mailing list on the interrupt issues, and I'm glad I'm not going to have to solve that problem yet again :)

Philipp Oppermann•vor 3 Jahren
Thanks! I'm glad that it has helped :)

anula•vor 3 Jahren
I have an interesting problem, that probably has something to do with alignment (as usual while dealing with assembly), though I can't say for sure.
I tried to run the code that does all the checks, but with no paging yet (so prior to "Paging" header). Unfortunately, it always gets into some kind of loop, sometimes qemu throws an exception:
`qemu: fatal: Trying to execute code outside RAM or ROM at 0x000000002b100044`
So it probably tries to execute some random code.

If I delete call to check_long_mode, everything works properly, and green OK is printed to the screen. I don't even need to delete the whole call, it is enough to put `ret` after `test edx, 1 << 29` so it seems as if the jump to error code (`jz .no_long_mode`) was somehow to blame.

During the course of debugging, I added a small function, almost identical to `error` and discovered that just adding the function makes the error go away.
Here are both my codes: https://gist.github.com/anu...
The first one (boot.asm) enters the strange loop (executing random instructions?) on my laptop, the second one (boot2.asm) executes properly. And the only difference is addition of some code that is never called anyway.

Any ideas what may cause it?

EDIT:
Aligning stack to 4096 (bss is in my code above text section) also seems to solve the issue. Still, I don't really understand why is this happening. I thought that x86 doesn't need instructions to be aligned to anything specific?

Philipp Oppermann•vor 3 Jahren
That was an interesting debugging session :D

I tried every debugging trick I knew, read the manual entries for all involved instructions, and even tried to use GDB. But I could not find the bug.

Then I gave up and just looked at the source code in the repo and created a diff to your code. And the problem was surprisingly simple:

You swapped `stack_bottom` and `stack_top`.

But this small change causes big problems. Every `push` or `call` instruction overwrites some bits of the `.text` section below. The last function in the source file and thus the last function in the `.text` section is `check_long_mode`. If you add something behind it, e.g. another error function, it is no longer overwritten and works again.

I think the counter-intuitive thing is that stuff further down in the source file ends up further up in memory. And the stack grows downwards to make it even more confusing. Maybe we should add a small note in the text, why `stack_bottom` needs to be _above_ `stack_top` in the file?

anula•vor 3 Jahren
Uh, that is an.. embarrassing error. I checked all registers twice (easy to mistake eax with ecx) but somehow never thought to check that... I guess that when you see top above bottom in code you unconsciously decide that it is ok.

About the note - it would probably make sense, maybe it will make someone to check their code twice, and surely will be a good reminder for people that have little experience with low level things like that.

Thanks very much for the help - I guess it would take me a lot of time later to debug it, when it would start to mysteriously fall after I add another function call in Rust.

Philipp Oppermann•vor 3 Jahren
Not embarrassing at all, just hard to debug!

I created an issue for the note, but it will take a while since I'm short on time right now. If you like, feel free to send a PR.

Wink Saville•vor 3 Jahren
Phillipp,

Previously I mentioned I'm using a derivative of your boot.S code to boot a C kernel. Things are going pretty good so far, but today I wanted to try to get interrupts going and have run into a brick wall.

I've simplified my test program to something to something very simple. All that happens is boot code jumps to the C code which enables interrupts and loops for a short period of time and then exits. There should be no interrupt sources so I'd expect this to run for as long as I'd like and then exit. And it does If the loop time is very short, but if I lengthen the loop it stops prematurely.

In a more sophisticated version of my program I initialize the Interrupt Descriptor Table and use the APIC to generate a one-shot timer interrupt. Here too, all is well if the delay is short, but when I lengthen the delay I get a Double Fault interrupt!

It almost feels like there is a watchdog timer or .......

Any suggestions welcome.

Thanks,

Wink

Philipp Oppermann•vor 3 Jahren
A double fault occurs when you don't handle an exception/interrupt or your exception handler causes another exception. Do you enable interrupts (sti) or do you just catch cpu exceptions? Maybe you forgot to handle the interrupts from the hardware timer? But it's difficult to help without the actual code…

Wink Saville•vor 3 Jahren
Agreed, and I see that in my more sophisticated program, the question is what is it that I'm doing wrong. I believe I've setup the Interrupt Descriptor Table to handle all interrupts, i.e. I have an array of 256 interrupt gates. That program is here (https://github.com/winksaville/sadie but its too complicated to debug and I haven't yet checked in my non-working APIC timer code. But with that code I'm able to do software interrupts and also when my APIC timer code fires an interrupt fast enough it does work. So it would seem I've done most of the initialization "properly". Note, I'm also compiling my code with -mno-red-zone so that shouldn't be the problem.

So my debug strategy in situations such as this is to simplify. So the first thing was to just enable interrupts and doing nothing that should cause an interrupt to occur and then delay awhile in the code and see what happens. But, sure enough I'm still getting a double fault. Of course according to the documentation in the Intel SDM Volume 3 section 6.15 "Interrupt 8--Double Fault Exception (#DF)" the error code is 0 and CS EIP registers are undefined :(

Anyway, I then simplified to as simple as I can get. I modified your boot.asm program adding the code below the esp initialization that output's character to the VGA display.


start:
  mov esp, stack_top

  ; Save registers
  push edx
  push ecx
  push ebx
  push eax

  ; Enable interrupts
  ;sti

  ; Initialize edx to vga buffer ah attribute, al ch
  mov edx, 0xb8000
  mov ax, 0x0f60

  ; ebx number of loops
  mov ebx,10000

.loop:

  ; Output next character and attribute
  mov word [edx], ax

  ; Increment to next character with wrap
  inc al
  cmp al, 0x7f
  jne .nextloc
  mov al,60

  ; Next location with wrap
.nextloc:
  add edx, 2
  and edx,0x7ff
  or  edx,0xb8000

  ; Delay
  mov ecx,0x2000
.delay:
  loop .delay

  ; Continue looping until ebx is 0
  dec ebx
  jnz .loop

  ; Disable interrupts
  cli

  ; Restore registers
  pop  eax
  pop  ebx
  pop  ecx
  pop  edx
Here is a github repo: (https://github.com/winksaville/baremetal-po-x86_64/tree/test_enable_interrupts). If you add the above code to your boot.asm it will print 10,000 characters to the VGA display and then continue with the normal code paths. If the "sti" instruction is commented out, as it is above, then all is well. But if I uncomment the "sti" thus enabling interrupts then it fails.

I anticipated that enabling interrupts would succeed as I wouldn't expect any interrupts because the hardware is in a state where no interrupts should be generated. Or if grub or the BIOS is using interrupts then I'd expect things to also be OK.

Obviously I'm wrong and I'd hope you'd be able to suggest where my flaw is.

Philipp Oppermann•vor 3 Jahren
Thanks for the overview and the simplified example! I haven't had the time to look at it in detail, but the problem in your simplified example could be the Programmable Interval timer. From the “Outputs” section:

The output from PIT channel 0 is connected to the PIC chip, so that it generates an "IRQ 0". Typically during boot the BIOS sets channel 0 with a count of 65535 or 0 (which translates to 65536), which gives an output frequency of 18.2065 Hz (or an IRQ every 54.9254 ms).
So it seems like the BIOS turns it on by default so that it causes an interrupts every ~55ms. This causes a double fault, since there is no interrupt handler for IRQ 0.

Wink Saville•vor 3 Jahren
Philipp, you were correct, the PIT was the culprit causing the "Double Fault". Although it turns out the PIT is actually generating an Interrupt 8 so its not really a Double Fault it just a PIT interrupt.

My short term solution is to add a pit_isr as interrupt 8 handler and at the end of pit_isr send an EOI to the PIT using outb(0x20, 0x20). I also needed to issue a APIC EOI for my apic_timer_isr and I cleaned up the initialization. So now my system is cleanly handling these interrupts at least.

For the PIT I really want to disable it and I'd like to suggest disabling the PIT be part of boot.asm so that my simple sti, delay, cli test works. If/when I figure that out I'll let you know. Oh, and if know how to disalbe the PIT please let me know.

Thanks again for your help!

Wink Saville•vor 3 Jahren
Here is a solution. There doesn't seem to be a way to disable the PIT, but you can disable all IRQ's from the PIC, adding the following code to my test_enable_interrupts branch allows the code to work even with the enabling interrupts:

```
; Disable PIC interrupts so we don't get interrupts if the PIC
; was being used by grub or BIOS. See Disabling section of
; https://wiki.osdev.org/PIC. If the application wants to use devices
; connected to the PIC, such at the PIT, it will probably want
; to remap the PIC interrupts to be above 0 .. 31 which are
; used or reserved by Intel. See the Initialisation section of
; the same page for the PIC_remap subroutine.

mov al,0xff
out 0xa1, al
out 0x21, al
```

Thanks again for your help.

Nicholas Platt•vor 3 Jahren
To identity map the first gigabyte of our kernel with 512 2MiB pages, we need one P4, one P3, and one P2 table.
Why don't we need to set up a P1 table? We don't even reserve the space for one since there's no p1_table label in the .bss. Is the CPU able to read the paging tables such that it knows to stop translating once it reaches an entry in P2 marked "huge"? What happens to bits 12-20 of the virtual address?

Don Rowe•vor 3 Jahren
Hi, Philipp! Thanks so much for creating this for us--it's been very fun to go from 0-OKAY with the ASM here, and I can't wait to get to the Rust portion (which is what drew me to this project in the first place. I'm a little confused, though, about the 4-level paging structure. Is there exactly one each of P2, P3, and P4, and then 512 different P1's that each point to various 4K physical pages?

Philipp Oppermann•vor 3 Jahren
Thanks!

There is always exactly one P4. For each P4 entry, there is a P3. For each P3 entry, there is a P2. And for each P2 entry, there is a P1. Each entry of the P1 then points to a physical memory page.

So there is one P4 table, 1…512 P3 tables, 1…(512*512) P2 tables, and 1…(512*512*512) P1 tables. (And 1…(512*512*512*512) mapped 4k pages. 512^4 * 4k = 256TiB = 2^48 bytes is the maximum amount of addressable virtual memory.)

If we wanted to identity map the first 2MiB, it would require 512 4k pages and thus exactly 512 P1 entries. Every page table has 512 entries, so we need exactly one P1 (and one P2, P3, P4).

If we wanted to identity map the first 513 4k pages, we would need another P1 entry. Our first P1 is full, so we create another P1. Its first entry points to the 513th 4k page and the other entries are empty. Now we map the second P2 entry (which is currently empty) to the P1 table.

In our case, we want to identity map the first 512*2MiB. This requires 512*512 4k pages and thus 512 P1 tables. Fortunately, there is a useful hardware feature: huge pages. A huge page is 2MiB instead of 4k and is mapped directly by the P2 (so we completely skip the P1 table). This allows us to avoid the 512 P4 tables. Instead we map the 512P2 entries to huge pages.

The big advantage of a multilevel page table is that we don't need to create the page tables / page table entries for memory areas we don't use. In contrast, a single level page table would need 68719476736 entries to address the same amount of virtual memory. So the page table alone would need 68719476736*8=512GiB memory, which is much more than the total amount of RAM in a consumer PC.

Don Rowe•vor 3 Jahren
Ah, I understand! Thank you.

Lonami•vor 2 Jahren
So excited to get started with the next chapter!! ^·^

lightning1141•vor 2 Jahren
If someone run the os get a check_long_mode error, try run qemu with this:

-cpu kvm64
Ps: Thanks Phil. This book is really helpful.

Frank Afriat•vor 2 Jahren
Thank you for the very clear blog and explanations.
Just a remark, would be clearer to add in the Paging section the meaning of bits 12-31 containing the physical address of the next P or the physical address.

What I don't understand is why P1 is not used and how the CPU know that there is no P1 and we link directly to the physical page ? It is also the role of the huge bit ? And also for 2 MB how is defined the offset ?

Philipp Oppermann•vor 2 Jahren
Thanks!

We don't use a P1 because it would be cumbersome to set up 512 P1 tables in assembly. Instead, we set the huge bit in the P2 entries, which signals to the CPU that the entry directly points to the physical start address of a 2MiB page frame. This address has to be 2MiB aligned, so bits 0-23 have to be zero. When translating an address, these bits specify the offset in the 2MiB page.

Just a remark, would be clearer to add in the Paging section the meaning of bits 12-31 containing the physical address of the next P or the physical address.
Thanks for the suggestion! I opened #314 to track it.

Eran Sabala•vor 2 Jahren
Very nice post.. Thanks for the effort (:

Anatol Pomozov•vor 2 Jahren
Thanks for the blogpost series. It is very useful for those who develops its own x86 operation system.

In my own project (unrelated to this Rust OS) I try to initialize segment registers with null descriptor like you do 'mov XX, 0'. Setting ds/es/fs/gs works fine, but when I try to set SS with null descriptor I get a crash. Looking at the documentation 'Intel 64 developers manual Vol. 2B 4-37' I see that 'MOV SS, 0' is prohibited and causes #GP(0).

I wonder why 'MOV SS, 0' works for you...

Stefan Junker•vor 2 Jahren
I'm not certain why there is a limitation, but in the blog post the
data is written to `ax` first and then loaded from `ax` to `ss`.

Anatol Pomozov•vor 2 Jahren
it seems that "mov" to segment register requires a general purpose register as source. In my code I also use 'movw %ax, %ds' I just made it a bit easier to read by using const value.

Anyway it is unrelated to my original question. Writing null descriptor to all segment registers (except %ss) is fine. Documentation also states that null descriptor cannot be used for the stack segment.

Philipp Oppermann•vor 2 Jahren
Hmm, do you have a link to the documentation? I can't find anything relevant on page 4-37 in this document: https://www.intel.com/Assets/en_US/PDF/manual/253667.pdf

The AMD64 manual states on page 253:

Normally, an IRET that pops a null selector into the SS register causes a general-protection exception (#GP) to occur. However, in long mode, the null selector indicates the existence of nested interrupt handlers and/or privileged software in 64-bit mode. Long mode allows an IRET to pop a null selector into SS from the stack under the following conditions:
• The target mode is 64-bit mode.
• The target CPL<3.
In this case, the processor does not load an SS descriptor, and the null selector is loaded into SS without causing a #GP exception
Maybe I interpreted that wrong, though…

Anatol Pomozov•vor 2 Jahren
Hi Philipp, your link points to 6 years old Intel doc, here is the same but much more recent https://software.intel.com/...

Scroll to 'MOV' instruction, page 4-37. There is a block algorithm for MOV that says

IF segment selector is NULL
THEN #GP(0); FI;

I believe I hit this issue.

Philipp Oppermann•vor 2 Jahren
Thanks for the link!

Hmm, the listing is preceded by “Loading a segment register while in protected mode results in special checks and actions, as described in the following listing.” (emphasis mine)

Under “64-Bit Mode Exceptions” (page 4-39) there are only 3 cases for a #GP(0):

If the memory address is in a non-canonical form.
If an attempt is made to load SS register with NULL segment selector when CPL = 3.
If an attempt is made to load SS register with NULL segment selector when CPL < 3 and CPL ≠ RPL.
I see no reason why we should hit any of these…

1 versteckt
Anatol Pomozov•letztes Jahr
I have one more question. In your example you do a jump to long mode. As far as I know long 'call' can be used here as well. In fact call works in KVM and vmware but for some reason the operation crashes with #GP error. Do you know why it can be?

Philipp Oppermann•letztes Jahr
You need to do a so-called far jump, which updates the code segment. I'm not sure right now if a far call is supported in long mode. Either way, returning to 32-bit code might not be a good idea anyway, since the opcodes might be interpreted differently.

Tomáš Král•letztes Jahr
Hi, I can't get the boot.asm file to assemble because it gives me this error: src/arch/x86_64/boot.asm:(.text+0x4a): undefined reference to `long_mode_start'

Philipp Oppermann•letztes Jahr
Does the error occur when invoking nasm? Then you need to add extern long_mode_start somewhere inside the boot.asm (e.g. at the beginning). If it occurs while invoking ld, make sure that the long_mode_init.asm file is assembled and passed to ld (and it should of course define a global long_mode_start: label).

Tomáš Král•letztes Jahr
Yep, I was missing the extern long_mode_start, thank you ! :)

Tomáš Král•letztes Jahr
Hi, I want to ask something about assembly. Why do I have to move p4_table to eax before moving eax into cr3 ? Why can't I move p4_table directly into cr3 ?

Philipp Oppermann•letztes Jahr
Because the CR3 register can only be loaded from a register. So you have to load the p4_table address into a register first.

fsb•letztes Jahr
Hi,

out of curiosity: Does it make sense to keep the 32bit print instructions as "dead code" in the program? It can never be reached, right?

; print `OK` to screen
mov dword [0xb8000], 0x2f4b2f4f
hlt
Philipp Oppermann•letztes Jahr
Yeah, it should be unreachable after entering long mode (we would need to enter protected mode again). So it does not make much sense to keep it.

David•letztes Jahr
You should probably mention that the "set_up_page_tables" function works with 32 bit addresses and 32-bit (4-byte) PTE/PDE entries, each holding the 20-bit, page-aligned, physical address of the next data structure (plus 12 bits of 0s, since each level is page aligned). Readers may be confused from the preceding explication of 64-bit PTEs, which are not used there (certainly I was).

Philipp Oppermann•letztes Jahr
We do use 8 byte PTEs with 64 bit addresses, but we only write the bottom 32 bits, since the higher 32 bits are zero.

David•letztes Jahr
I guess that what's unclear to me is why you say that each PTE entry contains the 52-bit physical address of the next frame/entry but in the table it looks like only bits 12-51 (40 bits) are used for that.

Philipp Oppermann•letztes Jahr
Oh, that's because page tables are always page aligned, i.e. bits 0-12 have to be always zero. The hardware manufacturers utilized that fact to use those bits for the flags instead.

David•letztes Jahr
Makes sense, thanks.

Shane•vor 9 Monaten
Is this rust or assembly? I've never used rust before although I've used assembly.

Philipp Oppermann•vor 9 Monaten
This post is still in assembly. The next post is rust.

DaeMoohn•vor 9 Monaten
Hi,

I'm trying to follow your steps while I'm trying to build a kernel in Rust. I have some questions at this point:

you skipped the A20 gate checking altogether. Is that an error or you consider it so arcane that is just not needed? On my emulators I'm trying to activate it and my machine just goes haywire.

why do you map 1 GB for your kernel here? A smaller amount would surely be as suitable as 1 GB

some other sites/blogs/resources I read on the internet warn us to map the kernel to a higher area due to linker issues

I haven't read in detail the next posts, but I've seen you remap the kernel somewhere in the future. Is that because what you are doing here is just a quick way to go to long mode, and you actually do it as needed in Rust?

On OSDev they also mention something about a P5 coming in the future.

Thanks, very informative reading!

© 2017. All rights reserved. Contact
