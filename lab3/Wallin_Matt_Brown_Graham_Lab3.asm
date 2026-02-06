;***********************************************************
;*	This is the skeleton file for Lab 3 of ECE 370
;*
;*	 Author: Graham Brown and Matt Wallin
;*	   Date: 2/6/2026
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is required for LCD Driver
.def	temp = r17
.def	waitcnt = r18
.def	ilcnt = r19
.def	olcnt = r23

.equ	buffTime = 25
.equ	button4 = 4
.equ	button5 = 5
.equ	button7 = 7
.equ	WTime = 25

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

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

		; Initialize LCD Display
		rcall LCDInit

		; NOTE that there is no RET or RJMP from INIT,
		; this is because the next instruction executed is the
		; first instruction of the main program

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		rcall LCDClr
		rcall LCDBacklightOn
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:

		; Move strings from Program Memory to Data Memory

		; Display the strings on the LCD Display

		in		mpr, PIND
		andi	mpr, (1<<button4|1<<button5|1<<button7)
		cpi   mpr, (1<<button4|1<<button7)
		brne CHECK_B4
		rcall storeString1
		rcall storeString2
		rcall LCDWrite
		rjmp	MAIN
CHECK_B4:	
		cpi   mpr, (1<<button5|1<<button7)
		brne CHECK_B7
		rcall LCDClr
		rcall LCDWrite
		rjmp MAIN
CHECK_B7: 
		cpi   mpr, (1<<button4|1<<button5)
		brne MAIN
		rcall storeString1
		rcall storeString2
		rcall displayTicker
		rjmp MAIN
		


;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: storeString1
; Desc: Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
storeString1:							; Begin a function with a label
		; Save variables by pushing them to the stack
		push ZL
		push ZH
		push YL
		push YH
		push mpr

		; Load Z pointer with STRING1_BEG address
		ldi ZL, low(STRING1_BEG<<1)     ; Load low byte (<<1 for word addressing)
		ldi ZH, high(STRING1_BEG<<1)    ; Load high byte

		ldi YL, low($0100)          ; Line 1 starts at $0100
		ldi YH, high($0100)

		LOOP1:
			lpm mpr, Z+                      ; Load byte and increment Z
			st Y+, mpr                       ; Store to data memory
			cpi ZL, low(STRING1_END<<1) ; while (Z != address after last character)
			brne LOOP1
			cpi ZH, high(STRING1_END<<1)
			brne LOOP1
			

		; Execute the function here

		; Restore variables by popping them from the stack,
		; in reverse order

		pop mpr
		pop YH
		pop YL
		pop ZH
		pop ZL
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: storeString2
; Desc: Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
storeString2:
		; Save variables by pushing them to the stack
		push ZL
		push ZH
		push YL
		push YH
		push mpr

		; Load Z pointer with STRING1_BEG address
		ldi ZL, low(STRING2_BEG<<1)     ; Load low byte (<<1 for word addressing)
		ldi ZH, high(STRING2_BEG<<1)    ; Load high byte

		ldi YL, low($0110)          ; Line 1 starts at $0100
		ldi YH, high($0110)

		LOOP2:
			lpm mpr, Z+                      ; Load byte and increment Z
			st Y+, mpr                       ; Store to data memory
			cpi ZL, low(STRING2_END<<1) ; while (Z != address after last character)
			brne LOOP2
			cpi ZH, high(STRING2_END<<1)
			brne LOOP2
			

		; Execute the function here

		; Restore variables by popping them from the stack,
		; in reverse order

		pop mpr
		pop YH
		pop YL
		pop ZH
		pop ZL
		ret						; End a function with RET

displayTicker: 
    push ZL
    push ZH
    push YL
    push YH
    push mpr
    push temp

TICKER:
    ; Save the first character
    ldi YL, low($0100)
    ldi YH, high($0100)
    ld temp, Y              ; Save first char in temp

    ldi ZL, low($0101)      ; Z = source (starts at second char)
    ldi ZH, high($0101)
    
SHIFT_STRS:
    ld mpr, Z+              ; Load from source, increment Z
    st Y+, mpr              ; Store to dest, increment Y
    cpi YL, low($0120)      ; Check if we've reached end of buffer
    brne SHIFT_STRS
    cpi YH, high($0120)
    brne SHIFT_STRS

    ; Put the saved first character at the end
    ldi YL, low($011F)
    ldi YH, high($011F)
    st Y, temp

    rcall LCDWrite
	ldi		waitcnt, WTime
	rcall Wait
	rjmp TICKER

    pop temp
    pop mpr
    pop YH
    pop YL
    pop ZH
    pop ZL
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

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING1_BEG:
.DB		"Matt and Graham "		; Declaring data in ProgMem
STRING1_END:

STRING2_BEG:
.DB		"were here!      "		; Declaring data in ProgMem
STRING2_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

