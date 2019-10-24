// StepperMotorController.c starter file EE319K Lab 5
// Runs on TM4C123
// Finite state machine to operate a stepper motor.  
// Jonathan Valvano
// January 18, 2019

/** Modified by Marc Julian Jamerlan on 10-22-2019 **/ 

// Hardware connections (External: two input buttons and four outputs to stepper motor)
//  PA5 is Wash input  (1 means pressed, 0 means not pressed)
//  PA4 is Wiper input  (1 means pressed, 0 means not pressed)
//  PE5 is Water pump output (toggle means washing)
//  PE4-0 are stepper motor outputs 
//  PF1 PF2 or PF3 control the LED on Launchpad used as a heartbeat
//  PB6 is LED output (1 activates external LED on protoboard)

#include "SysTick.h"
#include "TExaS.h"
#include <stdint.h>
#include "../inc/tm4c123gh6pm.h"

void EnableInterrupts(void);
// edit the following only if you need to move pins from PA4, PE3-0      
// logic analyzer on the real board
#define PA4       (*((volatile unsigned long *)0x40004040))
#define PE50      (*((volatile unsigned long *)0x400240FC))
void SendDataToLogicAnalyzer(void){
  UART0_DR_R = 0x80|(PA4<<2)|PE50;
}

struct State
	{
		uint32_t w_out;	// wiper out
		uint32_t l_out; // wash out
		uint32_t delay;
		const struct State *next[4];
	};
	typedef const struct State state_t;
	
	//start state
	#define S1 &fsm[0]
	// wiper states
	#define S2_0 &fsm[1]
	#define S3_0 &fsm[2]
	#define S4_0 &fsm[3]
	#define S5_0 &fsm[4]
	#define S6_0 &fsm[5]
	#define S7_0 &fsm[6]
	#define S8_0 &fsm[7]
	#define S9_0 &fsm[8]
	#define S10_0 &fsm[9]
	#define S11_0 &fsm[10]
	#define S12_0 &fsm[11]
	#define S13_0 &fsm[12]
	#define S14_0 &fsm[13]
	#define S15_0 &fsm[14]
	#define S16_0 &fsm[15]
	#define S17_0 &fsm[16]
	#define S18_0 &fsm[17]
	#define S19_0 &fsm[18]
	#define S20_0 &fsm[19]
	// wiper + washer states
	#define S2_1 &fsm[20]
	#define S3_1 &fsm[21]
	#define S4_1 &fsm[22]
	#define S5_1 &fsm[23]
	#define S6_1 &fsm[24]
	#define S7_1 &fsm[25]
	#define S8_1 &fsm[26]
	#define S9_1 &fsm[27]
	#define S10_1 &fsm[28]
	#define S11_1 &fsm[29]
	#define S12_1 &fsm[30]
	#define S13_1 &fsm[31]
	#define S14_1 &fsm[32]
	#define S15_1 &fsm[33]
	#define S16_1 &fsm[34]
	#define S17_1 &fsm[35]
	#define S18_1 &fsm[36]
	#define S19_1 &fsm[37]
	#define S20_1 &fsm[38]
	
	state_t fsm[39] = 
	{
		// wiper_out, wash_out, wait, {00, wash_on, wiper_only, 11}
		{0x00, 0, 5, {S1, S2_1, S2_0, S2_1}},
		{0x01, 0, 5, {S3_0, S3_1, S3_0, S3_1}},
		{0x02, 0, 5, {S4_0, S4_1, S4_0, S4_1}},
		{0x04, 0, 5, {S5_0, S5_1, S5_0, S5_1}},
		{0x08, 0, 5, {S6_0, S6_1, S6_0, S6_1}},
		{0x10, 0, 5, {S7_0, S7_1, S7_0, S7_1}},
		{0x01, 0, 5, {S8_0, S8_1, S8_0, S8_1}},
		{0x02, 0, 5, {S9_0, S9_1, S9_0, S9_1}},
		{0x04, 0, 5, {S10_0, S10_1, S10_0, S10_1}},
		{0x08, 0, 5, {S11_0, S11_1, S11_0, S11_1}},
		{0x10, 0, 5, {S12_0, S12_1, S12_0, S12_1}},
		{0x08, 0, 5, {S13_0, S13_1, S13_0, S13_1}},
		{0x04, 0, 5, {S14_0, S14_1, S14_0, S14_1}},
		{0x02, 0, 5, {S15_0, S15_1, S15_0, S15_1}},
		{0x01, 0, 5, {S16_0, S16_1, S16_0, S16_1}},
		{0x10, 0, 5, {S17_0, S17_1, S17_0, S17_1}},
		{0x08, 0, 5, {S18_0, S18_1, S18_0, S18_1}},
		{0x04, 0, 5, {S19_0, S19_1, S19_0, S19_1}},
		{0x02, 0, 5, {S20_0, S20_1, S20_0, S20_1}},
		{0x01, 0, 5, {S1, S1, S1, S1}},
		{0x01, 1, 5, {S3_1, S3_1, S3_1, S3_1}},
		{0x02, 1, 5, {S4_1, S4_1, S4_1, S4_1}},
		{0x04, 1, 5, {S5_1, S5_1, S5_1, S5_1}},
		{0x08, 1, 5, {S6_1, S6_1, S6_1, S6_1}},
		{0x10, 1, 5, {S7_1, S7_1, S7_1, S7_1}},
		{0x01, 1, 5, {S8_1, S8_1, S8_1, S8_1}},
		{0x02, 1, 5, {S9_1, S9_1, S9_1, S9_1}},
		{0x04, 1, 5, {S10_1, S10_1, S10_1, S10_1}},
		{0x08, 1, 5, {S11_1, S11_1, S11_1, S11_1}},
		{0x10, 1, 5, {S12_1, S12_1, S12_1, S12_1}},
		{0x08, 1, 5, {S13_1, S13_1, S13_1, S13_1}},
		{0x04, 1, 5, {S14_1, S14_1, S14_1, S14_1}},
		{0x02, 1, 5, {S15_1, S15_1, S15_1, S15_1}},
		{0x01, 1, 5, {S16_1, S16_1, S16_1, S16_1}},
		{0x10, 1, 5, {S17_1, S17_1, S17_1, S17_1}},
		{0x08, 1, 5, {S18_1, S18_1, S18_1, S18_1}},
		{0x04, 1, 5, {S19_1, S19_1, S19_1, S19_1}},
		{0x02, 1, 5, {S20_1, S20_1, S20_1, S20_1}},
		{0x01, 1, 5, {S1, S1, S1, S1}}
	};

