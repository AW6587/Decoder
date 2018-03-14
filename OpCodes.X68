*---------------------------------------------------------------
* Title      : Disassembler OpCodes
* Written by : Sarah Oliphant
* Date       : 3/2/2018
* Description: Separate Opcodes by checking bits from MSB to LSB
*---------------------------------------------------------------
   
addr1 EQU $2000 ; Memory Address of ORG for test code
addr2 EQU $2050 ; Memory Address of end of test code to disassemble
addr3 EQU $3000 ; Memory Address of Buffer for output
   
* Start of Decoder

    ORG    $1000    ; Memory Adress where this program is stored
    
START:                  ; first instruction of program

**** I/O ****  
IO:

    * User Input for starting and ending memory address
   
    * Convert ASCII Hex addresses 

    * check valid addresses
    
    * check that start address is less than end address
    
    * divide the range of addresses into pages *
    * call OPCODE on the first range of page addresses *
    
    * check if next page is less than the end address of the whole program *
    * Wait for 'Enter' after disassembling first page *
    * call OPCODE on the second range of page addresses *
    
    MOVE.W #addr1, A0 ; pointer to the next instruction to read initialized to start of test program
    MOVE.W #addr3, A1 ; buffer pointer has to be A1 for output functionality
    CLR.L (A1)            ; clear the buffer
    
    MOVE.W #addr1, A3 ; load Address register 3 with start of test program
    MOVE.W #addr2, A2 ; load Address register 2 with end of test program
    
    * After I/O is implemented, I/O will have already loaded this into A0, and passed to Opcode
    BRA OPCODE

IO_INVALID:
* Display XXXX XXXX DATA YYYY

    * The 'XXXX XXXX' (Address of current instruction) part
    * Move the first XXXX word of the address into D4
    MOVE.L A0, D4
    ROL.L #8, D4 * shift the first word left 8 bits
    ROL.L #8, D4 * shift the first word left another 8 bits for a total 16 bits
    AND.L #$0000FFFF, D4 * mask the second word 
    
    * Output the word loaded in D4
    JSR OUTPUT_WORD
    
    JSR PRINTSPACE * Output ' '
    
    * Move the second XXXX word of the address into D4
    MOVE.W A0, D4
   
    * Output the word loaded in D4
    JSR OUTPUT_WORD
    
    JSR PRINTSPACE * Output ' '
    
    * The 'DATA' part
    LEA DATA_OUT, A1 ; loads the address of the constant output 'DATA' into A1
    MOVE.B #14, D0 ; moves the number 14 into data register D0
    TRAP #15
    
    JSR PRINTSPACE * Output ' '
    
    * The 'YYYY' part
    MOVE.W (A0), D4 * moves the data word at address A0 into D4
    JSR OUTPUT_WORD
    
    JSR PRINTLINE * Output a space with a line break
    
* Increment Address pointer by 16 bits (2 bytes)
    JSR INCR_ADDRESS
    
    BRA IO_NEXT         ; check if there is a next instruction or done disassembling

OUTPUT_WORD: * Only call OUTPUT_WORD with JSR, since it returns using RTS *
* Given the 4 byte Word in D4, print each byte to the output as a Hex character
    
    * First byte in 4 byte word *
    MOVE.W D4, D5 * make copy of word in D5
    
    DIVU.W #$1000, D4 * divide to isolate first hex value to print
    MOVE.W D4, D6   * copy the isolated value to D6
    MULU.W #2, D6   * multiply the index by the size of the constant byte
    
    LEA OUT_0, A1 ; loads the address of the start of the constant Hex values
    ADD.W D6, A1 ; index into the constant hex by the number given in D6
    
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    * Second byte in 4 byte word *
    MOVE.L D5, D4 * restore copy of D4 from D5
    
    DIVU.W #$100, D4 * divide to isolate first and second hex value
    AND.W #$000F, D4  * mask the first 3 byte hex values 
    MOVE.W D4, D6 * copy the isolated value to D6
    MULU.W #2, D6 * multiply the index by the size of the constant byte
    
    LEA OUT_0, A1 ; loads the address of the start of the constant Hex values
    ADD.W D6, A1 ; index into constant hex by the number given in D6
    
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    * Third byte in 4 byte word *
    MOVE.L D5, D4 * restore copy of D4 from D5
    
    DIVU.W #$10, D4 * divide to isolate first, second, third hex values
    AND.W #$000F, D4 * mask the first 3 byte hex values
    MOVE.W D4, D6 * copy the isolated value to D6
    MULU.W #2, D6 * multiply the index by the size of the constant byte
    
    LEA OUT_0, A1 ; loads the address of the start of the constant Hex values
    ADD.W D6, A1 ; index into constant hex by the number given in D6
    
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    * Fourth byte in 4 byte word *
    MOVE.L D5, D4 * restore copy of D4 from D5
    
    AND.W #$000F, D4 * mask the first 3 byte hex values
    MOVE.W D4, D6 * copy the isolated value to D6
    MULU.W #2, D6 * multiply the index by the size of the constant byte
    
    LEA OUT_0, A1 ; loads the address of the start of the constant Hex values
    ADD.W D6, A1 ; index into constant hex by the number given in D6
    
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    * Clear D4, D5, D6 *
    CLR.L D4
    CLR.L D5
    CLR.L D6
    
    RTS

