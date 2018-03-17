*---------------------------------------------------------------
* Title      : Disassembler OpCodes/IO
* Written by : Sarah Oliphant, Midori williams
* Date       : 3/2/2018
* Description: Disassembler with I/O (still need E/A)
*---------------------------------------------------------------
   
* Start of Decoder

    ORG    $1000    ; Memory Adress where this program is stored
    
START:                  ; first instruction of program

**** I/O ****  

*-----------------------------------------------------------
* Initialize
* Description: initializes pointers and buffers
* A0 Program reading pointer
* A1 Buffer pointer
* D2 Input start address
* D3 Input end address
* D4 Flag indicates if code is good (1) or bad (0)

* D0 Stores trap tasks 0-14
* D1 trap reads or stores numbers/characters (task 3,4,5,6,7,8,11,12)
* A1 trap reads or stores strings (task# 0,1,2,13,14)

* D5 and D6 are free to use
* A2, A3, A4, A5 and A6 are free to use
*-----------------------------------------------------------

*-----------------------------------------------------------
* Start Prompts
* Description: Loads when program begins, describes good
* address range, prompts user for start and end addresses
*-----------------------------------------------------------

                MOVEA.L #0,A1               ;clear register 
                LEA     INTRO,A1            ;load start message
                MOVE.B  #14,D0              ;load command for trap to display string 
                TRAP    #15                 ;display start message
startadr_in:     
                MOVEA.L #0,A1               ;clear register 
                LEA     STARTADR_MSG,A1     ;load start address message
                MOVE.B  #14,D0              ;load command for trap to display string
                TRAP    #15                 ;display start address message
                CLR.L   D0
                
                LEA     INPUT_DISCLAIMER, A1 ; load input disclaimer message
                MOVE.B  #14, D0
                TRAP    #15
                CLR.L   D0
                
                MOVEA.L #0,A1               ;clear register 
                LEA     STARTADR,A1         ;load address in A1 to store staring address
                CLR.B   (A1)                ; clear the memory where starting address will be stored
                CLR.L   D1                  ;input length will be auto stored here
                MOVE.B  #2,D0               ;load command for trap to read data input
                TRAP    #15                 ;read start address from keyboard, stores at memlocation STARTADR
                CLR.L   D0
                JSR     valid_input         ;validate start address
                JSR     convert2hex         ;convert ascii input to hex
                MOVE.L  D0,D2               ;starting address hex value is moved to be stored longterm in D2
                CLR     D0
                MOVE.L  D2, D5              ; is_even checks the address in D5
                JSR     is_even             ;even address check

endadR_in:      
                MOVEA.L #0,A1               ;clear register 
                LEA     ENDADR_MSG,A1       ;load end address message
                MOVE.B  #14,D0              ;load command for trap to display string
                TRAP    #15                 ;display end address message
                CLR     D0
                
                LEA     INPUT_DISCLAIMER, A1 ; load input disclaimer message
                MOVE.B  #14, D0
                TRAP    #15
                CLR     D0
                
                MOVEA.L #0,A1               ;clear register 
                LEA     ENDADR,A1           ;load address in A1 to store ending address
                CLR     D1                  ;input length will be auto stored here
                MOVE.B  #2,D0               ;load command for trap to read data input
                TRAP    #15                 ;read start address from keyboard, stores at memlocation ENDADR
                CLR     D0
                JSR     valid_input         ;validate end address
                JSR     convert2hex         ;convert ascii input to hex
                MOVE.L  D0,D3               ;ending address hex value is moved to be stored longterm in D3
                MOVE.L  D3, D5              ; is_even checks the address in D5
                JSR     is_even             ;even address check
                
start_lt_end:
                * have to check that the start address is less than the ending address *
                * start address is in D2, end address is in D3 *
                
                * valid, call OpCode to start decoding *
                * Opcode needs the start address loaded into A3, end address loaded into A2
                * and current address (start address loaded into A0)
                
                MOVE.L D2, A3 * moves start address into A3
                MOVE.L D2, A0 * moves start address into A0
                MOVE.L D3, A2 * moves end address into A2
    
    MOVE.L #0, D7 * sets line on page counter to 0
    
    LEA START_DISASSEMBLING, A1
    JSR PRINT_VAR * prints START_DISASSEMBLING message
    
    BRA OPCODE * decode first 16 bit instruction

*-----------------------------------------------------------
* Address Validation
* Description: Check user input. 
* If out of range or > 8 character or not even number, 
* repeat start/end address prompt
*-----------------------------------------------------------
valid_input:    
                CLR.L   D5                  ;clear register
                MOVE.B  (A1),D5             ;load input address into D5
                CMP     #0,D1               ;input length stored in D1, cmp if $00
                BEQ.S   if_bad              ;no entry if it's $00
                CLR.L   D5                  ;clear register again, needed for hex conversion subroutine
                RTS 
is_even:                
                DIVU    #2,D5               ;divide address by 2
                SWAP    D5                  ;switch remainder to LSB  
                CMP.B   #$0,D5              ;it's even if remainder = 0
                BGT.S   if_bad              ;if remainer > 0 == odd, branch
                RTS                         ;else it's good, return
if_bad:
                LEA     STARTADR,A1         ;reset pointer to make sure it erases all previous input data
                MOVEA.L #0,A1               ;clear register 
                LEA     INVALID_MSG,A1
                MOVE.B  #14,D0              ;load command for trap to display string
                TRAP    #15                 ;display invalid message
                JSR     reset               ;reset registers
                JMP     startadr_in         ;restart prompt for input
reset:      
                CLR.L   D0                  ;clears all registers
                CLR.L   D1
                CLR.L   D2
                CLR.L   D3
                CLR.L   D4
                CLR.L   D5
                CLR.L   D6
                MOVEA.L #0,A0
                MOVEA.L #0,A1
                MOVEA.L #0,A2
                RTS

*-----------------------------------------------------------
* ASCII ==> Hex Convertion
* Description: converts user input from ascii to hex
* ascii numbers start at hex $30 - $39, valid uppercase 
* letters at $41 - $46, valid lowercase letters at $61 - $66
* out of that range is invalid input
*-----------------------------------------------------------
convert2hex:     
                MOVE.B  (A1)+,D5            ;load msb to lsb into D5 and move pointer forward
                CMP.B   #$30,D5             ;is ascii number D5 < 30?
                BLT     if_bad              ;input ascii not valid
                
                CMP.B   #$39,D5             ;is ascii number D5 <= 39?
                BLE     number_convert      ;input is number
                
                CMP.B   #$41,D5             ;is ascii number D5 < 41?
                BLT     if_bad              ;input ascii not valid

                CMP.B   #$46,D5             ;is ascii number D5 <= 46?
                BLE     upper_convert       ;input is uppercase hex letter
              
                CMP.B   #$46,D5             ;is ascii number D5 > 46?
                BGT     if_bad              ;input ascii not valid
                
number_convert: 
                SUB.B   #$30,D5             ;range adjust for number hex value
                JMP     done_or_shift       ;jump to check if end is reached or shift nums to left
upper_convert: 
                SUB.B   #$37,D5             ;range adjust for uppercase hex value
                JMP     done_or_shift       ;jump to check if end is reached or shift nums to left
                
done_or_shift:  
                ADD.B   D5,D0               ;append next number to D0
                CMP.B   #$00,(A1)           ;if A1 points to byte $00, no more num to convert
                BEQ.S   return2sub          ;use utility method to return to address input section
                LSL.L   #4,D0               ;else shift current bytes in D0 over to make room for next number                                        
                JMP     convert2hex         ;move on to next number 
return2sub:      
                RTS                         ;utility to return to calling subroutine when conversion is done

IO_PAGE:
    
    ADD.W #1, D7 * increment line counter on page
    
    * if page counter is > 19, wait for user to display enter before proceeding to call opcode 
    CMP.W #19, D7 * check if page counter is greater than 20
    BGT WAIT_FOR_ENTER * if it is, wait for the user to hit enter before displaying the next opcode

    * else go straight to next opcode
    BRA OPCODE
    
WAIT_FOR_ENTER:

    * display message to see next page of memory decoded
    LEA NEXT_PAGE, A1
    JSR PRINT_VAR * prints NEXT_PAGE message to output
    
    * wait for enter
    MOVE.B  #2,D0               ;load command for trap to read data input
    TRAP    #15     * call trap task 2
    
    * Disassembled memory message
    LEA START_DISASSEMBLING, A1
    JSR PRINT_VAR * prints disassembled memory message
    
    * CLR.L (A1) * clear A1 (changed by trap task 2)
    CLR.L D1 * clear D1 (changed by trap task 2)
    
    CLR.L D7 * reset line counter to 0

    * after enter go to next opcode
    BRA OPCODE

IO_INVALID:
* Display DATA YYYY
    
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
    
    BGT IO_PAGE * if memory address pointer is still less than the ending memory address, 
               * check if the user needs another page before decoding the next 16 bits
               * (this was BGT OPCODE)
    
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
    
    CLR.L D2
    
    * Display 'XXXX XXXX' (Address of current instruction)
    * Move the first XXXX word of the address into D4
    MOVE.L A0, D4
    ROL.L #8, D4 * shift the first word left 8 bits
    ROL.L #8, D4 * shift the first word left another 8 bits for a total 16 bits
    AND.L #$0000FFFF, D4 * mask the second word 
    
    * Output the word loaded in D4
    JSR OUTPUT_WORD
    
    * Move the second XXXX word of the address into D4
    MOVE.W A0, D4
   
    * Output the word loaded in D4
    JSR OUTPUT_WORD
    
    JSR PRINTSPACE * Output ' '
    
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
        
    * isolate destination mode (bits 8-6)
    JSR RELOAD_INSTRUCTION * reloads the 16 bit instruction into D2
    DIVU.W #64, D2 * divide to isolate the destination mode
    AND.L #$00000007, D2 * mask the division remainder
        
    CMP.B #1, D2
    BEQ MOVEA * MOVEA has bits 8-6 as 001, MOVE does not allow 001 as a destination mode
    
    BRA MOVE * else it's MOVE
        
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
     
    * 1X00 1 -> MOVEM ( so either 1100 1, or 1000 1) (shifted is 1 1001 or 1 0001)
    DIVU.W #128, D2 * divide by 128 to shift 7 bits
    AND.L #$0000001F, D2 * mask the division remainder and the first 4 bits of the instruction
    
    CMP.W #$0011, D2 * 1 0001
    BEQ MOVEM
    
    CMP.W #$0019, D2 * 1 1001
    BEQ MOVEM
            
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
    BEQ OR_LEFT * E/A is source operand

    CMP.W #1, D2 * check for opmode 001
    BEQ OR_LEFT * E/A is source operand
    
    CMP.W #2, D2 * check for opmode 010
    BEQ OR_LEFT * E/A is source operand
    
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
    BEQ ADD_LEFT * E/A is left operand (source)
    
    CMP.W #1, D2 * check for opmode 001
    BEQ ADD_LEFT * E/A is left operand (source)

    CMP.W #2, D2 * check for opmode 010
    BEQ ADD_LEFT * E/A is left operand (source)
    
    CMP.W #3, D2 * check for opmode 011
    BEQ ADDA
    
    CMP.W #4, D2 * check for opmmode 100
    BEQ ADD_RIGHT * E/A is right operand (destination)
    
    CMP.W #5, D2 * check for opmode 101
    BEQ ADD_RIGHT * E/A is right operand (destination)
    
    CMP.W #6, D2 * check for opmode 110
    BEQ ADD_RIGHT * E/A is right operand (destination)
    
    CMP.W #7, D2 * check for opmode 111
    BEQ ADDA
    
    * if not ADDA, ADD
    BRA IO_INVALID * shouldn't happen
    
* 1110 for first 4 bits *
FOURTEEN:    
    * one of the shifts (LSL, LSR, ASL, ASR, ROL, ROR) depending on later bits
    
    * check bits 6-7 -> [11] for memory shifts [00, 01, or 10] for register shifts
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    DIVU.W #64, D2 * divide the instruction to isolate the size/[11] bits
    AND.L #$00000003, D2 * mask the division remainder and the first 8 bits of instruction
    
    CMP.B #0, D2
    BEQ REGISTER_SHIFT
    
    CMP.B #1, D2
    BEQ REGISTER_SHIFT
    
    CMP.B #2, D2
    BEQ REGISTER_SHIFT
    
    CMP.B #3, D2
    BEQ MEMORY_SHIFT
    
    * if none of the shifts
    BRA IO_INVALID * shouldn't be possible to get here

* 1111 for first 4 bits *
FIFTEEN:
* Call I/O for invalid (none of the instructions to implement start this way) 
    BRA IO_INVALID

MOVE:
    
    * check if size is valid *
    JSR RELOAD_INSTRUCTION * reload the 16 bit instruction into D2
    DIVU.W #$1000, D2 * divide the instruction to isolate the size
    AND.L #$00000003, D2 * mask the division remainder
    
    CMP.B #0, D2
    BEQ IO_INVALID * the only invalid size is 00
    
    * call E/A to get effective Address for Source E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP1 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
    * call E/A to get effective Address of Destination E/A *
    CLR.L D3 * fancy bit shifting, to get mode and register realigned *
    MOVE.W (A0), D3 * copy instruction into D3
    MOVE.W (A0), D4 * copy instruction into D4
    ROR.L #3, D3 * rotate right 3 bits to get mode into mode position
    AND.L #$000000E0, D3 * mask everything except mode 
    DIVU.W #512, D4 * divide D4 to get register in last 3 bits
    AND.L #$00000007, D4 * mask everything in D4 except register
    ADD.W D4, D3 * put register into D3 with mode
    
    JSR EA_GROUP3 * D6 will be set to 1 if valid, 0 if invalid
    
    CMP.B #0, D6  * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
    * print MOVE *
    LEA MOVE_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (MOVE)
    
    * print size *
    JSR RELOAD_INSTRUCTION * reload the 16 bit instruction into D2
    DIVU.W #$1000, D2 * divide the instruction to isolate the size
    AND.L #$00000003, D2 * mask the division remainder
    
    JSR MOVESIZE * prints the size (.B, .W, or .L)
    
    JSR PRINTSPACE * print space *
    
    * print source E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print destination E/A *
    CLR.L D3 * fancy bit shifting, to get mode and register realigned *
    MOVE.W (A0), D3 * copy instruction into D3
    MOVE.W (A0), D4 * copy instruction into D4
    ROR.L #3, D3 * rotate right 3 bits to get mode into mode position
    AND.L #$000000E0, D3 * mask everything except mode 
    DIVU.W #512, D4 * divide D4 to get register in last 3 bits
    AND.L #$00000007, D4 * mask everything in D4 except register
    ADD.W D4, D3 * put register into D3 with mode
    
    JSR PRINT_EA
    
    * Use A5 to store the incremented address pointer
    * add standard 16 bit increment + source E/A increment + dest E/A increment *
    
    * Increment address pointer *
    JSR INCR_ADDRESS
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

MOVEA:

    * check if size is valid *
    JSR RELOAD_INSTRUCTION * reload the 16 bit instruction into D2
    DIVU.W #$1000, D2 * divide the instruction to isolate the size
    AND.L #$00000003, D2 * mask the division remainder
    
    CMP.B #0, D2
    BEQ IO_INVALID * size 00 is invalid
    
    CMP.B #1, D2 
    BEQ IO_INVALID * size 01 is invalid
    
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP1 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * print MOVEA *
    LEA MOVEA_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (MOVEA)
    
    JSR MOVESIZE (prints .W, or .L for the size)
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print address register *
    JSR RELOAD_INSTRUCTION * reload the 16 bit instruction into D2
    DIVU.W #512, D2 * divide to isolate the destination register
    AND.L #$00000007, D2 * mask the division remainder
    
    JSR PRINTADDRESSREGISTER * prints the address register number in D2
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID
   
MEMORY_SHIFT:
    * one of the shifts (LSL, LSR, ASL, ASR, ROL, ROR) specified with a single E/A
        
    * check next 3 bits after first 4 bits
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 * divide instruction by 512
    AND.L #$00000007, D2 * mask division remainder
    
    * 3 bits are 001 -> LSL/LSR *
    CMP.W #1, D2
    BEQ LS_MEM
    
    * 3 bits are 000 -> ASL/ASR *
    CMP.W #0, D2
    BEQ AS_MEM
    
    * 3 bits are 011 -> ROL/ROR *
    CMP.W #3, D2
    BEQ RO_MEM
    
    BRA IO_INVALID * if none of the shifts (bits 12-10 are something other than 001, 000, 011)
    
LS_MEM:
    * either LSL or LSR (memory shift) depending on direction bit *
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #256, D2 * divide instruction by 256 to isolate the direction bit
    AND.L #$00000001, D2 * mask division remainder
    
    CMP.W #0, D2
    BEQ LSR_MEM
    
    CMP.W #1, D2
    BEQ LSL_MEM
    
    BRA IO_INVALID * this shouldn't be possible
    
LSL_MEM:
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP7 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
    * prints LSL *
    LEA LSL_OUT, A1
    JSR PRINT_VAR * prints the last thing loaded into A1 (LSL)
    
    * print word (only size available to memory shifts) *
    JSR PRINTWORD
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer
    JSR INCR_ADDRESS

    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

LSR_MEM:
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP7 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * prints LSR *
    LEA LSR_OUT, A1
    JSR PRINT_VAR * prints the last thing loaded into A1 (LSR)
    
    * print word (only size available to memory shifts) *
    JSR PRINTWORD
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

AS_MEM:
    * either ASL or ASL (memory shift) depending on direction bit *
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #256, D2 * divide instruction by 256 to isolate the direction bit
    AND.L #$00000001, D2 * mask division remainder
    
    CMP.W #0, D2
    BEQ ASR_MEM
    
    CMP.W #1, D2
    BEQ ASL_MEM
    
    BRA IO_INVALID * this shouldn't be possible
    
ASL_MEM:
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP7 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * print ASL *
    LEA ASL_OUT, A1
    JSR PRINT_VAR * prints the last thing loaded into A1 (ASL)
    
    * print word (only size available to memory shifts) *
    JSR PRINTWORD
    
    * print space * 
    JSR PRINTSPACE
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID
    
ASR_MEM:
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP7 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * print ASR *
    LEA ASR_OUT, A1
    JSR PRINT_VAR * prints the last thing loaded into A1 (ASR)
    
    * print word (only size available to memory shifts *
    JSR PRINTWORD
    
    * print space *
    JSR PRINTSPACE
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID
        
RO_MEM:
    * either ROL or ROR (memory shift) depending on direction bit *
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #256, D2 * divide instruction by 256 to isolate the direction bit
    AND.L #$00000001, D2 * mask division remainder
    
    CMP.W #0, D2
    BEQ ROR_MEM
    
    CMP.W #1, D2
    BEQ ROL_MEM
    
    BRA IO_INVALID * this shouldn't be possible
    
ROL_MEM:
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP7 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * print ROL *
    LEA ROL_OUT, A1
    JSR PRINT_VAR * prints the last thing loaded into A1 (ROL)
    
    * print word (only size available to memory shifts *
    JSR PRINTWORD
    
    * print space *
    JSR PRINTSPACE
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer
    JSR INCR_ADDRESS

    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID
        
ROR_MEM:
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP7 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * print ROR *
    LEA ROR_OUT, A1
    JSR PRINT_VAR * prints the last thing loaded into A1 (ROR)
    
    * print word (only size available to memory shifts *
    JSR PRINTWORD
    
    * print space *
    JSR PRINTSPACE
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID
        
REGISTER_SHIFT:
    * one of the shifts (LSL, LSR, ASL, ASR, ROL, ROR) specified with either immediate #count, or a Data register
        
    * check bits 4-3, next to the register
        * 01 is LSL/LSR, 00 is ASL/ASR, 11 is ROL/ROR
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #8, D2 * divide instruction by 512
    AND.L #$00000003, D2 * mask division remainder
    
    CMP.B #0, D2
    BEQ AS_REG
    
    CMP.B #1, D2
    BEQ LS_REG
    
    CMP.B #3, D2
    BEQ RO_REG
    
    BRA IO_INVALID * if none of the shifts (bits 4-3 are 10)

LS_REG:
    * if size is 11, call IO_INVALID *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide instruction by 64 to isolate the size
    AND.L #$00000003, D2 * mask division remainder and first 8 bits of instruction
    
    CMP.W #3, D2
    BEQ IO_INVALID * size is 11 which is not allowed
    
    * check direction *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #256, D2 * divide instruction by 256 to isolate the direction bit
    AND.L #$00000001, D2 * mask division remainder
    
    CMP.W #1, D2
    BEQ LSL_REG
    
    CMP.W #0, D2
    BEQ LSR_REG
    
    BRA IO_INVALID * this shouldn't be possible

LSL_REG:
    * print LSL *
    LEA LSL_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (LSL)

    * print Size *   
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide instruction by 64 to isolate the size
    AND.L #$00000003, D2 * mask division remainder and first 8 bits of instruction
    JSR TWOBITSIZE * prints the size where 00 is .B 01 is .W and 10 is .L 

    JSR PRINTSPACE * print space *

    * check register or count *
    JSR COUNT_OR_REGISTER
    
    * Increment address pointer
    JSR INCR_ADDRESS

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

LSR_REG:
    * print LSR *
    LEA LSR_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (LSR)
    
    * print Size *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide instruction by 64 to isolate the size
    AND.L #$00000003, D2 * mask division remainder and first 8 bits of instruction
    JSR TWOBITSIZE * prints the size where 00 is .B 01 is .W and 10 is .L

    JSR PRINTSPACE * print space *

    * check register or count *
    JSR COUNT_OR_REGISTER
    
    * Increment address pointer
    JSR INCR_ADDRESS

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

AS_REG:
    * if size is 11, call IO_INVALID *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide instruction by 64 to isolate the size
    AND.L #$00000003, D2 * mask division remainder and first 8 bits of instruction
    
    CMP.W #3, D2
    BEQ IO_INVALID * size is 11 which is not allowed
    
    * check direction *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #256, D2 * divide instruction by 256 to isolate the direction bit
    AND.L #$00000001, D2 * mask division remainder
    
    CMP.W #1, D2
    BEQ ASL_REG
    
    CMP.W #0, D2
    BEQ ASR_REG
    
    BRA IO_INVALID * this shouldn't be possible

ASL_REG:
    * print ASL *
    LEA ASL_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (ASL)
    
    * print Size *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide instruction by 64 to isolate the size
    AND.L #$00000003, D2 * mask division remainder and first 8 bits of instruction
    JSR TWOBITSIZE * prints the size where 00 is .B 01 is .W and 10 is .L

    JSR PRINTSPACE * print space *

    * check register or count *
    JSR COUNT_OR_REGISTER
    
    * Increment address pointer
    JSR INCR_ADDRESS

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

ASR_REG:
    * print ASR *
    LEA ASR_OUT, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (ASR)
    
    * print Size *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide instruction by 64 to isolate the size
    AND.L #$00000003, D2 * mask division remainder and first 8 bits of instruction
    JSR TWOBITSIZE * prints the size where 00 is .B 01 is .W and 10 is .L

    JSR PRINTSPACE * print space *

    * check register or count *
    JSR COUNT_OR_REGISTER
    
    * Increment address pointer
    JSR INCR_ADDRESS

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID
    
RO_REG:
    * if size is 11 call IO_INVALID *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide instruction by 64 to isolate the size
    AND.L #$00000003, D2 * mask division remainder and first 8 bits of instruction
    
    CMP.W #3, D2
    BEQ IO_INVALID * size is 11 which is not allowed
    
    * check direction *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #256, D2 * divide instruction by 256 to isolate the direction bit
    AND.L #$00000001, D2 * mask division remainder
    
    CMP.W #1, D2
    BEQ ROL_REG
    
    CMP.W #0, D2
    BEQ ROR_REG
    
    BRA IO_INVALID * this shouldn't be possible
    
ROL_REG:
    * print ROL *
    LEA ROL_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (ROL)
    
    * print Size *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide instruction by 64 to isolate the size
    AND.L #$00000003, D2 * mask division remainder and first 8 bits of instruction
    JSR TWOBITSIZE * prints the size where 00 is .B 01 is .W and 10 is .L
    
    JSR PRINTSPACE * print space *
    
    * check register or count *
    JSR COUNT_OR_REGISTER

    * Increment address pointer
    JSR INCR_ADDRESS

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

ROR_REG:
    * print ROR *
    LEA ROR_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (ROR)
    
    * print Size *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide instruction by 64 to isolate the size
    AND.L #$00000003, D2 * mask division remainder and first 8 bits of instruction
    JSR TWOBITSIZE * prints the size where 00 is .B 01 is .W and 10 is .L
    
    JSR PRINTSPACE * print space *
    
    * check register or count *
    JSR COUNT_OR_REGISTER
    
    * Increment address pointer
    JSR INCR_ADDRESS

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

COUNT_OR_REGISTER:
    * check the count/register bit
    JSR RELOAD_INSTRUCTION
    DIVU.W #32, D2 * divide instruction by 32 to isolate the count/register bit
    AND.L #$00000001, D2 * mask division remainder
    
    CMP.B #0, D2
    BEQ REG_COUNT
    
    CMP.B #1, D2
    BEQ REG_REG

    RTS * return, shouldn't be able to reach here *

REG_REG:
    * print the first data register *
    JSR RELOAD_INSTRUCTION
    DIVU.W #512, D2 * isolate the first data register in D2
    AND.L #$00000007, D2 * mask the division remainder and the first 4 bits of instruction
    
    JSR PRINT_DATA_REGISTER
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print the second data register *
    JSR RELOAD_INSTRUCTION
    AND.L #$00000007, D2 * mask the first 13 bits of instruction to isolate the second data register
    
    JSR PRINT_DATA_REGISTER
    
    RTS * return *

REG_COUNT:
    
    * print the immediate data count *
    JSR RELOAD_INSTRUCTION
    DIVU.W #512, D2 * isolate the immediate data count in D2
    AND.L #$00000007, D2 * mask the division remainder and the first 4 bits of instruction
    
    JSR PRINT_IDATA
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print the data register *
    JSR RELOAD_INSTRUCTION
    AND.L #$00000007, D2 * mask the first 13 bits of instruction to isolate the data register
    
    JSR PRINT_DATA_REGISTER
    
    RTS * return *

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
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP2 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * print MULS *
    LEA MULS_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (MULS)
        
    * print .W (since Word is the only valid size of MULS) *
    JSR PRINTWORD * prints .W
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *

    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER

    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3

    * Increment address pointer
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

DIVS:
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP2 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * print DIVS *
    LEA DIVS_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (DIVS)
    
    * print .W (since Word is the only valid size for DIVS) *
    JSR PRINTWORD * prints .W

    JSR PRINTSPACE * print space *

    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER

    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3

    * Increment address pointer by 16 bits (2 bytes)
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

NEG:

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP3 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID

    * isolate size field 
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #64, D2 * divide by 64 to bit shift right 6 bits
    AND.L #$00000003, D2 * mask the divison remainder and the opcode bits
    
    CMP.W #3, D2 * if size is 11, it's invalid
    BEQ IO_INVALID
    
    LEA NEG_OUT, A1 * Load NEG to the Buffer
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    JSR TWOBITSIZE * call the 2 bit size function
    
    JSR PRINTSPACE * print space *
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA

    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3

    JSR INCR_ADDRESS * Increment address pointer by 16 bits (2 bytes)
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
* Call I/O to output a line return 
    LEA SPACE, A1
    BRA IO_VALID

JSR:
    
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP8 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
    LEA JSR_OUT, A1 * load JSR to A1
    JSR PRINT_VAR * print JSR to output
    
    JSR PRINTSPACE * print a space
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    JSR INCR_ADDRESS * Increment address pointer by 16 bits (2 bytes)
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * print a line return *
    LEA SPACE, A1
    BRA IO_VALID * Call I/O to output

LEA:

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP8 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    LEA LEA_OUT, A1 * load LEA to A1
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    JSR PRINTSPACE * print space
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * display a comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last thing loaded into A1
    
    JSR PRINTSPACE * display a space *
    
    JSR RELOAD_INSTRUCTION MOVE.W ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 * divide to shift the register bits all the way to the right
    AND.L #$0000007, D2 * mask division remainder and all bits except register number
    
    JSR PRINTADDRESSREGISTER * prints the address register # stored in D2
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    JSR INCR_ADDRESS * Increment address pointer by 16 bits (2 bytes)
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * print a line return *
    LEA SPACE, A1
    BRA IO_VALID

BCS:
    
    * load BCS to output *
    LEA BCS_OUT, A1
    JSR PRINT_VAR * prints BCS to output
    
    JSR PRINTSPACE * prints a space
    
    JSR PRINTDISPLACEMENT * prints displacement
    
    JSR BRANCHDISPLACEMENT * increments address pointer to next instruction by the appropriate amount
    
    * print a line return *
    LEA SPACE, A1
    BRA IO_VALID

BGE:
    
    * load BGE to output *
    LEA BGE_OUT, A1
    JSR PRINT_VAR * prints BGE to output
    
    JSR PRINTSPACE * prints a space
    
    JSR PRINTDISPLACEMENT * prints displacement
    
    JSR BRANCHDISPLACEMENT * increments address pointer to next instruction by the appropriate amount
    
    * print a line return *
    LEA SPACE, A1
    BRA IO_VALID
    
BLT:

    * load BLT to output *
    LEA BLT_OUT, A1
    JSR PRINT_VAR * prints BLT to output
    
    JSR PRINTSPACE * print a space
    
    JSR PRINTDISPLACEMENT * prints displacement
    
    JSR BRANCHDISPLACEMENT * increments address pointer to next instruction by the appropriate amount
    
    * print a line return *
    LEA SPACE, A1
    BRA IO_VALID

BVC:
    
    * load BVC to output *
    LEA BVC_OUT, A1
    JSR PRINT_VAR * prints BVC to output
    
    JSR PRINTSPACE * print a space
    
    JSR PRINTDISPLACEMENT * prints displacement
    
    JSR BRANCHDISPLACEMENT * increments address pointer to next instruction by the appropriate amount
    
    * print a line return *
    LEA SPACE, A1
    BRA IO_VALID

BRA:
    
    * load BRA to output *
    LEA BRA_OUT, A1
    JSR PRINT_VAR * prints BRA to output
    
    JSR PRINTSPACE * print a space
    
    JSR PRINTDISPLACEMENT * prints displacement
    
    JSR BRANCHDISPLACEMENT * increments address pointer to next instruction by the appropriate amount
    
    * print a line return *
    LEA SPACE, A1
    BRA IO_VALID

PRINTDISPLACEMENT:
* for the opcodes BCS, BGE, BLT, BVC, and BRA, (the Bcc opcodes), *

    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    AND.W #$00FF, D2 * mask the first 8 bits of instruction to leave the 8 bit displacement
    
    CMP.B #$00, D2     * check 8 bit displacement = $00
    BEQ PRINT_16_DISPLACE          * if yes, print the 16 bit displacement (4 bytes)
    
    CMP.B #$FF, D2     * check if 8 bit displacement = $FF
    BEQ PRINT_32_DISPLACE          * if yes, print the 32 bit displacement (6 bytes)
        
    * else increment by 16 bits (2 bytes)
    BRA PRINT_8_DISPLACE * Increment address pointer by 16 bits (2 bytes)
    
PRINT_16_DISPLACE:
* print the amount of displacement *

    * displacement is in 32 bits after instruction at A0
    MOVEA.L A0, A6 * copy A0 into A6
    ADD.W #2, A6 * adds 2 bytes to A6, so pointer is pointing at displacement

    CLR.L D1 * clear D1
    MOVE.W (A6), D1 * copy the displacement into D1

    MOVE.B #3, D0 * move task 3 into trap task
    TRAP #15 * trap 15

    RTS * return *

PRINT_32_DISPLACE:
* prints the amount of displacement *

    * displacement is in 16 bits after instruction at A0
    MOVEA.L A0, A6 * copy A0 into A6
    ADD.W #2, A6 * adds 2 bytes to A6, so pointer is pointing at displacement
    
    CLR.L D1 * clear D1
    MOVE.L (A6), D1 * copy the displacement into D1
    
    MOVE.B #3, D0 * move task 3 into trap task
    TRAP #15 * trap 15

    RTS * return *

PRINT_8_DISPLACE:
* prints the amount of displacement *

    * displacement is in last 8 bits of instruction at A0
    CLR.L D1 * clear D1
    MOVE.B (A0), D1 * copy the displacement into D1
    
    MOVE.B #3, D0 * move task 3 into trap task
    TRAP #15 * trap 15

    RTS * return *

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
    * check direction * 
    
    JSR RELOAD_INSTRUCTION * reloads the first 16 bits of instruction to D2 *
    DIVU.W #1024, D2
    AND.L #$00000001, D2 * mask the division remainder
    
    CMP.B #0, D2
    BEQ MOVEM_REG_TO_MEM
    
    CMP.B #1, D2
    BEQ MOVEM_MEM_TO_REG

    BRA IO_INVALID * shouldn't be able to reach here
    
MOVEMSIZE:
    
    JSR RELOAD_INSTRUCTION * reloads the first 16 bits of instruction to D2 *
    DIVU.W #64, D2 * divide by 64 to isolate the size bit
    AND.L #$00000001, D2 * mask the division remainder
    
    CMP.B #0, D2
    BEQ PRINTWORD
    
    CMP.B #1, D2
    BEQ PRINTLONG
    
    RTS * return, shouldn't ever get here *
    
MOVEM_REG_TO_MEM:

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP4 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
    * print MOVEM *
    LEA MOVEM_OUT, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (MOVEM) *
    
    * print size *
    JSR MOVEMSIZE
    
    JSR PRINTSPACE * print space *

    * print registers *
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last thing loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA

    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3

    * Increment address pointer by 32 bits (4 bytes)
    JSR INC32
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

MOVEM_MEM_TO_REG:
    
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP5 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
    * print MOVEM *
    LEA MOVEM_OUT, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (MOVEM) *
    
    * print size *
    JSR MOVEMSIZE
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (comma) *

    JSR PRINTSPACE * print space *

    * print registers *

    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3

    * Increment address pointer by 32 bits (4 bytes)
    JSR INC32
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID
    
CMP:
    * Opmode is loaded into D2 *
    
    * Call E/A to get effective address *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP1 * D6 will be set to 1 if valid, 0 if invalid
    
    CMP.B #0, D6 * if E/A not valid call IO_INVALID *
    BEQ IO_INVALID     
   
    * print CMP *
    LEA CMP_OUT, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (CMP)
    
    * print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment Address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

EOR:
    * Opmode is loaded into D2 *

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP3 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
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
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

OR_LEFT:
    * Opmode is loaded into D2 *

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP2 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * Print OR *
    LEA OR_OUT, A1
    JSR PRINT_VAR * print the last thing loaded into A1 (OR)
    
    * print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space *
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID
    
OR_RIGHT:
    * Opmode is loaded into D2 *

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP7 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
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
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

ADD_LEFT:
    * Opmode is loaded into D2 *
    
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP1 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
    * Print ADD *
    LEA ADD_OUT, A1
    JSR PRINT_VAR * print the last var loaded into A1 (ADD)
    
    * Print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3    
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

ADD_RIGHT:
    * Opmode is loaded into D2 *
    
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP7 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID

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
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

SUB_LEFT:
    * Opmode is loaded into D2 *

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP1 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
    * Print SUB *
    LEA SUB_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (SUB)
    
    * Print size based on opmode *
    JSR THREE_BIT_OPMODE
    
    JSR PRINTSPACE * print space

    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * print the last var loaded into A1 (comma)
    
    JSR PRINTSPACE * print space
    
    * print Data register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the data register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINT_DATA_REGISTER * call to PRINT_DATA_REGISTER
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

SUB_RIGHT:
    * Opmode is loaded into D2 *

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP7 * D6 will be set to 1 if valid, 0 if invalid
   
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
   
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
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

SUBQ:

    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP6 * D6 will be set to 1 if valid, 0 if invalid
        
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID    
    
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
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer by 16 bits (2 bytes) *
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output *
    LEA SPACE, A1
    BRA IO_VALID

ORI:
    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP3 * D6 will be set to 1 if valid, 0 if invalid
    
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
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
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * increment address pointer by either 32 bits or 48 bits *
    JSR INCR_32_OR_48
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
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

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP3 * D6 will be set to 1 if valid, 0 if invalid
    
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
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
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * increment address pointer by 32 bits or 48 bits depending on size *
    JSR INCR_32_OR_48
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
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
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP3 * D6 will be set to 1 if valid, 0 if invalid
    
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
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
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA

    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3

    * Increment address pointer by 32 bits (4 bytes) *
    JSR INC32
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE
    
    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

BCLR_DYNAMIC:

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR EA_GROUP3 * D6 will be set to 1 if valid, 0 if invalid
    
    CMP.B #0, D6   * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
        
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
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA

    * reset D3 before incrementing Address pointer
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3

    * Increment address pointer by 16 bits
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID

ADDA:
* opmode is loaded into D2 (either 011 for Word, or 111 for Long) *

    * Call E/A to get effective addresses
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy the instruction to D3
    JSR EA_GROUP1 * D6 will be set to 1 if valid, 0 if invalid
    
    CMP.B #0, D6    * If E/A not valid call IO_INVALID
    BEQ IO_INVALID
    
    * print ADDA *
    LEA ADDA_OUT, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (ADDA)
    
    * print size *
    JSR ADDA_SIZE
    
    JSR PRINTSPACE * print space *
    
    * print E/A *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    JSR PRINT_EA
    
    * print comma *
    LEA COMMA, A1
    JSR PRINT_VAR * prints the last var loaded to A1 (comma)
    
    JSR PRINTSPACE * print space
    
    * print address Register *
    JSR RELOAD_INSTRUCTION ; reload the first 16 bits of instruction to D2
    DIVU.W #512, D2 ; divide to isolate the address register
    AND.L #$00000007, D2 ; mask the division remainder
    JSR PRINTADDRESSREGISTER * call to PRINTADDRESSREGISTER
    
    * reset D3 before incrementing Address pointer *
    CLR.L D3 * clear D3
    MOVE.W (A0), D3 * copy instruction into D3
    
    * Increment address pointer by 16 bits
    JSR INCR_ADDRESS
    
    * Increment more if E/A has trailing DATA *
    JSR EA_INCREMENT_MORE

    * Call I/O to output
    LEA SPACE, A1
    BRA IO_VALID


ADDA_SIZE:
    * opmode is loaded into D2 *
    
    CMP.W #7, D2 * check if opmode is 111 *
    BEQ PRINTLONG
    
    CMP.W #3, D2 * chck if opmode is 011 *
    BEQ PRINTWORD
    
    RTS * return, only would be able to get here if size is invalid *

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

    CMP #1, D2 * check if the size is a byte *
    BEQ PRINTBYTE
    
    CMP #2, D2 * check if the size is a long *
    BEQ PRINTLONG
    
    CMP #3, D2 * check if the size is a word *
    BEQ PRINTWORD

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

EA_GROUP1: * always call with JSR, since returns with RTS *
* checks if the 6 bit E/A in [mode] [reg] order in D3 is valid, sets D6 to 1 if valid, 0 if invalid *
* all E/A modes are valid *
* called from the opcodes MOVE (src), MOVEA, ADD (left is E/A), SUB (left is E/A), ADDA, CMP *

    JSR SET_EA_INVALID * initialize valid/invalid flag to 0 *

    JSR IS_DN * checks if the E/A is Dn, sets D6 to 1 if valid *

    JSR IS_AN * checks if the E/A is An, sets D6 to 1 if valid *
    
    JSR IS_AN_INDIRECT * checks if the E/A is (An), sets D6 to 1 if valid *
    
    JSR IS_AN_INC * checks if the E/A is (An)+ , sets D6 to 1 if valid *
    
    JSR IS_AN_DEC * checks if the E/A is -(SP), sets D6 to 1 if valid *
    
    JSR IS_WORD * checks if the E/A is (xxx).W, sets D6 to 1 if valid *
    
    JSR IS_LONG * checks if the E/A is (xxx).L, sets D6 to 1 if valid *
    
    JSR IS_IMMEDIATE * checks if the E/A is #<data>, sets D6 to 1 if valid *

    RTS * return *

EA_GROUP2: * always call with JSR, since returns with RTS *
* checks if the 6 bit E/A in [mode] [reg] order in D3 is valid, sets D6 to 1 if valid, 0 if invalid *
* An is not valid E/A mode, all other E/A modes are valid *
* called from the opcodes MULS, DIVS, OR (left is E/A) *

    JSR SET_EA_INVALID * initialize valid/invalid flag to 0 *

    JSR IS_DN * checks if the E/A is Dn, sets D6 to 1 if valid *
    
    JSR IS_AN_INDIRECT * checks if the E/A is (An), sets D6 to 1 if valid *
    
    JSR IS_AN_INC * checks if the E/A is (An)+ , sets D6 to 1 if valid *
    
    JSR IS_AN_DEC * checks if the E/A is -(SP), sets D6 to 1 if valid *
    
    JSR IS_WORD * checks if the E/A is (xxx).W, sets D6 to 1 if valid *
    
    JSR IS_LONG * checks if the E/A is (XXX).L, sets D6 to 1 if valid *
    
    JSR IS_IMMEDIATE * checks if the E/A is #<data>, sets D6 to 1 if valid *

    RTS * return *

EA_GROUP3: * always call with JSR, since returns with RTS *
* checks if the 6 bit E/A in [mode] [reg] order in D3 is valid, sets D6 to 1 if valid, 0 if invalid *
* An and #<data> are not valid E/A modes, all other E/A modes are valid *
* called from the opcodes MOVE (dst), ORI, NEG, EOR, BCLR, CMPI *

    JSR SET_EA_INVALID * initialize valid/invalid flag to 0 *

    JSR IS_DN * checks if the E/A is Dn, sets D6 to 1 if valid *
    
    JSR IS_AN_INDIRECT * checks if the E/A is (An), sets D6 to 1 if valid *
    
    JSR IS_AN_INC * checks if the E/A is (An)+ , sets D6 to 1 if valid *
    
    JSR IS_AN_DEC * checks if the E/A is -(SP), sets D6 to 1 if valid *
    
    JSR IS_WORD * checks if the E/A is (xxx).W, sets D6 to 1 if valid *
    
    JSR IS_LONG * checks if the E/A is (XXX).L, sets D6 to 1 if valid *

    RTS * return *

EA_GROUP4: * always call with JSR, since returns with RTS *
* checks if the 6 bit E/A in [mode] [reg] order in D3 is valid, sets D6 to 1 if valid, 0 if invalid *
* valid E/A modes for MOVEM (reg to mem) only (An, Dn, (An)+, #<data> are not valid E/A modes *
* called by MOVEM (reg to mem) only *
    
    JSR SET_EA_INVALID * initialize valid/invalid flag to 0 *
    
    JSR IS_AN_INDIRECT * checks if the E/A is (An), sets D6 to 1 if valid *
    
    JSR IS_AN_DEC * checks if the E/A is -(SP), sets D6 to 1 if valid *
    
    JSR IS_WORD * checks if the E/A is (xxx).W, sets D6 to 1 if valid *
    
    JSR IS_LONG * checks if the E/A is (xxx).L, sets D6 to 1 if valid *

    RTS * return *

EA_GROUP5: * always call with JSR, since returns with RTS *
* checks if the 6 bit E/A in [mode] [reg] order in D3 is valid, sets D6 to 1 if valid, 0 if invalid *
* valid E/A modes for MOVEM (mem to reg) only (An, Dn, -(SP), #<data> are not valid E/A modes *
* called by MOVEM (mem to reg only) *
    
    JSR SET_EA_INVALID * initialize valid/invalid flag to 0 *
    
    JSR IS_AN_INDIRECT * checks if the E/A is (An), sets D6 to 1 if valid *
    
    JSR IS_AN_INC * checks if the E/A is (An)+ , sets D6 to 1 if valid *
    
    JSR IS_WORD * checks if the E/A is (xxx).W, sets D6 to 1 if valid *
    
    JSR IS_LONG * checks if the E/A is (xxx).L, sets D6 to 1 if valid *

    RTS * return *

EA_GROUP6: * always call with JSR, since returns with RTS *
* checks if the 6 bit E/A in [mode] [reg] order in D3 is valid, sets D6 to 1 if valid, 0 if invalid *
* valid E/A modes for SUBQ only #<data> is not valid E/A mode * 
* Called by SUBQ only *

    JSR SET_EA_INVALID * initialize valid/invalid flag to 0 *

    JSR IS_DN * checks if the E/A is Dn, sets D6 to 1 if valid *

    JSR IS_AN * checks if the E/A is An, sets D6 to 1 if valid *
    
    JSR IS_AN_INDIRECT * checks if the E/A is (An), sets D6 to 1 if valid *
    
    JSR IS_AN_INC * checks if the E/A is (An)+ , sets D6 to 1 if valid *
    
    JSR IS_AN_DEC * checks if the E/A is -(SP), sets D6 to 1 if valid *
    
    JSR IS_WORD * checks if the E/A is (xxx).W, sets D6 to 1 if valid *
    
    JSR IS_LONG * checks if the E/A is (xxx).L, sets D6 to 1 if valid *
    
    RTS * return *

EA_GROUP7: * always call with JSR, since returns with RTS *
* checks if the 6 bit E/A in [mode] [reg] order in D3 is valid, sets D6 to 1 if valid, 0 if invalid *
* An, Dn, #<data> are not valid E/A modes, all other E/A modes are valid *
* Called by ADD (right is E/A), SUB (right is E/A), OR (right is E/A), LSR (mem), LSL (mem), ASR (mem), ASL (mem), ROL (mem), ROR (mem) *

    JSR SET_EA_INVALID * initialize valid/invalid flag to 0 *
    
    JSR IS_AN_INDIRECT * checks if the E/A is (An), sets D6 to 1 if valid *
    
    JSR IS_AN_INC * checks if the E/A is (An)+ , sets D6 to 1 if valid *
    
    JSR IS_AN_DEC * checks if the E/A is -(SP), sets D6 to 1 if valid *
    
    JSR IS_WORD * checks if the E/A is (xxx).W, sets D6 to 1 if valid *
    
    JSR IS_LONG * checks if the E/A is (xxx).L, sets D6 to 1 if valid *
    
    RTS * return *
    
EA_GROUP8: * always call with JSR, since returns with RTS *
* checks if the 6 bit E/A in [mode] [reg] order in D3 is valid, sets D6 to 1 if valid, 0 if invalid *
* Dn, An, (An)+, -(SP), #<data> are not valid E/A modes, all other E/A modes are valid *
* Called by JSR, LEA *
    
    JSR SET_EA_INVALID * initialize valid/invalid flag to 0 *
    
    JSR IS_AN_INDIRECT * checks if the E/A is (An), sets D6 to 1 if valid *
    
    JSR IS_WORD * checks if E/A is (xxx).W, sets D6 to 1 if valid *
    
    JSR IS_LONG * checks if E/A is (xxx).L, sets D6 to 1 if valid *
    
    RTS * return *

PRINT_EA:
* prints the 6 bit E/A in [mode] [reg] order in D3 *

    JSR SET_EA_INVALID * initialize the valid/invalid flag to 0 *
    JSR IS_DN * checks if the E/A is Dn, sets D6 to 1 if valid *
    
    CMP.B #1, D6
    BEQ PRINT_DN * prints the Dn if D6 is valid *
    
    JSR IS_AN * checks if the E/A is An, sets D6 to 1 if valid *
    
    CMP.B #1, D6
    BEQ PRINT_AN * prints the An if D6 is valid *
    
    JSR IS_AN_INDIRECT * checks if the E/A is (An), sets D6 to 1 if valid *
    
    CMP.B #1, D6
    BEQ PRINT_AN_INDIRECT * prints the (An) if D6 is valid *
    
    JSR IS_AN_INC * checks if the E/A is (An)+, sets D6 to 1 if valid *
    
    CMP.B #1, D6
    BEQ PRINT_AN_INC * prints the (An)+ if D6 is valid *
    
    JSR IS_AN_DEC * checks if the E/A is -(SP), sets D6 to 1 if valid *
    
    CMP.B #1, D6
    BEQ PRINT_AN_DEC * prints the -(SP) if D6 is valid *
    
    JSR IS_WORD * checks if the E/A is (xxx).W, sets D6 to 1 if valid *
    
    CMP.B #1, D6
    BEQ PRINT_EA_WORD * prints the (XXX).W if D6 is valid *
    
    JSR IS_LONG * checks if the E/A is (XXX).L, sets D6 to 1 if valid *
    
    CMP.B #1, D6 
    BEQ PRINT_EA_LONG * print the (xxx).L if D6 is valid *
    
    JSR IS_IMMEDIATE * checks if the E/A is #<data>, sets D6 to 1 if valid *
    
    CMP.B #1, D6
    BEQ PRINT_IMMEDIATE_EA * prints the #<data> if D6 is valid *
    
    RTS * return, only reaches here if the E/A is invalid -> doesn't print anything when E/A invalid *

PRINT_DN:
* prints the 6 bit E/A in [mode] [reg] order in D3 *

    * print
    * display D *
    LEA OUT_D, A1 * loads D into A1
    MOVE.B #14, D0
    TRAP #15
    
    MOVE.L D3, D4 * copies reg and mode to D4
    
    AND.L #$000000007, D4 * masks everything but the register nuumber
    
    CLR.L D1 * clear D1
    
    MOVE.B D4, D1 * loads the data register # for output
    MOVE.B #3, D0 * trap task 3 displays a number to system out
    TRAP #15 * calls trap #15
    
    RTS * return *

PRINT_AN:
* prints the 6 bit E/A in [mode] [reg] order in D3 *

    * print
    
    * print
    * display A *
    LEA OUT_A, A1 * loads A into A1
    MOVE.B #14, D0
    TRAP #15
    
    * display register # *
    MOVE.L D3, D4 * copies reg and mode to D4
    
    AND.L #$000000007, D4 * masks everything but the register nuumber
    
    CLR.L D1 * clear D1
    
    MOVE.B D4, D1 * loads the data register # for output
    MOVE.B #3, D0 * trap task 3 displays a number to system out
    TRAP #15 * calls trap #15
    
    RTS * return *

PRINT_AN_INDIRECT:
* prints the 6 bit E/A in [mode] [reg] order in D3 *

    * print
    * display left paren '('
    LEA LEFT_PAREN, A1 * loads '(' into A1
    MOVE.B #14, D0
    TRAP #15
    
    * display A *
    LEA OUT_A, A1 * loads A into A1
    MOVE.B #14, D0
    TRAP #15
    
    * display register # *
    MOVE.L D3, D4 * copies reg and mode to D4
    
    AND.L #$000000007, D4 * masks everything but the register nuumber
    
    CLR.L D1 * clear D1
    
    MOVE.B D4, D1 * loads the data register # for output
    MOVE.B #3, D0 * trap task 3 displays a number to system out
    TRAP #15 * calls trap #15
    
    * display right paren ')'
    LEA RIGHT_PAREN, A1 * loads ')' into A1
    MOVE.B #14, D0
    TRAP #15
    
    RTS * return *

PRINT_AN_INC:
* prints the 6 bit E/A in [mode] [reg] order in D3 *

    * print
    JSR PRINT_AN_INDIRECT
    
    * display '+'
    LEA PLUS, A1 * loads '+' into A1
    MOVE.B #14, D0
    TRAP #15
    
    RTS * return *

PRINT_AN_DEC:
* prints the 6 bit E/A in [mode] [reg] order in D3 *

    * print '-'
    LEA MINUS, A1 * loads '-' into A1
    MOVE.B #14, D0
    TRAP #15
    
    JSR PRINT_AN_INDIRECT
    
    RTS * return *

PRINT_EA_WORD:
* prints the 6 bit E/A in [mode] [reg] order in D3 *

    * print '$'
    LEA DOLLAR, A1 * loads '$' into A1
    MOVE.B #14, D0
    TRAP #15
    
    MOVEA.L A0, A4 * copy current instruction address to A4
    
    ADD.W #2, A4 * increment A4 by 16 bits (2 bytes)
    
    CLR.L D4 * clear D4
    MOVE.W (A4), D4 * move the word of memory from A4 to D4
    
    JSR OUTPUT_WORD * prints the word in D4 to output
    
    RTS * return *

PRINT_EA_LONG:
* prints the 6 bit E/A in [mode] [reg] order in D3 *

    * print
    * print '$'
    LEA DOLLAR, A1 * loads '$' into A1
    MOVE.B #14, D0
    TRAP #15
    
    MOVEA.L A0, A4 * copy current instruction address to A4
    
    ADD.W #2, A4 * increment A4 by 16 bits (2 bytes)
    
    CLR.L D4 * clear D4
    MOVE.W (A4), D4 * move the word of memory from A4 to D4
    
    JSR OUTPUT_WORD * prints the word in D4 to output
    
    ADD.W #2, A4 * increment A4 by 16 bits (2 bytes)
    MOVE.W (A4), D4 * move the word of memory from A4 to D4
    
    JSR OUTPUT_WORD * prints the word in D4 to output
    
    RTS * return *

PRINT_IMMEDIATE_EA:
* prints the 6 bit E/A in [mode] [reg] order in D3 *

    * print
    * print '#'
    LEA HASH, A1 * loads '#' into A1
    MOVE.B #14, D0
    TRAP #15
    
    MOVEA.L A0, A4 * copy current instruction address to A4
    ADD.W #2, A4 * increment A4 by 16 bits (2 bytes)
    
    CLR.L D1 * clear D1
    MOVE.W (A4), D1 * move the word of memory from A4 to D1
    MOVE.B #3, D0 * trap task 3 displays a number to system out
    TRAP #15 * calls trap #15
    
    RTS * return *

IS_DN:
* checks if 6 bit E/A in [mode] [reg] order in D3 is Dn, sets D6 to 1 if valid *

    MOVE.L D3, D4 * save the E/A from D3 in D4

    * mode is bits 3-5, check if set to 000 *
    AND.L #$00000038, D4 * masks all bits but mode

    CMP.W #$0000, D4 * checks if bits 3-5 are [000]
    BEQ SET_EA_VALID
    
    RTS * return, only reaches here if EA is not Dn *

IS_AN:
* checks if 6 bit E/A in [mode] [reg] order in D3 is An, sets D6 to 1 if valid *
    
    MOVE.L D3, D4 * save the E/A from D3 in D4
    
    * mode is bits 3-5, check if set to 001
    AND.L #$00000038, D4 * masks all bits but mode

    CMP.W #$0008, D4 * check if bits 3-5 are [001]
    BEQ SET_EA_VALID 
    
    RTS * return, only reaches here if EA is not An *

IS_AN_INDIRECT:
* checks if 6 bit E/A in [mode] [reg] order in D3 is (An), sets D6 to 1 if valid *

    MOVE.L D3, D4 * save the E/A from D3 in D4

    * mode is bits 3-5, check if set to 010
    AND.L #$00000038, D4 * masks all bits but mode
    
    CMP.W #$0010, D4 * check if bits 3-5 are [010]
    BEQ SET_EA_VALID
    
    RTS * return, only reaches here if not (An) *

IS_AN_INC:
* checks if 6 bit E/A in [mode] [reg] order in D3 is (An)+, sets D6 to 1 if valid *

    MOVE.L D3, D4 * save the E/A from D3 in D4

    * mode is bits 3-5, check if set to 011
    AND.L #$00000038, D4 * masks all bits but mode
    
    CMP.W #$0018, D4 * check if bits 3-5 are [011]
    BEQ SET_EA_VALID
    
    RTS * return, only reaches here if not (An)+ *    

IS_AN_DEC:
* checks if 6 bit E/A in [mode] [reg] order in D3 is -(An), sets D6 to 1 if valid *

    MOVE.L D3, D4 * save the E/A from D3 in D4
    
    * mode is bits 3-5, check if set to 100
    AND.L #$00000038, D4 * masks all bits but mode
    
    CMP.W #$0020, D4 * check if bits 3-5 are [100]
    BEQ SET_EA_VALID
    
    RTS * return, only reaches here if not -(An) *

EA_INCREMENT_MORE:
* checks if 6 bit E/A in [mode] [reg] order in D3 is (XXX).W or (XXX).L, and increments the correct amount for word or long *

    MOVE.L D3, D4 * save the E/A from D3 in D4

    JSR SET_EA_INVALID * sets D6 to 0
    
    JSR IS_WORD * checks if it's (XXX).W *
    
    CMP.B #1, D6
    BEQ EA_INCREMENTADDRESS * increments by 16 bits (2 bytes)
    
    MOVE.L D3, D4 * save the E/A from D3 in D4
    
    JSR SET_EA_INVALID * sets D6 to 0
    
    JSR IS_LONG * checks if it's (XXX).L *

    CMP.B #1, D6
    BEQ EA_INC32
    
    RTS * return, if not incrementing *

EA_INCREMENTADDRESS:

    JSR INCR_ADDRESS * increments by 16 bits (2 bytes)
    
    RTS * return *
    
EA_INC32:

    JSR INC32 * increments by 32 bits (4 bytes)
    
    RTS * return *

IS_WORD:
* checks if 6 bit E/A in [mode] [reg] order in D3 is (XXX).W, sets D6 to 1 if valid *

    MOVE.L D3, D4 * save the E/A from D3 in D4
    
    * check mode and register, set to 111 000
    AND.L #$0000003F, D4 * masks all bits but mode and register
    
    CMP.W #$0038, D4 * check if bits 5-0 are 111 000
    BEQ SET_EA_VALID

    RTS * return, only reaches here if not (XXX).W *

IS_LONG:
* checks if 6 bit E/A in [mode] [reg] order in D3 is (XXX).L, sets D6 to 1 if valid *
    
    MOVE.L D3, D4 * save the E/A from D3 in D4
    
    * check mode and register, set to 111 001
    AND.L #$0000003F, D4 * masks all bits but mode and register
    
    CMP.W #$0039, D4 * check if bits 5-0 are 111 001
    BEQ SET_EA_VALID
    
    RTS * return, only reaches here if not (XXX).L *

IS_IMMEDIATE:
* checks if 6 bit E/A in [mode] [reg] order in D3 is #<data>, sets D6 to 1 if vvalid *

    MOVE.L D3, D4 * save the E/A from D3 in D4
    
    * check mode and register, set to 111 100
    AND.L #$0000003F, D4 * masks all bits but mode and register

    CMP.W #$003C, D4 * check if bits 5-0 are 111 100
    BEQ SET_EA_VALID

    RTS * return, only reaches here if not #<data> *

SET_EA_INVALID:

    MOVE.L #0, D6
    RTS * return *

SET_EA_VALID:

    MOVE.L #1, D6 
    RTS * return *

DONE: ; done



* comment out for final program. Utility for gracefull ending during testing.
graceful_end:
                LEA     PROGRAM_END,A1
                MOVE.B  #14,D0              ;load command for trap to display string
                TRAP    #15                 ;display utility ending message
                JSR     reset
                JMP     THE_END  
    SIMHALT             ; halt simulator

* test code down here -> memory address ORG at $4000

    ORG $4000
    MOVE.B D2, D1
    MOVE.L A0, D2
    MOVE.W (A0), (A1) * destination is printing as a data register
    MOVE.B -(A2), D4
    MOVE.W $00001000, D6
    MOVE.B #12, D7
    CMP.B $0020, D6
    MOVEM.L D2, (A1)
    MOVEM.W (A3), D2
    CMP.B $02004000, D7
    CMP.B D2, D1
    CMP.W A0, D2
    CMP.L (A2), D3
    CMP.B (A3)+, D4
    CMP.B -(A1), D6
    CMP.B #14, D6
    DIVU.W D1, D2 * not implemented -> should be DATA YYYY
    ASL.B #2, D0
    ROL.L #3, D0
    LSL.B #2, D5
    ASL.B D1, D2
    ASR.W D3, D4
    ROR.B D0, D1
    LSL.B D2, D3
    LSL.W (A0)
    ASR.W (A2)
    ASL (A1)
    ROR.W (A5)
    ADDA.L A1, A2 * displaying as DATA
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
    BGE DONE
    BLT DONE
    MOVEA.W D3, A2
    MOVE.B D2, D5 * displaying as DATA
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
*-----------------------------------------------------------
* Display outputs
*-----------------------------------------------------------

CR              EQU     $0D                
LF              EQU     $0A                  

INTRO           DC.B    '................................................................',CR,LF
                DC.B    '.                  (    (    (         )      )                .',CR,LF
                DC.B    '.                 )\ ) )\ ) )\ )   ( /(   ) /(                 .',CR,LF   
                DC.B    '.                ( )(_))/(_))/(_)) ((_)\ ((_)\                 .',CR,LF
                DC.B    '.                 (_)_)(_)) (_)_) (_(_)__ ((_)                 .',CR,LF
                DC.B    '.                 | _ \|_ _|/ __| / __|\ \/ /                  .',CR,LF
                DC.B    '.                 |   / | | \__ \| |__  \  /                   .',CR,LF
                DC.B    '.                 |_|_\|___||___/ \___| |_|                    .',CR,LF                
                DC.B    '.            (          )\  )   )     (    (     )             .',CR,LF
                DC.B    '.          ( )\   (    (() ()) /(  ( ())   ))(\ (( (           .',CR,LF
                DC.B    '.         )((_)   )\  /(_))/(_))(  )\ ))\  /(_))/(_))          .',CR,LF
                DC.B    '.        (_)_ )_ ((_) (_))(___) _((_)((__) (_)) (_))           .',CR,LF
                DC.B    '.        | _ )| | | |/ __||_ _|| \| || __|/ __|/ __|           .',CR,LF
                DC.B    '.        | _ \| |_| |\__ \ | | | .` || _| \__ \\__ \           .',CR,LF
                DC.B    '.        |___/ \___/ |___/|___||_|\_||___||___/|___/           .',CR,LF              
                DC.B    '.)  )   )       )   (       )   )\  )     (         (   )\  )  .',CR,LF
                DC.B    '.(( /( ( )/  ) /(  ) )\    (()( (()/(   )  )\))(   ( )\ (( (() .',CR,LF
                DC.B    '.)(_)) /(_))/(_))((_)(   /(_))/(_)))\  ((_)()\  )((_)/(_))/(_)).',CR,LF
                DC.B    '.(_)_)(_)_) (__)( )_ )) (_)) (_)) (__)(_()((_)((_)_ (_))  (_)_).',CR,LF
                DC.B    '.|   \|_ _|/ __|()/_\()/ __|/ __|| __||  \/  | | _ )| |   | _ \.',CR,LF
                DC.B    '.| |) || | \__ \ / _ \ \__ \\__ \| _| | |\/| | | _ \| |__ |   /.',CR,LF
                DC.B    '.|___/|___||___//_/ \_\|___/|___/|___||_|  |_| |___/|____||_|_\.',CR,LF
                DC.B    '................................................................',CR,LF,0

STARTADR_MSG    DC.B    'Enter a starting address in hex',CR,LF,0
INPUT_DISCLAIMER DC.B   '(even only, no spaces, max 8 characters) and press enter',CR,LF,0
ENDADR_MSG      DC.B    'Enter an ending address in hex',CR,LF,0
INVALID_MSG     DC.B    'Address not valid, try again',CR,LF,0
PROGRAM_END     DC.B    'End of program. Not so RISCy afterall!',CR,LF,0
NEXT_PAGE       DC.B    'Press enter to see more!',CR,LF,0
START_DISASSEMBLING DC.B 'Disassembled memory:',CR,LF,0

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
PLUS DC.B '+', 0
MINUS DC.B '-', 0

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

GOOD_BUFFER     DS.B    100
STARTADR        DS.B    8
ENDADR          DS.B    8

THE_END:
    END    START        ; last line of source

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
