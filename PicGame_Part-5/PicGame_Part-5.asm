                  LIST     P = P12F629

                  INCLUDE  "../P12F629.INC"

                  __CONFIG _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _BOREN_OFF & _CP_OFF & _CPD_OFF



;# PicGame - Microchip PIC Microcontroller Repeat Game
;# Copyright (C) 2017 Jason Birch
;#
;# This program is free software: you can redistribute it and/or modify
;# it under the terms of the GNU General Public License as published by
;# the Free Software Foundation, either version 3 of the License, or
;# (at your option) any later version.
;#
;# This program is distributed in the hope that it will be useful,
;# but WITHOUT ANY WARRANTY; without even the implied warranty of
;# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;# GNU General Public License for more details.
;#
;# You should have received a copy of the GNU General Public License
;# along with this program.  If not, see <http://www.gnu.org/licenses/>.



;/****************************************************************************/
;/* PicGame_Part-5 - Microchip PIC Microcontroller Repeat Game               */
;/*                  Part 5 - Lighting the LEDs.                             */
;/* V1.00 2017-06-28 (C) Jason Birch                                         */
;/*                                                                          */
;/* PIC Game Programming Series to demonstrate programming a Microchip PIC   */
;/* microcontroller. This part in the series covers lighting the LEDs on the */
;/* hardware.                                                                */
;/****************************************************************************/



;/*************/
;/* Constants */
;/*************/
SW_LED_1          EQU      GP5                  ; GPIO pin allocated for switch and LED 1.
SW_LED_2          EQU      GP2                  ; GPIO pin allocated for switch and LED 2.
SW_LED_3          EQU      GP0                  ; GPIO pin allocated for switch and LED 3.
SW_LED_4          EQU      GP4                  ; GPIO pin allocated for switch and LED 4.

SPEAKER           EQU      GP1                  ; GPIO pin allocated for speaker.

F_LED_SEQ_PAUSE   EQU      7                    ; Flag an LED sequence will pause, with application pause.

F_RESET_APP       EQU      0                    ; Re-initialise application flag.
F_PAUSED          EQU      1                    ; Application pausing flag.



;/******************/
;/* RAM Registers. */
;/******************/
CBLOCK            0x20
                  TEMP1                         ; Temporary register.
                  TEMP2                         ; Temporary register.

                  APP_FLAGS                     ; Application flags.
                  LED_STATE                     ; Current LED state.

                  LED_SEQ_ADR                   ; LED Sequence pattern address.
                  LED_SEQ_COUNT                 ; LED Sequence pattern count.
ENDC



                  CODE

;/**********************************/
;/* Reset program location vector. */
;/**********************************/
                  ORG      0x0000

                  MOVLW    0x20                 ; Clear all RAM values, except random cache.
                  MOVWF    FSR                  ; Set first RAM address.
                  MOVLW    0x30                 ; Clear 48 bytes of RAM.
                  GOTO     INIT                 ; Navigate around PIC intrupt vector address.



;/*************************************/
;/* Interupt program location vector. */
;/*************************************/
                  ORG      0x0004

                  RETFIE



;/*******************************/
;/* Initialise microcontroller. */
;/*******************************/
INIT              CALL     CLEAR_RAM            ; Clear all RAM values.
RESET_INIT        BCF      STATUS, RP0          ; Select Register bank 0
                  MOVLW    0x07                 ; Switch comparitor off.
                  MOVWF    CMCON                ; Comparitor in lowest power mode.
                  BSF      STATUS, RP0          ; Select Register bank 1
                  CLRF     TRISIO               ; All LED GPIO as an output.
                  BCF      STATUS, RP0          ; Select Register bank 0
                  MOVLW    (1 << SW_LED_1)|(1 << SW_LED_2)|(1 << SW_LED_3)|(1 << SW_LED_4)
                  MOVWF    GPIO                 ; Switch all LED GPIO outputs to on.

                  CALL     RESET_APP            ; Reset application variables.



