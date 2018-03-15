*-----------------------------------------------------------
* Title      :Dissasembler for 68K
* Written by :Midori williams
* Date       :1/3/18
* Description:
*-----------------------------------------------------------     

    ORG    $1000
START:                  ; first instruction of program

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
                CLR     D0
                
                MOVEA.L #0,A1               ;clear register 
                LEA     STARTADR,A1         ;load address in A1 to store staring address
                CLR     D1                  ;input length will be auto stored here
                MOVE.B  #2,D0               ;load command for trap to read data input
                TRAP    #15                 ;read start address from keyboard, stores at memlocation STARTADR
                CLR     D0
                JSR     valid_input         ;validate start address
                JSR     convert2hex         ;convert ascii input to hex
                MOVE.L  D0,D2               ;starting address hex value is moved to be stored longterm in D2
                CLR     D0
                JSR     is_even             ;even address check
endadR_in:      
                MOVEA.L #0,A1               ;clear register 
                LEA     ENDADR_MSG,A1       ;load end address message
                MOVE.B  #14,D0              ;load command for trap to display string
                TRAP    #15                 ;display end address message
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
                JSR     is_even             ;even address check

* comment out for final program. Utility for gracefull ending during testing.
graceful_end:
                LEA     PROGRAM_END,A1
                MOVE.B  #14,D0              ;load command for trap to display string
                TRAP    #15                 ;display utility ending message
                JSR     reset
                JMP     THE_END                
                       
*-----------------------------------------------------------
* Address Validation
* Description: Check user input. 
* If out of range or > 8 character or not even number, 
* repeat start/end address prompt
*-----------------------------------------------------------
valid_input:    
                CLR.L   D5                  ;clear register
                MOVE.L  (A1),D5             ;load input address into D5
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
*-----------------------------------------------------------
* Print Buffer / output
* Description: output either represents a readable assembly
* comand or address cannot be read and display in the form
* XXXXXXXX	DATA   YYYY, (XXXXXXXX is the memory address of 
* the word and YYYY is the hex value of the word)
*-----------------------------------------------------------
read_goodbuffer

print_bad_data

print_ea

print_opcode

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

STARTADR_MSG    DC.B    'Enter a starting address in hex (even numbers only)and press enter',CR,LF,0
ENDADR_MSG      DC.B    'Enter an ending address in hex (even numbers only)and press enter',CR,LF,0
INVALID_MSG     DC.B    'Address not valid, try again',CR,LF,0
PROGRAM_END     DC.B    'End of program. Not so RISCy afterall!',CR,LF,0

GOOD_BUFFER     DS.B    100
STARTADR        DS.B    8
ENDADR          DS.B    8
 

   

THE_END:
    END    START        ; last line of source
    







*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
