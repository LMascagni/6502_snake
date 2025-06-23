; === ARRAY grid 13x14 = 182 BYTE ===
grid       = $0200  ; Array inizia a $0200

; === VARIABILI === (dopo grid)
tmp_offset = $0300
tmp_mult   = $0301
row        = $0302
col        = $0303
val        = $0304
res_lsb    = $0305
res_msb    = $0306


; === ROUTINE: CALCOLA OFFSET PER CELLA (row * 14 + col) ===
; Output: Y = offset
calculate_offset:
  lda row
  sta tmp_mult
  lda #14
  sta tmp_offset

  jsr multiply

  lda res_lsb
  clc
  adc col
  tay
  rts

; === SUBROUTINE: MULTIPLICAZIONE tmp_offset * tmp_mult ===
; OUT: res_lsb = risultato LSB
;      res_msb = risultato MSB
multiply:
  lda #0
  sta res_lsb
  sta res_msb

  ldy tmp_mult
mul_loop:
  beq mul_done

  lda res_lsb
  clc
  adc tmp_offset
  sta res_lsb

  lda res_msb
  adc #0
  sta res_msb

  dey
  jmp mul_loop

mul_done:
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
  ldx #0
  lda #0
clear_loop:
  sta grid, x
  inx
  cpx #182
  bne clear_loop
  rts
