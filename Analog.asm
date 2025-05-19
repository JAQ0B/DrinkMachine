;********************************************************
;
;                 Drinks maskine
;
;                                 Device : PIC16F873
;                                 Author : Jacob Jørgensen
;********************************************************
	list            p=PIC16F873
	include         p16f873.inc
	__config _HS_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF &_LVP_OFF & _DEBUG_OFF


AnalogValue 	equ 20h	;Variable for index lookup table
goToStart	equ 21h ;variable for number of times needed to go to start
d1		equ 22h	;Delay variable
d2		equ 23h	;Delay variable
d3		equ 24h	;Delay variable
d4		equ 25h	;Delay variable


	
;**************** Constants    ********************
activationPin    equ   RA1 ; Pin 7  PORTA,1
directionPin     equ   RA5 ; Pin 4  PORTA,5
CommunicationPIN equ   RA4 ; Pin 6  PORTA,4	
LiftPin		 equ   RC5 ; Pin 16 PORTC,5
GinValve	 equ   RB0 ; Pin 21
RomValve	 equ   RB1 ; Pin 22
VodkaValve	 equ   RB2 ; Pin 23
MangoValve	 equ   RB3 ; Pin 24
RåstofValve	 equ   RB4 ; Pin 25
AppelsinValve	 equ   RB5 ; Pin 26
LemonValve	 equ   RB6 ; Pin 27
ColaValve	 equ   RB7 ; Pin 28
	 
	 
;****************  Bank macro  ********************
bank1 macro
    bsf STATUS, RP0
    endm
bank0 macro
    bcf STATUS, RP0
    endm

    org 0x00
    goto init

;Initialisering
init 
    bank1
    movlw B'00000000'
    movwf TRISC          ; Set all PORTC pins as output for lift
    movlw B'00000000'
    movwf TRISB          ; Set all PORTB pins as output for magnetic valves
    movlw B'000001'      ; Set RA0 as output for stepper motor activation and RA1 as output for direction
    movwf TRISA
    movlw B'10001111'    ; Set RA1 and 4 to digital and leave RA0 as analog. set RA3 and RA2 to refrence voltage. Set ADFM to 1 for Right justified.
    movwf ADCON1
    bank0
    clrf PORTB           ; Clear PortB
    clrf PORTA           ; Clear PortA
    clrf PORTC
    
;Main loop
	
	
; Main loop
Main:
    ; Read arduino value
    bcf PORTC, 2
    call ReadAnalogValue
    movf    AnalogValue, W    ; Move the analog value to W register
    sublw   D'3'             ; Subtract 3 from the analog value
    btfsc   STATUS, C         ; Check if result wraped around adn activated the C flag.
    goto Main
    bsf PORTC, 2
    call determineDrink	; Determine selected drink
    
      


; Subroutine to read potentiometer value
ReadAnalogValue:
    movlw B'00000101'   ; Select channel AN0 and enable ADC and Start conversion
    movwf ADCON0
    
WaitADConversion:
    btfsc ADCON0, GO    ; Wait for conversion to finish
    goto WaitADConversion
    
    bank1
    movf ADRESL, W      ; Read result
    bank0
    movwf AnalogValue
    
    
    return

