# Transitioning to Long Mode

Summry from https://intermezzos.github.io/book/first-edition/paging.html

## Paging

- address space: The full 64-bit address space has 2^64 addresses
- physical addresses: physical RAM address
- virtual addresses: address anywhere inside of the full address space

Software uses the virtual addresses, and the hardware uses physical addresses.

virtual memory: helping us always be able to map a 64-bit number to a real place in physical memory, ***and more***.

Mapping each individual address would be extremely inefficient; we would need to keep track of literally every memory address and where it points to. Instead, we split up memory into chunks, also called ‘pages’, and then map each page to an equal sized chunk of physical memory.

Paging is actually implemented by a part of the CPU called an ‘MMU’, for ‘memory management unit’. The MMU will translate virtual addresses into their respective physical addresses automatically; we can write all of our software with virtual addresses only. The MMU does this with a data structure called a ‘page table’. As an operating system, we load up the page table with a certain data structure, and then tell the CPU to enable paging.

Setting up paging is required before transition to long mode.

In long mode, the page table is four levels deep (there is 5-level now), and each page is 4096 bytes in size.
- the Page-Map Level-4 Table (PML4),
- the Page-Directory Pointer Table (PDP),
- the Page-Directory Table (PD),
- and the Page Table (PT).

The number of tables we need depends on how big we make each page. The bigger each page, the fewer pages fit into the virtual address space, so the fewer tables we need.

Creating page table entries (2MiB pages)

```asm
section .bss

align 4096

p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
```

`bss` stands for ‘block started by symbol’, and was introduced in the 1950s. The name doesn’t make much sense anymore, but the reason we use it is because of its behavior: entries in the bss section are automatically set to zero by the linker. This is useful, as we only want certain bits set to 1, and most of them set to zero.

The `resb` directive reserves bytes; we want to reserve space for each entry.

The `align` directive makes sure that we’ve aligned our tables properly. The idea is that the addresses here will be set to a multiple of 4096, hence ‘aligned’ to 4096 byte chunks.

??? After this has been added, we have a single valid entry for each level. However, because our page four entry is all zeroes, we have no valid pages.

Pointing the entries at each other

```asm
global start

section .text
bits 32
start:
    ; Point the first entry of the level 4 page table
    ; to the first entry in the p3 table
    mov eax, p3_table
    or eax, 0b11
    mov dword [p4_table + 0], eax
    
    ; Point the first entry of the level 3 page table
    ; to the first entry in the p2 table
    mov eax, p2_table
    or eax, 0b11
    mov dword [p3_table + 0], eax
```

We get the first third-level page table, set bits 0 and 1 to 1 (`or eax, ob11`) without other bits. Why? Each entry in a page table contains an address, but it also contains metadata about that page. The first two bits are the ‘present bit’ and the ‘writable bit’. By setting the first bit, we say “this page is currently in memory,” and by setting the second, we say “this page is allowed to be written to.”

> ??? You might be wondering, if the entry in the page table is an address, how can we use some of the bits of that address to store metadata without messing up the address? Remember that we used the align directive to make sure that the page tables all have addresses that are multiples of 4096. That means that the CPU can assume that the first 12 bits of all the addresses are zero. If they're always implicitly zero, we can use them to store metadata without changing the address.

Next we'll set up the level two page table to have valid references to pages.

```asm
    ; point each page table level two entry to a page
    mov ecx, 0         ; counter variable
.map_p2_table:
    mov eax, 0x200000  ; 2MiB, 2,097,152, 2MiB page size
    mul ecx            ; eax=eax*ecx: location of next page
    or eax, 0b10000011 ; bit8: huge page, otherwise, 4KiB page
    mov [p2_table + ecx * 8], eax

    inc ecx
    cmp ecx, 512    ; 512 entries, 512*8 = 4K bytes per page table
    jne .map_p2_table
```

Enable paging

Now that we have a valid page table, we need to inform the hardware about it. Here’s the steps we need to take:
- We have to put the address of the level four page table in a special register
- enable ‘physical address extension’
- set the ‘long mode bit’
- enable paging

```asm
    ; move page table address to cr3
    mov eax, p4_table
    mov cr3, eax
    
    ; enable PAE
    mov eax, cr4
    or eax, 1 << 5   ; set bit 5 of cr4
    mov cr4, eax
    
    ; set the long mode bit
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    
    ; enable paging
    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 16
    mov cr0, eax
```

