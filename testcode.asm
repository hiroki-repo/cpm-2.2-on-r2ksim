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





.org 0x0000
jp start
.org 0x0080
start:
	ld 	a,#0x08				;;proc=OSC,pclk=osc,periodic interrupt=disable
	ioi ld 	(GCSR),a
	ld 	a,#0x00				;;0x000000 Use /OE0 or /WE0 Use CS0
	ioi ld 	(MB0CR),a		;;use ROM
	ld 	a,#0x05				;0x400000 Use /OE1 or /WE1 Use CS1
	ioi ld 	(MB1CR),a		;;use RAM
;
	ld 	a,#0x01				;;PCLK/2 Timer A Enabled
	ioi ld 	(TACSR),a
	ld 	a,#0x00				;;Timer A4~A7 Clocked by PCLK/2,interrupts disabled
	ioi ld 	(TACR),a
	ld 	a,#0x0f			;;A-ch Clock timer :=(PCLK/2/16/38400)-1 (PCLK=19.6608MHz >> 38400bps)
	ioi ld 	(TAT4R),a

	ld 	a,#0x10				;;MMU Data Reg Physics address 0x10000 (CS1)
	ioi ld 	(DATASEG),a
	ld 	a,#0x10				;;MMU Stack Reg Physics address 0x10000 (CS1)
	ioi ld 	(STACKSEG),a
	ld 	a,#0x18				;;MMU Segsize logic Data address 0x8000 (CS1:0x18000)
	ioi ld 	(SEGSIZE),a		;;MMU Segsize logic Stack address 0xa000 (CS1:0x1a000)
	
	ld 	a,#0x10				;;MMU XPC Physics address 0x10000 (CS1:0x1e000)
	ld 	xpc,a
	    ld sp,#0xfc00
	call 	ppinit			;;parallel ports initialize
	call 	sioinit			;;serial channel initialize
	
ld hl,#hello
ml:
ld a,(hl)
inc hl
call putchar
and a,a
jr nz,ml
lplp:
jr lplp

hello:	.ascii "Hello, World!"
	.db #0x00

ppinit:
	ld	a,#0x40
	ioi ld	(PCFR),a		;C Port TxA set
	ret
sioinit:
	ld	a,#0x00
	ioi ld	(SACR),a		;Asynch mode, C port used, 8bit, Interrupt Disabled
	ret

putchar:				
	push	af
putchar01:
	ioi ld	a,(SASR)		;Serial A port Status in
      	bit     3,a			
        jr      nz,putchar01		;XMIT DATA REG > Full(bit3==1) check
 	pop	af
 	push	af
	ioi ld	(SADR),a		;no full(Empty) >> TxA data out
putchar_busy:
	ioi ld	a,(SASR)		;Serial A port Status in
	bit	3,a			;XMIT DATA REG > Full(bit3==1) check 
	jr	nz,putchar_busy
	pop	af			;no full(Empty) >> return
	ret
	
getchar:
	ioi ld 	a,(SASR)		;Serial A port Status in
	bit	7,a			;RCV DATA REG > EMPTY(bit7==0) check
	jr	z,getchar
	ioi ld	a,(SADR)		;No EMPTY(Full) > RxA data in
	push	af
getchar01:
	ioi ld	a,(SASR)		;Serial A port Status in
	bit	7,a			;RCV DATA REG >EMPTY(bit7==0) check
	jr	nz,getchar01
	pop	af			;EMPTY >> return
	ret

