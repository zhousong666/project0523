;------------------------------------------------------------------------------
; Module       = hwmdu_LibReplacement.s
; Version      = 1.9
;------------------------------------------------------------------------------
;                                  COPYRIGHT
;------------------------------------------------------------------------------
; Copyright (c) 2011 by Renesas Electronics Europe GmbH,
;               a company of the Renesas Electronics Corporation
;------------------------------------------------------------------------------
; Purpose:
;       sample code to use RL78_1 32bit Hardware Multiply Division Unit (HW_MDU)
;
;------------------------------------------------------------------------------
;
; Warranty Disclaimer
;
; Because the Product(s) is licensed free of charge, there is no warranty
; of any kind whatsoever and expressly disclaimed and excluded by Renesas,
; either expressed or implied, including but not limited to those for
; non-infringement of intellectual property, merchantability and/or
; fitness for the particular purpose.
; Renesas shall not have any obligation to maintain, service or provide bug
; fixes for the supplied Product(s) and/or the Application.
;
; Each User is solely responsible for determining the appropriateness of
; using the Product(s) and assumes all risks associated with its exercise
; of rights under this Agreement, including, but not limited to the risks
; and costs of program errors, compliance with applicable laws, damage to
; or loss of data, programs or equipment, and unavailability or
; interruption of operations.
;
; Limitation of Liability
;
; In no event shall Renesas be liable to the User for any incidental,
; consequential, indirect, or punitive damage (including but not limited
; to lost profits) regardless of whether such liability is based on breach
; of contract, tort, strict liability, breach of warranties, failure of
; essential purpose or otherwise and even if advised of the possibility of
; such damages. Renesas shall not be liable for any services or products
; provided by third party vendors, developers or consultants identified or
; referred to the User by Renesas in connection with the Product(s) and/or the
; Application.
;
;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
; History: 1.0 Initial version
;          1.1 New Company Name, problem fix in signed division function: 
;              NEG_Flag may be overwritten by new division started in ISR 
;          1.2 8-bit signed and unsigned division library replacement function 
;              added
;          1.3 error message updated
;          1.4 mode selection corrected 
;          1.5 modulo functions added 
;          1.6 problem fix signed 32bit division:
;              negative flag not cleared at division by zero
;          1.7 Correction of 16bit multiplication 
;              (preserve of register BC to be compatible to SW-library)
;          1.8 Usage of library modules only
;          1.9 Adapted for Embedded Workbench for RL78 V2.10 and far runtime
;              library calls
;
;------------------------------------------------------------------------------
;
;---------------------------------CAUTION--------------------------------------
;
; In case of using these functions interrupt handling is delayed!
;
;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
; Note: Select the correct include files for the device used by the application.
#include __DEVICE_FILE__
#include __DEVICE_FILE_EXT__


;------------------------------------------------------------------------------

#if __CORE__ != __RL78_1__
    #error "Functions for RL78_1 core devices only"
#endif

