   .org $8000

setup:
   jsr clear_grid
   
   lda #0
   sta row
   sta col
   lda #64
   sta val
   jsr write_grid_cell

   lda #12
   sta row
   lda #13
   sta col
   lda #2
   sta val
   jsr write_grid_cell

loop:


   jmp loop


; === INTERRUPT VECTORS ===
nmi:
irq:
  rti

  .include "lib/grid.s"

  .org $FFFA
  .word nmi
  .word setup
  .word irq
