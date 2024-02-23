mp3test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:

    andi x1, x1, 0
    addi x1, x1, 512    # (0x0200 -> tag = 1, index = 0)
    lw x9, good
    sw x9, 0(x1)

    andi x2, x2, 0
    addi x2, x2, 1024   # (0x0400 -> tag = 2, index = 1)
    addi x2, x2, 32
    lw x10, fill0
    sw x10, 0(x2)

    andi x3, x3, 0
    addi x3, x3, 1536   # (0x0600 -> tag = 3, index = 2)
    addi x3, x3, 64
    lw x11, fill1
    sw x11, 0(x3)

    andi x4, x4, 0
    add  x4, x2, x2     # (0x0800 -> tag = 3, index = 3)
    addi x4, x4, 96
    lw x12, fill2
    sw x12, 0(x4)

    andi x5, x5, 0
    add  x5, x2, x3     # (0x0A00 -> tag = 3, index = 4)
    addi x5, x5, 128
    lw x13, fill3
    sw x13, 0(x5)

    andi x6, x6, 0
    add  x6, x3, x3     # (0x0C00 -> tag = 3, index = 5)
    addi x6, x6, 160
    lw x14, fill4
    sw x14, 0(x6)

    andi x7, x7, 0
    add  x7, x3, x4     # (0x0E00 -> tag = 3, index = 6)
    addi x7, x7, 192
    lw x15, fill5
    sw x15, 0(x7)

    andi x8, x8, 0
    add  x8, x4, x4     # (0x01000 -> tag = 3, index = 7) 4096
    addi x8, x8, 224
    lw x16, fill6
    sw x16, 0(x8)

    lw x17, 0(x1)
    lw x18, 0(x2)
    lw x19, 0(x3)
    lw x20, 0(x4)
    lw x21, 0(x5)
    lw x22, 0(x6)
    lw x23, 0(x7)
    lw x24, 0(x8)

    # andi x1, x1, 0
    # addi x1, x1, 4608    # (0x01200 -> tag = 1, index = 0)
    add x1, x8, x1
    lw x9, good
    sw x9, 0(x1)

    # andi x2, x2, 0
    # addi x2, x2, 5120   # (0x01400 -> tag = 2, index = 0)
    add x2, x8, x2
    addi x2, x2, 32
    lw x10, fill0
    sw x10, 0(x2)

    # andi x3, x3, 0
    # addi x3, x3, 5632   # (0x01600 -> tag = 3, index = 0)
    add x3, x8, x3
    addi x3, x3, 64
    lw x11, fill1
    sw x11, 0(x3)

    # andi x4, x4, 0
    # addi x4, x4, 6144   # (0x01800 -> tag = 3, index = 0)
    add x4, x8, x4
    addi x4, x4, 96
    lw x12, fill2
    sw x12, 0(x4)

    # andi x5, x5, 0
    # addi x5, x5, 6656   # (0x01A00 -> tag = 3, index = 0)
    add x5, x8, x5
    addi x5, x5, 128
    lw x13, fill3
    sw x13, 0(x5)

    # andi x6, x6, 0
    # addi x6, x6, 7168   # (0x01C00 -> tag = 3, index = 0)
    add x6, x8, x6
    addi x6, x6, 160
    lw x14, fill4
    sw x14, 0(x6)

    # andi x7, x7, 0
    # addi x7, x7, 7680   # (0x01E00 -> tag = 3, index = 0)
    add x7, x8, x7
    addi x7, x7, 192
    lw x15, fill5
    sw x15, 0(x7)

    # andi x8, x8, 0
    # addi x8, x8, 8192   # (0x020000 -> tag = 3, index = 0)
    add x8, x8, x8
    addi x8, x8, 224
    lw x16, fill6
    sw x16, 0(x8)
    

    lw x17, 0(x1)
    lw x18, 0(x2)
    lw x19, 0(x3)
    lw x20, 0(x4)
    lw x21, 0(x5)
    lw x22, 0(x6)
    lw x23, 0(x7)
    lw x24, 0(x8)



    # la x3, threshold
    # sw x1, 0(x3)
    # andi x2, x2, 0
    # lw x2, threshold

    # lw  x1, bad
    # lb_signed	
    # lb x2, bad
    # lb_signed_non_word_aligned	
    # lb x3, bad + 2
    # lb_unsigned
    # lbu x4, bad	
    # lb_unsigned_non_word_aligned	
    # lbu x5, bad + 2
    # lh_signed	
    # lh x6, bad
    # lh_signed_non_word_aligned	
    # lh x7, bad + 2
    # lh_unsigned
    # lhu x8, bad	
    # lh_unsigned_non_word_aligned
    # lhu x9, bad + 2

    # and x2, x2, 0
    # and x8, x8, 0
    # addi x2, x2, -1
    # lw x2, fill0
    # la x1, bad
    # sw x2, 0(x1)
    # lw x3, 0(x1)
    # sw x8, 0(x1)

    # srli x2,x2, 4
    # sh x2, 0(x1)
    # lw x4, 0(x1)
    # sw x8, 0(x1)
    # sh x2, 2(x1)
    # lw x5, 0(x1)
    # sw x8, 0(x1)

    # srli x2,x2, 2
    # sb x2, 0(x1)
    # lw x6, 0(x1)
    # sw x8, 0(x1)
    # sb x2, 2(x1)
    # lw x7, 0(x1)

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
fill0:      .word 0xedcba987
fill1:      .word 0xbcdef123
fill2:      .word 0x3456789a
fill3:      .word 0xabcdef12
fill4:      .word 0x11111111
fill5:      .word 0x22222222
fill6:      .word 0x33333333
fill7:      .word 0x44444444
extra:      .word 0x98765432