;/******************************/
;/***** TEST HARNESS START *****/
;/******************************/
                  BSF      APP_FLAGS, F_PAUSED  ; LED Animations only occur when application is flagged as paused.
                  MOVLW    LED_SEQ_ROT_CLOCK    ; Rotating LED animation to show application is active and waiting.
                  CALL     SET_LED_ANIM
LOOP              CALL     NEXT_LED_ANIM_SEQ    ; Animate to next LED sequence.
                  CALL     LED_DISPLAY          ; Update LEDs.
                  CALL     PAUSE
                  GOTO     LOOP                 ; Infinite main loop.



PAUSE             CLRF     TEMP2
PAUSE_LOOP        CLRF     TEMP1
PAUSE_DELAY       DECFSZ   TEMP1
                  GOTO     PAUSE_DELAY
                  DECFSZ   TEMP2
                  GOTO     PAUSE_LOOP
                  RETURN
;/******************************/
;/*****  TEST HARNESS END  *****/
;/******************************/




;/***************************************************************************/
;/ * Re-initialise required registers on power up and reset of application. */
;/***************************************************************************/
RESET_APP         BCF      APP_FLAGS, F_RESET_APP ; Clear reset application flag.
                  BCF      APP_FLAGS, F_PAUSED  ; Ensure not paused.
                  RETURN



;/****************************************************************************/
;/* Update the LED display, at the GPIO pins of the device. The output of    */
;/* the actual GPIO outputs is always 0 for all pins. The LEDs are switched  */
;/* by changing the port direction of each pin. This is done for power       */
;/* saving reasons. The LEDs are held constantly high on one side, the other */
;/* side is pulled low by making the pin an output to switch an LED on.      */
;/* The LEDs are switched off by making the pin an input (high impedence).   */
;/* This saves power, as when the LED is on - pin pulled low. Pressing a     */
;/* switch has little effect as this also switches the LED on. But when the  */
;/* LED is off, the pin is high impedence, so pressing a swtich just         */
;/* switches the LED on. If the GPIO pin where held high to switch off the   */
;/* LED, pressing a swtich would not only switch on the LED, but also pull   */
;/* current from the output of the GPIO pin, and waste battery power.        */
;/*                                                                          */
;/* CALL WITH:                                                               */
;/* LED_STATE - The state of the TRISIO register.                            */
;/****************************************************************************/
LED_DISPLAY       MOVFW    LED_STATE            ; Get the current LED state to display.
                  XORLW    0xFF                 ; Invert the state so TRISIO method lights LEDs correctly.
                  ANDLW    (1 << SW_LED_1)|(1 << SW_LED_2)|(1 << SW_LED_3)|(1 << SW_LED_4)
                  BSF      STATUS, RP0          ; Select Register bank 1
                  MOVWF    TRISIO
                  BCF      STATUS, RP0          ; Select Register bank 0
                  MOVLW    ~((1 << SW_LED_1)|(1 << SW_LED_2)|(1 << SW_LED_3)|(1 << SW_LED_4))
                  ANDWF    GPIO, F              ; Ensure GPIO register is clear for all LEDs.
                  RETURN



;/***************************************/
;/* Start a new LED animation sequence. */
;/*                                     */
;/* CALL WITH:                          */
;/* W - Address of new LED animation.   */
;/***************************************/
SET_LED_ANIM      CLRF     LED_SEQ_COUNT        ; Initialise the LED animation sequence.
                  MOVWF    LED_SEQ_ADR
                  CLRF     LED_STATE            ; Don't light any LEDs at start of LED animation.
                  CALL     LED_DISPLAY          ; Update LEDs.
                  RETURN



;/*******************************************/
;/* Animate to next LED animation sequence. */
;/*******************************************/
NEXT_LED_ANIM_SEQ BTFSS    APP_FLAGS, F_PAUSED  ; Check if application is paused.
                  GOTO     SEQ_NO_PAUSE
                  BTFSC    LED_STATE, F_LED_SEQ_PAUSE ; Don't change LED sequence if flagged to pause with application.
                  GOTO     END_EEPROM_SEQ