IO_VALID:
* display the output loaded into A1
    MOVE.B #13, D0    ; Moves the number 13 into data register D0
    TRAP #15          ; TRAP 15 displays A1 to system out when D0 is #13
    
    BRA IO_NEXT         ; check if there is a next instruction or done disassembling
    
    
IO_NEXT:
* Check if the incremented address pointer is still less than the ending memory address
    
    CMPA.L A0, A2
    
    BGT OPCODE * if memory address pointer is still less than the ending memory address, decode the next 16 bits
    
    * else finished decoding and branch to done
    BRA DONE  

PRINTADDRESSREGISTER: * always call with JSR, since this function returns with RTS *
    * address register number should be loaded into the last 3 bits of D2 *
    
    * display A *
    LEA OUT_A, A1 * loads A into A1
    MOVE.B #14, D0
    TRAP #15
    
    MOVE.B D2, D1 * loads the address register # for output
    MOVE.B #3, D0 * trap task 3 displays a number to system out
    TRAP #15 * calls trap #15
    
    RTS * return *
    
PRINT_DATA_REGISTER: * always call with JSR, since this function returns with RTS *
    * data register number should be loaded into the last 3 bits of D2 *
    
    * display D *
    LEA OUT_D, A1 * loads D into A1
    MOVE.B #14, D0
    TRAP #15
    
    MOVE.B D2, D1 * loads the data register # for output
    MOVE.B #3, D0 * trap task 3 displays a number to system out
    TRAP #15 * calls trap #15

    RTS * return *

PRINT_IDATA: * always call with JSR, since this function returns with RTS *
    * immediate data should be loaded into the last 3 bits of D2 *
    
    * display # *
    LEA HASH, A1
    MOVE.B #14, D0
    TRAP #15
    
    MOVE.L D2, D1 * loads the immediate data for output
    MOVE.B #3, D0 * trap task 3 displays a number to system out
    TRAP #15 * calls trap #15
    
    RTS * return *

PRINTBYTE: * always call with JSR, since this function returns with RTS *
    
    LEA BYTE, A1 * loads .B into A1
    MOVE.B #14, D0    ; Moves the number 14 into data register D0
    TRAP #15          ; TRAP 15 displays A1 to system out when D0 is #14
    
    RTS * return, skips all the way back to the call on TWOBITSIZE, CMP_OPMODE *

PRINTWORD: * always call with JSR, since this function returns with RTS *
    
    LEA WORD, A1 * loads .W into A1
    MOVE.B #14, D0 ; moves the number 14 into data register D0
    TRAP #15 ; TRAP 15 dispalys A1 to system out when D0 is #14
    
    RTS * return, skips all the way back to the call on TWOBITSIZE, CMP_OPMODE *

PRINTLONG: * always call with JSR, since this function returns with RTS *

    LEA LONG, A1 * loads .L into A1
    MOVE.B #14, D0 ; moves number 14 into data register D0
    TRAP #15 ; TRAP 15 displays A1 to system out when D0 is #14
    
    RTS * return, skips all the way back to the call on TWOBITSIZE, CMP_OPMODE *
    
PRINTSPACE: * always call with JSR, since this function returns with RTS *

    LEA SPACE, A1 * loads ' ' into A1
    MOVE.B #14, D0 ; moves number 14 into data register D0
    TRAP #15 ; TRAP 15 displays A1 to system out when D0 is #14
    
    RTS * return *
    
PRINTLINE: * always call with JSR, since this function returns with RTS *
* prints a space with a line break *

    LEA SPACE, A1 * loads ' ' into A1
    MOVE.B #13, D0 ; moves number 14 into data register D0
    TRAP #15 ; TRAP 15 displays A1 to systeem out with a line break when D0 is #13
    
    RTS * return *
    
PRINT_VAR: * always call with JSR, since this function returns with RTS *
* prints the last thing loaded into A1, without a line break *

    MOVE.B #14, D0 ; moves number 14 into data register D0
    TRAP #15 ; TRAP #15 displays A1 to system out when D0 is #14
    
    RTS * return *

**** OpCode ****
* OpCode main should be branched to through OPCODE
* 16+ bit instruction should be located at A0
* A0 address pointer will be incremented according to the appropriate opcode instruction bit length
* Opcode main returns by branching to IO_VALID in order to call a line return on the last data loaded into A1
OPCODE:

