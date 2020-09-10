# 6.3 setup.S 程序

6.3.1功能描述

setup.S 是一个操作系统加载程序，它的主要作用是利用 ROM BIOS 中断读取机器系统数据，并将这
些数据保存到 0x90000 开始的位置（覆盖掉了 bootsect 程序所在的地方）。 所取得的参数和保留的内存位
置见表 6– 2 所示。这些参数将被内核中相关程序使用，例如字符设备驱动程序集中的 console.c 和 tty_io.c
程序等。

表 6– 2 setup 程序读取并保留的参数

```
内存地址 长度(字节) 名称 描述
0x90000 2 光标位置 列号（ 0x00-最左端），行号（ 0x00-最顶端）
0x90002 2 扩展内存数 系统从 1MB 开始的扩展内存数值（ KB）。
0x90004 2 显示页面 当前显示页面
0x90006 1 显示模式
0x90007 1 字符列数
0x90008 2 ??
0x9000A 1 显示内存 显示内存(0x00-64k,0x01-128k,0x02-192k,0x03=256k)
0x9000B 1 显示状态 0x00-彩色,I/O=0x3dX； 0x01-单色,I/O=0x3bX
0x9000C 2 特性参数 显示卡特性参数
0x9000E 1 屏幕行数 屏幕当前显示行数。
0x9000F 1 屏幕列数 屏幕当前显示列数。
...
0x90080 16 硬盘参数表 第 1 个硬盘的参数表
0x90090 16 硬盘参数表 第 2 个硬盘的参数表（如果没有，则清零）
0x901FC 2 根设备号 根文件系统所在的设备号（ bootsec.s 中设置）
```

然后 setup 程序将 system 模块从 0x10000-0x8ffff 整块向下移动到内存绝对地址 0x00000 处（当时认
为内核系统模块 system 的长度不会超过此值： 512KB）。接下来加载中断描述符表寄存器(IDTR)和全局
描述符表寄存器(GDTR)，开启 A20 地址线，重新设置两个中断控制芯片 8259A，将硬件中断号重新设
置为 0x20 - 0x2f。最后设置 CPU 的控制寄存器 CR0（也称机器状态字），进入 32 位保护模式运行，并跳
转到位于 system 模块最前面部分的 head.s 程序继续运行。

为了能让 head.s 在 32 位保护模式下运行，在本程序中临时设置了中断描述符表（ IDT） 和全局描述
符表（ GDT），并在 GDT 中设置了当前内核代码段的描述符和数据段的描述符。下面在 head.s 程序中还
会根据内核的需要重新设置这些描述符表。

下面我们再复习一下段描述符的格式、描述符表的结构和段选择符（有些书中称之为选择子）的格
式。 Linux 内核代码中用到的代码段、数据段描述符的格式见图 6-4 所示。其中各字段的详细含义请参见
第 4 章中的说明。

图 6-4 程序代码段和数据段的描述符格式

段描述符存放在描述符表中。描述符表其实就是内存中描述符项的一个阵列。描述符表有两类：全
局描述符表（ Global descriptor table – GDT） 和局部描述符表（ Local descriptor table – LDT）。处理器是通
过使用 GDTR 和 LDTR 寄存器来定位 GDT 表和当前的 LDT 表。这两个寄存器以线性地址的方式保存了
A -- 已访问
AVL -- 软件可用位
B -- 默认大小
C -- 一致代码段
31 16 15 0
31 12 11 8 7 0
基地址
Base 23..16
基地址
Base 31..24
TYPE
24 23 22 21 20 19 16 15 14 13
G B 0 P
A V L
段限长
19..16 DPL 1
段限长
Segment Limit 15..0
基地址
Base Address 15..0 0
4 / W / W
31 16 15 0
31 12 11 8 7 0
基地址
Base 23..16
基地址
Base 31..24
TYPE
24 23 22 21 20 19 16 15 14 13
G D 0 P
A V L
段限长
19..16 DPL 1
段限长
Segment Limit 15..0
基地址
Base Address 15..0 0
4 / W / W
数据段描述符
代码段描述符
0 E W A
1 C R A
D -- 默认值
DPL -- 描述符特权级
E -- 扩展方向
G -- 颗粒度
R -- 可读
LIMIT -- 段限长
W -- 可写
P -- 存在6.3 setup.S 程序
221
描述符表的基地址和表的长度。指令 LGDT 和 SGDT 用于访问 GDTR 寄存器；指令 LLDT 和 SLDT 用
于访问 LDTR 寄存器。 LGDT 使用内存中一个 6 字节操作数来加载 GDTR 寄存器。头两个字节代表描述
符表的长度，后 4 个字节是描述符表的基地址。然而请注意，访问 LDTR 寄存器的指令 LLDT 所使用的
操作数却是一个 2 字节的操作数，表示全局描述符表 GDT 中一个描述符项的选择符。该选择符所对应
的 GDT 表中的描述符项应该对应一个局部描述符表。

例如， setup.S 程序设置的 GDT 描述符项（见程序第 567--578 行），代码段描述符的值是
0x00C09A00000007FF（即： 0x07FF, 0x0000, 0x9A00, 0x00C0），表示代码段的限长是 8MB（ =(0x7FF + 1)
* 4KB，这里加 1 是因为限长值是从 0 开始算起的），段在线性地址空间中的基址是 0，段类型值 0x9A
表示该段存在于内存中、段的特权级别为 0、段类型是可读可执行的代码段，段代码是 32 位的并且段的
颗粒度是 4KB。数据段描述符的值是 0x00C09200000007FF（即： 0x07FF, 0x0000, 0x9200, 0x00C0），表
示数据段的限长是 8MB，段在线性地址空间中的基址是 0，段类型值 0x92 表示该段存在于内存中、段
的特权级别为 0、段类型是可读可写的数据段，段代码是 32 位的并且段的颗粒度是 4KB。

这里再对选择符进行一些说明。选择符部分用于指定一个段描述符，它是通过指定一描述符表并且
索引其中的一个描述符项完成的。 图 6-5 示出了选择符的格式。

图 6-5 段选择符格式

其中索引值（ Index）用于选择指定描述符表中 8192（ 213） 个描述符中的一个。处理器将该索引值乘上 8，
并加上描述符表的基地址即可访问表中指定的段描述符。表指示器（ Table Indicator - TI）用于指定选择
符所引用的描述符表。值为 0 表示指定 GDT 表，值为 1 表示指定当前的 LDT 表。请求者特权级（ Requestor's
Privalege Level - RPL）用于保护机制。

由于 GDT 表的第一项(索引值为 0)没有被使用，因此一个具有索引值 0 和表指示器值也为 0 的选择
符（也即指向 GDT 的第一项的选择符）可以用作为一个空(null)选择符。当一个段寄存器（不能是 CS
或 SS）加载了一个空选择符时，处理器并不会产生一个异常。但是若使用这个段寄存器访问内存时就会
产生一个异常。对于初始化还未使用的段寄存器,使得对其意外的引用能产生一个指定的异常这种应用来
说，这样的特性很有用。

在进入保护模式之前，我们必须首先设置好将要用到的段描述符表，例如全局描述符表 GDT。然后
使用指令 lgdt 把描述符表的基地址告知 CPU（ GDT 表的基地址存入 gdtr 寄存器）。再将机器状态字的保
护模式标志置位即可进入 32 位保护运行模式。

另外， setup.S 程序第 215--566 行代码用于识别机器中使用的显示卡类别。如果系统使用 VGA 显示
卡，那么我们就检查一下显示卡是否支持超过 25 行 x 80 列的扩展显示模式（或显示方式）。所谓显示模
式是指 ROM BIOS 中断 int 0x10 的功能 0（ ah=0x00） 设置屏幕显示信息的方法，其中 al 寄存器中的输
入参数值即是我们要设置的显示模式或显示方式号。通常我们把 IBM PC 机刚推出时所能设置的几种显
示模式称为标准显示模式，而以后添加的一些则被称为扩展显示模式。例如 ATI 显示卡除支持标准显示
模式以外，还支持扩展显示模式号 0x23、 0x33，即还能够使用 132 列 x 25 行和 132 列 x 44 行两种显示
模式在屏幕上显示信息。在 VGA、 SVGA 刚出现时期，这些扩展显示模式均由显示卡上的 BIOS 提供支
持。若识别出一块已知类型的显示卡，程序就会向用户提供选择分辨率的机会。

但由于这段程序涉及很多显示卡各自特有的端口信息，因此这段程序比较复杂。好在这段代码与内
核运行原理关系不大，因此可以跳过不看。如果想彻底理解这段代码，那么在阅读这段代码时最好能参
15 3 2 1 0
描述符索引 TI RPL6.3 setup.S 程序
222
考 Richard F.Ferraro 的书《Programmer's Guide to the EGA, VGA, and Super VGA Cards》，或者参考网上能
下载到的经典 VGA 编程资料“VGADOC4”。这段程序由 Mats Andersson (d88-man@nada.kth.se)编制，
现在 Linus 已忘记 d88-man 是谁了:-)。

6.3.2代码注释

程序 6-2 linux/boot/setup.S

