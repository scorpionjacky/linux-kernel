# 8086 Real Mode Addressing Romance

Original Post
- https://bbs.pediy.com/thread-115101.htm
- https://titanwolf.org/Network/Articles/Article?AID=284fab03-7938-4891-a8af-b7cd845efecc#gsc.tab=0

[Chinese Version](#chinese)

## 8086 Real Mode Addressing Romance

For 8088 real mode addressing, the textbook only says: 16 + 4 = 20 bits, so the 16-bit segment address is shifted left by 4 bits + 16 bit offset = 20 bits of physical address. Many people are just rote memorization, in fact they don't know the meaning, and they still feel dizzy. How can 16 bits be shifted to the left by 4 bits, and then add 16 bits to shift to 20 bits? Let's start with a story. A little-known story ============ Now, people know how great Intel and Microsoft are, if you really understand their growth process, you will find that they are also very ordinary, even not how about it. Just like Zhou Enlai and other Chinese elites, they would foolishly hand over the command of the Red Army to a German, and let the Red Army be defeated. If you don't say anything else now, a traitor and collusion with anti-China forces can drown them! Pull away, pull back. When IBM decided to use the 8088 chip to develop an IBM PC, and when Gates wanted to produce an operating system for the proposed IBM PC, Intel warned them both, saying you should not use that, we are developing a new 16-bit CPU (80286) You will regret it with 8088. However, since neither IBM nor Gates knew what happened to the PC computer operating system, they did not listen. Gates bought an operating system from a company in Washington. (Seattle Computer Products) this OS is called QDOS (Quick and Dirty Operating System), it was basically developed for 8086 by three former DRI (Digital Research Inc), these three people established A new company, and basically copied the CP/M and converted it to 16 bits, using and increasing the memory capacity (from 64K to 1024K). However, when it was developed as a 16-bit CP/M, it was not written to protected mode. Later, Gates made a few small changes to IBM and renamed it to something like 86-DOS or DOS-86 or something similar. It is basically designed for CP/M users. In fact, the first IBM personal computers (before they were called personal computers) boasted that CP/M programs could be run on it. ----- Look at the taste of fraud and profiteers? So for a long time, the developers of unix and OS/2 thought that DOS was not a real operating system at all. 8086/8088 addressing problem =============== Both 8088 and 80286 are 16-bit CPUs. Why did Intel warn IBM and Gates? In the end what happened? To understand what happened, we have to look at the inside of the processor and we will see huge differences. First, you find a piece of 8088 CPU, grind the packaging, grind it to the CPU silicon wafer, put it under the microscope, you will see the internal structure of 8086/88, it is not a new design at all, but two 8085 running in parallel (8 bits) There are so many more microprocessors. Each 8085 has its own 8-bit data and 16-bit addressing capabilities. Combining two 8-bit data registers to pretend to be a 16-bit register is easy. In fact, there is nothing new. The RCA COSMAC microprocessor uses 16 8-bit registers, which can be used as internal 8-bit or 16-bit registers. You can have up to 16 8-bit registers or 8 16-bit registers or any combination of the two. Now, a common IC factory in China can be easily designed. Probably due to the limitation of the production process at that time, 8088 can only have 40 feet. Intel's design "elite" left and right thought, determined 20 address lines (1M addressing space), and 16 data lines have to be 20. There are 16 multiplexes in the address line (time-sharing multiplex, that is, one will be the address line and the other will be the data line. To understand this, you can see the timing part of the 8088 chip manual, or you can read the 8052 microcontroller books, Its address lines and data lines are also multiplexed). To the essence of the problem, the two 8085 in 8088 each have a set of 16-bit addressing registers, how to let them address 20-bit 1M address? In fact, it is very simple to put them together to form 32-bit addressing. If that is the case, then many of the troubles may be gone (such as the A20 gate), but those "elites" may think that 32-bit addressing (4G address space) at that time Is it nonsense, it is estimated that the earth has disappeared and not so much memory is used? Besides, the boss was too tight, so they used two 8085 on a piece of hardware to achieve a very good method-segmentation: They divided the 1024K address space into 16-byte segments, a total of 64K segments, with a 8085 The 16-bit addressing register is used as the address offset register (so the length of the segment is 64K), and the other 16-bit addressing register of 8085 is used as the segment address register of the 16-byte segment. Note that he does not save the 16-byte segment Address, but the serial number of the 16-byte segment (0, 1, ... 65535). The advantage of this is that as long as a shifter and a 20-bit adder are added between two 8085 CPUs, the 20-bit address addressing can be completed-a 8085 address register (segment address-is 16 bytes) The number of the segment) is shifted by 4 bits to the left (* 16 = the first address of the 16-byte small segment), plus another address register of 8085, haha! You can pay the boss, the production cost is low, the design speed is fast, and the rich are not grandchildren! As for the future, . . . In fact, the size of the segment from 16 to 64K bytes can be achieved through a similar method of 1M addressing, why the elites do n’t choose 16 bytes? Because the 16-byte segment has the least displacement in the register forming the address period, it is best to achieve it. Think about it, if you want to implement 32-bit addressing, you need to add a multiplier between the two 8085, but if you realize the software developers will save much. . . . In addition, be aware that the 64-bit CPU did not break through the 32-bit address space limitation. The textbook only talks about: 16 + 4 = 20 bits, so the 16-bit segment address is shifted left by 4 bits + 16 bit offset = 20 bits of physical address. Many people are just rote memorization, in fact they don't know the meaning, and they still feel dizzy. How can 16 bits be shifted to the left by 4 bits, and then add 16 bits to shift to 20 bits? Its commercial and professional meanings are coping, co-opting, and a little bit of fooling. Using testimonials, at most, it is also the market with the lowest cost and the fastest speed. It is not technically perfect. The theoretical essence is: segmentation, 1024K is divided into 64k 16-byte segments, and the segment register does not store the segment's first address, but the segment's serial number. I do n’t know why, textbooks have never stated that way. At 80286, it was not just a mess of things to seize the market, or the foundation of 8088 was too bad, so that the design complexity factor of 80286 was too high, or other reasons, the Intels made two very low-level errors, so that 80286 had Two major flaws: First, he claimed that 80286 is compatible with 8086/8088 real mode, but when the real mode address reaches the top of 1024K and cannot be rewound, and 8088 circumvents, that is, when the address reaches FFFFFH, it will increase to 0. As a result, the painful problem of the A20 gate was generated, which caused IBM to have a very nasty way to use the keyboard controller to access the height of the A20 address line, so as to realize the address rewind in real mode to be compatible with 8088. This problem has evolved over time (it can be lengthy when written specifically) and has caused considerable trouble for software developers for a long time. Second, there is no way to return to real mode after 80286 enters protected mode from real mode, it must be reset! 80286 has 16M of storage space, but real mode can only access 1M, that is to say, to use more than 1M of memory, you must switch to protected mode, but you must reset the CPU when you come back, this is what kind of programmers in real mode Torture and torture? Of course, the problem has been solved by 386, however, so far, the A20 door has always existed. Take a look at how the 80286 bios designer conducted a memory self-test. When the PC starts, the bios first executes other programs that should be executed in real mode. When the memory self-test is performed, it first switches to protected mode, but completes the memory self-test, and then Set some flags in the keyboard controller, reset the CPU, and re-execute the BIOS, but it will check the flags in the keyboard controller and find that it is a hot reset of the bios, then jump to the reset and then execute. The vested interests of the technology empire bundled by the dictator of Intel's technology empire (such as IBM, Microsoft, etc.) are competing to return such a bad 80286 to consumers, showing the danger of technology monopoly. The reason why Intel, Microsoft, etc. are so deep, mysterious, and great is that they are so deep, mysterious, and great that they have been brainwashed by them or brainwashed by themselves. And for themselves, the initial volume is just ordinary people who occupy a little opportunity. When they reveal their inside story, it is far from being as deep, mysterious, and great as people think, and even full of filth.