* Check first 4 bits of 16 bit instruction at A0 *
    
    JSR RELOAD_INSTRUCTION ; make a copy of the first 16 bits of the instruction at A0 in D2
    
    DIVU.W #$1000, D2 ; divide the instruction to isolate the first 4 bits
    AND.L #$0000000F, D2 ; mask the division remainder
    
    * Check if first 4 bits are 0000
    CMP.B #0, D2 
    BEQ ZERO        ; branch to check instructions that start with 0000
    
    * Check if first 4 bits are 0001
    CMP.B #1, D2
    BEQ ONE_TWO_THREE   ; branch to check instructions that start with 0001
    
    * Check if first 4 bits are 0010
    CMP.B #2, D2
    BEQ ONE_TWO_THREE   ; branch to check instructions that start with 0010
    
    * Check if first 4 bits are 0011
    CMP.B #3, D2
    BEQ ONE_TWO_THREE   ; branch to check instructions that start with 0011
    
    * Check if first 4 bits are 0100
    CMP.B #4, D2
    BEQ FOUR        ; branch to check instructions that start with 0100
    
    * Check if first 4 bits are 0101
    CMP.B #5, D2
    BEQ FIVE        ; branch to check instructions that start with 0101
    
    * Check if first 4 bits are 0110
    CMP.B #6, D2
    BEQ SIX         ; branch to check instructions that start with 0110
    
    * Check if first 4 bits are 0111
    CMP.B #7, D2
    BEQ SEVEN
    
    * Check if first 4 bits are 1000
    CMP.B #8, D2
    BEQ EIGHT
    
    * Check if first 4 bits are 1001
    CMP.B #9, D2
    BEQ NINE
    
    * Check if first 4 bits are 1010
    CMP.B #10, D2
    BEQ TEN
    
    * Check if first 4 bits are 1011
    CMP.B #11, D2
    BEQ ELEVEN
    
    * Check if first 4 bits are 1100
    CMP.B #12, D2
    BEQ TWELVE
    
    * Check if first 4 bits are 1101
    CMP.B #13, D2
    BEQ THIRTEEN
    
    * Check if first 4 bits are 1110
    CMP.B #14, D2
    BEQ FOURTEEN
    
    * Last Option is first 4 bits are 1111
    BRA FIFTEEN

* 0000 for first 4 bits *
ZERO:

    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2

    DIVU.W #256, D2 * divide instruction to isolate second 4 bits
    AND.L #$0000000F, D2 * mask the division remainder and first 4 bits

    * ORI [0000 0000] [2 bit size] [EA]
    CMP.W #0, D2
    BEQ ORI
    
    * CMPI [0000 1100] [2 bit size] [EA]
    CMP.W #12, D2
    BEQ CMPI
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    DIVU.W #64, D2 * divide to isolate the 6 bits before EA from first 4 bits
    AND.L #$0000003F, D2 * mask the division remainder
    
    * BCLR (static) [0000 1000 10] [EA] -> masked EA bit shifts to 0010 0010
    CMP.W #$22, D2
    BEQ BCLR_STATIC

    * BCLR (dynamic) [0000] [Register] [110] [EA]
    AND.L #$00000007, D2 * mask the register
    
    CMP.W #6, D2
    BEQ BCLR_DYNAMIC

* if none of above for 0000 call invalid data
    BRA IO_INVALID

* 0001, 0010, 0011 for first 4 bits *
ONE_TWO_THREE:
    * MOVE or MOVEA
    
* if not MOVE or MOVEA call invalid data
    BRA IO_INVALID
    
* 0100 for first 4 bits *
FOUR:
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    * check if it's NOP (0100 1110 0111 0001)
    CMP.W #$4E71, D2
    BEQ NOP
    
    * check if it's RTS (0100 1110 0111 0101)
    CMP.W #$4E75, D2
    BEQ RTS
             
    * check if it's JSR (0100 1110 10 [EA]) where [EA] is 6 bits
    DIVU.W #64, D2 * divide D2 by 64 to isolate the first 10 bits of instruction
    AND.L #$0000FFFF, D2 * mask the first 4 bytes (division remainder)
    
    CMP.W #$013A, D2 * check the first 10 bits are 0100 1110 10 shifted to -> 0000 0001 0011 1010
    BEQ JSR
       
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    * check if it's NEG (0100 0100 [size] [EA])
    DIVU.W #$100, D2 * divide D2 to isolate first 8 bits
    AND.L #$0000FFFF, D2 * mask the first 4 bits (division remainder)
    CMP.W #$0044, D2 * check the second 4 bits are 4
    BEQ NEG
    
    MOVE.W (A0), D2 ; reload the first 16 bits of instruction to D2
    
    * check if it's LEA (0100 [reg] 111 [EA]) where reg is 3 bits and EA is 6 bits
    DIVU.W #64, D2 * divide D2 by 64 to bit shift 6 bits
    AND.L #$00000007, D2 * mask the division remainder and the first 7 bits of the instruction
    CMP.W #$0007, D2 * check that bits between [reg] and [EA] are 111
    BEQ LEA
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
* other instructions starting with 0100 
            * 1X00 1 -> MOVEM
            
* if none of those instructions with 0100 work, call invalid data
    BRA IO_INVALID


* 0101 for first 4 bits *
FIVE:
* SUBQ (size 00, 01, 10) with a 1 bit before size check for codes (100, 101, 110)

    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    * bit between [data] and [size] has to be a 1
    
    DIVU.W #64, D2 * divide the instruction to isolate size code
    AND.L #$00000007, D2 * mask the division remainder and the first 7 bits of instruction
    
    CMP.B #4, D2 * check for code 100
    BEQ SUBQ
    
    CMP.B #5, D2 * check for code 101
    BEQ SUBQ
    
    CMP.B #6, D2 * check for code 110
    BEQ SUBQ
    
    * if not SUBQ
    BRA IO_INVALID * when bit between data and size is 0 or size is 11

* 0110 for first 4 bits *
SIX:
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    DIVU.W #$100, D2 * divide the instruction to isolate the condition code
    AND.L #$0000000F, D2 * mask the division remainder and the first 4 bits of instruction
    
    * 0101 is BCS (hex equivalent is 5)*
    CMP.B #$5, D2
    BEQ BCS
    
    * 1100 is BGE (hex equivalent is C or 12) *
    CMP.B #$C, D2
    BEQ BGE
    
    * 1101 is BLT (hex equivalent is D or 13) *
    CMP.B #$D, D2
    BEQ BLT
    
    * 1000 is BVC (hex equivalent is 8) *
    CMP.B #$8, D2
    BEQ BVC
    
    * 0000 is BRA (hex equivalent is 0) *
    CMP.B #$0, D2
    BEQ BRA

    * if not one of the BCC
    BRA IO_INVALID
    