```
1 !
2 ! setup.s (C) 1991 Linus Torvalds
3 !
4 ! setup.s is responsible for getting the system data from the BIOS,
5 ! and putting them into the appropriate places in system memory.
6 ! both setup.s and system has been loaded by the bootblock.
7 !
8 ! This code asks the bios for memory/disk/other parameters, and
9 ! puts them in a "safe" place: 0x90000-0x901FF, ie where the
10 ! boot-block used to be. It is then up to the protected mode
11 ! system to read them from there before the area is overwritten
12 ! for buffer-blocks.
13 !
! setup.s 负责从 BIOS 中获取系统数据，并将这些数据放到系统内存的适当
! 地方。此时 setup.s 和 system 已经由 bootsect 引导块加载到内存中。
!
! 这段代码询问 bios 有关内存/磁盘/其他参数，并将这些参数放到一个
! “安全的”地方： 0x90000-0x901FF，也即原来 bootsect 代码块曾经在
! 的地方，然后在被缓冲块覆盖掉之前由保护模式的 system 读取。
14
15 ! NOTE! These had better be the same as in bootsect.s!
! 以下这些参数最好和 bootsect.s 中的相同！
16 #include <linux/config.h>
! config.h 中定义了 DEF_INITSEG = 0x9000； DEF_SYSSEG = 0x1000； DEF_SETUPSEG = 0x9020。
17
18 INITSEG = DEF_INITSEG ! we move boot here - out of the way ! 原来 bootsect 所处的段。
19 SYSSEG = DEF_SYSSEG ! system loaded at 0x10000 (65536). ! system 在 0x10000 处。
20 SETUPSEG = DEF_SETUPSEG ! this is the current segment ! 本程序所在的段地址。
21
22 .globl begtext, begdata, begbss, endtext, enddata, endbss
23 .text
24 begtext:
25 .data
26 begdata:
27 .bss
28 begbss:
29 .text
30
31 entry start
32 start:
33
34 ! ok, the read went well so we get current cursor position and save it for6.3 setup.S 程序
223
35 ! posterity.
! ok，整个读磁盘过程都正常，现在将光标位置保存以备今后使用（相关代码在 59--62 行）。
36
! 下句将 ds 置成 INITSEG(0x9000)。这已经在 bootsect 程序中设置过，但是现在是 setup 程序，
! Linus 觉得需要再重新设置一下。
37 mov ax,#INITSEG
38 mov ds,ax
39
40 ! Get memory size (extended mem, kB)
! 取扩展内存的大小值（ KB）。
! 利用 BIOS 中断 0x15 功能号 ah = 0x88 取系统所含扩展内存大小并保存在内存 0x90002 处。
! 返回： ax = 从 0x100000（ 1M）处开始的扩展内存大小(KB)。若出错则 CF 置位， ax = 出错码。
41
42 mov ah,#0x88
43 int 0x15
44 mov [2],ax ! 将扩展内存数值存在 0x90002 处（ 1 个字）。
45
46 ! check for EGA/VGA and some config parameters
! 检查显示方式（ EGA/VGA）并取参数。
! 调用 BIOS 中断 0x10 功能号 0x12（ 视频子系统配置）取 EBA 配置信息。
! ah = 0x12， bl = 0x10 - 取 EGA 配置信息。
! 返回：
! bh =显示状态(0x00 -彩色模式， I/O 端口=0x3dX； 0x01 -单色模式， I/O 端口=0x3bX)。
! bl = 安装的显示内存(0x00 - 64k； 0x01 - 128k； 0x02 - 192k； 0x03 = 256k。 )
! cx = 显示卡特性参数(参见程序后对 BIOS 视频中断 0x10 的说明)。
47
48 mov ah,#0x12
49 mov bl,#0x10
50 int 0x10
51 mov [8],ax ! 0x90008 = ??
52 mov [10],bx ! 0x9000A =安装的显示内存； 0x9000B=显示状态(彩/单色)
53 mov [12],cx ! 0x9000C =显示卡特性参数。
! 检测屏幕当前行列值。若显示卡是 VGA 卡时则请求用户选择显示行列值，并保存到 0x9000E 处。
54 mov ax,#0x5019 ! 在 ax 中预置屏幕默认行列值（ ah = 80 列； al=25 行）。
55 cmp bl,#0x10 ! 若中断返回 bl 值为 0x10，则表示不是 VGA 显示卡，跳转。
56 je novga
57 call chsvga ! 检测显示卡厂家和类型，修改显示行列值（第 215 行）。
58 novga: mov [14],ax ! 保存屏幕当前行列值（ 0x9000E， 0x9000F）。
! 使用 BIOS 中断 0x10 功能 0x03 取屏幕当前光标位置，并保存在内存 0x90000 处（ 2 字节）。
! 控制台初始化程序 console.c 会到此处读取该值。
! BIOS 中断 0x10 功能号 ah = 0x03， 读光标位置。
! 输入： bh = 页号
! 返回： ch = 扫描开始线； cl = 扫描结束线； dh = 行号(0x00 顶端)； dl = 列号(0x00 最左边)。
59 mov ah,#0x03 ! read cursor pos
60 xor bh,bh
61 int 0x10 ! save it in known place, con_init fetches
62 mov [0],dx ! it from 0x90000.
63
64 ! Get video-card data:
! 下面这段用于取显示卡当前显示模式。
! 调用 BIOS 中断 0x10，功能号 ah = 0x0f。
! 返回： ah = 字符列数； al = 显示模式； bh = 当前显示页。6.3 setup.S 程序
224
! 0x90004(1 字)存放当前页； 0x90006 存放显示模式； 0x90007 存放字符列数。
65
66 mov ah,#0x0f
67 int 0x10
68 mov [4],bx ! bh = display page
69 mov [6],ax ! al = video mode, ah = window width
70
71 ! Get hd0 data
! 取第一个硬盘的信息（复制硬盘参数表）。
! 第 1 个硬盘参数表的首地址竟然是中断 0x41 的中断向量值！而第 2 个硬盘参数表紧接在第 1 个
! 表的后面，中断 0x46 的向量向量值也指向第 2 个硬盘的参数表首址。表的长度是 16 个字节。
! 下面两段程序分别复制 ROM BIOS 中有关两个硬盘参数表到： 0x90080 处存放第 1 个硬盘的表，
! 0x90090 处存放第 2 个硬盘的表。 有关硬盘参数表内容说明，请参见 6.3.3 节的表 6-4。
72
! 第 75 行语句从内存指定位置处读取一个长指针值， 并放入 ds 和 si 寄存器。 ds 中放段地址，
! si 是段内偏移地址。这里是把内存地址 4 * 0x41（ = 0x104） 处保存的 4 个字节读出。 这 4 字
! 节即是硬盘参数表所处位置的段和偏移值。
73 mov ax,#0x0000
74 mov ds,ax
75 lds si,[4*0x41] ! 取中断向量 0x41 的值，即 hd0 参数表的地址ds:si
76 mov ax,#INITSEG
77 mov es,ax
78 mov di,#0x0080 ! 传输的目的地址: 0x9000:0x0080  es:di
79 mov cx,#0x10 ! 共传输 16 字节。
80 rep
81 movsb
82
83 ! Get hd1 data
84
85 mov ax,#0x0000
86 mov ds,ax
87 lds si,[4*0x46] ! 取中断向量 0x46 的值，即 hd1 参数表的地址ds:si
88 mov ax,#INITSEG
89 mov es,ax
90 mov di,#0x0090 ! 传输的目的地址: 0x9000:0x0090  es:di
91 mov cx,#0x10
92 rep
93 movsb
94
95 ! Check that there IS a hd1 :-)
! 检查系统是否有第 2 个硬盘。如果没有则把第 2 个表清零。
! 利用 BIOS 中断调用 0x13 的取盘类型功能，功能号 ah = 0x15；
! 输入： dl = 驱动器号（ 0x8X 是硬盘： 0x80 指第 1 个硬盘， 0x81 第 2 个硬盘）
! 输出： ah = 类型码； 00 - 没有这个盘， CF 置位； 01 - 是软驱，没有 change-line 支持；
! 02 - 是软驱(或其他可移动设备)，有 change-line 支持； 03 - 是硬盘。
96
97 mov ax,#0x01500
98 mov dl,#0x81
99 int 0x13
100 jc no_disk1
101 cmp ah,#3 ! 是硬盘吗？ (类型 = 3 ？ )。
102 je is_disk1
103 no_disk1:6.3 setup.S 程序
225
104 mov ax,#INITSEG ! 第 2 个硬盘不存在，则对第 2 个硬盘表清零。
105 mov es,ax
106 mov di,#0x0090
107 mov cx,#0x10
108 mov ax,#0x00
109 rep
110 stosb
111 is_disk1:
112
113 ! now we want to move to protected mode ...
! 现在我们要进入保护模式中了...
114
115 cli ! no interrupts allowed ! ! 从此开始不允许中断。
116
117 ! first we move the system to it's rightful place
! 首先我们将 system 模块移到正确的位置。
! bootsect 引导程序会把 system 模块读入到内存 0x10000（ 64KB） 开始的位置。由于当时假设
! system 模块最大长度不会超过 0x80000（ 512KB） ，即其末端不会超过内存地址 0x90000，所以
! bootsect 会把自己移动到 0x90000 开始的地方，并把 setup 加载到它的后面。下面这段程序的
! 用途是再把整个 system 模块移动到 0x00000 位置，即把从 0x10000 到 0x8ffff 的内存数据块
! （ 512KB）整块地向内存低端移动了 0x10000（ 64KB） 字节。
118
119 mov ax,#0x0000
120 cld ! 'direction'=0, movs moves forward
121 do_move:
122 mov es,ax ! destination segment ! es:di 是目的地址(初始为 0x0:0x0)
123 add ax,#0x1000
124 cmp ax,#0x9000 ! 已经把最后一段（从 0x8000 段开始的 64KB）代码移动完？
125 jz end_move ! 是，则跳转。
126 mov ds,ax ! source segment ! ds:si 是源地址(初始为 0x1000:0x0)
127 sub di,di
128 sub si,si
129 mov cx,#0x8000 ! 移动 0x8000 字（ 64KB 字节）。
130 rep
131 movsw
132 jmp do_move
133
134 ! then we load the segment descriptors
! 此后，我们加载段描述符。
! 从这里开始会遇到 32 位保护模式的操作。 有关这方面的信息请参阅第 4 章。在进入保护模式
! 中运行之前，我们需要首先设置好需要使用的段描述符表。这里需要设置全局描述符表 GDT 和
! 中断描述符表 IDT。下面指令 LIDT 用于加载中断描述符表寄存器。它的操作数（ idt_48） 有
! 6 字节。前 2 字节(字节 0-1）是描述符表的字节长度值；后 4 字节（字节 2-5）是描述符表的
! 32 位线性基地址， 其形式参见下面 580--586 行说明。中断描述符表中的每一个 8 字节表项指
! 出发生中断时需要调用的代码信息。与中断向量有些相似，但要包含更多的信息。
!
! LGDT 指令用于加载全局描述符表寄存器，其操作数格式与 LIDT 指令的相同。全局描述符表中
! 的每个描述符项（ 8 字节）描述了保护模式下数据段和代码段（块）的信息。 其中包括段的
! 最大长度限制（ 16 位）、段的线性地址基址（ 32 位）、段的特权级、段是否在内存、读写许可
! 权以及其他一些保护模式运行的标志。参见后面 567--578 行。
135
136 end_move:
137 mov ax,#SETUPSEG ! right, forgot this at first. didn't work :-)6.3 setup.S 程序
226
138 mov ds,ax ! ds 指向本程序(setup)段。
139 lidt idt_48 ! load idt with 0,0 ! 加载 IDT 寄存器。
140 lgdt gdt_48 ! load gdt with whatever appropriate ! 加载 GDT 寄存器。
141
142 ! that was painless, now we enable A20
! 以上的操作很简单，现在我们开启 A20 地址线。
! 为了能够访问和使用 1MB 以上的物理内存，我们需要首先开启 A20 地址线。参见本程序列表后
! 有关 A20 信号线的说明。关于所涉及的一些端口和命令，可参考 kernel/chr_drv/keyboard.S
! 程序后对键盘接口的说明。至于机器是否真正开启了 A20 地址线，我们还需要在进入保护模式
! 之后（能访问 1MB 以上内存之后）在测试一下。这个工作放在了 head.S 程序中（ 32--36 行）。
143
144 call empty_8042 ! 测试 8042 状态寄存器，等待输入缓冲器空。
! 只有当输入缓冲器为空时才可以对其执行写命令。
145 mov al,#0xD1 ! command write ! 0xD1 命令码-表示要写数据到
146 out #0x64,al ! 8042 的 P2 端口。 P2 端口位 1 用于 A20 线的选通。
147 call empty_8042 ! 等待输入缓冲器空，看命令是否被接受。
148 mov al,#0xDF ! A20 on ! 选通 A20 地址线的参数。
149 out #0x60,al ! 数据要写到 0x60 口。
150 call empty_8042 ! 若此时输入缓冲器为空，则表示 A20 线已经选通。
151
152 ! well, that went ok, I hope. Now we have to reprogram the interrupts :-(
153 ! we put them right after the intel-reserved hardware interrupts, at
154 ! int 0x20-0x2F. There they won't mess up anything. Sadly IBM really
155 ! messed this up with the original PC, and they haven't been able to
156 ! rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f,
157 ! which is used for the internal hardware interrupts as well. We just
158 ! have to reprogram the 8259's, and it isn't fun.
159
! 希望以上一切正常。现在我们必须重新对中断进行编程 :-( 我们将它们放在正好
! 处于 Intel 保留的硬件中断后面，即 int 0x20--0x2F。在那里它们不会引起冲突。
! 不幸的是 IBM 在原 PC 机中搞糟了，以后也没有纠正过来。 如此 PC 机 BIOS 把中断
! 放在了 0x08--0x0f，这些中断也被用于内部硬件中断。所以我们就必须重新对 8259
! 中断控制器进行编程，这一点都没意思。
!
! PC 机使用 2 个可编程中断控制器 8259A 芯片，关于 8259A 的编程方法请参见本程序后的介绍。
! 第 162 行上定义的两个字（ 0x00eb）是直接使用机器码表示的两条相对跳转指令，起延时作用。
! 0xeb 是直接近跳转指令的操作码，带 1 个字节的相对位移值。因此跳转范围是-127 到 127。 CPU
! 通过把这个相对位移值加到 EIP 寄存器中就形成一个新的有效地址。 执行时所花费的 CPU 时钟
! 周期数是 7 至 10 个。 0x00eb 表示跳转位移值是 0 的一条指令，因此还是直接执行下一条指令。
! 这两条指令共可提供 14--20 个 CPU 时钟周期的延迟时间。 因为在 as86 中没有表示相应指令的助
! 记符， 因此 Linus 在一些汇编程序中就直接使用机器码来表示这种指令。另外， 每个空操作指令
! NOP 的时钟周期数是 3 个，因此若要达到相同的延迟效果就需要 6 至 7 个 NOP 指令。
!
! 8259 芯片主片端口是 0x20-0x21，从片端口是 0xA0-0xA1。输出值 0x11 表示初始化命令开始，
! 它是 ICW1 命令字，表示边沿触发、多片 8259 级连、最后要发送 ICW4 命令字。
160 mov al,#0x11 ! initialization sequence
161 out #0x20,al ! send it to 8259A-1 ! 发送到 8259A 主芯片。
162 .word 0x00eb,0x00eb ! jmp $+2, jmp $+2 ! '$'表示当前指令的地址，
163 out #0xA0,al ! and to 8259A-2 ! 再发送到 8259A 从芯片。
164 .word 0x00eb,0x00eb
! Linux 系统硬件中断号被设置成从 0x20 开始。参见表 3-2：硬件中断请求信号与中断号对应表。
165 mov al,#0x20 ! start of hardware int's (0x20)
166 out #0x21,al ! 送主芯片 ICW2 命令字，设置起始中断号，要送奇端口。6.3 setup.S 程序
227
167 .word 0x00eb,0x00eb
168 mov al,#0x28 ! start of hardware int's 2 (0x28)
169 out #0xA1,al ! 送从芯片 ICW2 命令字，从芯片的起始中断号。
170 .word 0x00eb,0x00eb
171 mov al,#0x04 ! 8259-1 is master
172 out #0x21,al ! 送主芯片 ICW3 命令字，主芯片的 IR2 连从芯片 INT。
！参见代码列表后的说明。
173 .word 0x00eb,0x00eb
174 mov al,#0x02 ! 8259-2 is slave
175 out #0xA1,al ! 送从芯片 ICW3 命令字，表示从芯片的 INT 连到主芯
! 片的 IR2 引脚上。
176 .word 0x00eb,0x00eb
177 mov al,#0x01 ! 8086 mode for both
178 out #0x21,al ! 送主芯片 ICW4 命令字。 8086 模式；普通 EOI、非缓冲
! 方式，需发送指令来复位。初始化结束，芯片就绪。
179 .word 0x00eb,0x00eb
180 out #0xA1,al ！送从芯片 ICW4 命令字，内容同上。
181 .word 0x00eb,0x00eb
182 mov al,#0xFF ! mask off all interrupts for now
183 out #0x21,al ! 屏蔽主芯片所有中断请求。
184 .word 0x00eb,0x00eb
185 out #0xA1,al ！屏蔽从芯片所有中断请求。
186
187 ! well, that certainly wasn't fun :-(. Hopefully it works, and we don't
188 ! need no steenking BIOS anyway (except for the initial loading :-).
189 ! The BIOS-routine wants lots of unnecessary data, and it's less
190 ! "interesting" anyway. This is how REAL programmers do it.
191 !
192 ! Well, now's the time to actually move into protected mode. To make
193 ! things as simple as possible, we do no register set-up or anything,
194 ! we let the gnu-compiled 32-bit programs do that. We just jump to
195 ! absolute address 0x00000, in 32-bit protected mode.
!
! 哼，上面这段编程当然没劲:-(，但希望这样能工作，而且我们也不再需要乏味的 BIOS
! 了（除了初始加载:-)。 BIOS 子程序要求很多不必要的数据，而且它一点都没趣。那是
! “真正”的程序员所做的事。
!
! 好了，现在是真正开始进入保护模式的时候了。为了把事情做得尽量简单，我们并不对
! 寄存器内容进行任何设置。我们让 gnu 编译的 32 位程序去处理这些事。在进入 32 位保
! 护模式时我们仅是简单地跳转到绝对地址 0x00000 处。
196
! 下面设置并进入 32 位保护模式运行。首先加载机器状态字(lmsw-Load Machine Status Word)，
! 也称控制寄存器 CR0，其比特位 0 置 1 将导致 CPU 切换到保护模式，并且运行在特权级 0 中，即
! 当前特权级 CPL=0。此时段寄存器仍然指向与实地址模式中相同的线性地址处（在实地址模式下
! 线性地址与物理内存地址相同）。在设置该比特位后，随后一条指令必须是一条段间跳转指令以
! 用于刷新 CPU 当前指令队列。因为 CPU 是在执行一条指令之前就已从内存读取该指令并对其进行
! 解码。然而在进入保护模式以后那些属于实模式的预先取得的指令信息就变得不再有效。而一条
! 段间跳转指令就会刷新 CPU 的当前指令队列，即丢弃这些无效信息。另外，在 Intel 公司的手册
! 上建议 80386 或以上 CPU 应该使用指令“mov cr0,ax”切换到保护模式。 lmsw 指令仅用于兼容以
! 前的 286 CPU。
197 mov ax,#0x0001 ! protected mode (PE) bit ! 保护模式比特位(PE)。
198 lmsw ax ! This is it! ! 就这样加载机器状态字!6.3 setup.S 程序
228
199 jmpi 0,8 ! jmp offset 0 of segment 8 (cs) ! 跳转至 cs 段偏移 0 处。
! 我们已经将 system 模块移动到 0x00000 开始的地方，所以上句中的偏移地址是 0。而段值 8 已经
! 是保护模式下的段选择符了，用于选择描述符表和描述符表项以及所要求的特权级。段选择符长
! 度为 16 位（ 2 字节）；位 0-1 表示请求的特权级 0--3，但 Linux 操作系统只用到两级： 0 级（内
! 核级）和 3 级（用户级）；位 2 用于选择全局描述符表（ 0）还是局部描述符表(1)；位 3-15 是描
! 述符表项的索引，指出选择第几项描述符。所以段选择符 8（ 0b0000,0000,0000,1000）表示请求
! 特权级 0、使用全局描述符表 GDT 中第 2 个段描述符项，该项指出代码的基地址是 0（参见 571 行），
! 因此这里的跳转指令就会去执行 system 中的代码。
200
201 ! This routine checks that the keyboard command queue is empty
202 ! No timeout is used - if this hangs there is something wrong with
203 ! the machine, and we probably couldn't proceed anyway.
! 下面这个子程序检查键盘命令队列是否为空。这里不使用超时方法 -
! 如果这里死机，则说明 PC 机有问题，我们就没有办法再处理下去了。
!
! 只有当输入缓冲器为空时（键盘控制器状态寄存器位 1 = 0）才可以对其执行写命令。
204 empty_8042:
205 .word 0x00eb,0x00eb
206 in al,#0x64 ! 8042 status port ! 读 AT 键盘控制器状态寄存器。
207 test al,#2 ! is input buffer full? ! 测试位 1，输入缓冲器满？
208 jnz empty_8042 ! yes - loop
209 ret
210
! 注意下面 215--566 行代码牵涉到众多显示卡端口信息，因此比较复杂。但由于这段代码与内核
! 运行关系不大，因此可以跳过不看。
211 ! Routine trying to recognize type of SVGA-board present (if any)
212 ! and if it recognize one gives the choices of resolution it offers.
213 ! If one is found the resolution chosen is given by al,ah (rows,cols).
! 下面是用于识别 SVGA 显示卡（若有的话）的子程序。若识别出一块就向用户
! 提供选择分辨率的机会，并把分辨率放入寄存器 al、 ah（行、列）中返回。
!
! 下面首先显示 588 行上的 msg1 字符串（ "按<回车键>查看存在的 SVGA 模式，或按任意键继续"），
! 然后循环读取键盘控制器输出缓冲器，等待用户按键。如果用户按下回车键就去检查系统具有
! 的 SVGA 模式，并在 AL 和 AH 中返回最大行列值，否则设置默认值 AL=25 行、 AH=80 列并返回。
214
215 chsvga: cld
216 push ds ! 保存 ds 值。将在 231 行（或 490 或 492 行）弹出。
217 push cs ! 把默认数据段设置成和代码段同一个段。
218 pop ds
219 mov ax,#0xc000
220 mov es,ax ! es 指向 0xc000 段。此处是 VGA 卡上的 ROM BIOS 区。
221 lea si,msg1 ! ds:si 指向 msg1 字符串。
222 call prtstr ! 显示以 NULL 结尾的 msg1 字符串。
! 首先请注意,按键按下产生的扫描码称为接通码（ make code)，释放一个按下的按键产生的扫描码
! 称为断开码（ break code）。 下面这段程序读取键盘控制其输出缓冲器中的扫描码或命令。如果
! 收到的扫描码是比 0x82 小的接通码，那么因为 0x82 是最小的断开码值，所以小于 0x82 表示还没
! 有按键松开。如果扫描码大于 0xe0，表示收到的扫描码是扩展扫描码的前缀码。如果收到的是断
! 开码 0x9c，则表示 用户按下/松开了回车键，于是程序跳转去检查系统是否具有或支持 SVGA 模式。
! 否则就把 AX 设置为默认行列值并返回。
223 nokey: in al,#0x60 ! 读取键盘控制器缓冲中的扫描码。
224 cmp al,#0x82 ! 与最小断开码 0x82 比较。6.3 setup.S 程序
229
225 jb nokey ! 若小于 0x82， 表示还没有按键松开。
226 cmp al,#0xe0
227 ja nokey ! 若大于 0xe0，表示收到的是扩展扫描码前缀。
228 cmp al,#0x9c ! 若断开码是 0x9c，表示用户按下/松开了回车键，
229 je svga ! 于是程序跳转去检查系统是否具有 SVGA 模式。
230 mov ax,#0x5019 ! 否则设置默认行列值 AL=25 行、 AH=80 列。
231 pop ds
232 ret
! 下面根据 VGA 显示卡上的 ROM BIOS 指定位置处的特征数据串或者支持的特别功能来判断机器上
! 安装的是什么牌子的显示卡。本程序共支持 10 种显示卡的扩展功能。注意，此时程序已经在第
! 220 行把 es 指向 VGA 卡上 ROM BIOS 所在的段 0xc000（参见第 2 章）。
!
! 首先判断是不是 ATI 显示卡。我们把 ds:si 指向 595 行上 ATI 显示卡特征数据串，并把 es:si 指
! 向 VGA BIOS 中指定位置（偏移 0x31）处。该特征串共有 9 个字符（ "761295520"），我们来循环
! 比较这个特征串。如果相同则表示机器中的 VGA 卡是 ATI 牌子的，于是让 ds:si 指向该显示卡可
! 以设置的行列模式值 dscati（第 615 行），让 di 指向 ATI 卡可设置的行列个数和模式，并跳转
! 到标号 selmod（ 438 行）处进一步进行设置。
233 svga: lea si,idati ! Check ATI 'clues' ! 检查判断 ATI 显示卡的数据。
234 mov di,#0x31 ! 特征串从 0xc000:0x0031 开始。
235 mov cx,#0x09 ! 特征串有 9 个字节。
236 repe
237 cmpsb ! 如果 9 个字节都相同，表示系统中有一块 ATI 牌显示卡。
238 jne noati ! 若特征串不同则表示不是 ATI 显示卡。跳转继续检测卡。
! Ok，我们现在确定了显示卡的牌子是 ATI。于是 si 指向 ATI 显示卡可选行列值表 dscati
! di 指向扩展模式个数和扩展模式号列表 moati，然后跳转到 selmod（ 438 行）处继续处理。
239 lea si,dscati ! 把 dscati 的有效地址放入 si。
240 lea di,moati
241 lea cx,selmod
242 jmp cx
! 现在来判断是不是 Ahead 牌子的显示卡。首先向 EGA/VGA 图形索引寄存器 0x3ce 写入想访问的
! 主允许寄存器索引号 0x0f，同时向 0x3cf 端口（此时对应主允许寄存器）写入开启扩展寄存器
! 标志值 0x20。然后通过 0x3cf 端口读取主允许寄存器值，以检查是否可以设置开启扩展寄存器
! 标志。如果可以则说明是 Ahead 牌子的显示卡。注意 word 输出时 al端口 n， ah端口 n+1。
243 noati: mov ax,#0x200f ! Check Ahead 'clues'
244 mov dx,#0x3ce ! 数据端口指向主允许寄存器（ 0x0f0x3ce 端口），
245 out dx,ax ! 并设置开启扩展寄存器标志（ 0x200x3cf 端口）。
246 inc dx ! 然后再读取该寄存器，检查该标志是否被设置上。
247 in al,dx
248 cmp al,#0x20 ! 如果读取值是 0x20，则表示是 Ahead A 显示卡。
249 je isahed ! 如果读取值是 0x21，则表示是 Ahead B 显示卡。
250 cmp al,#0x21 ! 否则说明不是 Ahead 显示卡，于是跳转继续检测其余卡。
251 jne noahed
! Ok，我们现在确定了显示卡的牌子是 Ahead。于是 si 指向 Ahead 显示卡可选行列值表 dscahead，
! di 指向扩展模式个数和扩展模式号列表 moahead，然后跳转到 selmod（ 438 行）处继续处理。
252 isahed: lea si,dscahead
253 lea di,moahead
254 lea cx,selmod
255 jmp cx
! 现在来检查是不是 Chips & Tech 生产的显示卡。通过端口 0x3c3（ 0x94 或 0x46e8） 设置 VGA 允许
! 寄存器的进入设置模式标志（位 4），然后从端口 0x104 读取显示卡芯片集标识值。如果该标识值6.3 setup.S 程序
230
! 是 0xA5，则说明是 Chips & Tech 生产的显示卡。
256 noahed: mov dx,#0x3c3 ! Check Chips & Tech. 'clues'
257 in al,dx ! 从 0x3c3 端口读取 VGA 允许寄存器值，添加上进入设置模式
258 or al,#0x10 ! 标志（位 4）后再写回。
259 out dx,al
260 mov dx,#0x104 ! 在设置模式时从全局标识端口 0x104 读取显示卡芯片标识值，
261 in al,dx ! 并暂时存放在 bl 寄存器中。
262 mov bl,al
263 mov dx,#0x3c3 ! 然后把 0x3c3 端口中的进入设置模式标志复位。
264 in al,dx
265 and al,#0xef
266 out dx,al
267 cmp bl,[idcandt] ! 再把 bl 中标识值与位于 idcandt 处（第 596 行）的 Chips &
268 jne nocant ! Tech 的标识值 0xA5 作比较。如果不同则跳转比较下一种显卡。
! Ok，我们现在确定了该显示卡的牌子。于是 si 指向该品牌显示卡的可选行列值表 dsccandt， di 指向
! 扩展模式个数和扩展模式号列表 mocandt，然后跳转到 selmod（ 438 行）处继续进行设置模式操作。
269 lea si,dsccandt
270 lea di,mocandt
271 lea cx,selmod
272 jmp cx
! 现在检查是不是 Cirrus 显示卡。方法是使用 CRT 控制器索引号 0x1f 寄存器的内容来尝试禁止扩展
! 功能。该寄存器被称为鹰标（ Eagle ID） 寄存器，将其值高低半字节交换一下后写入端口 0x3c4 索
! 引的 6 号（定序/扩展）寄存器应该会禁止 Cirrus 显示卡的扩展功能。如果不会则说明不是 Cirrus
! 显示卡。因为从端口 0x3d4 索引的 0x1f 鹰标寄存器中读取的内容是鹰标值与 0x0c 索引号对应的显
! 存起始地址高字节寄存器内容异或操作之后的值，因此在读 0x1f 中内容之前我们需要先把显存起始
! 高字节寄存器内容保存后清零，并在检查后恢复之。另外，将没有交换过的 Eagle ID 值写到 0x3c4
! 端口索引的 6 号定序/扩展寄存器会重新开启扩展功能。
273 nocant: mov dx,#0x3d4 ! Check Cirrus 'clues'
274 mov al,#0x0c ! 首先向 CRT 控制寄存器的索引寄存器端口 0x3d4 写入要访问
275 out dx,al ! 的寄存器索引号 0x0c（对应显存起始地址高字节寄存器），
276 inc dx ! 然后从 0x3d5 端口读入显存起始地址高字节并暂存在 bl 中，
277 in al,dx ! 再把显存起始地址高字节寄存器清零。
278 mov bl,al
279 xor al,al
280 out dx,al
281 dec dx ! 接着向 0x3d4 端口输出索引 0x1f，指出我们要在 0x3d5 端口
282 mov al,#0x1f ! 访问读取“ Eagle ID”寄存器内容。
283 out dx,al
284 inc dx
285 in al,dx ! 从 0x3d5 端口读取“ Eagle ID”寄存器值，并暂存在 bh 中。
286 mov bh,al ! 然后把该值高低 4 比特互换位置存放到 cl 中。再左移 8 位
287 xor ah,ah ! 后放入 ch 中，而 cl 中放入数值 6。
288 shl al,#4
289 mov cx,ax
290 mov al,bh
291 shr al,#4
292 add cx,ax
293 shl cx,#8
294 add cx,#6 ! 最后把 cx 值存放入 ax 中。此时 ah 中是换位后的“ Eagle
295 mov ax,cx ! ID”值， al 中是索引号 6，对应定序/扩展寄存器。把 ah
296 mov dx,#0x3c4 ! 写到 0x3c4 端口索引的定序/扩展寄存器应该会导致 Cirrus
297 out dx,ax ! 显示卡禁止扩展功能。6.3 setup.S 程序
231
298 inc dx
299 in al,dx ! 如果扩展功能真的被禁止，那么此时读入的值应该为 0。
300 and al,al ! 如果不为 0 则表示不是 Cirrus 显示卡，跳转继续检查其他卡。
301 jnz nocirr
302 mov al,bh ! 是 Cirrus 显示卡，则利用第 286 行保存在 bh 中的“ Eagle
303 out dx,al ! ID”原值再重新开启 Cirrus 卡扩展功能。此时读取的返回
304 in al,dx ! 值应该为 1。若不是，则仍然说明不是 Cirrus 显示卡。
305 cmp al,#0x01
306 jne nocirr
! Ok，我们现在知道该显示卡是 Cirrus 牌。于是首先调用 rst3d4 子程序恢复 CRT 控制器的显示起始
! 地址高字节寄存器内容，然后让 si 指向该品牌显示卡的可选行列值表 dsccurrus， di 指向扩展模式
! 个数和扩展模式号列表 mocirrus，然后跳转到 selmod（ 438 行）处继续设置显示操作。
307 call rst3d4 ! 恢复 CRT 控制器的显示起始地址高字节寄存器内容。
308 lea si,dsccirrus
309 lea di,mocirrus
310 lea cx,selmod
311 jmp cx
! 该子程序利用保存在 bl 中的值（第 278 行）恢复 CRT 控制器的显示起始地址高字节寄存器内容。
312 rst3d4: mov dx,#0x3d4
313 mov al,bl
314 xor ah,ah
315 shl ax,#8
316 add ax,#0x0c
317 out dx,ax ! 注意，这是 word 输出！！ al 0x3d4， ah 0x3d5。
318 ret
! 现在检查系统中是不是 Everex 显示卡。方法是利用中断 int 0x10 功能 0x70（ ax =0x7000，
! bx=0x0000）调用 Everex 的扩展视频 BIOS 功能。对于 Everes 类型显示卡，该中断调用应该
! 会返回模拟状态，即有以下返回信息：
! al = 0x70，若是基于 Trident 的 Everex 显示卡；
! cl = 显示器类型： 00-单色； 01-CGA； 02-EGA； 03-数字多频； 04-PS/2； 05-IBM 8514； 06-SVGA。
! ch = 属性：位 7-6： 00-256K， 01-512K， 10-1MB， 11-2MB；位 4-开启 VGA 保护；位 0-6845 模拟。
! dx = 板卡型号：位 15-4：板类型标识号；位 3-0：板修正标识号。
! 0x2360-Ultragraphics II； 0x6200-Vision VGA； 0x6730-EVGA； 0x6780-Viewpoint。
! di = 用 BCD 码表示的视频 BIOS 版本号。
319 nocirr: call rst3d4 ! Check Everex 'clues'
320 mov ax,#0x7000 ! 设置 ax = 0x7000, bx=0x0000，调用 int 0x10。
321 xor bx,bx
322 int 0x10
323 cmp al,#0x70 ! 对于 Everes 显示卡， al 中应该返回值 0x70。
324 jne noevrx
325 shr dx,#4 ! 忽律板修正号（位 3-0）。
326 cmp dx,#0x678 ! 板类型号是 0x678 表示是一块 Trident 显示卡，则跳转。
327 je istrid
328 cmp dx,#0x236 ! 板类型号是 0x236 表示是一块 Trident 显示卡，则跳转。
329 je istrid
! Ok，我们现在确定了该显示卡的牌子。于是 si 指向该品牌显示卡的可选行列值表 dsceverex， di 指
! 向扩展模式个数和扩展模式号列表 moeverex，然后跳转到 selmod（ 438 行）处继续进行设置操作。
330 lea si,dsceverex
331 lea di,moeverex
332 lea cx,selmod
333 jmp cx6.3 setup.S 程序
232
334 istrid: lea cx,ev2tri ! 是 Trident 类型的 Everex 显示卡，则跳转到 ev2tri 处理。
335 jmp cx
! 现在检查是不是 Genoa 显示卡。方式是检查其视频 BIOS 中的特征数字串（ 0x77、 0x00、 0x66、
! 0x99）。注意，此时 es 已经在第 220 行被设置成指向 VGA 卡上 ROM BIOS 所在的段 0xc000。
336 noevrx: lea si,idgenoa ! Check Genoa 'clues'
337 xor ax,ax ! 让 ds:si 指向第 597 行上的特征数字串。
338 seg es
339 mov al,[0x37] ! 取 VGA 卡上 BIOS 中 0x37 处的指针（它指向特征串）。
340 mov di,ax ! 因此此时 es:di 指向特征数字串开始处。
341 mov cx,#0x04
342 dec si
343 dec di
344 l1: inc si ! 然后循环比较这 4 个字节的特征数字串。
345 inc di
346 mov al,(si)
347 seg es
348 and al,(di)
349 cmp al,(si)
350 loope l1
351 cmp cx,#0x00 ! 如果特征数字串完全相同，则表示是 Genoa 显示卡，
352 jne nogen ! 否则跳转去检查其他类型的显示卡。
! Ok，我们现在确定了该显示卡的牌子。于是 si 指向该品牌显示卡的可选行列值表 dscgenoa， di 指
! 向扩展模式个数和扩展模式号列表 mogenoa，然后跳转到 selmod（ 438 行）处继续进行设置操作。
353 lea si,dscgenoa
354 lea di,mogenoa
355 lea cx,selmod
356 jmp cx
! 现在检查是不是 Paradise 显示卡。同样是采用比较显示卡上 BIOS 中特征串（“ VGA=”）的方式。
357 nogen: lea si,idparadise ! Check Paradise 'clues'
358 mov di,#0x7d ! es:di 指向 VGA ROM BIOS 的 0xc000:0x007d 处，该处应该有
359 mov cx,#0x04 ! 4 个字符“ VGA=”。
360 repe
361 cmpsb
362 jne nopara ! 若有不同的字符，表示不是 Paradise 显示卡，于是跳转。
363 lea si,dscparadise ! 否则让 si 指向 Paradise 显示卡的可选行列值表，让 di 指
364 lea di,moparadise ! 向扩展模式个数和模式号列表。然后跳转到 selmod 处去选
365 lea cx,selmod ! 择想要使用的显示模式。
366 jmp cx
! 现在检查是不是 Trident（ TVGA）显示卡。 TVGA 显示卡扩充的模式控制寄存器 1（ 0x3c4 端口索引
! 的 0x0e）的位 3--0 是 64K 内存页面个数值。这个字段值有一个特性：当写入时，我们需要首先把
! 值与 0x02 进行异或操作后再写入；当读取该值时则不需要执行异或操作，即异或前的值应该与写
! 入后再读取的值相同。下面代码就利用这个特性来检查是不是 Trident 显示卡。
367 nopara: mov dx,#0x3c4 ! Check Trident 'clues'
368 mov al,#0x0e ! 首先在端口 0x3c4 输出索引号 0x0e，索引模式控制寄存器 1。
369 out dx,al ! 然后从 0x3c5 数据端口读入该寄存器原值，并暂存在 ah 中。
370 inc dx
371 in al,dx
372 xchg ah,al
373 mov al,#0x00 ! 然后我们向该寄存器写入 0x00，再读取其值al。
374 out dx,al ! 写入 0x00 就相当于“原值” 0x02 异或 0x02 后的写入值，6.3 setup.S 程序
233
375 in al,dx ! 因此若是 Trident 显示卡，则此后读入的值应该是 0x02。
376 xchg al,ah ! 交换后， al=原模式控制寄存器 1 的值， ah=最后读取的值。
! 下面语句右则英文注释是“真奇怪...书中并没有要求这样操作，但是这对我的 Trident 显示卡
! 起作用。如果不这样做，屏幕就会变模糊...”。这几行附带有英文注释的语句执行如下操作：
! 如果 bl 中原模式控制寄存器 1 的位 1 在置位状态的话就将其复位，否则就将位 1 置位。
! 实际上这几条语句就是对原模式控制寄存器 1 的值执行异或 0x02 的操作，然后用结果值去设置
! （恢复）原寄存器值。
377 mov bl,al ! Strange thing ... in the book this wasn't
378 and bl,#0x02 ! necessary but it worked on my card which
379 jz setb2 ! is a trident. Without it the screen goes
380 and al,#0xfd ! blurred ...
381 jmp clrb2 !
382 setb2: or al,#0x02 !
383 clrb2: out dx,al
384 and ah,#0x0f ! 取 375 行最后读入值的页面个数字段（位 3--0），如果
385 cmp ah,#0x02 ! 该字段值等于 0x02，则表示是 Trident 显示卡。
386 jne notrid
! Ok，我们现在可以确定是 Trident 显示卡。于是 si 指向该品牌显示卡的可选行列值表 dsctrident，
! di 指向扩展模式个数和扩展模式号列表 motrident，然后跳转到 selmod（ 438 行）处继续设置操作。
387 ev2tri: lea si,dsctrident
388 lea di,motrident
389 lea cx,selmod
390 jmp cx
! 现在检查是不是 Tseng 显示卡（ ET4000AX 或 ET4000/W32 类）。方法是对 0x3cd 端口对应的段
! 选择（ Segment Select） 寄存器执行读写操作。该寄存器高 4 位（位 7--4）是要进行读操作的
! 64KB 段号（ Bank number） ，低 4 位（位 3--0）是指定要写的段号。如果指定段选择寄存器的
! 值是 0x55（表示读、写第 6 个 64KB 段），那么对于 Tseng 显示卡来说，把该值写入寄存器后
! 再读出应该还是 0x55。
391 notrid: mov dx,#0x3cd ! Check Tseng 'clues'
392 in al,dx ! Could things be this simple ! :-)
393 mov bl,al ! 先从 0x3cd 端口读取段选择寄存器原值，并保存在 bl 中。
394 mov al,#0x55 ! 然后我们向该寄存器中写入 0x55。再读入并放在 ah 中。
395 out dx,al
396 in al,dx
397 mov ah,al
398 mov al,bl ! 接着恢复该寄存器的原值。
399 out dx,al
400 cmp ah,#0x55 ! 如果读取的就是我们写入的值，则表明是 Tseng 显示卡。
401 jne notsen
! Ok，我们现在可以确定是 Tseng 显示卡。于是 si 指向该品牌显示卡的可选行列值表 dsctseng，
! di 指向扩展模式个数和扩展模式号列表 motseng，然后跳转到 selmod（ 438 行）处继续设置操作。
402 lea si,dsctseng ! 于是让 si 指向 Tseng 显示卡的可选行列值的列表，让 di
403 lea di,motseng ! 指向对应扩展模式个数和模式号列表，然后跳转到 selmod
404 lea cx,selmod ! 去执行模式选择操作。
405 jmp cx
! 下面检查是不是 Video7 显示卡。端口 0x3c2 是混合输出寄存器写端口，而 0x3cc 是混合输出寄存
! 器读端口。该寄存器的位 0 是单色/彩色标志。如果为 0 则表示是单色，否则是彩色。判断是不是
! Video7 显示卡的方式是利用这种显示卡的 CRT 控制扩展标识寄存器（索引号是 0x1f）。该寄存器
! 的值实际上就是显存起始地址高字节寄存器（索引号 0x0c）的内容和 0xea 进行异或操作后的值。
! 因此我们只要向显存起始地址高字节寄存器中写入一个特定值，然后从标识寄存器中读取标识值
! 进行判断即可。6.3 setup.S 程序
234
! 通过对以上显示卡和这里 Video7 显示卡的检查分析，我们可知检查过程通常分为三个基本步骤。
! 首先读取并保存测试需要用到的寄存器原值，然后使用特定测试值进行写入和读出操作，最后恢
! 复原寄存器值并对检查结果作出判断。
406 notsen: mov dx,#0x3cc ! Check Video7 'clues'
407 in al,dx
408 mov dx,#0x3b4 ! 先设置 dx 为单色显示 CRT 控制索引寄存器端口号 0x3b4。
409 and al,#0x01 ! 如果混合输出寄存器的位 0 等于 0（单色）则直接跳转，
410 jz even7 ! 否则 dx 设置为彩色显示 CRT 控制索引寄存器端口号 0x3d4。
411 mov dx,#0x3d4
412 even7: mov al,#0x0c ! 设置寄存器索引号为 0x0c，对应显存起始地址高字节寄存器。
413 out dx,al
414 inc dx
415 in al,dx ! 读取显示内存起始地址高字节寄存器内容，并保存在 bl 中。
416 mov bl,al
417 mov al,#0x55 ! 然后在显存起始地址高字节寄存器中写入值 0x55，再读取出来。
418 out dx,al
419 in al,dx
420 dec dx ! 然后通过 CRTC 索引寄存器端口 0x3b4 或 0x3d4 选择索引号是
421 mov al,#0x1f ! 0x1f 的 Video7 显示卡标识寄存器。该寄存器内容实际上就是
422 out dx,al ! 显存起始地址高字节和 0xea 进行异或操作后的结果值。
423 inc dx
424 in al,dx ! 读取 Video7 显示卡标识寄存器值，并保存在 bh 中。
425 mov bh,al
426 dec dx ! 然后再选择显存起始地址高字节寄存器，恢复其原值。
427 mov al,#0x0c
428 out dx,al
429 inc dx
430 mov al,bl
431 out dx,al
432 mov al,#0x55 ! 随后我们来验证“ Video7 显示卡标识寄存器值就是显存起始
433 xor al,#0xea ! 地址高字节和 0xea 进行异或操作后的结果值” 。因此 0x55
434 cmp al,bh ! 和 0xea 进行异或操作的结果就应该等于标识寄存器的测试值。
435 jne novid7 ! 若不是 Video7 显示卡，则设置默认显示行列值（ 492 行）。
! Ok，我们现在可以确定是 Video7 显示卡。于是 si 指向该品牌显示卡的可选行列值表 dscvideo7，
! di 指向扩展模式个数和扩展模式号列表 movideo7，然后继续进行模式设置操作。
436 lea si,dscvideo7
437 lea di,movideo7
! 下面根据上述代码判断出的显示卡类型以及取得的相关扩展模式信息（ si 指向的行列值列表； di
! 指向扩展模式个数和模式号列表），提示用户选择可用的显示模式，并设置成相应显示模式。最后
! 子程序返回系统当前设置的屏幕行列值（ ah = 列数； al=行数）。例如，如果系统中是 ATI 显示卡，
! 那么屏幕上会显示以下信息：
! Mode: COLSxROWS:
! 0. 132 x 25
! 1. 132 x 44
! Choose mode by pressing the corresponding number.
!
! 这段程序首先在屏幕上显示 NULL 结尾的字符串信息“ Mode: COLSxROWS:”。
438 selmod: push si
439 lea si,msg2
440 call prtstr
441 xor cx,cx
442 mov cl,(di) ! 此时 cl 中是检查出的显示卡的扩展模式个数。6.3 setup.S 程序
235
443 pop si
444 push si
445 push cx
! 然后在每一行上显示出当前显示卡可选择的扩展模式行列值，供用户选用。
446 tbl: pop bx ! bx = 显示卡的扩展模式总个数。
447 push bx
448 mov al,bl
449 sub al,cl
450 call dprnt ! 以十进制格式显示 al 中的值。
451 call spcing ! 显示一个点再空 4 个空格。
452 lodsw ! 在 ax 中加载 si 指向的行列值，随后 si 指向下一个 word 值。
453 xchg al,ah ! 交换位置后 al = 列数。
454 call dprnt ! 显示列数；
455 xchg ah,al ! 此时 al 中是行数值。
456 push ax
457 mov al,#0x78 ! 显示一个小“ x” ，即乘号。
458 call prnt1
459 pop ax ! 此时 al 中是行数值。
460 call dprnt ! 显示行数。
461 call docr ! 回车换行。
462 loop tbl ! 再显示下一个行列值。 cx 中扩展模式计数值递减 1。
! 在扩展模式行列值都显示之后，显示“ Choose mode by pressing the corresponding number.” 。
463 pop cx ! cl 中是显示卡扩展模式总个数值。
464 call docr
465 lea si,msg3 ! 显示“请按相应数字键来选择模式。”
466 call prtstr
! 然后从键盘口读取用户按键的扫描码，根据该扫描码确定用户选择的行列值模式号，并利用 ROM
! BIOS 的显示中断 int 0x10 功能 0x00 来设置相应的显示模式。
! 第 468 行的“ 模式个数值+0x80” 是所按数字键-1 的断开扫描码。对于 0--9 数字键，它们的断开
! 扫描码分别是： 0 - 0x8B； 1 - 0x82； 2 - 0x83； 3 - 0x84； 4 - 0x85；
! 5 - 0x86； 6 - 0x87； 7 - 0x88； 8 - 0x89； 9 - 0x8A。
! 因此，如果读取的键盘断开扫描码小于 0x82 就表示不是数字键；如果扫描码等于 0x8B 则表示用户
! 按下数字 0 键。
467 pop si ! 弹出原行列值指针（指向显示卡行列值表开始处）。
468 add cl,#0x80 ! cl + 0x80 = 对应“数字键-1” 的断开扫描码。
469 nonum: in al,#0x60 ! Quick and dirty...
470 cmp al,#0x82 ! 若键盘断开扫描码小于 0x82 则表示不是数字键，忽律该键。
471 jb nonum
472 cmp al,#0x8b ! 若键盘断开扫描码等于 0x8b，表示按下了数字键 0。
473 je zero
474 cmp al,cl ! 若扫描码大于扩展模式个数值对应的最大扫描码值，表示
475 ja nonum ! 键入的值超过范围或不是数字键的断开扫描码。否则表示
476 jmp nozero ! 用户按下并松开了一个非 0 数字按键。
! 下面把断开扫描码转换成对应的数字按键值，然后利用该值从模式个数和模式号列表中选择对应的
! 的模式号。接着调用机器 ROM BIOS 中断 int 0x10 功能 0 把屏幕设置成模式号指定的模式。最后再
! 利用模式号从显示卡行列值表中选择并在 ax 中返回对应的行列值。
477 zero: sub al,#0x0a ! al = 0x8b - 0x0a = 0x81。
478 nozero: sub al,#0x80 ! 再减去 0x80 就可以得到用户选择了第几个模式。
479 dec al ! 从 0 起计数。
480 xor ah,ah ! int 0x10 显示功能号=0（设置显示模式）。
481 add di,ax6.3 setup.S 程序
236
482 inc di ! di 指向对应的模式号（跳过第 1 个模式个数字节值）。
483 push ax
484 mov al,(di) ! 取模式号al 中，并调用系统 BIOS 显示中断功能 0。
485 int 0x10
486 pop ax
487 shl ax,#1 ! 模式号乘 2，转换成为行列值表中对应值的指针。
488 add si,ax
489 lodsw ! 取对应行列值到 ax 中（ ah = 列数， al = 行数）。
490 pop ds ! 恢复第 216 行保存的 ds 原值。在 ax 中返回当前显示行列值。
491 ret
! 若都不是上面检测的显示卡，那么我们只好采用默认的 80 x 25 的标准行列值。
492 novid7: pop ds ! Here could be code to support standard 80x50,80x30
493 mov ax,#0x5019
494 ret
495
496 ! Routine that 'tabs' to next col.
! 光标移动到下一制表位的子程序。
497
! 显示一个点字符'.'和 4 个空格。
498 spcing: mov al,#0x2e ! 显示一个点字符'.'。
499 call prnt1
500 mov al,#0x20
501 call prnt1
502 mov al,#0x20
503 call prnt1
504 mov al,#0x20
505 call prnt1
506 mov al,#0x20
507 call prnt1
508 ret
509
510 ! Routine to print asciiz-string at DS:SI
! 显示位于 DS:SI 处以 NULL（ 0x00）结尾的字符串。
511
512 prtstr: lodsb
513 and al,al
514 jz fin
515 call prnt1 ! 显示 al 中的一个字符。
516 jmp prtstr
517 fin: ret
518
519 ! Routine to print a decimal value on screen, the value to be
520 ! printed is put in al (i.e 0-255).
! 显示十进制数字的子程序。显示值放在寄存器 al 中（ 0--255）。
521
522 dprnt: push ax
523 push cx
524 mov ah,#0x00
525 mov cl,#0x0a
526 idiv cl
527 cmp al,#0x09
528 jbe lt1006.3 setup.S 程序
237
529 call dprnt
530 jmp skip10
531 lt100: add al,#0x30
532 call prnt1
533 skip10: mov al,ah
534 add al,#0x30
535 call prnt1
536 pop cx
537 pop ax
538 ret
539
540 ! Part of above routine, this one just prints ascii al
! 上面子程序的一部分。显示 al 中的一个字符。
! 该子程序使用中断 0x10 的 0x0E 功能，以电传方式在屏幕上写一个字符。光标会自动移到下一个
! 位置处。如果写完一行光标就会移动到下一行开始处。如果已经写完一屏最后一行，则整个屏幕
! 会向上滚动一行。字符 0x07（ BEL）、 0x08（ BS）、 0x0A(LF)和 0x0D（ CR）被作为命令不会显示。
! 输入： AL -- 欲写字符； BH -- 显示页号； BL -- 前景显示色（图形方式时）。
541
542 prnt1: push ax
543 push cx
544 mov bh,#0x00 ! 显示页面。
545 mov cx,#0x01
546 mov ah,#0x0e
547 int 0x10
548 pop cx
549 pop ax
550 ret
551
552 ! Prints <CR> + <LF> ! 显示回车+换行。
553
554 docr: push ax
555 push cx
556 mov bh,#0x00
557 mov ah,#0x0e
558 mov al,#0x0a
559 mov cx,#0x01
560 int 0x10
561 mov al,#0x0d
562 int 0x10
563 pop cx
564 pop ax
565 ret
566
! 全局描述符表开始处。描述符表由多个 8 字节长的描述符项组成。这里给出了 3 个描述符项。
! 第 1 项无用（ 568 行），但须存在。第 2 项是系统代码段描述符（ 570-573 行），第 3 项是系
! 统数据段描述符(575-578 行)。
567 gdt:
568 .word 0,0,0,0 ! dummy ! 第 1 个描述符，不用。
569
! 在 GDT 表中这里的偏移量是 0x08。它是内核代码段选择符的值。
570 .word 0x07FF ! 8Mb - limit=2047 (0--2047，因此是 2048*4096=8Mb)
571 .word 0x0000 ! base address=0
572 .word 0x9A00 ! code read/exec ! 代码段为只读、可执行。6.3 setup.S 程序
238
573 .word 0x00C0 ! granularity=4096, 386 ! 颗粒度为 4096， 32 位模式。
574
! 在 GDT 表中这里的偏移量是 0x10。它是内核数据段选择符的值。
575 .word 0x07FF ! 8Mb - limit=2047 (2048*4096=8Mb)
576 .word 0x0000 ! base address=0
577 .word 0x9200 ! data read/write ! 数据段为可读可写。
578 .word 0x00C0 ! granularity=4096, 386 ! 颗粒度为 4096， 32 位模式。
579
! 下面是加载中断描述符表寄存器 idtr 的指令 lidt 要求的 6 字节操作数。前 2 字节是 IDT 表的
! 限长，后 4 字节是 idt 表在线性地址空间中的 32 位基地址。 CPU 要求在进入保护模式之前需设
! 置 IDT 表，因此这里先设置一个长度为 0 的空表。
580 idt_48:
581 .word 0 ! idt limit=0
582 .word 0,0 ! idt base=0L
583
! 这是加载全局描述符表寄存器 gdtr 的指令 lgdt 要求的 6 字节操作数。前 2 字节是 gdt 表的限
! 长，后 4 字节是 gdt 表的线性基地址。这里全局表长度设置为 2KB（ 0x7ff 即可） ，因为每 8
! 字节组成一个段描述符项，所以表中共可有 256 项。 4 字节的线性基地址为 0x0009<<16 +
! 0x0200 + gdt，即 0x90200 + gdt。 (符号 gdt 是全局表在本程序段中的偏移地址，见 205 行)
584 gdt_48:
585 .word 0x800 ! gdt limit=2048, 256 GDT entries
586 .word 512+gdt,0x9 ! gdt base = 0X9xxxx
587
588 msg1: .ascii "Press <RETURN> to see SVGA-modes available or any other key to continue."
589 db 0x0d, 0x0a, 0x0a, 0x00
590 msg2: .ascii "Mode: COLSxROWS:"
591 db 0x0d, 0x0a, 0x0a, 0x00
592 msg3: .ascii "Choose mode by pressing the corresponding number."
593 db 0x0d, 0x0a, 0x00
594
! 下面是 4 个显示卡的特征数据串。
595 idati: .ascii "761295520"
596 idcandt: .byte 0xa5 ! 标号 idcandt 意思是 ID of Chip AND Tech.
597 idgenoa: .byte 0x77, 0x00, 0x66, 0x99
598 idparadise: .ascii "VGA="
599
! 下面是各种显示卡可使用的扩展模式个数和对应的模式号列表。其中每一行第 1 个字节是模式个
! 数值，随后的一些值是中断 0x10 功能 0（ AH=0）可使用的模式号。例如从 602 行可知，对于 ATI
! 牌子的显示卡，除了标准模式以外还可使用两种扩展模式： 0x23 和 0x33。
600 ! Manufacturer: Numofmodes: Mode:
! 厂家： 模式数量： 模式列表：
601
602 moati: .byte 0x02, 0x23, 0x33
603 moahead: .byte 0x05, 0x22, 0x23, 0x24, 0x2f, 0x34
604 mocandt: .byte 0x02, 0x60, 0x61
605 mocirrus: .byte 0x04, 0x1f, 0x20, 0x22, 0x31
606 moeverex: .byte 0x0a, 0x03, 0x04, 0x07, 0x08, 0x0a, 0x0b, 0x16, 0x18, 0x21, 0x40
607 mogenoa: .byte 0x0a, 0x58, 0x5a, 0x60, 0x61, 0x62, 0x63, 0x64, 0x72, 0x74, 0x78
608 moparadise: .byte 0x02, 0x55, 0x54
609 motrident: .byte 0x07, 0x50, 0x51, 0x52, 0x57, 0x58, 0x59, 0x5a
610 motseng: .byte 0x05, 0x26, 0x2a, 0x23, 0x24, 0x22
611 movideo7: .byte 0x06, 0x40, 0x43, 0x44, 0x41, 0x42, 0x456.3 setup.S 程序
239
612
! 下面是各种牌子 VGA 显示卡可使用的模式对应的列、行值列表。例如第 615 行表示 ATI 显示卡两
! 种扩展模式的列、行值分别是 132 x 25、 132 x 44。
613 ! msb = Cols lsb = Rows:
! 高字节=列数 低字节=行数：
614
615 dscati: .word 0x8419, 0x842c ! ATI 卡可设置列、行值。
616 dscahead: .word 0x842c, 0x8419, 0x841c, 0xa032, 0x5042 ! Ahead 卡可设置值。
617 dsccandt: .word 0x8419, 0x8432
618 dsccirrus: .word 0x8419, 0x842c, 0x841e, 0x6425
619 dsceverex: .word 0x5022, 0x503c, 0x642b, 0x644b, 0x8419, 0x842c, 0x501e, 0x641b, 0xa040,
0x841e
620 dscgenoa: .word 0x5020, 0x642a, 0x8419, 0x841d, 0x8420, 0x842c, 0x843c, 0x503c, 0x5042,
0x644b
621 dscparadise: .word 0x8419, 0x842b
622 dsctrident: .word 0x501e, 0x502b, 0x503c, 0x8419, 0x841e, 0x842b, 0x843c
623 dsctseng: .word 0x503c, 0x6428, 0x8419, 0x841c, 0x842c
624 dscvideo7: .word 0x502b, 0x503c, 0x643c, 0x8419, 0x842c, 0x841c
625
626 .text
627 endtext:
628 .data
629 enddata:
630 .bss
631 endbss:
6.3.3其他信息
为了获取机器的基本参数和向用户显示启动过程的消息，这段程序多次调用了 ROM BIOS 中的中断
服务，并开始涉及一些对硬件端口的访问操作。下面简要地描述程序中使用到的几种 BIOS 中断调用服
务，并对 A20 地址线问题的缘由进行说明。 最后提及关于 80X86 CPU 32 位保护模式运行的问题。
6.3.3.1 当前内存映像
在 setup.s 程序执行结束后，系统模块 system 被移动到物理内存地址 0x00000 开始处，而从位置
0x90000 开始处则存放了内核将会使用的一些系统基本参数，示意图如图 6-6 所示。6.3 setup.S 程序
240
图 6-6 setup.s 程序结束后内存中程序示意图
此时临时全局表 GDT 中有三个描述符。 第一个是 NULL 不使用，另外两个分别是代码段描述符和
数据段描述符。它们都指向系统模块的起始处，也即物理内存地址 0x0000 处。这样当 setup.s 中执行最
后一条指令 'jmp 0,8 '（第 193 行）时，就会跳到 head.s 程序开始处继续执行下去。这条指令中的'8'是
段选择符值，用来指定所需使用的描述符项，此处是指临时 GDT 表中的代码段描述符。 '0'是描述符项指
定的代码段中的偏移值。
6.3.3.2 BIOS 视频中断 0x10
本节说明上面程序中用到的 ROM BIOS 中视频中断服务功能。 对获取显示卡信息功能（其他辅助功
能选择） 的说明请见表 6-3 所示。 其他显示服务功能已在程序注释中给出。
表 6– 3 获取显示卡信息（功能号： ah = 0x12， bl = 0x10）
输入/返回信息 寄存器 内容说明
输入信息
ah 功能号=0x12，获取显示卡信息
bl 子功能号=0x10。
返回信息
bh
视频状态：
0x00 – 彩色模式（此时视频硬件 I/O 端口基地址为 0x3DX）；
0x01 – 单色模式（此时视频硬件 I/O 端口基地址为 0x3BX）；
注：其中端口地址中的 X 值可为 0 – f。
bl
已安装的显示内存大小：
00 = 64K, 01 = 128K, 02 = 192K, 03 = 256K
ch
特性连接器比特位信息：
比特位 0-1 特性线 1-0，状态 2；
比特位 2-3 特性线 1-0，状态 1；
比特位 4-7 未使用(为 0)
cl 视频开关设置信息：
0x90200
0x00000
临时全局描述符表
(gdt)
system 模块
setup.s 程序
0x90000
head.s 程序
系统参数
库模块(lib)
内存管理模块(mm)
内核模块(kernel)
main.c 程序
setup.s 代码
代码段描述符
数据段描述符
原来的 bootsect.s
程序被覆盖掉了6.3 setup.S 程序
241
比特位 0-3 分别对应开关 1-4 关闭； 位 4-7 未使用。
原始 EGA/VGA 开关设置值:
0x00 MDA/HGC； 0x01-0x03 MDA/HGC；
0x04 CGA 40x25； 0x05 CGA 80x25；
0x06 EGA+ 40x25； 0x07-0x09 EGA+ 80x25；
0x0A EGA+ 80x25 单色； 0x0B EGA+ 80x25 单色。
6.3.3.3 硬盘基本参数表（“INT 0x41”）
在 ROM BIOS 的中断向量表中， INT 0x41 的中断向量位置处（ 4 * 0x41 =0x0000:0x0104） 存放的并
不是中断服务程序的地址，而是第一个硬盘的基本参数表的地址，见表 6-4 所示。对于 IBM PC 全兼容
机器的 BIOS，这里存放的硬盘参数表的地址具体值是 F000h:E401h。第二个硬盘的基本参数表入口地址
存于 INT 0x46 中断向量位置处。
表 6– 4 硬盘基本参数信息表
位移 大小 英文名称 说明
0x00 字 cyl 柱面数
0x02 字节 head 磁头数
0x03 字 开始减小写电流的柱面(仅 PC/ XT 使用，其他为 0)
0x05 字 wpcom 开始写前预补偿柱面号（乘 4）
0x07 字节 最大 ECC 猝发长度（仅 PC/XT 使用，其他为 0）
0x08 字节 ctl
控制字节（驱动器步进选择）
位 0 - 未用； 位 1 - 保留(0) (关闭 IRQ)；
位 2 - 允许复位； 位 3 - 若磁头数大于 8 则置 1；
位 4 - 未用(0)； 位 5 - 若在柱面数+1 处有厂商的坏区图，则置 1
位 6 - 禁止 ECC 重试； 位 7 - 禁止访问重试。
0x09 字节 标准超时值（仅 PC/ XT 使用，其他为 0）
0x0A 字节 格式化超时值（仅 PC/ XT 使用，其他为 0）
0x0B 字节 检测驱动器超时值（仅 PC/ XT 使用，其他为 0）
0x0C 字 lzone 磁头着陆(停止)柱面号
0x0E 字节 sect 每磁道扇区数
0x0F 字节 保留。
6.3.3.4 A20 地址线问题
1981 年 8 月， IBM 公司最初推出的个人计算机 IBM PC 使用的是准 16 位的 Intel 8088 CPU。 该 CPU
具有 16 位内部数据总线（ 外部 8 位）和 20 位地址总线宽度。因此， 该微机中地址线只有 20 根(A0 – A19)，
CPU 最多可寻址 1MB 的内存范围。在当时流行的机器内存 RAM 容量只有几十 KB、几百 KB 的情况下，
20 根地址线已足够用来寻址这些内存。其所能寻址的最高地址是 0xffff:0xffff，也即 0x10ffef。对于超出
0x100000(1MB)的内存地址， CPU 将默认环绕寻址到 0x0ffef 位置处。
当 IBM 公司于 1985 年推出 PC/AT 新机型时，使用的是 Intel 80286 CPU，具有 24 根地址线，可寻
址最多 16MB 内存，并且有一个与 8088 完全兼容的实模式运行方式。然而，在寻址值超过 1MB 时它却
不能象 8088 CPU 那样实现地址寻址的环绕。但是当时已经有一些程序被设计成利用这种地址环绕机制
进行工作。因此，为了实现与原 PC 机完全兼容， IBM 公司发明了使用一个开关来开启或禁止 0x100000
地址比特位。由于在当时的键盘控制器 8042 上恰好有空闲的端口引脚（输出端口 P2，引脚 P21），于是
便使用了该引脚来作为与门来控制这个地址比特位。该信号即被称为 A20。如果它为零，则比特 20 及以6.3 setup.S 程序
242
上地址都被清除。从而实现了兼容性。关于键盘控制器 8042 芯片，请参见 kernel/chr_drv/keyboard.S 程
序后的说明。
为了兼容性，默认条件下在机器启动时 A20 地址线是禁止的，所以 32 位机器的操作系统必须使用
适当的方法来开启它。但是由于各种兼容机所使用的芯片集不同，要做到这一点却是非常的麻烦。因此
通常要在几种控制方法中选择。
对 A20 信号线进行控制的常用方法是设置键盘控制器的端口值。这里的 setup.s 程序（ 138-144 行）
即使用了这种典型的控制方式。对于其他一些兼容微机还可以使用其他方式来做到对 A20 线的控制。有
些操作系统将 A20 的开启和禁止作为实模式与保护运行模式之间进行转换的标准过程中的一部分。由于
键盘的控制器速度很慢，因此就不能使用键盘控制器对 A20 线来进行操作。为此引进了一个 A20 快速门
选项(Fast Gate A20)。它使用 I/O 端口 0x92 来处理 A20 信号线，避免了使用慢速的键盘控制器操作方式。
对于不含键盘控制器的系统就只能使用 0x92 端口来控制。但是该端口也有可能被其他兼容微机上的设备
（如显示芯片）所使用，从而造成系统错误的操作。还有一种方式是通过读 0xee 端口来开启 A20 信号
线，写该端口则会禁止 A20 信号线。
6.3.3.5 8259A 中断控制器的编程方法
在第 2 章中我们已经概要介绍了中断机制的基本工作原理和 PC/AT 兼容微机中使用的硬件中断子系
统。这里我们首先介绍 8259A 芯片的工作原理，然后详细说明 8259A 芯片的编程方法以及 Linux 内核对
其设置的工作方式。
1. 8259A 芯片工作原理
前面已经说过，在 PC/AT 系列兼容机中使用了级联的两片 8259A 可编程控制器（ PIC）芯片，共可
管理 15 级中断向量，参见图 2-20 所示。其中从芯片的 INT 引脚连接到主芯片的 IR2 引脚上。主 8259A
芯片的端口基地址是 0x20，从芯片是 0xA0。一个 8259A 芯片的逻辑框图见图 6-7 所示。
图 6-7 可编程中断控制器 8259A 芯片框图
图中，中断请求寄存器 IRR（ Interrupt Request Register） 用来保存中断请求输入引脚上所有请求服务
中断级，寄存器的 8 个比特位（ D7—D0）分别对应引脚 IR7—IR0。中断屏蔽寄存器 IMR（ Interrup Mask
Register）用于保存被屏蔽的中断请求线对应的比特位，寄存器的 8 位也是对应 8 个中断级。哪个比特位
被置 1 就屏蔽哪一级中断请求。即 IMR 对 IRR 进行处理，其每个比特位对应 IRR 的每个请求比特位。
对高优先级输入线的屏蔽并不会影响低优先级中断请求线的输入。优先级解析器 PR（ Priority Resolver）
控制逻辑等
优先级
解析器
(PR)
中断请求
寄存器
(IRR)
正在服务
寄存器
(ISR)
IR0
IR1
IR2
IR3
IR4
IR5
IR6
IR7
初始化命令字
寄存器组ICWs
操作命令字
INTA 寄存器组OCWs
INT
数据总线
D7– D0 缓冲
中断屏蔽寄存器
(IMR)
A06.3 setup.S 程序
243
用于确定 IRR 中所设置比特位的优先级，选通最高优先级的中断请求到正在服务寄存器 ISR（ In-Service
Register）中。 ISR 中保存着正在接受服务的中断请求。控制逻辑方框中的寄存器组用于接受 CPU 产生
的两类命令。在 8259A 可以正常操作之前，必须首先设置初始化命令字 ICW（ Initialization Command Words）
寄存器组的内容。而在其工作过程中，则可以使用写入操作命令字 OCW（ Operation Command Words）
寄存器组来随时设置和管理 8259A 的工作方式。 A0 线用于选择操作的寄存器。在 PC/AT 微机系统中，
当 A0 线为 0 时芯片的端口地址是 0x20 和 0xA0（从芯片），当 A0=1 时端口就是 0x21 和 0xA1。
来自各个设备的中断请求线分别连接到 8259A 的 IR0—IR7 中断请求引脚上。当这些引脚上有一个
或多个中断请求信号到来时，中断请求寄存器 IRR 中相应的比特位被置位锁存。此时若中断屏蔽寄存器
IMR 中对应位被置位，则相应的中断请求就不会送到优先级解析器中。对于未屏蔽的中断请求被送到优
先级解析器之后，优先级最高的中断请求会被选出。此时 8259A 就会向 CPU 发送一个 INT 信号，而 CPU
则会在执行完当前的一条指令之后向 8259A 返回一个 INTA 来响应中断信号。 8259A 在收到这个响应信
号之后就会把所选出的最高优先级中断请求保存到正在服务寄存器 ISR 中，即 ISR 中对应中断请求级的
比特位被置位。与此同时，中断请求寄存器 IRR 中的对应比特位被复位，表示该中断请求开始正被处理
中。
此后， CPU 会向 8259A 发出第 2 个 INTA 脉冲信号，该信号用于通知 8259A 送出中断号。因此在该
脉冲信号期间 8259A 就会把一个代表中断号的 8 位数据发送到数据总线上供 CPU 读取。
到此为止， CPU 中断周期结束。如果 8259A 使用的是自动结束中断 AEOI （ Automatic End of Interrupt）
方式，那么在第 2 个 INTA 脉冲信号的结尾处正在服务寄存器 ISR 中的当前服务中断比特位就会被复位。
否则的话，若 8259A 处于非自动结束方式，那么在中断服务程序结束时程序就需要向 8259A 发送一个结
束中断（ EOI）命令以复位 ISR 中的比特位。如果中断请求来自接联的第 2 个 8259A 芯片，那么就需要
向两个芯片都发送 EOI 命令。此后 8259A 就会去判断下一个最高优先级的中断，并重复上述处理过程。
下面我们先给出初始化命令字和操作命令字的编程方法，然后再对其中用到的一些操作方式作进一步说
明。
2. 初始化命令字编程
可编程控制器 8259A 主要有 4 种工作方式：①全嵌套方式；②循环优先级方式；③特殊屏蔽方式和
④程序查询方式。通过对 8259A 进行编程，我们可以选定 8259A 的当前工作方式。编程时分两个阶段。
一是在 8259A 工作之前对每个 8259A 芯片 4 个初始化命令字（ ICW1—ICW4）寄存器的写入编程；二是
在工作过程中随时对 8259A 的 3 个操作命令字（ OCW1—OCW3）进行编程。在初始化之后，操作命令
字的内容可以在任何时候写入 8259A。下面我们先说明对 8259A 初始化命令字的编程操作。
初始化命令字的编程操作流程见图 6-8 所示。由图可以看出，对 ICW1 和 ICW2 的设置是必需的。
而只有当系统中包括多片 8259A 芯片并且是接连的情况下才需要对 ICW3 进行设置。这需要在 ICW1 的
设置中明确指出。另外，是否需要对 ICW4 进行设置也需要在 ICW1 中指明。6.3 setup.S 程序
244
图 6-8 8259A 初始化命令字设置顺序
(1) ICW1 当发送字节的比特位 4（ D4） =1 并且地址线 A0=0 时，表示是对 ICW1 编程。此时对于 PC/AT
微机系统的多片级联情况下， 8259A 主芯片的端口地址是 0x20，从芯片的端口地址是 0xA0。 ICW1 的格
式如表 6–5 所示。
表 6– 5 中断初始化命令字 ICW1 格式
位 名称 含义
D7 A7
A7—A5 表示在 MCS80/85 中用于中断服务过程的页面起始地址。
与 ICW2 中的 A15—A8 共同组成。这几位对 8086/88 处理器无用。
D6 A6
D5 A5
D4 恒为 1
D3 LTIM 1 - 电平触发中断方式； 0 – 边沿触发方式。
D2 ADI MCS80/85 系统用于 CALL 指令地址间隔。对 8086/88 处理器无用。
D1 SNGL 1 – 单片 8259A； 0 – 多片。
D0 IC4 1 – 需要 ICW4； 0 – 不需要。
在 Linux 0.12 内核中， ICW1 被设置为 0x11。表示中断请求是边沿触发、多片 8259A 级联并且最后
需要发送 ICW4。
(2) ICW2 用于设置芯片送出的中断号的高 5 位。在设置了 ICW1 之后，当 A0=1 时表示对 ICW2 进行设
置。此时对于 PC/AT 微机系统的多片级联情况下， 8259A 主芯片的端口地址是 0x21，从芯片的端口地址
是 0xA1。 ICW2 格式见表 6–6 所示。
表 6– 6 中断初始化命令字 ICW2 格式
A0 D7 D6 D5 D4 D3 D2 D1 D0
1 A15/T7 A14/T6 A13/T5 A12/T4 A11/T3 A10 A9 A8
在 MCS80/85 系统中，位 D7—D0 表示的 A15—A8 与 ICW1 设置的 A7-A5 组成中断服务程序页面地
N(IC4=0)
Y(IC4=1)
N(SNGL=1)
Y(SNGL=0)
设置 ICW1
设置 ICW 寄存器组
就绪，可接受中断
设置 ICW2
设置 ICW3
设置 ICW4
嵌套方式?
需要 ICW4?6.3 setup.S 程序
245
址。在使用 8086/88 处理器的系统或兼容系统中 T7—T3 是中断号的高 5 位，与 8259A 芯片自动设置的
低 3 位组成一个 8 位的中断号。 8259A 在收到第 2 个中断响应脉冲 INTA 时会送到数据总线上，以供 CPU
读取。

Linux 0.12 系统把主片的 ICW2 设置为 0x20，表示主片中断请求 0 级—7 级对应的中断号范围是
0x20—0x27。而从片的 ICW2 被设置成 0x28，表示从片中断请求 8 级—15 级对应的中断号范围是
0x28—0x2f。

(3) ICW3 用于具有多个 8259A 芯片级联时，加载 8 位的从寄存器（ Slave Register）。端口地址同上。 ICW3
格式见表 6–7 所示。

表 6– 7 中断初始化命令字 ICW3 格式

A0 D7 D6 D5 D4 D3 D2 D1 D0
主片： 1 S7 S6 S5 S4 S3 S2 S1 S0
A0 D7 D6 D5 D4 D3 D2 D1 D0
从片： 1 0 0 0 0 0 ID2 ID1 ID0

主片 S7—S0 各比特位对应级联的从片。哪位为 1 则表示主片的该中断请求引脚 IR 上信号来自从片，
否则对应的 IR 引脚没有连从片。从片的 ID2—ID0 三个比特位对应各从片的标识号，即连接到主片的中
断级。当某个从片接收到级联线（ CAS2—CAS0）输入的值与自己的 ID2—ID0 相等时，则表示此从片被
选中。此时该从片应该向数据总线发送从片当前选中中断请求的中断号。

Linux 0.12 内核把 8259A 主片的 ICW3 设置为 0x04，即 S2=1，其余各位为 0。表示主芯片的 IR2 引
脚连接一个从芯片。从芯片的 ICW3 被设置为 0x02，即其标识号为 2。表示从片连接到主片的 IR2 引脚。
因此，中断优先级的排列次序为 0 级最高，接下来是从片上的 8—15 级，最后是 3—7 级。

(4) ICW4 当 ICW1 的位 0（ IC4）置位时，表示需要 ICW4。地址线 A0=1。端口地址同上说明。 ICW4
格式见表 6–8 所示。

表 6– 8 中断初始化命令字 ICW4 格式

位 名称 含义
D7-5 恒为 0
D4 SFNM 1 – 选择特殊全嵌套方式； 0 – 普通全嵌套方式。
D3 BUF 1 – 缓冲方式； 0 – 非缓冲方式。
D2 M/S 1 – 缓冲方式下主片； 0 – 缓冲方式下从片。
D1 AEOI 1 – 自动结束中断方式； 0 – 非自动结束方式。
D0 μ PM 1 – 8086/88 处理器系统； 0 – MCS80/85 系统。
Linux 0.12 内核送往 8259A 主芯片和从芯片的 ICW4 命令字的值均为 0x01。表示 8259A 芯片被设置
成普通全嵌套、非缓冲、非自动结束中断方式，并且用于 8086 及其兼容系统。

3. 操作命令字编程

在对 8259A 设置了初始化命令字寄存器后，芯片就已准备好接收设备的中断请求信号了。但在 8259A
工作期间，我们也可以利用操作命令字 OCW1—OCW3 来监测 8259A 的工作状况，或者随时改变初始化
时设定的 8259A 的工作方式。 对这 3 个操作命令字的访问寻址由地址线 A0 和 D4D3 两位组成：当 A0=16.3 setup.S 程序
246
时，访问的是 OCW1；当 A0=0， D4D3=00 时，是 OCW2；当 A=0， D4D3=01 时，是 OCW3。

(1) OCW1 用于对 8259A 中中断屏蔽寄存器 IMR 进行读/写操作。地址线 A0 需为 1。端口地址说明同上。
OCW1 格式见表 6–9 所示。

表 6– 9 中断操作命令字 OCW1 格式

A0 D7 D6 D5 D4 D3 D2 D1 D0
1 M7 M6 M5 M4 M3 M2 M1 M0

位 D7—D0 对应 8 个中断请求 7 级—0 级的屏蔽位 M7—M0。若 M=1，则屏蔽对应中断请求级；若
M=0，则允许对应的中断请求级。另外，屏蔽高优先级并不会影响其他低优先级的中断请求。

在 Linux 0.12 内核初始化过程中，代码在设置好相关的设备驱动程序后就会利用该操作命令字来修
改相关中断请求屏蔽位。例如在软盘驱动程序初始化结束时，为了允许软驱设备发出中断请求，就会读
端口 0x21 以取得 8259A 芯片的当前屏蔽字节，然后与上~0x40 来复位对应软盘控制器连接的中断请求 6
的屏蔽位，最后再写回中断屏蔽寄存器中。参见 kernel/blk_drv/floppy.c 程序第 461 行。

(2) OCW2 用于发送 EOI 命令或设置中断优先级的自动循环方式。当比特位 D4D3 = 00，地址线 A0=0
时表示对 OCW2 进行编程设置。操作命令字 OCW2 的格式见表 6–10 所示。

表 6– 10 中断操作命令字 OCW2 格式

位 名称 含义
D7 R 优先级循环状态。
D6 SL 优先级设定标志。
D5 EOI 非自动结束标志。
D4-3 恒为 0。
D2 L2
L2—L0 3 位组成级别号，分别对应中断请求级别 IRQ0--IRQ7 （或
IRQ8—IRQ15）。
D1 L1
D0 L0
其中位 D7—D5 的组合的作用和含义见表 6–11 所示。其中带有*号者可通过设置 L2--L0 来指定优先级使
ISR 复位，或者选择特殊循环优先级成为当前最低优先级。
表 6– 11 操作命令字 OCW2 的位 D7--D5 组合含义
R(D7) SL(D6) EOI(D5) 含义 类型
0 0 1 非特殊结束中断 EOI 命令（全嵌套方式）。
结束中断
0 1 1 *特殊结束中断 EOI 命令（非全嵌套方式）。
1 0 1 非特殊结束中断 EOI 命令时循环。
1 0 0 自动结束中断 AEOI 方式时循环（设置）。 优先级自动循环
0 0 0 自动结束中断 AEOI 方式时循环（清除）。
1 1 1 *特殊结束中断 EOI 命令时循环。
特殊循环
1 1 0 *设置优先级命令。
0 1 0 无操作。

Linux 0.12 内核仅使用该操作命令字在中断处理过程结束之前向 8259A 发送结束中断 EOI 命令。所6.3 setup.S 程序
247
使用的 OCW2 值为 0x20，表示全嵌套方式下的非特殊结束中断 EOI 命令。

(3) OCW3 用于设置特殊屏蔽方式和读取寄存器状态（ IRR 和 ISR）。当 D4D3=01、地址线 A0=0 时，表
示对 OCW3 进行编程（读/写）。但在 Linux 0.12 内核中并没有用到该操作命令字。 OCW3 的格式见表 6–12
所示。

表 6– 12 中断操作命令字 OCW3 格式

位 名称 含义
D7 恒为 0。
D6 ESMM 对特殊屏蔽方式操作。
D5 SMM D6—D5 为 11 – 设置特殊屏蔽； 10 – 复位特殊屏蔽。
D4 恒为 0。
D3 恒为 1。
D2 P 1 – 查询（ POLL）命令； 0 – 无查询命令。
D1 RR 在下一个 RD 脉冲时读寄存器状态。
D0 RIS D1—D0 为 11 – 读正在服务寄存器 ISR； 10 – 读中断请求寄存器 IRR。

4. 8259A 操作方式说明

在说明 8259A 初始化命令字和操作命令字的编程过程中，提及了 8259A 的一些工作方式。下面对几
种常见的方式给出详细说明，以便能更好地理解 8259A 芯片的运行方式。

(1) 全嵌套方式

在初始化之后，除非使用了操作命令字改变过 8259A 的工作方式，否则它会自动进入这种全嵌套工
作方式。在这种工作方式下，中断请求优先级的秩序是从 0 级到 7 级（ 0 级优先级最高）。当 CPU 响应
一个中断，那么最高优先级中断请求就被确定，并且该中断请求的中断号会被放到数据总线上。另外，
正在服务寄存器 ISR 的相应比特位会被置位，并且该比特位的置位状态将一直保持到从中断服务过程返
回之前发送结束中断 EOI 命令为止。如果在 ICW4 命令字中设置了自动中断结束 AEOI 比特位，那么 ISR
中的比特位将会在 CPU 发出第 2 个中断响应脉冲 INTA 的结束边沿被复位。在 ISR 有置位比特位期间，
所有相同优先级和低优先级的中断请求将被暂时禁止，但允许更高优先级中断请求得到响应和处理。再
者，中断屏蔽寄存器 IMR 的相应比特位可以分别屏蔽 8 级中断请求，但屏蔽任意一个中断请求并不会影
响其他中断请求的操作。最后，在初始化命令字编程之后， 8259A 引脚 IR0 具有最高优先级，而 IR7 的
优先级最低。 Linux 0.12 内核代码即把系统的 8259A 芯片设置工作在这个方式下。

(2) 中断结束（ EOI）方法

如上所述，正在服务寄存器 ISR 中被处理中断请求对应的比特位可使用两种方式来复位。其一是当
ICW4 中的自动中断结束 AEOI 比特位置位时，通过在 CPU 发出的第 2 个中断响应脉冲 INTA 的结束边
沿被复位。这种方法称为自动中断结束（ AEOI）方法。其二是在从中断服务过程返回之前发送结束中断
EOI 命令来复位。这种方法称为程序中断结束（ EOI）方法。在级联系统中，从片中断服务程序需要发
送两个 EOI 命令，一个用于从片，另一个用于主片。

程序发出 EOI 命令的方法有两种格式。一种称为特殊 EOI 命令，另一种称为非特殊 EOI 命令。特殊
的 EOI 命令用于非全嵌套方式下，可用于指定 EOI 命令具体复位的中断级比特位。即在向芯片发送特殊
EOI 命令时需要指定被复位的 ISR 中的优先级。特殊 EOI 命令使用操作命令字 OCW2 发送，高 3 比特位
是 011，最低 3 位用来指定优先级。在目前的 Linux 系统中就使用了这种特殊 EOI 命令。用于全嵌套方
式的非特殊 EOI 命令会自动地把当前正在服务寄存器 ISR 中最高优先级比特位复位。因为在全嵌套方式
下 ISR 中最高优先级比特位肯定是最后响应和服务的优先级。它也使用 OCW2 来发出，但最高 3 比特位
需要为 001。本书讨论的 Linux 0.12 系统中则使用了这种非特殊 EOI 命令。

(3) 特殊全嵌套方式

在 ICW4 中设置的特殊全嵌套方式（ D4=1）主要用于级联的大系统中，并且每个从片中的优先级需
要保存。这种方式与上述普通全嵌套方式相似，但有以下两点例外：

A. 当从某个从片发出的中断请求正被服务时，该从片并不会被主片的优先级排除。因此该从片发出
的其他更高优先级中断请求将被主片识别，主片会立刻向 CPU 发出中断。而在上述普通全嵌套方式中，
当一个从片中断请求正在被服务时，该从片会被主片屏蔽掉。因此从该从片发出的更高优先级中断请求
就不能被处理。

B. 当退出中断服务程序时，程序必须检查当前中断服务是否是从片发出的唯一一个中断请求。检查
的方法是先向从片发出一个非特殊中断结束 EOI 命令，然后读取其正在服务寄存器 ISR 的值。检查此时
该值是否为 0。如果是 0，则表示可以再向主片发送一个非特殊 EOI 命令。若不为 0，则无需向主片发送
EOI 命令。

(4) 多片级联方式

8259A 可以被很容易地连接成一个主片和若干个从片组成的系统。若使用 8 个从片那么最多可控制
64 个中断优先级。主片通过 3 根级联线来控制从片。这 3 根级联线相当于从片的选片信号。在级联方式
中，从片的中断输出端被连接到主片的中断请求输入引脚上。当从片的一个中断请求线被处理并被响应
时，主片会选择该从片把相应的中断号放到数据总线上。

在级联统中，每个 8259A 芯片必须独立地进行初始化，并且可以工作在不同方式下。另外，要分别
对主片和从片的初始化命令字 ICW3 进行编程。在操作过程中也需要发送 2 个中断结束 EOI 命令。一个
用于主片，另一个用于从片。

(5) 自动循环优先级方式

当我们在管理优先级相同的设备时，就可以使用 OCW2 把 8259A 芯片设置成自动循环优先级方式。
即在一个设备接受服务后，其优先级自动变成最低的。优先级依次循环变化。最不利的情况是当一个中
断请求来到时需要等待它之前的 7 个设备都接受了服务之后才能得到服务。

(6) 中断屏蔽方式

中断屏蔽寄存器 IMR 可以控制对每个中断请求的屏蔽。 8259A 可设置两种屏蔽方式。对于一般普通
屏蔽方式，使用 OCW1 来设置 IMR。 IMR 的各比特位（ D7--D0）分别作用于各个中断请求引脚 IR7 -- IR0。
屏蔽一个中断请求并不会影响其他优先级的中断请求。对于一个中断请求在响应并被服务期间（没有发
送 EOI 命令之前），这种普通屏蔽方式会使得 8259A 屏蔽所有低优先级的中断请求。但有些应用场合可
能需要中断服务过程能动态地改变系统的优先级。为了解决这个问题， 8259A 中引进了特殊屏蔽方式。
我们需要使用 OCW3 首先设置这种方式（ D6、 D5 比特位）。在这种特殊屏蔽方式下， OCW1 设置的屏
蔽信息会使所有未被屏蔽的优先级中断均可以在某个中断过程中被响应。

(7) 读寄存器状态

8259A 中有 3 个寄存器（ IMR、 IRR 和 ISR）可让 CPU 读取其状态。 IMR 中的当前屏蔽信息可以通
过直接读取 OCW1 来得到。在读 IRR 或 ISR 之前则需要首先使用 OCW3 输出读取 IRR 或 ISR 的命令，
然后才可以进行读操作6.3 setup.S 程序
220
0x90080 16 硬盘参数表 第 1 个硬盘的参数表
0x90090 16 硬盘参数表 第 2 个硬盘的参数表（如果没有，则清零）
0x901FC 2 根设备号 根文件系统所在的设备号（ bootsec.s 中设置）

然后 setup 程序将 system 模块从 0x10000-0x8ffff 整块向下移动到内存绝对地址 0x00000 处（当时认
为内核系统模块 system 的长度不会超过此值： 512KB）。接下来加载中断描述符表寄存器(IDTR)和全局
描述符表寄存器(GDTR)，开启 A20 地址线，重新设置两个中断控制芯片 8259A，将硬件中断号重新设
置为 0x20 - 0x2f。最后设置 CPU 的控制寄存器 CR0（也称机器状态字），进入 32 位保护模式运行，并跳
转到位于 system 模块最前面部分的 head.s 程序继续运行。

为了能让 head.s 在 32 位保护模式下运行，在本程序中临时设置了中断描述符表（ IDT） 和全局描述
符表（ GDT），并在 GDT 中设置了当前内核代码段的描述符和数据段的描述符。下面在 head.s 程序中还
会根据内核的需要重新设置这些描述符表。

下面我们再复习一下段描述符的格式、描述符表的结构和段选择符（有些书中称之为选择子）的格
式。 Linux 内核代码中用到的代码段、数据段描述符的格式见图 6-4 所示。其中各字段的详细含义请参见
第 4 章中的说明。

图 6-4 程序代码段和数据段的描述符格式

段描述符存放在描述符表中。描述符表其实就是内存中描述符项的一个阵列。描述符表有两类：全
局描述符表（ Global descriptor table – GDT） 和局部描述符表（ Local descriptor table – LDT）。处理器是通
过使用 GDTR 和 LDTR 寄存器来定位 GDT 表和当前的 LDT 表。这两个寄存器以线性地址的方式保存了
A -- 已访问
AVL -- 软件可用位
B -- 默认大小
C -- 一致代码段
31 16 15 0
31 12 11 8 7 0
基地址
Base 23..16
基地址
Base 31..24
TYPE
24 23 22 21 20 19 16 15 14 13
G B 0 P
A V L
段限长
19..16 DPL 1
段限长
Segment Limit 15..0
基地址
Base Address 15..0 0
4 / W / W
31 16 15 0
31 12 11 8 7 0
基地址
Base 23..16
基地址
Base 31..24
TYPE
24 23 22 21 20 19 16 15 14 13
G D 0 P
A V L
段限长
19..16 DPL 1
段限长
Segment Limit 15..0
基地址
Base Address 15..0 0
4 / W / W
数据段描述符
代码段描述符
0 E W A
1 C R A
D -- 默认值
DPL -- 描述符特权级
E -- 扩展方向
G -- 颗粒度
R -- 可读
LIMIT -- 段限长
W -- 可写
P -- 存在6.3 setup.S 程序
221
描述符表的基地址和表的长度。指令 LGDT 和 SGDT 用于访问 GDTR 寄存器；指令 LLDT 和 SLDT 用
于访问 LDTR 寄存器。 LGDT 使用内存中一个 6 字节操作数来加载 GDTR 寄存器。头两个字节代表描述
符表的长度，后 4 个字节是描述符表的基地址。然而请注意，访问 LDTR 寄存器的指令 LLDT 所使用的
操作数却是一个 2 字节的操作数，表示全局描述符表 GDT 中一个描述符项的选择符。该选择符所对应
的 GDT 表中的描述符项应该对应一个局部描述符表。

例如， setup.S 程序设置的 GDT 描述符项（见程序第 567--578 行），代码段描述符的值是
0x00C09A00000007FF（即： 0x07FF, 0x0000, 0x9A00, 0x00C0），表示代码段的限长是 8MB（ =(0x7FF + 1)
* 4KB，这里加 1 是因为限长值是从 0 开始算起的），段在线性地址空间中的基址是 0，段类型值 0x9A
表示该段存在于内存中、段的特权级别为 0、段类型是可读可执行的代码段，段代码是 32 位的并且段的
颗粒度是 4KB。数据段描述符的值是 0x00C09200000007FF（即： 0x07FF, 0x0000, 0x9200, 0x00C0），表
示数据段的限长是 8MB，段在线性地址空间中的基址是 0，段类型值 0x92 表示该段存在于内存中、段
的特权级别为 0、段类型是可读可写的数据段，段代码是 32 位的并且段的颗粒度是 4KB。

这里再对选择符进行一些说明。选择符部分用于指定一个段描述符，它是通过指定一描述符表并且
索引其中的一个描述符项完成的。 图 6-5 示出了选择符的格式。

图 6-5 段选择符格式

其中索引值（ Index）用于选择指定描述符表中 8192（ 213） 个描述符中的一个。处理器将该索引值乘上 8，
并加上描述符表的基地址即可访问表中指定的段描述符。表指示器（ Table Indicator - TI）用于指定选择
符所引用的描述符表。值为 0 表示指定 GDT 表，值为 1 表示指定当前的 LDT 表。请求者特权级（ Requestor's
Privalege Level - RPL）用于保护机制。

由于 GDT 表的第一项(索引值为 0)没有被使用，因此一个具有索引值 0 和表指示器值也为 0 的选择
符（也即指向 GDT 的第一项的选择符）可以用作为一个空(null)选择符。当一个段寄存器（不能是 CS
或 SS）加载了一个空选择符时，处理器并不会产生一个异常。但是若使用这个段寄存器访问内存时就会
产生一个异常。对于初始化还未使用的段寄存器,使得对其意外的引用能产生一个指定的异常这种应用来
说，这样的特性很有用。

在进入保护模式之前，我们必须首先设置好将要用到的段描述符表，例如全局描述符表 GDT。然后
使用指令 lgdt 把描述符表的基地址告知 CPU（ GDT 表的基地址存入 gdtr 寄存器）。再将机器状态字的保
护模式标志置位即可进入 32 位保护运行模式。

另外， setup.S 程序第 215--566 行代码用于识别机器中使用的显示卡类别。如果系统使用 VGA 显示
卡，那么我们就检查一下显示卡是否支持超过 25 行 x 80 列的扩展显示模式（或显示方式）。所谓显示模
式是指 ROM BIOS 中断 int 0x10 的功能 0（ ah=0x00） 设置屏幕显示信息的方法，其中 al 寄存器中的输
入参数值即是我们要设置的显示模式或显示方式号。通常我们把 IBM PC 机刚推出时所能设置的几种显
示模式称为标准显示模式，而以后添加的一些则被称为扩展显示模式。例如 ATI 显示卡除支持标准显示
模式以外，还支持扩展显示模式号 0x23、 0x33，即还能够使用 132 列 x 25 行和 132 列 x 44 行两种显示
模式在屏幕上显示信息。在 VGA、 SVGA 刚出现时期，这些扩展显示模式均由显示卡上的 BIOS 提供支
持。若识别出一块已知类型的显示卡，程序就会向用户提供选择分辨率的机会。

但由于这段程序涉及很多显示卡各自特有的端口信息，因此这段程序比较复杂。好在这段代码与内
核运行原理关系不大，因此可以跳过不看。如果想彻底理解这段代码，那么在阅读这段代码时最好能参
15 3 2 1 0
描述符索引 TI RPL6.3 setup.S 程序
222
考 Richard F.Ferraro 的书《Programmer's Guide to the EGA, VGA, and Super VGA Cards》，或者参考网上能
下载到的经典 VGA 编程资料“VGADOC4”。这段程序由 Mats Andersson (d88-man@nada.kth.se)编制，
现在 Linus 已忘记 d88-man 是谁了:-)。

6.3.2代码注释

程序 6-2 linux/boot/setup.S

```asm
1 !
2 ! setup.s (C) 1991 Linus Torvalds
3 !
4 ! setup.s is responsible for getting the system data from the BIOS,
5 ! and putting them into the appropriate places in system memory.
6 ! both setup.s and system has been loaded by the bootblock.
7 !
8 ! This code asks the bios for memory/disk/other parameters, and
9 ! puts them in a "safe" place: 0x90000-0x901FF, ie where the
10 ! boot-block used to be. It is then up to the protected mode
11 ! system to read them from there before the area is overwritten
12 ! for buffer-blocks.
13 !
! setup.s 负责从 BIOS 中获取系统数据，并将这些数据放到系统内存的适当
! 地方。此时 setup.s 和 system 已经由 bootsect 引导块加载到内存中。
!
! 这段代码询问 bios 有关内存/磁盘/其他参数，并将这些参数放到一个
! “安全的”地方： 0x90000-0x901FF，也即原来 bootsect 代码块曾经在
! 的地方，然后在被缓冲块覆盖掉之前由保护模式的 system 读取。
14
15 ! NOTE! These had better be the same as in bootsect.s!
! 以下这些参数最好和 bootsect.s 中的相同！
16 #include <linux/config.h>
! config.h 中定义了 DEF_INITSEG = 0x9000； DEF_SYSSEG = 0x1000； DEF_SETUPSEG = 0x9020。
17
18 INITSEG = DEF_INITSEG ! we move boot here - out of the way ! 原来 bootsect 所处的段。
19 SYSSEG = DEF_SYSSEG ! system loaded at 0x10000 (65536). ! system 在 0x10000 处。
20 SETUPSEG = DEF_SETUPSEG ! this is the current segment ! 本程序所在的段地址。
21
22 .globl begtext, begdata, begbss, endtext, enddata, endbss
23 .text
24 begtext:
25 .data
26 begdata:
27 .bss
28 begbss:
29 .text
30
31 entry start
32 start:
33
34 ! ok, the read went well so we get current cursor position and save it for6.3 setup.S 程序
223
35 ! posterity.
! ok，整个读磁盘过程都正常，现在将光标位置保存以备今后使用（相关代码在 59--62 行）。
36
! 下句将 ds 置成 INITSEG(0x9000)。这已经在 bootsect 程序中设置过，但是现在是 setup 程序，
! Linus 觉得需要再重新设置一下。
37 mov ax,#INITSEG
38 mov ds,ax
39
40 ! Get memory size (extended mem, kB)
! 取扩展内存的大小值（ KB）。
! 利用 BIOS 中断 0x15 功能号 ah = 0x88 取系统所含扩展内存大小并保存在内存 0x90002 处。
! 返回： ax = 从 0x100000（ 1M）处开始的扩展内存大小(KB)。若出错则 CF 置位， ax = 出错码。
41
42 mov ah,#0x88
43 int 0x15
44 mov [2],ax ! 将扩展内存数值存在 0x90002 处（ 1 个字）。
45
46 ! check for EGA/VGA and some config parameters
! 检查显示方式（ EGA/VGA）并取参数。
! 调用 BIOS 中断 0x10 功能号 0x12（ 视频子系统配置）取 EBA 配置信息。
! ah = 0x12， bl = 0x10 - 取 EGA 配置信息。
! 返回：
! bh =显示状态(0x00 -彩色模式， I/O 端口=0x3dX； 0x01 -单色模式， I/O 端口=0x3bX)。
! bl = 安装的显示内存(0x00 - 64k； 0x01 - 128k； 0x02 - 192k； 0x03 = 256k。 )
! cx = 显示卡特性参数(参见程序后对 BIOS 视频中断 0x10 的说明)。
47
48 mov ah,#0x12
49 mov bl,#0x10
50 int 0x10
51 mov [8],ax ! 0x90008 = ??
52 mov [10],bx ! 0x9000A =安装的显示内存； 0x9000B=显示状态(彩/单色)
53 mov [12],cx ! 0x9000C =显示卡特性参数。
! 检测屏幕当前行列值。若显示卡是 VGA 卡时则请求用户选择显示行列值，并保存到 0x9000E 处。
54 mov ax,#0x5019 ! 在 ax 中预置屏幕默认行列值（ ah = 80 列； al=25 行）。
55 cmp bl,#0x10 ! 若中断返回 bl 值为 0x10，则表示不是 VGA 显示卡，跳转。
56 je novga
57 call chsvga ! 检测显示卡厂家和类型，修改显示行列值（第 215 行）。
58 novga: mov [14],ax ! 保存屏幕当前行列值（ 0x9000E， 0x9000F）。
! 使用 BIOS 中断 0x10 功能 0x03 取屏幕当前光标位置，并保存在内存 0x90000 处（ 2 字节）。
! 控制台初始化程序 console.c 会到此处读取该值。
! BIOS 中断 0x10 功能号 ah = 0x03， 读光标位置。
! 输入： bh = 页号
! 返回： ch = 扫描开始线； cl = 扫描结束线； dh = 行号(0x00 顶端)； dl = 列号(0x00 最左边)。
59 mov ah,#0x03 ! read cursor pos
60 xor bh,bh
61 int 0x10 ! save it in known place, con_init fetches
62 mov [0],dx ! it from 0x90000.
63
64 ! Get video-card data:
! 下面这段用于取显示卡当前显示模式。
! 调用 BIOS 中断 0x10，功能号 ah = 0x0f。
! 返回： ah = 字符列数； al = 显示模式； bh = 当前显示页。6.3 setup.S 程序
224
! 0x90004(1 字)存放当前页； 0x90006 存放显示模式； 0x90007 存放字符列数。
65
66 mov ah,#0x0f
67 int 0x10
68 mov [4],bx ! bh = display page
69 mov [6],ax ! al = video mode, ah = window width
70
71 ! Get hd0 data
! 取第一个硬盘的信息（复制硬盘参数表）。
! 第 1 个硬盘参数表的首地址竟然是中断 0x41 的中断向量值！而第 2 个硬盘参数表紧接在第 1 个
! 表的后面，中断 0x46 的向量向量值也指向第 2 个硬盘的参数表首址。表的长度是 16 个字节。
! 下面两段程序分别复制 ROM BIOS 中有关两个硬盘参数表到： 0x90080 处存放第 1 个硬盘的表，
! 0x90090 处存放第 2 个硬盘的表。 有关硬盘参数表内容说明，请参见 6.3.3 节的表 6-4。
72
! 第 75 行语句从内存指定位置处读取一个长指针值， 并放入 ds 和 si 寄存器。 ds 中放段地址，
! si 是段内偏移地址。这里是把内存地址 4 * 0x41（ = 0x104） 处保存的 4 个字节读出。 这 4 字
! 节即是硬盘参数表所处位置的段和偏移值。
73 mov ax,#0x0000
74 mov ds,ax
75 lds si,[4*0x41] ! 取中断向量 0x41 的值，即 hd0 参数表的地址ds:si
76 mov ax,#INITSEG
77 mov es,ax
78 mov di,#0x0080 ! 传输的目的地址: 0x9000:0x0080  es:di
79 mov cx,#0x10 ! 共传输 16 字节。
80 rep
81 movsb
82
83 ! Get hd1 data
84
85 mov ax,#0x0000
86 mov ds,ax
87 lds si,[4*0x46] ! 取中断向量 0x46 的值，即 hd1 参数表的地址ds:si
88 mov ax,#INITSEG
89 mov es,ax
90 mov di,#0x0090 ! 传输的目的地址: 0x9000:0x0090  es:di
91 mov cx,#0x10
92 rep
93 movsb
94
95 ! Check that there IS a hd1 :-)
! 检查系统是否有第 2 个硬盘。如果没有则把第 2 个表清零。
! 利用 BIOS 中断调用 0x13 的取盘类型功能，功能号 ah = 0x15；
! 输入： dl = 驱动器号（ 0x8X 是硬盘： 0x80 指第 1 个硬盘， 0x81 第 2 个硬盘）
! 输出： ah = 类型码； 00 - 没有这个盘， CF 置位； 01 - 是软驱，没有 change-line 支持；
! 02 - 是软驱(或其他可移动设备)，有 change-line 支持； 03 - 是硬盘。
96
97 mov ax,#0x01500
98 mov dl,#0x81
99 int 0x13
100 jc no_disk1
101 cmp ah,#3 ! 是硬盘吗？ (类型 = 3 ？ )。
102 je is_disk1
103 no_disk1:6.3 setup.S 程序
225
104 mov ax,#INITSEG ! 第 2 个硬盘不存在，则对第 2 个硬盘表清零。
105 mov es,ax
106 mov di,#0x0090
107 mov cx,#0x10
108 mov ax,#0x00
109 rep
110 stosb
111 is_disk1:
112
113 ! now we want to move to protected mode ...
! 现在我们要进入保护模式中了...
114
115 cli ! no interrupts allowed ! ! 从此开始不允许中断。
116
117 ! first we move the system to it's rightful place
! 首先我们将 system 模块移到正确的位置。
! bootsect 引导程序会把 system 模块读入到内存 0x10000（ 64KB） 开始的位置。由于当时假设
! system 模块最大长度不会超过 0x80000（ 512KB） ，即其末端不会超过内存地址 0x90000，所以
! bootsect 会把自己移动到 0x90000 开始的地方，并把 setup 加载到它的后面。下面这段程序的
! 用途是再把整个 system 模块移动到 0x00000 位置，即把从 0x10000 到 0x8ffff 的内存数据块
! （ 512KB）整块地向内存低端移动了 0x10000（ 64KB） 字节。
118
119 mov ax,#0x0000
120 cld ! 'direction'=0, movs moves forward
121 do_move:
122 mov es,ax ! destination segment ! es:di 是目的地址(初始为 0x0:0x0)
123 add ax,#0x1000
124 cmp ax,#0x9000 ! 已经把最后一段（从 0x8000 段开始的 64KB）代码移动完？
125 jz end_move ! 是，则跳转。
126 mov ds,ax ! source segment ! ds:si 是源地址(初始为 0x1000:0x0)
127 sub di,di
128 sub si,si
129 mov cx,#0x8000 ! 移动 0x8000 字（ 64KB 字节）。
130 rep
131 movsw
132 jmp do_move
133
134 ! then we load the segment descriptors
! 此后，我们加载段描述符。
! 从这里开始会遇到 32 位保护模式的操作。 有关这方面的信息请参阅第 4 章。在进入保护模式
! 中运行之前，我们需要首先设置好需要使用的段描述符表。这里需要设置全局描述符表 GDT 和
! 中断描述符表 IDT。下面指令 LIDT 用于加载中断描述符表寄存器。它的操作数（ idt_48） 有
! 6 字节。前 2 字节(字节 0-1）是描述符表的字节长度值；后 4 字节（字节 2-5）是描述符表的
! 32 位线性基地址， 其形式参见下面 580--586 行说明。中断描述符表中的每一个 8 字节表项指
! 出发生中断时需要调用的代码信息。与中断向量有些相似，但要包含更多的信息。
!
! LGDT 指令用于加载全局描述符表寄存器，其操作数格式与 LIDT 指令的相同。全局描述符表中
! 的每个描述符项（ 8 字节）描述了保护模式下数据段和代码段（块）的信息。 其中包括段的
! 最大长度限制（ 16 位）、段的线性地址基址（ 32 位）、段的特权级、段是否在内存、读写许可
! 权以及其他一些保护模式运行的标志。参见后面 567--578 行。
135
136 end_move:
137 mov ax,#SETUPSEG ! right, forgot this at first. didn't work :-)6.3 setup.S 程序
226
138 mov ds,ax ! ds 指向本程序(setup)段。
139 lidt idt_48 ! load idt with 0,0 ! 加载 IDT 寄存器。
140 lgdt gdt_48 ! load gdt with whatever appropriate ! 加载 GDT 寄存器。
141
142 ! that was painless, now we enable A20
! 以上的操作很简单，现在我们开启 A20 地址线。
! 为了能够访问和使用 1MB 以上的物理内存，我们需要首先开启 A20 地址线。参见本程序列表后
! 有关 A20 信号线的说明。关于所涉及的一些端口和命令，可参考 kernel/chr_drv/keyboard.S
! 程序后对键盘接口的说明。至于机器是否真正开启了 A20 地址线，我们还需要在进入保护模式
! 之后（能访问 1MB 以上内存之后）在测试一下。这个工作放在了 head.S 程序中（ 32--36 行）。
143
144 call empty_8042 ! 测试 8042 状态寄存器，等待输入缓冲器空。
! 只有当输入缓冲器为空时才可以对其执行写命令。
145 mov al,#0xD1 ! command write ! 0xD1 命令码-表示要写数据到
146 out #0x64,al ! 8042 的 P2 端口。 P2 端口位 1 用于 A20 线的选通。
147 call empty_8042 ! 等待输入缓冲器空，看命令是否被接受。
148 mov al,#0xDF ! A20 on ! 选通 A20 地址线的参数。
149 out #0x60,al ! 数据要写到 0x60 口。
150 call empty_8042 ! 若此时输入缓冲器为空，则表示 A20 线已经选通。
151
152 ! well, that went ok, I hope. Now we have to reprogram the interrupts :-(
153 ! we put them right after the intel-reserved hardware interrupts, at
154 ! int 0x20-0x2F. There they won't mess up anything. Sadly IBM really
155 ! messed this up with the original PC, and they haven't been able to
156 ! rectify it afterwards. Thus the bios puts interrupts at 0x08-0x0f,
157 ! which is used for the internal hardware interrupts as well. We just
158 ! have to reprogram the 8259's, and it isn't fun.
159
! 希望以上一切正常。现在我们必须重新对中断进行编程 :-( 我们将它们放在正好
! 处于 Intel 保留的硬件中断后面，即 int 0x20--0x2F。在那里它们不会引起冲突。
! 不幸的是 IBM 在原 PC 机中搞糟了，以后也没有纠正过来。 如此 PC 机 BIOS 把中断
! 放在了 0x08--0x0f，这些中断也被用于内部硬件中断。所以我们就必须重新对 8259
! 中断控制器进行编程，这一点都没意思。
!
! PC 机使用 2 个可编程中断控制器 8259A 芯片，关于 8259A 的编程方法请参见本程序后的介绍。
! 第 162 行上定义的两个字（ 0x00eb）是直接使用机器码表示的两条相对跳转指令，起延时作用。
! 0xeb 是直接近跳转指令的操作码，带 1 个字节的相对位移值。因此跳转范围是-127 到 127。 CPU
! 通过把这个相对位移值加到 EIP 寄存器中就形成一个新的有效地址。 执行时所花费的 CPU 时钟
! 周期数是 7 至 10 个。 0x00eb 表示跳转位移值是 0 的一条指令，因此还是直接执行下一条指令。
! 这两条指令共可提供 14--20 个 CPU 时钟周期的延迟时间。 因为在 as86 中没有表示相应指令的助
! 记符， 因此 Linus 在一些汇编程序中就直接使用机器码来表示这种指令。另外， 每个空操作指令
! NOP 的时钟周期数是 3 个，因此若要达到相同的延迟效果就需要 6 至 7 个 NOP 指令。
!
! 8259 芯片主片端口是 0x20-0x21，从片端口是 0xA0-0xA1。输出值 0x11 表示初始化命令开始，
! 它是 ICW1 命令字，表示边沿触发、多片 8259 级连、最后要发送 ICW4 命令字。
160 mov al,#0x11 ! initialization sequence
161 out #0x20,al ! send it to 8259A-1 ! 发送到 8259A 主芯片。
162 .word 0x00eb,0x00eb ! jmp $+2, jmp $+2 ! '$'表示当前指令的地址，
163 out #0xA0,al ! and to 8259A-2 ! 再发送到 8259A 从芯片。
164 .word 0x00eb,0x00eb
! Linux 系统硬件中断号被设置成从 0x20 开始。参见表 3-2：硬件中断请求信号与中断号对应表。
165 mov al,#0x20 ! start of hardware int's (0x20)
166 out #0x21,al ! 送主芯片 ICW2 命令字，设置起始中断号，要送奇端口。6.3 setup.S 程序
227
167 .word 0x00eb,0x00eb
168 mov al,#0x28 ! start of hardware int's 2 (0x28)
169 out #0xA1,al ! 送从芯片 ICW2 命令字，从芯片的起始中断号。
170 .word 0x00eb,0x00eb
171 mov al,#0x04 ! 8259-1 is master
172 out #0x21,al ! 送主芯片 ICW3 命令字，主芯片的 IR2 连从芯片 INT。
！参见代码列表后的说明。
173 .word 0x00eb,0x00eb
174 mov al,#0x02 ! 8259-2 is slave
175 out #0xA1,al ! 送从芯片 ICW3 命令字，表示从芯片的 INT 连到主芯
! 片的 IR2 引脚上。
176 .word 0x00eb,0x00eb
177 mov al,#0x01 ! 8086 mode for both
178 out #0x21,al ! 送主芯片 ICW4 命令字。 8086 模式；普通 EOI、非缓冲
! 方式，需发送指令来复位。初始化结束，芯片就绪。
179 .word 0x00eb,0x00eb
180 out #0xA1,al ！送从芯片 ICW4 命令字，内容同上。
181 .word 0x00eb,0x00eb
182 mov al,#0xFF ! mask off all interrupts for now
183 out #0x21,al ! 屏蔽主芯片所有中断请求。
184 .word 0x00eb,0x00eb
185 out #0xA1,al ！屏蔽从芯片所有中断请求。
186
187 ! well, that certainly wasn't fun :-(. Hopefully it works, and we don't
188 ! need no steenking BIOS anyway (except for the initial loading :-).
189 ! The BIOS-routine wants lots of unnecessary data, and it's less
190 ! "interesting" anyway. This is how REAL programmers do it.
191 !
192 ! Well, now's the time to actually move into protected mode. To make
193 ! things as simple as possible, we do no register set-up or anything,
194 ! we let the gnu-compiled 32-bit programs do that. We just jump to
195 ! absolute address 0x00000, in 32-bit protected mode.
!
! 哼，上面这段编程当然没劲:-(，但希望这样能工作，而且我们也不再需要乏味的 BIOS
! 了（除了初始加载:-)。 BIOS 子程序要求很多不必要的数据，而且它一点都没趣。那是
! “真正”的程序员所做的事。
!
! 好了，现在是真正开始进入保护模式的时候了。为了把事情做得尽量简单，我们并不对
! 寄存器内容进行任何设置。我们让 gnu 编译的 32 位程序去处理这些事。在进入 32 位保
! 护模式时我们仅是简单地跳转到绝对地址 0x00000 处。
196
! 下面设置并进入 32 位保护模式运行。首先加载机器状态字(lmsw-Load Machine Status Word)，
! 也称控制寄存器 CR0，其比特位 0 置 1 将导致 CPU 切换到保护模式，并且运行在特权级 0 中，即
! 当前特权级 CPL=0。此时段寄存器仍然指向与实地址模式中相同的线性地址处（在实地址模式下
! 线性地址与物理内存地址相同）。在设置该比特位后，随后一条指令必须是一条段间跳转指令以
! 用于刷新 CPU 当前指令队列。因为 CPU 是在执行一条指令之前就已从内存读取该指令并对其进行
! 解码。然而在进入保护模式以后那些属于实模式的预先取得的指令信息就变得不再有效。而一条
! 段间跳转指令就会刷新 CPU 的当前指令队列，即丢弃这些无效信息。另外，在 Intel 公司的手册
! 上建议 80386 或以上 CPU 应该使用指令“mov cr0,ax”切换到保护模式。 lmsw 指令仅用于兼容以
! 前的 286 CPU。
197 mov ax,#0x0001 ! protected mode (PE) bit ! 保护模式比特位(PE)。
198 lmsw ax ! This is it! ! 就这样加载机器状态字!6.3 setup.S 程序
228
199 jmpi 0,8 ! jmp offset 0 of segment 8 (cs) ! 跳转至 cs 段偏移 0 处。
! 我们已经将 system 模块移动到 0x00000 开始的地方，所以上句中的偏移地址是 0。而段值 8 已经
! 是保护模式下的段选择符了，用于选择描述符表和描述符表项以及所要求的特权级。段选择符长
! 度为 16 位（ 2 字节）；位 0-1 表示请求的特权级 0--3，但 Linux 操作系统只用到两级： 0 级（内
! 核级）和 3 级（用户级）；位 2 用于选择全局描述符表（ 0）还是局部描述符表(1)；位 3-15 是描
! 述符表项的索引，指出选择第几项描述符。所以段选择符 8（ 0b0000,0000,0000,1000）表示请求
! 特权级 0、使用全局描述符表 GDT 中第 2 个段描述符项，该项指出代码的基地址是 0（参见 571 行），
! 因此这里的跳转指令就会去执行 system 中的代码。
200
201 ! This routine checks that the keyboard command queue is empty
202 ! No timeout is used - if this hangs there is something wrong with
203 ! the machine, and we probably couldn't proceed anyway.
! 下面这个子程序检查键盘命令队列是否为空。这里不使用超时方法 -
! 如果这里死机，则说明 PC 机有问题，我们就没有办法再处理下去了。
!
! 只有当输入缓冲器为空时（键盘控制器状态寄存器位 1 = 0）才可以对其执行写命令。
204 empty_8042:
205 .word 0x00eb,0x00eb
206 in al,#0x64 ! 8042 status port ! 读 AT 键盘控制器状态寄存器。
207 test al,#2 ! is input buffer full? ! 测试位 1，输入缓冲器满？
208 jnz empty_8042 ! yes - loop
209 ret
210
! 注意下面 215--566 行代码牵涉到众多显示卡端口信息，因此比较复杂。但由于这段代码与内核
! 运行关系不大，因此可以跳过不看。
211 ! Routine trying to recognize type of SVGA-board present (if any)
212 ! and if it recognize one gives the choices of resolution it offers.
213 ! If one is found the resolution chosen is given by al,ah (rows,cols).
! 下面是用于识别 SVGA 显示卡（若有的话）的子程序。若识别出一块就向用户
! 提供选择分辨率的机会，并把分辨率放入寄存器 al、 ah（行、列）中返回。
!
! 下面首先显示 588 行上的 msg1 字符串（ "按<回车键>查看存在的 SVGA 模式，或按任意键继续"），
! 然后循环读取键盘控制器输出缓冲器，等待用户按键。如果用户按下回车键就去检查系统具有
! 的 SVGA 模式，并在 AL 和 AH 中返回最大行列值，否则设置默认值 AL=25 行、 AH=80 列并返回。
214
215 chsvga: cld
216 push ds ! 保存 ds 值。将在 231 行（或 490 或 492 行）弹出。
217 push cs ! 把默认数据段设置成和代码段同一个段。
218 pop ds
219 mov ax,#0xc000
220 mov es,ax ! es 指向 0xc000 段。此处是 VGA 卡上的 ROM BIOS 区。
221 lea si,msg1 ! ds:si 指向 msg1 字符串。
222 call prtstr ! 显示以 NULL 结尾的 msg1 字符串。
! 首先请注意,按键按下产生的扫描码称为接通码（ make code)，释放一个按下的按键产生的扫描码
! 称为断开码（ break code）。 下面这段程序读取键盘控制其输出缓冲器中的扫描码或命令。如果
! 收到的扫描码是比 0x82 小的接通码，那么因为 0x82 是最小的断开码值，所以小于 0x82 表示还没
! 有按键松开。如果扫描码大于 0xe0，表示收到的扫描码是扩展扫描码的前缀码。如果收到的是断
! 开码 0x9c，则表示 用户按下/松开了回车键，于是程序跳转去检查系统是否具有或支持 SVGA 模式。
! 否则就把 AX 设置为默认行列值并返回。
223 nokey: in al,#0x60 ! 读取键盘控制器缓冲中的扫描码。
224 cmp al,#0x82 ! 与最小断开码 0x82 比较。6.3 setup.S 程序
229
225 jb nokey ! 若小于 0x82， 表示还没有按键松开。
226 cmp al,#0xe0
227 ja nokey ! 若大于 0xe0，表示收到的是扩展扫描码前缀。
228 cmp al,#0x9c ! 若断开码是 0x9c，表示用户按下/松开了回车键，
229 je svga ! 于是程序跳转去检查系统是否具有 SVGA 模式。
230 mov ax,#0x5019 ! 否则设置默认行列值 AL=25 行、 AH=80 列。
231 pop ds
232 ret
! 下面根据 VGA 显示卡上的 ROM BIOS 指定位置处的特征数据串或者支持的特别功能来判断机器上
! 安装的是什么牌子的显示卡。本程序共支持 10 种显示卡的扩展功能。注意，此时程序已经在第
! 220 行把 es 指向 VGA 卡上 ROM BIOS 所在的段 0xc000（参见第 2 章）。
!
! 首先判断是不是 ATI 显示卡。我们把 ds:si 指向 595 行上 ATI 显示卡特征数据串，并把 es:si 指
! 向 VGA BIOS 中指定位置（偏移 0x31）处。该特征串共有 9 个字符（ "761295520"），我们来循环
! 比较这个特征串。如果相同则表示机器中的 VGA 卡是 ATI 牌子的，于是让 ds:si 指向该显示卡可
! 以设置的行列模式值 dscati（第 615 行），让 di 指向 ATI 卡可设置的行列个数和模式，并跳转
! 到标号 selmod（ 438 行）处进一步进行设置。
233 svga: lea si,idati ! Check ATI 'clues' ! 检查判断 ATI 显示卡的数据。
234 mov di,#0x31 ! 特征串从 0xc000:0x0031 开始。
235 mov cx,#0x09 ! 特征串有 9 个字节。
236 repe
237 cmpsb ! 如果 9 个字节都相同，表示系统中有一块 ATI 牌显示卡。
238 jne noati ! 若特征串不同则表示不是 ATI 显示卡。跳转继续检测卡。
! Ok，我们现在确定了显示卡的牌子是 ATI。于是 si 指向 ATI 显示卡可选行列值表 dscati
! di 指向扩展模式个数和扩展模式号列表 moati，然后跳转到 selmod（ 438 行）处继续处理。
239 lea si,dscati ! 把 dscati 的有效地址放入 si。
240 lea di,moati
241 lea cx,selmod
242 jmp cx
! 现在来判断是不是 Ahead 牌子的显示卡。首先向 EGA/VGA 图形索引寄存器 0x3ce 写入想访问的
! 主允许寄存器索引号 0x0f，同时向 0x3cf 端口（此时对应主允许寄存器）写入开启扩展寄存器
! 标志值 0x20。然后通过 0x3cf 端口读取主允许寄存器值，以检查是否可以设置开启扩展寄存器
! 标志。如果可以则说明是 Ahead 牌子的显示卡。注意 word 输出时 al端口 n， ah端口 n+1。
243 noati: mov ax,#0x200f ! Check Ahead 'clues'
244 mov dx,#0x3ce ! 数据端口指向主允许寄存器（ 0x0f0x3ce 端口），
245 out dx,ax ! 并设置开启扩展寄存器标志（ 0x200x3cf 端口）。
246 inc dx ! 然后再读取该寄存器，检查该标志是否被设置上。
247 in al,dx
248 cmp al,#0x20 ! 如果读取值是 0x20，则表示是 Ahead A 显示卡。
249 je isahed ! 如果读取值是 0x21，则表示是 Ahead B 显示卡。
250 cmp al,#0x21 ! 否则说明不是 Ahead 显示卡，于是跳转继续检测其余卡。
251 jne noahed
! Ok，我们现在确定了显示卡的牌子是 Ahead。于是 si 指向 Ahead 显示卡可选行列值表 dscahead，
! di 指向扩展模式个数和扩展模式号列表 moahead，然后跳转到 selmod（ 438 行）处继续处理。
252 isahed: lea si,dscahead
253 lea di,moahead
254 lea cx,selmod
255 jmp cx
! 现在来检查是不是 Chips & Tech 生产的显示卡。通过端口 0x3c3（ 0x94 或 0x46e8） 设置 VGA 允许
! 寄存器的进入设置模式标志（位 4），然后从端口 0x104 读取显示卡芯片集标识值。如果该标识值6.3 setup.S 程序
230
! 是 0xA5，则说明是 Chips & Tech 生产的显示卡。
256 noahed: mov dx,#0x3c3 ! Check Chips & Tech. 'clues'
257 in al,dx ! 从 0x3c3 端口读取 VGA 允许寄存器值，添加上进入设置模式
258 or al,#0x10 ! 标志（位 4）后再写回。
259 out dx,al
260 mov dx,#0x104 ! 在设置模式时从全局标识端口 0x104 读取显示卡芯片标识值，
261 in al,dx ! 并暂时存放在 bl 寄存器中。
262 mov bl,al
263 mov dx,#0x3c3 ! 然后把 0x3c3 端口中的进入设置模式标志复位。
264 in al,dx
265 and al,#0xef
266 out dx,al
267 cmp bl,[idcandt] ! 再把 bl 中标识值与位于 idcandt 处（第 596 行）的 Chips &
268 jne nocant ! Tech 的标识值 0xA5 作比较。如果不同则跳转比较下一种显卡。
! Ok，我们现在确定了该显示卡的牌子。于是 si 指向该品牌显示卡的可选行列值表 dsccandt， di 指向
! 扩展模式个数和扩展模式号列表 mocandt，然后跳转到 selmod（ 438 行）处继续进行设置模式操作。
269 lea si,dsccandt
270 lea di,mocandt
271 lea cx,selmod
272 jmp cx
! 现在检查是不是 Cirrus 显示卡。方法是使用 CRT 控制器索引号 0x1f 寄存器的内容来尝试禁止扩展
! 功能。该寄存器被称为鹰标（ Eagle ID） 寄存器，将其值高低半字节交换一下后写入端口 0x3c4 索
! 引的 6 号（定序/扩展）寄存器应该会禁止 Cirrus 显示卡的扩展功能。如果不会则说明不是 Cirrus
! 显示卡。因为从端口 0x3d4 索引的 0x1f 鹰标寄存器中读取的内容是鹰标值与 0x0c 索引号对应的显
! 存起始地址高字节寄存器内容异或操作之后的值，因此在读 0x1f 中内容之前我们需要先把显存起始
! 高字节寄存器内容保存后清零，并在检查后恢复之。另外，将没有交换过的 Eagle ID 值写到 0x3c4
! 端口索引的 6 号定序/扩展寄存器会重新开启扩展功能。
273 nocant: mov dx,#0x3d4 ! Check Cirrus 'clues'
274 mov al,#0x0c ! 首先向 CRT 控制寄存器的索引寄存器端口 0x3d4 写入要访问
275 out dx,al ! 的寄存器索引号 0x0c（对应显存起始地址高字节寄存器），
276 inc dx ! 然后从 0x3d5 端口读入显存起始地址高字节并暂存在 bl 中，
277 in al,dx ! 再把显存起始地址高字节寄存器清零。
278 mov bl,al
279 xor al,al
280 out dx,al
281 dec dx ! 接着向 0x3d4 端口输出索引 0x1f，指出我们要在 0x3d5 端口
282 mov al,#0x1f ! 访问读取“ Eagle ID”寄存器内容。
283 out dx,al
284 inc dx
285 in al,dx ! 从 0x3d5 端口读取“ Eagle ID”寄存器值，并暂存在 bh 中。
286 mov bh,al ! 然后把该值高低 4 比特互换位置存放到 cl 中。再左移 8 位
287 xor ah,ah ! 后放入 ch 中，而 cl 中放入数值 6。
288 shl al,#4
289 mov cx,ax
290 mov al,bh
291 shr al,#4
292 add cx,ax
293 shl cx,#8
294 add cx,#6 ! 最后把 cx 值存放入 ax 中。此时 ah 中是换位后的“ Eagle
295 mov ax,cx ! ID”值， al 中是索引号 6，对应定序/扩展寄存器。把 ah
296 mov dx,#0x3c4 ! 写到 0x3c4 端口索引的定序/扩展寄存器应该会导致 Cirrus
297 out dx,ax ! 显示卡禁止扩展功能。6.3 setup.S 程序
231
298 inc dx
299 in al,dx ! 如果扩展功能真的被禁止，那么此时读入的值应该为 0。
300 and al,al ! 如果不为 0 则表示不是 Cirrus 显示卡，跳转继续检查其他卡。
301 jnz nocirr
302 mov al,bh ! 是 Cirrus 显示卡，则利用第 286 行保存在 bh 中的“ Eagle
303 out dx,al ! ID”原值再重新开启 Cirrus 卡扩展功能。此时读取的返回
304 in al,dx ! 值应该为 1。若不是，则仍然说明不是 Cirrus 显示卡。
305 cmp al,#0x01
306 jne nocirr
! Ok，我们现在知道该显示卡是 Cirrus 牌。于是首先调用 rst3d4 子程序恢复 CRT 控制器的显示起始
! 地址高字节寄存器内容，然后让 si 指向该品牌显示卡的可选行列值表 dsccurrus， di 指向扩展模式
! 个数和扩展模式号列表 mocirrus，然后跳转到 selmod（ 438 行）处继续设置显示操作。
307 call rst3d4 ! 恢复 CRT 控制器的显示起始地址高字节寄存器内容。
308 lea si,dsccirrus
309 lea di,mocirrus
310 lea cx,selmod
311 jmp cx
! 该子程序利用保存在 bl 中的值（第 278 行）恢复 CRT 控制器的显示起始地址高字节寄存器内容。
312 rst3d4: mov dx,#0x3d4
313 mov al,bl
314 xor ah,ah
315 shl ax,#8
316 add ax,#0x0c
317 out dx,ax ! 注意，这是 word 输出！！ al 0x3d4， ah 0x3d5。
318 ret
! 现在检查系统中是不是 Everex 显示卡。方法是利用中断 int 0x10 功能 0x70（ ax =0x7000，
! bx=0x0000）调用 Everex 的扩展视频 BIOS 功能。对于 Everes 类型显示卡，该中断调用应该
! 会返回模拟状态，即有以下返回信息：
! al = 0x70，若是基于 Trident 的 Everex 显示卡；
! cl = 显示器类型： 00-单色； 01-CGA； 02-EGA； 03-数字多频； 04-PS/2； 05-IBM 8514； 06-SVGA。
! ch = 属性：位 7-6： 00-256K， 01-512K， 10-1MB， 11-2MB；位 4-开启 VGA 保护；位 0-6845 模拟。
! dx = 板卡型号：位 15-4：板类型标识号；位 3-0：板修正标识号。
! 0x2360-Ultragraphics II； 0x6200-Vision VGA； 0x6730-EVGA； 0x6780-Viewpoint。
! di = 用 BCD 码表示的视频 BIOS 版本号。
319 nocirr: call rst3d4 ! Check Everex 'clues'
320 mov ax,#0x7000 ! 设置 ax = 0x7000, bx=0x0000，调用 int 0x10。
321 xor bx,bx
322 int 0x10
323 cmp al,#0x70 ! 对于 Everes 显示卡， al 中应该返回值 0x70。
324 jne noevrx
325 shr dx,#4 ! 忽律板修正号（位 3-0）。
326 cmp dx,#0x678 ! 板类型号是 0x678 表示是一块 Trident 显示卡，则跳转。
327 je istrid
328 cmp dx,#0x236 ! 板类型号是 0x236 表示是一块 Trident 显示卡，则跳转。
329 je istrid
! Ok，我们现在确定了该显示卡的牌子。于是 si 指向该品牌显示卡的可选行列值表 dsceverex， di 指
! 向扩展模式个数和扩展模式号列表 moeverex，然后跳转到 selmod（ 438 行）处继续进行设置操作。
330 lea si,dsceverex
331 lea di,moeverex
332 lea cx,selmod
333 jmp cx6.3 setup.S 程序
232
334 istrid: lea cx,ev2tri ! 是 Trident 类型的 Everex 显示卡，则跳转到 ev2tri 处理。
335 jmp cx
! 现在检查是不是 Genoa 显示卡。方式是检查其视频 BIOS 中的特征数字串（ 0x77、 0x00、 0x66、
! 0x99）。注意，此时 es 已经在第 220 行被设置成指向 VGA 卡上 ROM BIOS 所在的段 0xc000。
336 noevrx: lea si,idgenoa ! Check Genoa 'clues'
337 xor ax,ax ! 让 ds:si 指向第 597 行上的特征数字串。
338 seg es
339 mov al,[0x37] ! 取 VGA 卡上 BIOS 中 0x37 处的指针（它指向特征串）。
340 mov di,ax ! 因此此时 es:di 指向特征数字串开始处。
341 mov cx,#0x04
342 dec si
343 dec di
344 l1: inc si ! 然后循环比较这 4 个字节的特征数字串。
345 inc di
346 mov al,(si)
347 seg es
348 and al,(di)
349 cmp al,(si)
350 loope l1
351 cmp cx,#0x00 ! 如果特征数字串完全相同，则表示是 Genoa 显示卡，
352 jne nogen ! 否则跳转去检查其他类型的显示卡。
! Ok，我们现在确定了该显示卡的牌子。于是 si 指向该品牌显示卡的可选行列值表 dscgenoa， di 指
! 向扩展模式个数和扩展模式号列表 mogenoa，然后跳转到 selmod（ 438 行）处继续进行设置操作。
353 lea si,dscgenoa
354 lea di,mogenoa
355 lea cx,selmod
356 jmp cx
! 现在检查是不是 Paradise 显示卡。同样是采用比较显示卡上 BIOS 中特征串（“ VGA=”）的方式。
357 nogen: lea si,idparadise ! Check Paradise 'clues'
358 mov di,#0x7d ! es:di 指向 VGA ROM BIOS 的 0xc000:0x007d 处，该处应该有
359 mov cx,#0x04 ! 4 个字符“ VGA=”。
360 repe
361 cmpsb
362 jne nopara ! 若有不同的字符，表示不是 Paradise 显示卡，于是跳转。
363 lea si,dscparadise ! 否则让 si 指向 Paradise 显示卡的可选行列值表，让 di 指
364 lea di,moparadise ! 向扩展模式个数和模式号列表。然后跳转到 selmod 处去选
365 lea cx,selmod ! 择想要使用的显示模式。
366 jmp cx
! 现在检查是不是 Trident（ TVGA）显示卡。 TVGA 显示卡扩充的模式控制寄存器 1（ 0x3c4 端口索引
! 的 0x0e）的位 3--0 是 64K 内存页面个数值。这个字段值有一个特性：当写入时，我们需要首先把
! 值与 0x02 进行异或操作后再写入；当读取该值时则不需要执行异或操作，即异或前的值应该与写
! 入后再读取的值相同。下面代码就利用这个特性来检查是不是 Trident 显示卡。
367 nopara: mov dx,#0x3c4 ! Check Trident 'clues'
368 mov al,#0x0e ! 首先在端口 0x3c4 输出索引号 0x0e，索引模式控制寄存器 1。
369 out dx,al ! 然后从 0x3c5 数据端口读入该寄存器原值，并暂存在 ah 中。
370 inc dx
371 in al,dx
372 xchg ah,al
373 mov al,#0x00 ! 然后我们向该寄存器写入 0x00，再读取其值al。
374 out dx,al ! 写入 0x00 就相当于“原值” 0x02 异或 0x02 后的写入值，6.3 setup.S 程序
233
375 in al,dx ! 因此若是 Trident 显示卡，则此后读入的值应该是 0x02。
376 xchg al,ah ! 交换后， al=原模式控制寄存器 1 的值， ah=最后读取的值。
! 下面语句右则英文注释是“真奇怪...书中并没有要求这样操作，但是这对我的 Trident 显示卡
! 起作用。如果不这样做，屏幕就会变模糊...”。这几行附带有英文注释的语句执行如下操作：
! 如果 bl 中原模式控制寄存器 1 的位 1 在置位状态的话就将其复位，否则就将位 1 置位。
! 实际上这几条语句就是对原模式控制寄存器 1 的值执行异或 0x02 的操作，然后用结果值去设置
! （恢复）原寄存器值。
377 mov bl,al ! Strange thing ... in the book this wasn't
378 and bl,#0x02 ! necessary but it worked on my card which
379 jz setb2 ! is a trident. Without it the screen goes
380 and al,#0xfd ! blurred ...
381 jmp clrb2 !
382 setb2: or al,#0x02 !
383 clrb2: out dx,al
384 and ah,#0x0f ! 取 375 行最后读入值的页面个数字段（位 3--0），如果
385 cmp ah,#0x02 ! 该字段值等于 0x02，则表示是 Trident 显示卡。
386 jne notrid
! Ok，我们现在可以确定是 Trident 显示卡。于是 si 指向该品牌显示卡的可选行列值表 dsctrident，
! di 指向扩展模式个数和扩展模式号列表 motrident，然后跳转到 selmod（ 438 行）处继续设置操作。
387 ev2tri: lea si,dsctrident
388 lea di,motrident
389 lea cx,selmod
390 jmp cx
! 现在检查是不是 Tseng 显示卡（ ET4000AX 或 ET4000/W32 类）。方法是对 0x3cd 端口对应的段
! 选择（ Segment Select） 寄存器执行读写操作。该寄存器高 4 位（位 7--4）是要进行读操作的
! 64KB 段号（ Bank number） ，低 4 位（位 3--0）是指定要写的段号。如果指定段选择寄存器的
! 值是 0x55（表示读、写第 6 个 64KB 段），那么对于 Tseng 显示卡来说，把该值写入寄存器后
! 再读出应该还是 0x55。
391 notrid: mov dx,#0x3cd ! Check Tseng 'clues'
392 in al,dx ! Could things be this simple ! :-)
393 mov bl,al ! 先从 0x3cd 端口读取段选择寄存器原值，并保存在 bl 中。
394 mov al,#0x55 ! 然后我们向该寄存器中写入 0x55。再读入并放在 ah 中。
395 out dx,al
396 in al,dx
397 mov ah,al
398 mov al,bl ! 接着恢复该寄存器的原值。
399 out dx,al
400 cmp ah,#0x55 ! 如果读取的就是我们写入的值，则表明是 Tseng 显示卡。
401 jne notsen
! Ok，我们现在可以确定是 Tseng 显示卡。于是 si 指向该品牌显示卡的可选行列值表 dsctseng，
! di 指向扩展模式个数和扩展模式号列表 motseng，然后跳转到 selmod（ 438 行）处继续设置操作。
402 lea si,dsctseng ! 于是让 si 指向 Tseng 显示卡的可选行列值的列表，让 di
403 lea di,motseng ! 指向对应扩展模式个数和模式号列表，然后跳转到 selmod
404 lea cx,selmod ! 去执行模式选择操作。
405 jmp cx
! 下面检查是不是 Video7 显示卡。端口 0x3c2 是混合输出寄存器写端口，而 0x3cc 是混合输出寄存
! 器读端口。该寄存器的位 0 是单色/彩色标志。如果为 0 则表示是单色，否则是彩色。判断是不是
! Video7 显示卡的方式是利用这种显示卡的 CRT 控制扩展标识寄存器（索引号是 0x1f）。该寄存器
! 的值实际上就是显存起始地址高字节寄存器（索引号 0x0c）的内容和 0xea 进行异或操作后的值。
! 因此我们只要向显存起始地址高字节寄存器中写入一个特定值，然后从标识寄存器中读取标识值
! 进行判断即可。6.3 setup.S 程序
234
! 通过对以上显示卡和这里 Video7 显示卡的检查分析，我们可知检查过程通常分为三个基本步骤。
! 首先读取并保存测试需要用到的寄存器原值，然后使用特定测试值进行写入和读出操作，最后恢
! 复原寄存器值并对检查结果作出判断。
406 notsen: mov dx,#0x3cc ! Check Video7 'clues'
407 in al,dx
408 mov dx,#0x3b4 ! 先设置 dx 为单色显示 CRT 控制索引寄存器端口号 0x3b4。
409 and al,#0x01 ! 如果混合输出寄存器的位 0 等于 0（单色）则直接跳转，
410 jz even7 ! 否则 dx 设置为彩色显示 CRT 控制索引寄存器端口号 0x3d4。
411 mov dx,#0x3d4
412 even7: mov al,#0x0c ! 设置寄存器索引号为 0x0c，对应显存起始地址高字节寄存器。
413 out dx,al
414 inc dx
415 in al,dx ! 读取显示内存起始地址高字节寄存器内容，并保存在 bl 中。
416 mov bl,al
417 mov al,#0x55 ! 然后在显存起始地址高字节寄存器中写入值 0x55，再读取出来。
418 out dx,al
419 in al,dx
420 dec dx ! 然后通过 CRTC 索引寄存器端口 0x3b4 或 0x3d4 选择索引号是
421 mov al,#0x1f ! 0x1f 的 Video7 显示卡标识寄存器。该寄存器内容实际上就是
422 out dx,al ! 显存起始地址高字节和 0xea 进行异或操作后的结果值。
423 inc dx
424 in al,dx ! 读取 Video7 显示卡标识寄存器值，并保存在 bh 中。
425 mov bh,al
426 dec dx ! 然后再选择显存起始地址高字节寄存器，恢复其原值。
427 mov al,#0x0c
428 out dx,al
429 inc dx
430 mov al,bl
431 out dx,al
432 mov al,#0x55 ! 随后我们来验证“ Video7 显示卡标识寄存器值就是显存起始
433 xor al,#0xea ! 地址高字节和 0xea 进行异或操作后的结果值” 。因此 0x55
434 cmp al,bh ! 和 0xea 进行异或操作的结果就应该等于标识寄存器的测试值。
435 jne novid7 ! 若不是 Video7 显示卡，则设置默认显示行列值（ 492 行）。
! Ok，我们现在可以确定是 Video7 显示卡。于是 si 指向该品牌显示卡的可选行列值表 dscvideo7，
! di 指向扩展模式个数和扩展模式号列表 movideo7，然后继续进行模式设置操作。
436 lea si,dscvideo7
437 lea di,movideo7
! 下面根据上述代码判断出的显示卡类型以及取得的相关扩展模式信息（ si 指向的行列值列表； di
! 指向扩展模式个数和模式号列表），提示用户选择可用的显示模式，并设置成相应显示模式。最后
! 子程序返回系统当前设置的屏幕行列值（ ah = 列数； al=行数）。例如，如果系统中是 ATI 显示卡，
! 那么屏幕上会显示以下信息：
! Mode: COLSxROWS:
! 0. 132 x 25
! 1. 132 x 44
! Choose mode by pressing the corresponding number.
!
! 这段程序首先在屏幕上显示 NULL 结尾的字符串信息“ Mode: COLSxROWS:”。
438 selmod: push si
439 lea si,msg2
440 call prtstr
441 xor cx,cx
442 mov cl,(di) ! 此时 cl 中是检查出的显示卡的扩展模式个数。6.3 setup.S 程序
235
443 pop si
444 push si
445 push cx
! 然后在每一行上显示出当前显示卡可选择的扩展模式行列值，供用户选用。
446 tbl: pop bx ! bx = 显示卡的扩展模式总个数。
447 push bx
448 mov al,bl
449 sub al,cl
450 call dprnt ! 以十进制格式显示 al 中的值。
451 call spcing ! 显示一个点再空 4 个空格。
452 lodsw ! 在 ax 中加载 si 指向的行列值，随后 si 指向下一个 word 值。
453 xchg al,ah ! 交换位置后 al = 列数。
454 call dprnt ! 显示列数；
455 xchg ah,al ! 此时 al 中是行数值。
456 push ax
457 mov al,#0x78 ! 显示一个小“ x” ，即乘号。
458 call prnt1
459 pop ax ! 此时 al 中是行数值。
460 call dprnt ! 显示行数。
461 call docr ! 回车换行。
462 loop tbl ! 再显示下一个行列值。 cx 中扩展模式计数值递减 1。
! 在扩展模式行列值都显示之后，显示“ Choose mode by pressing the corresponding number.” 。
463 pop cx ! cl 中是显示卡扩展模式总个数值。
464 call docr
465 lea si,msg3 ! 显示“请按相应数字键来选择模式。”
466 call prtstr
! 然后从键盘口读取用户按键的扫描码，根据该扫描码确定用户选择的行列值模式号，并利用 ROM
! BIOS 的显示中断 int 0x10 功能 0x00 来设置相应的显示模式。
! 第 468 行的“ 模式个数值+0x80” 是所按数字键-1 的断开扫描码。对于 0--9 数字键，它们的断开
! 扫描码分别是： 0 - 0x8B； 1 - 0x82； 2 - 0x83； 3 - 0x84； 4 - 0x85；
! 5 - 0x86； 6 - 0x87； 7 - 0x88； 8 - 0x89； 9 - 0x8A。
! 因此，如果读取的键盘断开扫描码小于 0x82 就表示不是数字键；如果扫描码等于 0x8B 则表示用户
! 按下数字 0 键。
467 pop si ! 弹出原行列值指针（指向显示卡行列值表开始处）。
468 add cl,#0x80 ! cl + 0x80 = 对应“数字键-1” 的断开扫描码。
469 nonum: in al,#0x60 ! Quick and dirty...
470 cmp al,#0x82 ! 若键盘断开扫描码小于 0x82 则表示不是数字键，忽律该键。
471 jb nonum
472 cmp al,#0x8b ! 若键盘断开扫描码等于 0x8b，表示按下了数字键 0。
473 je zero
474 cmp al,cl ! 若扫描码大于扩展模式个数值对应的最大扫描码值，表示
475 ja nonum ! 键入的值超过范围或不是数字键的断开扫描码。否则表示
476 jmp nozero ! 用户按下并松开了一个非 0 数字按键。
! 下面把断开扫描码转换成对应的数字按键值，然后利用该值从模式个数和模式号列表中选择对应的
! 的模式号。接着调用机器 ROM BIOS 中断 int 0x10 功能 0 把屏幕设置成模式号指定的模式。最后再
! 利用模式号从显示卡行列值表中选择并在 ax 中返回对应的行列值。
477 zero: sub al,#0x0a ! al = 0x8b - 0x0a = 0x81。
478 nozero: sub al,#0x80 ! 再减去 0x80 就可以得到用户选择了第几个模式。
479 dec al ! 从 0 起计数。
480 xor ah,ah ! int 0x10 显示功能号=0（设置显示模式）。
481 add di,ax6.3 setup.S 程序
236
482 inc di ! di 指向对应的模式号（跳过第 1 个模式个数字节值）。
483 push ax
484 mov al,(di) ! 取模式号al 中，并调用系统 BIOS 显示中断功能 0。
485 int 0x10
486 pop ax
487 shl ax,#1 ! 模式号乘 2，转换成为行列值表中对应值的指针。
488 add si,ax
489 lodsw ! 取对应行列值到 ax 中（ ah = 列数， al = 行数）。
490 pop ds ! 恢复第 216 行保存的 ds 原值。在 ax 中返回当前显示行列值。
491 ret
! 若都不是上面检测的显示卡，那么我们只好采用默认的 80 x 25 的标准行列值。
492 novid7: pop ds ! Here could be code to support standard 80x50,80x30
493 mov ax,#0x5019
494 ret
495
496 ! Routine that 'tabs' to next col.
! 光标移动到下一制表位的子程序。
497
! 显示一个点字符'.'和 4 个空格。
498 spcing: mov al,#0x2e ! 显示一个点字符'.'。
499 call prnt1
500 mov al,#0x20
501 call prnt1
502 mov al,#0x20
503 call prnt1
504 mov al,#0x20
505 call prnt1
506 mov al,#0x20
507 call prnt1
508 ret
509
510 ! Routine to print asciiz-string at DS:SI
! 显示位于 DS:SI 处以 NULL（ 0x00）结尾的字符串。
511
512 prtstr: lodsb
513 and al,al
514 jz fin
515 call prnt1 ! 显示 al 中的一个字符。
516 jmp prtstr
517 fin: ret
518
519 ! Routine to print a decimal value on screen, the value to be
520 ! printed is put in al (i.e 0-255).
! 显示十进制数字的子程序。显示值放在寄存器 al 中（ 0--255）。
521
522 dprnt: push ax
523 push cx
524 mov ah,#0x00
525 mov cl,#0x0a
526 idiv cl
527 cmp al,#0x09
528 jbe lt1006.3 setup.S 程序
237
529 call dprnt
530 jmp skip10
531 lt100: add al,#0x30
532 call prnt1
533 skip10: mov al,ah
534 add al,#0x30
535 call prnt1
536 pop cx
537 pop ax
538 ret
539
540 ! Part of above routine, this one just prints ascii al
! 上面子程序的一部分。显示 al 中的一个字符。
! 该子程序使用中断 0x10 的 0x0E 功能，以电传方式在屏幕上写一个字符。光标会自动移到下一个
! 位置处。如果写完一行光标就会移动到下一行开始处。如果已经写完一屏最后一行，则整个屏幕
! 会向上滚动一行。字符 0x07（ BEL）、 0x08（ BS）、 0x0A(LF)和 0x0D（ CR）被作为命令不会显示。
! 输入： AL -- 欲写字符； BH -- 显示页号； BL -- 前景显示色（图形方式时）。
541
542 prnt1: push ax
543 push cx
544 mov bh,#0x00 ! 显示页面。
545 mov cx,#0x01
546 mov ah,#0x0e
547 int 0x10
548 pop cx
549 pop ax
550 ret
551
552 ! Prints <CR> + <LF> ! 显示回车+换行。
553
554 docr: push ax
555 push cx
556 mov bh,#0x00
557 mov ah,#0x0e
558 mov al,#0x0a
559 mov cx,#0x01
560 int 0x10
561 mov al,#0x0d
562 int 0x10
563 pop cx
564 pop ax
565 ret
566
! 全局描述符表开始处。描述符表由多个 8 字节长的描述符项组成。这里给出了 3 个描述符项。
! 第 1 项无用（ 568 行），但须存在。第 2 项是系统代码段描述符（ 570-573 行），第 3 项是系
! 统数据段描述符(575-578 行)。
567 gdt:
568 .word 0,0,0,0 ! dummy ! 第 1 个描述符，不用。
569
! 在 GDT 表中这里的偏移量是 0x08。它是内核代码段选择符的值。
570 .word 0x07FF ! 8Mb - limit=2047 (0--2047，因此是 2048*4096=8Mb)
571 .word 0x0000 ! base address=0
572 .word 0x9A00 ! code read/exec ! 代码段为只读、可执行。6.3 setup.S 程序
238
573 .word 0x00C0 ! granularity=4096, 386 ! 颗粒度为 4096， 32 位模式。
574
! 在 GDT 表中这里的偏移量是 0x10。它是内核数据段选择符的值。
575 .word 0x07FF ! 8Mb - limit=2047 (2048*4096=8Mb)
576 .word 0x0000 ! base address=0
577 .word 0x9200 ! data read/write ! 数据段为可读可写。
578 .word 0x00C0 ! granularity=4096, 386 ! 颗粒度为 4096， 32 位模式。
579
! 下面是加载中断描述符表寄存器 idtr 的指令 lidt 要求的 6 字节操作数。前 2 字节是 IDT 表的
! 限长，后 4 字节是 idt 表在线性地址空间中的 32 位基地址。 CPU 要求在进入保护模式之前需设
! 置 IDT 表，因此这里先设置一个长度为 0 的空表。
580 idt_48:
581 .word 0 ! idt limit=0
582 .word 0,0 ! idt base=0L
583
! 这是加载全局描述符表寄存器 gdtr 的指令 lgdt 要求的 6 字节操作数。前 2 字节是 gdt 表的限
! 长，后 4 字节是 gdt 表的线性基地址。这里全局表长度设置为 2KB（ 0x7ff 即可） ，因为每 8
! 字节组成一个段描述符项，所以表中共可有 256 项。 4 字节的线性基地址为 0x0009<<16 +
! 0x0200 + gdt，即 0x90200 + gdt。 (符号 gdt 是全局表在本程序段中的偏移地址，见 205 行)
584 gdt_48:
585 .word 0x800 ! gdt limit=2048, 256 GDT entries
586 .word 512+gdt,0x9 ! gdt base = 0X9xxxx
587
588 msg1: .ascii "Press <RETURN> to see SVGA-modes available or any other key to continue."
589 db 0x0d, 0x0a, 0x0a, 0x00
590 msg2: .ascii "Mode: COLSxROWS:"
591 db 0x0d, 0x0a, 0x0a, 0x00
592 msg3: .ascii "Choose mode by pressing the corresponding number."
593 db 0x0d, 0x0a, 0x00
594
! 下面是 4 个显示卡的特征数据串。
595 idati: .ascii "761295520"
596 idcandt: .byte 0xa5 ! 标号 idcandt 意思是 ID of Chip AND Tech.
597 idgenoa: .byte 0x77, 0x00, 0x66, 0x99
598 idparadise: .ascii "VGA="
599
! 下面是各种显示卡可使用的扩展模式个数和对应的模式号列表。其中每一行第 1 个字节是模式个
! 数值，随后的一些值是中断 0x10 功能 0（ AH=0）可使用的模式号。例如从 602 行可知，对于 ATI
! 牌子的显示卡，除了标准模式以外还可使用两种扩展模式： 0x23 和 0x33。
600 ! Manufacturer: Numofmodes: Mode:
! 厂家： 模式数量： 模式列表：
601
602 moati: .byte 0x02, 0x23, 0x33
603 moahead: .byte 0x05, 0x22, 0x23, 0x24, 0x2f, 0x34
604 mocandt: .byte 0x02, 0x60, 0x61
605 mocirrus: .byte 0x04, 0x1f, 0x20, 0x22, 0x31
606 moeverex: .byte 0x0a, 0x03, 0x04, 0x07, 0x08, 0x0a, 0x0b, 0x16, 0x18, 0x21, 0x40
607 mogenoa: .byte 0x0a, 0x58, 0x5a, 0x60, 0x61, 0x62, 0x63, 0x64, 0x72, 0x74, 0x78
608 moparadise: .byte 0x02, 0x55, 0x54
609 motrident: .byte 0x07, 0x50, 0x51, 0x52, 0x57, 0x58, 0x59, 0x5a
610 motseng: .byte 0x05, 0x26, 0x2a, 0x23, 0x24, 0x22
611 movideo7: .byte 0x06, 0x40, 0x43, 0x44, 0x41, 0x42, 0x456.3 setup.S 程序
239
612
! 下面是各种牌子 VGA 显示卡可使用的模式对应的列、行值列表。例如第 615 行表示 ATI 显示卡两
! 种扩展模式的列、行值分别是 132 x 25、 132 x 44。
613 ! msb = Cols lsb = Rows:
! 高字节=列数 低字节=行数：
614
615 dscati: .word 0x8419, 0x842c ! ATI 卡可设置列、行值。
616 dscahead: .word 0x842c, 0x8419, 0x841c, 0xa032, 0x5042 ! Ahead 卡可设置值。
617 dsccandt: .word 0x8419, 0x8432
618 dsccirrus: .word 0x8419, 0x842c, 0x841e, 0x6425
619 dsceverex: .word 0x5022, 0x503c, 0x642b, 0x644b, 0x8419, 0x842c, 0x501e, 0x641b, 0xa040,
0x841e
620 dscgenoa: .word 0x5020, 0x642a, 0x8419, 0x841d, 0x8420, 0x842c, 0x843c, 0x503c, 0x5042,
0x644b
621 dscparadise: .word 0x8419, 0x842b
622 dsctrident: .word 0x501e, 0x502b, 0x503c, 0x8419, 0x841e, 0x842b, 0x843c
623 dsctseng: .word 0x503c, 0x6428, 0x8419, 0x841c, 0x842c
624 dscvideo7: .word 0x502b, 0x503c, 0x643c, 0x8419, 0x842c, 0x841c
625
626 .text
627 endtext:
628 .data
629 enddata:
630 .bss
631 endbss:
```

6.3.3其他信息

为了获取机器的基本参数和向用户显示启动过程的消息，这段程序多次调用了 ROM BIOS 中的中断
服务，并开始涉及一些对硬件端口的访问操作。下面简要地描述程序中使用到的几种 BIOS 中断调用服
务，并对 A20 地址线问题的缘由进行说明。 最后提及关于 80X86 CPU 32 位保护模式运行的问题。

6.3.3.1 当前内存映像

在 setup.s 程序执行结束后，系统模块 system 被移动到物理内存地址 0x00000 开始处，而从位置
0x90000 开始处则存放了内核将会使用的一些系统基本参数，示意图如图 6-6 所示。6.3 setup.S 程序
240

图 6-6 setup.s 程序结束后内存中程序示意图

此时临时全局表 GDT 中有三个描述符。 第一个是 NULL 不使用，另外两个分别是代码段描述符和
数据段描述符。它们都指向系统模块的起始处，也即物理内存地址 0x0000 处。这样当 setup.s 中执行最
后一条指令 'jmp 0,8 '（第 193 行）时，就会跳到 head.s 程序开始处继续执行下去。这条指令中的'8'是
段选择符值，用来指定所需使用的描述符项，此处是指临时 GDT 表中的代码段描述符。 '0'是描述符项指
定的代码段中的偏移值。

6.3.3.2 BIOS 视频中断 0x10

本节说明上面程序中用到的 ROM BIOS 中视频中断服务功能。 对获取显示卡信息功能（其他辅助功
能选择） 的说明请见表 6-3 所示。 其他显示服务功能已在程序注释中给出。

表 6– 3 获取显示卡信息（功能号： ah = 0x12， bl = 0x10）

输入/返回信息 寄存器 内容说明
输入信息
ah 功能号=0x12，获取显示卡信息
bl 子功能号=0x10。
返回信息
bh
视频状态：
0x00 – 彩色模式（此时视频硬件 I/O 端口基地址为 0x3DX）；
0x01 – 单色模式（此时视频硬件 I/O 端口基地址为 0x3BX）；
注：其中端口地址中的 X 值可为 0 – f。
bl
已安装的显示内存大小：
00 = 64K, 01 = 128K, 02 = 192K, 03 = 256K
ch
特性连接器比特位信息：
比特位 0-1 特性线 1-0，状态 2；
比特位 2-3 特性线 1-0，状态 1；
比特位 4-7 未使用(为 0)
cl 视频开关设置信息：
0x90200
0x00000
临时全局描述符表
(gdt)
system 模块
setup.s 程序
0x90000
head.s 程序
系统参数
库模块(lib)
内存管理模块(mm)
内核模块(kernel)
main.c 程序
setup.s 代码
代码段描述符
数据段描述符
原来的 bootsect.s
程序被覆盖掉了6.3 setup.S 程序
241
比特位 0-3 分别对应开关 1-4 关闭； 位 4-7 未使用。
原始 EGA/VGA 开关设置值:
0x00 MDA/HGC； 0x01-0x03 MDA/HGC；
0x04 CGA 40x25； 0x05 CGA 80x25；
0x06 EGA+ 40x25； 0x07-0x09 EGA+ 80x25；
0x0A EGA+ 80x25 单色； 0x0B EGA+ 80x25 单色。

6.3.3.3 硬盘基本参数表（“INT 0x41”）

在 ROM BIOS 的中断向量表中， INT 0x41 的中断向量位置处（ 4 * 0x41 =0x0000:0x0104） 存放的并
不是中断服务程序的地址，而是第一个硬盘的基本参数表的地址，见表 6-4 所示。对于 IBM PC 全兼容
机器的 BIOS，这里存放的硬盘参数表的地址具体值是 F000h:E401h。第二个硬盘的基本参数表入口地址
存于 INT 0x46 中断向量位置处。

表 6– 4 硬盘基本参数信息表

位移 大小 英文名称 说明
0x00 字 cyl 柱面数
0x02 字节 head 磁头数
0x03 字 开始减小写电流的柱面(仅 PC/ XT 使用，其他为 0)
0x05 字 wpcom 开始写前预补偿柱面号（乘 4）
0x07 字节 最大 ECC 猝发长度（仅 PC/XT 使用，其他为 0）
0x08 字节 ctl
控制字节（驱动器步进选择）
位 0 - 未用； 位 1 - 保留(0) (关闭 IRQ)；
位 2 - 允许复位； 位 3 - 若磁头数大于 8 则置 1；
位 4 - 未用(0)； 位 5 - 若在柱面数+1 处有厂商的坏区图，则置 1
位 6 - 禁止 ECC 重试； 位 7 - 禁止访问重试。
0x09 字节 标准超时值（仅 PC/ XT 使用，其他为 0）
0x0A 字节 格式化超时值（仅 PC/ XT 使用，其他为 0）
0x0B 字节 检测驱动器超时值（仅 PC/ XT 使用，其他为 0）
0x0C 字 lzone 磁头着陆(停止)柱面号
0x0E 字节 sect 每磁道扇区数
0x0F 字节 保留。

6.3.3.4 A20 地址线问题

1981 年 8 月， IBM 公司最初推出的个人计算机 IBM PC 使用的是准 16 位的 Intel 8088 CPU。 该 CPU
具有 16 位内部数据总线（ 外部 8 位）和 20 位地址总线宽度。因此， 该微机中地址线只有 20 根(A0 – A19)，
CPU 最多可寻址 1MB 的内存范围。在当时流行的机器内存 RAM 容量只有几十 KB、几百 KB 的情况下，
20 根地址线已足够用来寻址这些内存。其所能寻址的最高地址是 0xffff:0xffff，也即 0x10ffef。对于超出
0x100000(1MB)的内存地址， CPU 将默认环绕寻址到 0x0ffef 位置处。

当 IBM 公司于 1985 年推出 PC/AT 新机型时，使用的是 Intel 80286 CPU，具有 24 根地址线，可寻
址最多 16MB 内存，并且有一个与 8088 完全兼容的实模式运行方式。然而，在寻址值超过 1MB 时它却
不能象 8088 CPU 那样实现地址寻址的环绕。但是当时已经有一些程序被设计成利用这种地址环绕机制
进行工作。因此，为了实现与原 PC 机完全兼容， IBM 公司发明了使用一个开关来开启或禁止 0x100000
地址比特位。由于在当时的键盘控制器 8042 上恰好有空闲的端口引脚（输出端口 P2，引脚 P21），于是
便使用了该引脚来作为与门来控制这个地址比特位。该信号即被称为 A20。如果它为零，则比特 20 及以6.3 setup.S 程序
242
上地址都被清除。从而实现了兼容性。关于键盘控制器 8042 芯片，请参见 kernel/chr_drv/keyboard.S 程
序后的说明。

为了兼容性，默认条件下在机器启动时 A20 地址线是禁止的，所以 32 位机器的操作系统必须使用
适当的方法来开启它。但是由于各种兼容机所使用的芯片集不同，要做到这一点却是非常的麻烦。因此
通常要在几种控制方法中选择。

对 A20 信号线进行控制的常用方法是设置键盘控制器的端口值。这里的 setup.s 程序（ 138-144 行）
即使用了这种典型的控制方式。对于其他一些兼容微机还可以使用其他方式来做到对 A20 线的控制。有
些操作系统将 A20 的开启和禁止作为实模式与保护运行模式之间进行转换的标准过程中的一部分。由于
键盘的控制器速度很慢，因此就不能使用键盘控制器对 A20 线来进行操作。为此引进了一个 A20 快速门
选项(Fast Gate A20)。它使用 I/O 端口 0x92 来处理 A20 信号线，避免了使用慢速的键盘控制器操作方式。
对于不含键盘控制器的系统就只能使用 0x92 端口来控制。但是该端口也有可能被其他兼容微机上的设备
（如显示芯片）所使用，从而造成系统错误的操作。还有一种方式是通过读 0xee 端口来开启 A20 信号
线，写该端口则会禁止 A20 信号线。

6.3.3.5 8259A 中断控制器的编程方法

在第 2 章中我们已经概要介绍了中断机制的基本工作原理和 PC/AT 兼容微机中使用的硬件中断子系
统。这里我们首先介绍 8259A 芯片的工作原理，然后详细说明 8259A 芯片的编程方法以及 Linux 内核对
其设置的工作方式。

1. 8259A 芯片工作原理

前面已经说过，在 PC/AT 系列兼容机中使用了级联的两片 8259A 可编程控制器（ PIC）芯片，共可
管理 15 级中断向量，参见图 2-20 所示。其中从芯片的 INT 引脚连接到主芯片的 IR2 引脚上。主 8259A
芯片的端口基地址是 0x20，从芯片是 0xA0。一个 8259A 芯片的逻辑框图见图 6-7 所示。

图 6-7 可编程中断控制器 8259A 芯片框图

图中，中断请求寄存器 IRR（ Interrupt Request Register） 用来保存中断请求输入引脚上所有请求服务
中断级，寄存器的 8 个比特位（ D7—D0）分别对应引脚 IR7—IR0。中断屏蔽寄存器 IMR（ Interrup Mask
Register）用于保存被屏蔽的中断请求线对应的比特位，寄存器的 8 位也是对应 8 个中断级。哪个比特位
被置 1 就屏蔽哪一级中断请求。即 IMR 对 IRR 进行处理，其每个比特位对应 IRR 的每个请求比特位。
对高优先级输入线的屏蔽并不会影响低优先级中断请求线的输入。优先级解析器 PR（ Priority Resolver）
控制逻辑等
优先级
解析器
(PR)
中断请求
寄存器
(IRR)
正在服务
寄存器
(ISR)
IR0
IR1
IR2
IR3
IR4
IR5
IR6
IR7
初始化命令字
寄存器组ICWs
操作命令字
INTA 寄存器组OCWs
INT
数据总线
D7– D0 缓冲
中断屏蔽寄存器
(IMR)
A06.3 setup.S 程序
243

用于确定 IRR 中所设置比特位的优先级，选通最高优先级的中断请求到正在服务寄存器 ISR（ In-Service
Register）中。 ISR 中保存着正在接受服务的中断请求。控制逻辑方框中的寄存器组用于接受 CPU 产生
的两类命令。在 8259A 可以正常操作之前，必须首先设置初始化命令字 ICW（ Initialization Command Words）
寄存器组的内容。而在其工作过程中，则可以使用写入操作命令字 OCW（ Operation Command Words）
寄存器组来随时设置和管理 8259A 的工作方式。 A0 线用于选择操作的寄存器。在 PC/AT 微机系统中，
当 A0 线为 0 时芯片的端口地址是 0x20 和 0xA0（从芯片），当 A0=1 时端口就是 0x21 和 0xA1。
来自各个设备的中断请求线分别连接到 8259A 的 IR0—IR7 中断请求引脚上。当这些引脚上有一个
或多个中断请求信号到来时，中断请求寄存器 IRR 中相应的比特位被置位锁存。此时若中断屏蔽寄存器
IMR 中对应位被置位，则相应的中断请求就不会送到优先级解析器中。对于未屏蔽的中断请求被送到优
先级解析器之后，优先级最高的中断请求会被选出。此时 8259A 就会向 CPU 发送一个 INT 信号，而 CPU
则会在执行完当前的一条指令之后向 8259A 返回一个 INTA 来响应中断信号。 8259A 在收到这个响应信
号之后就会把所选出的最高优先级中断请求保存到正在服务寄存器 ISR 中，即 ISR 中对应中断请求级的
比特位被置位。与此同时，中断请求寄存器 IRR 中的对应比特位被复位，表示该中断请求开始正被处理
中。

此后， CPU 会向 8259A 发出第 2 个 INTA 脉冲信号，该信号用于通知 8259A 送出中断号。因此在该
脉冲信号期间 8259A 就会把一个代表中断号的 8 位数据发送到数据总线上供 CPU 读取。
到此为止， CPU 中断周期结束。如果 8259A 使用的是自动结束中断 AEOI （ Automatic End of Interrupt）
方式，那么在第 2 个 INTA 脉冲信号的结尾处正在服务寄存器 ISR 中的当前服务中断比特位就会被复位。
否则的话，若 8259A 处于非自动结束方式，那么在中断服务程序结束时程序就需要向 8259A 发送一个结
束中断（ EOI）命令以复位 ISR 中的比特位。如果中断请求来自接联的第 2 个 8259A 芯片，那么就需要
向两个芯片都发送 EOI 命令。此后 8259A 就会去判断下一个最高优先级的中断，并重复上述处理过程。
下面我们先给出初始化命令字和操作命令字的编程方法，然后再对其中用到的一些操作方式作进一步说
明。

2. 初始化命令字编程

可编程控制器 8259A 主要有 4 种工作方式：①全嵌套方式；②循环优先级方式；③特殊屏蔽方式和
④程序查询方式。通过对 8259A 进行编程，我们可以选定 8259A 的当前工作方式。编程时分两个阶段。
一是在 8259A 工作之前对每个 8259A 芯片 4 个初始化命令字（ ICW1—ICW4）寄存器的写入编程；二是
在工作过程中随时对 8259A 的 3 个操作命令字（ OCW1—OCW3）进行编程。在初始化之后，操作命令
字的内容可以在任何时候写入 8259A。下面我们先说明对 8259A 初始化命令字的编程操作。
初始化命令字的编程操作流程见图 6-8 所示。由图可以看出，对 ICW1 和 ICW2 的设置是必需的。
而只有当系统中包括多片 8259A 芯片并且是接连的情况下才需要对 ICW3 进行设置。这需要在 ICW1 的
设置中明确指出。另外，是否需要对 ICW4 进行设置也需要在 ICW1 中指明。6.3 setup.S 程序
244

图 6-8 8259A 初始化命令字设置顺序

(1) ICW1 当发送字节的比特位 4（ D4） =1 并且地址线 A0=0 时，表示是对 ICW1 编程。此时对于 PC/AT
微机系统的多片级联情况下， 8259A 主芯片的端口地址是 0x20，从芯片的端口地址是 0xA0。 ICW1 的格
式如表 6–5 所示。
表 6– 5 中断初始化命令字 ICW1 格式
位 名称 含义
D7 A7
A7—A5 表示在 MCS80/85 中用于中断服务过程的页面起始地址。
与 ICW2 中的 A15—A8 共同组成。这几位对 8086/88 处理器无用。
D6 A6
D5 A5
D4 恒为 1
D3 LTIM 1 - 电平触发中断方式； 0 – 边沿触发方式。
D2 ADI MCS80/85 系统用于 CALL 指令地址间隔。对 8086/88 处理器无用。
D1 SNGL 1 – 单片 8259A； 0 – 多片。
D0 IC4 1 – 需要 ICW4； 0 – 不需要。
在 Linux 0.12 内核中， ICW1 被设置为 0x11。表示中断请求是边沿触发、多片 8259A 级联并且最后
需要发送 ICW4。

(2) ICW2 用于设置芯片送出的中断号的高 5 位。在设置了 ICW1 之后，当 A0=1 时表示对 ICW2 进行设
置。此时对于 PC/AT 微机系统的多片级联情况下， 8259A 主芯片的端口地址是 0x21，从芯片的端口地址
是 0xA1。 ICW2 格式见表 6–6 所示。
表 6– 6 中断初始化命令字 ICW2 格式
A0 D7 D6 D5 D4 D3 D2 D1 D0
1 A15/T7 A14/T6 A13/T5 A12/T4 A11/T3 A10 A9 A8
在 MCS80/85 系统中，位 D7—D0 表示的 A15—A8 与 ICW1 设置的 A7-A5 组成中断服务程序页面地
N(IC4=0)
Y(IC4=1)
N(SNGL=1)
Y(SNGL=0)
设置 ICW1
设置 ICW 寄存器组
就绪，可接受中断
设置 ICW2
设置 ICW3
设置 ICW4
嵌套方式?
需要 ICW4?6.3 setup.S 程序
245
址。在使用 8086/88 处理器的系统或兼容系统中 T7—T3 是中断号的高 5 位，与 8259A 芯片自动设置的
低 3 位组成一个 8 位的中断号。 8259A 在收到第 2 个中断响应脉冲 INTA 时会送到数据总线上，以供 CPU
读取。

Linux 0.12 系统把主片的 ICW2 设置为 0x20，表示主片中断请求 0 级—7 级对应的中断号范围是
0x20—0x27。而从片的 ICW2 被设置成 0x28，表示从片中断请求 8 级—15 级对应的中断号范围是
0x28—0x2f。

(3) ICW3 用于具有多个 8259A 芯片级联时，加载 8 位的从寄存器（ Slave Register）。端口地址同上。 ICW3
格式见表 6–7 所示。

表 6– 7 中断初始化命令字 ICW3 格式

A0 D7 D6 D5 D4 D3 D2 D1 D0
主片： 1 S7 S6 S5 S4 S3 S2 S1 S0
A0 D7 D6 D5 D4 D3 D2 D1 D0
从片： 1 0 0 0 0 0 ID2 ID1 ID0

主片 S7—S0 各比特位对应级联的从片。哪位为 1 则表示主片的该中断请求引脚 IR 上信号来自从片，
否则对应的 IR 引脚没有连从片。从片的 ID2—ID0 三个比特位对应各从片的标识号，即连接到主片的中
断级。当某个从片接收到级联线（ CAS2—CAS0）输入的值与自己的 ID2—ID0 相等时，则表示此从片被
选中。此时该从片应该向数据总线发送从片当前选中中断请求的中断号。

Linux 0.12 内核把 8259A 主片的 ICW3 设置为 0x04，即 S2=1，其余各位为 0。表示主芯片的 IR2 引
脚连接一个从芯片。从芯片的 ICW3 被设置为 0x02，即其标识号为 2。表示从片连接到主片的 IR2 引脚。
因此，中断优先级的排列次序为 0 级最高，接下来是从片上的 8—15 级，最后是 3—7 级。

(4) ICW4 当 ICW1 的位 0（ IC4）置位时，表示需要 ICW4。地址线 A0=1。端口地址同上说明。 ICW4
格式见表 6–8 所示。
表 6– 8 中断初始化命令字 ICW4 格式
位 名称 含义
D7-5 恒为 0
D4 SFNM 1 – 选择特殊全嵌套方式； 0 – 普通全嵌套方式。
D3 BUF 1 – 缓冲方式； 0 – 非缓冲方式。
D2 M/S 1 – 缓冲方式下主片； 0 – 缓冲方式下从片。
D1 AEOI 1 – 自动结束中断方式； 0 – 非自动结束方式。
D0 μ PM 1 – 8086/88 处理器系统； 0 – MCS80/85 系统。
Linux 0.12 内核送往 8259A 主芯片和从芯片的 ICW4 命令字的值均为 0x01。表示 8259A 芯片被设置
成普通全嵌套、非缓冲、非自动结束中断方式，并且用于 8086 及其兼容系统。

3. 操作命令字编程

在对 8259A 设置了初始化命令字寄存器后，芯片就已准备好接收设备的中断请求信号了。但在 8259A
工作期间，我们也可以利用操作命令字 OCW1—OCW3 来监测 8259A 的工作状况，或者随时改变初始化
时设定的 8259A 的工作方式。 对这 3 个操作命令字的访问寻址由地址线 A0 和 D4D3 两位组成：当 A0=16.3 setup.S 程序
246
时，访问的是 OCW1；当 A0=0， D4D3=00 时，是 OCW2；当 A=0， D4D3=01 时，是 OCW3。

(1) OCW1 用于对 8259A 中中断屏蔽寄存器 IMR 进行读/写操作。地址线 A0 需为 1。端口地址说明同上。
OCW1 格式见表 6–9 所示。
表 6– 9 中断操作命令字 OCW1 格式
A0 D7 D6 D5 D4 D3 D2 D1 D0
1 M7 M6 M5 M4 M3 M2 M1 M0
位 D7—D0 对应 8 个中断请求 7 级—0 级的屏蔽位 M7—M0。若 M=1，则屏蔽对应中断请求级；若
M=0，则允许对应的中断请求级。另外，屏蔽高优先级并不会影响其他低优先级的中断请求。
在 Linux 0.12 内核初始化过程中，代码在设置好相关的设备驱动程序后就会利用该操作命令字来修
改相关中断请求屏蔽位。例如在软盘驱动程序初始化结束时，为了允许软驱设备发出中断请求，就会读
端口 0x21 以取得 8259A 芯片的当前屏蔽字节，然后与上~0x40 来复位对应软盘控制器连接的中断请求 6
的屏蔽位，最后再写回中断屏蔽寄存器中。参见 kernel/blk_drv/floppy.c 程序第 461 行。

(2) OCW2 用于发送 EOI 命令或设置中断优先级的自动循环方式。当比特位 D4D3 = 00，地址线 A0=0
时表示对 OCW2 进行编程设置。操作命令字 OCW2 的格式见表 6–10 所示。

表 6– 10 中断操作命令字 OCW2 格式

位 名称 含义
D7 R 优先级循环状态。
D6 SL 优先级设定标志。
D5 EOI 非自动结束标志。
D4-3 恒为 0。
D2 L2
L2—L0 3 位组成级别号，分别对应中断请求级别 IRQ0--IRQ7 （或
IRQ8—IRQ15）。
D1 L1
D0 L0
其中位 D7—D5 的组合的作用和含义见表 6–11 所示。其中带有*号者可通过设置 L2--L0 来指定优先级使
ISR 复位，或者选择特殊循环优先级成为当前最低优先级。
表 6– 11 操作命令字 OCW2 的位 D7--D5 组合含义
R(D7) SL(D6) EOI(D5) 含义 类型
0 0 1 非特殊结束中断 EOI 命令（全嵌套方式）。
结束中断
0 1 1 *特殊结束中断 EOI 命令（非全嵌套方式）。
1 0 1 非特殊结束中断 EOI 命令时循环。
1 0 0 自动结束中断 AEOI 方式时循环（设置）。 优先级自动循环
0 0 0 自动结束中断 AEOI 方式时循环（清除）。
1 1 1 *特殊结束中断 EOI 命令时循环。
特殊循环
1 1 0 *设置优先级命令。
0 1 0 无操作。
Linux 0.12 内核仅使用该操作命令字在中断处理过程结束之前向 8259A 发送结束中断 EOI 命令。所6.3 setup.S 程序
247
使用的 OCW2 值为 0x20，表示全嵌套方式下的非特殊结束中断 EOI 命令。

(3) OCW3 用于设置特殊屏蔽方式和读取寄存器状态（ IRR 和 ISR）。当 D4D3=01、地址线 A0=0 时，表
示对 OCW3 进行编程（读/写）。但在 Linux 0.12 内核中并没有用到该操作命令字。 OCW3 的格式见表 6–12
所示。

表 6– 12 中断操作命令字 OCW3 格式

位 名称 含义
D7 恒为 0。
D6 ESMM 对特殊屏蔽方式操作。
D5 SMM D6—D5 为 11 – 设置特殊屏蔽； 10 – 复位特殊屏蔽。
D4 恒为 0。
D3 恒为 1。
D2 P 1 – 查询（ POLL）命令； 0 – 无查询命令。
D1 RR 在下一个 RD 脉冲时读寄存器状态。
D0 RIS D1—D0 为 11 – 读正在服务寄存器 ISR； 10 – 读中断请求寄存器 IRR。

4. 8259A 操作方式说明

在说明 8259A 初始化命令字和操作命令字的编程过程中，提及了 8259A 的一些工作方式。下面对几
种常见的方式给出详细说明，以便能更好地理解 8259A 芯片的运行方式。

(1) 全嵌套方式

在初始化之后，除非使用了操作命令字改变过 8259A 的工作方式，否则它会自动进入这种全嵌套工
作方式。在这种工作方式下，中断请求优先级的秩序是从 0 级到 7 级（ 0 级优先级最高）。当 CPU 响应
一个中断，那么最高优先级中断请求就被确定，并且该中断请求的中断号会被放到数据总线上。另外，
正在服务寄存器 ISR 的相应比特位会被置位，并且该比特位的置位状态将一直保持到从中断服务过程返
回之前发送结束中断 EOI 命令为止。如果在 ICW4 命令字中设置了自动中断结束 AEOI 比特位，那么 ISR
中的比特位将会在 CPU 发出第 2 个中断响应脉冲 INTA 的结束边沿被复位。在 ISR 有置位比特位期间，
所有相同优先级和低优先级的中断请求将被暂时禁止，但允许更高优先级中断请求得到响应和处理。再
者，中断屏蔽寄存器 IMR 的相应比特位可以分别屏蔽 8 级中断请求，但屏蔽任意一个中断请求并不会影
响其他中断请求的操作。最后，在初始化命令字编程之后， 8259A 引脚 IR0 具有最高优先级，而 IR7 的
优先级最低。 Linux 0.12 内核代码即把系统的 8259A 芯片设置工作在这个方式下。

(2) 中断结束（ EOI）方法

如上所述，正在服务寄存器 ISR 中被处理中断请求对应的比特位可使用两种方式来复位。其一是当
ICW4 中的自动中断结束 AEOI 比特位置位时，通过在 CPU 发出的第 2 个中断响应脉冲 INTA 的结束边
沿被复位。这种方法称为自动中断结束（ AEOI）方法。其二是在从中断服务过程返回之前发送结束中断
EOI 命令来复位。这种方法称为程序中断结束（ EOI）方法。在级联系统中，从片中断服务程序需要发
送两个 EOI 命令，一个用于从片，另一个用于主片。

程序发出 EOI 命令的方法有两种格式。一种称为特殊 EOI 命令，另一种称为非特殊 EOI 命令。特殊
的 EOI 命令用于非全嵌套方式下，可用于指定 EOI 命令具体复位的中断级比特位。即在向芯片发送特殊
EOI 命令时需要指定被复位的 ISR 中的优先级。特殊 EOI 命令使用操作命令字 OCW2 发送，高 3 比特位
是 011，最低 3 位用来指定优先级。在目前的 Linux 系统中就使用了这种特殊 EOI 命令。用于全嵌套方
式的非特殊 EOI 命令会自动地把当前正在服务寄存器 ISR 中最高优先级比特位复位。因为在全嵌套方式
下 ISR 中最高优先级比特位肯定是最后响应和服务的优先级。它也使用 OCW2 来发出，但最高 3 比特位
需要为 001。本书讨论的 Linux 0.12 系统中则使用了这种非特殊 EOI 命令。6.4 head.s 程序
248

(3) 特殊全嵌套方式

在 ICW4 中设置的特殊全嵌套方式（ D4=1）主要用于级联的大系统中，并且每个从片中的优先级需
要保存。这种方式与上述普通全嵌套方式相似，但有以下两点例外：

A. 当从某个从片发出的中断请求正被服务时，该从片并不会被主片的优先级排除。因此该从片发出
的其他更高优先级中断请求将被主片识别，主片会立刻向 CPU 发出中断。而在上述普通全嵌套方式中，
当一个从片中断请求正在被服务时，该从片会被主片屏蔽掉。因此从该从片发出的更高优先级中断请求
就不能被处理。

B. 当退出中断服务程序时，程序必须检查当前中断服务是否是从片发出的唯一一个中断请求。检查
的方法是先向从片发出一个非特殊中断结束 EOI 命令，然后读取其正在服务寄存器 ISR 的值。检查此时
该值是否为 0。如果是 0，则表示可以再向主片发送一个非特殊 EOI 命令。若不为 0，则无需向主片发送
EOI 命令。

(4) 多片级联方式

8259A 可以被很容易地连接成一个主片和若干个从片组成的系统。若使用 8 个从片那么最多可控制
64 个中断优先级。主片通过 3 根级联线来控制从片。这 3 根级联线相当于从片的选片信号。在级联方式
中，从片的中断输出端被连接到主片的中断请求输入引脚上。当从片的一个中断请求线被处理并被响应
时，主片会选择该从片把相应的中断号放到数据总线上。
在级联统中，每个 8259A 芯片必须独立地进行初始化，并且可以工作在不同方式下。另外，要分别
对主片和从片的初始化命令字 ICW3 进行编程。在操作过程中也需要发送 2 个中断结束 EOI 命令。一个
用于主片，另一个用于从片。

(5) 自动循环优先级方式

当我们在管理优先级相同的设备时，就可以使用 OCW2 把 8259A 芯片设置成自动循环优先级方式。
即在一个设备接受服务后，其优先级自动变成最低的。优先级依次循环变化。最不利的情况是当一个中
断请求来到时需要等待它之前的 7 个设备都接受了服务之后才能得到服务。

(6) 中断屏蔽方式

中断屏蔽寄存器 IMR 可以控制对每个中断请求的屏蔽。 8259A 可设置两种屏蔽方式。对于一般普通
屏蔽方式，使用 OCW1 来设置 IMR。 IMR 的各比特位（ D7--D0）分别作用于各个中断请求引脚 IR7 -- IR0。
屏蔽一个中断请求并不会影响其他优先级的中断请求。对于一个中断请求在响应并被服务期间（没有发
送 EOI 命令之前），这种普通屏蔽方式会使得 8259A 屏蔽所有低优先级的中断请求。但有些应用场合可
能需要中断服务过程能动态地改变系统的优先级。为了解决这个问题， 8259A 中引进了特殊屏蔽方式。
我们需要使用 OCW3 首先设置这种方式（ D6、 D5 比特位）。在这种特殊屏蔽方式下， OCW1 设置的屏
蔽信息会使所有未被屏蔽的优先级中断均可以在某个中断过程中被响应。

(7) 读寄存器状态

8259A 中有 3 个寄存器（ IMR、 IRR 和 ISR）可让 CPU 读取其状态。 IMR 中的当前屏蔽信息可以通
过直接读取 OCW1 来得到。在读 IRR 或 ISR 之前则需要首先使用 OCW3 输出读取 IRR 或 ISR 的命令，
然后才可以进行读操作。
