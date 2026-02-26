;***********************************************************
;*	This is the skeleton file for Lab 5 of ECE 375
;*
;*	 Author: Graham Brown and Matt Wallin
;*	   Date: 2/20/2026
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def    zero = r0       ; Zero register
.def	mpr = r16				; Multipurpose register
.def	rcnt = r17				; Right Count
.def	lcnt = r18				; Left Count
.def	ilcnt = r19				; Inner Loop Counter
.def	olcnt = r23				; Outer Loop Counter
.def    waitcnt = r24   ; Wait counter

.equ	WTime = 100				; Time to wait in wait loop

.equ	EngEnR = 5				; Right Engine Enable Bit
.equ	EngEnL = 6				; Left Engine Enable Bit
.equ	EngDirR = 4				; Right Engine Direction Bit
.equ	EngDirL = 7				; Left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0002
		rcall	HitRight
		reti

.org	$0004
		rcall	HitLeft
		reti

.org	$0008
		rcall	ClearCounters
		reti

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

		clr		zero			; Set the zero register to zero, maintain
										; these semantics, meaning, dont
										; load anything else into it.

		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge
		ldi mpr, 0b1000_1010
		sts EICRA, mpr				; Sets INT0, 1, 3 to falling edge
		; Configure the External Interrupt Mask
		ldi mpr, 0b0000_1011			; Activates INT 0, 1, 3
		out EIMSK, mpr
		; Turn on interrupts
		sei
			; NOTE: This must be the last thing to do in the INIT function
		clr rcnt
		clr lcnt
		rcall LCDInit
		rcall LCDBacklightOn
		rcall DisplayCounters
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		ldi mpr, MovFwd
		out PORTB, mpr
		rjmp	MAIN			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the
;	left whisker interrupt, one to handle the right whisker
;	interrupt, and maybe a wait function
;------------------------------------------------------------

;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:
		push mpr
		push waitcnt
		in mpr, SREG
		push mpr
		cli                     ; disable interrupts during behavior
		inc rcnt
		rcall DisplayCounters

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime*2	; Wait for 2 seconds
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		ldi mpr, 0b00001011     ; clear INT0, INT1, INT3 pending flags
		out EIFR, mpr
		pop mpr
		out SREG, mpr           ; re-enables I-bit naturally
		pop waitcnt
		pop mpr
		ret

;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		push mpr
		push waitcnt
		in mpr, SREG
		push mpr
		cli                     ; disable interrupts during behavior
		inc lcnt
		rcall DisplayCounters

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime*2	; Wait for 2 seconds
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		ldi mpr, 0b00001011     ; clear INT0, INT1, INT3 pending flags
		out EIFR, mpr
		pop mpr
		out SREG, mpr           ; re-enables I-bit naturally
		pop waitcnt
		pop mpr
		ret

DisplayCounters:
    push mpr
    push XL
    push XH

    ; Clear both lines
    rcall LCDClr

    ; Write "R:" and rcnt to line 1
    ldi XL, low($0100)
    ldi XH, high($0100)
    ldi mpr, 'R'
    st X+, mpr
    ldi mpr, ':'
    st X+, mpr
    mov mpr, rcnt
    rcall Bin2ASCII

    ; Write "L:" and lcnt to line 2
    ldi XL, low($0110)
    ldi XH, high($0110)
    ldi mpr, 'L'
    st X+, mpr
    ldi mpr, ':'
    st X+, mpr
    mov mpr, lcnt
    rcall Bin2ASCII

    rcall LCDWrite

    pop XH
    pop XL
    pop mpr
    ret

ClearCounters:
		clr rcnt
		clr lcnt
		rcall DisplayCounters
		ret

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label

		; Save variable by pushing them to the stack

		; Execute the function here

		; Restore variable by popping them from the stack in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"