<a id="chinese"></a>
## [原创]8086实模式寻址演义 
 
*2010-6-14 18:48  7094*

https://bbs.pediy.com/thread-115101.htm

对于8088实模式寻址，教科书上只讲：１６＋４＝２０位，所以１６位段地址左移４位＋１６位偏移＝２０位物理地址。很多人也只是死记，其实并不知道其含义，而且还会感到晕，怎么１６位左移４位，再加１６位偏移就成２０位了？

下面从一个故事说起。

### 一个鲜为人知的故事

============

现在，人们都知道Intel和Microsoft是多么的伟大，如果真正了解他们的成长过程，你就会发现他们也很普通，甚至不怎么样。就象周恩来等中共精英，当初会愚蠢的把红军指挥权交给一个德国人，而让红军一败涂地一样，放到现在别的不说，一个卖国、勾结什么反华势力就能把他们淹死！

扯远了，拉回来。IBM决定使用8088芯片开发IBM PC，及盖茨要为建议的IBM PC生产一个操作系统的时候，英特尔警告他们两个，说你们不要用那个，我们正在开发一款新的16位CPU（80286），你们用8088会后悔的。

然而， 由于IBM和盖茨都不知道PC计算机操作系统是怎么会事，所以他们不听。盖茨在华盛顿从一个公司买了一个操作系统。（西雅图电脑产品）的这个 OS被称为QDOS（快速和肮脏的操作系统），它基本是由三位前DRI（Digital Research Inc數位研究公司）的人为8086开发的，这三个人成立了这家新公司，并基本上复制了CP/M，并把它转换为16位，使用和增加了内存容量（从64K到量1024K）。然而，当它被开发成16位 CP/M时，它不是写给保护模式的。后来盖茨把它针对IBM做了很少的小改动，改名为像86-DOS或DOS-86或类似的东西。它基本上是专为CP/M 用户设计的。事实上，第一台IBM个人电脑（他们被称为个人电脑之前）吹嘘说CP/M的程序可以在其上运行。-----瞧瞧是不是优点欺诈和奸商的味道？所以在很长时间unix、OS/2的开发人员都认为DOS根本就谈不上是真正的操作系统。
　　      
8086/8088的寻址问题

