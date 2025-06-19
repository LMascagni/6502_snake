MESSAGE_PTR = $00

;VIA Registers
LCD_PORTB = $6000
LCD_PORTA = $6001
LCD_DDRB = $6002
LCD_DDRA = $6003

; VIA/LCD pins
E  = %10000000  ; Enable pin bitcode 
RW = %01000000  ; Read/Write pin bitcode
RS = %00100000  ; Register Select pin bitcode

lcd_init: 
  jsr via_init

  lda #%00111000    ; Set 8-bit mode, 2-line display, 5x8 font
  jsr lcd_send_instruction
  lda #%00001100    ; Display on, cursor on, blink off
  jsr lcd_send_instruction
  lda #%00000110    ; Increment and shift cursor, don't shift display
  jsr lcd_send_instruction
  lda #$00000001    ; Clear display
  jsr lcd_send_instruction
  rts

via_init:
  lda #%11111111    ; Set all pins on port B to output
  sta LCD_DDRB
  lda #%11100000    ; Set top 3 pins on port A to output
  sta LCD_DDRA
  rts

lcd_wait_until_free:
  pha
  lda #%00000000    ; Port B is input
  sta LCD_DDRB
lcd_busy:
  lda #RW
  sta LCD_PORTA
  lda #(RW | E)
  sta LCD_PORTA
  lda LCD_PORTB
  and #%10000000
  bne lcd_busy
  ; LCD Free
  lda #RW
  sta LCD_PORTA
  lda #%11111111    ; Port B is output
  sta LCD_DDRB
  pla
  rts

lcd_send_instruction:
  jsr lcd_wait_until_free
  sta LCD_PORTB
  lda #0            ; Clear RS/RW/E bits
  sta LCD_PORTA
  lda #E            ; Set E bit to send instruction
  sta LCD_PORTA
  lda #0            ; Clear RS/RW/E bits
  sta LCD_PORTA
  rts

lcd_print_char:
  jsr lcd_wait_until_free
  sta LCD_PORTB
  lda #RS           ; Set RS, Clear RW/E bits
  sta LCD_PORTA
  lda #(RS | E)     ; Set E bit to send instruction
  sta LCD_PORTA
  lda #RS           ; Clear E bits
  sta LCD_PORTA
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
