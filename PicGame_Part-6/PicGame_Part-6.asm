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
;/* PicGame_Part-6 - Microchip PIC Microcontroller Repeat Game               */
;/*                  Part 6 - Playing Sound.                                 */
;/* V1.00 2017-06-28 (C) Jason Birch                                         */
;/*                                                                          */
;/* PIC Game Programming Series to demonstrate programming a Microchip PIC   */
;/* microcontroller. This part in the series covers playing sound on the     */
;/* hardware.                                                                */
;/****************************************************************************/



;/*************/
;/* Constants */
;/*************/
SILENT_FREQ_H     EQU      0xFF                 ; Timer period for tune slient period.

SW_LED_1          EQU      GP5                  ; GPIO pin allocated for switch and LED 1.
SW_LED_2          EQU      GP2                  ; GPIO pin allocated for switch and LED 2.
SW_LED_3          EQU      GP0                  ; GPIO pin allocated for switch and LED 3.
SW_LED_4          EQU      GP4                  ; GPIO pin allocated for switch and LED 4.

SPEAKER           EQU      GP1                  ; GPIO pin allocated for speaker.

F_LED_SEQ_PAUSE   EQU      7                    ; Flag an LED sequence will pause, with application pause.

F_RESET_APP       EQU      0                    ; Re-initialise application flag.
F_PAUSED          EQU      1                    ; Application pausing flag.
F_SOUND_ON        EQU      2                    ; Application flag for sound on/off.
F_SOUND_ACTIVE    EQU      3                    ; Application flag for sound currently active.



;/******************/
;/* RAM Registers. */
;/******************/
CBLOCK            0x20
                  INT_W                         ; Temporary store for W during interupt.
                  INT_STATUS                    ; Temporary store for STATUS during interupt.
                  TEMP1                         ; Temporary register.
                  TEMP2                         ; Temporary register.

                  BEEP_FREQ_L                   ; Frequency of current beep.
                  BEEP_FREQ_H
                  BEEP_LEN_L                    ; Duration of current beep.
                  BEEP_LEN_H
                  TUNE_PTR                      ; Pointer to current note in tune.

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

INT_HANDLE        MOVWF    INT_W                ; Store registers from application duting interupt.
                  MOVFW    STATUS
                  MOVWF    INT_STATUS

                  BCF      STATUS, RP0          ; Select Register bank 0

INT_TIMER1        BTFSS    PIR1, TMR1IF         ; Did a TIMER1 interupt trigger?
                  GOTO     INT_TIMER0
                  BTFSS    APP_FLAGS, F_SOUND_ACTIVE ; Is sound currently active?
                  GOTO     INT_TIMER1_END
                  MOVFW    BEEP_FREQ_L          ; Reset timer 1 count to required beep frequency period.
                  MOVWF    TMR1L
                  MOVFW    BEEP_FREQ_H
                  MOVWF    TMR1H
                  BTFSS    STATUS, Z            ; If quiet peiod, silent beep.
                  GOTO     MAKE_SOUND
                  MOVLW    SILENT_FREQ_H        ; Silent periods have a specific frequency period as
                  MOVWF    TMR1H                ; the period effects the length of the duration for the beep.
                  GOTO     SPEAKER_ON
MAKE_SOUND        MOVFW    GPIO                 ; When using bidirectional ports, read port before bit operations.
                  BTFSC    GPIO, SPEAKER        ; Check the current state of the speaker GPIO output.
                  GOTO     SPEAKER_OFF
                  BSF      GPIO, SPEAKER        ; Toggle GPIO to on.
                  GOTO     SPEAKER_ON
SPEAKER_OFF       BCF      GPIO, SPEAKER        ; Toggle GPIO to off.
SPEAKER_ON        DECFSZ   BEEP_LEN_L           ; Play beep for specified duration.
                  GOTO     INT_TIMER1_END
                  DECFSZ   BEEP_LEN_H
                  GOTO     INT_TIMER1_END
                  BCF      APP_FLAGS, F_SOUND_ACTIVE ; When duration complete stop beep by flagging beep off.
                  BCF      GPIO, SPEAKER        ; Switch off speaker at end for low power as default.
INT_TIMER1_END    BCF      PIR1, TMR1IF

INT_TIMER0

INT_END           MOVFW    INT_STATUS           ; Restore registers for application to continue after interupt.
                  MOVWF    STATUS
                  MOVFW    INT_W
                  BSF      STATUS, Z
                  BTFSS    INT_STATUS, Z
                  BCF      STATUS, Z
                  RETFIE



;/*******************************/
;/* Initialise microcontroller. */
;/*******************************/
INIT              CALL     CLEAR_RAM            ; Clear all RAM values.
RESET_INIT        BCF      STATUS, RP0          ; Select Register bank 0
                  MOVLW    0x07                 ; Switch comparitor off.
                  MOVWF    CMCON                ; Comparitor in lowest power mode.
                  BSF      STATUS, RP0          ; Select Register bank 1
                  BSF      PIE1, TMR1IE         ; Configure Timer1 interupts.
                  CLRF     TRISIO               ; All LED GPIO as an output.
                  BCF      STATUS, RP0          ; Select Register bank 0
                  MOVLW    (1 << SW_LED_1)|(1 << SW_LED_2)|(1 << SW_LED_3)|(1 << SW_LED_4)
                  MOVWF    GPIO                 ; Switch all LED GPIO outputs to on.
                  MOVLW    (1 << NOT_T1SYNC)|(1 << TMR1ON)
                  MOVWF    T1CON                ; Prescale timer 1 for beep frequencies.
                  BCF      PIR1, TMR1IF         ; Prepair timer 1 for first interupt.

                  CALL     RESET_APP            ; Reset application variables.

                  MOVLW    (1 << GIE)|(1 << PEIE) ; |(1 << GPIE)|(1 << TMR0IE)
                  MOVWF    INTCON               ; Enable interupts.
                  CLRF     PIR1                 ; Clear interupt triggered flags.


;/******************************/
;/***** TEST HARNESS START *****/
;/******************************/
                  BSF      APP_FLAGS, F_PAUSED  ; LED Animations only occur when application is flagged as paused.
                  BSF      APP_FLAGS, F_SOUND_ON ; Toggle sound on.
                  MOVLW    TUNE_WIN             ; Play win tune.
                  MOVWF    TUNE_PTR
                  MOVLW    LED_SEQ_ROT_CLOCK    ; Rotating LED animation to show application is active and waiting.
                  CALL     SET_LED_ANIM
LOOP              CALL     NEXT_LED_ANIM_SEQ    ; Animate to next LED sequence.
                  CALL     PLAY_NEXT_BEEP       ; Play the next note of a tune, if playing.
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
RESET_APP         CLRF     TUNE_PTR             ; No tune currently playing.
                  BCF      APP_FLAGS, F_RESET_APP ; Clear reset application flag.
                  BCF      APP_FLAGS, F_PAUSED  ; Ensure not paused.
                  RETURN



;/**********************************************************************/
;/* Whan a tune is being played, an interupt will call this routing to */
;/* start the next beep playing when the previous beep ends. Or stop   */
;/* playing at the end of the tune.                                    */
;/**********************************************************************/
PLAY_NEXT_BEEP    MOVFW    TUNE_PTR             ; Is tune currently playing?
                  BTFSC    STATUS, Z
                  GOTO     NEXT_BEEP_END
                  BTFSC    APP_FLAGS, F_SOUND_ACTIVE ; Is beep currently playing?
                  GOTO     NEXT_BEEP_END
                  CALL     READ_EEPROM          ; Get the next note to play.
                  BTFSS    STATUS, Z            ; Is note end of tune marker?
                  GOTO     PLAY_NEXT_NOTE
                  CLRF     TUNE_PTR             ; Switch off tune at end of tune.
                  GOTO     NEXT_BEEP_END
