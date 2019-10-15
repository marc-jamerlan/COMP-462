;****************** main.s ***************
; Program written by: Marc Julian Jamerlan
; Date Created: 2/4/2017
; Last Modified: 10/14/2019
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE2 is Button input  (1 means pressed, 0 means not pressed)
;  PE3 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE3 an output and make PE2 and PF4 inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the button (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 70% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 2Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 30%.
;      TIP: debugging the breathing LED algorithm using the real board.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

       IMPORT  TExaS_Init
       THUMB
       AREA    DATA, ALIGN=2
       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
     BL  TExaS_Init ; voltmeter, scope on PD3
 ; Turn on Port E and Port F clock
	 ldr r0, =SYSCTL_RCGCGPIO_R
	 ldr r1, [r0]
	 orr r1, r1, #0x30
	 str r1, [r0]
 	 nop
	 nop
	 nop
	 nop
	 
; Make PE3 output	 
	 ldr r0, =GPIO_PORTE_DIR_R
	 mov r1, #0x08
	 str r1, [r0]
	 
; Enable Port E digital i/o  
	 ldr r0, =GPIO_PORTE_DEN_R
	 mov r1, #0x1F
	 str r1, [r0]
	 
; Unlock Port F lock register
	 ldr r0, =GPIO_PORTF_LOCK_R
	 ldr r1, =GPIO_LOCK_KEY
	 str r1, [r0]

; enable Port F commit
	 ldr r0, =GPIO_PORTF_CR_R	
	 mov r1, #0x10
	 str r1, [r0]
	 
; enable pull-up on PF4
	 ldr r0, =GPIO_PORTF_PUR_R	
	 mov r1, #0x10
	 str r1, [r0]	
	
; Make PF4 input
	 ldr r0, =GPIO_PORTF_DIR_R
	 mov r1, #0x00
	 str r1, [r0]
	 
; Enable Port F digital i/o  
	 ldr r0, =GPIO_PORTF_DEN_R
	 mov r1, #0x10
	 str r1, [r0]	 

     CPSIE  I    ; TExaS voltmeter, scope runs on interrupts	

init 
; Initialize duty cycle and delay registers	 
	 mov r6, #0x03		; 30% duty cycle
	 ldr r7, =0x2DC6C0	; DELAY1 = 150ms
	 ldr r8, =0X6ACFC0 ; DELAY2 = 350ms
	 ldr r9, =0x989680 ; FREQ = 500ms	 
loop 
	 ldr r0, =GPIO_PORTF_DATA_R
	 ldr r1, [r0]
	 and r1, #0x10 ; read switch input from PF4
	 cmp r1, #0	   ; 0 means pressed, otherwise continue	
	 beq breathingLEDInit
	 ldr r0, =GPIO_PORTE_DATA_R
	 ldr r1, [r0]	 
	 and r1, #0x04 ; read switch input from PE2
	 cmp r1, #4
	 beq pressed ; check if pressed; stop oscillations if pressed
loop2
; Set PE3 high 
	 orr r1, r1, #0x08 
	 str r1, [r0]
; Delay for high	 
	 mov r3, r7
wait
	 subs r3, r3, #0x01
	 bne wait
; Clear PE3 low	
	 ldr r1, [r0]
	 eor r1, r1, #0x08 
	 str r1, [r0]	 
; Delay for low	 
	 mov r3, r8
wait2
	 subs r3, r3, #0x01
	 bne wait2
     b loop
; continue looping until not pressed

pressed	 
	 ldr r0, =GPIO_PORTE_DATA_R
	 ldr r1, [r0]	 
	 and r2, r1, #0x04 ; read switch input from PE2
	 cmp r2, #0 
	 beq modDutyCycle 
	 b pressed
; if released, modify duty cycle and return to loop
modDutyCycle
; Calculate new duty cycle
	 mov r4, #10
	 add r6, r6, #2 ; increase duty cycle by 20%
	 udiv r2, r6, r4 
	 mls r6, r2, r4, r6 ; DUTYCYCLE = duty cycle - (10 * (duty cycle/10)) = duty cycle mod 10 
; Calculate new delay times	 
	 mov r1, r9
	 mul r3, r1, r6
	 udiv r3, r3, r4 ; DELAY1 = FREQ * duty cycle / 10 
	 sub r1, r1, r3 ; DELAY2 = FREQ - DELAY1 
	 mov r7, r3
	 mov r8, r1
	 b loop
	 
; initialize values for breathing LED
breathingLEDInit	
	 ldr r0, =GPIO_PORTE_DATA_R
	 ldr r1, [r0]
; Breathing LED values	 
	 mov r6, #0x01		; 10% duty cycle	
	 ldr r7, =0x4E20	; DELAY1 = 1ms
	 ldr r8, =0X2BF20 	; DELAY2 = 9ms
	 ldr r9, =0x30D40	; FREQ = 10ms
	 mov r10, #0		; counter = 0
	 mov r11, #0		; flag for breathing up or down
	 
; loop for breathing LED
breathingLEDloop
; Set PE3 high 
	 orr r1, r1, #0x08 
	 str r1, [r0]
; Delay for high	 
	 mov r3, r7
breathingLEDwait
	 subs r3, r3, #0x01
	 bne breathingLEDwait
; Clear PE3 low	
	 ldr r1, [r0]
	 eor r1, r1, #0x08 
	 str r1, [r0]	 
; Delay for low	 
	 mov r3, r8
breathingLEDwait2
	 subs r3, r3, #0x01
	 bne breathingLEDwait2	
; for(counter =0; counter < 9; counter++)	 
	 add r10, r10, #1
	 cmp r10, #9
	 bne breathingLEDloop
	 cmp r11, #0
	 bne breathingLEDdown
	 
breathingLEDup	 
; Calculate new duty cycle
	 mov r4, #10
	 add r6, r6, #1 ; increase duty cycle by 10%
	 udiv r2, r6, r4 
	 mls r6, r2, r4, r6 ; DUTYCYCLE = duty cycle - (10 * (duty cycle/10)) = duty cycle mod 10 
; Calculate new delay times	 
	 mov r1, r9
	 mul r3, r1, r6
	 udiv r3, r3, r4 ; DELAY1 = FREQ * duty cycle / 10 
	 sub r1, r1, r3 ; DELAY2 = FREQ - DELAY1 
	 mov r7, r3
	 mov r8, r1	
	 mov r10, #0 ; reinitialize counter to 0
	 cmp r6, #0
     bne breathingLEDloop
	 
breathingLEDdownInit	
	 mov r6, #0x09		; 90% duty cycle	
	 ldr r7, =0X2BF20 	; 9ms  
	 ldr r8, =0x4E20	; 1ms
	 mov r11, #1		; set flag to 1
breathingLEDdown
	; Calculate new duty cycle
	 mov r4, #10
	 sub r6, r6, #1 ; decrease duty cycle by 10%
	 udiv r2, r6, r4 
	 mls r6, r2, r4, r6 ; DUTYCYCLE = duty cycle - (10 * (duty cycle/10)) = duty cycle mod 10 
	; Calculate new delay times	 
	 mov r1, r9
	 mul r3, r1, r6
	 udiv r3, r3, r4 ; DELAY1 = FREQ * duty cycle / 10 
	 sub r1, r1, r3 ; DELAY2 = FREQ - DELAY1 
	 mov r7, r3
	 mov r8, r1	
	 mov r10, #0 ; reinitialize counter to 0
	 cmp r6, #0
     bne breathingLEDloop
	 b init
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file

