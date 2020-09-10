#include <linux/config.h>
#include <linux/segment.h>
#ifndef SVGA_MODE
#define SVGA_MODE ASK_VGA
#endif
INITSEG  = DEF_INITSEG
SYSSEG   = DEF_SYSSEG
SETUPSEG = DEF_SETUPSEG
.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text
entry start
start:

	mov	ax,#INITSEG
	mov	ds,ax

	mov	ah,#0x88
	int	0x15
	mov	[2],ax

	mov	ax,#0x0305
	xor	bx,bx
	int	0x16

	mov	ah,#0x12
	mov	bl,#0x10
	int	0x10
	mov	[8],ax
	mov	[10],bx
	mov	[12],cx
	mov	ax,#0x5019
	cmp	bl,#0x10
	je	novga
	mov	ax,#0x1a00
	int	0x10
	mov	bx,ax
	mov	ax,#0x5019
	cmp	bl,#0x1a
	jne	novga	
	call	chsvga
novga:	mov	[14],ax
	mov	ah,#0x03
	xor	bh,bh
	int	0x10
	mov	[0],dx
	

	
	mov	ah,#0x0f
	int	0x10
	mov	[4],bx
	mov	[6],ax

	xor	ax,ax
	mov	ds,ax
	lds	si,[4*0x41]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0080
	mov	cx,#0x10
	cld
	rep
	movsb

	xor	ax,ax
	mov	ds,ax
	lds	si,[4*0x46]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	cld
	rep
	movsb

	mov	ax,#0x01500
	mov	dl,#0x81
	int	0x13
	jc	no_disk1
	cmp	ah,#3
	je	is_disk1
no_disk1:
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	xor	ax,ax
	cld
	rep
	stosb
is_disk1:

	mov	ax,#INITSEG
	mov	ds,ax
	mov	[0x1ff],#0
	int	0x11
	test	al,#0x04
	jz	no_psmouse
	mov	[0x1ff],#0xaa
no_psmouse:

	cli
	mov	al,#0x80
	out	#0x70,al

	mov	ax,#0x100
	mov	bx,#0x1000
	cld
do_move:
	mov	es,ax
	add	ax,#0x100
	cmp	ax,#0x9000
	jz	end_move
	mov	ds,bx
	add	bx,#0x100
	sub	di,di
	sub	si,si
	mov 	cx,#0x800
	rep
	movsw
	jmp	do_move

end_move:
	mov	ax,#SETUPSEG
	mov	ds,ax
	lidt	idt_48
	lgdt	gdt_48

	call	empty_8042
	mov	al,#0xD1
	out	#0x64,al
	call	empty_8042
	mov	al,#0xDF
	out	#0x60,al
	call	empty_8042

	xor	ax,ax
	out	#0xf0,al
	call	delay
	out	#0xf1,al
	call	delay


	mov	al,#0x11
	out	#0x20,al
	call	delay
	out	#0xA0,al
	call	delay
	mov	al,#0x20
	out	#0x21,al
	call	delay
	mov	al,#0x28
	out	#0xA1,al
	call	delay
	mov	al,#0x04
	out	#0x21,al
	call	delay
	mov	al,#0x02
	out	#0xA1,al
	call	delay
	mov	al,#0x01
	out	#0x21,al
	call	delay
	out	#0xA1,al
	call	delay
	mov	al,#0xFF
	out	#0xA1,al
	call	delay
	mov	al,#0xFB
	out	#0x21,al

	mov	ax,#0x0001
	lmsw	ax
	jmp	flush_instr
flush_instr:
	jmpi	0x1000,KERNEL_CS

empty_8042:
	call	delay
	in	al,#0x64
	test	al,#1
	jz	no_output
	call	delay
	in	al,#0x60
	jmp	empty_8042
no_output:
	test	al,#2
	jnz	empty_8042
	ret


getkey:
	xor	ah,ah
	int	0x16
	ret

