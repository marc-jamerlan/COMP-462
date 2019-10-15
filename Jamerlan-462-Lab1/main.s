;****************** main.s ***************
; Program initially written by: Yerraballi and Valvano
; Author: Marc Julian Jamerlan
; Date Created: 1/15/2018 
; Last Modified: 9/12/2019 
; Brief description of the program: Spring 2019 Lab1
; The objective of this system is to implement odd-bit counting system
; Hardware connections: 
;  Output is positive logic, 1 turns on the LED, 0 turns off the LED
;  Inputs are negative logic, meaning switch not pressed is 1, pressed is 0
;    PE0 is an input 
;    PE1 is an input 
;    PE2 is an input 
;    PE3 is the output
; Overall goal: 
;   Make the output 1 if there is an odd number of 1's at the inputs, 
;     otherwise make the output 0
; The specific operation of this system 
;   Initialize Port E to make PE0,PE1,PE2 inputs and PE3 an output
;   Over and over, read the inputs, calculate the result and set the output

; NOTE: Do not use any conditional branches in your solution. 
;       We want you to think of the solution in terms of logical and shift operations

GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_DEN_R   EQU 0x4002451C
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

      THUMB
      AREA    DATA, ALIGN=2
;global variables go here
      ALIGN
      AREA    |.text|, CODE, READONLY, ALIGN=2
      EXPORT  Start
Start
	  ;PORT INITIALIZATION
	  LDR R1, =SYSCTL_RCGCGPIO_R
	  LDR R0, [R1]
      ORR R0, R0, #0x10	; turns on clock at port e
	  STR R0, [R1]
	  NOP
	  NOP
	  LDR R1, =GPIO_PORTE_DEN_R
	  MOV R0, #0x0F ; digital I/O
	  STR R0, [R1]	
	  LDR R1, =GPIO_PORTE_DIR_R
	  MOV R0, #0x08	; PE3 output, all other pins input
	  STR R0, [R1]	
	  
loop
	  ;PARITY CALCULATION	
	  LDR R0, =GPIO_PORTE_DATA_R
	  LDR R1, [R0]
	  MOV R2, #0
	  MOV R3, #0
	  AND R2, R1, #1
	  ADD R3, R3, R2 ; add first bit
	  LSR R1, R1, #1 
	  AND R2, R1, #1
	  ADD R3, R3, R2 ; add second bit
	  LSR R1, R1, #1 
	  AND R2, R1, #1
	  ADD R3, R3, R2 ; add third bit
	  AND R3, R3, #1 
	  LSL R3, R3, #3 ; send result of parity calc to bit 4
	  LDR R0, =GPIO_PORTE_DATA_R
	  STR R3, [R0]
      B   loop

      ALIGN        ; make sure the end of this section is aligned
      END          ; end of file
          