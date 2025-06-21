{$A+,B-,D+,E+,F-,G+,I+,L+,N+,O-,R-,S+,V+,X-}
{$M 16384,0,655360}
unit XMSApi;

interface
const
 XMSErr:Byte=0;

const
 xmOk=0;
 xmNoPresent=1;
 xmBadFn=$80;
 xmVDisk=$81;
 xmA20=$82;
 xmOutOfMemory=$A0;
 xmOutOfHandles=$A1;
 xmBadHandle=$A2;
 xmBadSHandle=$A3;
 xmBadSOffset=$A4;
 xmBadDHandle=$A5;
 xmBadDOffset=$A6;
 xmBadLength=$A7;
 xmBadOverlap=$A8;
 xmBadParity=$A9;
 xmBlockNotLocked=$AA;
 xmBlockLocked=$AB;
 xmLockOverlow=$AC;
 xmLockFail=$AD;

type
 PXMSPointer=^TXMSPointer;
 TXMSPointer=record
              case Handle:Word of
                 0:(Ptr:Pointer);
                 1:(Offset:LongInt);
             end;
 PXMSMoveStruct=^TXMSMoveStruct;
 TXMSMoveStruct=record
                 Length:LongInt;
                 Source,
                 Target:TXMSPointer;
                end;
const
 SXMSPointer=SizeOf(TXMSpointer);

function XMSPresent:Boolean;
procedure InitXMSApi;
function XMSVersion:Word;
function XMSMemAvail:Word;
function XMSMaxAvail:Word;
function XMSGetMem(Size:Word):Word;
procedure XMSFreeMem(Handle:Word);
procedure XMSMove(var Src,Dest:TXMSPointer;Len:LongInt);
procedure Ptr_XMSPtr(Src:Pointer;var Dest:TXMSPointer);
procedure XMSPtr(Handle:Word; Offs:Longint;var Dest:TXMSPointer);
procedure XMSReallocate(Handle:Word; Size:Word);

implementation
var
 XMSEntry:procedure;
 XMSMoveStruct:TXMSMoveStruct;

procedure XMSReallocate(Handle:Word; Size:Word); assembler;
 asm
  MOV AH,0Fh
  MOV BX,Size
  MOV DX,Handle
  CALL XMSEntry
  OR AX,AX
  JNZ @Konec
  MOV XMSErr,BL
@Konec:
 end;

procedure XMSPtr(Handle:Word; Offs:Longint;var Dest:TXMSPointer); assembler;
 asm
  CLD
  LES DI,Dest
  MOV AX,Handle
  STOSW
  MOV AX,Word (Offs)
  STOSW
  MOV AX,Word (Offs+2)
  STOSW
 end;

procedure Ptr_XMSPtr(Src:Pointer;var Dest:TXMSPointer); assembler;
 asm
  CLD
  LES DI,Dest
  XOR AX,AX
  STOSW
  MOV AX,Word (Src)
  STOSW
  MOV AX,Word (Src+2)
  STOSW
 end;

procedure XMSMove(var Src,Dest:TXMSPointer;Len:LongInt); assembler;
 asm
  PUSH DS
  MOV AX,DS
  MOV ES,AX
  CLD
  MOV DI,OFFSET XMSMoveStruct
  MOV AX,Word (Len)
  STOSW
  MOV AX,Word (Len+2)
  STOSW
  LDS SI,Src
  MOV CX,SXMSPointer / 2
  REP MOVSW
  LDS SI,Dest
  MOV CX,SXMSPointer / 2
  REP MOVSW
  POP DS
  MOV SI,OFFSET XMSMoveStruct
  MOV AH,0Bh
  CALL XMSEntry
  OR AX,AX
  JNZ @Konec
  MOV XMSErr,BL
@Konec:
 end;

procedure XMSFreeMem(Handle:Word); assembler;
 asm
  MOV AH,0Ah
  MOV DX,Handle
  CALL XMSEntry
  OR AX,AX
  JNZ @Konec
  MOV XMSErr,BL
@Konec:
 end;

function XMSGetMem(Size:Word):Word; assembler;
 asm
  MOV AH,09
  MOV DX,Size
  CALL XMSEntry
  OR AX,AX
  MOV AX,DX
  JNZ @Konec
  MOV XMSErr,BL
@Konec:
 end;

procedure NoXMSPresent; far; assembler;
 asm
  MOV XMSErr,xmNoPresent;
 end;

function XMSMemAvail:Word; assembler;
 asm
  MOV AH,8
  CALL XMSEntry
  OR AX,AX
  MOV AX,DX
  JNZ @Konec
  MOV XMSErr,BL
@Konec:
 end;

function XMSMaxAvail:Word; assembler;
 asm
  MOV AH,8
  CALL XMSEntry
  OR AX,AX
  JNZ @Konec
  MOV XMSErr,BL
@Konec:
 end;

function XMSPresent:Boolean; assembler;
 asm
  MOV AX,4300h
  INT 2Fh
  CMP AL,80h
  XOR AL,AL
  JNE @Konec
  INC AL
@Konec:
 end;

function GetXMSEntry:pointer; assembler;
 asm
  MOV AX,4310h
  INT 2Fh
  MOV AX,BX
  MOV DX,ES
 end;

procedure InitXMSApi;
 begin
  if XMSPresent then @XMSEntry:=GetXMSEntry else
  begin XMSEntry:=NoXMSPresent; XMSErr:=xmNoPresent; end;
 end;

function XMSVersion:Word; assembler;
 asm
  XOR AH,AH
  CALL XMSEntry
  XOR DL,1
  MOV XMSErr,DL
 end;

begin
 InitXMSApi;
end.