#  mp4-cp2.s version 1.3
.align 4
.section .text
.globl _start
_start:

lw x1, A
lw x2, B
lw x3, C
lw x4, D
lw x5, E
lw x6, F
lw x7, G
lw x8, H

la x15, A
addi x1, x1, 15
sw x1, 0(x15)
nop
nop
nop

lw x9, I
lw x10, A
nop
nop
nop

halt:
    beq x0, x0, halt
    lw x7, BAD

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
TEST:   .word 0x10000000
FULL:   .word 0xFFFFFFFF
ADDR:   .word 0x800F0000    # Initial satp data
OFF:    .word 0x00000001    # Page Offsets
STATUS: .word 0x00080000
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

E:      .word 0x00000005
        nop
        nop
        nop
        nop
        nop
        nop
        nop

F:      .word 0x00000006
        nop
        nop
        nop
        nop
        nop
        nop
        nop

G:      .word 0x00000007
        nop
        nop
        nop
        nop
        nop
        nop
        nop

H:      .word 0x00000008
        nop
        nop
        nop
        nop
        nop
        nop
        nop

I:      .word 0x00000009
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