.r2k
.area TEST(ABS)

;;Global Control/Status Register
GCSR	.equ	0x00
;;Global Output Control Register
GOCR	.equ	0x0e
;;MMU: Memory Bank 0 Control Ragister
MB0CR	.equ	0x14
;;MMU: Memory Bank 1 Control Ragister
MB1CR	.equ	0x15
;;MMU: MMU Instruction/Data Register
MMIDR	.equ	0x10
;;MMU: Data Segment Register(Z180 BBR)
DATASEG	.equ	0x12
;;MMU: Segment Size Register(Z180 CBAR)
SEGSIZE	.equ	0x13
;;MMU: Stack Segment Register(Z180 CBR)
STACKSEG	.equ	0x11


;;Parallel ports 
;;PPC
;;Port C Data Ragister
PCDR	.equ	0x50
;;Port C Function Ragister
PCFR	.equ	0x55


;;Timer A
;;Timer A Control/Status Register
TACSR	.equ	0xa0
;;Timer A Control Register
TACR	.equ	0xa4
;;Timer A1 Constant register
TAT1R	.equ	0xA3
;;Timer A4 Constant register
TAT4R	.equ	0xA9

;;Serial A port
;;Serial A Port Status Register
SASR	.equ	0xc3
;;Serial A port Control Register
SACR	.equ	0xc4
;;Serial A port Data Register
SADR	.equ	0xc0
;;Serial A port Long Register
SALR	.equ	0xc2

.org 0xf200
boot:	 jp biosboot 
wboot:	 jp bioswboot 
const:	 jp biosconst 
conin:	 jp biosconin 
conout:	 jp biosconout 
listd:	 jp bioslist 
punch:	 jp biospunch 
reader:	 jp biosreader 
home:	 jp bioshome 
seldsk:	 jp biosseldsk 
settrk:	 jp biossettrk 
setsec:	 jp biossetsec 
setdma:	 jp biossetdma 
read:	 jp biosread 
write:	 jp bioswrite 
listst:	 jp bioslistst 
sectrn:	 jp biossectrn

;
;	Data tables for disks
;	Four disks, 26 sectors/track, disk size = number of 1024 byte blocks
;	Number of directory entries (32-bytes each) set to 127 per 500 blocks
;	Allocation map bits = number of blocks needed to contain directory entries
;	No translations -- translation maps commented out
;
;	disk Parameter header for disk 00
dpbase:
	.dw	0x0000, 0x0000
	.dw	0x0000, 0x0000
	.dw	dirbf, dpblk
	.dw	chk00, all00
;	disk parameter header for disk 01
	.dw	0x0000, 0x0000
	.dw	0x0000, 0x0000
	.dw	dirbf, dpblk
	.dw	chk01, all01
;	disk parameter header for disk 02
	.dw	0x0000, 0x0000
	.dw	0x0000, 0x0000
	.dw	dirbf, dpblk
	.dw	chk02, all02
;	disk parameter header for disk 03
	.dw	0x0000, 0x0000
	.dw	0x0000, 0x0000
	.dw	dirbf, dpblk
	.dw	chk03, all03
;
;	sector translate vector
;Since no translation will comment out
;trans:	db	 1,  7, 13, 19	;sectors  1,  2,  3,  4
;	.db	25,  5, 11, 17	;sectors  5,  6,  7,  6
;	.db	23,  3,  9, 15	;sectors  9, 10, 11, 12
;	.db	21,  2,  8, 14	;sectors 13, 14, 15, 16
;	.db	20, 26,  6, 12	;sectors 17, 18, 19, 20
;	.db	18, 24,  4, 10	;sectors 21, 22, 23, 24
;	.db	16, 22		;sectors 25, 26
;
dpblk:	;disk parameter block for all disks.
	.dw	256		;sectors per track
	.db	4		;block shift factor
	.db	15		;block mask - with block shift, sets block size to 1024
	.db	0		;null mask
	.dw	1023		;disk size-1 = number of blocks in a disk - 1
	.dw	256		;directory max = no. directory entries/disk, arbitrary
	.db	240		;alloc 0 -- need 4 bits (blocks) for 256 directory entries -- 
	.db	0		;alloc 1 -- no. bits = (directory max x 32)/block size	
	.dw	0		;check size -- no checking, so zero
	.dw	1		;track offset -- first track for system

