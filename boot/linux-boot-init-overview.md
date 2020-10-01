# Boot Flow (x86), 5.8.x

ref:
- [linux_note](https://github.com/jindian/linux_note) by [jindian](https://github.com/jindian?tab=repositories) <- [@gitbooks.io](https://start_fjin.gitbooks.io/linux-note/content/)
- [Linux Insides](https://github.com/0xAX/linux-insides) by 0xax  <- [@gitbooks.io](https://0xax.gitbooks.io/linux-insides/content/Booting/)
- [Linux boot protocol](https://github.com/torvalds/linux/blob/master/Documentation/x86/boot.rst)
- GNU Make, HTML manual: [Single-Page](https://www.gnu.org/software/make/manual/make.html) / [Multi-Page](https://www.gnu.org/software/make/manual/html_node/index.html) / kbuild [makefile](https://www.kernel.org/doc/html/latest/kbuild/makefiles.html)
- 知乎 [Linux内核启动](https://www.zhihu.com/column/c_1122808218635739136) by King Wag, 14 articles
  - [Layout of bzImage](https://zhuanlan.zhihu.com/p/73077391)
- https://en.wikipedia.org/wiki/Vmlinux

## modern kernel with boot manager

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
- copy_boot_params(); /* First, copy the boot header into the "zeropage" */
- console_init();  /* Initialize the early-boot console */
- init_heap(); /* End of heap check */
- validate_cpu() /* Make sure we have all the proper CPU support */
- set_bios_mode(); /* Tell the BIOS what CPU mode we intend to run in. */
- detect_memory(); /* Detect memory layout */
- keyboard_init(); /* Set keyboard repeat rate (why?) and query the lock flags */
- query_ist(); /* Query Intel SpeedStep (IST) information */
- query_apm_bios(); /* Query APM information */ if CONFIG_APM | CONFIG_APM_MODULE
- query_edd(); /* Query EDD information */ if CONFIG_EDD | CONFIG_EDD_MODULE
- set_video(); /* Set the video mode */
- [go_to_protected_mode()](https://github.com/torvalds/linux/blob/v4.16/arch/x86/boot/pm.c); (x86/boot/pm.c) /* Do the last things and invoke protected mode */
	- realmode_switch_hook();
    - enable_a20()
    - reset_coprocessor();
    - mask_all_interrupts();
    - setup_idt();
	- setup_gdt();
	- protected_mode_jump(); [x86/boot/pmjump.S](https://github.com/torvalds/linux/blob/master/arch/x86/boot/pmjump.S)
        - this jumps to the 32-bit entry point (arch/x86/boot/compressed/head_64.S)

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
