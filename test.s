;MESSAGE_PTR = $00

MAINPORTA = $6001
MAINDDRA = $6003



int_flag = $0200 ;1 byte

  .org $8000

reset:
  ;setup dell'interrupt sul pin CB1
  lda #%10010011
  sta IER

  lda #%00000001
  sta $600C

  ;inizializzazione lcd
  jsr lcd_init

  ;setup pin led come output
  lda MAINDDRA
  ora #%00000001
  sta MAINDDRA

  cli ;abilitazione dell'interrupt
  
  lda #<messagetitle
  sta MESSAGE_PTR  
  lda #>messagetitle  
  sta MESSAGE_PTR + 1  
  jsr print_message

loop:
  jmp loop

messagetitle:   .asciiz "  -  INT_01  -                          "
messagebutton1: .asciiz "tasto 1 premuto"
messagebutton2: .asciiz "tasto 2 premuto"
messagebutton3: .asciiz "tasto 3 premuto"


print_message1:
  lda #<messagebutton1
  sta MESSAGE_PTR  
  lda #>messagebutton1  
  sta MESSAGE_PTR + 1  
  jsr print_message
  rts

print_message2:
  lda #<messagebutton2
  sta MESSAGE_PTR  
  lda #>messagebutton2  
  sta MESSAGE_PTR + 1  
  jsr print_message
  rts

print_message3:
  lda #<messagebutton3
  sta MESSAGE_PTR  
  lda #>messagebutton3  
  sta MESSAGE_PTR + 1  
  jsr print_message
  rts

print_message:  
  ldy #0                 ; Character index counter init to zero (Using Y for indirect addressing)  
print_next_char:         ; Print Char  
  lda (MESSAGE_PTR),y    ; Load message byte with y-value offset from target of pointer.  
  beq exit_print_next_char	; If we're done, go to loop  
  jsr lcd_print_char     ; Print the currently-addressed Char  
  iny                    ; Increment character index counter (Y)  
  jmp print_next_char    ; print the next char
exit_print_next_char:
  rts


nmi:
irq:
  lda PORTA
  and #%00011110
  ror
  clc
  adc #%00110000
  jsr lcd_print_char
  rti

  .include "lib/lcd.s"
  .include "lib/io.s"

  .org $fffa
  .word nmi
  .word reset
  .word irq
