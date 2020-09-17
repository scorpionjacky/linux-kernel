# Booting explained

Linux Boot Process with a multi-boot manager and BIOS setup (GRUB as an example)

```
Power-up/Reset          BIOS (System startup)
Stage 1 bootloader:     BIOS             <- MBR (by GRUB)
Stage 1.5 bootloader:   MBR code in mem  <- GRUB stage 1.5 code
Stage 2 bootloader:     GRUB 1.5 in mem  <- /boot/grub2
Kernel Loading          GRUB in mem      <- load kernel image
Kernel Setup/Init       Kernel in memory
```

*What's the process with UEFI?*

System startup

The system startup stage depends on the hardware that Linux is being booted on. On an embedded platform, a bootstrap environment is used when the system is powered on, or reset. Examples include U-Boot, RedBoot, and MicroMonitor from Lucent. Embedded platforms are commonly shipped with a boot monitor. These programs reside in special region of flash memory on the target hardware and provide the means to download a Linux kernel image into flash memory and subsequently execute it. In addition to having the ability to store and boot a Linux image, these boot monitors perform some level of system test and hardware initialization. In an embedded target, these boot monitors commonly cover both the first- and second-stage boot loaders.

In a PC, booting Linux begins in the BIOS at address 0xFFFF0. The first step of the BIOS is the power-on self test (POST). The job of the POST is to perform a check of the hardware. The second step of the BIOS is local device enumeration and initialization.

Given the different uses of BIOS functions, the BIOS is made up of two parts: the POST code and runtime services. After the POST is complete, it is flushed from memory, but the BIOS runtime services remain and are available to the target operating system.

The MBR is a 512-byte sector with a magic number in the last two bytes, located in the first sector on the disk (sector 1 of cylinder 0, head 0). After the MBR is loaded into RAM, the BIOS yields control to it

The primary boot loader that resides in the MBR is a 512-byte image containing both program code and a small partition table (see Figure 2). The first 446 bytes are the primary boot loader, which contains both executable code and error message text. The next sixty-four bytes are the partition table, which contains a record for each of four partitions (sixteen bytes each). The MBR ends with two bytes that are defined as the magic number (0xAA55). The magic number serves as a validation check of the MBR.

```
MBR
000 - 445  Bootloader
446 - 510  Partition Table
511 - 512  Magic Number: 0xAA55 (note the endians)
```

Partition table contains multiple partition entriesm with each entry the following format:

`Partition flag | Start CHS | Partition byte | End CHS | Start LBA | Size`

There are 63 sections from the start of a disk to the first partition. The first section of 512 bytes are used for MBR, there are 62 sectors (62*512=31,744) bytes left, This is where the stage 1.6 loader can be stored for multi-boot managers.

Because of the larger amount of code that can be accommodated for stage 1.5, it can have enough code to contain a few common filesystem drivers, such as the standard EXT and other Linux filesystems, FAT, and NTFS. The GRUB2 core.img is much more complex and capable than the older GRUB1 stage 1.5. This means that stage 2 of GRUB2 can be located on a standard EXT filesystem but it cannot be located on a logical volume. So the standard location for the stage 2 files is in the /boot filesystem, specifically /boot/grub2.

Note that the /boot directory must be located on a filesystem that is supported by GRUB. Not all filesystems are. The function of stage 1.5 is to begin execution with the filesystem drivers necessary to locate the stage 2 files in the /boot filesystem and load the needed drivers.

The function of GRUB2 stage 2 is to locate and load a Linux kernel into RAM and turn control of the computer over to the kernel. The kernel and its associated files are located in the /boot directory. The kernel files are identifiable as they are all named starting with vmlinuz.

Kernel

All of the kernels are in a self-extracting, compressed format to save space. The kernels are located in the /boot directory, along with an initial RAM disk image, and device maps of the hard drives.

After the selected kernel is loaded into memory and begins executing, it must first extract itself from the compressed version of the file before it can perform any useful work. Once the kernel has extracted itself, it loads systemd, which is the replacement for the old SysV init program, and turns control over to it.

This is the end of the boot process. At this point, the Linux kernel and systemd are running but unable to perform any productive tasks for the end user because nothing else is running.

Kernel image starts with `header.S` in the `start` assembly routine. This routine does some basic hardware setup and invokes the `startup_32` routine in `compressed/head.S`. This routine sets up a basic environment (stack, etc.) and clears the Block Started by Symbol (BSS). The kernel is then decompressed through a call to a C function called `decompress_kernel` (located in `boot/compressed/misc.c`). When the kernel is decompressed into memory, it is called. This is yet another `startup_32` function, but this function is in `kernel/head.S`.

https://developer.ibm.com/technologies/linux/articles/l-linuxboot/