; Subroutine to determine selected drink
determineDrink:
    movf    AnalogValue, W    ; Move the analog value to W register
    sublw   D'32'             ; Subtract 32 from the analog value
    btfsc   STATUS, C         ; Check if result wraped around adn activated the C flag.
    goto    GinHass           ; If within threshold, call GinHass

    ; Compare with threshold for GinLemon
    movf    AnalogValue, W    ; Move the analog value to W register again
    sublw   D'64'             ; Subtract 64 from the analog value
    btfsc   STATUS, C         ; Check if result wraped around adn activated the C flag.
    goto    GinLemon          ; If within threshold, call GinLemon
    
    ; Do the same for the rest
    movf    AnalogValue, W    
    sublw   D'96'             
    btfsc   STATUS, C         
    goto    RomOgCola         
    
    movf    AnalogValue, W    
    sublw   D'128'            
    btfsc   STATUS, C         
    goto    VodkaLemon        
    
    movf    AnalogValue, W
    sublw   D'128'
    btfsc   STATUS, C
    goto    VodkaLemon        

    movf    AnalogValue, W
    sublw   D'160'
    btfsc   STATUS, C
    goto    VodkaJuice

    movf    AnalogValue, W
    sublw   D'192'
    btfsc   STATUS, C
    goto    VodkaCola

    movf    AnalogValue, W
    sublw   D'224'
    btfsc   STATUS, C
    goto    Astronaut

    movf    AnalogValue, W
    sublw   D'255'
    btfsc   STATUS, C
    goto    LongIsland


; Function to move the stepper one bottle position to the left
MoveOneBottleLeft:
    ; Set direction to left
    bcf   PORTA, directionPin
    ; Activate the motor
    bsf   PORTA, activationPin
    ; Wait for the motor to move one position
    call  MovementDelay
    ; Deactivate the motor
    bcf   PORTA, activationPin
    return

; Function to move the stepper one bottle position to the right
MoveOneBottleRight:
    ; Set direction to right
    bsf   PORTA, directionPin
    ; Activate the motor
    bsf   PORTA, activationPin
    ; Wait for the motor to move one position
    call  MovementDelay
    ; Deactivate the motor
    bcf   PORTA, activationPin
    bcf   PORTA, directionPin
    return
;**************************Drinks functions***********************************
; Konfigurer dem så de kalder de rigtige funktioner i række følge.
GinHass:
    bsf PORTC, LiftPin	    ;Activates the lift
    ;Since Gin is the start bottle no need to turn just open valve
    bsf PORTB, GinValve	    ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, GinValve	    ;Close valve
    ;Go to Mango by turning 3 times and open valve
    call MoveOneBottleLeft
    call MoveOneBottleLeft
    call MoveOneBottleLeft
    bsf PORTB, MangoValve   ;Open valve
    call Delay_1s	    ;Dispense Mango for 1 sec NÅR VI FINDER UD AF HVOR LANG TID HVER SKAL VÆRE ÅBEN KAN VI KØRER DEM SYNKRONT OG SLUKKE FOR DEM INDIVIDUELT
    bcf PORTB, MangoValve   ;Close valve
    ;Open Lemon valve on the side.
    bsf PORTB, LemonValve   ;Open valve
    call Delay_1s	    ;Dispense Lemon for 1 sec
    bcf PORTB, LemonValve   ;Close valve
    ;Go to start
    movlw D'3'
    movwf goToStart	    ;Set goToStart to 3 meaing it needs to turn 3 times to the right to return to start (Gin bottle)
    call MoveOneBottleRight
    decfsz  goToStart, 1    ;Minus 1 from the goToStart variable and go 2 lines back if zero skip 
    goto    $-2 
    ; Go back to main loop and listen for new drink
    bcf PORTC, LiftPin	    ;Deactivates the lift
    goto Main

GinLemon:
    bsf PORTC, LiftPin	    ;Activates the lift
    ;Since Gin is the start bottle no need to turn just open valve
    bsf PORTB, GinValve	    ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, GinValve	    ;Close valve
    ;Open Lemon valve on the side.
    bsf PORTB, LemonValve   ;Open valve
    call Delay_1s	    ;Dispense Lemon for 1 sec
    bcf PORTB, LemonValve   ;Close valve
    ; Go back to main loop and listen for new drink
    bcf PORTC, LiftPin	    ;Deactivates the lift
    goto Main
    
