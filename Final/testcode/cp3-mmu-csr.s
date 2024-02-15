#  mp4-cp2.s version 1.3
.align 4
.section .text
.globl _start
_start:

addi x1, x1, 1
nop
nop
nop
csrrw x5, 0xc01, x1     # x5 should have 0 and mtime should have 1
addi x2, x2, 0xff
csrrs x6, 0xb00, x2     # mcycle should have 32'b0ff and x6 should have 0 since mcycle was not set
nop
nop
nop
nop
addi x3, x3, 0xf0
csrrc x7, 0xb00, x3     # mcycle should have 32'b00f and x7 should have 32'b0ff
csrrwi x8, 0xc01, 1     # mtime should have 1 and x8 should have 1 
csrrsi x9, 0xc81, 15    # mtimeh should have 0xf and x9 should have 0
nop
nop
nop
nop
csrrci x10, 0xc81, 3    # mtimeh should have 0xc and x10 should have f
nop
nop
nop
nop

# Above code should display successful address translation as well as instruction TLB hits
lw x12, ADDR            # Show data TLB miss
lw x13, OFF
lw x11, B               # dcache miss -> dtlb hit
add x12, x12, x13
nop 
nop
csrrw x15, 0x180, x12   # Next tranlation should fail due to an invalid page (should also flush itlb) 1
# Wait for the next address translation
nop
nop
nop
lw x14, FULL            # Should dtlb miss
add x12, x12, x13
csrrw x15, 0x180, x12   # Next tranlation should fail due to not having interactable flags set  2
nop
nop
nop
lw x14, FULL            # Should dtlb miss
add x12, x12, x13
csrrw x15, 0x180, x12   # Next tranlation should fail due to writing a non-readable page  3
nop
nop
nop
lw x14, FULL            # Should dtlb miss
add x12, x12, x13
csrrw x15, 0x180, x12   # Next tranlation should fail due to a non-accessible page  4
nop
nop
nop
lw x14, FULL            # Should dtlb miss
add x12, x12, x13
csrrw x15, 0x180, x12   # Next tranlation should fail due to due to trying to read from an executable page without permission (make sure to not have permission)  5
nop
nop
nop
lw x16, STATUS          # Should dtlb miss
csrrs x0, 0x300, x16    # Next translation should success because MXR bit was set  5
nop
nop
nop
lw x14, FULL            # Should dtlb miss
add x12, x12, x13
csrrw x15, 0x180, x12   # Next translation should fail due to misaligned superpage  6
nop
nop
nop
lw x14, FULL            # Should dtlb miss
add x12, x12, x13
csrrw x15, 0x180, x12   # Next translation should succeed with an aligned superpage  7
nop
nop
nop
lw x14, FULL            # Should dtlb miss
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

.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
