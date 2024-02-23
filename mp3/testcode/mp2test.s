mp2test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    andi x1, x1, 0
    andi x2, x2, 0
    andi x3, x3, 0
    addi x1, x1, -1
    addi x2, x2, 1
    la x4, test
    beq x1, x2, pass
    jalr x1, x4, 8
pass:
    addi x3, x3, 1
    beq x0, x0, halt
test:
    addi x3, x3, 1
    ret
    addi x3, x3, -1
    ret

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

deadend:
    lw x8, bad     # X8 <= 0xdeadbeef
deadloop:
    beq x8, x8, deadloop

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d