# Booting Related

- [Basic Input/Output System](https://en.wikipedia.org/wiki/BIOS) (BIOS) firmware/flash memory 
  - Detailed Booting Process, Memory Setup, Exteneded ROM, etc
- [Unified Extensible Firmware Interface](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface) (UEFI)
- [Coreboot](https://en.wikipedia.org/wiki/Coreboot) and [Libreboot](https://en.wikipedia.org/wiki/Libreboot)

- [Master Boot Record](https://en.wikipedia.org/wiki/Master_boot_record) (MBR)
- [GUID Partition Table](https://en.wikipedia.org/wiki/GUID_Partition_Table) (GPT)

Boot Manager
  - Grub2
  - [Grub](http://www.gnu.org/software/grub/) (Grand Unified Boot loader)
  - Lilo
  - Others

[Booting](https://en.wikipedia.org/wiki/Booting#Boot-loader) (Bootloader)

Bootstrap

BIOS loading bootloader


## Booting a PC

The BIOS firmware comes pre-installed on a personal computer's system board, and it is the first software to run when powered on.

After turning on your computer, the first thing that happens is that the BIOS (Basic Input Output System) takes control, initializes the screen and keyboard, and tests the main memory. At this point, no storage media or external devices are known to the system.

After that, the system reads the current date and time as well as information about the most important peripheral devices from the CMOS setup. After reading the CMOS, the BIOS should recognize the first hard disk, including details such as its geometry. It can then start to load the operating system (OS) from there.

To load the OS, the system loads a 512-byte data segment from the first hard disk into main memory and executes the code stored at the beginning of this segment. The instructions contained in it determine the rest of the boot process. This is why the first 512 bytes of the hard disk are often called the Master Boot Record (MBR).

Up to this point (loading the MBR), the boot sequence is independent of the installed operating system and is identical on all PCs. Also, all the PC has to access peripheral hardware are those routines (drivers) stored in the BIOS.

Master Boot Record

The layout of the MBR always follows a standard that is independent of the operating system. The first 446 bytes are reserved for program code. The next 64 bytes offer space for a partition table for up to four partitions (see Section 1.7. “Partitioning for Experts”). Without the partition table, no file systems exist on the hard disk — the disk would be virtually useless without it. The last two bytes must contain a special magic number (AA55). An MBR containing a different number would be considered invalid by the BIOS and any PC operating system.

Boot Sectors

Boot sectors are the first sectors on a hard disk partition, except in the case of extended partitions, which are just containers for other partitions. Boot sectors offer 512 bytes of space and are designed to contain code capable of launching an operating system on this partition. Boot sectors of formatted DOS, Windows, and OS/2 partitions do exactly that (in addition, they contain some basic data about the file system structure). In contrast, the boot sector of a Linux partition is empty (even after creating a file system on it). Thus, a Linux partition cannot bootstrap itself, even if it contains a kernel and a valid root file system. A boot sector with a valid start code contains the same magic number as the MBR in its last two bytes (AA55).

## Map Files, GRUB, and LILO

The main obstacle for booting an operating system is that the kernel is usually a file within a file system on a partition on a disk. These concepts are unknown to the BIOS. To circumvent this, maps and map files were introduced. These maps simply note the physical block numbers on the disk that comprise the logical files. When such a map is processed, the BIOS loads all the physical blocks in sequence as noted in the map, building the logical file in memory.

In contrast to LILO, which relies entirely on maps, GRUB tries to gain independence from the fixed maps at an early stage. GRUB achieves this by means of the file system code, which enables access to files by way of the path specification instead of the block numbers.

## Booting with GRUB

GRUB (the Grand Unified Boot loader) consists of two stages. The first stage is only 512 bytes long. It is written to the MBR or to the boot sector of a disk partition or floppy disk. The second, larger stage is loaded after that and holds the program code. The only purpose of the first stage is to load the second one.

The second stage contains code for reading file systems. GRUB has the ability to access file systems even before booting is finished, as long as they are on devices handled by the BIOS (floppies or hard disks).

All boot parameters can easily be changed before booting. If, for example, the menu file contains an error, it can be fixed. Boot parameters can be entered interactively at a prompt. GRUB offers the possibility to find the location of the kernel and initrd before booting. With this, you can even boot operating systems for which no entry exists in the boot menu.

The configuration file /boot/grub/menu.lst is loaded by GRUB directly from the file system on each boot, so there is no need to update GRUB when the file has been modified.

The fact that BIOS device names do not correspond to Linux devices is an issue resolved with algorithms that establish a mapping. GRUB stores the result in a file (device.map), which can be edited. 
