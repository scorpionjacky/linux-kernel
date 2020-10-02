# Booting Explained

Linux has its own [boot loader](https://en.wikipedia.org/wiki/Booting#Modern_boot_loaders) (serving as MBR) up until version 2.4.\*. Starting from 2.6 (2.5 is a development version), the MBR part has been removed, and a boot manager is required to boot Linux kernel.

Linux versions between version 0.11 and 2.4 have bootsect.S, setup.S and header.S to serve as boot loader (MBR), setup, and kernel image. BIOS loads MBR, MBR loads setup, and setup loads the kernel. Starting from 2.6, these three have been changed to header.S and header_32.S and header_64.S. The MBR component has been removed and the many of the what setup.S does has been moved to c code. header_32.S and header_64.S are used for 32/64 bit respectively. Linux 0.01 has no setup.S and there is only 2-stage boot loading process.

Other than no longer serving MBR, the Linux booting process still dooe all the real-mode to protected-mode switch, GDT/IDT setup etc.

---

Linux Booting Process with a multi-boot manager and BIOS setup ([GRUB2](https://en.wikipedia.org/wiki/GNU_GRUB#Version_2_(GRUB_2)) as an example):

```
On Power-up/Reset       BIOS (System startup)
Stage 1 bootloader:     BIOS             <- MBR (boot.img GRUB)
Stage 1.5 bootloader:   MBR code in mem  <- GRUB core.img
Stage 2 bootloader:     GRUB 1.5 in mem  <- /boot/grub2, FS drivers, configs
Kernel Loading          GRUB in mem      <- load kernel image
Kernel Setup/Init       Kernel in memory
```

*Note: GRUB can alternatively pass control of the boot process to another boot loader, using chain loading. This is the method used to load operating systems that do not support the Multiboot Specification or are not supported directly by GRUB.*

*Note: [Master Boot Record](https://en.wikipedia.org/wiki/Master_boot_record) (MBR) vs [GUID Partition Table](https://en.wikipedia.org/wiki/GUID_Partition_Table) (GPT)*

*Note: [Unified Extensible Firmware Interface](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface) (UEFI), and what's the process UEFI for booting?*

*Note: [Coreboot](https://en.wikipedia.org/wiki/Coreboot) and [Libreboot](https://en.wikipedia.org/wiki/Libreboot)*

**System startup**

The [system startup](https://en.wikipedia.org/wiki/BIOS#System_startup) stage depends on the hardware that Linux is being booted on. On an embedded platform, a bootstrap environment is used when the system is powered on, or reset. Examples include U-Boot, RedBoot, and MicroMonitor from Lucent. Embedded platforms are commonly shipped with a boot monitor. These programs reside in special region of flash memory on the target hardware and provide the means to download a Linux kernel image into flash memory and subsequently execute it. In addition to having the ability to store and boot a Linux image, these boot monitors perform some level of system test and hardware initialization. In an embedded target, these boot monitors commonly cover both the first- and second-stage boot loaders.

In a PC, booting Linux begins in the [BIOS](https://en.wikipedia.org/wiki/BIOS) at address 0xFFFF0. The first step of the BIOS is the [power-on self test](https://en.wikipedia.org/wiki/Power-on_self-test) (POST). The job of the POST is to perform a check of the hardware. The second step of the BIOS is local device enumeration and initialization.

Given the different uses of BIOS functions, the BIOS is made up of two parts: the POST code and runtime services. After the POST is complete, it is flushed from memory, but the BIOS runtime services remain and are available to the target operating system.

The [MBR](https://en.wikipedia.org/wiki/Master_boot_record) is a 512-byte sector with a magic number in the last two bytes, located in the first sector on the disk (sector 1 of cylinder 0, head 0). After the MBR is loaded into RAM, the BIOS yields control to it

The primary boot loader that resides in the MBR is a 512-byte image containing both program code and a small partition table (see Figure 2). The first 446 bytes are the primary boot loader, which contains both executable code and error message text. The next sixty-four bytes are the partition table, which contains a record for each of four partitions (sixteen bytes each). The MBR ends with two bytes of the magic number 0xAA55 ([0x55 (offset +0x1FE) 0xAA (offset +0x1FF)](https://en.wikipedia.org/wiki/BIOS#Notes)) menifesting itself as a valid MBR.

```
MBR
000 - 445  Bootloader
446 - 510  Partition Table
511 - 512  Magic Number: 0xAA55 (note the endians)
```

Partition table contains multiple partition entriesm with each entry the following format:

`Partition flag | Start CHS | Partition byte | End CHS | Start LBA | Size`

There are 63 sections from the start of a disk to the first partition. The first section of 512 bytes are used for MBR, and the remaining 62 sectors (62\*512=31,744 bytes) are used by multi-boot managers as the stage 1.5 loader.

Because of the larger amount of space that can be accommodated for stage 1.5, it can have enough code to contain a few common filesystem drivers, such as the standard EXT and other Linux filesystems, FAT, and NTFS. The GRUB2 core.img is much more complex and capable than the older GRUB1 stage 1.5. This means that stage 2 of GRUB2 can be located on a standard EXT filesystem but it cannot be located on a logical volume. So the standard location for the stage 2 files is in the /boot filesystem, specifically /boot/grub2.

Note that the /boot directory must be located on a filesystem that is supported by GRUB. Not all filesystems are. The function of stage 1.5 is to begin execution with the filesystem drivers necessary to locate the stage 2 files in the /boot filesystem and load the needed drivers.

The function of GRUB2 stage 2 is to locate and load a Linux kernel into RAM and turn control of the computer over to the kernel. The kernel and its associated files are located in the /boot directory. The kernel files are identifiable as they are all named starting with vmlinuz.

memory map after Linux kernel is loaded into memory:
```
        | Protected-mode kernel  |
100000  +------------------------+
        | I/O memory hole        |
0A0000  +------------------------+
        | Reserved for BIOS      | Leave as much as possible unused
        ~                        ~
        | Command line           | (Can also be below the X+10000 mark)
X+10000 +------------------------+
        | Stack/heap             | For use by the kernel real-mode code.
X+08000 +------------------------+
        | Kernel setup           | The kernel real-mode code.
        | Kernel boot sector     | The kernel legacy boot sector.
      X +------------------------+
        | Boot loader            | <- Boot sector entry point 0x7C00
001000  +------------------------+
        | Reserved for MBR/BIOS  |
000800  +------------------------+
        | Typically used by MBR  |
000600  +------------------------+
        | BIOS use only          |
000000  +------------------------+
```

**Kernel**

All of the kernels are in a self-extracting, compressed format to save space. The kernels are located in the /boot directory, along with an initial RAM disk image, and device maps of the hard drives.

***Multiboot specification:*** Within the OS image file, the header must be in the first 8192 (2¹³) bytes for Multiboot and 32768 (2¹⁵) bytes for Multiboot2. The loader searches for a magic number to find the header, which is 0x1BADB002 for Multiboot and 0xE85250D6 for Multiboot2. In the header, entry_addr points to the code where control is handed over to the OS. This allows different executable file formats (see Comparison of executable file formats). If the OS kernel is an ELF file (Executable and Linkable Format), which it is for the Linux kernel, this can be omitted for Multiboot2. The ELF format is very common in the open source world and has its own field (e_entry) containing the entry point. Before jumping to the OS entry point, the boot loader must provide a boot information structure to tell the OS how it left the system; for Multiboot, this is a struct, and for Multiboot2, every field (group) has a type tag and a size.

At the head of this kernel image is a routine that does some minimal amount of hardware setup and then decompresses the kernel contained within the kernel image and places it into high memory. If an initial RAM disk image is present, this routine moves it into memory and notes it for later use. The routine then calls the kernel and the kernel boot begins.

Kernel image starts with `header.S` in the `start` assembly routine. This routine does some basic hardware setup and invokes the `startup_32` routine in `compressed/head.S`. This routine sets up a basic environment (stack, etc.) and clears the Block Started by Symbol (BSS). The kernel is then decompressed through a call to a C function called `decompress_kernel` (located in `boot/compressed/misc.c`). When the kernel is decompressed into memory, it is called. This is yet another `startup_32` function, but this function is in `kernel/head.S`.

In the new `startup_32` function (also called the swapper or process 0), the page tables are initialized and memory paging is enabled. The type of CPU is detected along with any optional floating-point unit (FPU) and stored away for later use. The `start_kernel` function is then invoked (`init/main.c`), which takes you to the non-architecture specific Linux kernel. This is, in essence, the main function for the Linux kernel.

```
start()                 arch/x86/boot/header.S
startup_32()            arch/x86/boot/compress/header.S
  decompress_kernel()   compress/misc.c
startup_32()            kernel/head.S
start_kernel()          init/main.c
cpu_idle()              init/main.c
```

With the call to start_kernel, a long list of initialization functions are called to set up interrupts, perform further memory configuration, and load the initial RAM disk. In the end, a call is made to kernel_thread (in arch/i386/kernel/process.c) to start the init function, which is the first user-space process. Finally, the idle task is started and the scheduler can now take control (after the call to cpu_idle). With interrupts enabled, the pre-emptive scheduler periodically takes control to provide multitasking.

During the boot of the kernel, the initial-RAM disk (initrd) that was loaded into memory by the stage 2 boot loader is copied into RAM and mounted. This initrd serves as a temporary root file system in RAM and allows the kernel to fully boot without having to mount any physical disks. Since the necessary modules needed to interface with peripherals can be part of the initrd, the kernel can be very small, but still support a large number of possible hardware configurations. After the kernel is booted, the root file system is pivoted (via pivot_root) where the initrd root file system is unmounted and the real root file system is mounted.

The initrd function allows you to create a small Linux kernel with drivers compiled as loadable modules. These loadable modules give the kernel the means to access disks and the file systems on those disks, as well as drivers for other hardware assets. Because the root file system is a file system on a disk, the initrd function provides a means of bootstrapping to gain access to the disk and mount the real root file system. In an embedded target without a hard disk, the initrd can be the final root file system, or the final root file system can be mounted via the Network File System (NFS).

> Note: The decompress_kernel function is where you see the usual decompression messages emitted to the display: *Uncompressing Linux… Ok, booting the kernel.*


**Init**

After the kernel is booted and initialized, the kernel starts the first user-space application. This is the first program invoked that is compiled with the standard C library. Prior to this point in the process, no standard C applications have been executed.

In a desktop Linux system, the first application started is commonly /sbin/init. But it need not be. Rarely do embedded systems require the extensive initialization provided by init (as configured through /etc/inittab). In many cases, you can invoke a simple shell script that starts the necessary embedded applications.

*Once the kernel has extracted itself, it loads systemd, which is the replacement for the old SysV init program, and turns control over to it.*

This is the end of the boot process. At this point, the Linux kernel and systemd are running but unable to perform any productive tasks for the end user because nothing else is running.

---

For a modern bzImage kernel with boot protocol version >= 2.02, a [memory layout](https://www.kernel.org/doc/html/latest/x86/boot.html#memory-layout) like the following is suggested:
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


---

ref

- Latest version of [header.S](https://github.com/torvalds/linux/blob/master/arch/x86/boot/header.S)
- 0xax: booting [gitbooks.io](https://0xax.gitbooks.io/linux-insides/content/Booting/), [github](https://github.com/0xAX/linux-insides/tree/master/Booting)

read this next:

https://opensource.com/article/17/2/linux-boot-and-startup

https://www.golinuxhub.com/2017/12/step-by-step-linux-boot-process-with/
