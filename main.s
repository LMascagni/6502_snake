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

char_pos = $0500

; variabili per snake
direction = $0501   ;0 - no dir, 1 - up, 2 - down, 3 - left, 4 - right
position_x = $0502
position_y = $0503
last_x = $0504
last_y = $0505


bitmap_bit_table:
  .byte %00010000, %00001000, %00000100, %00000010, %00000001



; === SETUP ===
setup:
  ;ldx #$ff
  ;txs
  ;cli

  ;setup dell'interrupt sul pin CB1
  lda #%10010011
  sta IER

  lda #%00000001
  sta PCR

  jsr lcd_init
  jsr define_custom_chars

  jsr clear_grid

  ; Inizializza la posizione del serpente
  lda #7
  sta row
  sta position_y
  lda #7
  sta col
  sta position_x
  lda #1
  sta val
  jsr write_grid_cell

  lda DDRA
  and #%11100001  ; Imposta i bit 5-7 come output, preserva 0-4
  sta DDRA

  ;imposta punteggio di test
  lda #0
  sta points
  sta direction

  jmp loop

loop:
  ; Gestisci la direzione del serpente
  jsr handle_movement

  ; renderizza la griglia
  jsr render_grid
  ; Stampa lo schermo
  ; (testo, bordi, griglia e punteggio)
  jsr print_screen

  ;inc points
  
  ;se il punteggio è maggiore di 183 resettalo
  lda points
  cmp #241
  bcc no_reset
  lda #0
  sta points
no_reset:

  ; delay 256 ms
  ;lda #$00
  ;sta time_delay_millis
  ;lda #$01
  ;sta time_delay_millis + 1
  ;jsr delay_millis

  jmp loop

; === ROUTINE: LEGGI INPUT ===
read_input:
  lda PORTA
  and #%00011110  ; Maschera i bit 1-4

  cmp #%00000010  ; Freccia sinistra
  bne check_down
  lda #3
  sta direction
  rts

check_down:
  cmp #%00000100  ; Freccia giù
  bne check_right
  lda #2
  sta direction
  rts

check_right:
  cmp #%00001000  ; Freccia destra
  bne check_up
  lda #4
  sta direction
  rts

check_up:
  cmp #%00010000  ; Freccia su
  bne no_key
  lda #1
  sta direction
  rts

no_key:
  lda #0
  sta direction
  rts

handle_movement:
  ; Gestisce la direzione del serpente
  lda direction
  bne move
  rts

move:
  ; Salva la posizione precedente
  lda position_x
  sta last_x
  lda position_y
  sta last_y

  ; Aggiorna la posizione in base alla direzione
  lda direction
  cmp #1          ; Su
  beq move_up
  cmp #2          ; Giù
  beq move_down
  cmp #3          ; Sinistra
  beq move_left
  cmp #4          ; Destra
  beq move_right

  rts

move_up:
  lda position_y
  beq no_move_up
  sec
  sbc #1
  sta position_y
no_move_up:
  jmp draw_move

move_down:
  lda position_y   ; carica la Y attuale
  cmp #15
  beq no_move_down
  clc
  adc #1
  sta position_y
no_move_down:
  jmp draw_move

move_left:
  lda position_x
  beq no_move_left
  sec
  sbc #1
  sta position_x
no_move_left:
  jmp draw_move

move_right:
  lda position_x   ; carica la X attuale
  cmp #14
  beq no_move_right
  clc
  adc #1
  sta position_x
no_move_right:
  jmp draw_move


draw_move:
  ;cancellare la cella precedente se last_x e last_y sono diversi da position_x e position_y
  lda last_x
  cmp position_x
  bne skip_check_y
  lda last_y
  cmp position_y
  beq skip_clear_cell
skip_check_y:
  ;cancella la cella precedente
  lda last_y
  sta row
  lda last_x
  sta col
  lda #0
  sta val
  jsr write_grid_cell
  ;disegna la nuova cella
  lda position_y
  sta row
  lda position_x
  sta col
  lda #1
  sta val
  jsr write_grid_cell

skip_clear_cell:
  rts


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
  ;calcola l'indirizzo CGRAM ((display_row * 3 + display_col) * 8) + $50
  lda display_row
  sta tmp_mult
  lda #3
  sta tmp_offset
  jsr multiply
  lda res_lsb
  clc
  adc display_col
  sta tmp_mult
  lda #8
  sta tmp_offset
  jsr multiply
  lda res_lsb
  clc
  adc #$50
  sta char_pos

  ; manda l'indirizzo CGRAM all'lcd
  ;lda #$40 + 16
  lda char_pos
  jsr lcd_send_instruction
  
render_char:
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
  ;se la riga è maggiore di 7 incrementa display_col, altrimenti torna a render_char_2
  lda char_col
  cmp #5
  bne render_char

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
  bne render_char
  lda #0
  sta char_row
  ;se la riga è maggiore di 7, incrementa display_col
  inc display_col
  ;se la colonna è maggiore di 2, incrementa display_row e resetta display_col
  lda display_col
  cmp #3
  beq skip_render_grid_loop
  jmp render_grid_loop
skip_render_grid_loop:
  ; resetta display_col
  lda #0
  sta display_col
  ; incrementa display_row
  inc display_row
  ; se la riga è maggiore di 1, torna a render_grid_loop
  lda display_row
  cmp #2
  beq end_render_grid
  jmp render_grid_loop
end_render_grid:

  ; se la riga è maggiore di 1, termina
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
  lda #4
  jsr lcd_print_char

  lda #$C0 + $06
  jsr lcd_send_instruction
  lda #5
  jsr lcd_print_char

  lda #$C0 + $07
  jsr lcd_send_instruction
  lda #6
  jsr lcd_print_char

  lda #$C0 + $08
  jsr lcd_send_instruction
  lda #7
  jsr lcd_print_char

  rts



; === INTERRUPT VECTORS ===
nmi:
irq:
  inc points

  ; Leggi input da tastiera
  jsr read_input

  rti

  .include "lib/io.s"
  .include "lib/lcd.s"
  .include "lib/time.s"
  .include "lib/grid.s"

  .org $fffA
  .word nmi
  .word setup
  .word irq
