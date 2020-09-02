#include <linux/config.h>
SYSSIZE = DEF_SYSSIZE

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

SETUPLEN = 4

BOOTSEG  = 0x07c0

INITSEG  = DEF_INITSEG

SETUPSEG = DEF_SETUPSEG

SYSSEG   = DEF_SYSSEG

ENDSEG   = SYSSEG + SYSSIZE

ROOT_DEV = 0
SWAP_DEV = 0


entry start
start:
    mov	ax, #BOOTSEG
	mov	ds, ax
	mov	ax, #INITSEG
	mov	es, ax
	mov	cx, #256
	sub	si, si
	sub	di, di
	rep
	movw
	jmpi	go, INITSEG

go:	mov	ax,cs
	mov	dx, #0xfef4

	mov	ds,ax
	mov	es,ax

	mov	ss,ax
	mov	sp,dx

	push	#0
	pop	fs
	mov	bx, #0x78


	seg fs
	lgs	si, (bx)

	mov	di, dx
	mov	cx, #6
	cld

	rep
	seg gs
	movw

	mov	di, dx
	movb 4(di), *18

	seg fs
	mov	(bx), di
	seg fs
	mov	2(bx), es

	mov ax, cs
	mov	fs, ax
	mov	gs, ax

	xor	ah, ah
	xor	dl, dl
	int 0x13

load_setup:
	xor	dx, dx
	mov	cx, #0x0002
	mov	bx, #0x0200
	mov	ax, #0x0200 + SETUPLEN
	int	0x13
	jnc	ok_load_setup

	push	ax
	call	print_nl
	mov	bp, sp
	call print_hex
	pop	ax

	xor	dl, dl
	xor	ah, ah
	int	0x13
	j	load_setup

ok_load_setup:
	xor	dl, dl
	mov	ah, #0x08
	int	0x13
	xor	ch, ch
	seg cs


	mov	sectors, cx
	mov	ax, #INITSEG
	mov	es, ax

	mov	ah, #0x03
	xor	bh, bh
	int	0x10

	mov	cx, #9
	mov	bx, #0x0007
	mov	bp, #msg1
	mov	ax, #0x1301
	int	0x10

    mov ax, #SYSSEG
    mov es, ax
    call read_it
    call kill_motor
    call print_nl

	seg cs
	mov	ax, root_dev
	or	ax, ax
	jne	root_defined

	seg cs
	mov	bx, sectors
	mov	ax, #0x0208
	cmp	bx, #15
	je	root_defined
	mov	ax, #0x021c
	cmp	bx, #18
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	seg cs
	mov	root_dev, ax

	jmpi	0, SETUPSEG


sread:	.word 1 + SETUPLEN
head:	.word 0
track:	.word 0

read_it:
	mov ax, es
	test ax, #0x0fff
die:
	jne die
	xor bx, bx
rp_read:


	mov ax, es
	cmp ax, #ENDSEG
	jb ok1_read
	ret
ok1_read:



	seg cs
	mov ax, sectors
	sub ax, sread
	mov cx, ax
	shl cx, #9
	add cx, bx
	jnc ok2_read
	je ok2_read


	xor ax, ax
	sub ax, bx
	shr ax, #9
ok2_read:


	call read_track
	mov cx, ax
	add ax, sread
	seg cs
	cmp ax, sectors
	jne ok3_read

	mov ax, #1
	sub ax, head
	jne ok4_read
	inc track
ok4_read:
	mov head, ax
	xor ax, ax
ok3_read:

	mov sread, ax
	shl cx, #9
	add bx, cx
	jnc rp_read

	mov ax, es
	add ah, #0x10
	mov es, ax
	xor bx, bx
	jmp rp_read




read_track:
	pusha
	pusha
	mov	ax, #0xe2e
	mov	bx, #7
 	int	0x10
	popa


	mov dx, track
	mov cx, sread
	inc cx
	mov ch, dl
	mov dx, head
	mov dh, dl
	and dx, #0x0100
	mov ah, #2

	push	dx
	push	cx
	push	bx
	push	ax

	int 0x13
	jc bad_rt
	add	sp, #8
	popa
	ret


bad_rt:
	push	ax
	call	print_all

	xor ah, ah
	xor dl, dl
	int 0x13

	add	sp, #10
	popa
	jmp read_track

print_all:
	mov	cx, #5
	mov	bp, sp

print_loop:
	push	cx
	call	print_nl
	jae	no_reg


	mov	ax, #0xe05 + 0x41 - 1
	sub	al, cl
	int	0x10

	mov	al, #0x58
	int	0x10

	mov	al, #0x3a
	int	0x10


no_reg:
	add	bp, #2
	call	print_hex
	pop	cx
	loop	print_loop
	ret


print_nl:
	mov	ax, #0xe0d
	int	0x10
	mov	al, #0xa
	int 	0x10
	ret

print_hex:
	mov	cx, #4
	mov	dx, (bp)


print_digit:
	rol	dx, #4
	mov	ah, #0xe
	mov	al, dl
	and	al, #0xf
	add	al, #0x30
	cmp	al, #0x39
	jbe	good_digit
	add	al, #0x41 - 0x30 - 0xa

good_digit:
	int	0x10
	loop	print_digit
	ret

kill_motor:
	push dx
	mov dx, #0x3f2
	xor al, al
	outb
	pop dx
	ret

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Loading"


.org 506
swap_dev:
	.word SWAP_DEV
root_dev:
	.word ROOT_DEV

boot_flag:
	.word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:

