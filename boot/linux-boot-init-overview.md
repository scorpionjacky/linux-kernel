# Boot Flow (x86), 5.8.x

ref:
- [linux_note](https://github.com/jindian/linux_note) by [jindian](https://github.com/jindian?tab=repositories) <- [@gitbooks.io](https://start_fjin.gitbooks.io/linux-note/content/)
- [Linux Insides](https://github.com/0xAX/linux-insides) by 0xax  <- [@gitbooks.io](https://0xax.gitbooks.io/linux-insides/content/Booting/)
- [Linux boot protocol](https://github.com/torvalds/linux/blob/master/Documentation/x86/boot.rst)
- GNU Make, HTML manual: [Single-Page](https://www.gnu.org/software/make/manual/make.html) / [Multi-Page](https://www.gnu.org/software/make/manual/html_node/index.html) / kbuild [makefile](https://www.kernel.org/doc/html/latest/kbuild/makefiles.html)
- [Linux-5.6.6 内核引导](https://mp.weixin.qq.com/s/HoxloDfe0wVHZLzEuUqX8Q)
- 知乎
  - [Linux内核启动](https://www.zhihu.com/column/c_1122808218635739136) by King Wag, 14 articles
    - [Layout of bzImage](https://zhuanlan.zhihu.com/p/73077391)
  - [MIT6.828-神级OS课程](https://zhuanlan.zhihu.com/p/74028717)
  - https://zhuanlan.zhihu.com/p/161723710 / https://zhuanlan.zhihu.com/p/108084783
- https://en.wikipedia.org/wiki/Vmlinux
- https://www.cnblogs.com/alantu2018/

## modern kernel with boot manager

Memory map after Linux Kernel is loaded into memory by Grub:
```
          ~                        ~
          |  Protected-mode kernel |
  100000  +------------------------+
          |  I/O memory hole       |
  0A0000  +------------------------+
          |  Reserved for BIOS     |      Leave as much as possible unused
          ~                        ~
          |  Command line          |      (Can also be below the X+10000 mark)
  X+10000 +------------------------+
          |  Stack/heap            |      For use by the kernel real-mode code.
  X+08000 +------------------------+
          |  Kernel setup          |      The kernel real-mode code.
          |  Kernel boot sector    |      The kernel legacy boot sector.
  X       +------------------------+
          |  Boot loader           |      <- Boot sector entry point 0000:7C00
  001000  +------------------------+
          |  Reserved for MBR/BIOS |
  000800  +------------------------+
          |  Typically used by MBR |
  000600  +------------------------+
          |  BIOS use only         |
  000000  +------------------------+
```
... where the address X is as low as the design of the boot loader permits.

[arch/x86/boot/header.S](https://github.com/torvalds/linux/blob/master/arch/x86/boot/header.S) ([@elixir](https://elixir.bootlin.com/linux/latest/source/arch/x86/boot/header.S))
- First 512 bytes (formerly as MBR) display error message to use a boot manager
- Followed by [linux boot protocol](https://www.kernel.org/doc/Documentation/x86/boot.txt) and various Linux data structures
    - kernel setup entry point: [`.globl _start`](https://github.com/torvalds/linux/blob/c9c9e6a49f8998e9334507378c08cc16cb3ec0e5/arch/x86/boot/header.S#L294)
- [`start_of_setup`](https://github.com/torvalds/linux/blob/c9c9e6a49f8998e9334507378c08cc16cb3ec0e5/arch/x86/boot/header.S#L584) (`.section ".entrytext", "ax"`)
    - Make sure that all segment register values are equal
    - Set up a correct stack, if needed
    - Set up [bss](https://en.wikipedia.org/wiki/.bss)
    - Jump to the C code in [`arch/x86/boot/main.c`](https://github.com/torvalds/linux/blob/master/arch/x86/boot/main.c)

Pay attention to the data parts, and section names which are used in [arch/x86/boot/setup.ld](https://github.com/torvalds/linux/blob/master/arch/x86/boot/setup.ld).

More detail at [linux-insides](https://0xax.gitbooks.io/linux-insides/content/Booting/linux-bootstrap-1.html)

[arch/x86/boot/main.c](https://github.com/torvalds/linux/blob/171d4ff79f965c1f164705ef0aaea102a6ad238b/arch/x86/boot/main.c#L134) ([@elixir](https://elixir.bootlin.com/linux/latest/source/arch/x86/boot/main.c))
- copy_boot_params(); /* First, copy the boot header into the "zeropage", hdr (header.S) -> boot_params' struct setup_header hdr*/
- console_init();  /* Initialize the early-boot console */
- init_heap(); /* End of heap check: stack_end = max(esp - STACK_SIZE, heap_end) */
- validate_cpu() /* Make sure we have all the proper CPU support */
- set_bios_mode(); /* Tell the BIOS what CPU mode we intend to run in. */
- detect_memory(); /* Detect memory layout, Int0x15 #0xe820, save to e820entry array: start_addr, size, type */
- keyboard_init(); /* Set keyboard repeat rate (why?) and query the lock flags */
- query_ist(); /* Query Intel SpeedStep (IST) information */
- query_apm_bios(); /* Query APM information */ if CONFIG_APM | CONFIG_APM_MODULE
- query_edd(); /* Query EDD information */ if CONFIG_EDD | CONFIG_EDD_MODULE
- set_video(); /* Set the video mode */
- [go_to_protected_mode()](https://github.com/torvalds/linux/blob/v4.16/arch/x86/boot/pm.c); (x86/boot/pm.c) /* Do the last things and invoke protected mode */
  - realmode_switch_hook(); / * disable NMI */
  - enable_a20(); /* activate a20 if not yet */
  - reset_coprocessor();
  - mask_all_interrupts();
  - setup_idt(); /* load null idt */
  - setup_gdt(); /* CS, DS, TSS */
  - protected_mode_jump(); [x86/boot/pmjump.S](https://github.com/torvalds/linux/blob/master/arch/x86/boot/pmjump.S)
  - this jumps to the 32-bit entry point (arch/x86/boot/compressed/head_64.S)
    - uses gcc noreturn attributes
    - passes code32 entry addr (0x100000)，and boot_params
    - x86_linux boot protocol: for bzImage in PM, kernel is relocated to 0x100000

保护模式总结
- gdtr寄存器(48位)存储全局描述符表的基址(32位)与大小(16位)
- 段寄存器存储段选择子(16位)，包含段描述符在段描述表中的索引，GDT/LDT标志位，RPL请求者优先级(与段描述符中的优先级协同工作)
- 段描述符(64位)
```
31          24        19      16              7            0
------------------------------------------------------------
|             | |B| |A|       | |   | |0|E|W|A|            |
| BASE 31:24  |G|/|L|V| LIMIT |P|DPL|S|  TYPE | BASE 23:16 | 4
|             | |D| |L| 19:16 | |   | |1|C|R|A|            |
------------------------------------------------------------
|                             |                            |
|        BASE 15:0            |       LIMIT 15:0           | 0
|                             |                            |
------------------------------------------------------------
```
  - Limit(20位)表示内存段长度
    - G = 0, 内存段的长度按照1 byte进行增长(Limit每增加1，段长度增加1 byte)，最大的内存段长度将是1M bytes；
    - G = 1, 内存段的长度按照4K bytes进行增长(Limit每增加1，段长度增加4K bytes)，最大的内存段长度是4G bytes;
  - Base(32位)表示段基址
  - 40-47位定义内存段类型以及支持的操作
    - S标志(第44位)定义了段类型，S = 0说明这个内存段是一个系统段;S = 1说明这个内存段是一个代码段或者是数据段(堆栈段是一种特殊类型的数据段，堆栈段必须是可以进行读写的段)。
      - S = 1的情况下，第43位决定了内存段是数据段还是代码段。如果43位 = 0，说明是一个数据段，否则就是一个代码段。
      - 数据段，第42，41，40位表示的是(E扩展，W可写，A可访问)
      - 代码段，第42，41，40位表示的是(C一致，R可读，A可访问）
```
|           Type Field        | Descriptor Type | Description
|-----------------------------|-----------------|------------------
| Decimal                     |                 |
|             0    E    W   A |                 |
| 0           0    0    0   0 | Data            | Read-Only
| 1           0    0    0   1 | Data            | Read-Only, accessed
| 2           0    0    1   0 | Data            | Read/Write
| 3           0    0    1   1 | Data            | Read/Write, accessed
| 4           0    1    0   0 | Data            | Read-Only, expand-down
| 5           0    1    0   1 | Data            | Read-Only, expand-down, accessed
| 6           0    1    1   0 | Data            | Read/Write, expand-down
| 7           0    1    1   1 | Data            | Read/Write, expand-down, accessed
|                  C    R   A |                 |
| 8           1    0    0   0 | Code            | Execute-Only
| 9           1    0    0   1 | Code            | Execute-Only, accessed
| 10          1    0    1   0 | Code            | Execute/Read
| 11          1    0    1   1 | Code            | Execute/Read, accessed
| 12          1    1    0   0 | Code            | Execute-Only, conforming
| 14          1    1    0   1 | Code            | Execute-Only, conforming, accessed
| 13          1    1    1   0 | Code            | Execute/Read, conforming
| 15          1    1    1   1 | Code            | Execute/Read, conforming, accessed
```
  - P 标志(bit 47) 说明该内存段是否已经存在于内存中。如果P = 0，那么在访问这个内存段的时候将报错。
  - AVL 标志(bit 52) 在Linux内核中没有被使用。
  - L 标志(bit 53) 只对代码段有意义，如果L = 1，说明该代码段需要运行在64位模式下。
  - D/B flag(bit 54) 根据段描述符描述的是一个可执行代码段、下扩数据段还是一个堆栈段，这个标志具有不同的功能。（对于32位代码和数据段，这个标志应该总是设置为1；对于16位代码和数据段，这个标志被设置为0。）。
    - 可执行代码段。此时这个标志称为D标志并用于指出该段中的指令引用有效地址和操作数的默认长度。如果该标志置位，则默认值是32位地址和32位或8位的操作数；如果该标志为0，则默认值是16位地址和16位或8位的操作数。指令前缀0x66可以用来选择非默认值的操作数大小；前缀0x67可用来选择非默认值的地址大小。
    - 栈段（由SS寄存器指向的数据段）。此时该标志称为B（Big）标志，用于指明隐含堆栈操作（如PUSH、POP或CALL）时的栈指针大小。如果该标志置位，则使用32位栈指针并存放在ESP寄存器中；如果该标志为0，则使用16位栈指针并存放在SP寄存器中。如果堆栈段被设置成一个下扩数据段，这个B标志也同时指定了堆栈段的上界限。
    - 下扩数据段。此时该标志称为B标志，用于指明堆栈段的上界限。如果设置了该标志，则堆栈段的上界限是0xFFFFFFFF（4GB）；如果没有设置该标志，则堆栈段的上界限是0xFFFF（64KB）。

[arch/x86/boot/compressed/head_64.S](https://github.com/torvalds/linux/blob/master/arch/x86/boot/compressed/head_64.S) ([@elixir](https://elixir.bootlin.com/linux/latest/source/arch/x86/boot/compressed/head_64.S)) detail info [linux-insides](https://0xax.gitbooks.io/linux-insides/content/Booting/linux-bootstrap-4.html)
- Stack setup and CPU verification
- Calculate the relocation address
- Reload the segments if needed
- Preparation before entering long mode
- Early page table initialization
- transition to 64-bit mode
- Preparing to Decompress the Kernel
- The final touches before kernel decompression
- trampoline ?? somewhere sometime *[for LegoOS](http://lastweek.io/lego/kernel/trampoline/)*
- Kernel decompression: [`call	extract_kernel`](https://elixir.bootlin.com/linux/latest/source/arch/x86/boot/compressed/misc.c#L340)
- `jmp *%rax` jump to start_kernel() in init/main.c

? [`arch/x86/kernel/head64.c`](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/head64.c)

initial_code <- [head_64.S using x86_64_start_kernel from head64.c](https://elixir.bootlin.com/linux/latest/source/arch/x86/kernel/head_64.S#L265)

`__startup_64()` in [arch/x86/kernel/head64.c](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/head64.c)

`x86_64_start_kernel()` in [arch/x86/kernel/head64.c](https://github.com/torvalds/linux/blob/master/arch/x86/kernel/head64.c)
- BUILD_BUG_ON(MODULES_VADDR < __START_KERNEL_map);
- BUILD_BUG_ON(MODULES_VADDR - __START_KERNEL_map < KERNEL_IMAGE_SIZE);
- BUILD_BUG_ON(MODULES_LEN + KERNEL_IMAGE_SIZE > 2*PUD_SIZE);
- BUILD_BUG_ON((__START_KERNEL_map & ~PMD_MASK) != 0);
- BUILD_BUG_ON((MODULES_VADDR & ~PMD_MASK) != 0);
- BUILD_BUG_ON(!(MODULES_VADDR > __START_KERNEL));
- MAYBE_BUILD_BUG_ON(!(((MODULES_END - 1) & PGDIR_MASK) == (__START_KERNEL & PGDIR_MASK)));
- BUILD_BUG_ON(__fix_to_virt(__end_of_fixed_addresses) <= MODULES_END);
- cr4_init_shadow();
- reset_early_page_tables(); /* Kill off the identity-map trampoline */
- clear_bss();
- clear_page(init_top_pgt);
- sme_early_init();
- kasan_early_init();
- idt_setup_early_handler();
- copy_bootdata(__va(real_mode_data));
- load_ucode_bsp();
- init_top_pgt[511] = early_top_pgt[511]; /* set init_top_pgt kernel high mapping*/
- `x86_64_start_reservations`(real_mode_data);
    - call `start_kernel()` in init/main.c

[init/main.c](https://github.com/torvalds/linux/blob/master/init/main.c) ([@elixir](https://elixir.bootlin.com/linux/latest/source/init/main.c))
- set_task_stack_end_magic(&init_task);
- smp_setup_processor_id();
- debug_objects_early_init();
- cgroup_init_early();
- local_irq_disable();
- early_boot_irqs_disabled = true;
- boot_cpu_init();
- page_address_init();
- pr_notice("%s", linux_banner);
- early_security_init();
- setup_arch(&command_line);
- setup_boot_config(command_line);
- setup_command_line(command_line);
- setup_nr_cpu_ids();
- setup_per_cpu_areas();
- smp_prepare_boot_cpu();	/* arch-specific boot-cpu hooks */
- boot_cpu_hotplug_init();
- build_all_zonelists(NULL);
- page_alloc_init();
- pr_notice("Kernel command line: %s\n", saved_command_line);
- jump_label_init();
- parse_early_param();
- after_dashes = parse_args(xxx);
- setup_log_buf(0);
- vfs_caches_init_early();
- sort_main_extable();
- trap_init();
- mm_init();
- ftrace_init();
- early_trace_init(); /* trace_printk can be enabled here */
- sched_init();
- preempt_disable();
- local_irq_disable();
- radix_tree_init();
- housekeeping_init();
- workqueue_init_early();
- rcu_init();
- trace_init(); /* Trace events are available after this */
- initcall_debug_enable();
- context_tracking_init();
- early_irq_init(); /* init some links before init_ISA_irqs() */
- init_IRQ();
- tick_init();
- rcu_init_nohz();
- init_timers();
- hrtimers_init();
- softirq_init();
- timekeeping_init();
- rand_initialize();
- add_latent_entropy();
- add_device_randomness(command_line, strlen(command_line));
- boot_init_stack_canary();
- time_init();
- perf_event_init();
- profile_init();
- call_function_init();
- WARN(!irqs_disabled(), "Interrupts were enabled early\n");
- early_boot_irqs_disabled = false;
- local_irq_enable();
- kmem_cache_init_late();
- console_init();
- lockdep_init();
- locking_selftest();
- mem_encrypt_init();
- #ifdef CONFIG_BLK_DEV_INITRD xxx #endif
- setup_per_cpu_pageset();
- numa_policy_init();
- acpi_early_init();
- if (late_time_init) late_time_init();
- sched_clock_init();
- calibrate_delay();
- pid_idr_init();
- anon_vma_init();
- #ifdef CONFIG_X86 efi_enter_virtual_mode(); #endif
- thread_stack_cache_init();
- cred_init();
- fork_init();
- proc_caches_init();
- uts_ns_init();
- buffer_init();
- key_init();
- security_init();
- dbg_late_init();
- vfs_caches_init();
- pagecache_init();
- signals_init();
- seq_file_init();
- proc_root_init();
- nsfs_init();
- cpuset_init();
- cgroup_init();
- taskstats_init_early();
- delayacct_init();
- poking_init();
- check_bugs();
- acpi_subsystem_init();
- arch_post_acpi_subsys_init();
- sfi_init_late();
- kcsan_init();
- arch_call_rest_init(); /* Do the rest non-__init'ed, we're now alive */
    - rest_init()
        - rcu_scheduler_starting();
        - pid = kernel_thread(`kernel_init`, NULL, CLONE_FS);
        - rcu_read_lock();
        - tsk = find_task_by_pid_ns(pid, &init_pid_ns);
        - set_cpus_allowed_ptr(tsk, cpumask_of(smp_processor_id()));
        - rcu_read_unlock();
        - numa_default_policy();
        - pid = kernel_thread(kthreadd, NULL, CLONE_FS | CLONE_FILES);
        - rcu_read_lock();
        - kthreadd_task = find_task_by_pid_ns(pid, &init_pid_ns);
        - rcu_read_unlock();
        - system_state = SYSTEM_SCHEDULING;
        - complete(&kthreadd_done);
        - schedule_preempt_disabled();
        - cpu_startup_entry(CPUHP_ONLINE); /* Call into cpu_idle with preempt disabled */
- prevent_tail_call_optimization();
