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

.include "m32U4def.inc"

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def    mpr     = r16
.def    waitcnt = r17
.def    ilcnt   = r18
.def    olcnt   = r19

.def    gesture = r23
.def    oppGest = r24

.equ    SendReady   = 0b11111111
.equ    GestRock    = 0b00000001
.equ    GestPaper   = 0b00000010
.equ    GestScissor = 0b00000011

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg

;***********************************************************
;*  Interrupt Vectors
;***********************************************************
.org    $0000
        rjmp    INIT

.org    $0056

;***********************************************************
;*  Program Initialization
;***********************************************************
INIT:
        ; Stack Pointer
        ldi     mpr, low(RAMEND)
        out     SPL, mpr
        ldi     mpr, high(RAMEND)
        out     SPH, mpr

        ; I/O Ports
        ldi     mpr, 0xFF
        out     DDRB, mpr
        ldi     mpr, 0x00
        out     PORTB, mpr

        ldi     mpr, 0x00
        out     DDRD, mpr
        ldi     mpr, 0xFF
        out     PORTD, mpr

        ; USART1
        ; Enable U2X1 (double speed)
        ldi     mpr, 0b00000010
        sts     UCSR1A, mpr

        ; Set baud rate: UBRR = 832 = 0x0340 (16MHz, U2X1, 2400bps)
        ldi     mpr, 0x03
        sts     UBRR1H, mpr
        ldi     mpr, 0x40
        sts     UBRR1L, mpr

        ; Enable receiver and transmitter
        ldi     mpr, 0b00011000
        sts     UCSR1B, mpr

        ; Frame format: async, no parity, 2 stop bits, 8 data bits
        ldi     mpr, 0b00001110
        sts     UCSR1C, mpr

        ; Timer/Counter1: Normal mode, no clock source yet
        ldi     mpr, 0b00000000
        sts     TCCR1A, mpr
        ldi     mpr, 0b00000000
        sts     TCCR1B, mpr

        ; LCD
        rcall   LCDInit
        rcall   LCDBacklightOn
        rcall   LCDClr

        ; Initialize gesture
        ldi     gesture, GestRock

;***********************************************************
;*  Main Program
;***********************************************************
MAIN:
        ; Reset gesture each round
        ldi     gesture, GestRock

        ; Flush any stale bytes in RX buffer from previous round
FlushStale:
        lds     mpr, UCSR1A
        sbrs    mpr, RXC1
        rjmp    FlushDone
        lds     mpr, UDR1
        rjmp    FlushStale
FlushDone:

        ; Display "Welcome! / Please press PD7"
        rcall   LCDClrLn1
        rcall   LCDClrLn2
        ldi     ZL, low(WelcomeMsg1<<1)
        ldi     ZH, high(WelcomeMsg1<<1)
        ldi     XL, low(0x0100)
        ldi     XH, high(0x0100)
        rcall   CopyStringToSRAM
        ldi     ZL, low(WelcomeMsg2<<1)
        ldi     ZH, high(WelcomeMsg2<<1)
        ldi     XL, low(0x0110)
        ldi     XH, high(0x0110)
        rcall   CopyStringToSRAM
        rcall   LCDWrite

        ; Poll PD7 (active low), wait for press then release
WaitPD7:
        in      mpr, PIND
        sbrc    mpr, 7
        rjmp    WaitPD7
WaitPD7Release:
        in      mpr, PIND
        sbrs    mpr, 7
        rjmp    WaitPD7Release

        ; Display "Ready. Waiting / for the opponent"
        rcall   LCDClrLn1
        rcall   LCDClrLn2
        ldi     ZL, low(ReadyMsg1<<1)
        ldi     ZH, high(ReadyMsg1<<1)
        ldi     XL, low(0x0100)
        ldi     XH, high(0x0100)
        rcall   CopyStringToSRAM
        ldi     ZL, low(ReadyMsg2<<1)
        ldi     ZH, high(ReadyMsg2<<1)
        ldi     XL, low(0x0110)
        ldi     XH, high(0x0110)
        rcall   CopyStringToSRAM
        rcall   LCDWrite

        ; Send ready, wait for opponent
        rcall   CheckReady

        ; Display "Game start"
        rcall   LCDClrLn1
        rcall   LCDClrLn2
        ldi     ZL, low(GameStartMsg<<1)
        ldi     ZH, high(GameStartMsg<<1)
        ldi     XL, low(0x0100)
        ldi     XH, high(0x0100)
        rcall   CopyStringToSRAM
        rcall   LCDWrite

        ; Turn all 4 LEDs on (PB7:4)
        in      mpr, PORTB
        ori     mpr, 0b11110000
        out     PORTB, mpr

        ; Countdown: 4 x 1.5sec, polling PD4
        ldi     r25, 4