getkt:
	call	gettime
	add	al,#30
	cmp	al,#60
	jl	lminute
	sub	al,#60
lminute:
	mov	cl,al
again:	mov	ah,#0x01
	int	0x16
	jnz	getkey
	call	gettime
	cmp	al,cl
	jne	again
	mov	al,#0x20
	ret


flush:	mov	ah,#0x01
	int	0x16
	jz	empty
	xor	ah,ah
	int	0x16
	jmp	flush
empty:	ret


gettime:
	push	cx
	mov	ah,#0x02
	int	0x1a
	mov	al,dh
	and	al,#0x0f
	mov	ah,dh
	mov	cl,#0x04
	shr	ah,cl
	aad
	pop	cx
	ret


delay:
	.word	0x00eb
	ret


chsvga:	cld
	push	ds
	push	cs
	mov	ax,[0x01fa]
	pop	ds
	mov	modesave,ax
	mov 	ax,#0xc000
	mov	es,ax
	mov	ax,modesave
	cmp	ax,#NORMAL_VGA
	je	defvga
	cmp	ax,#EXTENDED_VGA
	je	vga50
	cmp	ax,#ASK_VGA
	jne	svga
	lea	si,msg1
	call	prtstr
	call	flush
nokey:	call	getkt
	cmp	al,#0x0d
	je	svga
	cmp	al,#0x20
	je	defvga
	call 	beep
	jmp	nokey
defvga:	mov	ax,#0x5019
	pop	ds
	ret

vga50:
	mov	ax,#0x1112
	xor	bl,bl
	int	0x10
	mov	ax,#0x1200
	mov	bl,#0x20
	int	0x10
	mov	ax,#0x1201
	mov	bl,#0x34
	int	0x10
	mov	ah,#0x01
	mov	cx,#0x0607
	int	0x10
	pop	ds
	mov	ax,#0x5032
	ret

vga28:
	pop	ax
	mov	ax,#0x1111
	xor	bl,bl
	int	0x10
	mov	ah, #0x01
	mov	cx,#0x0b0c
	int	0x10
	pop	ds
	mov	ax,#0x501c
	ret

svga:   cld
        lea     si,id9GXE
        mov     di,#0x49
        mov     cx,#0x11
        repe
        cmpsb
        jne     of1280
is9GXE:	lea 	si,dsc9GXE
	lea	di,mo9GXE
	br	selmod
of1280:	cld	
	lea	si,idf1280
	mov	di,#0x10a
	mov	cx,#0x21
	repe
	cmpsb
	jne	nf1280	
isVRAM:	lea	si,dscf1280
	lea	di,mof1280
	br	selmod
nf1280:	lea	si,idVRAM
	mov	di,#0x10a
	mov	cx,#0x0c
	repe
	cmpsb
	je	isVRAM
	cld
	lea 	si,idati
	mov	di,#0x31
	mov 	cx,#0x09
	repe
	cmpsb
	jne	noati
	lea	si,dscati
	lea	di,moati
	br	selmod
noati:	mov	ax,#0x200f
	mov	dx,#0x3ce
	out	dx,ax
	inc	dx
	in	al,dx
	cmp	al,#0x20
	je	isahed
	cmp	al,#0x21
	jne	noahed
isahed:	lea	si,dscahead
	lea	di,moahead
	br	selmod
noahed:	mov	dx,#0x3c3
	in	al,dx
	or	al,#0x10
	out	dx,al
	mov	dx,#0x104		
	in	al,dx
	mov	bl,al
	mov	dx,#0x3c3
	in	al,dx
	and	al,#0xef
	out	dx,al
	cmp	bl,[idcandt]
	jne	nocant
	lea	si,dsccandt
	lea	di,mocandt
	br	selmod