RomOgCola:
    bsf PORTC, LiftPin	    ;Activates the lift
    ;Go to Rom reletive to the Gin bottel meaning one turn to the left and open valve
    call MoveOneBottleLeft
    bsf PORTB, RomValve	    ;Open valve
    call Delay_1s	    ;Dispense Rom for 1 sec
    bcf PORTB, RomValve	    ;Close valve
    ;Open cola valve on the side.
    bsf PORTB, ColaValve    ;Open valve
    call Delay_1s	    ;Dispense Cola for 1 sec
    bcf PORTB, ColaValve    ;Close valve
    ;Go to start
    movlw D'2'	
    movwf goToStart	    ;Set goToStart to 1 meaing it needs to turn 1 times to the right to return to start
    call MoveOneBottleRight
    decfsz  goToStart, 1    ;Minus 1 from the goToStart variable and go 2 lines back if zero skip 
    goto    $-2 
    ; Go back to main loop and listen for new drink
    bcf PORTC, LiftPin	    ;Deactivates the lift
    goto Main

VodkaLemon:
    bsf PORTC, LiftPin	    ;Activates the lift
    ;Go to Vodka reletive to the Gin bottel meaning two turn to the left and open valve
    call MoveOneBottleLeft
    call MoveOneBottleLeft
    bsf PORTB, VodkaValve   ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, VodkaValve   ;Close valve
    ;Open Lemon valve on the side.
    bsf PORTB, LemonValve   ;Open valve
    call Delay_1s	    ;Dispense Lemon for 1 sec
    bcf PORTB, LemonValve   ;Close valve
    ;Go to start
    movlw D'3'
    movwf goToStart	    ;Set goToStart to 2 meaing it needs to turn 2 times to the right to return to start
    call MoveOneBottleRight
    decfsz  goToStart, 1    ;Minus 1 from the goToStart variable and go 2 lines back if zero skip 
    goto    $-2 
    ; Go back to main loop and listen for new drink
    bcf PORTC, LiftPin	    ;Deactivates the lift
    goto Main

VodkaJuice:
    bsf PORTC, LiftPin	    ;Activates the lift
    ;Go to Vodka reletive to the Gin bottel meaning two turn to the left and open valve
    call MoveOneBottleLeft
    call MoveOneBottleLeft
    bsf PORTB, VodkaValve   ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, VodkaValve   ;Close valve
    ;Open Appeljuice valve on the side.
    bsf PORTB, AppelsinValve   ;Open valve
    call Delay_1s	    ;Dispense Lemon for 1 sec
    bcf PORTB, AppelsinValve   ;Close valve
    ;Go to start
    movlw D'3'
    movwf goToStart	    ;Set goToStart to 2 meaing it needs to turn 2 times to the right to return to start
    call MoveOneBottleRight
    decfsz  goToStart, 1    ;Minus 1 from the goToStart variable and go 2 lines back if zero skip 
    goto    $-2 
    ; Go back to main loop and listen for new drink
    bcf PORTC, LiftPin	    ;Deactivates the lift
    goto Main
   

VodkaCola:
    bsf PORTC, LiftPin	    ;Activates the lift
    ;Go to Vodka reletive to the Gin bottel meaning two turn to the left and open valve
    call MoveOneBottleLeft
    call MoveOneBottleLeft
    bsf PORTB, VodkaValve   ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, VodkaValve   ;Close valve
    ;Open Lemon valve on the side.
    bsf PORTB, ColaValve   ;Open valve
    call Delay_1s	    ;Dispense Lemon for 1 sec
    bcf PORTB, ColaValve   ;Close valve
    ;Go to start
    movlw D'2'
    movwf goToStart	    ;Set goToStart to 2 meaing it needs to turn 2 times to the right to return to start
    call MoveOneBottleRight
    decfsz  goToStart, 1    ;Minus 1 from the goToStart variable and go 2 lines back if zero skip 
    goto    $-2 
    ; Go back to main loop and listen for new drink
    bcf PORTC, LiftPin	    ;Deactivates the lift
    goto Main

