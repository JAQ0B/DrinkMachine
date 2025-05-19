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


receivedData 	equ 20h	;Variable for index lookup table
goToStart	equ 21h ;variable for number of times needed to go to start
d1		equ 22h	;Delay variable
d2		equ 23h	;Delay variable
d3		equ 24h	;Delay variable
d4		equ 25h	;Delay variable


	
;**************** Constants    ********************
activationPin    equ   RA1 ; Pin 3 PORTA,1
directionPin     equ   RA2 ; Pin 4 PORTA,2
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
	movlw B'10000000'
	movwf TRISC          ; Set TRISC 7 til input (receive) og 6 til output (transmit)
	movlw B'00000000'
	movwf TRISB          ; Set all PORTB pins as output for magnetic valves
	movlw B'000000'      ; Set RA0 as output for stepper motor activation and RA1 as output for direction
	movwf TRISA
	movlw B'00001110'    ; Set RA1 to 4 to digital and leave RA0 as analog
	movwf ADCON1
	movlw D'1'          ; Baud rate = 115200bps
	movwf SPBRG
	movlw B'00100100'    ; TXEN=1, BRGH=1 - TX enable, high bitrate
	movwf TXSTA
	bank0
	movlw B'10000000'
	movwf RCSTA          ; SPEN=1 - Enables serial ports
	clrf PORTB           ; Clear PortB
	clrf PORTA           ; Clear PortB


;Main loop
Main
	clrf TXREG              ; Clear confirmation byte sent to Arduino, so it knows the drink is done.
	call receiveData        ; Call receive function to check for incoming data
	call sendConfirmation   ; Send confirmation back to Arduino
	
	; Determine which function to call based on the received data
	movf receivedData, W   ; Move the received data into W register
	addlw -1               ; Subtract 1 from W register (since array index starts from 0)
	btfsc STATUS, Z        ; If Zero flag is set (i.e., receivedData was 1), call GinHass
	call GinHass
	addlw -1               ; Subtract 1 from W register
	btfsc STATUS, Z        ; If Zero flag is set (i.e., receivedData was 2), call GinLemon
	call GinLemon
	addlw -1               ; Subtract 1 from W register
	btfsc STATUS, Z        ; If Zero flag is set (i.e., receivedData was 3), call RomOgCola
	call RomOgCola
	addlw -1               ; Subtract 1 from W register
	btfsc STATUS, Z        ; If Zero flag is set (i.e., receivedData was 4), call VodkaLemon
	call VodkaLemon
	addlw -1               ; Subtract 1 from W register
	btfsc STATUS, Z        ; If Zero flag is set (i.e., receivedData was 5), call VodkaJuice
	call VodkaJuice
	addlw -1               ; Subtract 1 from W register
	btfsc STATUS, Z        ; If Zero flag is set (i.e., receivedData was 6), call VodkaCola
	call VodkaCola
	addlw -1               ; Subtract 1 from W register
	btfsc STATUS, Z        ; If Zero flag is set (i.e., receivedData was 7), call Astronaut
	call Astronaut
	call LongIsland	       ; If not any of the above receivedData was 8, call LongIsland

	goto Main               ; Continue looping

; Function to receive data from Arduino
receiveData:
	btfss PIR1, RCIF        ; Check if data is available in the receive buffer
	goto Main               ; If not, continue looping
	movf RCREG, W           ; Read the received data from the receive buffer
	movwf receivedData      ; Store the received data in a variable
	return

; Function to send confirmation back to Arduino
sendConfirmation:
	movlw 0x01              ; Send a confirmation byte back to Arduino
	movwf TXREG
	return

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
    goto Main

GinLemon:
    ;Since Gin is the start bottle no need to turn just open valve
    bsf PORTB, GinValve	    ;Open valve
    call Delay_1s	    ;Dispense for 1 sec
    bcf PORTB, GinValve	    ;Close valve
    ;Open Lemon valve on the side.
    bsf PORTB, LemonValve   ;Open valve
    call Delay_1s	    ;Dispense Lemon for 1 sec
    bcf PORTB, LemonValve   ;Close valve
    ; Go back to main loop and listen for new drink
    goto Main
    
RomOgCola:
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
    goto Main

VodkaLemon:
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
    movlw D'2'
    movwf goToStart	    ;Set goToStart to 2 meaing it needs to turn 2 times to the right to return to start
    call MoveOneBottleRight
    decfsz  goToStart, 1    ;Minus 1 from the goToStart variable and go 2 lines back if zero skip 
    goto    $-2 
    ; Go back to main loop and listen for new drink
    goto Main

VodkaJuice:
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
    goto Main
   

VodkaCola:
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
    goto Main

Astronaut:
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
    goto Main

;The LongIsland as the group calls it is all the alcohol combined 
LongIsland:
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
    goto Main

; Delay function
MovementDelay:
	goto Delay_1s		; Waits 1 secound can be cahnged to waht ever by goto more Delay funktions.
	return
;*************************Delay functions**************************************
; Delay function for 10 ms
Delay_10ms:
	movlw   D'10'           ; Approximately 10 iterations for 10 ms delay
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
	movwf   d3              ; Move W to d3
Delay_2:
	call    Delay_10ms      ; Call the 10 ms delay function
	decfsz  d3, 1           ; Decrement d3. Skip next instruction if zero
	goto    Delay_2         ; Repeat outer loop
	return                  ; Return from subroutine

; Delay function for 1 second
Delay_1s:
	movlw   D'10'           ; 10 iterations for 1 second delay
	movwf   d4              ; Move W to d4
Delay_3:
	call    Delay_100ms     ; Call the 100 ms delay function
	decfsz  d4, 1           ; Decrement d4. Skip next instruction if zero
	goto    Delay_3         ; Repeat outer loop
	return                  ; Return from subroutine

	end
