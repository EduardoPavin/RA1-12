.equ HEX03,   0xFF200020
.equ HEX45,   0xFF200030
.equ LEDR,    0xFF200000
.equ KEY,     0xFF200050
.equ SW,      0xFF200040
.equ DELAY_V, 2000000

.data
stack_base:   .space 4096
resultados:   .space 4096
num_results:  .word  0
const_one_lo: .word  0x00000000
const_one_hi: .word  0x3FF00000
seg7_table:
  .byte 0x3f
  .byte 0x06
  .byte 0x5b
  .byte 0x4f
  .byte 0x66
  .byte 0x6d
  .byte 0x7d
  .byte 0x07
  .byte 0x7f
  .byte 0x6f
mem_RAIO_lo:   .word 0
mem_RAIO_hi:   .word 0
mem_RAIO_init: .word 0
mem_VMAX_lo:   .word 0
mem_VMAX_hi:   .word 0
mem_VMAX_init: .word 0

.text
.global _start

display_result:
  PUSH {R0-R3, R9, R10, LR}
  FMRRD R0, R1, D0
  LDR R2, =0x80000000
  TST R1, R2
  MOV R10, #0
  BEQ disp_pos
  MOV R10, #1
  EOR R1, R1, R2
  FMDRR D0, R0, R1
disp_pos:
  FTOSID S2, D0
  FMRS R0, S2
  LDR R2, =9999
  CMP R0, R2
  MOVGT R0, R2
  CMP R0, #0
  MOVLT R0, #0
  LDR R2, =0x00000000
  LDR R3, =0x40240000
  FMDRR D3, R2, R3
  FMSR S4, R0
  FSITOD D2, S4
  LDR R9, =seg7_table
  FDIVD D4, D2, D3
  FTOSID S6, D4
  FSITOD D4, S6
  FMULD D4, D4, D3
  FSUBD D4, D2, D4
  FTOSID S6, D4
  FMRS R1, S6
  LDRB R1, [R9, R1]
  FDIVD D2, D2, D3
  FTOSID S6, D2
  FSITOD D2, S6
  FDIVD D4, D2, D3
  FTOSID S6, D4
  FSITOD D4, S6
  FMULD D4, D4, D3
  FSUBD D4, D2, D4
  FTOSID S6, D4
  FMRS R2, S6
  LDRB R2, [R9, R2]
  ORR R1, R1, R2, LSL #8
  FDIVD D2, D2, D3
  FTOSID S6, D2
  FSITOD D2, S6
  FDIVD D4, D2, D3
  FTOSID S6, D4
  FSITOD D4, S6
  FMULD D4, D4, D3
  FSUBD D4, D2, D4
  FTOSID S6, D4
  FMRS R2, S6
  LDRB R2, [R9, R2]
  ORR R1, R1, R2, LSL #16
  FDIVD D2, D2, D3
  FTOSID S6, D2
  FSITOD D2, S6
  FDIVD D4, D2, D3
  FTOSID S6, D4
  FSITOD D4, S6
  FMULD D4, D4, D3
  FSUBD D4, D2, D4
  FTOSID S6, D4
  FMRS R2, S6
  LDRB R2, [R9, R2]
  ORR R1, R1, R2, LSL #24
  LDR R9, =HEX03
  STR R1, [R9]
  LDR R9, =HEX45
  CMP R10, #1
  MOVEQ R2, #0x40
  MOVNE R2, #0x00
  STR R2, [R9]
  FTOSID S2, D0
  FMRS R0, S2
  LDR R9, =LEDR
  MOV R2, #0xFF
  ORR R2, R2, #0x300
  AND R0, R0, R2
  STR R0, [R9]
  POP {R0-R3, R9, R10, LR}
  BX LR

delay_sub:
  PUSH {R0, LR}
  LDR R0, =DELAY_V
delay_loop:
  SUBS R0, R0, #1
  BNE delay_loop
  POP {R0, LR}
  BX LR

wait_key:
  PUSH {R1, LR}
  LDR R1, =KEY
wk_press:
  LDR R0, [R1]
  AND R0, R0, #0xF
  CMP R0, #0
  BEQ wk_press
wk_release:
  LDR R1, =KEY
  LDR R1, [R1]
  AND R1, R1, #0xF
  CMP R1, #0
  BNE wk_release
  POP {R1, LR}
  BX LR

pot_int:
  PUSH {R11, LR}
  LDR R0, =const_one_lo
  LDR R1, =const_one_hi
  LDR R0, [R0]
  LDR R1, [R1]
  FMDRR D2, R0, R1
pot_loop:
  CMP R11, #0
  BEQ pot_done
  FMULD D2, D2, D0
  SUB R11, R11, #1
  B pot_loop
pot_done:
  FCPYD D0, D2
  POP {R11, LR}
  BX LR

