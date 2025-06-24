	MODEL TINY
	CODESEG
	ORG 100h
Start:		JMP Begin
MBR             DB 1 DUP (?)
Copyright       DB 'Universal boot utilities (MBACTIVE)  Version 1.0  ARNAY Software',13,10,10,'$' 
BadNumMSG       DB ' Syntaxe:     MBACTIVE n',13,10,10
                DB '              n ... cislo aktivovane partition [1..4]',13,10,10,'$'
                DB 512 - ($ - OFFSET MBR) DUP (?)
OkMSG           DB ' Partition uspesne aktivovana.',13,10,'$'
DiskMSG         DB ' Chyba V/V operace disku.',13,10,'$'
Begin:          MOV DX,OFFSET Copyright
                MOV AH,09h
                INT 21h
                MOV BL,[DS:82h]
                CMP BL,'1'
                JB BadNumber
                CMP BL,'4'
                JA BadNumber
                MOV AX,0201h
                MOV BX,OFFSET MBR
                MOV CX,0001h
                MOV DX,0080h
                INT 13h
                JC DiskError
                MOV byte ptr [OFFSET MBR + 1BEh],0
                MOV byte ptr [OFFSET MBR + 1CEh],0
                MOV byte ptr [OFFSET MBR + 1DEh],0
                MOV byte ptr [OFFSET MBR + 1EEh],0
                MOV BL,[DS:82h]
                AND BL,0Fh
                SHL BL,4
                XOR BH,BH
                ADD BX,OFFSET MBR + 1BEh - 16
                MOV byte ptr [BX],80h
                MOV AX,0301h
                MOV BX,OFFSET MBR
                MOV CX,0001h
                MOV DX,0080h
                INT 13h
                JC DiskError
                MOV DX,OFFSET OkMSG
                XOR AL,AL
Konec:          PUSH AX
                MOV AH,9h
                INT 21h
                POP AX
                MOV AH,4Ch
                INT 21h
DiskError:      MOV DX,OFFSET DiskMSG
                MOV AL,2
                JMP Konec
BadNumber:      MOV DX,OFFSET BadNumMSG
                MOV AL,1
                JMP Konec
		END Start