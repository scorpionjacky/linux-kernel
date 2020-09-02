sectors = 18

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

BOOTSEG = 0x07c0
INITSEG = 0x9000
SYSSEG  = 0x1000
ENDSEG	= SYSSEG + SYSSIZE

entry start
start:
	mov	ax,#BOOTSEG
	mov	ds,ax
	mov	ax,#INITSEG
	mov	es,ax
	mov	cx,#256
	sub	si,si
	sub	di,di
	rep
	movw
	jmpi	go,INITSEG
go:	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	ss,ax
	mov	sp,#0x400

	mov	ah,#0x03
	xor	bh,bh
	int	0x10
	
	mov	cx,#24
	mov	bx,#0x0007
	mov	bp,#msg1
	mov	ax,#0x1301
	int	0x10

	mov	ax,#SYSSEG
	mov	es,ax
	call	read_it
	call	kill_motor

	mov	ah,#0x03
	xor	bh,bh
	int	0x10
	mov	[510],dx

	cli
	mov	ax,#0x0000
	cld
do_move:
	mov	es,ax
	add	ax,#0x1000
	cmp	ax,#0x9000
	jz	end_move
	mov	ds,ax
	sub	di,di
	sub	si,si
	mov 	cx,#0x8000
	rep
	movsw
	j	do_move


end_move:

	mov	ax,cs
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

	mov	al,#0x11
	out	#0x20,al
	.word	0x00eb,0x00eb
	out	#0xA0,al
	.word	0x00eb,0x00eb
	mov	al,#0x20
	out	#0x21,al
	.word	0x00eb,0x00eb
	mov	al,#0x28
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x04
	out	#0x21,al
	.word	0x00eb,0x00eb
	mov	al,#0x02
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0x01
	out	#0x21,al
	.word	0x00eb,0x00eb
	out	#0xA1,al
	.word	0x00eb,0x00eb
	mov	al,#0xFF
	out	#0x21,al
	.word	0x00eb,0x00eb
	out	#0xA1,al

	mov	ax,#0x0001
	lmsw	ax
	jmpi	0,8

empty_8042:
	.word	0x00eb,0x00eb
	in	al,#0x64
	test	al,#2
	jnz	empty_8042
	ret

sread:	.word 1
head:	.word 0
track:	.word 0
read_it:
	mov ax,es
	test ax,#0x0fff
die:	jne die
	xor bx,bx
rp_read:
	mov ax,es
	cmp ax,#ENDSEG
	jb ok1_read
	ret
ok1_read:
	mov ax,#sectors
	sub ax,sread
	mov cx,ax
	shl cx,#9
	add cx,bx
	jnc ok2_read
	je ok2_read
	xor ax,ax
	sub ax,bx
	shr ax,#9
ok2_read:
	call read_track
	mov cx,ax
	add ax,sread
	cmp ax,#sectors
	jne ok3_read
	mov ax,#1
	sub ax,head
	jne ok4_read
	inc track
ok4_read:
	mov head,ax
	xor ax,ax
ok3_read:
	mov sread,ax
	shl cx,#9
	add bx,cx
	jnc rp_read
	mov ax,es
	add ax,#0x1000
	mov es,ax
	xor bx,bx
	jmp rp_read

read_track:
	push ax
	push bx
	push cx
	push dx
	mov dx,track
	mov cx,sread
	inc cx
	mov ch,dl
	mov dx,head
	mov dh,dl
	mov dl,#0
	and dx,#0x0100
	mov ah,#2
	int 0x13
	jc bad_rt
	pop dx
	pop cx
	pop bx
	pop ax
	ret
bad_rt:	mov ax,#0
	mov dx,#0
	int 0x13
	pop dx
	pop cx
	pop bx
	pop ax
	jmp read_track

kill_motor:
	push dx
	mov dx,#0x3f2
	mov al,#0
	outb
	pop dx
	ret

gdt:
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
	.word	gdt,0x9
	
msg1:
	.byte 13,10
	.ascii "Loading system ..."
	.byte 13,10,13,10

.text
endtext:
.data
enddata:
.bss
endbss:
