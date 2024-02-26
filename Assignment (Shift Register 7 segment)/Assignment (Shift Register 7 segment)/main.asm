;
; Assignment (Shift Register 7 segment).asm
;
; Created: 2/24/2024 12:26:51
; Author : Lenovo
;


; Include the definition file for ATmega328P
.include "m328pdef.inc"

; Define constants for better readability
.equ    BITOUT=256
.equ    INDEX=257
.equ    SWITCH_PIN = PINC ; Assume dipswitch is connected to PORTC

; Define register variables
.def    TMP = r20
.def    DELAYTEMP = r25
.def    DELAYTEMP2 = r26
.def    SysBitTest = r5
.def    SysCalcTempA = r22
.def    SysValueCopy = r21
.def    SysWaitTempMS = r29
.def    SysWaitTempMS_H = r30
.def    SysTemp1=r0

; Program start and stack initialization
nop
BASPROGRAMSTART:
    ldi SysValueCopy, high(RAMEND)
    out SPH, SysValueCopy
    ldi SysValueCopy, low(RAMEND)
    out SPL, SysValueCopy
    rcall INITSYS
    rcall INIT595

SysDoLoop_S1:
    ; Set BITOUT to 1 and shift the bit
    ldi SysValueCopy, 1
    sts BITOUT, SysValueCopy
    rcall SHIFTBIT

    ; Delay for selected time based on dipswitch
    rcall CheckDipswitch

    ; Reset INDEX to 0
    ldi SysValueCopy, 0
    sts INDEX, SysValueCopy

SysForLoop1:
    ; Increment INDEX and shift the bit
    lds SysTemp1, INDEX
    inc SysTemp1
    sts INDEX, SysTemp1
    ldi SysValueCopy, 0
    sts BITOUT, SysValueCopy
    rcall SHIFTBIT

    ; Delay for selected time based on dipswitch
    rcall CheckDipswitch

    ; Check if INDEX is less than 7 and loop accordingly
    lds SysCalcTempA, INDEX
    cpi SysCalcTempA, 7
    brlo SysForLoop1

SysForLoopEnd1:
    rjmp SysDoLoop_S1
SysDoLoop_E1:

BASPROGRAMEND:
    ; Enter sleep mode
    sleep
    rjmp BASPROGRAMEND

; Initialization subroutine for system
INITSYS:
    ldi SysValueCopy, 0
    out PORTB, SysValueCopy
    ldi SysValueCopy, 0
    out PORTC, SysValueCopy
    ldi SysValueCopy, 0
    out PORTD, SysValueCopy
    ret

; Subroutine to shift a bit
SHIFTBIT:
    cbi PORTB, 3
    cbi PORTB, 4
    cbi PORTB, 1
    lds SysBitTest, BITOUT
    sbrc SysBitTest, 0
    sbi PORTB, 1
    sbi PORTB, 4
    sbi PORTB, 3
    ret

; Initialization subroutine for 74HC595 shift register
INIT595:
    ; Set data direction for shift register pins
    sbi DDRB,5
    sbi DDRB,4
    sbi DDRB,3
    sbi DDRB,2
    sbi DDRB,1

    ; Clear shift register outputs
    cbi PORTB,5
    cbi PORTB,4
    cbi PORTB,3
    cbi PORTB,2
    cbi PORTB,1

    ; Set latch pin to high
    sbi PORTB,5

    ; Set data direction for port D pins
    sbi DDRD,5
    sbi DDRD,4
    sbi DDRD,3
    sbi DDRD,2
    sbi DDRD,1

    ; Clear port D outputs
    cbi PORTD,5
    cbi PORTD,4
    cbi PORTD,3
    cbi PORTD,2
    cbi PORTD,1

    ; Set latch pin to high
    sbi PORTD,5
    ret

; Delay in milliseconds subroutine
Delay_MS:
    inc SysWaitTempMS_H

DMS_START:
    ldi DELAYTEMP2,254

DMS_OUTER:
    ldi DELAYTEMP,20

DMS_INNER:
    dec DELAYTEMP
    brne DMS_INNER

    dec DELAYTEMP2
    brne DMS_OUTER

    dec SysWaitTempMS
    brne DMS_START

    dec SysWaitTempMS_H
    brne DMS_START

    ret

; Check dipswitch subroutine
CheckDipswitch:
    ldi TMP, 0xFF           ; Initialize TMP register to 0xFF
    in TMP, SWITCH_PIN      ; Read dipswitch value into TMP register

    ; Check if bit 1 is set (button 2 pressed)
    sbrc TMP, 0x00
    rjmp Delay_100MS

    rcall Delay_1S

    ; If no input is detected, delay 1 second
    ret



Delay_100MS:
    ldi SysWaitTempMS, 100    ; Set delay to 100 milliseconds
    ldi SysWaitTempMS_H, 0    ; Set delay MSB to 0
    rcall Delay_MS            ; Call the original delay subroutine
    ret

; Delay in 1 second subroutine
Delay_1S:
    ldi SysValueCopy, 10   ; Set loop count to 100 (100ms * 100 = 10000ms = 10s)

Delay_1S_Loop:
    rcall Delay_100MS       ; Call the 100ms delay subroutine
    dec SysValueCopy        ; Decrement loop counter
    brne Delay_1S_Loop      ; Repeat the loop until the counter reaches 0

    ret



