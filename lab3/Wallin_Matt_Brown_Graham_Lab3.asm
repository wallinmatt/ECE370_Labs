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
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Main function design is up to you. Below is an example to brainstorm.

		; Move strings from Program Memory to Data Memory

		; Display the strings on the LCD Display

		rcall LCDBacklightOn

		rcall storeString1

		rcall storeString2

		rcall LCDWrite

		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

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
			LPM mpr, Z+                      ; Load byte and increment Z
			ST Y+, mpr                       ; Store to data memory
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
storeString2:							; Begin a function with a label
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
			LPM mpr, Z+                      ; Load byte and increment Z
			ST Y+, mpr                       ; Store to data memory
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
.DB		"were here!"		; Declaring data in ProgMem
STRING2_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