`cr3` is a special register, called a ‘control register’. The `cr` registers are special: they control how the CPU actually works. `cr3` register needs to hold the location of the page table.

The rdmsr and wrmsr instructions read and write to a ‘model specific register’, hence msr.

So, *technically* after paging is enabled, we are in long mode. But we’re not in real long mode; we’re in a special compatibility mode. To get to real long mode, we need a data structure called a ‘global descriptor table’.


## Setting up a GDT

We’re currently in long mode, but not ‘real’ long mode. We need to go from this ‘compatibility mode’ to honest-to-goodness long mode. To do this, we need to set up a ‘global descriptor table’.

This table, also known as a GDT, is kind of vestigial. The GDT is used for a style of memory handling called ‘segmentation’, which is in contrast to the paging model that we just set up. Even though we’re not using segmentation, however, we’re still required to have a valid GDT. Such is life.

```asm
section .rodata
gdt64:
    dq 0
.code: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
.data: equ $ - gdt64
    dq (1<<44) | (1<<47) | (1<<41)
.pointer:
    dw .pointer - gdt64 - 1
    dq gdt64
```

We have a new section: rodata. This stands for ‘read only data’. `dq` is ‘define quad-word’, a 64-bit value

`.code` tells the assembler to scope this label under the last label that appeared, so we'll say `gdt64.code` rather than just `code`. 

`equ $ - gdt64`: we don't reference the entry by its address, we reference it by an offset. `$` is the current position. So we're subtracting the address of gdt64 from the current position. Conveniently, that's the offset number we need for later: how far is this segment past the start of the GDT.

The code segment: Set the 44th, 47th, 41st, 43rd, and 53rd bit.
- 44: ‘descriptor type’: This has to be 1 for code and data segments
- 47: ‘present’: This is set to 1 if the entry is valid
- 41: ‘read/write’: If this is a code segment, 1 means that it’s readable
- 43: ‘executable’: Set to 1 for code segments
- 53: ‘64-bit’: if this is a 64-bit GDT, this should be set

The data segment: Set the 44th, 47th, 41st bit.
- 41: ‘read/write’: If this is a data segment, 1 means that it’s writable

```asm
lgdt [gdt64.pointer]
```

GDTR: *32(64)-bit Linear Base Address* + *16-bit Table Limit*


We'll use `lgdt` to load GDT to gdtr (register). `lddt` takes 32+64 bitswhich is where `.pointer` is.

## Jumping headlong into long mode

Our last task is to update several special registers called 'segment registers'. Again, we're not using segmentation, but things won't work unless we set them properly. Once we do, we'll be out of the compatibility mode and into long mode for real.

```asm
; update selectors
mov ax, gdt64.data
mov ss, ax
mov ds, ax
mov es, ax
```

Here's a short rundown of these registers:
- `ax`: This isn't a segment register. It's a sixteen-bit register. Remember 'eax' from our loop accumulator? The 'e' was for 'extended', and it's the thirty-two bit version of the ax register. The segment registers are sixteen bit values, so we start off by putting the data part of our GDT into it, to load into all of the segment registers.
- `ss`: The 'stack segment' register. We don't even have a stack yet, that's how little we're using this. Still needs to be set.
- `ds`: the 'data segment' register. This points to the data segment of our GDT, which is conveniently what we loaded into ax.
- `es`: an 'extra segment' register. Not used, still needs to be set.

There's one more register which needs to be updated, however: the code segment register, `cs`. Should be an easy `mov cs, ax`, right? Wrong! It's not that easy. Unfortunately, we can't modify the code segment register ourselves, or bad things can happen. But we need to change it. So what do we do?

The way to change `cs` is to execute what's called a 'far jump'. Have you heard of goto? A jump is just like that; we used one to do our little loop when setting up paging. A 'far jump' is a jump instruction that goes really far. That's a little bit simplistic, but the full technical details involve stuff about memory segmentation, which again, we're not using, so going into them doesn't matter.

```asm
; jump to long mode!
jmp gdt64.code:long_mode_start
```

`foo:bar` syntax is what makes this a long jump. When we execute this, it will then update the code selector register with our entry in the GDT!

```asm
section .text
bits 64
long_mode_start:
    mov rax, 0x2f592f412f4b2f4f   ; rax: 64bit register
    mov qword [0xb8000], rax   ;qword: quad-word, 64bit; w/dw/qw-16/32/64

    hlt
```