nocant:	mov	dx,#0x3d4
	mov	al,#0x0c
	out	dx,al
	inc	dx
	in	al,dx
	mov	bl,al
	xor	al,al
	out	dx,al
	dec	dx
	mov	al,#0x1f
	out	dx,al
	inc	dx
	in	al,dx
	mov	bh,al
	xor	ah,ah
	shl	al,#4
	mov	cx,ax
	mov	al,bh
	shr	al,#4
	add	cx,ax
	shl	cx,#8
	add	cx,#6
	mov	ax,cx
	mov	dx,#0x3c4
	out	dx,ax
	inc	dx
	in	al,dx
	and	al,al
	jnz	nocirr
	mov	al,bh
	out	dx,al
	in	al,dx
	cmp	al,#0x01
	jne	nocirr
	call	rst3d4	
	lea	si,dsccirrus
	lea	di,mocirrus
	br	selmod
rst3d4:	mov	dx,#0x3d4
	mov	al,bl
	xor	ah,ah
	shl	ax,#8
	add	ax,#0x0c
	out	dx,ax
	ret	
nocirr:	call	rst3d4
	mov	ax,#0x7000
	xor	bx,bx
	int	0x10
	cmp	al,#0x70
	jne	noevrx
	shr	dx,#4
	cmp	dx,#0x678
	je	istrid
	cmp	dx,#0x236
	je	istrid
	lea	si,dsceverex
	lea	di,moeverex
	br	selmod
istrid:	lea	cx,ev2tri
	jmp	cx
noevrx:	lea	si,idgenoa
	xor 	ax,ax
	seg es
	mov	al,[0x37]
	mov	di,ax
	mov	cx,#0x04
	dec	si
	dec	di
l1:	inc	si
	inc	di
	mov	al,(si)
	test	al,al
	jz	l2
	seg es
	cmp	al,(di)
l2:	loope 	l1
	cmp	cx,#0x00
	jne	nogen
	lea	si,dscgenoa
	lea	di,mogenoa
	br	selmod
nogen:	cld
	lea	si,idoakvga
	mov	di,#0x08
	mov	cx,#0x08
	repe
	cmpsb
	jne	nooak
	lea	si,dscoakvga
	lea	di,mooakvga
	br	selmod
nooak:	cld
	lea	si,idparadise
	mov	di,#0x7d
	mov	cx,#0x04
	repe
	cmpsb
	jne	nopara
	lea	si,dscparadise
	lea	di,moparadise
	br	selmod
nopara:	mov	dx,#0x3c4
	mov	al,#0x0e
	out	dx,al
	inc	dx
	in	al,dx
	xchg	ah,al
	xor	al,al
	out	dx,al
	in	al,dx
	xchg	al,ah
	mov	bl,al
	and	bl,#0x02
	jz	setb2
	and	al,#0xfd
	jmp	clrb2
setb2:	or	al,#0x02
clrb2:	out	dx,al
	and	ah,#0x0f
	cmp	ah,#0x02
	jne	notrid
ev2tri:	lea	si,dsctrident
	lea	di,motrident
	jmp	selmod
notrid:	mov	dx,#0x3cd
	in	al,dx
	mov	bl,al
	mov	al,#0x55
	out	dx,al
	in	al,dx
	mov	ah,al
	mov	al,bl
	out	dx,al
	cmp	ah,#0x55
 	jne	notsen
	lea	si,dsctseng
	lea	di,motseng
	jmp	selmod
notsen:	mov	dx,#0x3cc
	in	al,dx
	mov	dx,#0x3b4
	and	al,#0x01
	jz	even7
	mov	dx,#0x3d4
even7:	mov	al,#0x0c
	out	dx,al
	inc	dx
	in	al,dx
	mov	bl,al
	mov	al,#0x55
	out	dx,al
	in	al,dx
	dec	dx
	mov	al,#0x1f
	out	dx,al
	inc	dx
	in	al,dx
	mov	bh,al
	dec	dx
	mov	al,#0x0c
	out	dx,al
	inc	dx
	mov	al,bl
	out	dx,al
	mov	al,#0x55
	xor	al,#0xea
	cmp	al,bh
	jne	novid7
	lea	si,dscvideo7
	lea	di,movideo7
	jmp	selmod
