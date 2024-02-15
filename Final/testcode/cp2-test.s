#  mp4-cp2.s version 1.3
.align 4
.section .text
.globl _start
_start:

#   Your pipeline should be able to do hazard detection and forwarding.
#   Note that you should not stall or forward for dependencies on register x0 or when an
#   instruction does not use one of the source registers (such as rs2 for immediate instructions).

# Display that Forwarding works
    andi x1,x1,0 # Should not affect end result
    addi x1,x1,1 # x1 should have 1 at the end
    add x2,x1,x1 # x2 should have 2 at the end
    add x3,x1,x2 # x3 should have 3 at the end
    add x4,x1,x3 # x4 should have 4 at the end
    add x5,x1,x4 # x5 should have 5 at the end
    add x6,x3,x5 # x6 should have 8 at the end

    # andi x1,x1,0
    andi x2,x2,0
    andi x3,x3,0
    andi x4,x4,0
    andi x5,x5,0
    andi x6,x6,0
     # Forwarding x0 test
    add x3, x3, 1
    add x0, x1, 0
    add x2, x0, 0

    beq x2, x3, oof

    # Forwarding sr2 imm test
    add x2, x1, 0
    add x3, x1, 2                      # 2 immediate makes sr2 bits point to x2
    add x4, x0, 3

    bne x3, x4, oof                    # Also, test branching on 2 forwarded values :)

    # MEM -> EX forwarding with stall
    lw x1, NOPE
    lw x1, A
    add x5, x1, x0                     # Necessary forwarding stall
    # ^rs2 (x0) gets vrs2(x1) because I am forwarding ID and EX at the same time
    # Idea: instead of giving forwarded value to registers, give it directly to EX components
    bne x5, x1, oof

    # WB -> MEM forwarding test
    add x3, x1, 1 #2
    la x8, TEST
    sw  x3, 0(x8)
    lw  x4, TEST

    bne x4, x3, oof


    # Half word forwarding test
    lh  x2, FULL
    add x3, x0, -1

    bne x3, x2, oof

    # Cache miss control test
    add x4, x0, 3
    lw  x2, B                          # Cache miss
    add x3, x2, 1                      # Try to forward from cache miss load

    bne x4, x3, oof

    # Forwarding contention test
    add x2, x0, 1
    add x2, x0, 2
    add x3, x2, 1

    beq x3, x2, oof

    lw x7, GOOD

    li  t0, 1
    la  t1, tohost
    sw  t0, 0(t1)
    sw  x0, 4(t1)

halt:
    beq x0, x0, halt
    lw x7, BAD

oof:
    lw x7, BAD
    lw x2, PAY_RESPECTS
    beq x0, x0, halt

.section .rodata
.balign 256
DataSeg:
    nop
    nop
    nop
    nop
    nop
    nop
BAD:            .word 0x00BADBAD
PAY_RESPECTS:   .word 0xFFFFFFFF
# cache line boundary - this cache line should never be loaded

A:      .word 0x00000001
GOOD:   .word 0x600D600D
NOPE:   .word 0x00BADBAD
TEST:   .word 0x00000000
FULL:   .word 0xFFFFFFFF
        nop
        nop
        nop
# cache line boundary

B:      .word 0x00000002
        nop
        nop
        nop
        nop
        nop
        nop
        nop
# cache line boundary

C:      .word 0x00000003
        nop
        nop
        nop
        nop
        nop
        nop
        nop
# cache line boundary

D:      .word 0x00000004
        nop
        nop
        nop
        nop
        nop
        nop
        nop

.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