;------------------------------------------------------------------------------
;       Multiplies two signed/unsigned ints
;
;       Input:  AX      Operand 1
;               BC      Operand 2
;
;       Call:   CALL    HWMUL_16_16_16
;
;       Output: AX      result (Op1 mul Op2)
;               Z-flag
;
; This function can be used as replacement for the library function ?I_MUL_L02
; by using the linker option -eHWMUL_16_16_16=?I_MUL_L02
;------------------------------------------------------------------------------
        MODULE __HWMDU_LIBREPLACEMENTS
        PUBLIC  HWMUL_16_16_16
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWMUL_16_16_16:
        PUSH  BC
        PUSH  PSW
        DI

        ; select multiplication mode
        MOV   MDUC, #0x00

        MOVW  MDAL,AX
        MOVW  AX,BC
        MOVW  MDAH,AX
        NOP
        MOVW  AX,MDBL
        POP   PSW
        CMPW  AX,#0x0000  ; set / clear Z-Flag
        
        POP   BC
        
        RET
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;       Multiplies two signed/unsigned longs
;
;       Input:  AX,BC      Operand 1
;               Stack      Operand 2
;       Output: AX,BC      result (Op1 mul Op2)
;               Z-flag
;
; This function can be used as replacement for the library function ?L_MUL_L03
; by using the linker option -eHWMUL_32_32_32=?L_MUL_L03
;------------------------------------------------------------------------------
        PUBLIC  HWMUL_32_32_32
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWMUL_32_32_32:
        PUSH  HL
        PUSH  DE
        PUSH  PSW
        DI
        PUSH  BC   ; HW_P1
        PUSH  AX   ; LW_P1

        ; select multiplication mode
        MOV   MDUC, #0x00

        ; get 2nd parameter from stack
        MOVW  HL,SP
        MOVW  AX,[HL+0x10]
        MOVW  DE,AX          ; HW_P2
        MOVW  AX,[HL+0x0E]   ; LW_P2

        ; 1st multiplication HW_P1 * LW_P2
        MOVW  MDAL,AX
        MOVW  AX,BC
        MOVW  MDAH,AX
        POP   BC         ; LW_P1
        PUSH  BC
        MOVW  AX,MDBL

        ; 2nd multiplication LW_P1 * HW_P2
        XCHW  AX,BC
        MOVW  MDAL,AX
        MOVW  AX,DE
        MOVW  MDAH,AX
        NOP
        MOVW  AX,MDBL
        XCH   A,X
        ADD   A,C
        XCH   A,X
        ADDC  A,B
        MOVW  DE,AX    ; temp result2

        ; 3rd multiplication LW_P1 * LW_P2
        POP   AX           ; LW_P1
        MOVW  MDAL,AX
        MOVW  HL,SP
        MOVW  AX,[HL+0x0C]
        MOVW  MDAH,AX
        NOP
        MOVW  AX,MDBL
        MOVW  BC,AX
        MOVW  AX,MDBH
        XCH   A,X
        ADD   A,E
        XCH   A,X
        ADDC  A,D
        XCHW  AX,BC

        ; clean up stack
        POP   DE
        POP   PSW

        ; set / clear Z-Flag according to the result
        XCHW  AX,BC
        CMPW  AX, #0x0000
        XCHW  AX,BC
        SKNZ
        CMPW  AX, #0x0000
        POP   DE
        POP   HL
        RET
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;       Division of two unsigned chars
;
;       Input:  A         Operand 1
;               X         Operand 2
;
;       Call:   CALL       HWDIV_8_8_8
;
;       Output: A         Operand1 div Operand2
;               Z-flag
; This function can be used as replacement for the library function ?UC_DIV_L01
; by using the linker option -eHWDIV_8_8_8=?UC_DIV_L01
;------------------------------------------------------------------------------
        PUBLIC  HWDIV_8_8_8
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWDIV_8_8_8:
        PUSH  PSW
        DI

        ; select division mode
        MOV   MDUC, #0x80

        MOVW  MDAH,AX                ; temp. storage       
        
        ; store first parameter to HWMDU        
        CLRB  X
        XCH   A,X
        MOVW  MDAL,AX
        
        ; store second parameter to HWMDU
        MOVW  AX,MDAH
        CLRB  A
        MOVW  MDBL,AX
        
        CMP0  X                   ; divison by zero ?                   
        MOV   A,MDAL
        BZ    LABEL02

        ; set high words of HWMDU
        MOVW  MDAH,#0x0000
        MOVW  MDBH,#0x0000

        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        
        ; get result
        MOVW  AX,MDAL
        XCH   A,X
        