;
;	end of fixed tables
;
cpmstart:
	ld de,#0xdc00
	ld (dmatmp4diskemu),de
	ld a,#0
	ld (dmatmp4diskemu+2),a
	ld (dmatmp4diskemu+3),a
	ld (dmatmp4diskemu+4),a
	ld (dmatmp4diskemu+5),a
	ld l,#1
	ld h,#0
	ld b,#44
cpmbios_cpmload:
	ld a,l
	ld (dmatmp4diskemu+2),a
	ld a,#0
	ld (dmatmp4diskemu+4),a
	call biosread
	inc l
cpmbios_cpmload_dmaaddrset:
	ld a,e
	add a,#0x80
	ld e,a
	ld a,d
	adc a,#0
	ld d,a
	ld (dmatmp4diskemu),de
	djnz cpmbios_cpmload
	ld a,#0xc3
	ld hl,#wboot
	ld (0x0000),a
	ld (0x0001),hl
	ld hl,#0xe406
	ld (0x0005),a
	ld (0x0006),hl
	ld de,#0x0080
	ld (dmatmp4diskemu),de
	ld a,(0x0004)
	and a,#0xf
	ld (diskno),a
	ld c,a
	ld sp,#0x0080
	jp 0xdc00
biosboot: 
	xor a,a
	ld (diskno),a
	ld sp,#0xfc00
	ld	a,#0x08			;proc=OSC,pclk=osc,periodic interrupt=disable
	ioi
	ld	(GCSR),a
	;ld	a,#0x00			;0x000000 Use /OE0 or /WE0 Use CS0
	;ioi
	;ld	(MB0CR),a		;use ROM
	;ld	a,#0x00			;0x400000 Use /OE1 or /WE1 Use CS1
	;ioi
	;ld	(MB1CR),a		;use RAM
;
	;ld	a,#0x01			;PCLK/2 Timer A Enabled
	;ioi
	;ld	(TACSR),a
	;ld	a,#0x00			;Timer A4~A7 Clocked by PCLK/2,interrupts disabled
	;ioi
	;ld	(TACR),a
	;ld	a,#0x0f		;A-ch Clock timer :=(PCLK/2/16/38400)-1 (PCLK=19.6608MHz >> 38400bps)
	;ioi
	;ld	(TAT4R),a

	;ld	a,#0x10			;MMU Data Reg Physics address 0x10000 (CS1)
	;ioi
	;ld	(DATASEG),a
	;ld	a,#0x10			;MMU Stack Reg Physics address 0x10000 (CS1)
	;ioi
	;ld 	(STACKSEG),a
	ld	a,#0x00			;MMU Segsize logic Data address 0x0000 (CS1:0x10000)
	ioi
	ld	(SEGSIZE),a		;MMU Segsize logic Stack address 0x0000 (CS1:0x10000)
	
	ld	a,#0x10			;MMU XPC Physics address 0x10000 (CS1:0x1e000)
	ld	xpc,a
	call	ppinit			;parallel ports initialize
	call	sioinit			;serial channel initialize
	
	ld sp,#0x0080
	;ld a,#0b010010101
	ld a,#0b010010100
	ld (0x0003),a
	ld a,#0
	ld (0x0004),a
	ld hl,#hellomes
	call showmes
	jp cpmstart
ppinit:
	ld	a,#0x40
	ioi
	ld	(PCFR),a		;C Port TxA set
	ret
sioinit:
	ld	a,#0x00
	ioi
	ld	(SACR),a		;Asynch mode, C port used, 8bit, Interrupt Disabled
	ret

putchar:				
	push	af
