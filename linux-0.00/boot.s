! boot.s 程序

! 编译方法
! as86 -0 -a -o boot.o boot.s
! ld86 -0 -s -o boot boot.o

! 这是512K的引导程序，做了如下的工作:
! 1 使用BIOS的0x13中断，读取真正内核到内存
! 2 将内核移动到内存开始位置
! 3 设置保护模式下的初始GDT/IDT
! 4 切换到保护模式
! 5 跳转到内核开始位置执行
! mov cx,#0x2000 here need modify
! to 0x1000???


! 首先利用 BIOS 中断把内核代码（head代码）加载到内存0x10000处，然后移动到内存0处
! 最后进入保护模式，并跳转到内存0（head代码）开始处继续运行

! 引导程序（本程序, 512字节）被BIOS加载到内存0x7c00处
BOOTSEG = 0x07c0
! 内核（head）先加载到0x10000处，然后移动到0x0处
SYSSEG  = 0x1000
! 内核占用的最大磁盘扇区数
SYSLEN  = 17

entry start
start:
  ! 段间跳转到0x07c0:go处。
  ! BIOS已经将本程序加载到0x07c0的位置，
  ! 目前是在实模式下，启动时段寄存器的缺省值是00，
  ! 所以此处实际还是跳转到go，0的位置，
  ! 同时段间跳转会修改CS和IP的值，
  ! 这句执行完后，CS被设置为0x07c0，IP被设置为go
  ! 当本程序刚运行时所有段寄存器值均为0。
  ! 该跳转语句会把CS寄存器加载到0x07c0（原为0）。
  jmpi go,#BOOTSEG

go:
  ! 让DS和SS都指向0x07c0段，（段寄存器只能接受寄存器）
  mov ax,cs
  mov ds,ax
  mov ss,ax
  ! 设置临时栈指针，其值需大于程序末端并有一定空间。
  ! arbitrary value >>512
  mov sp,#0x400

! ok, we've written the message, now
! register oneself

! 实模式下初始的中断向量表是在跳转到0x07c0之前，已经由BIOS设置好

! 加载内核代码到内存0x10000开始处
! 利用BIOS中断int 0x13功能2从启动盘读取head代码。
! DH - 磁头号；DL - 磁盘驱动号；CH - 10位磁道号低8位
! CL - 位7、6是磁道号高2位，位5-0起始扇区号（从1计）
! ES:BX - 读入缓冲区设置（0x1000:0000）。
! AH - 读扇区功能号，AL - 需读的扇区数（17）
load_system:
  mov dx,#0x0000
  mov cx,#0x0002
  mov ax,#SYSSEG
  mov es,ax
  ! 清空bx，ES:BX(0x10000:0x0000)是读入缓冲区位置
  xor bx,bx
  mov ax,#0x200+SYSLEN
  int 0x13
  ! 若没有发生错误则跳转继续运行，否则死循环
  jnc ok_load
die:
  jmp die

! 把内核代码移动到内存0开始处，共移动8KB字节（内核长度不超过8KB）
ok_load:
  ! 关中断
  ! 之所以要关闭中断，是因为此时已经将内核加载完毕，
  ! 而加载内核是需要使用BIOS提供的0x13中断的，
  ! 所以在加载完内核前不能关闭中断。
  ! 而后续要转入保护模式并且使用多任务，
  ! 在内核完全准备好后续操作前，要将中断关闭。
  ! 否则中断会破坏内核的初始化。
  ! 后续再开启多任务时，会再次开启中断。
  cli
  ! 为rep指令做准备，
  ! 把要内核要开始移动的位置，放入DS:SI,
  ! 目的地位置放入ES:DI，移动次数放入cx，
  ! cx是移动次数4096(0x1000转换为10进制)次
  ! 移动开始位置DS:SI = Ox1000:0；目的位置 ES:DI = 0:0
  mov ax,#SYSSEG
  mov ds,ax
  xor ax,ax
  mov es,ax
  ! 设置共移动4k次，每次移动一个字（word）
  mov cx,#0x1000
  sub si,si
  sub di,di
  rep
  movsw  ! 执行重复移动指令, 每次移动一个字

  ! 加载IDT和GDT基地址寄存器IDTR和GDTR

  ! 因为刚使用了ds，要先让DS重新指向0x07c0段
  mov ax,#BOOTSEG
  mov ds,ax
  ! 加载IDTR。6字节操作数：2字节长度，4字节线性基地址
  lidt idt_48
  ! 加载GDTR。6字节操作数：2字节长度，4字节线性基地址
  lgdt gdt_48

  ! GDTR: 全局描述符表寄存器 赵炯第四章 
  ! 指令LGDT和SGDT 用于加载和保存GDTR寄存器的内容
  ! 加电或者复位之后，基地址是0，长度值被设置为0XFFF，
  ! 在保护模式初始化过程中，必须给GDTR加载一个新值
  ! absolute address 0x00000, in 32-bit protected mode.

  ! 设置控制寄存器CR0（即机器状态字），进入保护模式。
  ! 段选择符值8对应GDT表中第2个段描述符
  
  ! 在CR0中设置保护模式标志PE（位0）
  mov ax,#0x0001
  lmsw ax
  
  ! 注意此时段值已是段选择符，该段线性基地址是0
  ! 然后跳转到段选择符指定的段中，偏移0处
  
  ! 虽然执行LMSW指令以后切换到了保护模式，
  ! 但该指令规定其后必须紧随一条段间跳转指令以
  ! 刷新CPU的指令缓冲队列。因此在LMSW指令后，CPU还是继续执行下一条指令
  ! 此处0,8已经是保护模式的地址，8是选择符，0是偏移地址
  ! 跳转到段选择符是8，偏移0的地址处,段选择符8转化为16位2进制为
  ! 0000000000001        0          00
  ! |--描述符索引--|--GDT/LDT--|--特权级--|
  ! 其中0为GDT 1为LDT
  ! 其中00为特权级0 11为特权级3
  ! 其中描述符索引1是CS段选择符，可详见下面gdt的定义
  
  ! jmpi 有副作用，会设置CS的值

  ! jmp offset 0 of segment 8 (cs)  1000 段选择符，
  ! 选择第二个，作为全局描述符，	
  ! 所以从线性基地址8 偏移0开始运行程序
  jmpi 0,8

! 下面是全局描述符表GDT的内容， 其包含3个段描述符，
! 第1个必须清零(null descriptor)，
! 第2个是代码段，第三个是数据段

gdt:
  ! 段描述符0，必需清零，每个描述符占8字节
  .word 0,0,0,0  

  ! .word 0x07FF,0x0000,0x9A00,0x00c0

! 段描述符1：8Mb - 段限长值
  ! 8Mb - limit=2047 (2048*4096=8Mb)
  .word 0x07ff
  ! 段基地址=0x0000
  ! base address=0x00000  基地址
  .word 0x0000
  ! 是代码段，可读/执行
  ! code read/exec
  .word 0x9A00
  ! 段属性颗粒度=4KB
  ! granularity=4096, 386
  .word 0x00C0

  ! .word 0x07FF,0x0000,0x9200,0x00c0
  .word 0x07ff
  .word 0x0000
  .word 0x9200  ! 与上不同
  .word 0x00C0

! 下面分别是LIDT和LGDT指令的6字节操作数
! IDTR |---32位表基地址---|--16位表长度--|
! GDTR |---32位表基地址---|--16位表长度--|
! word. 16位长度,32位基地址

idt_48:
  ! .word 0,0,0
  .word 0    ! IDT表长度是0， idt limit=0
  .word 0,0  ! IDT表的线性基地址也是0， idt base=0L

gdt_48:
  ! .word 0x7ff,0x7c00+gdt,0
  
  ! GDT表长度是2048字节，可容纳256个描述符项
  ! gdt limit=2048, 256 GDT entries
  .word 0x07ff
  ! GDT表的线性基地址在0x07c0段的偏移gdt处
  ! gdt base = 07xxx
  .word 0x7c00+gdt,0

! 引导扇区有效标志，必须处于引导扇区最后2字节
.org 510
    .word 0xAA55
