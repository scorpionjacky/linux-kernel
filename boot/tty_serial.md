ref:

- https://en.wikipedia.org/wiki/Linux_console
- https://en.wikipedia.org/wiki/8250_UART
- https://en.wikibooks.org/wiki/Serial_Programming/8250_UART_Programming
- https://en.wikipedia.org/wiki/16550_UART
- [tty @jesstess/ldd3-examples](https://github.com/jesstess/ldd3-examples/tree/master/examples/), [ldd4](https://github.com/jesstess/ldd4)
- https://tldp.org/HOWTO/Serial-HOWTO.html#toc18 (v2.27 February 2011)
- https://tldp.org/HOWTO/Text-Terminal-HOWTO.html (2013)
- https://www.linusakesson.net/programming/tty/
- https://processors.wiki.ti.com/index.php/Linux_Core_UART_User%27s_Guide
- https://wiki.st.com/stm32mpu/wiki/Serial_TTY_overview
- https://www.oreilly.com/library/view/linux-device-drivers/0596005903/ch18.html
- https://web.archive.org/web/20200207194832/https://www.lammertbies.nl/comm/info/serial-uart
- https://people.cs.clemson.edu/~mark/interrupts.html
- https://cateee.net/lkddb/web-lkddb/SERIAL_8250.html
- https://www.programmersought.com/article/41803652491/

---


UART means Universal Asynchronous Receiver/Transmitter. This is a chip which receives and transmits data serially; each serial port you have will use one, though it is possible that several may be integrated into one chip. 8250, 16450 and 16550 are all common types of UARTs.

---

A tty is the abstraction for serial IO presented to a program that runs on a terminal (or in a terminal window -- the program doesn't normally know the difference). It understands presenting a bunch of characters to the program; it understands using backspace keys to erase characters before the program sees them. It might be running on top of a real serial device, or it might be running on top of something like characters being fed to a terminal window under X.

A serial device is a driver for a real hardware device like a UART. It understands things like bit rates, parity, modem control lines, and interrupts. It will pass its data to a tty device.

---

A tty driver handles a lot of common code used on serial ports, built-in modems, PC consoles (including the PC keyboard), pseudo-terminals (ptys) and sometimes parallel ports connected to printers. It does not talk directly to hardware. Lots, but not all, of the arguments to "stty" are handled by the tty driver, including:

- editing characters (such as deleting the last character typed (typically ^H or DEL), re-drawing the line (typically ^R), erasing the input line (typically ^U), etc.
- characters that generate signals, such as SIGINTR (typically ^C on a PC keyboard) and various job control characters.
- translation to and from CR to LF to CRLF line endings
- gathering the input into lines.
- tab expansion, if any
- Does most of the buffering of characters.
and some of these parameters are passed through to the hardware driver:
- flow control, if any, may be passed through to the hardware driver.
- passes through settings for hardware modes (e.g. speed) to the hardware driver.

Some tty drivers have additions to the standard line discipline, which can implement some packet-oriented protocols such as PPP and SLIP, and perhaps talk over the network to a box that has multiple serial ports attached.

A hardware driver (e.g. serial port, uart, console video & keyboard) handles:
- Actually getting characters to and from the hardware and passes these to/from the tty driver.
- Usually contains the interrupt service routines for the hardware.
- Actually makes such settings as input and/or output speed, number of bits per character, odd/even/no/space/mark parity, number of stop bits (1/1.5/2), take effect. What can be set often depends on the controls available in hardware.
- Allows setting and reading modem control lines, if the hardware has them.
- Note that ptys have no hardware, but a pty driver passes characters between the "master" and "slave" sides of a pty, processing them through the tty driver.
- In the case of a PC console, contains a terminal emulator that translates a stream of characters (including control characters and escape sequences) to the memory-mapped video memory, and translates keyboard make/break codes to character codes.

Ttys that operate over a network are generally implemented using a daemon process and a pty.

Terminal windows that operate on a GUI (e.g. xterm) are generally implemented using a process (e.g. child of sshd) and a pty.

---

TTY vs CU (Mac, Linux)
In Unix and Linux environments, each serial communication port has two parts to it, a tty.* and a cu.*. When you look at your ports in say the Arduino IDE, you'll see both for one port.

The difference between the two is that a TTY device is used to call into a device/system, and the CU device (call-up) is used to call out of a device/system. Thus, this allows for two-way communication at the same time (full-duplex). This is more important to know if you are doing network communications through a terminal or other program, but it is still a question that comes up frequently. Just know that, for the purposes of this tutorial, always use the tty option for serial communication.

---