LABEL02:
        ; set / clear Z-Flag according to the result
        POP   PSW
        CMP0  A

        RET
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;       Modulo Operation of two unsigned chars
;
;       Input:  A         Operand 1
;               X         Operand 2
;
;       Call:   CALL      HWMOD_8_8_8
;
;       Output: A         Operand1 modulo Operand2
;               Z-flag
; This function can be used as replacement for the library function ?UC_MOD_L01
; by using the linker option -eHWMOD_8_8_8=?UC_MOD_L01
;------------------------------------------------------------------------------
        PUBLIC  HWMOD_8_8_8
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWMOD_8_8_8:
        PUSH  PSW
        DI

        ; select division mode
        MOV   MDUC, #0x80

        MOVW  MDAH,AX                ; temp. storage       
        
        ; store first parameter to HWMDU        
        CLRB  X
        XCH   A,X
        MOVW  MDAL,AX
        
        ; store second parameter to HWMDU
        MOVW  AX,MDAH
        CLRB  A
        MOVW  MDBL,AX
        
        CMP0  X                   ; divison by zero ?                   
        CLRB  A
        BZ    LABEL12

        ; set high words of HWMDU
        MOVW  MDAH,#0x0000
        MOVW  MDBH,#0x0000

        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        
        ; get result
        MOVW  AX,MDCL
        XCH   A,X
        
LABEL12:
        ; set / clear Z-Flag according to the result
        POP   PSW
        CMP0  A

        RET
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;       Division of two unsigned ints
;
;       Input:  AX         Operand 1
;               BC         Operand 2
;
;       Call:   CALL       HWDIV_16_16_16
;
;       Output: AX         Operand1 div Operand2
;               Z-flag
; This function can be used as replacement for the library function ?UI_DIV_L02
; by using the linker option -eHWDIV_16_16_16=?UI_DIV_L02
;------------------------------------------------------------------------------
        PUBLIC  HWDIV_16_16_16
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWDIV_16_16_16:
        PUSH  PSW
        DI

        ; set high words of HWMDU
        MOVW  MDAH,#0x0000
        MOVW  MDBH,#0x0000
        
        ; select division mode
        MOV   MDUC, #0x80
        
        ; store first parameter to HWMDU
        MOVW  MDAL,AX
        MOVW  AX,BC
        MOVW  MDBL,AX
        
        CMPW  AX, #0x0000          ; low word zero ?                   
        MOV   A,MDAL
        XCH   A,X
        BZ    LABEL22

        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        
        ; get result
        MOVW  AX,MDAL
        
LABEL22:
        ; set / clear Z-Flag according to the result
        POP   PSW
        CMPW  AX, #0x0000

        RET
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;       Modulo Operation of two unsigned ints
;
;       Input:  AX         Operand 1
;               BC         Operand 2
;
;       Call:   CALL       HWMOD_16_16_16
;
;       Output: AX         Operand1 modulo Operand2
;               Z-flag
; This function can be used as replacement for the library function ?UI_MOD_L02
; by using the linker option -eHWMOD_16_16_16=?UI_MOD_L02
;------------------------------------------------------------------------------
        PUBLIC  HWMOD_16_16_16
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWMOD_16_16_16:
        PUSH  PSW
        DI

        ; set high words of HWMDU
        MOVW  MDAH,#0x0000
        MOVW  MDBH,#0x0000
        
        ; select division mode
        MOV   MDUC, #0x80
        
        ; store first parameter to HWMDU
        MOVW  MDAL,AX
        MOVW  AX,BC
        MOVW  MDBL,AX
        
        CMPW  AX, #0x0000          ; low word zero ?                   
        CLRB  A
        XCH   A,X
        BZ    LABEL32

        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        
        ; get result
        MOVW  AX,MDCL
        
LABEL32:
        ; set / clear Z-Flag according to the result
        POP   PSW
        CMPW  AX, #0x0000

        RET
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;       Division of two unsigned longs
;
;       Input:  AX, BC     Operand 1
;               Stack      Operand 2
;
;       Call:   CALL       HWDIV_32_32_32
;
;       Output: AX, BC     Operand1 div Operand2
;               Z-flag
; This function can be used as replacement for the library function ?UL_DIV_L03
; by using the linker option -eHWDIV_32_32_32=?UL_DIV_L03
;------------------------------------------------------------------------------
        PUBLIC  HWDIV_32_32_32
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWDIV_32_32_32:
        PUSH  HL       
        PUSH  PSW
        DI

        ; select division mode
        MOV   MDUC, #0x80
        
        ; store first parameter to HWMDU
        MOVW  MDAL,AX
        MOVW  AX,BC
        MOVW  MDAH,AX
        
        ; store second parameter to HWMDU
        MOVW  HL,SP
        MOVW  AX,[HL+10]
        CMPW  AX, #0x0000          ; high word zero ?                   
        BZ    LABEL43
        MOVW  MDBH,AX        
        MOVW  AX,[HL+8]       
        MOVW  MDBL,AX
        BR    LABEL44
LABEL43:        
        MOVW  MDBH,AX        
        MOVW  AX,[HL+8]       
        CMPW  AX, #0x0000          ; low word zero ?                   
        MOVW  MDBL,AX
        BNZ   LABEL44
        
        ; division by zero
        ; clean up stack
        POP   PSW
        CLRW  AX
        CLRW  BC
        SET1  PSW.6      
        BR    LABEL42

LABEL44:
        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        ; clean up stack
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
                
        ; get result
        MOVW  AX,MDAH
        MOVW  BC,AX
        MOVW  AX,MDAL

        POP   PSW
        
        ; set / clear Z-Flag according to the result
        XCHW  AX,BC
        CMPW  AX, #0x0000
        XCHW  AX,BC
        SKNZ
        CMPW  AX, #0x0000
LABEL42:
        POP   HL
        RET
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;       Modulo Operation of two unsigned longs
;
;       Input:  AX, BC     Operand 1
;               Stack      Operand 2
;
;       Call:   CALL       HWMOD_32_32_32
;
;       Output: AX, BC     Operand1 modulo Operand2
;               Z-flag
; This function can be used as replacement for the library function ?UL_MOD_L03
; by using the linker option -eHWMOD_32_32_32=?UL_MOD_L03
;------------------------------------------------------------------------------
        PUBLIC  HWMOD_32_32_32
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWMOD_32_32_32:
        PUSH  HL       
        PUSH  PSW
        DI

        ; select division mode
        MOV   MDUC, #0x80
        
        ; store first parameter to HWMDU
        MOVW  MDAL,AX
        MOVW  AX,BC
        MOVW  MDAH,AX
        
        ; store second parameter to HWMDU
        MOVW  HL,SP
        MOVW  AX,[HL+10]
        CMPW  AX, #0x0000          ; high word zero ?                   
        BZ    LABEL53
        MOVW  MDBH,AX        
        MOVW  AX,[HL+8]       
        MOVW  MDBL,AX
        BR    LABEL54
LABEL53:        
        MOVW  MDBH,AX        
        MOVW  AX,[HL+8]       
        CMPW  AX, #0x0000          ; low word zero ?                   
        MOVW  MDBL,AX
        BNZ   LABEL54
        
        ; division by zero
        ; clean up stack
        POP   PSW
        MOVW  AX,#0xF368          
        CLRW  BC
        BR    LABEL52

LABEL54:
        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        ; clean up stack
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
                
        ; get result
        MOVW  AX,MDCH
        MOVW  BC,AX
        MOVW  AX,MDCL

        POP   PSW
        
        ; set / clear Z-Flag according to the result
        XCHW  AX,BC
        CMPW  AX, #0x0000
        XCHW  AX,BC
        SKNZ
        CMPW  AX, #0x0000