PLAY_NEXT_NOTE    CALL     START_BEEP           ; Start playing next beep.
                  INCF     TUNE_PTR             ; Point to next note to play.
NEXT_BEEP_END     RETURN



;/*************************************************************************/
;/* Start playing a beep note for a given duration.                       */
;/*                                                                       */
;/* CALL WITH:                                                            */
;/* W - High nibble - Duration of beep.                                   */
;/* W - Low nibble - Offset to beep frequency in frequency look up table. */
;/*************************************************************************/
START_BEEP        BTFSS    APP_FLAGS, F_SOUND_ON ; Check if sound is enabled.
                  GOTO     NO_SOUND
                  BTFSC    APP_FLAGS, F_SOUND_ACTIVE ; Is beep currently playing?
                  GOTO     NO_SOUND
                  MOVWF    BEEP_LEN_L           ; Use W low nibble as the frequency of the beep.
                  MOVWF    BEEP_LEN_H           ; Use W high nibble as the length of the beep.
                  SWAPF    BEEP_LEN_H           ; Move high nibble to low nibble, beep length.
                  MOVLW    0x0F                 ; Mask for lower nibble only.
                  ANDWF    BEEP_LEN_H, F        ; Beep length is only lower nibble.
                  ANDWF    BEEP_LEN_L, F        ; Use lower nibble of W to lookup frequencey of beep.
                  MOVLW    FREQ_LOOKUP
                  ADDWF    BEEP_LEN_L, W        ; Calculate lookup EEPROM address.
                  CALL     READ_EEPROM          ; Get beep frequency period for timer 1.
                  MOVWF    BEEP_FREQ_H          ; Set timer periods for beep.
                  MOVWF    TMR1H
                  CLRF     BEEP_FREQ_L
                  CLRF     TMR1L
                  CLRF     BEEP_LEN_L
                  BSF      APP_FLAGS, F_SOUND_ACTIVE ; Start beep by switching on timer 1.
NO_SOUND          RETURN



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

FREQ_LOOKUP       DE       0x00                 ; Silent beep definition.
                  DE       0xF1                 ; Frequency period for note 1
                  DE       0xF2                 ; Frequency period for note 2
                  DE       0xF3                 ; Frequency period for note 3
                  DE       0xF4                 ; Frequency period for note 4
                  DE       0xF5                 ; Frequency period for note 5
                  DE       0xF6                 ; Frequency period for note 6
                  DE       0xF7                 ; Frequency period for note 7
                  DE       0xF8                 ; Frequency period for note 8
                  DE       0xF9                 ; Frequency period for note 9
                  DE       0xFA                 ; Frequency period for note A
                  DE       0xFB                 ; Frequency period for note B
                  DE       0xFC                 ; Frequency period for note C
                  DE       0xFD                 ; Frequency period for note D
                  DE       0xFE                 ; Frequency period for note E
                  DE       0xFF                 ; Frequency period for note F

TUNE_LEVEL_LOOKUP DE       TUNE_LEVEL_ONE
                  DE       TUNE_LEVEL_TWO
                  DE       TUNE_LEVEL_THREE
                  DE       TUNE_LEVEL_FOUR

TUNE_LEVEL_ONE    DE       1F, 00

TUNE_LEVEL_TWO    DE       1F, 10, 1F, 00

TUNE_LEVEL_THREE  DE       1F, 10, 1F, 10, 1F, 00

TUNE_LEVEL_FOUR   DE       1F, 10, 1F, 10, 1F, 10, 1F, 00

TUNE_SOUND_ON     DE       1E, 10, 1F, 00

TUNE_WIN          DE       4E, 4F, 4E, 4F, 4E, 4F, 00

TUNE_LOSE         DE       35, 10, 31, 00

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