CountdownLoop:
        rcall   Wait1p5Sec_PD4
        rcall   TurnOffNextLED
        dec     r25
        brne    CountdownLoop

        ; Exchange gestures with opponent
        rcall   ExchangeGestures

        ; Show both gestures
        rcall   DisplayGestures

        ; Turn all 4 LEDs back on for result countdown
        in      mpr, PORTB
        ori     mpr, 0b11110000
        out     PORTB, mpr

        ; Result countdown: 4 x 1.5sec
        ldi     r25, 4
ResultCountdown:
        rcall   Wait1p5Sec
        rcall   TurnOffNextLED
        dec     r25
        brne    ResultCountdown

        ; Show result
        rcall   ShowResult

        ; Brief pause then restart
        rcall   Wait1p5Sec

        rjmp    MAIN

;***********************************************************
;*  CopyStringToSRAM
;*  Copies 16 bytes from program memory (Z) to SRAM (X)
;***********************************************************
CopyStringToSRAM:
        push    mpr
        push    ilcnt

        ldi     ilcnt, 16
CopyLoop:
        lpm     mpr, Z+
        st      X+, mpr
        dec     ilcnt
        brne    CopyLoop

        pop     ilcnt
        pop     mpr
        ret

;***********************************************************
;*  CheckReady
;*  Transmits ready signal, waits for opponent ready
;***********************************************************
CheckReady:
        push    mpr
        push    ilcnt
        push    olcnt

CRSendReady:
        ; Wait for TX buffer empty, then send ready
        lds     mpr, UCSR1A
        sbrs    mpr, UDRE1
        rjmp    CRSendReady
        ldi     mpr, SendReady
        sts     UDR1, mpr

        ; Wait a short time for opponent to respond
        ldi     olcnt, 200
CRWaitOuter:
        ldi     ilcnt, 200
CRWaitInner:
        dec     ilcnt
        brne    CRWaitInner
        dec     olcnt
        brne    CRWaitOuter

        ; Check if we got a response
        lds     mpr, UCSR1A
        sbrs    mpr, RXC1
        rjmp    CRSendReady     ; no response yet, send again

        ; Read and verify the response
        lds     mpr, UDR1
        cpi     mpr, SendReady
        brne    CRSendReady     ; wrong byte, send again

        ; Got valid ready from opponent ï¿½ done
        pop     olcnt
        pop     ilcnt
        pop     mpr
        ret

;***********************************************************
;*  ExchangeGestures
;*  Sends own gesture, receives opponent gesture into oppGest
;***********************************************************
ExchangeGestures:
        push    mpr

        ; Flush stale ready bytes left over from CheckReady
EGFlush:
        lds     mpr, UCSR1A
        sbrs    mpr, RXC1
        rjmp    EGFlushDone
        lds     mpr, UDR1
        rjmp    EGFlush
EGFlushDone:

WaitTX_Gest:
        lds     mpr, UCSR1A
        sbrs    mpr, UDRE1
        rjmp    WaitTX_Gest
        sts     UDR1, gesture

WaitRX_Gest:
        lds     mpr, UCSR1A
        sbrs    mpr, RXC1
        rjmp    WaitRX_Gest
        lds     oppGest, UDR1

        pop     mpr
        ret

;***********************************************************
;*  Wait1p5Sec
;*  1.5 second delay using Timer/Counter1 Normal mode
;*  16MHz / 1024 = 15625 ticks/sec
;*  1.5 sec = 23438 ticks
;*  Preload = 65536 - 23438 = 42098 = 0xA432
;***********************************************************
Wait1p5Sec:
        push    mpr

        ldi     mpr, 0b00000101
        sts     TCCR1B, mpr

        ldi     mpr, 0xA4
        sts     TCNT1H, mpr
        ldi     mpr, 0x32
        sts     TCNT1L, mpr

        ldi     mpr, (1<<TOV1)
        out     TIFR1, mpr

WaitOvf:
        in      mpr, TIFR1
        sbrs    mpr, TOV1
        rjmp    WaitOvf

        ldi     mpr, 0b00000000
        sts     TCCR1B, mpr

        pop     mpr
        ret

;***********************************************************
;*  Wait1p5Sec_PD4
;*  1.5 sec delay, polls PD4 for gesture cycling
;***********************************************************
Wait1p5Sec_PD4:
        push    mpr

        ldi     mpr, 0b00000101
        sts     TCCR1B, mpr

        ldi     mpr, 0xA4
        sts     TCNT1H, mpr
        ldi     mpr, 0x32
        sts     TCNT1L, mpr

        ldi     mpr, (1<<TOV1)
        out     TIFR1, mpr

PD4PollLoop:
        in      mpr, TIFR1
        sbrs    mpr, TOV1
        rjmp    CheckPD4
        rjmp    TimerDonePD4

