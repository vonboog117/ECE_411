.align 4
.section .text
.globl _start
_start:
    nop
    nop
    nop
    add x8, x3, x4
    nop
    nop
    nop
    # pcrel_NEGTWO: auipc x10, %pcrel_hi(GOOD)
    # lw x4, %pcrel_lo(pcrel_NEGTWO)(x10)
    # addi x4, x4, 4
    lw x4, GOOD
    addi x5, x4, 1
    nop
    nop
    add x8, x3, x4
    nop
    nop

    # Forwarding
    andi x10, x10, 0
    addi x10, x10, 1    # x10 should have 1
    add x11, x10, x10   # x11 should have 2
    add x12, x11, x10   # x12 should have 3
    add x13, x12, x10   # x13 should have 4
    add x14, x13, x10   # x14 should have 5
    addi x0, x0, 1
    add x15, x15, x0    # x15 should have 0

    # Branch Prediction
    addi x20, x20, 1
    beq x0, x0, halt    # Only x20 should have 1
    addi x21, x21, 1
    addi x22, x22, 1
    addi x23, x23, 1
    addi x24, x24, 1

halt:
    beq x0, x0, halt


.section .rodata
.balign 256
GOOD:   .word 0x600D600D
BADD:   .word 0xBADDBADD