floor_d0:
  PUSH {LR}
  FTOSID S4, D0
  FSITOD D0, S4
  POP {LR}
  BX LR

_start:
  MRC p15, 0, R0, c1, c0, 2
  ORR R0, R0, #0xF00000
  MCR p15, 0, R0, c1, c0, 2
  MOV R0, #0x40000000
  FMXR FPEXC, R0
  LDR R4, =stack_base
  MOV R5, #0
  LDR R6, =resultados
  MOV R7, #0
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x40000000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40080000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FADDD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40100000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x3ff00000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FSUBD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FMULD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x40590000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40180000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FDIVD D0, D0, D1
  BL floor_d0
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x403d0000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40180000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FCPYD D3, D0
  FDIVD D0, D0, D1
  BL floor_d0
  FMULD D0, D0, D1
  FSUBD D0, D3, D0
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x40000000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40240000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FTOSID S6, D1
  FMRS R11, S6
  BL pot_int
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x51eb851f
  LDR R1, =0x40091eb8
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FMRRD R0, R1, D0
  LDR R2, =mem_RAIO_lo
  STR R0, [R2]
  LDR R2, =mem_RAIO_hi
  STR R1, [R2]
  LDR R2, =mem_RAIO_init
  MOV R3, #1
  STR R3, [R2]
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =mem_RAIO_lo
  LDR R1, =mem_RAIO_hi
  LDR R0, [R0]
  LDR R1, [R1]
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =mem_RAIO_lo
  LDR R1, =mem_RAIO_hi
  LDR R0, [R0]
  LDR R1, [R1]
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FMULD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x51eb851f
  LDR R1, =0x40091eb8
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FMULD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x3ff00000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  FTOSID S8, D1
  FMRS R8, S8
  MOV R9, #6
  SUB R9, R9, R8
  CMP R9, #0
  MOVLT R9, #0
  LSL R9, R9, #3
  ADD R9, R6, R9
  FLDD D0, [R9]
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x40490000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40390000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FSUBD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =mem_RAIO_lo
  LDR R1, =mem_RAIO_hi
  LDR R0, [R0]
  LDR R1, [R1]
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40000000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FTOSID S6, D1
  FMRS R11, S6
  BL pot_int
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x40000000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  FTOSID S8, D1
  FMRS R8, S8
  MOV R9, #9
  SUB R9, R9, R8
  CMP R9, #0
  MOVLT R9, #0
  LSL R9, R9, #3
  ADD R9, R6, R9
  FLDD D0, [R9]
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x40240000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40000000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FDIVD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40080000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40100000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FADDD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FSUBD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x40140000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  FTOSID S8, D1
  FMRS R8, S8
  MOV R9, #11
  SUB R9, R9, R8
  CMP R9, #0
  MOVLT R9, #0
  LSL R9, R9, #3
  ADD R9, R6, R9
  FLDD D0, [R9]
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =0x00000000
  LDR R1, =0x401c0000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FMRRD R0, R1, D0
  LDR R2, =mem_VMAX_lo
  STR R0, [R2]
  LDR R2, =mem_VMAX_hi
  STR R1, [R2]
  LDR R2, =mem_VMAX_init
  MOV R3, #1
  STR R3, [R2]
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =mem_VMAX_lo
  LDR R1, =mem_VMAX_hi
  LDR R0, [R0]
  LDR R1, [R1]
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40080000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FCPYD D3, D0
  FDIVD D0, D0, D1
  BL floor_d0
  FMULD D0, D0, D1
  FSUBD D0, D3, D0
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
  MOV R5, #0
  LDR R0, =mem_VMAX_lo
  LDR R1, =mem_VMAX_hi
  LDR R0, [R0]
  LDR R1, [R1]
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40000000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FMULD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =mem_RAIO_lo
  LDR R1, =mem_RAIO_hi
  LDR R0, [R0]
  LDR R1, [R1]
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  LDR R0, =0x00000000
  LDR R1, =0x40080000
  FMDRR D0, R0, R1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FADDD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D1, [R8]
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  FDIVD D0, D0, D1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FSTD D0, [R8]
  ADD R5, R5, #1
  SUB R5, R5, #1
  LSL R8, R5, #3
  ADD R8, R4, R8
  FLDD D0, [R8]
  LSL R8, R7, #3
  ADD R8, R6, R8
  FSTD D0, [R8]
  ADD R7, R7, #1
  LDR R9, =num_results
  STR R7, [R9]
  BL display_result
  BL delay_sub
  BL wait_key
final_loop:
  LDR R9, =num_results
  LDR R7, [R9]
  MOV R8, #0
show_loop:
  LSL R0, R8, #3
  ADD R0, R6, R0
  FLDD D0, [R0]
  BL display_result
  BL wait_key
  ADD R8, R8, #1
  CMP R8, R7
  BLT show_loop
  B final_loop
END: B END