novid7:	lea	si,dsunknown
	lea	di,mounknown
selmod:	xor	cx,cx
	mov	cl,(di)
	mov	ax,modesave
	cmp	ax,#ASK_VGA
	je	askmod
	cmp	ax,#NORMAL_VGA
	je	askmod
	cmp	al,cl
	jl	gotmode
	push	si
	lea	si,msg4
	call	prtstr
	pop	si
askmod:	push	si
	lea	si,msg2
	call	prtstr
	pop	si
	push	si
	push	cx
tbl:	pop	bx
	push	bx
	mov	al,bl
	sub	al,cl
	call	modepr
	lodsw
	xchg	al,ah
	call	dprnt
	xchg	ah,al
	push	ax
	mov	al,#0x78
	call	prnt1
	pop	ax
	call	dprnt
	push	si
	lea	si,crlf
	call	prtstr
	pop	si
	loop	tbl
	pop	cx
	lea	si,msg3
	call	prtstr
	pop	si
	add	cl,#0x30
	jmp	nonum
nonumb:	call	beep
nonum:	call	getkey
	cmp	al,#0x30
	jb	nonumb
	cmp	al,#0x3a
	jbe	number
	cmp	al,#0x61
	jb	nonumb
	cmp	al,#0x7a
	ja	nonumb
	sub	al,#0x27
	cmp	al,cl
	jae	nonumb
	sub	al,#0x30
	jmp	gotmode
number: cmp	al,cl
	jae	nonumb
	sub	al,#0x30
gotmode:	xor	ah,ah
	or	al,al
	beq	vga50
	push	ax
	dec	ax
	beq	vga28
	add	di,ax
	mov	al,(di)
	int 	0x10
	pop	ax
	shl	ax,#1
	add	si,ax
	lodsw
	pop	ds
	ret

prtstr:	lodsb
	and	al,al
	jz	fin
	call	prnt1
	jmp	prtstr
fin:	ret


dprnt:	push	ax
	push	cx
	xor	ah,ah
	mov	cl,#0x0a
	idiv	cl
	cmp	al,#0x09
	jbe	lt100
	call	dprnt
	jmp	skip10
lt100:	add	al,#0x30
	call	prnt1
skip10:	mov	al,ah
	add	al,#0x30
	call	prnt1	
	pop	cx
	pop	ax
	ret


modepr:	push	ax
	cmp	al,#0x0a
	jb	digit
	add	al,#0x27
digit:	add	al,#0x30
	mov	modenr, al
	push 	si
	lea	si, modestring
	call	prtstr
	pop	si
	pop	ax
	ret

prnt1:	push	ax
	push	cx
	xor	bh,bh
	mov	cx,#0x01
	mov	ah,#0x0e
	int	0x10
	pop	cx
	pop	ax
	ret
beep:	mov	al,#0x07
	jmp	prnt1
	
gdt:
	.word	0,0,0,0
	.word	0,0,0,0
	.word	0x07FF
	.word	0x0000
	.word	0x9A00
	.word	0x00C0
	.word	0x07FF
	.word	0x0000
	.word	0x9200
	.word	0x00C0
idt_48:
	.word	0
	.word	0,0
gdt_48:
	.word	0x800
	.word	512+gdt,0x9
msg1:		.ascii	"Press <RETURN> to see SVGA-modes available, <SPACE> to continue or wait 30 secs."
		db	0x0d, 0x0a, 0x0a, 0x00
msg2:		.ascii	"Mode:  COLSxROWS:"
		db	0x0d, 0x0a, 0x0a, 0x00
msg3:		db	0x0d, 0x0a
		.ascii	"Choose mode by pressing the corresponding number or letter."