LABEL52:
        POP   HL
        RET
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;       Division of two signed chars
;
;       Input:  A         Operand 1
;               X         Operand 2
;
;       Call:   CALL       HWSDIV_8_8_8
;
;       Output: A          Operand1 div Operand2
;               Z-flag
; This function can be used as replacement for the library function ?SC_DIV_L01
; by using the linker option -eHWSDIV_8_8_8=?SC_DIV_L01
;------------------------------------------------------------------------------
        PUBLIC   HWSDIV_8_8_8
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWSDIV_8_8_8:
        PUSH  PSW
        DI
        
        ; select division mode
        MOV   MDUC, #0x80
        
        MOVW  MDAH,AX             ; temp. storage 
        CLRB  X        
        ; store first parameter to HWMDU
        BF    A.7, LABEL61         ; negative value ?
        SUB   X,A
        CLRB  A
        XOR   S:NEG_Flag,#0xFF    ; invert negative flag
        SKNZ
LABEL61:
        XCH   A,X
LABEL62:
        MOVW  MDAL,AX

        ; store second parameter to HWMDU
        MOVW  AX,MDAH
        XCH   A,X
        CLRB  X
        BF    A.7, LABEL63         ; negative value ?
        SUB   X,A
        CLRB  A
        XOR   S:NEG_Flag,#0xFF    ; invert negative flag
        BR    LABEL64
LABEL63:
        XCH   A,X
LABEL64:
        MOVW  MDBL,AX        
        
        CMP0  X                   ; divison by zero ?                   
        CLRB  A
        BZ    LABEL65
        
        ; set high words of HWMDU
        MOVW  MDAH,#0x0000
        MOVW  MDBH,#0x0000        

        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        
LABEL65:
        ; get result
        MOVW  AX,MDAL

        CMP   S:NEG_Flag,#0x00          
        SKNZ                                            
        XCH   A,X                                       
        SKZ 
        SUB   A,X               
     
        ; clear negative flag
        CLRB  S:NEG_Flag
        POP   PSW
        
        ; set / clear Z-Flag according to the result
        CMP0  A

        RET
       
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;       Modulo Operation of two signed chars
;
;       Input:  A         Operand 1
;               X         Operand 2
;
;       Call:   CALL       HWSMOD_8_8_8
;
;       Output: A          Operand1 modulo Operand2
;               Z-flag
; This function can be used as replacement for the library function ?SC_MOD_L01
; by using the linker option -eHWSMOD_8_8_8=?SC_MOD_L01
;------------------------------------------------------------------------------
        PUBLIC   HWSMOD_8_8_8
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWSMOD_8_8_8:
        PUSH  PSW
        DI
        
        ; select division mode
        MOV   MDUC, #0x80
        
        MOVW  MDAH,AX             ; temp. storage 
        CLRB  X        
        ; store first parameter to HWMDU
        BF    A.7, LABEL71         ; negative value ?
        SUB   X,A
        CLRB  A
        XOR   S:NEG_Flag,#0xFF    ; invert negative flag
        SKNZ
LABEL71:
        XCH   A,X
LABEL72:
        MOVW  MDAL,AX

        ; store second parameter to HWMDU
        MOVW  AX,MDAH
        XCH   A,X
        CLRB  X
        BF    A.7, LABEL73         ; negative value ?
        SUB   X,A
        CLRB  A
        BR    LABEL74
LABEL73:
        XCH   A,X
LABEL74:
        MOVW  MDBL,AX               
        CMP0  X                   ; divison by zero ?                   
        CLRB  A
        BZ    LABEL75
        
        ; set high words of HWMDU
        MOVW  MDAH,#0x0000
        MOVW  MDBH,#0x0000        

        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        
        ; get result
        MOVW  AX,MDCL

        CMP   S:NEG_Flag,#0x00          
        SKNZ                                            
        XCH   A,X                                       
        SKZ 
        SUB   A,X               
