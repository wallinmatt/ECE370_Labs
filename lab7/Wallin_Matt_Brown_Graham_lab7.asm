
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
	ldi	mpr, 0b0000_0000 ;Need to calculate bitrate
	out	UBRR1H, mpr
	ldi	mpr, 0b0000_0000
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


;***********************************************************
;*	Functions and Subroutines
;***********************************************************

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

CheckReady:
	push mpr

ChooseInput:
; TODO

DisplayGestures:
	push    mpr

	rcall   LCDClr

	; Opponent on line 1
	cpi     oppGest, GestRock
	breq    OppRock
	cpi     oppGest, GestPaper
	breq    OppPaper
	cpi     oppGest, GestScissor
	breq    OppScissor
	rjmp    ShowSelf

OppRock:
	ldi     ZL, low(RockMsg<<1)
	ldi     ZH, high(RockMsg<<1)
	rjmp    WriteOpp
OppPaper:
	ldi     ZL, low(PaperMsg<<1)
	ldi     ZH, high(PaperMsg<<1)
	rjmp    WriteOpp
OppScissor:
	ldi     ZL, low(ScissorMsg<<1)
	ldi     ZH, high(ScissorMsg<<1)

WriteOpp:
	ldi     mpr, 1
	rcall   LCDWriteLine

ShowSelf:
	rcall   DisplayCurrentGesture

	pop     mpr
	ret

ShowResult:
	push    mpr

	rcall   LCDClr

	; Check draw
	cp      gesture, oppGest
	breq    IsDraw

	; Rock=1, Paper=2, Scissors=3
	; Win conditions: Rock beats Scissors (1 vs 3)
	;                 Paper beats Rock    (2 vs 1)
	;                 Scissors beats Paper(3 vs 2)
	cpi     gesture, GestRock
	brne    CheckPaperWin
	cpi     oppGest, GestScissor
	breq    IsWin
	rjmp    IsLose

CheckPaperWin:
	cpi     gesture, GestPaper
	brne    CheckScissorWin
	cpi     oppGest, GestRock
	breq    IsWin
	rjmp    IsLose

CheckScissorWin:
	cpi     gesture, GestScissor
	brne    IsLose
	cpi     oppGest, GestPaper
	breq    IsWin
	rjmp    IsLose

IsWin:
	ldi     ZL, low(WinMsg<<1)
	ldi     ZH, high(WinMsg<<1)
	ldi     mpr, 1
	rcall   LCDWriteLine
	rjmp    ResultSelf

IsDraw:
	ldi     ZL, low(DrawMsg<<1)
	ldi     ZH, high(DrawMsg<<1)
	ldi     mpr, 1
	rcall   LCDWriteLine
	rjmp    ResultSelf

IsLose:
	ldi     ZL, low(LoseMsg<<1)
	ldi     ZH, high(LoseMsg<<1)
	ldi     mpr, 1
	rcall   LCDWriteLine

ResultSelf:
	rcall   DisplayCurrentGesture

	pop     mpr
	ret
;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
;***********************************************************
;*  Stored Program Data
;***********************************************************
WelcomeMsg1:
	.DB     "Welcome!        "
WelcomeMsg2:
	.DB     "Please press PD7"
ReadyMsg1:
	.DB     "Ready. Waiting  "
ReadyMsg2:
	.DB     "for the opponent"
GameStartMsg:
	.DB     "Game start      "
RockMsg:
	.DB     "Rock            "
PaperMsg:
	.DB     "Paper           "
ScissorMsg:
	.DB     "Scissor         "
WinMsg:
	.DB     "You won!        "
LoseMsg:
	.DB     "You lost        "
DrawMsg:
	.DB     "Draw            "

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