===============

8088和80286都是16位CPU，Intel当初为什么会警告IBM和盖茨呢？到底发生了什么？

要了解发生了什么，我们要看看处理器的内部，会看到巨大的差异。首先，你找一片８０８８ＣＰＵ，把包装磨掉，磨到ＣＰＵ硅片，放到显微镜下，你会看到8086/88的内部结构，它根本不是一个新的设计，而是两个并联运行的8085（８位）微处理器再多那么一点点。

每个8085有它自己的8位数据和16位寻址能力。结合2个8位数据寄存器假装16位寄存器很容易。事实上这没有任何新东西，RCA COSMAC微处理器就使用16个8位寄存器，可作为内部的8位或16位寄存器使用,你可以有多达16个8位寄存器或8个16位寄存器或两者的任何组合。现在，一个中国的普通ＩＣ厂都可以轻易设计的出来。

可能由于受当时生产工艺所限，８０８８只能有４０个脚，ｉｎｔｅｌ的设计“精英”左思右想，确定了２０条地址线（１Ｍ的寻址空间），而且１６条数据线还要和２０条地址线中的１６条复用（分时复用，即一会是地址线，一会是数据线，对此要想了解，可看８０８８芯片手册的时序部分，也可看８０５２单片机书籍，它的地址线和数据线也是复用的）。

到了问题的实质了，８０８８内的两个８０８５各有一套１６位寻址寄存器，如何让他们寻址２０位的１Ｍ地址呢？其实把他们并在一起形成３２位寻址很简单，如果是那样后来的很多麻烦可能就都没有了（如Ａ２０门），但当时那些“精英”可能认为３２位寻址（４Ｇ地址空间）那是扯淡，估计地球消失了也用不到那么多的内存吧？再说了老板逼的又紧，于是他们采用了在一个硬件上使用两个８０８５非常好实现的方法－－分段：