CheckPD4:
        in      mpr, PIND
        sbrc    mpr, 4
        rjmp    PD4PollLoop

        inc     gesture
        cpi     gesture, 4
        brne    NoWrap
        ldi     gesture, GestRock
NoWrap:
        rcall   DisplayCurrentGesture

WaitPD4Release:
        in      mpr, PIND
        sbrs    mpr, 4
        rjmp    WaitPD4Release

        rjmp    PD4PollLoop

TimerDonePD4:
        ldi     mpr, 0b00000000
        sts     TCCR1B, mpr

        pop     mpr
        ret

;***********************************************************
;*  TurnOffNextLED
;*  Turns off highest lit LED in PB7:4, preserves PB3:0
;***********************************************************
TurnOffNextLED:
        push    mpr
        in      mpr, PORTB

        sbrc    mpr, 7
        rjmp    OffPB7
        sbrc    mpr, 6
        rjmp    OffPB6
        sbrc    mpr, 5
        rjmp    OffPB5
        sbrc    mpr, 4
        rjmp    OffPB4
        rjmp    LEDDone

OffPB7:
        andi    mpr, 0b01111111
        rjmp    WriteLED
OffPB6:
        andi    mpr, 0b10111111
        rjmp    WriteLED
OffPB5:
        andi    mpr, 0b11011111
        rjmp    WriteLED
OffPB4:
        andi    mpr, 0b11101111

WriteLED:
        out     PORTB, mpr
LEDDone:
        pop     mpr
        ret

;***********************************************************
;*  DisplayCurrentGesture
;*  Copies own gesture string to SRAM line 2 and renders
;***********************************************************
DisplayCurrentGesture:
        push    mpr

        cpi     gesture, GestRock
        breq    DCG_Rock
        cpi     gesture, GestPaper
        breq    DCG_Paper

DCG_Scissor:
        ldi     ZL, low(ScissorMsg<<1)
        ldi     ZH, high(ScissorMsg<<1)
        rjmp    DCG_Write
DCG_Rock:
        ldi     ZL, low(RockMsg<<1)
        ldi     ZH, high(RockMsg<<1)
        rjmp    DCG_Write
DCG_Paper:
        ldi     ZL, low(PaperMsg<<1)
        ldi     ZH, high(PaperMsg<<1)

DCG_Write:
        ldi     XL, low(0x0110)
        ldi     XH, high(0x0110)
        rcall   CopyStringToSRAM
        rcall   LCDWrLn2

        pop     mpr
        ret

;***********************************************************
;*  DisplayGestures
;*  Opponent on line 1, self on line 2
;***********************************************************
DisplayGestures:
        push    mpr

        rcall   LCDClr

        ; Opponent gesture to line 1 SRAM
        cpi     oppGest, GestRock
        breq    DG_OppRock
        cpi     oppGest, GestPaper
        breq    DG_OppPaper

DG_OppScissor:
        ldi     ZL, low(ScissorMsg<<1)
        ldi     ZH, high(ScissorMsg<<1)
        rjmp    DG_WriteOpp
DG_OppRock:
        ldi     ZL, low(RockMsg<<1)
        ldi     ZH, high(RockMsg<<1)
        rjmp    DG_WriteOpp
DG_OppPaper:
        ldi     ZL, low(PaperMsg<<1)
        ldi     ZH, high(PaperMsg<<1)

DG_WriteOpp:
        ldi     XL, low(0x0100)
        ldi     XH, high(0x0100)
        rcall   CopyStringToSRAM
        rcall   LCDWrLn1

        rcall   DisplayCurrentGesture

        pop     mpr
        ret

;***********************************************************
;*  ShowResult
;*  Compares gesture and oppGest, displays outcome
;***********************************************************
ShowResult:
        push    mpr

        rcall   LCDClr

        cp      gesture, oppGest
        breq    IsDraw

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
        cpi     oppGest, GestPaper
        breq    IsWin
        rjmp    IsLose

IsWin:
        ldi     ZL, low(WinMsg<<1)
        ldi     ZH, high(WinMsg<<1)
        rjmp    SR_WriteLine1

IsDraw:
        ldi     ZL, low(DrawMsg<<1)
        ldi     ZH, high(DrawMsg<<1)
        rjmp    SR_WriteLine1

IsLose:
        ldi     ZL, low(LoseMsg<<1)
        ldi     ZH, high(LoseMsg<<1)

SR_WriteLine1:
        ldi     XL, low(0x0100)
        ldi     XH, high(0x0100)
        rcall   CopyStringToSRAM
        rcall   LCDWrLn1

        rcall   DisplayCurrentGesture

        pop     mpr
        ret

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
;*  Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"
