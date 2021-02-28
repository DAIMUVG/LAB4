;Archivo:	Main_lab_3.s
;dispositivo:	PIC16F887
;Autor:		Dylan Ixcayau
;Compilador:	pic-as (v2.31), MPLABX V5.45
;
;Programa:	Botones y Timer 0
;Hardware:	Botones en el puerto B, LEDs en el puerto A y Display en el puerto C, D
;
;Creado:	22 feb, 2021
;Ultima modificacion:  23 feb, 2021

PROCESSOR 16F887
#include <xc.inc>

; configuración word1
 CONFIG FOSC=INTRC_NOCLKOUT //Oscilador interno sin salidas
 CONFIG WDTE=OFF	    //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON	    //PWRT enabled (espera de 72ms al iniciar
 CONFIG MCLRE=OFF	    //pin MCLR se utiliza como I/O
 CONFIG CP=OFF		    //sin protección de código
 CONFIG CPD=OFF		    //sin protección de datos
 
 CONFIG BOREN=OFF	    //sin reinicio cuando el voltaje baja de 4v
 CONFIG IESO=OFF	    //Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    //Cambio de reloj externo a interno en caso de falla
 CONFIG LVP=ON		    //Programación en bajo voltaje permitida
 
;configuración word2
  CONFIG WRT=OFF	//Protección de autoescritura 
  CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 
    
  PSECT udata_bank0 ;common memory
    cont:	DS  2 ;2 byte apartado
    var:	DS  1
    w_temp:	DS  1;1 byte apartado
    STATUS_TEMP:DS  1;1 byte
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	;posición 000h para el reset
  resetVec:
    PAGESEL main
    goto main
    
  PSECT code, delta=2, abs
ORG 100h	;posicion para el codigo
;------------------ TABLA -----------------------
TABLA_7S:
    clrf    PCLATH
    bsf	    PCLATH, 0
    andlw   0x0F
    addwf   PCL
    retlw   00111111B;0
    retlw   00000110B;1
    retlw   01011011B;2
    retlw   01001111B;3
    retlw   01100110B;4
    retlw   01101101B;5
    retlw   01111101B;6
    retlw   00000111B;7
    retlw   01111111B;8
    retlw   01101111B;9
    retlw   01110111B;A
    retlw   01111100B;b
    retlw   00111001B;c
    retlw   01011110B;d
    retlw   01111001B;E
    retlw   01110001B;F
    
    
;-----------configuracion----------------------------  
main:				    ;Configuración de los puertos
    banksel	ANSEL		    ;Llamo al banco de memoria donde estan los ANSEL
    clrf	ANSEL		    ;Pines digitales
    clrf	ANSELH
    
    banksel	TRISA		    ;Llamo al banco de memoria donde estan los TRISA y WPUB
    movlw	11110000B	    ;Configuro los puertos de salida que usare y los demas los dejo como entradas para no afectar el conteo del led
    movwf	TRISA
    
    movlw	10000000B	    ;Configuro el puerto C, que sera el puerto que llevara mi primer display
    movwf	TRISC
    
    movlw	10000000B	    ;Configuro el puerto C, que sera el puerto que llevara mi segundo display
    movwf	TRISD
    
    bcf		OPTION_REG, 7	    ;Activo la opcion de las resistencias en el PUERTOB 
    bsf		WPUB, 0		    ;Activo las resistencias de los puertos que usare
    bsf		WPUB, 1
    
    bsf		TRISB, 0	    ;Dejo como entradas los puertos que usare para los botones
    bsf		TRISB, 1
    
    banksel	PORTA		    ;Llamo al banco de memoria donde estan los PORT
    clrf	PORTA		    ;Limpio los puertos de salidas digitales
    clrf	PORTC
    clrf	PORTD
    
    call	config_reloj		;Configuracion de reloj para darle un valor al oscilador
    call	config_IO		;Configuracion de las interrupciones del Puerto B
    call	config_timr0		;Configuracion del timer 0
    call	config_IE		;Configuracion de las interrupciones del timer0
    banksel	PORTA
    