crlf:		db	0x0d, 0x0a, 0x00
msg4:		.ascii	"You passed an undefined mode number to setup. Please choose a new mode."
		db	0x0d, 0x0a, 0x0a, 0x07, 0x00
modestring:	.ascii	"   "
modenr:		db	0x00
		.ascii	":    "
		db	0x00
		
idati:		.ascii	"761295520"
idcandt:	.byte	0xa5
idgenoa:	.byte	0x77, 0x00, 0x99, 0x66
idparadise:	.ascii	"VGA="
idoakvga:	.ascii  "OAK VGA "
idf1280:	.ascii	"Orchid Technology Fahrenheit 1280"
id9GXE:		.ascii  "Graphics Power By"
idVRAM:		.ascii	"Stealth VRAM"



moati:		.byte	0x04,	0x23, 0x33 
moahead:	.byte	0x07,	0x22, 0x23, 0x24, 0x2f, 0x34
mocandt:	.byte	0x04,	0x60, 0x61
mocirrus:	.byte	0x06,	0x1f, 0x20, 0x22, 0x31
moeverex:	.byte	0x0c,	0x03, 0x04, 0x07, 0x08, 0x0a, 0x0b, 0x16, 0x18, 0x21, 0x40
mogenoa:	.byte	0x0c,	0x58, 0x5a, 0x60, 0x61, 0x62, 0x63, 0x64, 0x72, 0x74, 0x78
moparadise:	.byte	0x04,	0x55, 0x54
motrident:	.byte	0x09,	0x50, 0x51, 0x52, 0x57, 0x58, 0x59, 0x5a
motseng:	.byte	0x07,	0x26, 0x2a, 0x23, 0x24, 0x22
movideo7:	.byte	0x08,	0x40, 0x43, 0x44, 0x41, 0x42, 0x45
mooakvga:	.byte   0x08,   0x00, 0x07, 0x4e, 0x4f, 0x50, 0x51
mo9GXE:		.byte	0x04,	0x54, 0x55
mof1280:	.byte	0x04,	0x54, 0x55
mounknown:	.byte	0x02



dscati:		.word	0x5032, 0x501c, 0x8419, 0x842c
dscahead:	.word	0x5032, 0x501c, 0x842c, 0x8419, 0x841c, 0xa032, 0x5042
dsccandt:	.word	0x5032, 0x501c, 0x8419, 0x8432
dsccirrus:	.word	0x5032, 0x501c, 0x8419, 0x842c, 0x841e, 0x6425
dsceverex:	.word	0x5032, 0x501c, 0x5022, 0x503c, 0x642b, 0x644b, 0x8419, 0x842c, 0x501e, 0x641b, 0xa040, 0x841e
dscgenoa:	.word	0x5032, 0x501c, 0x5020, 0x642a, 0x8419, 0x841d, 0x8420, 0x842c, 0x843c, 0x503c, 0x5042, 0x644b
dscparadise:	.word	0x5032, 0x501c, 0x8419, 0x842b
dsctrident:	.word 	0x5032, 0x501c, 0x501e, 0x502b, 0x503c, 0x8419, 0x841e, 0x842b, 0x843c
dsctseng:	.word	0x5032, 0x501c, 0x503c, 0x6428, 0x8419, 0x841c, 0x842c
dscvideo7:	.word	0x5032, 0x501c, 0x502b, 0x503c, 0x643c, 0x8419, 0x842c, 0x841c
dscoakvga:	.word   0x5032, 0x501c, 0x2819, 0x5019, 0x503c, 0x843c, 0x8419, 0x842b
dscf1280:	.word	0x5032, 0x501c, 0x842b, 0x8419
dsc9GXE:	.word	0x5032, 0x501c, 0x842b, 0x8419
dsunknown:	.word	0x5032, 0x501c
modesave:	.word	SVGA_MODE
	
.text
endtext:
.data
enddata:
.bss
endbss:
