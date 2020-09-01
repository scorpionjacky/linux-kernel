# head.s

# 包含32为保护模式初始化设置代码、时钟中断代码、系统调用中断代码和两个任务代码
# 在初始化完成之后程序移动到任务0开始执行，并在时钟中断控制下进行任务0和1之间的
# 切换操作

#  head.s contains the 32-bit startup code.
#  Two L3 task multitasking. The code of tasks are in kernel area, 
#  just like the Linux. The kernel code is located at 0x10000.

#  编译方法
#  as -o head.o head.s
#  这是一个运行在保护模式下的AT&T汇编写的多任务内核
#  代码包括
#  1 初始化设置代码
#  2 时钟中断代码
#  3 系统调用中断代码 
#  4 任务a和任务b的代码
#  在初始化完成之后程序移动到任务0开始执行，
#  并在时钟中断控制下进行任务0和任务1之间的切换

#  书上代码需要修改的地方
#  movl scr_loc, %bx => movlscr_loc, %ebx
#  movl $65, %al => movb $65, %al
#  movl $66, %al => movb $66, %al
#  align 2 => align 4
#  align 3 => align 8

SCRN_SEL  = 0x18      # 屏幕显示内存段选择符
TSS0_SEL  = 0x20      # 任务0的TSS段选择符
LDT0_SEL  = 0x28      # 任务0的LDT段选择符
TSS1_SEL  = 0x30      # 任务1的TSS段选择符
LDT1_SEL  = 0x38      # 任务1的LDT段选择符

# 定时器初始计数值，即每隔10毫秒发送一次中断请求
# 由于8254芯片的时钟输入频率为1193180 Hz，
# 所以芯片每隔1193190/100次计数，
# 就会发出一个时钟中断请求信号，
# 也就是每隔10毫秒左右(1秒的1/100)

# change to 1000ms
LATCH     = 1193000


.global startup_32

.text

# startup_32是特殊的标号，表示保护程序的开始位置
startup_32:

  # 首先加载数据段寄存器DS、堆栈寄存器SS和堆栈指针ESP。
  # 所有段的线性基地址都是0
  # 作为三个段之一的CS此处不用重新设置，
  # 完全是因为本次执行是从boot用长跳转jmpi指令过来的，
  # 这个指令有副作用，会设置CS寄存器的值为长跳转的段寄存器
  movl $0x10,%eax   # 0x10是GDT中数据段选择符
  # 对ds 赋值为0X10 就是GDT中数据段选择符2 0是空的 1是代码段 2 是数据段
  mov %ax,%ds
  # lss指令把，段地址:偏移地址 存到ss:esp
  # 把init_stack 有效地址（就是偏移）给esp堆栈指针,把ox10给ss（堆栈段地址）
  lss init_stack,%esp
  
  # 在新的位置重新设置IDT和GDT表
  # setup base fields of descriptors.
  call setup_idt    # 设置IDT，先把256个中断门都填默认处理过程描述符
  call setup_gdt    # 设置GDT
  movl $0x10,%eax   # 在改变了GDT之后重新加载所有段寄存器
  mov %ax,%ds
  mov %ax,%es
  mov %ax,%fs
  mov %ax,%gs
  lss init_stack,%esp
  
  # 设置8253定时芯片。
  # 把计数器通道0设置成每隔10毫秒向中断控制器发送一个中断请求信号
  movb $0x36, %al    # 控制字：设置通道0工作在方式3、计数初值采用二进制
  movl $0x43,%edx    # 8253芯片控制字寄存器写端口
  outb %al,%dx
  movl $LATCH,%eax   # 初始计数值设置为LATCH（1193180/100）频率100HZ
  # movl $11930, %eax
  movl $0x40,%edx    # 通道0的端口号
  outb %al,%dx       # 分两次把初始计数值写入通道0
  movb %ah,%al
  outb %al,%dx

  # 在IDT表第8和第128（0x80）项处分别设置
  # 定时中断门描述符和系统调用陷阱门描述符
  
  movl $0x00080000,%eax       # 中断程序属内核，即EAX高字是内核代码段选择符0x0008
  movw $timer_interrupt,%ax   # 设置定时中断门描述符，取定时中断处理程序地址
  movw $0x8E00,%dx            # 中断门类型是14（屏蔽中断），特权级0或硬件使用
  
  movl $0x08,%ecx             # 开机时BIOS设置的时钟中断向量号8，这里直接使用
  lea idt(,%ecx,8),%esi       # 把IDT描述符0x80地址放到ESI中，然后设置该描述符
  movl %eax,(%esi)
  movl %edx,4(%esi)
  movw $system_interrupt,%ax  # 设置系统调用陷阱门描述符，系统调用处理程序地址
  movw $0xef00,%dx            # 陷阱门类型是15,特权级3的程序可执行
  movl $0x80,%ecx             # 系统调用向量号0x80
  lea idt(,%ecx,8),%esi       # 把IDT描述符项0x80地址放到ESI中，然后设置描述符
  movl %eax,(%esi)
  movl %edx,4(%esi)

  # unmask the timer interrupt.
  # movl $0x21, %edx
  # inb %dx, %al
  # andb $0xfe, %al
  # outb %al, %dx

  # 好了，现在我们为移动到任务0（任务A）中执行来操作堆栈内存，
  # 在堆栈中人工建立中断返回时的场景
  
  # 为人工移动到任务0准备堆栈
  pushfl                  # 复位标志寄存器EFLAGS中的嵌套任务标志
  andl $0xfffbfff,(%esp)
  popfl
  movl $TSS0_SEL,%eax     # 把任务0的TSS段选择符加载到任务寄存器TR
  ltr %ax
  movl $LDT0_SEL,%eax     # 把任务0的LDT段选择符加载到局部描述符表寄存器LDTR
  lldt %ax                # TR和LDTR只需人工加载一次，以后CPU会自动处理
  movl $0,current         # 把当前任务号0保持在current变量中
  sti                     # 现在开启中断，并在栈中营造中断返回时的场景
  pushl $0x17             # 把任务0当前局部空间数据段（堆栈段）选择符入栈
  pushl $init_stack       # 把堆栈指针入栈（也可以把ESP入栈）
  pushfl                  # 把标志寄存器值入栈
  pushl $0x0f             # 把当前局部空间代码段选择符入栈
  pushl $task0            # 把代码指针入栈
  iret                    # 执行中断返回指令，从而切换到特权级3的任务0执行

# 以下是设置GDT和IDT中描述符项的子程序
setup_gdt:                # 用6字节操作数lgdt_opcode设置GDT表位置和长度
  lgdt lgdt_opcode
  ret

# 这段代码暂时设置IDT表中所有256个中断门描述符都为同一个默认值，
# 均使用默认的中断处理过程ignore_int。设置的具体方法是：首先在
# eax和edx寄存器对中分别设置好默认中断门描述符的0-3字节和4-7字节
# 的内容，然后利用该寄存器对循环往IDT表中填充默认中断门描述符内容

# 把所有256个中断门描述符设置为使用默认处理过程
# 设置方法与设置定时中断门描述符的方法一样
setup_idt:
  lea ignore_int,%edx
  movl $0x00080000,%eax  # 选择符为0x0008
  movw %dx,%ax           # selector = 0x0008 = cs
  movw $0x8E00,%dx       # 中断门类型，特权级为0， dpl=0, present
  lea idt,%edi
  mov $256,%ecx          # 循环设置所有256个门描述符项
rp_idt:
  movl %eax,(%edi)
  movl %edx,4(%edi)
  addl $8,%edi
  dec %ecx
  jne rp_idt
  lidt lidt_opcode       # 最后用6字节操作数加载IDTR寄存器
  ret

# 显示字符子程序。取当前光标位置并把AL中的字符显示在屏幕上。
# 整个屏幕可以显示80x25个字符
write_char:
  push %gs             # 首先保存要用到的寄存器，EAX由调用者负责保存
  pushl %ebx
  mov $SCRN_SEL,%ebx   # 然后让GS指向显示内存段（0xb8000）
  mov %bx,%gs
  movl scr_loc,%ebx    # 再从变量scr_loc中取目前字符显示设置值
  shl $1,%ebx          # 因为在屏幕上每个字符还有一个属性字节，因为字符
  movb %al,%gs:(%ebx)  # 实际显示位置对应的显示内存偏移地址要乘2
  shr $1,%ebx          # 把字符放到显示内存后把位置除2加1,此时位置值对
  incl %ebx            # 应下一个显示位置。如果该位置大于2000，则复位成0
  cmpl $2000,%ebx
  jb 1f
  movl $0,%ebx
1:
  movl %ebx,scr_loc    # 最后把这个位置值保存起来（src_loc）
  popl %ebx            # 并弹出保持的寄存器内容，返回
  pop %gs
  ret

# 以下是3个中断处理程序：默认中断、定时中断和系统调用中断
# ignore_int是默认的中断处理程序，若系统产生了其他中断，则会在屏幕上显示一个‘C’
.align 4    # align 2
ignore_int:
  push %ds
  pushl %eax
  movl $0x10,%eax   # 首先让DS指向内核数据段，因为中断程序属于内核
  mov %ax,%ds
  movl $67,%eax     # 在AL中存放字符'C'的代码，调用显示程序显示在屏幕
  call write_char
  popl %eax
  pop %ds
  iret

# 这是定时中断处理程序。其主要执行任务切换操作
.align 4    # align 2
timer_interrupt:
  push %ds
  pushl %eax
  movl $0x10,%eax   # 首先让DS指向内核数据段，因为中断处理属于内核
  mov %ax,%ds
  movb $0x20,%al    # 然后立刻允许其他硬件中断，即向8259A发送EOI命令
  outb %al,$0x20
  movl $1,%eax      # 接着判断当前任务，若是任务1则去执行任务0,或反之
  cmpl %eax,current
  je 1f
  movl %eax,current  # 若当前任务是0,则把1存入current，并跳转到任务1
  ljmp $TSS1_SEL,$0  # 去执行，注意跳转的偏移值无用，但需要写上
  jmp 2f
1:
  movl $0,current    # 若当前任务是1,则把0存入current，并跳转到任务0
  ljmp $TSS0_SEL,$0  # 去执行
2:
  popl %eax
  pop %ds
  iret

# 系统调用中断int 0x80处理程序，该示例只有一个显示字符功能
.align 4    # align 2
system_interrupt:
  push %ds
  pushl %edx
  pushl %ecx
  pushl %ebx
  pushl %eax
  movl $0x10,%edx   # 首先让DS指向内核数据段
  mov %dx,%ds
  call write_char   # 然后调用显示字符子程序write_char，显示AL中的字符
  popl %eax
  popl %ebx
  popl %ecx
  popl %edx
  pop %ds
  iret

/*********************************************************/
# 数据区。没有专门定义，是和代码区混合编写的。

current:
  .long 0     # 当前任务号（0或1）
scr_loc:
  .long 0     # 屏幕当前显示位置，按照从左上到右下顺序显示

.align 4    # align 2
# 加载IDTR寄存器的6字节操作数：表长度和基地址
lidt_opcode:
  # 16位表长，没法通过减法获得长度，是通过调用fill填充的
  .word 256*8-1
  .long idt      # 32位基地址
# 加载GDTR寄存器的6字节操作数：表长度和基地址
lgdt_opcode:
  # 16位表长，可以通过减法获得长度。
  .word (end_gdt-gdt)-1
  .long gdt      # 32位基地址

.align 8
idt:
  .fill 256,8,0   # IDT空间。共256个门描述符，每个8字节，共2KB
gdt:
  # NULL descriptor
  .quad 0x0000000000000000    # GDT表。第1个描述符不用。quad是4字节宽度
  
  .quad 0x00c09a00000007ff    # 第2个是内核代码段描述符。其选择符是0x08。
  /* 8Mb 0x08, base = 0x00000 */
  # 第2描述符，内核代码段，基地址0 段限长7ff，2047字节，选择符0x08 = 1:0:00
  #   |    |  
  #   +----+  高地址   方便查表的格式
  #   | 00 |          | 00 c0 9a 00 |   
  #   +----+          | 00 00 07 ff |
  #   | c0 |
  #   +----+  
  #   | 9a |
  #   +----+  
  #   | 00 |
  #   +----+  
  #   | 00 |
  #   +----+  
  #   | 00 |
  #   +----+  
  #   | 07 |
  #   +----+  低地址
  #   | ff |  
  #   +----+  
  #   |    | 
  
  .quad 0x00c09200000007ff    # 第3个是内核代码段描述符。其选择符是0x10。
  /* 8Mb 0x10 */
  # 第3描述符，内核数据段，基地址0 只有TYPE段类型与第2描述符不一样, 选择符0x08 = 10:0:00
  
  .quad 0x00c0920b80000002    # 第4个是内核代码段描述符。其选择符是0x18。
  /* screen 0x18 - for display */
  #  4K颗粒度，数据段 ，读写，基地址0xb8000,段限长度为0x0002,实际段长度是8KB
  #  对应到显示内存区域上     2*颗粒度（4K）=8KB

  .word 0x68,tss0,0xe900,0x0  # 第5个是TSS0段的描述符。其选择符是0x20。
  # 第5描述符，TSS0段的描述符,基地址tss0,段限长104(0x68)
  #   |        |  
  #   +--------+  高地址   方便查表的格式
  #   | 0x0000 |          | 00 00 e9 00 |      
  #   +--------+          | tss0  00 68 |
  #   | 0xe900 |
  #   +--------+  
  #   | tss0   |
  #   +--------+  
  #   | 0x0068 |  
  #   +--------+  低地址
  #   |        |
  
  .word 0x40,ldt0,0xe200,0x0  # 第6个是LDT0段的描述符。其选择符是0x28。
  # 第6描述符，LDT0段的描述符，基地址ldt0，段限长0x40
  
  .word 0x68,tss1,0xe900,0x0  # 第7个是TSS1段的描述符。其选择符是0x30。
  # 第7描述符，TSS1段的描述符，基地址tss1，段限长0x68
  
  .word 0x40,ldt1,0xe200,0x0  # 第8个是LDT1段的描述符。其选择符是0x38。
  # 第8描述符，LDT1段的描述符，基地址ldt1，段限长0x40
