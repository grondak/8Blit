                processor 6502		; -----------------------------------------------------
                                    ; S02E01 Ex4. Table of Pointers
                include	 "vcs.h"	;
                include  "macro.h"	; Instead of calulating the pointers during runtime, we  
                                    ; create a small data table to hold the pointers and then
                                    ; select which pointer index we want for the graphic.
                                    ; 
                                    ;
                                    ; Subscribe to 8Blit to join in.
                                    ; https://www.youtube.com/8blit
                                    ;
                                    ; Visit our website
                                    ; https://www.8blit.com

                                    ; NTSC 262 scanlines 60 Hz, PAL 312 scanlines 50Hz
PF_H            equ #192            ; playfield height
OS_H            equ #30             ; overscan height
VB_H            equ #34             ; vertical blank height - VERTICAL_SYNC macro takes 3

GHOST_H         equ #9              ; ghost sprite height
GHOST_F         equ #2              ; Number of frames in the ghost animation


                seg.u	vars		; uninitialized segment
                org	$80             ; origin set at base of ram

p0_y			ds 1	 	        ; 1 byte - player 0 y pos
tp0_y           ds 1                ; 1 byte - temporary player 0 y pos
scanline        ds 1                ; 1 byte - current scanline

ghost_frame     ds 1                ; current frame of ghost animation
ghostPtr        ds 2    

                seg	main    		; start of main segment
                org $F000


reset:			CLEAN_START			; ouput: all ram registers 0

                lda	#$98	         
                sta	COLUBK			; set the PF color

                lda #$1E
                sta COLUP0          ; set the P1 color

                lda #165		    
                sta p0_y			; initial y pos of p0

                lda #80             ; a = hpos
                ldx #0			    ; P0
                jsr pos_x			; set the initial course position of the player 0 graphic


nextframe:		VERTICAL_SYNC	    ; output: a = 0

                ldx	#VB_H 			; (2)
vblank: 		sta	WSYNC			; (3) 
                dex					; (2) decrement x by 1
                bne	vblank 		    ; (2/3) branch if not equal 

                ; create a pointer to the ghost graphic instead of pointing directy to it
                inc ghost_frame     ; (5)
                lda ghost_frame     ; (2)
                and #15             ; (2)
                sta ghost_frame     ; (3)
                lsr                 ; (2)
                lsr                 ; (2)
                lsr                 ; (2) 

                tax                 ; (2)
                lda ghost_pLSB,x    ; (5)
                sta ghostPtr        ; (3)
                lda ghost_pMSB,x    ; (5)
                sta ghostPtr+1      ; (3)

ghost.done:     lda p0_y            ; (2)
                sta tp0_y           ; (3)

                lda #PF_H		    ; (2)
                sta scanline        ; (3)

                lda #$0	            ; (2) set D1 to 0 to end VBLANK
                sta	WSYNC		    ; (3)
                sta VBLANK		    ; (3) turn on the beam

kernel:		    lda #GHOST_H        ; (2) load height of sprite
                sec                 ; (2) set carry flag
                isb tp0_y           ; (5) increase tp0_y subtract from accumulator
                bcs draw_p0         ; (2/3)
                lda #0              ; (2)

draw_p0:        tay                 ; (2)

                lda (ghostPtr),y    ; (5) Indirect mode, pull graphic from pointer
                
                sta WSYNC           ; (3) 
                sta GRP0            ; (3)
        
                dec	scanline        ; (5)
                bne kernel		    ; (2/3)

                sta WSYNC           ; (3)

                lda #$2     	    ; set D1 = 1 to initiate VBLANK
                sta VBLANK		    ; turn off the beam
                ldx #OS_H	        ; (2)
overscan:       sta WSYNC		    ; (3)
                dex				    ; (2)
                bne overscan	    ; (2/3)

                jmp nextframe       ; (3) jump back up to start the next frame

; -- set horizontal position (a = X position, x = 0-1 player, 2-3 missiles, 4 ball)
pos_x           sta WSYNC	        ; (3) start a new line
	            sec		            ; (2) set carry flag
px.loop         sbc #15		        ; (2) subtract 15
	            bcs px.loop	        ; (2/3) branch until negative
	            eor #7		        ; (2) calculate fine offset
	            asl                 ; (2)
	            asl                 ; (2)
	            asl                 ; (2)
	            asl                 ; (2)
	            sta RESP0,x	        ; (3) fix coarse position
	            sta HMP0,x	        ; (3) set fine offset
	            rts		            ; (6) return to caller

ghost_pLSB:     .byte <ghost_f0     ; LSB
                .byte <ghost_f1

ghost_pMSB:     .byte >ghost_f0     ; MSB
                .byte >ghost_f1

ghost_f0:       .byte $0
	            .byte %01010101 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %10010011 
	            .byte %11011011 
	            .byte %10010011 
	            .byte %01111110 
	            .byte %00111100 

ghost_f1:       .byte $0
	            .byte %10101010 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %11111111 
	            .byte %10010011 
	            .byte %11011011 
	            .byte %10010011 
	            .byte %01111110 
	            .byte %00111100             

                org 	$FFFA

                .word reset     	; NMI  ($FFFA)
                .word reset     	; RESET ($FFFC)
                .word reset     	; IRQ ($FFFE)


