; Castle Wolfenstein Sound Board
; https://github.com/Michaelangel007/apple2_castle_wolfenstein_sound_board
; Assembler: Merlin32
;
; To rip code + data
;   bsave "cw.play.1950",1950:1980
;   bsave "cw.sfx.5e36",5e36:8b9d

temp = $FB
dst  = $FC
src  = $FE

PRODOS = $BF00

KEY         = $C000
KEYSTROBE   = $C010

SQUEEKER    = $C030

TEXT        = $FB39 ; SETTXT
HOME        = $FC58
COUT        = $FDED
BELL        = $FBDD

        ORG $2000

LENGTH = __END - __START + __MAIN - Main

; Move from $2000 .. $5D00
Main    BIT __MAIN + $3D00
        LDA #$4C        ; "JMP" $abs
        STA $2000
Move    LDY #0
Src     LDA $2000,Y     ; The two regions don't overlap
Dst     STA $5D00,Y     ; $2000 + $2E9E = $4E9E < $5D00
        INY
        BNE Src
        INC Src+2
        INC Dst+2
        LDA Src+2
        CMP #>LENGTH + Main
        BNE Move
        BEQ Main

__MAIN
        ORG * + $3D00 ; $5D00
__START
        JSR TEXT
        JSR HOME

        LDA #'A'+$80
        STA temp

        LDX #$5E    ; hi
        LDY #$36    ; lo
        STX src+1
        STY src+0

        STX Pointers+1
        STY Pointers+0

        LDX #>Pointers
        LDY #<Pointers+2
        STX dst+1
        STY dst+0

; Walk Linked-List
PrintNames
        LDY #1
        LDA (src),Y     ;16-bit pointer to next SFX
        BEQ DoneNames
        STA (dst),Y

        DEY
        LDA (src),Y
        STA (dst),Y

        INY
        INY
        LDX #$18

        LDA temp
        JSR COUT
        INC temp

        LDA #')'+$80
        JSR COUT
        LDA #' '+$80
        JSR COUT

LoopName
        LDA (src),Y
        JSR COUT
        INY
        DEX
        BNE LoopName

        LDA #$8D
        JSR COUT

        LDY #0
        LDA (dst),Y
        STA src+0
        INY
        LDA (dst),Y
        STA src+1

        INC dst         ; too lazy to do page cross check
        INC dst
        BNE PrintNames

DoneNames
        JSR BELL

GetInput
        LDA KEY
        BPl GetInput
        STA KEYSTROBE

        AND #$7F
        CMP #$1B
        BEQ Exit

        SEC
        SBC #'A'
        ASL
        TAX
        LDA Pointers,X
        CLC
        ADC #36         ; + 36?
        STA src+0
        INX
        LDA Pointers,X
        BEQ DoneNames
        ADC #0
        STA src+1
        JSR Play
        JMP GetInput
Exit    JSR  PRODOS        ;Call the MLI ($BF00)

        DFB  $65           ;CALL TYPE = QUIT
        DW   PARMTABLE     ;Pointer to parameter table
PARMTABLE
        DFB  4             ;Number of parameters is 4
        DFB  0             ;0 is the only quit type
        DW   0000          ;Pointer reserved for future use
        DFB  0             ;Byte reserved for future use
        DW   0000          ;Pointer reserved for future use


; Player ripped from $1950
Play
        LDY #$00
NextNote
        LDA (src),Y
        PHA
        STA temp
DelayNote
        LDY #$04
        BEQ DoneDelay
Delay
        DEY
        BNE Delay
DoneDelay
        DEC temp
        BNE DelayNote
        PLA
        CMP #$FE
        BEQ SkipDelay
DAC
        LDA #$FF
        NOP
        EOR #$FF
        STA DAC+1
        LDA SQUEEKER
SkipDelay
        INC src+0
        BNE SamePage
        INC src+1
SamePage
        LDA (src),Y
        CMP #$FF
        BNE NextNote
        RTS

; Array of 16-bit pointers
        DS \,$00
Pointers            ; This can't go on the previous page since it spills over due to lazy code above
        DS $36,$00
SFX     PUTBIN cw.sfx.5e36

        DS \,$FF    ; Pad with End-of-Song
__END