* 0111 for first 4 bits * 
SEVEN:   
* Call I/O for invalid (none of the instructions to implement start this way)
    BRA IO_INVALID
    
* 1000 for first 4 bits *
EIGHT:

    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2

    DIVU.W #64, D2 * divide the instruction to isolate the opmode
    AND.L #$00000007, D2 * mask the division remainder and the first 7 bits of instruction
    
    * separate by opmode
        * DIVS (opmode 111)
        * OR (opmodes 000, 001, 010, 100, 101, 110)
        
    CMP.W #0, D2 * check for opmode 000
    BEQ OR_LEFT * E/A is destination operand

    CMP.W #1, D2 * check for opmode 001
    BEQ OR_LEFT * E/A is destination operand
    
    CMP.W #2, D2 * check for opmode 010
    BEQ OR_LEFT * E/A is destination operand
    
    CMP.W #4, D2 * check for opmode 100
    BEQ OR_RIGHT * E/A is destination operand
    
    CMP.W #5, D2 * check for opmode 101
    BEQ OR_RIGHT * E/A is destination operand
    
    CMP.W #6, D2 * check for opmode 110
    BEQ OR_RIGHT * E/A is destination operand
    
    CMP.W #7, D2 * check for opmode 111
    BEQ DIVS
    
    * if not DIVS, OR (when opmode is 011)
    BRA IO_INVALID

* 1001 for first 4 bits *
NINE:    
* SUB (opmodes 000, 001, 010, 100, 101, 110)

    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2

    DIVU.W #64, D2 * divide the instruction to isolate the opmode
    AND.L #$00000007, D2 * mask the division remainder and the first 7 bits of instruction
    
    CMP.W #0, D2 * check for opmode 000
    BEQ SUB_LEFT * E/A is left operand
    
    CMP.W #1, D2 * check for opmode 001
    BEQ SUB_LEFT * E/A is left operand
    
    CMP.W #2, D2 * check for opmode 010
    BEQ SUB_LEFT * E/A is left operand
    
    CMP.W #4, D2 * check for opmode 100
    BEQ SUB_RIGHT * E/A is right operand
    
    CMP.W #5, D2 * check for opmode 101
    BEQ SUB_RIGHT * E/A is right operand
    
    CMP.W #6, D2 * check for opmode 110
    BEQ SUB_RIGHT * E/A is right operand

    * if not SUB (opmodes 011, 111)
    BRA IO_INVALID

* 1010 for first 4 bits *
TEN:
* Call I/O for invalid (none of the instructions to implement start this way)
    BRA IO_INVALID

* 1011 for first 4 bits *
ELEVEN:
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2

    DIVU.W #64, D2 * divide the instruction to isolate the opmode
    AND.L #$00000007, D2 * mask the division remainder and the first 7 bits of instruction
    
    * EOR (opmodes 100, 101, 110)
    CMP.W #4, D2 * check for opmode 100
    BEQ EOR * if yes EOR
    
    CMP.W #5, D2 * check for opmode 101
    BEQ EOR * if yes EOR
    
    CMP.W #6, D2 * check for opmode 110
    BEQ EOR * if yes EOR

    * CMP (opmodes 000, 001, 010)
    CMP.W #0, D2 * check for opmode 000
    BEQ CMP * if yes CMP
    
    CMP.W #1, D2 * check for opmode 001
    BEQ CMP * if yes CMP
    
    CMP.W #2, D2 * check for opmode 010
    BEQ CMP * if yes CMP
    
    BRA IO_INVALID * when opmode is 111, 011
    
* 1100 for first 4 bits *
TWELVE:
    * MULS
    
    * check that the 3 bits between [register] and [E/A] are 111 (basically the opmode)
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2

    DIVU.W #64, D2 * divide the instruction to isolate the opmode
    AND.L #$00000007, D2 * mask the division remainder and the first 7 bits of instruction
    
    CMP.W #7, D2 * check that the 3 bits between [reg] and [E/A] are 111
    BEQ MULS
    
    * if not MULS
    BRA IO_INVALID
    
* 1101 for first 4 bits *    
THIRTEEN:
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2

    DIVU.W #64, D2 * divide the instruction to isolate the opmode
    AND.L #$00000007, D2 * mask the division remainder and the first 7 bits of instruction
    
    * separate by opmode
        * ADDA (opmode 011, 111)
        * ADD (opmodes 000, 001, 010, 100, 101, 110)
        
    CMP.W #0, D2 * check for opmode 000
    BEQ ADD_LEFT * E/A is left operand
    
    CMP.W #1, D2 * check for opmode 001
    BEQ ADD_LEFT * E/A is left operand

    CMP.W #2, D2 * check for opmode 010
    BEQ ADD_LEFT * E/A is left operand
    
    CMP.W #3, D2 * check for opmode 011
    BEQ ADDA
    
    CMP.W #4, D2 * check for opmmode 100
    BEQ ADD_RIGHT * E/A is right operand
    
    CMP.W #5, D2 * check for opmode 101
    BEQ ADD_RIGHT * E/A is right operand
    
    CMP.W #6, D2 * check for opmode 110
    BEQ ADD_RIGHT * E/A is right operand
    
    CMP.W #7, D2 * check for opmode 111
    BEQ ADDA
    
    * if not ADDA, ADD
    BRA IO_INVALID * shouldn't happen
    