他们把１０２４Ｋ地址空间分成１６字节的段，共６４Ｋ个段，用一个８０８５的１６位寻址寄存器作地址偏移寄存器（故段的长度是６４Ｋ），而另一个８０８５的１６位寻址寄存器作１６字节段的段地址寄存器，注意，他保存的不是１６字节段的地址，而是１６字节段的序号（０，１，．．．６５５３５）。

这样做的好处是：只要在两８０８５ＣＰＵ之间加一个移位器和一个２０位的加法器，就可以完成２０位的地址寻址－－一个８０８５的地址寄存器（段地址－－就是１６字节段的序号）左移４位（＊１６　＝　１６字节小段的首地址），加上另一个８０８５的地址寄存器就可以啦，哈哈！可以向老板交差了，制作成本低，设计速度快，有钱不抢是孙子！至于以后，。。。。

其实，段的大小从１６－６４Ｋ字节都可以通过类似方法实现１Ｍ寻址，为什么那帮精英非选１６字节呢？因为，１６字节的段，形成地址时段寄存器的位移最少，最好实现。

大家想想，要是实现３２位寻址，则需要在两个８０８５间加一个乘法器，但是如果实现了软件开发人员会省多少事。。。。，另外，要知道直到６４位ＣＰＵ才突破３２位地址空间的限制。

教科书上只讲：１６＋４＝２０位，所以１６位段地址左移４位＋１６位偏移＝２０位物理地址。很多人也只是死记，其实并不知道其含义，而且还会感到晕，怎么１６位左移４位，再加１６位偏移就成２０位了？

其商业、职业含义是应付、凑伙，并带点糊弄，用褒义词，最多也是用最小的成本、最快的速度占领市场，决不是技术上精益求精。其理论实质是：分段，１０２４Ｋ分成６４ｋ个１６字节的段，段寄存器保存的不是段的首地址，而是段的序号。不知为什么，教科书上从来不这样叙述。

到了80286，不只是为了抢占市场搞的手忙脚乱，还是8088的底子太差，以至于80286的设计复杂系数太高，还是其他什么原因，intel们又犯了两个非常低级的错误，以至于80286有两个重大缺陷：

首先，他声称80286兼容8086/8088实模式，但是在实模式地址达到1024K顶端时且不能回绕，而8088事回绕的，即地址到达FFFFFH时，再增加要回到0。

于是，产生了A20门这个痛苦问题，致使IBM不得不非常龌龊的通过键盘控制器来A20地址线的高低，从而实现实模式下的地址回绕，以便和8088兼容。这个问题后来又不断演化（专门写出来就可长篇大论），并长期给软件开发人员带来不小的麻烦。

第二， 80286从实模式进入保护模式后没有办法退回实模式，必须复位才行！ 80286有16M的存储空间，但实模式只能访问1M，也就是说，要使用1M以上的内存，必须切换到保护模式，可是要回来必须复位CPU，这对实模式下程序员是怎么一种折磨和酷刑呀？当然，到了386这个问题得到了解决，然而，至今，A20门则一直存在。

看看80286的bios设计人员是如何进行内存自检的，PC启动时，bios先在实模式执行其他应该执行的程序，到了内存自检时，首先切换到保护模式，但完成内存自检，然后在键盘控制器中设一些标志，复位CPU， bios重新执行，但会检查键盘控制器中的标志，发现是bios的热复位，则跳到复位的地方接着执行。

Intel这个技术帝国的独裁者捆绑的这个技术帝国的既得利益者(如，IBM、Microsoft等)，竞把如此糟糕的80286退给消费者，可见技术垄断的危害性。

Intel、microsoft等之所以高深、神秘、伟大，完全在于被他们洗脑或自己给自己洗脑的大众把他们高深、神秘、伟大了，而他们本身，初期量仅仅是占据了一点点先机的普通人，当揭开他们的内幕，远没有人们认为的那样高深、神秘、伟大，甚至还充满了龌龊。
