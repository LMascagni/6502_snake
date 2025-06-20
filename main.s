  .org $8000

; === STRINGHE ===
schermo: .asciiz "SNAKE     PUNTI:                        v 1.0"
test: .asciiz "TESTO DI PROVA"

; === VARIABILI ===
points = $02CC

; === CARATTERI CUSTOM (8 byte ciascuno) ===
char_0: ; BOX 1-1
  .byte %11111
  .byte %10000
  .byte %10000
  .byte %10000
  .byte %10000
  .byte %10000
  .byte %10000
  .byte %10000

char_1: ; BOX 1-2
  .byte %11111
  .byte %00000
  .byte %00000
  .byte %00000
  .byte %00000
  .byte %00000
  .byte %00000
  .byte %00000

char_2: ; BOX 1-3
  .byte %11111
  .byte %00001
  .byte %00001
  .byte %00001
  .byte %00001
  .byte %00001
  .byte %00001
  .byte %00001

char_3: ; BOX 2-1
  .byte %10000
  .byte %10000
  .byte %10000
  .byte %10000
  .byte %10000
  .byte %10000
  .byte %10000
  .byte %11111

char_4: ; BOX 2-2
  .byte %00000
  .byte %00000
  .byte %00000
  .byte %00000
  .byte %00000
  .byte %00000
  .byte %00000
  .byte %11111

char_5: ; BOX 2-3
  .byte %00001
  .byte %00001
  .byte %00001
  .byte %00001
  .byte %00001
  .byte %00001
  .byte %00001
  .byte %11111

; === SETUP ===
setup:
  jsr lcd_init
  jsr define_custom_chars

  jsr clear_grid

  ; Spegni LED (bit 0 di PORTA)
  lda PORTA
  and #%11111110
  sta PORTA

  ; === Scrivi nella griglia ===
  lda #3
  sta row
  lda #5
  sta col
  lda #17
  sta val
  jsr write_grid_cell

  ; === Leggi dalla griglia ===
  lda #3
  sta row
  lda #5
  sta col
  jsr read_grid_cell

  sta val         ; memorizza il valore letto

  ;imposta punteggio di test
  lda #170
  sta points

  jmp loop

loop:
  ; accendi LED

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
  lda char_0, x
  jsr lcd_print_char
  inx
  cpx #8
  bne load_char_0

  ; Carattere 1
  lda #$40 + 8
  jsr lcd_send_instruction
  ldx #0
load_char_1:
  lda char_1, x
  jsr lcd_print_char
  inx
  cpx #8
  bne load_char_1

  ; Carattere 2
  lda #$40 + 16
  jsr lcd_send_instruction
  ldx #0
load_char_2:
  lda char_2, x
  jsr lcd_print_char
  inx
  cpx #8
  bne load_char_2

  ; Carattere 3
  lda #$40 + 24
  jsr lcd_send_instruction
  ldx #0
load_char_3:
  lda char_3, x
  jsr lcd_print_char
  inx
  cpx #8
  bne load_char_3

  ; Carattere 4
  lda #$40 + 32
  jsr lcd_send_instruction
  ldx #0
load_char_4:
  lda char_4, x
  jsr lcd_print_char
  inx
  cpx #8
  bne load_char_4
  
  ; Carattere 5
  lda #$40 + 40
  jsr lcd_send_instruction
  ldx #0
load_char_5:
  lda char_5, x
  jsr lcd_print_char
  inx
  cpx #8
  bne load_char_5

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
print_grid:
  ; Posiziona cursore a riga 1, colonna 6
  lda #$80 + $06
  jsr lcd_send_instruction
  lda #0              ; stampa carattere custom #0
  jsr lcd_print_char

  ; Posiziona cursore a riga 1, colonna 7
  lda #$80 + $07
  jsr lcd_send_instruction
  lda #1              ; stampa carattere custom #1
  jsr lcd_print_char

  ; Posiziona cursore a riga 1, colonna 8
  lda #$80 + $08
  jsr lcd_send_instruction
  lda #2              ; stampa carattere custom #2
  jsr lcd_print_char

  ; Posiziona cursore a riga 2, colonna 6
  lda #$C0 + $06
  jsr lcd_send_instruction
  lda #3              ; stampa carattere custom #3
  jsr lcd_print_char

  ; Posiziona cursore a riga 2, colonna 7
  lda #$C0 + $07
  jsr lcd_send_instruction
  lda #4              ; stampa carattere custom #4
  jsr lcd_print_char

  ; Posiziona cursore a riga 2, colonna 8
  lda #$C0 + $08
  jsr lcd_send_instruction
  lda #5              ; stampa carattere custom #5
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