LABEL75:    
        ; clear negative flag
        CLRB  S:NEG_Flag
        POP   PSW
        
        ; set / clear Z-Flag according to the result
        CMP0  A

        RET
       
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;       Division of two signed ints
;
;       Input:  AX         Operand 1
;               BC         Operand 2
;
;       Call:   CALL       HWSDIV_16_16_16
;
;       Output: AX         Operand1 div Operand2
;               Z-flag
; This function can be used as replacement for the library function ?SI_DIV_L02
; by using the linker option -eHWSDIV_16_16_16=?SI_DIV_L02
;------------------------------------------------------------------------------
        PUBLIC   HWSDIV_16_16_16
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWSDIV_16_16_16:
        PUSH  HL
        PUSH  PSW
        DI

        ; set high words of HWMDU
        MOVW  MDAH,#0x0000
        MOVW  MDBH,#0x0000
        
        ; select division mode
        MOV   MDUC, #0x80
        
        ; store first parameter to HWMDU
        BF    A.7, LABEL81         ; negative value ?
        MOVW  HL,AX
        CLRW  AX
        SUB   A,L
        XCH   A,X
        SUBC  A,H
        XOR   S:NEG_Flag,#0xFF    ; invert negative flag
LABEL81:
        MOVW  MDAL,AX

        ; store second parameter to HWMDU
        MOVW  AX,BC
        BF    A.7, LABEL82         ; negative value ?
        MOVW  HL,AX
        CLRW  AX
        SUB   A,L
        XCH   A,X
        SUBC  A,H
        XOR   S:NEG_Flag,#0xFF    ; invert negative flag

LABEL82:
        MOVW  MDBL,AX        
        CMPW  AX, #0x0000         ; divisor equal zero
        MOV   A,MDAL
        XCH   A,X
        BZ    LABEL83

        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        
        ; get result
        MOVW  AX,MDAL
        CMP   S:NEG_Flag,#0x00
        BZ    LABEL83
        MOVW  HL,AX
        MOVW  AX,#0x0000 
        SUB   A,L
        XCH   A,X
        SUBC  A,H 
LABEL83:
        ; clear negative flag
        CLRB   S:NEG_Flag

        POP   PSW

        ; set / clear Z-Flag according to the result
        CMPW  AX, #0x0000

        POP   HL
        RET
       
;------------------------------------------------------------------------------
        

;------------------------------------------------------------------------------
;       Modulo Operation of two signed ints
;
;       Input:  AX         Operand 1
;               BC         Operand 2
;
;       Call:   CALL       HWSMOD_16_16_16
;
;       Output: AX         Operand1 modulo Operand2
;               Z-flag
; This function can be used as replacement for the library function ?SI_MOD_L02
; by using the linker option -eHWSMOD_16_16_16=?SI_MOD_L02
;------------------------------------------------------------------------------
        PUBLIC   HWSMOD_16_16_16
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWSMOD_16_16_16:
        PUSH  HL
        PUSH  PSW
        DI

        ; set high words of HWMDU
        MOVW  MDAH,#0x0000
        MOVW  MDBH,#0x0000
        
        ; select division mode
        MOV   MDUC, #0x80
        
        ; store first parameter to HWMDU
        BF    A.7, LABEL91         ; negative value ?
        MOVW  HL,AX
        CLRW  AX
        SUB   A,L
        XCH   A,X
        SUBC  A,H
        XOR   S:NEG_Flag,#0xFF    ; invert negative flag
LABEL91:
        MOVW  MDAL,AX

        ; store second parameter to HWMDU
        MOVW  AX,BC
        BF    A.7, LABEL92         ; negative value ?
        MOVW  HL,AX
        CLRW  AX
        SUB   A,L
        XCH   A,X
        SUBC  A,H
LABEL92:
        MOVW  MDBL,AX        
        CMPW  AX, #0x0000         ; divisor equal zero
        CLRB  A
        XCH   A,X
        BZ    LABEL93

        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        
        ; get result
        MOVW  AX,MDCL
        CMP   S:NEG_Flag,#0x00
        BZ    LABEL93
        MOVW  HL,AX
        CLRW  AX
        SUB   A,L
        XCH   A,X
        SUBC  A,H 
