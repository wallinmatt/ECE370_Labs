
;***********************************************************
;*
;*	This is the TRANSMIT skeleton file for Lab 7 of ECE 375
;*
;*  	Rock Paper Scissors
;* 	Requirement:
;* 	1. USART1 communication
;* 	2. Timer/counter1 Normal mode to create a 1.5-sec delay
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m32U4def.inc"         ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def    mpr = r16               ; Multi-Purpose Register
.def waitcnt = r17              ; Wait Counter

; Use this signal code between two boards for their game ready
.equ    SendReady = 0b11111111
.equ	WTime = 100				; Time to wait in wait loop

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;***********************************************************
;*  Interrupt Vectors
;***********************************************************
.org    $0000                   ; Beginning of IVs
	    rjmp    INIT            	; Reset interrupt


.org    $0056                   ; End of Interrupt Vectors

;***********************************************************
;*  Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi	mpr, low(RAMEND)
	out	SPL, mpr
	ldi	mpr, high(RAMEND)
	out	SPH, mpr
	;I/O Ports
	ldi	mpr, 0xFF
	out	DDRB, mpr
	ldi	mpr, 0x00
	out	PORTB, mpr

	ldi	mpr, 0x00
	out	DDRD, mpr
	ldi	mpr, 0xFF
	out	PORTD, mpr

	;USART1
	;Set baudrate at 2400bps
	ldi	mpr, 0b0000_0001
	out	UBRR1H, mpr
	ldi	mpr, 0b1010_0000
	out	UBRR1L, mpr

	;Enable receiver and transmitter
	ldi	mpr, 0b0001_1000
	out	UCSR1B, mpr

	;Set frame format: 8 data bits, 2 stop bits
	ldi	mpr, 0b0000_1110
	out	UCSR1C, mpr

	;TIMER/COUNTER1
		;Set Normal mode
	ldi	mpr, 0b1010_0000 
	sts	TCCR1A, mpr
	ldi	mpr, 0b0000_0001
	sts	TCCR1B, mpr

	;Other
	rcall LCDInit
	rcall LCDBacklightOn


;***********************************************************
;*  Main Program
;***********************************************************
MAIN:

	;TODO: ???

		rjmp	MAIN


WaitSixSecs:
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


;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_START:
    .DB		"Welcome!"		; Declaring data in ProgMem
STRING_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

