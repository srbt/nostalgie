unit TMouse;

interface
type
 TMouseRec=record
            X,Y:Integer;
            Pressed:Byte;
            Visible:Boolean;
           end;
 TLastRec=record
           Count,X,Y:Integer;
          end;
 TCursorType=(Soft,Hard);

var
 MRatioX,
 MRatioY:Integer;
 MGetMaxX,
 MGetMaxY:Integer;

const DoubleClick:Boolean=false;
const DoubleDelay:Word=8;

function MInit:Boolean;
function MWhereX:Integer;
function MWhereY:Integer;
function MPressed:Byte;
procedure MShow;
procedure MHide;
procedure MGetInfo(var Info:TMouseRec);
procedure MGotoXY(X,Y:Integer);
procedure MWindow(X,Y,X1,Y1:Integer);
procedure MScale(X,Y:Integer);
procedure MLastPressed(Button:Byte;var R:TLastRec);
procedure MLastRelease(Button:Byte;var R:TLastRec);
procedure MLightPen(OnOff:Boolean);
procedure MSetUserInt(Mask:Integer;Proc:Pointer);
procedure MDefGraph(X,Y:Integer;var Mask);
procedure MDefText(Typ:TCursorType;Scr, Cur:Integer);

implementation

var
 MVisible:Boolean;
 Timer:LongInt absolute $0:$046C;
 LastTime:LongInt;
const Unpress:Boolean=True;

function MInit:Boolean;
 var
  A:Byte;
 begin
  asm
   XOR AX,AX
   INT $33          { Inicializace }
   CMP AX,-1
   JNZ @Spatne
   MOV SS:A,1
   MOV AX,3         { Zjistovani meritka }
   INT $33
   PUSH CX
   PUSH DX
   MOV AX,4
   MOV CX,5000
   MOV DX,5000
   INT $33
   MOV AX,3
   INT $33
   MOV DS:MGetMaxX,CX
   MOV DS:MGetMaxY,DX
   MOV AX,4
   POP DX
   POP CX
   INT $33
   MOV DS:MVisible,0
   MOV DS:MRatioX,8
   MOV DS:MRatioY,16
   JMP @Konec
@Spatne:
   MOV SS:A,0
@Konec:
  end;
  LastTime:=Timer;
  MInit:=Boolean(A);
 end;

function MWhereX:Integer;
 var A:Integer;
 begin
  asm
   XOR CX,CX
   MOV AX,3
   INT $33
   MOV SS:A,CX
  end;
  MWhereX:=A;
 end;

function MWhereY:Integer;
 var A:Integer;
 begin
  asm
   XOR DX,DX
   MOV AX,3
   INT $33
   MOV SS:A,DX
  end;
  MWhereY:=A;
 end;

function MPressed:Byte;
 var A:Integer;
 begin
  asm
   XOR BX,BX
   MOV AX,3
   INT $33
   MOV SS:A,BX
  end;
  DoubleClick:=(Timer-LastTime<=DoubleDelay) and (A>0)and(Unpress);
  Unpress:=A=0;
  if not Unpress then LastTime:=Timer;
  MPressed:=A;
 end;

procedure MShow; assembler;
 asm
  CMP DS:MVisible,1
  JZ @Konec
  MOV AX,1
  INT $33
  MOV DS:MVisible,1
@Konec:
 end;

procedure MHide; assembler;
 asm
  CMP DS:MVisible,0
  JZ @Konec
  MOV AX,2
  INT $33
  MOV DS:MVisible,0
@Konec:
 end;

procedure MGetInfo(var Info:TMouseRec);
 var I:TMouseRec;
 begin
  asm
   MOV AX,3
   INT $33
   MOV SS:I.Pressed,Bl
   MOV SS:I.X,CX
   MOV SS:I.Y,DX
   MOV Dl,DS:MVisible
   MOV SS:I.Visible,Dl
  end;
  DoubleClick:=(Timer-LastTime<=DoubleDelay)and(I.Pressed>0)and Unpress;
  Unpress:=I.Pressed=0;
  if not Unpress then LastTime:=Timer;
  Info:=I;
 end;

procedure MGotoXY(X,Y:Integer);
 begin
  asm
   MOV AX,4
   MOV CX,SS:X
   MOV DX,SS:Y
   INT $33
  end
 end;

procedure MWindow(X,Y,X1,Y1:Integer);
 begin
  asm
   MOV AX,7
   MOV CX,SS:X
   MOV DX,SS:X1
   INT $33
   MOV AX,8
   MOV CX,SS:Y
   MOV DX,SS:Y1
   INT $33
  end
 end;

procedure MScale(X,Y:Integer);
 begin
  asm
   MOV AX,15
   MOV CX,SS:X
   MOV DS:MRatioX,CX
   MOV DX,SS:Y
   MOV DS:MRatioY,DX
   INT $33
  end
 end;

procedure MLastPressed(Button:Byte;var R:TLastRec);
 var R1:TLastRec;
 begin
  asm
   MOV AX,5
   MOV Bl,SS:Button
   INT $33
   MOV SS:R1.Count,BX
   MOV SS:R1.X,CX
   MOV SS:R1.Y,DX
  end;
  R:=R1;
 end;

procedure MLastRelease(Button:Byte;var R:TLastRec);
 var R1:TLastRec;
 begin
  asm
   MOV AX,6
   MOV Bl,SS:Button
   INT $33
   MOV SS:R1.Count,BX
   MOV SS:R1.X,CX
   MOV SS:R1.Y,DX
  end;
  R:=R1;
 end;

procedure MDefGraph(X,Y:Integer;var Mask);
 var S,O:Integer;
 begin
  S:=Seg(Mask);
  O:=Ofs(Mask);
  asm
   MOV AX,9
   MOV BX,SS:X
   MOV CX,SS:Y
   MOV ES,SS:S
   MOV DX,SS:O
   INT $33
  end
 end;

procedure MDefText(Typ:TCursorType;Scr, Cur:Integer);
 begin
  asm
   MOV AX,10
   MOV BH,0
   MOV BL,SS:Typ
   MOV CX,SS:Scr
   MOV DX,SS:Cur
   INT $33
  end
 end;

procedure MLightPen(OnOff:Boolean);
 begin
  asm
   CMP SS:OnOff,1
   JZ @ZAPNOUT
   MOV AX,14
   JMP @KONEC
@ZAPNOUT:
   MOV AX,13
@KONEC:
   INT $33
  end;
 end;

procedure MSetUserInt(Mask:Integer;Proc:Pointer);
 var
  S,O:Integer;
 begin
  S:=Seg(Proc^);
  O:=Ofs(Proc^);
  asm
   MOV AX,12
   MOV CX,SS:Mask
   MOV ES,SS:S
   MOV DX,SS:O
   INT $33
  end
 end;
end.