;***********************************************************
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	spd = r17
.def	zero = r18

.equ	Spd1 = 0
.equ	Spd2 = 1
.equ	Spd3 = 2
.equ	Spd4 = 3

.equ	EngEnR = 5				; right Engine Enable Bit
.equ	EngEnL = 6				; left Engine Enable Bit
.equ	EngDirR = 4				; right Engine Direction Bit
.equ	EngDirL = 7				; left Engine Direction Bit

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

.org	$0002
		rjmp	SPEED_DOWN		; INT0 - speed down

.org	$0004
		rjmp	SPEED_UP		; INT1 - speed up

.org	$000E
		rjmp	SPEED_MAX		; INT3 - max speed

.org	$0056					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		; Clear zero register
		clr		zero

		; Initialize Port B for output (motors)
		ldi		mpr, 0xFF
		out		DDRB, mpr		; set all Port B pins as output
		ldi		mpr, 0x00
		out		PORTB, mpr		; initialize all Port B outputs low

		; Initialize Port D for input (buttons)
		ldi		mpr, 0x00
		out		DDRD, mpr		; set all Port D pins as input
		ldi		mpr, 0xFF
		out		PORTD, mpr		; enable pull-up resistors on Port D

		; Configure External Interrupts
		ldi		mpr, 0b1000_1010
		sts		EICRA, mpr		; INT0, INT1, INT3 falling edge
		ldi		mpr, 0b0000_1011
		out		EIMSK, mpr		; enable INT0, INT1, INT3

		; Configure 16-bit Timer/Counter 1A and 1B
		clr		mpr
		sts		TCNT1H, mpr
		sts		TCNT1L, mpr

		; Fast PWM, 8-bit mode, no prescaling
		ldi		mpr, 0b10110001
		sts		TCCR1A, mpr
		ldi		mpr, 0b00010001
		sts		TCCR1B, mpr

		; Set initial speed to 0
		clr		spd
		sts		OCR1AL, zero
		sts		OCR1BL, zero

		; Set TekBot to Move Forward on Port B
		ldi		mpr, (1<<EngDirR)|(1<<EngDirL)|(1<<EngEnR)|(1<<EngEnL)
		out		PORTB, mpr

		; NOTE: This must be the last thing to do in the INIT function
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN			; loop forever, interrupts handle everything

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

SPEED_DOWN:
		push	mpr
		push	spd
		in		mpr, SREG
		push	mpr

		cpi		spd, 0
		breq	SPEED_DOWN_DONE

		; Decrement speed level
		dec		spd

		; Calculate new OCR value (spd * 17)
		ldi		mpr, 17
		mul		spd, mpr		; result in r0
		clr		r1				; clear r1 after mul
		sts		OCR1AL, r0
		sts		OCR1BL, r0

		; Update Port B - preserve direction bits, update speed bits
		in		mpr, PORTB
		andi	mpr, 0b11110000		; clear lower nibble
		or		mpr, spd			; OR in speed LEVEL (0-15), not OCR value
		out		PORTB, mpr

SPEED_DOWN_DONE:
		pop		mpr
		out		SREG, mpr
		pop		spd
		pop		mpr
		reti

;-----------------------------------------------------------

SPEED_UP:
		push	mpr
		push	spd
		in		mpr, SREG
		push	mpr

		cpi		spd, 15
		breq	SPEED_UP_DONE

		; Increment speed level
		inc		spd

		; Calculate new OCR value (spd * 17)
		ldi		mpr, 17
		mul		spd, mpr		; result in r0
		clr		r1				; clear r1 after mul
		sts		OCR1AL, r0
		sts		OCR1BL, r0

		; Update Port B - preserve direction bits, update speed bits
		in		mpr, PORTB
		andi	mpr, 0b11110000	; clear lower nibble
		or		mpr, r0			; OR in new speed value
		out		PORTB, mpr

SPEED_UP_DONE:
		pop		mpr
		out		SREG, mpr
		pop		spd
		pop		mpr
		reti

;-----------------------------------------------------------

SPEED_MAX:
		push	mpr
		push	spd
		in		mpr, SREG
		push	mpr

		; Set speed to max
		ldi		spd, 15

		; 15 * 17 = 255
		ldi		mpr, 17
		mul		spd, mpr		; result in r0 = 255
		clr		r1				; clear r1 after mul
		sts		OCR1AL, r0
		sts		OCR1BL, r0

		; Update Port B - preserve direction bits, update speed bits
		in		mpr, PORTB
		andi	mpr, 0b11110000	; clear lower nibble
		ori		mpr, 0b00001111	; set all speed bits (speed 15)
		out		PORTB, mpr

SPEED_MAX_DONE:
		pop		mpr
		out		SREG, mpr
		pop		spd
		pop		mpr
		reti

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************