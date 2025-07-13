.code16
.intel_syntax noprefix

main:
    jmp boot

# Bytes 4-62 stores deviceinfo. This is essentially a struct
bootsector:
    iOEM:          .ascii "zoot    "     # OEM String
    iSectSize:     .word  0x200          # bytes per sector
    iClustSize:    .byte  1              # sectors per cluster
    iResSect:      .word  1              # #of reserved sectors
    iFatCnt:       .byte  2              # #of FAT copies
    iRootSize:     .word  224            # size of root directory
    iTotalSect:    .word  2880           # total # of sectors if over 32 MB
    iMedia:        .byte  0xF0           # media Descriptor
    iFatSize:      .word  9              # size of each FAT
    iTrackSect:    .word  9              # sectors per track
    iHeadCnt:      .word  2              # number of read-write heads
    iHiddenSect:   .int   0              # number of hidden sectors
    iSect32:       .int   0              # # sectors for over 32 MB
    iBootDrive:    .byte  0              # holds drive that the boot sector
                                         # came from
    iReserved:     .byte  0              # reserved, empty
    iBootSign:     .byte  0x29           # extended boot sector signature
    iVolID:        .ascii "seri"         # disk serial
    acVolumeLabel: .ascii "MYVOLUME   "  # volume label
    acFSType:      .ascii "FAT16   "     # file system type

usefulconstants:
    diskerror: .asciz "(FreePaw) Disk ERROR.\r\n"
    rebootmsg: .asciz "(FreePaw) Press any key to reboot\r\n"
    loadmsg:   .asciz "Loading FreePaw...\r\n"

Reboot:
    lea si, rebootmsg
    call WriteString

    # Keyboard - Get Keystroke: int 0x16 subfunc 0
    # AH: 0
    # Returns:
    # AH: BIOS Scan Code
    # AL: ASCII Char
    .waitforkey:
    xor ax, ax
    int 0x16

    .reboot:
    .byte 0xEA           # machine language to jump to FFFF:0000 (reboots)
    .word 0x0000
    .word 0xFFFF

WriteString:
    lodsb                # Special x86 instruction to load DS:SI to AL
    or al, al            # Only 0 at end of string
    jz .WriteStringDone  

    # Teletype video output: int 0x10 subfunc 0xe
    # AH: 0xe
    # AL: Character to print
    # BH: Page Number
    # BL: Foreground color
    .printchar:
    MOV ah, 0xe          # subfunction 0xe is the print subfunc
    mov BH, 0            # pagenum 0
    mov BL, 9            # 9 is white 
    int 0x10             # Interupt to give control to BIOS
    jmp WriteString      # Continue untill end of string

    .WriteStringDone:
    ret

boot:
    cli                  # Disable interrupts
    mov iBootDrive, dl   # Save Drive we booted from
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00       # Setup top of stack. Grows down in x86
    lea si, loadmsg
    .resetdisk:
    mov dl, iBootDrive   # dl stores the drive we want to reset
    xor ax, ax           # ax stores the subfunction to use; Subfunc 0 is reset
    int 0x13             # BIOS interrupt 0x13 subfunction 0 is disk reset
    jc .bootfail         # jc set on disk reset fail
    .printandwait:
    call WriteString
    .bootfail:
    lea si, diskerror
    call WriteString
    call Reboot
    sti                  # Re-enable interrupts

# it may be safe to use external zig code. This line will cause an odd
# compilation error if the binary exceeds 512 bytes.
.fill (510-(.-main)), 1, 0
