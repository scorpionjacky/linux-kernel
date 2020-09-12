# Booting Related

- [Basic Input/Output System](https://en.wikipedia.org/wiki/BIOS) (BIOS) firmware/flash memory 
  - Detailed Booting Process, POST, Reset, Memory Setup, Exteneded ROM, etc
- [Unified Extensible Firmware Interface](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface) (UEFI)
- [Coreboot](https://en.wikipedia.org/wiki/Coreboot) and [Libreboot](https://en.wikipedia.org/wiki/Libreboot)

- [Master Boot Record](https://en.wikipedia.org/wiki/Master_boot_record) (MBR)
- [GUID Partition Table](https://en.wikipedia.org/wiki/GUID_Partition_Table) (GPT)

Boot Manager
  - [GNU Grub 2](https://en.wikipedia.org/wiki/GNU_GRUB)
  - [Grub](http://www.gnu.org/software/grub/) (Grand Unified Boot loader)
  - Lilo
  - Others

[Booting](https://en.wikipedia.org/wiki/Booting#Boot-loader) (Bootloader)

Bootstrap

BIOS loading bootloader


**Bootstrap**

On power-up or restart, POST will do [this](https://en.wikipedia.org/wiki/BIOS#System_startup). Note CTRL+ALT-DEL bypasses POST step to speed up reboot. POST, or Power-On Self Test is the beginning stages of the BIOS operation after a power on of a computer.

BIOS load the first 512 Bytes from storage devices. The first read data with [0x55 (offset +0x1FE) 0xAA (offset +0x1FF)](https://en.wikipedia.org/wiki/BIOS#Notes) in the last two bytes is considered a valid boot loader and thus control is past to the beginning of 512 byte code. Read [MBR](https://en.wikipedia.org/wiki/Master_boot_record) for information about the possible content of the 512 bytes.

**Map Files, GRUB, and LILO**

The main obstacle for booting an operating system is that the kernel is usually a file within a file system on a partition on a disk. These concepts are unknown to the BIOS. To circumvent this, maps and map files were introduced. These maps simply note the physical block numbers on the disk that comprise the logical files. When such a map is processed, the BIOS loads all the physical blocks in sequence as noted in the map, building the logical file in memory.

In contrast to LILO, which relies entirely on maps, GRUB tries to gain independence from the fixed maps at an early stage. GRUB achieves this by means of the file system code, which enables access to files by way of the path specification instead of the block numbers.

##Booting with GRUB 2**

Grub 2 loads load itself in [four stages](https://en.wikipedia.org/wiki/GNU_GRUB#Version_2_(GRUB_2)) and then presents a boot menu for users to choose a kernel. Once boot options have been selected, GRUB loads the selected kernel into memory and passes control to the kernel. Alternatively, GRUB can pass control of the boot process to another boot loader, using chain loading. This is the method used to load operating systems that do not support the Multiboot Specification or are not supported directly by GRUB.