LABEL93:
        ; clear negative flag
        CLRB   S:NEG_Flag

        POP   PSW

        ; set / clear Z-Flag according to the result
        CMPW  AX, #0x0000

        POP   HL
        RET
       
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;       Division of two signed longs
;
;       Input:  AX, BC     Operand 1
;               Stack      Operand 2
;
;       Call:   CALL       HWSDIV_32_32_32
;
;       Output: AX, BC     Operand1 div Operand2
;               Z-flag
; This function can be used as replacement for the library function ?SL_DIV_L03
; by using the linker option -eHWSDIV_32_32_32=?SL_DIV_L03
;------------------------------------------------------------------------------
        PUBLIC  HWSDIV_32_32_32
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWSDIV_32_32_32:
        PUSH  HL       
        PUSH  PSW
        DI

        ; select division mode
        SET1  MDUC.7
        
        ; store first parameter to HWMDU       
        MOVW  MDAL,AX
        XCHW  AX,BC
        MOVW  MDAH,AX
        BF    A.7, LABEL105         ; negative value ?
        XCHW  AX,BC
#if defined(__USE_FAR_RT_CALLS__)
        CALL    F:CHGSIGN_32
#else
        CALL  CHGSIGN_32          ; change sign
#endif
        XOR   S:NEG_Flag,#0xFF    ; invert negative flag
        MOVW  MDAL,AX             ; reload value
        MOVW  AX,BC
        MOVW  MDAH,AX        
LABEL105:        
        ; store second parameter to HWMDU
        MOVW  HL,SP
        MOVW  AX,[HL+10]
        CMPW  AX, #0x0000          ; high word zero ?                   
        BZ    LABEL103

        BF    A.7, LABEL106         ; negative value ?
        XCHW  AX,BC
        MOVW  AX,[HL+8]       
#if defined(__USE_FAR_RT_CALLS__)
        CALL    F:CHGSIGN_32
#else
        CALL  CHGSIGN_32          ; change sign
#endif
        XOR   S:NEG_Flag,#0xFF    ; invert negative flag
        MOVW  MDBL,AX        
        MOVW  AX,BC       
        MOVW  MDBH,AX
        BR    LABEL104
LABEL106
        MOVW  MDBH,AX        
        MOVW  AX,[HL+8]       
        MOVW  MDBL,AX
        BR    LABEL104
LABEL103:        
        MOVW  MDBH,AX        
        MOVW  AX,[HL+8]       
        CMPW  AX, #0x0000          ; low word zero ?                   
        MOVW  MDBL,AX
        BNZ   LABEL104
        
        ; division by zero
        ; clear negative flag
        MOV   S:NEG_Flag,#0x00
        ; clean up stack
        POP   PSW
        CLRW  AX
        CLRW  BC
        SET1  PSW.6      
        BR    LABEL102

LABEL104:
        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
                
        ; get result
        MOVW  AX,MDAH
        MOVW  BC,AX
        MOVW  AX,MDAL
        
        ; check negative flag
        CMP   S:NEG_Flag,#0x00
        BZ    LABEL108
#if defined(__USE_FAR_RT_CALLS__)
        CALL    F:CHGSIGN_32
#else
        CALL  CHGSIGN_32          ; change sign
#endif
LABEL108
        ; clear negative flag
        MOV   S:NEG_Flag,#0x00

        POP   PSW

        ; set / clear Z-Flag according to the result
        XCHW  AX,BC
        CMPW  AX, #0x0000
        XCHW  AX,BC
        SKNZ
        CMPW  AX, #0x0000