SEQ_NO_PAUSE      MOVFW    LED_SEQ_ADR          ; Get the address for the current animation sequence.
                  ADDWF    LED_SEQ_COUNT, W     ; Add the offset to the position to get next value.
                  INCF     LED_SEQ_COUNT        ; Point to the next address.
                  CALL     READ_EEPROM          ; Read the next animation value.
                  XORLW    0xFF                 ; Check for end of animation.
                  BTFSS    STATUS, Z            ; A value of 0xFF, is the end of sequence.
                  GOTO     SET_EEPROM_SEQ
                  CLRF     LED_SEQ_COUNT        ; Point to the start of sequence when at end.
                  CALL     NEXT_LED_ANIM_SEQ    ; Get the start animation value, by recursion.
                  XORLW    0xFF                 ; Adjust for recursion.
SET_EEPROM_SEQ    XORLW    0xFF                 ; Undo end of sequence check effect on W.
                  MOVWF    LED_STATE            ; Update LEDs.
END_EEPROM_SEQ    RETURN



;/****************************************/
;/* Read a value from an EEPROM address. */
;/*                                      */
;/* CALL WITH:                           */
;/* W - EEPROM address.                  */
;/*                                      */
;/* RETURNS WITH:                        */
;/* W - EEPROM value read.               */
;/****************************************/
READ_EEPROM       BSF      STATUS, RP0          ; Select Register bank 1
                  MOVWF    EEADR                ; Point to the address in EEPROM.
                  BSF      EECON1, RD           ; Read from EEPROM.
                  MOVFW    EEDATA               ; Read the value from EEPROM.
                  BCF      STATUS, RP0          ; Select Register bank 0
                  RETURN



;/*****************************/
;/* Reset a RAM area to 0x00. */
;/*                           */
;/* CALL WITH:                */
;/* FSR - Start RAM address.  */
;/* W   - Byte clear count.   */
;/*****************************/
CLEAR_RAM         CLRF     INDF                 ; Clear RAM address.
                  INCF     FSR                  ; Point to next RAM address,
                  ADDLW    0xFF                 ; Subtract 1 from loop count.
                  BTFSS    STATUS, Z
                  GOTO     CLEAR_RAM            ; Loop until all RAM addresses cleared.
                  RETURN



                  ORG      0x2100               ; EEPROM Area.

LED_SEQ_NULL      DE       0x00
                  DE       0xFF

LED_SEQ_ROT_CLOCK DE       (1 << SW_LED_1)
                  DE       (1 << SW_LED_2)
                  DE       (1 << SW_LED_3)
                  DE       (1 << SW_LED_4)
                  DE       0xFF

LED_SEQ_LEVEL     DE       (1 << F_LED_SEQ_PAUSE)|(1 << SW_LED_1)
                  DE       (1 << F_LED_SEQ_PAUSE)|(1 << SW_LED_1)|(1 << SW_LED_2)
                  DE       (1 << F_LED_SEQ_PAUSE)|(1 << SW_LED_1)|(1 << SW_LED_2)|(1 << SW_LED_3)
                  DE       (1 << F_LED_SEQ_PAUSE)|(1 << SW_LED_1)|(1 << SW_LED_2)|(1 << SW_LED_3)|(1 << SW_LED_4)
                  DE       0xFF

LED_SEQ_WIN       DE       (1 << SW_LED_1)|(1 << SW_LED_2)|(1 << SW_LED_3)|(1 << SW_LED_4)
                  DE       0x00
                  DE       0xFF

LED_SEQ_LOSE      DE       (1 << SW_LED_1)|(1 << SW_LED_3)
                  DE       (1 << SW_LED_2)|(1 << SW_LED_4)
                  DE       0xFF



                  END

