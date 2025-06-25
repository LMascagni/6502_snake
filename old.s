  .org $8000

; === STRINGHE ===
schermo: .asciiz "SNAKE     PUNTI:                        v 1.1"
test: .asciiz "TESTO DI PROVA"

; === VARIABILI ===
points = $0400

tmp_char_row = $0401

; coordinate della griglia
display_row = $0402
display_col = $0403
char_row = $0404
char_col = $0405

char_pos = $0406

bitmap_bit_table:
  .byte %00010000, %00001000, %00000100, %00000010, %00000001



; === SETUP ===
setup:
  jsr lcd_init
  jsr define_custom_chars

  jsr clear_grid

  lda #0
  sta row
  sta col
  lda #1
  sta val
  jsr write_grid_cell
  
  inc col
  inc row
  jsr write_grid_cell

  inc col
  inc col
   jsr write_grid_cell


  ; Spegni LED (bit 0 di PORTA)
  lda PORTA
  and #%11111110
  sta PORTA

  ;imposta punteggio di test
  lda #170
  sta points

  jmp loop

loop:

  jsr render_grid

  jsr print_screen

  inc points
  
  ;se il punteggio è maggiore di 183 resettalo
  lda points
  cmp #183
  bcc no_reset
  lda #0
  sta points
no_reset:

  ; delay 1 secondo
  lda #$E8
  sta time_delay_millis
  lda #$03
  sta time_delay_millis + 1
  jsr delay_millis

  jmp loop

; === ROUTINE: PRINT SCREEN ===
print_screen:
  jsr print_text
  jsr print_grid_border
  jsr print_grid
  jsr print_points
  rts

; === ROUTINE: DEFINISCI CARATTERI CUSTOM ===
define_custom_chars:
  ; Carattere 0
  lda #$40
  jsr lcd_send_instruction
  ldx #0
load_char_0:
  lda #%00000001
  jsr lcd_print_char
  inx
  cpx #8
  bne load_char_0

  ; Carattere 1
  lda #$40 + 8
  jsr lcd_send_instruction
  ldx #0
load_char_1:
  lda #%00010000
  jsr lcd_print_char
  inx
  cpx #8
  bne load_char_1

; Carattere 3 (placeholder)
  lda #$40 + 24
  jsr lcd_send_instruction
  ldx #0
load_char_2:
  lda #%00010101
  jsr lcd_print_char
  lda #%00001010
  jsr lcd_print_char
  inx
  inx
  cpx #8
  bne load_char_2

  rts

; === ROUTINE: RENDER GRID ===
render_grid:
; Inizializza le coordinate della griglia
  lda #0
  sta display_row
  sta display_col
  sta char_row
  sta char_col

render_grid_loop:
  ;calcola l'indirizzo in base a display_row e display_col ((display_row * 2 + display_col) * 8) + $4F
  


;char 2
  lda #$40 + 16
  jsr lcd_send_instruction
  
render_char_2:
  ;calolo posizione relativa per grid
  ;row
  lda display_row
  sta tmp_mult
  lda #8
  sta tmp_offset
  jsr multiply
  lda res_lsb
  clc
  adc char_row
  sta row

  ;col
  lda display_col
  sta tmp_mult
  lda #5
  sta tmp_offset
  jsr multiply
  lda res_lsb
  clc
  adc char_col
  sta col

  ;leggi il valore dalla griglia
  jsr read_grid_cell

  ;se il valore è zero, skippa il pixel
  lda val
  beq skip_pixel
  ;altrimenti imposta il pixel a 1

  lda tmp_char_row
  ldx char_col
  ora bitmap_bit_table, x
  sta tmp_char_row

skip_pixel:
  ;incrementa la colonna
  inc char_col
  ;se la colonna è maggiore di 4, resetta e incrementa la riga e scrivi nell lcd tmp_char_row
  ;se la riga è maggiore di 7, termina, altrimenti torna a render_char_2
  lda char_col
  cmp #5
  bne render_char_2

  ;se la colonna è maggiore di 4, manda il la riga del carattere all'lcd
  lda tmp_char_row
  jsr lcd_print_char
  lda #0
  sta tmp_char_row


  lda #0
  sta char_col
  inc char_row
  lda char_row
  cmp #8
  bne render_char_2
  ;se la riga è maggiore di 7, termina
  rts


; === ROUTINE: TESTO SCHERMO ===
print_text:
  lda #$80
  jsr lcd_send_instruction

  ldx #0
print_loop:
  lda schermo,x
  beq end_print
  jsr lcd_print_char
  inx
  jmp print_loop
end_print:
  rts

; === ROUTINE: DISEGNA BOX USANDO I CARATTERI DEFINITI ===
print_grid_border:
  ; Posiziona cursore a riga 1, colonna 5
  lda #$80 + $05
  jsr lcd_send_instruction
  lda #0              ; stampa carattere custom #0
  jsr lcd_print_char

  ; Posiziona cursore a riga 1, colonna 5
  lda #$C0 + $05
  jsr lcd_send_instruction
  lda #0              ; stampa carattere custom #0
  jsr lcd_print_char

  ; Posiziona cursore a riga 1, colonna 9
  lda #$80 + $09
  jsr lcd_send_instruction
  lda #1              ; stampa carattere custom #1
  jsr lcd_print_char

  ; Posiziona cursore a riga 2, colonna 9
  lda #$C0 + $09
  jsr lcd_send_instruction
  lda #1              ; stampa carattere custom #1
  jsr lcd_print_char

  rts

print_points:
  lda #$CB         ; Posiziona cursore a riga 1, colonna 14
  jsr lcd_send_instruction

  lda points       ; A = punti
  sta tmp_offset   ; Usa tmp_offset come buffer temporaneo

  ; Calcola centinaia
  lda tmp_offset
  ldx #0
cent_loop:
  cmp #100
  blt fine_cent
  sec
  sbc #100
  inx
  jmp cent_loop
fine_cent:
  sta tmp_offset   ; resto
  txa              ; centinaia
  clc
  adc #$30         ; ASCII
  jsr lcd_print_char

  ; Calcola decine
  lda tmp_offset
  ldx #0
dec_loop:
  cmp #10
  blt fine_dec
  sec
  sbc #10
  inx
  jmp dec_loop
fine_dec:
  sta tmp_offset   ; resto
  txa              ; decine
  clc
  adc #$30
  jsr lcd_print_char

  ; Calcola unità
  lda tmp_offset   ; unità
  clc
  adc #$30
  jsr lcd_print_char

  rts

print_grid:
  lda #$80 + $06
  jsr lcd_send_instruction
  lda #2
  jsr lcd_print_char

  lda #$80 + $07
  jsr lcd_send_instruction
  lda #3
  jsr lcd_print_char

  lda #$80 + $08
  jsr lcd_send_instruction
  lda #3
  jsr lcd_print_char

  lda #$C0 + $06
  jsr lcd_send_instruction
  lda #3
  jsr lcd_print_char

  lda #$C0 + $07
  jsr lcd_send_instruction
  lda #3
  jsr lcd_print_char

  lda #$C0 + $08
  jsr lcd_send_instruction
  lda #3
  jsr lcd_print_char

  rts



; === INTERRUPT VECTORS ===
nmi:
irq:
  rti

  .include "lib/io.s"
  .include "lib/lcd.s"
  .include "lib/time.s"
  .include "lib/grid.s"

  .org $FFFA
  .word nmi
  .word setup
  .word irq
