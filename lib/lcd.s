; === lcd.s aggiornato: compatibile con LED su PORTA ===

MESSAGE_PTR = $00

; VIA/LCD pins (bit alti)
E  = %10000000  ; Enable pin
RW = %01000000  ; Read/Write
RS = %00100000  ; Register Select

; === TMP VARIABILE INTERNA ===
tmp_porta: .byte 0

; === Init ===
lcd_init: 
  jsr via_init

  lda #%00111000    ; Function set: 8-bit, 2-line, 5x8
  jsr lcd_send_instruction
  lda #%00001100    ; Display ON, cursor OFF, blink OFF
  jsr lcd_send_instruction
  lda #%00000110    ; Entry mode set: Increment, no shift
  jsr lcd_send_instruction
  lda #%00000001    ; Clear display
  jsr lcd_send_instruction
  rts

via_init:
  lda #%11111111
  sta DDRB
  lda #%11100000    ; Only top 3 bits output (keep lower for LED)
  sta DDRA
  rts

; === Routine helper per scrittura sicura su PORTA ===
; A contiene i nuovi valori dei bit 5-7, preserva 0-4
safe_set_lcd_ctrl:
  pha
  lda PORTA
  and #%00011111        ; preserva i bit 0–4 (es. LED)
  sta tmp_porta
  pla
  ora tmp_porta
  sta PORTA
  rts

; === Busy Wait ===
lcd_wait_until_free:
  pha
  lda #%00000000
  sta DDRB

lcd_busy:
  lda #RW
  jsr safe_set_lcd_ctrl

  lda #(RW | E)
  jsr safe_set_lcd_ctrl

  lda PORTB
  and #%10000000
  bne lcd_busy

  lda #RW
  jsr safe_set_lcd_ctrl

  lda #%11111111
  sta DDRB
  pla
  rts

; === Istruzione LCD ===
lcd_send_instruction:
  jsr lcd_wait_until_free
  sta PORTB

  lda #0
  jsr safe_set_lcd_ctrl

  lda #E
  jsr safe_set_lcd_ctrl

  lda #0
  jsr safe_set_lcd_ctrl
  rts

; === Scrivi un carattere ===
lcd_print_char:
  jsr lcd_wait_until_free
  sta PORTB

  lda #RS
  jsr safe_set_lcd_ctrl

  lda #(RS | E)
  jsr safe_set_lcd_ctrl

  lda #RS
  jsr safe_set_lcd_ctrl
  rts