Loop:
    movf	var, w			;var es la viriable para meter en la tabla
    call	TABLA_7S		;w se va a la tabla y se convierte en lo que necesitamos para el display
    movwf	PORTD			;w se va a PORTD y muestra los valores correctos en hexadecimal en la tabla
    
    movf	PORTA, w		;Mueve el valor del contador de las LEDs a w
    call	TABLA_7S		;w se va a la tabla y se convierte en lo que necesitamos para el display
    movwf	PORTC			;w se va a PORTC y muestra los valores correctos en hexadecimal en la tabla
    
    
    goto	Loop
    
PSECT intVect, class=CODE, abs, delta=2
  ;----------------------interrupción reset------------------------
  ORG 04h	;posición 0004h para interr
  push:			    
    movf    w_temp	    ;Guardamos w en una variable temporal
    swapf   STATUS, W	    ;Sustraemos el valor de status a w sin tocar las interrupciones
    movwf   STATUS_TEMP	    ;Guardamos el status que acabamos de guardar en una variable temporal
    
  isr:
    btfsc   T0IF	    ;Si el timer0 no levanta ninguna bandera de interrupcion
    call    TMR0_interrupt  ;Rutina de interrupcion del timer0
    
    btfsc   RBIF	    ;Si el puerto B levanta la banderas de interrupcion
    call    IOCB_interrupt  ;Rutina de interrupcion del puerto B
    
  pop:
    swapf   STATUS_TEMP, W  ;Recuperamos el valor del status original
    movwf   STATUS	    ;Regresamos el valor a Status
    swapf   w_temp, F	    ;Guardamos el valor sin tocar las banderas a F
    swapf   w_temp, W	    ;El valor normal lo dejamos en w
    retfie		    ;Salimos de las interrupciones
    
;---------SubrutinasInterrupción-----------
IOCB_interrupt:		    ;Rutina de interrupcion del puerto B	    
    btfss   PORTB, 0	    ;Revisamos el primer boton
    incf    PORTA	    ;incrementamos el puerto A y por ende el display
    btfss   PORTB, 1	    ;Revisamos el segundo boton 
    decf    PORTA	    ;decrementamos el puerto A y por ende el display
    bcf	    RBIF	    ;Bajamos la bandera del puerto B
    return

TMR0_interrupt:		    ;Rutina de interrupcion del timer 0
    call timr0		    ;llamamos a la rutina para asignarle un valor al timer
    
    incf    cont	    ;Incrementamos la variable cont de 1 en 1
    movf    cont, w	    ;Guardamos el valor de la variable en w
    sublw   50		    ;A w le restamos 50
    btfss   STATUS, 2	    ;revisamos si la bandera del status 2 esta apagada
    goto    retrnT0	    ;Repetimos hasta que la resta sea 0 y pueda pasar a la siguiente instruccion
    clrf    cont	    ;limpiamos la variable para poder repetir
    incf    var		    ;Incrementamos la segunda variable que controlara el 2do display

retrnT0:
    return
;---------------subrutinas------------------------------
config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bsf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 4MHz
    return

config_IE:
    bsf	    GIE		;Habilitar en general las interrupciones, Globales
    bsf	    T0IE	;Se encuentran en INTCON
    bcf	    T0IF	;Limpiamos bandera
    return
    
config_IO:  
    bsf	    IOCB, 0
    bsf	    IOCB, 1
    
    banksel PORTA
    movf    PORTB, W	;Condición mismatch
    bcf	    RBIF
    return
    
config_timr0:
    banksel OPTION_REG	    ;Banco de registros asociadas al puerto A
    bcf	    T0CS	    ; reloj interno clock selection
    bcf	    PSA		    ;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0		   ;PS = 111 Tiempo en ejecutar , 256
    
    banksel TMR0
    call    timr0
    return

timr0: 
    movlw   178
    movwf   TMR0
    bcf	    T0IF
    return
    
end