putchar01:
	ioi
	ld	a,(SASR)		;Serial A port Status in
      	bit     3,a			
        jr      nz,putchar01		;XMIT DATA REG > Full(bit3==1) check
 	pop	af
 	push	af
	ioi
	ld	(SADR),a		;no full(Empty) >> TxA data out
putchar_busy:
	ioi
	ld	a,(SASR)		;Serial A port Status in
	bit	3,a			;XMIT DATA REG > Full(bit3==1) check 
	jr	nz,putchar_busy
	pop	af			;no full(Empty) >> return
	ret
	
getchar:
	ioi
	ld 	a,(SASR)		;Serial A port Status in
	bit	7,a			;RCV DATA REG > EMPTY(bit7==0) check
	jr	z,getchar
	ioi
	ld	a,(SADR)		;No EMPTY(Full) > RxA data in
	push	af
getchar01:
	ioi
	ld	a,(SASR)		;Serial A port Status in
	bit	7,a			;RCV DATA REG >EMPTY(bit7==0) check
	jr	nz,getchar01
	pop	af			;EMPTY >> return
	ret

bioswboot: 
	ld sp,#0xffff
	jp cpmstart

hellomes:.ascii "62k CP/M ver 2.2"
.db 0x00
showmes:
	ld c,(hl)
	call biosconout
	inc hl
	ld a,(hl)
	and a
	jr nz,showmes
	ret

biosconst: 
	ld a,(0x0003)
	and a,#3
	cp a,#0
	jr z,const_tty
	cp a,#1
	jr z,const_crt
	cp a,#2
	jp z,bioslistst
	ld a,#0x0
	ret
const_tty:
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl
	ioi
	ld 	a,(SASR)		;Serial A port Status in
	bit	7,a			;RCV DATA REG > EMPTY(bit7==0) check
	jr	z,const_tty_
	ld a,#0xff
const_tty__:
	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
const_tty_:
	ld a,#0x00
	jr const_tty__
const_crt:
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl
	
	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
biosconin: 
	ld a,(0x0003)
	and a,#3
	cp a,#0
	jr z,conin_tty
	cp a,#1
	jr z,conin_crt
	cp a,#2
	jp z,biosreader
	ld a,#0x0
	ret
conin_tty:
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl
	call getchar
	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
conin_crt:
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl

	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
biosconout: 
	ld a,(0x0003)
	and a,#3
	cp a,#0
	jr z,conout_tty
	cp a,#1
	jr z,conout_crt
	cp a,#2
	jp z,bioslist
	ld a,c
	ret
conout_tty:
	ld a,c
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl
	    call putchar
	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
conout_crt:
	ld a,c
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl

	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
bioslist: 
	ld a,(0x0003)
	rrca
	rrca
	rrca
	rrca
	rrca
	rrca
	and a,#3
	cp a,#0
	jp z,conout_tty
	cp a,#1
	jp z,conout_crt
	cp a,#2
	jp z,list_lpt
	ld a,c
	ret
list_lpt:
	ld a,c
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl

	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
biospunch: 
	ld a,(0x0003)
	rrca
	rrca
	rrca
	rrca
	and a,#3
	cp a,#0
	jp z,conout_tty
	cp a,#1
	jr z,punch_ptp
	cp a,#2
	jp z,punch_up1
	ld a,c
	ret
punch_ptp:
	ld a,c
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl

	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
punch_up1:
	ld a,c
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl

	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
biosreader: 
	ld a,(0x0003)
	rrca
	rrca
	and a,#3
	cp a,#0
	jp z,conin_tty
	cp a,#1
	jr z,reader_ptr
	cp a,#2
	jp z,reader_ur1
	ld a,#0
	ret
reader_ptr:
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl

	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
reader_ur1:
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl

	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ret
bioshome: 
	ld a,#0
	ld (dmatmp4diskemu+4),a
	ld (dmatmp4diskemu+5),a
	ret
biosseldsk: 
	ld a,c
	cp a,#1
	jr nc,biosseldsk_0
	ld (diskno),a
	ld hl,#0
	ld l,c
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld bc,#dpbase
	add hl,bc
	res 0,e
	ret
