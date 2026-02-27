;***********************************************************
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;*	 Author: Graham Brown and Matt Wallin
;*	   Date: 2/27/2026
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

		; Configure 16-bit Timer/Counter 1A and 1B
		clr		mpr
		sts		TCNT1H, mpr
		sts		TCNT1L, mpr

		; Fast PWM, 8-bit mode, no prescaling
		ldi		mpr, 0b10100001
		sts		TCCR1A, mpr
		ldi		mpr, 0b00001001
		sts		TCCR1B, mpr

		; Set initial speed to max, display on Port B pins 3:0
		ldi		spd, 15
		ldi		mpr, 255
		sts		OCR1AH, zero
		sts		OCR1AL, mpr
		sts		OCR1BH, zero
		sts		OCR1BL, mpr

		; Set TekBot to Move Forward and speed on Port B
		ldi		mpr, (1<<EngDirR)|(1<<EngDirL)|(1<<EngEnR)|(1<<EngEnL)
		ori		mpr, 0b00001111
		out		PORTB, mpr

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		; poll Port D pushbuttons
		in		mpr, PIND
		andi	mpr, 0b00001011

		; if pressed, adjust speed
		cpi		mpr, 0b00001010
		breq	SPEED_DOWN

		cpi		mpr, 0b00001001
		breq	SPEED_UP

		cpi		mpr, 0b00000011
		breq	SPEED_MAX

		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

SPEED_DOWN:
		; Check if already at speed 0
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
		andi	mpr, 0b11110000	; clear lower nibble
		or		mpr, spd		; OR in speed LEVEL (0-15)
		out		PORTB, mpr

		; Wait for button release
SPEED_DOWN_WAIT:
		in		mpr, PIND
		andi	mpr, 0b00001011
		cpi		mpr, 0b00001011
		brne	SPEED_DOWN_WAIT

SPEED_DOWN_DONE:
		rjmp	MAIN


SPEED_UP:
		; Check if already at speed 15
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
		or		mpr, spd		; OR in speed LEVEL (0-15)
		out		PORTB, mpr

		; Wait for button release
SPEED_UP_WAIT:
		in		mpr, PIND
		andi	mpr, 0b00001011
		cpi		mpr, 0b00001011
		brne	SPEED_UP_WAIT

SPEED_UP_DONE:
		rjmp	MAIN


SPEED_MAX:
		; Set speed to max
		ldi		spd, 15
		ldi		mpr, 255
		sts		OCR1AH, zero
		sts		OCR1AL, mpr
		sts		OCR1BH, zero
		sts		OCR1BL, mpr

		; Update Port B - preserve direction bits, update speed bits
		in		mpr, PORTB
		andi	mpr, 0b11110000	; clear lower nibble
		ori		mpr, 0b00001111	; set all speed bits (speed 15)
		out		PORTB, mpr

		; Wait for button release
SPEED_MAX_WAIT:
		in		mpr, PIND
		andi	mpr, 0b00001011
		cpi		mpr, 0b00001011
		brne	SPEED_MAX_WAIT

SPEED_MAX_DONE:
		rjmp	MAIN

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program