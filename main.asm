stm8/

	#include "mapping.inc"
	#include "stm8s103f.inc"
	
	segment byte at 100 'ram1'
buffer1  ds.b
buffer2  ds.b
buffer3  ds.b
nibble1  ds.b	
pad1     ds.b	
	
	
	segment 'rom'
main.l
	; initialize SP
	ldw X,#stack_end
	ldw SP,X

	#ifdef RAM0	
	; clear RAM0
ram0_start.b EQU $ram0_segment_start
ram0_end.b EQU $ram0_segment_end
	ldw X,#ram0_start
clear_ram0.l
	clr (X)
	incw X
	cpw X,#ram0_end	
	jrule clear_ram0
	#endif

	#ifdef RAM1
	; clear RAM1
ram1_start.w EQU $ram1_segment_start
ram1_end.w EQU $ram1_segment_end	
	ldw X,#ram1_start
clear_ram1.l
	clr (X)
	incw X
	cpw X,#ram1_end	
	jrule clear_ram1
	#endif

	; clear stack
stack_start.w EQU $stack_segment_start
stack_end.w EQU $stack_segment_end
	ldw X,#stack_start
clear_stack.l
	clr (X)
	incw X
	cpw X,#stack_end	
	jrule clear_stack

main_loop.l
							; timer1 setup for PWM on PC4 timer1 chanel4 (hardware w/o gpio)
	  mov CLK_CKDIVR,#$0    ; set max internal clock 16mhz
	  mov TIM1_CR1,#$E0	; enable both CMS bits for center aligned mode3 ,APRE bit set for ARR preload enable
	  ;mov TIM1_CR1,#$80		; APRE enable with edge aligned 
	  mov TIM1_PSCRH,#$0    ; timer 2 prescaler div by 0 runs at FCPU 16mhz
	  mov TIM1_PSCRL,#$0    ; timer 2 prescaler div by 0 runs at FCPU 16mhz
	  mov TIM1_ARRH,#$7d    ; count to 32000 ,high byte must be loaded  first,
	  mov TIM1_ARRL,#$00    ; frequency of signal becomes 16000000/32000=500hz or 0.5khz
	  mov TIM1_CCR4H,#$0c   ; compare register set to 3200 =10% of count, duty cycle 
	  mov TIM1_CCR4L,#$80 	; duty cycle is either 10% or 90% bassed on poarity (32000/3200)=10,320=1%
	  ;bset TIM1_CCER2,#5  	; setting polarity bit of timer2 makes ch2 output opposite,comment out if need not  
	  mov TIM1_CCMR4,#$60 	; set to PWM mode 1
	  bset TIM1_CCMR4,#3	; OC4PE: Output compare 2 preload enable
	  bset TIM1_CCER2,#4    ; enable chan 4 as output
	  bset TIM1_BKR,#7		; enable output compare
	  bset TIM1_CR1,#0      ; set CEN bit to enable the timer

setup						; timer4 setup for delay 1ms base timer
	  bset PD_DDR,#5
	  bset PD_ODR,#5
	  mov TIM4_PSCR ,#$07	; select timer 4 prescaler to 128, 7 means 2^7=128
	  mov TIM4_ARR,#249		; 16mhz/128=125000 =1s,125000/1000=125cycles/milli,load 250-1 as 0 is counted=249 =2ms
	  bset TIM4_IER,#0		; enable update interrupt in interrupt register
	  bset TIM4_CR1,#0		; enable timer4
	  rim					; enable interrupt globally
	  
 



here
	
	mov buffer2,#12		; array counter
	ldw X,#value		; pointer to array label "value" ,address is loaded in X
	
delay_loop
	ld a,buffer1		; copy buffer 1 value to reg A
	cp a,#250			; compare A to 250 ,has it reached 250ms??
	jrne delay_loop		; if not wait in loop
	bcpl PD_ODR,#5		; toggle led on PD5 to indicate timer4 is working
loop
	incw x				; increase pointer
	ld a,(x)			; load pwm high byte from array to a
	ld TIM1_CCR4H,a		; load a to capture compare register high , strictly follow sequence
	incw X				; increase pointer to next byte
	ld a,(x)			; load a with low byte of the 16 bit PWM value from address in X
	ld TIM1_CCR4L,a		; load a to capture compare register low,strictly follow sequence

	dec buffer2			; decrease array counter
	jreq here			; if array counter reach 0 jump to label "here"to reload
	jp delay_loop		; if array counter not 0 loop through array till counter is 0
	
	
value dc.b 	$00,$7D,$00,$0C,$80,$19,$00,$25,$80,$32,$00,$3E,$80,$4B,$00 ;PWM values array
value1 dc.b $57,$80,$64,$00,$70,$80,$00,$00   	
	  
	Interrupt timer4_ISR
timer4_ISR
	bres TIM4_SR,#0	; clear update interrupt flag
	inc buffer1		; increase buffer1 by 1 count every 1ms
	iret			; return from interrupt
	  



	
	
	
	interrupt NonHandledInterrupt
NonHandledInterrupt.l
	iret

	segment 'vectit'
	dc.l {$82000000+main}									; reset
	dc.l {$82000000+NonHandledInterrupt}	; trap
	dc.l {$82000000+NonHandledInterrupt}	; irq0
	dc.l {$82000000+NonHandledInterrupt}	; irq1
	dc.l {$82000000+NonHandledInterrupt}	; irq2
	dc.l {$82000000+NonHandledInterrupt}	; irq3
	dc.l {$82000000+NonHandledInterrupt}	; irq4
	dc.l {$82000000+NonHandledInterrupt}	; irq5
	dc.l {$82000000+NonHandledInterrupt}	; irq6
	dc.l {$82000000+NonHandledInterrupt}	; irq7
	dc.l {$82000000+NonHandledInterrupt}	; irq8
	dc.l {$82000000+NonHandledInterrupt}	; irq9
	dc.l {$82000000+NonHandledInterrupt}	; irq10
	dc.l {$82000000+NonHandledInterrupt}	; irq11
	dc.l {$82000000+NonHandledInterrupt}	; irq12
	dc.l {$82000000+NonHandledInterrupt}	; irq13
	dc.l {$82000000+NonHandledInterrupt}	; irq14
	dc.l {$82000000+NonHandledInterrupt}	; irq15
	dc.l {$82000000+NonHandledInterrupt}	; irq16
	dc.l {$82000000+NonHandledInterrupt}	; irq17
	dc.l {$82000000+NonHandledInterrupt}	; irq18
	dc.l {$82000000+NonHandledInterrupt}	; irq19
	dc.l {$82000000+NonHandledInterrupt}	; irq20
	dc.l {$82000000+NonHandledInterrupt}	; irq21
	dc.l {$82000000+NonHandledInterrupt}	; irq22
	dc.l {$82000000+timer4_ISR}	; irq23	; irq23
	dc.l {$82000000+NonHandledInterrupt}	; irq24
	dc.l {$82000000+NonHandledInterrupt}	; irq25
	dc.l {$82000000+NonHandledInterrupt}	; irq26
	dc.l {$82000000+NonHandledInterrupt}	; irq27
	dc.l {$82000000+NonHandledInterrupt}	; irq28
	dc.l {$82000000+NonHandledInterrupt}	; irq29

	end