Astronaut:
    bsf PORTC, LiftPin	    ;Activates the lift
    ;Go to Råstoff reletive to the Gin bottel meaning four turn to the left and open valve
    call MoveOneBottleLeft
    call MoveOneBottleLeft
    call MoveOneBottleLeft
    call MoveOneBottleLeft
    bsf PORTB, RåstofValve  ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, RåstofValve  ;Close valve
    ;Open Lemon valve on the side.
    bsf PORTB, LemonValve   ;Open valve
    call Delay_1s	    ;Dispense Lemon for 1 sec
    bcf PORTB, LemonValve   ;Close valve
    ;Go to start
    movlw D'4'
    movwf goToStart	    ;Set goToStart to 4 meaing it needs to turn 4 times to the right to return to start
    call MoveOneBottleRight
    decfsz  goToStart, 1    ;Minus 1 from the goToStart variable and go 2 lines back if zero skip 
    goto    $-2 
    ; Go back to main loop and listen for new drink
    bcf PORTC, LiftPin	    ;Deactivates the lift
    goto Main

;The LongIsland as the group calls it is all the alcohol combined 
LongIsland:
    bsf PORTC, LiftPin	    ;Activates the lift
    ;Open for gin
    bsf PORTB, GinValve	    ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, GinValve	    ;Close valve
    ;Go to the next flask and open valve
    call MoveOneBottleLeft
    bsf PORTB, RomValve  ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, RomValve  ;Close valve
    ;Go to the next flask and open valve
    call MoveOneBottleLeft
    bsf PORTB, VodkaValve  ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, VodkaValve  ;Close valve
    ;Skip mangosirup and go to the next flask and open valve
    call MoveOneBottleLeft
    call MoveOneBottleLeft
    bsf PORTB, RåstofValve  ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, RåstofValve  ;Close valve
    ;Open Cola valve on the side.
    bsf PORTB, ColaValve   ;Open valve
    call Delay_1s	    ;Dispense Lemon for 1 sec
    bcf PORTB, ColaValve   ;Close valve
    ;Go to start
    movlw D'4'
    movwf goToStart	    ;Set goToStart to 4 meaing it needs to turn 4 times to the right to return to start
    call MoveOneBottleRight
    decfsz  goToStart, 1    ;Minus 1 from the goToStart variable and go 2 lines back if zero skip 
    goto    $-2 
    ; Go back to main loop and listen for new drink
    bcf PORTC, LiftPin	    ;Deactivates the lift
    goto Main

; Delay function
MovementDelay:
	goto Delay_1s		; Waits 1 secound can be cahnged to waht ever by goto more Delay funktions.
	return
;*************************Delay functions**************************************
; Delay function for 10 ms
Delay_10ms:
	movlw   D'13'           ; Approximately 13 iterations for 10 ms delay
	movwf   d1              ; Move W to d1
Delay_0:
	movlw   D'255'          ; Each iteration of the inner loop takes approximately 3 µs
	movwf   d2              ; Move W to d2
Delay_1:
	nop
	decfsz  d2, 1           ; Decrement d2. Skip next instruction if zero
	goto    $-2             ; Go to next instruction
	decfsz  d1, 1           ; Decrement d1. Skip next instruction if zero
	goto    Delay_0         ; Repeat outer loop
	return                  ; Return from subroutine

; Delay function for 100 ms
Delay_100ms:
	movlw   D'10'           ; Approximately 10 iterations for 100 ms delay
	movwf   d3              ; Move W to d1
Delay_2:
	call    Delay_10ms      ; Call the 10 ms delay function
	decfsz  d3, 1           ; Decrement d3. Skip next instruction if zero
	goto    Delay_2         ; Repeat outer loop
	return                  ; Return from subroutine

; Delay function for 1 second
Delay_1s:
	movlw   D'10'           ; 10 iterations for 1 second delay
	movwf   d4              ; Move W to d1
Delay_3:
	call    Delay_100ms     ; Call the 100 ms delay function
	decfsz  d4, 1           ; Decrement d4. Skip next instruction if zero
	goto    Delay_3         ; Repeat outer loop
	return                  ; Return from subroutine

	end