end_gdt:    #用来计算gdt表的长度
  .fill 128,4,0      # 初始内核堆栈空间，后续给任务0当做内核数据段

init_stack: # 刚进入保护模式时用于加载SS:ESP堆栈指针值
  .long init_stack   # 堆栈偏移位置
  .word 0x10         # 堆栈段起始地址，同数据段

# 下面是任务0的LDT表段中的局部段描述符
.align 8
ldt0:
  .quad 0x0000000000000000    # 第1个描述符，不用
  .quad 0x00c0fa00000003ff    # 第2个局部代码段描述符，对应选择符0x0f，基地址是0，段限长3ff
  .quad 0x00c0f200000003ff    # 第3个局部数据段描述符，对应选择符0x17，基地址是0，段限长3ff
# 下面是任务0的TSS段的内容，注意其中标号等字段在任务切换时不会改变
tss0:
  .long 0                     /* back link */
  .long krn_stk0,0x10         /* esp0, ss0 */
  .long 0,0,0,0,0             /* esp1, ss1, esp2, ss2, cr3 */
  .long 0,0,0,0,0             /* eip, eflags, eax, ecx, edx */
  .long 0,0,0,0,0             /* ebx, esp, ebp, esi, edi */
  .long 0,0,0,0,0,0           /* es, cs, ss, ds, fs, gs */
  .long LDT0_SEL,0x8000000    /* ldt, trace bitmap */
  .fill 128,4,0               # 这是任务0的内核栈空间
krn_stk0:

# 下面是任务1的LDT表段内容和TSS段内容
.align 8
ldt1:
  .quad 0x0000000000000000    # 第1个描述符，不用
  .quad 0x00c0fa00000003ff    # 第2个局部代码段描述符，对应选择符0x0f
  .quad 0x00c0f200000003ff    # 第3个局部数据段描述符，对应选择符0x17
tss1:
  .long 0                     /* back link */
  .long krn_stk1,0x10         /* esp0, ss0 */
  .long 0,0,0,0,0             /* esp1, ss1, esp2, ss2, cr3 */
  .long task1, 0x200          /* eip, eflags */
  .long 0,0,0,0               /* eax, ecx, edx, ebx */
  .long usr_stk1,0,0,0        /* esp, ebp, esi, edi */
  .long 0x17,0x0f,0x17,0x17,0x17,0x17     /* es, cs, ss, ds, fs, gs */
  .long LDT1_SEL,0x8000000    /* ldt, trace bitmap */
  .fill 128,4,0               # 这是任务1的内核栈空间
krn_stk1:

# 下面是任务0和任务1的程序，他们分别循环显示字符‘A’和‘B’
task0:
  # movl $0x17,%eax    # 首先让DS指向任务的局部数据段
  # movw %ax,%ds       # 因为任务没有使用局部数据，所以这2句可省略
  movb $65,%al       # 把需要显示的字符‘A’放入AL寄存器中
  int $0x80          # 执行系统调用，显示字符
  movl $0xfff,%ecx   # 执行循环，起延时作用
1:
  loop 1b
  jmp task0          # 跳转到任务代码开始处继续显示字符

task1:
  # movl $0x17,%eax
  # movw %ax,%ds
  movb $66,%al       # 把需要显示的字符‘B‘放入AL寄存器中
  int $0x80          # 执行系统调用，显示字符
  movl $0xfff,%ecx   # 延时一段时间，并跳转到开始处继续循环显示
1:
  loop 1b
  jmp task1

  .fill 128,4,0      # 这是任务1的用户栈空间
usr_stk1:
