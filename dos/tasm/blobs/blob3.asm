P286                                    ;volba procesoru

model TINY                              ;pro COM soubor

DATASEG                                 ;datovy segment

TABULKA:
        include blobdata.inc
BLOB:                    
dw  30,  0,  0,  0, 30, 40,  0,  0, 30, 70,  0,  0, 30,100,  0,  0
dw  30,130,  0,  0, 60, 70,  0,  0, 90, 70,  0,  0, 90,100,  0,  0
dw  60,130,  0,  0, 90,130,  0,  0,150, 10,  0,  0,150, 40,  0,  0
dw 150, 70,  0,  0,150,100,  0,  0,150,130,  0,  0,180, 10,  0,  0
dw 180, 70,  0,  0,210, 10,  0,  0,210, 40,  0,  0,210, 70,  0,  0
dw 210,100,  0,  0,210,130,  0,  0

dw  20, 40, -2, -2,140, 10, -2,  2, 30, 20, -2, -3, 43, 40, -2,  3
dw  30, 30,  2, -2,280, 10,  2,  2,310, 60,  2, -3, 54, 50,  2,  3
dw  60, 40,  3, -2,180, 69,  3,  2   

Y dw 0           

UDATASEG                                ;neinicializovana data

BLOBOB  dw  4095 dup (?)

;***************************************************************************

CODESEG
        startupcode

;--- Nastaveni stacku a bufferu ---

        mov     AX,CS                   ;vzit code segment
        add     AX,1000h                ;posun o 64kB
        mov     ES,AX                   ;zde je BUFFER

;--- Nastaveni grafickeho modu a vymazani bufferu klavesnice ---

        mov     AX,13h                  ;graficky rezim
        int     10h
OPAK:   mov     AH,01h                  ;zjistit, zda je klavesa v bufferu
        int     16h
        jz      KONEC
        xor     AH,AH                   ;precist buffer
        int     16h
        jmp     OPAK
KONEC:

;--- Vytvoreni bitmapy ---

        mov     DI,offset BLOBOB
        mov     BX,4095
 OO:                                    ;vymazani bitmapy
        mov     [DI+BX],byte ptr 0      ;DS
        dec     BX  
        jnz     OO

FORY:   xor     AX,AX
        push    AX
FORX:
        sub     AX,31                   ;sqr(X-31)
        imul    AX                                      
        mov     CX,AX
        mov     AX,word ptr [Y]
        sub     AX,31
        imul    AX
        add     AX,CX
        pop     BX
        push    BX
        shl     BX,6
        add     BX,word ptr [Y]
        mov     DI,offset BLOBOB
        mov     SI,offset TABULKA
        cmp     AX,1022
        jnc     _ELSE
        mov     BP,AX
        mov     AL,DS:[SI+BP]
        mov     [DI+BX],AL              ;DS
        jmp     POK    
_ELSE:  xor     AL,AL  
        mov     [DI+BX],AL              ;DS
POK:    pop     AX     
        inc     AX     
        cmp     AX,63  
        push    AX     
        jnz     FORX   
        inc     word ptr [Y]
        cmp     word ptr [Y],63
        jnz     FORY   
        pop     AX     
                       
;--- Nastaveni palety ---
                       
        xor     AH,AH  
        xor     BX,BX  
        mov     AL,63  
        push    DS     
        push    ES       
        pop     DS     
PALOPAK:               
        mov     [BX],AL
        mov     [BX+1],byte ptr 0
        mov     [BX+2],AH
        mov     [BX+64*3],AH
        mov     [BX+1+64*3],AH
        mov     [BX+2+64*3],AL
        mov     [BX+128*3],AL                           
        mov     [BX+1+128*3],byte ptr 63
        mov     [BX+2+128*3],AH
        mov     [BX+64*3+128*3],byte ptr 0
        mov     [BX+1+64*3+128*3],AL
        mov     [BX+2+64*3+128*3],AL
        inc     AH     
        dec     AL     
        add     BX,3   
        cmp     BX,64*3-1
        jc      PALOPAK
        pop     DS     
                       
;--- Nastaveni palety pres BIOS
                       
        mov     AX,1012H                ;sluzba 10h, podsluzba 12h
        xor     BX,BX                   ;offset prvni barvy
        mov     CX,255                  ;pocet barev
        xor     DX,DX    
        int     10H                     ;volej BIOS
        cld              
                         
;*************************************************************************
;--- Hlavni smycka       
C0:                      
        xor     BP,BP                   ;pocitadlo 0..31
FORD:   mov     DI,offset BLOB
        mov     BX,BP    
        shl     BX,3                    ;D*8 (kazdy blob 8 byte)
                 
        mov     AX,[DI+BX]
        add     AX,[DI+BX+4]            ;posun
        mov     [DI+BX],AX
        mov     SI,AX                   ;X
        mov     AX,[DI+BX+2]
        add     AX,[DI+BX+6]
        cmp     AX,130-60
        jb      MENSI
        neg     word ptr [DI+BX+6]
MENSI:           
        mov     [DI+BX+2],AX
                         
;---Vykresleni blobu 63*63 do bufferu ---
                         
        shl     AX,6     
        mov     DI,AX                   ;ES:DI adresa bufferu
        shl     AX,2     
        add     DI,AX    
        add     DI,SI                   ;v DI je adresa X+Y*320
        xor     DX,DX    
        mov     SI,offset BLOBOB        ;DS:SI offset dat
                         
SMYC1:  mov     CX,64                   ;pocitadlo smycky 2
SMYC2:  lodsb                           ;nacteni barvy
        add     ES:[DI],AL              ;vykresleni bodu
        inc     DI                      ;dalsi bod
        dec     CX
        jnz     SMYC2                   ;jeden radek spocitany
        inc     DX                      ;pocitadlo vnejsi smycky
        add     DI,320-64               ;dalsi radek
        cmp     DX,63                   ;fsechny radky?
        jnz     SMYC1                   ;opakuj vnejsi smycku
        inc     BP                      ;dalsi blob
        cmp     BP,31    
        jnz     FORD                    ;opakuj pro vsechny bloby
                         
;---Buffer do obrazove pameti ---
                         
        push    DS       
        push    ES       
        mov     AX,ES    
        mov     DS,AX    
        xor     SI,SI                   ;DS:SI adresa bufferu
        mov     AX,0A000h                                    
        mov     ES,AX                   ;ES:DI adresa obrazove pameti
        xor     DI,DI       
        mov     CX,320*130/4
P386                     
        rep     movsd    
        pop     ES       
        pop     DS       
                         
;--- Smazat buffer ---   
                         
        xor     DI,DI                   ;ES:DI adresa bufferu
        mov     CX,320*200/4            ;pocet opakovani
        mov     EAX,0    
        rep     stosd    
P286                     
                         
;--- Zjisteni, zda byla stisknuta klavesa ---
                         
        mov     AH,01h                  ;je klavesa v bufferu ?
        int     16h      
        jz      C0       
                         

;--- Konec ---

        xor     AH,AH                   ;vymaz bufferu klavesnice
        int     16h
        mov     AX,03h                  ;textovy mod
        int     10h
        mov     AX,4c00h
        int     21h

END
