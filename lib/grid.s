; === VARIABILI ===
tmp_offset = $0200
tmp_mult   = $0201
row        = $0202
col        = $0203
val        = $0204

; === ARRAY grid 13x14 = 182 BYTE ===
grid       = $0205  ; Array inizia subito dopo le variabili

; === ROUTINE: CALCOLA OFFSET PER CELLA (row * 14 + col) ===
; Output: Y = offset
calculate_offset:
  lda row
  sta tmp_mult      ; tmp_mult = row

  ; row * 8
  lda tmp_mult
  asl
  asl
  asl
  sta tmp_offset

  ; + row * 4
  lda tmp_mult
  asl
  asl
  clc
  adc tmp_offset
  sta tmp_offset

  ; + row * 2
  lda tmp_mult
  asl
  clc
  adc tmp_offset
  sta tmp_offset  ; tmp_offset = row * 14

  ; + col
  lda col
  clc
  adc tmp_offset
  tay
  rts

; === ROUTINE: SCRIVI NELLA CELLA ===
write_grid_cell:
  jsr calculate_offset
  lda val
  sta grid, y
  rts

; === ROUTINE: LEGGI DALLA CELLA ===
read_grid_cell:
  jsr calculate_offset
  lda grid, y
  rts

; === ROUTINE: SVUOTA L'ARRAY GRID (13x14 = 182 celle) ===
clear_grid:
  ldx #0          ; Inizializza indice X a 0
  lda #0          ; Valore zero da scrivere

clear_loop:
  sta grid, x     ; Scrive 0 nella posizione grid + X
  inx             ; Incrementa X
  cpx #182        ; Abbiamo raggiunto la fine?
  bne clear_loop  ; Se no, continua il ciclo
  rts
