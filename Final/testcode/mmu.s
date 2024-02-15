.align 4
.section .text
.globl _start
_start:
HALT:
    beq x0, x0, HALT

.align 12
.word 0x00000001
.word 0x00000001
.word 0x00000001
.word 0x00000001