* 1110 for first 4 bits *
FOURTEEN:    
    * one of the shifts (LSL, LSR, ASL, ASR, ROL, ROR) depending on later bits
    
    * if none of the shifts
    BRA IO_INVALID

* 1111 for first 4 bits *
FIFTEEN:
* Call I/O for invalid (none of the instructions to implement start this way) 
    BRA IO_INVALID

NOP:
* Load NOP to the Buffer (in A1)
    LEA NOP_OUT, A1
    
* Increment address pointer by 16 bits (2 bytes)
    JSR INCR_ADDRESS
    
* Call I/O to output 
    BRA IO_VALID


RTS:
* Load RTS to the Buffer (in A1)
    LEA RTS_OUT, A1

* Increment address pointer by 16 bits (2 bytes)
    JSR INCR_ADDRESS

* Call I/O to output
    BRA IO_VALID

MULS:
    * Call E/A to get effective address
        * If E/A not valid call IO_INVALID
        
    * print MULS *
    LEA MULS_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (MULS)
        
    * print .W (since Word is the only valid size of MULS *
    JSR PRINTWORD * prints .W
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *

    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER

    * Increment address pointer
    JSR INCR_ADDRESS

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

DIVS:
    * Call E/A to get effective address
        * If E/A not valid call IO_INVALID
        
    * print DIVS *
    LEA DIVS_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (DIVS)
    
    * print .W (since Word is the only valid size for DIVS *
    JSR PRINTWORD * prints .W

    JSR PRINTSPACE * print space *

    * print E/A *
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER

    * Increment address pointer by 16 bits (2 bytes)
    JSR INCR_ADDRESS

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

NEG:

    * isolate size field 
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide by 64 to bit shift right 6 bits
    AND.L #$00000003, D2 * mask the divison remainder and the opcode bits
    
    CMP.W #3, D2 * if size is 11, it's invalid
    BEQ IO_INVALID
    
    LEA NEG_OUT, A1 * Load NEG to the Buffer
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    JSR TWOBITSIZE * call the 2 bit size function
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    * Call E/A to get effective address, and print them to output

        * If E/A not valid call IO_INVALID

    JSR INCR_ADDRESS * Increment address pointer by 16 bits (2 bytes)

* Call I/O to output a line return 
    LEA SPACE, A1
    BRA IO_VALID

JSR:
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    * Call E/A to get effective address for last 6 bits loaded in D2
    
        * If E/A not valid call IO_INVALID
    
    LEA JSR_OUT, A1 * load JSR to A1
    
    JSR INCR_ADDRESS * Increment address pointer by 16 bits (2 bytes)

    BRA IO_VALID * Call I/O to output

LEA:

    * Call E/A to get effective address
        * if E/A not valid call IO_INVALID 
        
    LEA LEA_OUT, A1 * load LEA to A1
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    * display E/A to output
    
    JSR PRINTSPACE * display a space *
    
    * display a comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    JSR PRINTSPACE * display a space *
    
    JSR RELOAD_INSTRUCTION MOVE.W ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 * divide to shift the register bits all the way to the right
    AND.L #$0000007, D2 * mask division remainder and all bits except register number
    
    JSR PRINTADDRESSREGISTER * prints the address register # stored in D2
    
    JSR INCR_ADDRESS * Increment address pointer by 16 bits (2 bytes)
    
    * print a line return *
    LEA SPACE, A1
    BRA IO_VALID

BCS:
    
    JSR BRANCHDISPLACEMENT
    
    * load BCS to output *
    LEA BCS_OUT, A1
    BRA IO_VALID

BGE:
    JSR BRANCHDISPLACEMENT
    
    * load BGE to output *
    LEA BGE_OUT, A1
    BRA IO_VALID
    
BLT:

    JSR BRANCHDISPLACEMENT

    * load BLT to output *
    LEA BLT_OUT, A1
    BRA IO_VALID

BVC:
    JSR BRANCHDISPLACEMENT

    * load BVC to output *
    LEA BVC_OUT, A1
    BRA IO_VALID

BRA:
    JSR BRANCHDISPLACEMENT

    * load BRA to output *
    LEA BRA_OUT, A1
    BRA IO_VALID

BRANCHDISPLACEMENT: * only call this method with JSR, since it returns with RTS *
* for the opcodes BCS, BGE, BLT, BVC, and BRA, (the Bcc opcodes), *
* checks the 8-bit displacement to see how far to increment the address pointer *
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    AND.W #$00FF, D2 * mask the first 8 bits of instruction to leave the 8 bit displacement
    
    CMP.B #$00, D2     * check 8 bit displacement = $00
    BEQ INC32          * if yes, increment by 32 bits (4 bytes)
    
    CMP.B #$FF, D2     * check if 8 bit displacement = $FF
    BEQ INC48          * if yes, increment by 48 bits (6 bytes)
        
    * else increment by 16 bits (2 bytes)
    JSR INCR_ADDRESS * Increment address pointer by 16 bits (2 bytes)
    
    RTS * return *
    
INC32: * call JSR on this method, since it returns with RTS *

    ADD.W #4, A0 * increment address pointer by 48 bits (6 bytes)
    RTS * return, skips back to the JSR call on BRANCHDISPLACEMENT, INCR_32_OR_64 *
   
INC48: * call JSR on this method, since it returns with RTS *

    ADD.W #6, A0 * increments address pointer by 32 bits (4 bytes)
    RTS * return, skips back to the JSR call on BRANCHDISPLACEMENT, INCR_32_OR_64 *
 
MOVEM:
* Load MOVEM to the Buffer

* Call E/A to get effective addresses

    * If E/A not valid call IO_INVALID

* Increment address pointer

* Call I/O to output
    BRA IO_VALID
    
CMP:
    * Opmode is loaded into D2 *
    
    * Call E/A to get effective address *
        * if E/A not valid call IO_INVALID *
        
    * print CMP *
    LEA CMP_OUT, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (CMP)
    
    * print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * Increment Address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

EOR:
    * Opmode is loaded into D2 *

    * Call E/A to get effective address *
        * if E/A not valid call IO_INVALID
    
    * print EOR *
    LEA EOR_OUT, A1
    JSR PRINT_VAR * print the last var loaded into A1 (EOR)
    
    * print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space *
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    * print E/A *
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS

    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

OR_LEFT:
    * Opmode is loaded into D2 *

    * Call E/A to get effective address *
        * if E/A not valid call to IO_INVALID
        
    * Print OR *
    LEA OR_OUT, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (OR)
    
    * print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID
    
OR_RIGHT:
    * Opmode is loaded into D2 *

    * Call E/A to get effective address *
        * if E/A not valid call to IO_INVALID
    
    * Print OR *
    LEA OR_OUT, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (OR)
    
    * print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space *
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    * print space *
    JSR PRINTSPACE
    
    * print E/A *
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

ADD_LEFT:
    * Opmode is loaded into D2 *
    
    * Call E/A to get effective address *
        * if E/A not valid call IO_INVALID *
        
    * Print ADD *
    LEA ADD_OUT, A1
    JSR PRINT_VAR * print the last var loaded into A1 (ADD)
    
    * Print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space
    
    * print E/A *
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

ADD_RIGHT:
    * Opmode is loaded into D2 *
    
    * Call E/A to get effective address *
        * if E/A not valid call IO_INVALID *

    * Print ADD *
    LEA ADD_OUT, A1
    JSR PRINT_VAR * print the last var loaded into A1 (ADD)
    
    * Print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space
    
    * print E/A *
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

SUB_LEFT:
    * Opmode is loaded into D2 *

    * Call E/A to get effective address *
        * if E/A not valid call IO_INVALID *
        
    * Print SUB *
    LEA SUB_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (SUB)
    
    * Print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space

    * print E/A *
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

SUB_RIGHT:
    * Opmode is loaded into D2 *

    * Call E/A to get effective address *
        * if E/A not valid call IO_INVALID *
   
    * Print SUB *
    LEA SUB_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (SUB)
    
    * Print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space
    
    * print E/A *
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

SUBQ:

    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    * Call E/A to get effective address *
        * if E/A not valid call IO_INVALID *
        
    * Print SUBQ *
    LEA SUBQ_OUT, A1
    JSR PRINT_VAR * print the last var loaded into A1 (SUBQ)
    
    * isolate size *
    DIVU.W #64, D2 * divide to isolate the size
    AND.L #$00000003, D2 * mask the division remainder
    
    * print size *
    JSR TWOBITSIZE
    
    JSR PRINTSPACE * print space *
    
    * print Immediate Data *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the immediate data
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_IDATA * call to PRINT_IDATA

    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    * print space *
    JSR PRINTSPACE
    
    * print E/A *
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

ORI:
    * Call E/A to get effective address *
        * if E/A not valid call IO_INVALID *
        
    * Print ORI *
    LEA ORI_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (ORI)
    
    * isolate the size *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2

    DIVU.W #64, D2 * divide to isolate the size
    AND.L #$00000003, D2 * mask the division remainder
    
    * print size *
    JSR TWOBITSIZE
    
    JSR PRINTSPACE * print space *
    
    * print variable length (byte, word, long) immediate data *
    JSR PRINT_IMMEDIATE
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    
    * increment address pointer by either 32 bits or 48 bits *
    JSR INCR_32_OR_48
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

INCR_32_OR_48: * always call with JSR, since returns with RTS *

    * isolate the size *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2

    DIVU.W #64, D2 * divide to isolate the size
    AND.L #$00000003, D2 * mask the division remainder
    
    CMP #0, D2 * check for byte size
    BEQ INC32 * increments address pointer by 32 bits (4 bytes)
    
    CMP #1, D2 * check for word size
    BEQ INC32 * increments address pointer by 32 bits (4 bytes)
    
    CMP #2, D2 * check for long size
    BEQ INC48 * increments address pointer by 32 bits (6 bytes)
    
    RTS * return, shouldn't reach here, only if size is invalid *

PRINT_IMMEDIATE: * always call by JSR, since returns with RTS *
    * size is loaded in D2 (00 is Byte, 01 is Word, 10 is long)
    
    CMP #0, D2 * check if size of immediate is byte
    BEQ BYTE_IMMEDIATE
    
    CMP #1, D2 * check if size of immediate is word
    BEQ WORD_IMMEDIATE
    
    CMP #2, D2 * check if size of immediate is long
    BEQ LONG_IMMEDIATE
    
    RTS * return, only gets here if size is invalid *

BYTE_IMMEDIATE:

    MOVEA.L A0, A5 * copies current address pointer to A5
    
    ADD.W #2, A5 * increments A5 address pointer by 2 bytes (16 bits)

    CLR D2 * clear D2

    MOVE.B (A5), D2 * copies the byte of memory at addrress A5 into D2

    BRA PRINT_IDATA * prints the immediate data in D2, then returns to opcode

WORD_IMMEDIATE:

    MOVEA.L A0, A5 * copies current address pointer to A5
    
    ADD.W #2, A5 * increments A5 address pointer by 2 bytes (16 bits)
    
    CLR D2 * clear D2
    
    MOVE.W (A5), D2 * copies the word of memory at address A5 into D2

    BRA PRINT_IDATA * prints the immediate data in D2, then returns to opcode
    
LONG_IMMEDIATE:

    MOVEA.L A0, A5 * copies current address pointer to A5
    
    ADD.W #2, A5 * increments A5 address pointer by 2 bytes (16 bits)
    
    CLR D2 * clear D2
    
    MOVE.L (A5), D2 * copies the long of memory at address A5 into D2

    BRA PRINT_IDATA * prints the immediate data in D2, then returns to opcode

CMPI:

    * Call E/A to get effective address *
        * If E/A not valid call IO_INVALID *
        
    * Print CMPI *
    LEA CMPI_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (CMPI)
    
    * isolate size *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    DIVU.W #64, D2 * divide to isolate the size
    AND.L #$00000003, D2 * mask the division remainder
    
    * print size *
    JSR TWOBITSIZE
    
    JSR PRINTSPACE * print space *
    
    * print variable length (byte, word, long) immediate data *
    JSR PRINT_IMMEDIATE
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    
    * increment address pointer by 32 bits or 48 bits depending on size *
    JSR INCR_32_OR_48
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID
    
BCLR_STATIC:

    * check if the next 8 bits following the current 16 bit instruction are 0
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    MOVEA.L A0, A5 * copies current address pointer to A5
    
    ADD.W #2, A5 * increments A5 address pointer by 2 bytes (16 bits)

    CLR D2 * clear D2

    MOVE.B (A5), D2 * copies the byte of memory at addrress A5 into D2
    
    CMP.B #$00, D2 * checks that the next 8 bits following the instruction are 0000 0000
    BNE IO_INVALID * if not equal, invalid instruction

    * Call E/A to get effective addresses

        * If E/A not valid call IO_INVALID
    
    * Print BCLR *
    LEA BCLR_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (BCLR)
    
    * Print Space *
    JSR PRINTSPACE
    
    * print immediate data in the last 8 bits of second 16 bit instructions * 
    ADD.W #1, A5 * increments A5 to point at the immediate data
    JSR WORD_IMMEDIATE * prints the immediate data
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (comma)
    
    * print space *
    JSR PRINTSPACE
    
    * print E/A *

    * Increment address pointer by 32 bits (4 bytes) *
    JSR INC32

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

BCLR_DYNAMIC:

    * Call E/A to get effective addresses

        * If E/A not valid call IO_INVALID
        
    * print BCLR *
    LEA BCLR_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (BCLR)
    
    * print space *
    JSR PRINTSPACE
    
    * print data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (comma)
    
    * print space *
    JSR PRINTSPACE
    
    * print E/A *

    * Increment address pointer by 16 bits
    JSR INCR_ADDRESS

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

ADDA:
    * Call E/A to get effective addresses

        * If E/A not valid call IO_INVALID
        
    * print ADDA *

    * Increment address pointer

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID


THREE_BIT_OPMODE * must call with JSR, since returns with RTS *
* Opmode is loaded into D2 *
* Calling this method from EOR, CMP, OR, ADD, SUB *

    CMP.B #0, D2 * opmode 000
    BEQ PRINTBYTE
    
    CMP.B #1, D2 * opmode 001
    BEQ PRINTWORD
    
    CMP.B #2, D2 * opmode 010
    BEQ PRINTLONG
    
    CMP.B #4, D2 * opmode 100
    BEQ PRINTBYTE
    
    CMP.B #5, D2 * opmode 101
    BEQ PRINTWORD
    
    CMP.B #6, D2 * opmode 110
    BEQ PRINTLONG
    
    RTS * return if opmode is invalid (it shouldn't be if checking invalid opmodes in the opcode decoding)

TWOBITSIZE: * always call with JSR, since this function returns with RTS *
* prints .L for 10, .W for 01, or .B for 00 where the two bits are in D2 *
* Called from NEG, SUBQ, ORI, CMPI *

    CMP #0, D2 * check if the size is byte *
    BEQ PRINTBYTE

    CMP #1, D2 * check if the size is word *
    BEQ PRINTWORD
    
    CMP #2, D2 * check if the size is long *
    BEQ PRINTLONG

    RTS * return if the size in D2 is invalid (shouldn't be if checking invalid size before calling *
    
MOVESIZE: * always call with JSR, since this function returns with RTS *
* prints .L for 10, .W for 11, or .B for 01 where the two bits are in D2 *

    RTS * return if the size is invalid (shouldn't be if checking invalid size before calling *
    
RELOAD_INSTRUCTION: * always call with JSR, since this function returns with RTS *
* clears data register 2, and reloads the 16 bit instruction at Address Register 0 *

    CLR.L D2 * clear D2
    
    MOVE.W (A0), D2 ; reload the first 16 bits of instruction to D2
    
    RTS * return *
    
INCR_ADDRESS: * always call with JSR, since this function returns with RTS *
* increments the address pointer at A0 by 16 bits (2 bytes)

    ADD.W #2, A0

    RTS * return *

DONE: ; done


    SIMHALT             ; halt simulator

* test code down here -> memory address ORG at $2000

    ORG $2000
    BCLR #4, (A3)
    MULS D2, D3
    DIVS (A1), D3
    NOP         ; test instructions
    BCLR D4, (A2)
    ORI.L #$10002000, D5
    CMPI.L #24568465, D2
    SUBQ.B #2, (A0)
    SUB.W (A0), D2
    ADD.L (A3), D4
    OR.B (A2), D3
    EOR.W D1, D2
    CMP.B D2, D1
    BGE DONE
    BLT DONE
    BVC DONE
    BCS DONE
    BRA DONE
    LEA NOP_OUT, A1
    NEG.L $1600
    JSR DONE
    NOT $1600   ; test instructions 
    NOP         ; test instruction
    RTS
    

* Put variables and constants here


* Constants for output instructions
NOP_OUT DC.B 'NOP',0        ; output message when NOP is the test instruction
DATA_OUT DC.B 'DATA',0      ; output message when invalid instruction
MOVE_OUT DC.B 'MOVE', 0     ; output message when MOVE is the test instruction
MOVEA_OUT DC.B 'MOVEA', 0   ; output message when MOVEA is the test instruction
MOVEM_OUT DC.B 'MOVEM', 0   ; output message when MOVEM is the test instruction
ADD_OUT DC.B 'ADD', 0       ; output message when ADD is the test instruction
ADDA_OUT DC.B 'ADDA', 0     ; output message when ADD is the test instruction
SUB_OUT DC.B 'SUB', 0       ; output message when SUB is the test instruction
SUBQ_OUT DC.B 'SUBQ', 0     ; output message when SUBQ is the test instruction
MULS_OUT DC.B 'MULS', 0     ; output message when MULS is the test instruction
DIVS_OUT DC.B 'DIVS', 0     ; output message when DIVS is the test instruction
LEA_OUT DC.B 'LEA', 0       ; output message when LEA is the test instruction
OR_OUT DC.B 'OR', 0         ; output message when OR is the test instruction
ORI_OUT DC.B 'ORI', 0       ; output message when ORI is the test instruction
NEG_OUT DC.B 'NEG', 0       ; output message when NEG is the test instruction
EOR_OUT DC.B 'EOR', 0       ; output message when EOR is the test instruction
LSR_OUT DC.B 'LSR', 0       ; output message when LSR is the test instruction
LSL_OUT DC.B 'LSL', 0       ; output message when LSL is the test instruction
ASR_OUT DC.B 'ASR', 0       ; output message when ASR is the test instruction
ASL_OUT DC.B 'ASL', 0       ; output message when ASL is the test instruction
ROL_OUT DC.B 'ROL', 0       ; output message when ROL is the test instruction
ROR_OUT DC.B 'ROR', 0       ; output message when ROR is the test instruction
BCLR_OUT DC.B 'BCLR', 0     ; output message when BCLR is the test instruction
CMP_OUT DC.B 'CMP', 0       ; output message when CMP is the test instruction
CMPI_OUT DC.B 'CMPI', 0     ; output message when CMPI is the test instruction
BCS_OUT DC.B 'BCS', 0       ; output message when BCS is the test instruction
BGE_OUT DC.B 'BGE', 0       ; output message when BGE is the test instruction
BLT_OUT DC.B 'BLT', 0       ; output message when BLT is the test instruction
BVC_OUT DC.B 'BVC', 0       ; output message when BVC is the test instruction
BRA_OUT DC.B 'BRA', 0       ; output message when BRA is the test instruction
JSR_OUT DC.B 'JSR', 0       ; output message when JSR is the test instruction
RTS_OUT DC.B 'RTS', 0       ; output message when RTS is the test instruction

* Constants for Instruction size
LONG DC.B '.L', 0
WORD DC.B '.W', 0
BYTE DC.B '.B', 0

* Constants for Miscellaneous
SPACE DC.B ' ', 0
COMMA DC.B ',', 0
HASH DC.B '#', 0
DOLLAR DC.B '$', 0
LEFT_PAREN DC.B '(', 0
RIGHT_PAREN DC.B ')', 0

* Constant Hex Numbers for XXXX XXXX DATA YYYY 
OUT_0 DC.B '0', 0
OUT_1 DC.B '1', 0
OUT_2 DC.B '2', 0
OUT_3 DC.B '3', 0
OUT_4 DC.B '4', 0
OUT_5 DC.B '5', 0
OUT_6 DC.B '6', 0
OUT_7 DC.B '7', 0
OUT_8 DC.B '8', 0
OUT_9 DC.B '9', 0
OUT_A DC.B 'A', 0
OUT_B DC.B 'B', 0
OUT_C DC.B 'C', 0
OUT_D DC.B 'D', 0
OUT_E DC.B 'E', 0
OUT_F DC.B 'F', 0

    END    START        ; last line of source











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
