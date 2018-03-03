*---------------------------------------------------------------
* Title      : Disassembler OpCodes
* Written by : Sarah Oliphant
* Date       : 3/2/2018
* Description: Separate Opcodes by checking bits from MSB to LSB
*---------------------------------------------------------------
   
addr1 EQU $2000 ; Memory Adress of ORG for test code
   
* Start of Decoder

    ORG    $1000    ; Memory Adress where this program is stored
    
START:                  ; first instruction of program

* Input output here    
IO:

   * User Input
   
   * Convert ASCII Hex addresses 


    MOVE.W #addr1, A0 ; load the Address register with start of test program to Address Register 0
   * After I/O is implemented, I/O will have already loaded this into A0, and passed to Opcode

OPCODE:

* Check first 2 bits of 16 bit instruction at A0 *

* make a copy of the 16 bit instruction at A0

* DIVU the first word of the instruction by 8
* then SUB the word from 00
* BEQ to part 00 (00)

* SUB the word from 01
* BEQ to part 01

* SUB the word from 10
* BEQ to part 10

* last option - BRA to part 11 


* Opcode Part0: 00 for first 2 bits *
PART0: 
    
    * check if 3rd and fourth bits are 00 (0000)
            * check more bits to determine either:
                * BCLR (dynamic)
                * ORI
                * BCLR (static)
                * CMPI
    * else (0001, 0010, 0011)
            * MOVE or MOVEA
    
* Opcode Part1: 01 for first 2 bits *
PART1: 
    
    * check if it's RTS type 4 instruction by checking 12 bits (0100 1110 0111)
            * check if it's NOP or RTS
                * NOP has last 4 bits 0001
                * RTS has last 4 bits 0101
                
    * other instructions starting with 0100
            * 1100 0 -> MULS or DIVS (long)
            * XXX1 -> LEA
            * 0100 -> NEG
            * 1110 -> JSR
            * 1X00 1 -> MOVEM
     
    * starting with 0101
            * SUBQ
            
    * starting with 0110
            * loop over the BCC instructions
                * 0101 -> BCS
                * 1100 -> BGE
                * 1101 -> BLT
                * 1000 -> BVC
                * 0000 -> BRA
    
    * else starting with 0111 call I/O for invalid (none of the instructions to implement start this way) 
    
    
* Opcode Part2: 10 for first 2 bits *
PART2:
    
    * starting with 1000
        * separate by opmode
        * DIVS (opmode 111)
        * OR (all other opmodes)
        
    * starting with 1001
        * SUB
    
    * starting with 1011
        * EOR (opmodes 100, 101, 110)
        * CMP (opmodes 000, 001, 010)
    
    * else starting with 1010 call I/O for invalid (none of the instructions to implement start this way)
    
* Opcode Part3: 11 for first 2 bits *
PART3:
    
    * starting with 1100
        * MULS
        
    * starting with 1101
        * ADDA (opmode 011, 111)
        * ADD (all other opmodes)
        
    * starting with 1110
        * one of the shifts (LSL, LSR, ASL, ASR, ROL, ROR) depending on later bits

    * starting with 1111 call I/O for invalid (none of the instructions to implement start this way) 

    
FINISHOPCODE:

    BRA IO ; call I/O to read the next 16 bit instruction into A0

DONE: ; done


    SIMHALT             ; halt simulator

* test code down here -> memory address ORG at $2000

    ORG $2000
    NOT $1600 ; test instructions 

* Put variables and constants here


* Constants for output instructions
NOP DC.B 'NOP',0        ; output message when NOP is the test instruction
DATA DC.B 'DATA',0      ; output message when invalid instruction
MOVE DC.B 'MOVE', 0     ; output message when MOVE is the test instruction
MOVEA DC.B 'MOVEA', 0   ; output message when MOVEA is the test instruction
MOVEM DC.B 'MOVEM', 0   ; output message when MOVEM is the test instruction
ADD DC.B 'ADD', 0       ; output message when ADD is the test instruction
ADDA DC.B 'ADDA', 0     ; output message when ADD is the test instruction
SUB DC.B 'SUB', 0       ; output message when SUB is the test instruction
SUBQ DC.B 'SUBQ', 0     ; output message when SUBQ is the test instruction
MULS DC.B 'MULS', 0     ; output message when MULS is the test instruction
DIVS DC.B 'DIVS', 0     ; output message when DIVS is the test instruction
LEA DC.B 'LEA', 0       ; output message when LEA is the test instruction
OR DC.B 'OR', 0         ; output message when OR is the test instruction
ORI DC.B 'ORI', 0       ; output message when ORI is the test instruction
NEG DC.B 'NEG', 0       ; output message when NEG is the test instruction
EOR DC.B 'EOR', 0       ; output message when EOR is the test instruction
LSR DC.B 'LSR', 0       ; output message when LSR is the test instruction
LSL DC.B 'LSL', 0       ; output message when LSL is the test instruction
ASR DC.B 'ASR', 0       ; output message when ASR is the test instruction
ASL DC.B 'ASL', 0       ; output message when ASL is the test instruction
ROL DC.B 'ROL', 0
ROR DC.B 'ROR', 0
BCLR DC.B 'BCLR', 0
CMP DC.B 'CMP', 0
CMPI DC.B 'CMPI', 0
BCS DC.B 'BCS', 0
BGE DC.B 'BGE', 0
BLT DC.B 'BLT', 0
BVC DC.B 'BVC', 0
BRA DC.B 'BRA', 0
JSR DC.B 'JSR', 0
RTS DC.B 'RTS', 0


    END    START        ; last line of source
    
    
    
    

    





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
