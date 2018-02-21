*-----------------------------------------------------------
* Title      : NOP Decoding
* Written by : Sarah Oliphant
* Date       : 2/20/2018
* Description: Binary Assembled NOP Instruction to decoded output NOP
*-----------------------------------------------------------
   
addr1 EQU $2000 ; Memory Adress of ORG for test code
data1 EQU $4E71 ; Binary NOP instruction (0100 1110 0111 0001)
   
* Start of NOP Decoder

    ORG    $1000    ; Memory Adress where this program (NOP Decoder) is stored
    
START:                  ; first instruction of program
    
    MOVE.W #data1, D2 ; load the NOP instruction in the data register 2
    MOVE.W #addr1, A2 ; load the Address register with start of test program to Address Register 2

* subtract binary NOP instruction - test program memory (D2 - memory at A2)

    SUB D2, (A2) ; subtract the memory at A2 from D2

* check the 0 bit and branch to NOPOUT

    BEQ NOPOUT
    
    * 0 bit is not zero means D2 and A2 are not equal and the Instruction is not NOP
    
    LEA NOTNOP, A1 ; loads the message 'NOT NOP' message to address register A1
    MOVE.B #14, D0    ; Moves the number 14 into data register D0
    TRAP #15          ; TRAP 15 displays A1 to system out when D0 is #14
    
    BRA DONE ; Branch always after finished outputing to 
* output the format for bad instruction here

NOPOUT: ; output NOP here
    LEA NOP, A1   ; loads the message 'NOP' into address register A1
    MOVE.B #14, D0    ; Moves the number 14 into data register D0
    TRAP #15          ; TRAP 15 displays A1 to system out when D0 is #14

DONE: ; done with NOP decoding


    SIMHALT             ; halt simulator

* test code down here -> memory address ORG at $2000

    ORG $2000
    NOT $1600 ; test NOP instruction, change this to something else to change the 

* Put variables and constants here

NOP DC.B 'NOP',0 ; output message when NOP is the test instruction
NOTNOP DC.B 'NOT NOP',0 ; output message when NOP is not the test instruction


    END    START        ; last line of source
    
    
    
    

    



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
