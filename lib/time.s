time_delay_millis = $02
time_delay_micros = $04

delay_millis:
  ;1ms delay
  lda #$E8
  sta T1CL
  lda #$03
  sta T1CH
delay_millis_1:
  ;controllo del contatore del timer
  bit IFR
  bvc delay_millis_1
  lda T1CL
  ;decremento di 1 della variabile del tempo
  dec time_delay_millis
  lda time_delay_millis
  bne delay_millis
  dec time_delay_millis + 1
  lda time_delay_millis + 1
  bne delay_millis
exit_delay_millis:
  rts


delay_micros:
  ;1us delay
  lda #$01
  sta T1CL
  lda #$00
  sta T1CH
delay_micros_1:
  ;controllo del contatore del timer
  bit IFR
  bvc delay_micros_1
  lda T1CL
  ;decremento di 1 della variabile del tempo
  dec time_delay_micros
  lda time_delay_micros
  bne delay_micros
  dec time_delay_micros + 1
  lda time_delay_micros + 1
  bne delay_micros
exit_delay_micros:
  rts