void Port_Init(void)
{
	SYSCTL_RCGCGPIO_R = 0x33; // Clock for Ports A, B, E, F
	while((SYSCTL_PRGPIO_R & 0x33) == 0){}; // wait until ready
	// Port A init
	GPIO_PORTA_DIR_R = 0x00; // PA4-5 input
	GPIO_PORTA_DEN_R = 0x30; 	
	// Port B init 
	GPIO_PORTB_DIR_R = 0x40; // PB6 output	
	GPIO_PORTB_DEN_R = 0x40;
	// Port E init
	GPIO_PORTE_DIR_R = 0x3F; // PE0-5 output
	GPIO_PORTE_DEN_R = 0x3F; 	
	// Port F init
	GPIO_PORTF_LOCK_R = 0x4C4F434B;
	GPIO_PORTF_CR_R = 0x01;  // unlock PF1
	GPIO_PORTF_DIR_R = 0x01; // PF1 output 
	GPIO_PORTF_PUR_R = 0x01; // enable pullup on PF1
	GPIO_PORTF_DEN_R = 0x01; 	
}

uint32_t swapBits(uint32_t bits)
{
	uint32_t bit1 = (bits << 1) & 0x03;
	uint32_t bit2 = (bits >> 1) & 0x03;
	return bit1 | bit2;
}

int main(void){ 
	uint32_t in;	
	state_t *pt; // state pointer
	
  TExaS_Init(&SendDataToLogicAnalyzer);    // activate logic analyzer and set system clock to 80 MHz
  SysTick_Init(); 
	Port_Init();
	
	pt = S1;
	
  EnableInterrupts();   
  while(1){
		// output
		GPIO_PORTF_DATA_R = 0x01; // heartbeat
		GPIO_PORTE_DATA_R = pt->w_out; // send to PE0-4
		GPIO_PORTE_DATA_R |= pt->l_out << 5; // send to PE5
			
		SysTick_Wait10ms(pt->delay); // wait
		in = swapBits((GPIO_PORTA_DATA_R >> 5) & 0x03); // input
		pt = pt->next[in]; // next				
  }
}