biosseldsk_0:
	ld hl,#0x0
	set 0,e
	ret
biossettrk: 
	ld (dmatmp4diskemu+4),bc
	ret
biossetsec:
	ld (dmatmp4diskemu+2),bc
	ret
biossetdma: 
	ld (dmatmp4diskemu),bc
	ret
biosread: 
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl
	ld a,(dmatmp4diskemu+2)
	ioe
	ld (0x0000),a
	ld a,(dmatmp4diskemu+4)
	ioe
	ld (0x0001),a
	ld hl,(dmatmp4diskemu)
	ioe
	ld (0x0002),hl
	ld a,#0x01
	ioe
	ld (0x0004),a
	ld a,(diskno)
	rla
	set 0,a
	ioe
	ld (0x0005),a
	ioe
	ld a,(0x0005)
	bit 0,a
	jr nz,biosreadwrite_err
	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ld a,#0
	ret

biosreadwrite_err:
	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ld a,#0xff
	ret
biosrw_backupflashstate:	.db 0
bioswrite: 
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl
	ld a,(dmatmp4diskemu+2)
	ioe
	ld (0x0000),a
	ld a,(dmatmp4diskemu+4)
	ioe
	ld (0x0001),a
	ld hl,(dmatmp4diskemu)
	ioe
	ld (0x0002),hl
	ld a,#0x01
	ioe
	ld (0x0004),a
	ld a,(diskno)
	rla
	set 0,a
	ioe
	ld (0x0005),a
	ioe
	ld a,(0x0005)
	bit 0,a
	jr nz,biosreadwrite_err
	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ld a,#0
	ret
bioslistst: 
	ld a,(0x0003)
	rrca
	rrca
	rrca
	rrca
	rrca
	rrca
	and a,#3
	cp a,#0
	jp z,const_tty
	cp a,#1
	jp z,const_crt
	cp a,#2
	jp z,listst_lpt
	ld a,#0
	ret
listst_lpt:
	ld (cpmbios_bcbak),bc
	ld (cpmbios_debak),de
	ld (cpmbios_hlbak),hl
	ld (cpmbios_afbak),a

	ld bc,(cpmbios_bcbak)
	ld de,(cpmbios_debak)
	ld hl,(cpmbios_hlbak)
	ld a,(cpmbios_afbak)
	ret
biossectrn:
	ex de,hl
	add hl,bc
	ret

cpmbios_bcbak:.dw 0
cpmbios_debak:.dw 0
cpmbios_hlbak:.dw 0
cpmbios_afbak:.dw 0
dmatmp4diskemu:.dw 0
	.dw 0
	.dw 0
crtx:
	.db 0
crty:
	.db 0
kbuffer:
	.db 0
;
;	the remainder of the cbios is reserved uninitialized
;	data area, and does not need to be a Part of the
;	system	memory image (the space must be available,
;	however, between"begdat" and"enddat").
;
track:	.ds	2		;two bytes for expansion
sector:	.ds	2		;two bytes for expansion
dmaad:	.ds	2		;direct memory address
diskno:	.ds	1		;disk number 0-15
;
;	scratch ram area for bdos use
begdat: ;beginning of data area
dirbf:	.ds	128	 	;scratch directory area
;Allocation scratch areas, size of each must be (DSM/8)+1
all00:	.ds	128	 	;allocation vector 0
all01:	.ds	128	 	;allocation vector 1
all02:	.ds	128	 	;allocation vector 2
all03:	.ds	128	 	;allocation vector 3
;Could probably remove these chk areas, but just made size small
chk00:	.ds	1		;check vector 0
chk01:	.ds	1		;check vector 1
chk02:	.ds	1	 	;check vector 2
chk03:	.ds	1	 	;check vector 3
;
enddat:;end of data area
datsiz	.equ	enddat - begdat ;size of data area
hstbuf: 	.ds 256		;buffer for host disk sector
addrbeepconf:   .db 0x00
