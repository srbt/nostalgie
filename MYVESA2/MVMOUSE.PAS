unit MVMouse;

interface

uses MyVesa;
const
 meOk=0;
 meNotInstalled=1;

var
 MouseError:Integer;
 MouseCursorDraw,
 MouseCursorHide:Procedure;
 MouseHidden:Word;
 MouseX,MouseY:Word;
 MousePressed:Word;

procedure MouseInit;
procedure MouseDone;
procedure MouseShow;
procedure MouseHide;

implementation

const
 Reentr:Boolean=False;

procedure NullCursor; far;
 begin
 end;

procedure NewHandler; far; assembler;
 asm
  PUSH DS
  MOV DI,seg @DATA
  MOV DS,DI
  CMP DS:Reentr,0
  JNZ @Hidden2
  MOV DS:Reentr,1
@Move:
  MOV DI,DS:MouseHidden
  OR DI,DI
  JNZ @Hidden
  PUSHA
  PUSH DS
  CALL MouseCursorHide
  POP DS
  POPA
@Hidden:
  MOV MousePressed,BX
  SHR CX,2
  SHR DX,2
  MOV MouseX,CX
  MOV MouseY,DX
  OR DI,DI
  JNZ @Hidden2
  PUSH DS
  CALL MouseCursorDraw
  POP DS
@Hidden2:
  MOV DS:Reentr,0
  POP DS
 end;

(*
procedure NewHandler; far; assembler;
 asm
  PUSH DS
  MOV CX,seg @DATA
  MOV DS,CX
  TEST AL,1
  JNZ @Move
  MOV MousePressed,BX
  JMP @Konec
@Move:
  MOV CX,MouseHidden
  OR CX,CX
  JNZ @Hidden
  PUSHA
  PUSH DS
  CALL MouseCursorHide
  POP DS
  POPA
@Hidden:
  MOV MousePressed,BX
  ADD SI,MouseX
  ADD DI,MouseY
  OR SI,SI
  JNB @DIOK1
  XOR SI,SI
@SIOK1:
  CMP SI,GetMaxX
  JNA @SIOK2
  MOV SI,GetMaxX
@SIOK2:
  MOV MouseX,SI
  OR DI,DI
  JNB @DIOK1
  XOR DI,DI
@DIOK1:
  CMP DI,GetMaxY
  JNA @DIOK2
  MOV DI,GetMaxY
@DIOK2:
  MOV MouseY,DI
  OR CX,CX
  JNZ @Hidden2
  CALL MouseCursorDraw
@Hidden2:
@Konec:
  POP DS
 end;
*)

procedure MouseInit; assembler;
 asm
  XOR AX,AX
  INT 33h
  INC AX
  JZ @MouseOK
  MOV MouseError,meNotInstalled
  JMP @Konec
@MouseOk:
  MOV AX,SEG NewHandler
  MOV ES,AX
  MOV AX,0Ch
  MOV CX,7Fh
  MOV DX,OFFSET NewHandler
  MOV BX,DX
  INT 33h
  mov ax,7
  mov cx,0
  mov dx,GetMaxX
  SHL DX,2
  int $33
  mov ax,8
  mov cx,0
  mov dx,GetMaxY  { Set YMAX for mouse windows }
  SHL DX,2
  int $33
{  mov ax,$000f
  mov cx,4
  mov dx,cx
  int $33}
  MOV AX,04
  XOR CX,CX
  MOV DX,CX
  INT 33h
@Konec:
 end;

procedure MouseDone; assembler;
 asm
  XOR AX,AX
  INT 33h
 end;

procedure MouseShow; assembler;
 asm
  CMP MouseHidden,1
  JB @Konec
  JNZ @NoHide
  MOV Reentr,1
  CALL MouseCursorDraw;
@NoHide:
  DEC MouseHidden
  MOV Reentr,0
@Konec:
 end;

procedure MouseHide; assembler;
 asm
  MOV Reentr,1
  INC MouseHidden
  CMP MouseHidden,1
  JNZ @NoHide
  CALL MouseCursorHide
@NoHide:
  MOV Reentr,0
 end;

begin
 MouseCursorDraw:=NullCursor;
 MouseCursorHide:=NullCursor;
 MouseX:=0; MouseY:=0; MousePressed:=0;
 MouseHidden:=1; MouseError:=0;
end.