LABEL102:
        POP   HL
        RET
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;       Modulo Operation of two signed longs
;
;       Input:  AX, BC     Operand 1
;               Stack      Operand 2
;
;       Call:   CALL       HWSMOD_32_32_32
;
;       Output: AX, BC     Operand1 modulo Operand2
;               Z-flag
; This function can be used as replacement for the library function ?SL_MOD_L03
; by using the linker option -eHWSMOD_32_32_32=?SL_MOD_L03
;------------------------------------------------------------------------------
        PUBLIC  HWSMOD_32_32_32
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
HWSMOD_32_32_32:
        PUSH  HL       
        PUSH  PSW
        DI

        ; select division mode
        MOV   MDUC, #0x80
        
        ; store first parameter to HWMDU       
        MOVW  MDAL,AX
        XCHW  AX,BC
        MOVW  MDAH,AX
        BF    A.7, LABEL115         ; negative value ?
        XCHW  AX,BC
#if defined(__USE_FAR_RT_CALLS__)
        CALL    F:CHGSIGN_32
#else
        CALL  CHGSIGN_32          ; change sign
#endif
        XOR   S:NEG_Flag,#0xFF    ; invert negative flag
        MOVW  MDAL,AX             ; reload value
        MOVW  AX,BC
        MOVW  MDAH,AX        
LABEL115:        
        ; store second parameter to HWMDU
        MOVW  HL,SP
        MOVW  AX,[HL+10]
        CMPW  AX, #0x0000          ; high word zero ?                   
        BZ    LABEL113

        BF    A.7, LABEL116         ; negative value ?
        XCHW  AX,BC
        MOVW  AX,[HL+8]       
#if defined(__USE_FAR_RT_CALLS__)
        CALL    F:CHGSIGN_32
#else
        CALL  CHGSIGN_32          ; change sign
#endif
        MOVW  MDBL,AX        
        MOVW  AX,BC       
        MOVW  MDBH,AX
        BR    LABEL114
LABEL116
        MOVW  MDBH,AX        
        MOVW  AX,[HL+8]       
        MOVW  MDBL,AX
        BR    LABEL114
LABEL113:        
        MOVW  MDBH,AX        
        MOVW  AX,[HL+8]       
        CMPW  AX, #0x0000          ; low word zero ?                   
        MOVW  MDBL,AX
        BNZ   LABEL114
        
        ; division by zero
        ; clear negative flag
        CLRB  S:NEG_Flag
        ; clean up stack
        POP   PSW
        MOVW  AX,#0xF366          
        CLRW  BC
        BR    LABEL112

LABEL114:
        ; start division mode
        SET1  MDUC.0              
        ; after 16 clocks the result is available
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
                
        ; get result
        MOVW  BC,MDCH
        MOVW  AX,MDCL
        
        ; check negative flag
        CMP0  S:NEG_Flag
        BZ    LABEL118
#if defined(__USE_FAR_RT_CALLS__)
        CALL    F:CHGSIGN_32
#else
        CALL  CHGSIGN_32          ; change sign
#endif
LABEL118
        ; clear negative flag
        CLRB  S:NEG_Flag

        POP   PSW

        ; set / clear Z-Flag according to the result
        XCHW  AX,BC
        CMPW  AX, #0x0000
        XCHW  AX,BC
        SKNZ
        CMPW  AX, #0x0000
LABEL112:
        POP   HL
        RET

;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;       Data Definition for signed division functions
;------------------------------------------------------------------------------
        SECTION `.sbss`:DATA:NOROOT(1)
NEG_Flag: DS 1
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;       Change sign of long 
;
;       Input:  AX, BC     Operand 
;
;       Call:   CALL       CHGSIGN_32
;
;       Output: AX, BC     -(Operand)
;------------------------------------------------------------------------------
#ifdef __USE_FAR_RT_CALLS__
        SECTION `.ftext`:CODE:NOROOT(0)
#else
        SECTION `.text`:CODE:NOROOT(0)
#endif        
CHGSIGN_32:
        PUSH HL
        MOVW HL,AX
        CLRW AX
        SUB  A,L
        XCH  A,X
        SUBC A,H

        MOVW HL,AX

        CLRW AX
        SUBC A,C
        XCH  A,X
        SUBC A,B
        
        XCHW AX,BC
        MOVW AX,HL
        
        POP  HL
        ret

;------------------------------------------------------------------------------

        END
