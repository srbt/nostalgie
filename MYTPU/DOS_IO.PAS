unit Dos_IO;

 { Tato knihovna umo‘¤uje vyu‘¡vat k p©¡stupu na obrazovku a
   vstup z kl vesnice p©¡mo slu‘by DOSu a BIOSu }

interface
uses Dos;

const
 kbEsc       = $011B;  kbAltSpace  = $0200;  kbCtrlIns   = $0400;
 kbShiftIns  = $0500;  kbCtrlDel   = $0600;  kbShiftDel  = $0700;
 kbBack      = $0E08;  kbCtrlBack  = $0E7F;  kbShiftTab  = $0F00;
 kbTab       = $0F09;  kbAltQ      = $1000;  kbAltW      = $1100;
 kbAltE      = $1200;  kbAltR      = $1300;  kbAltT      = $1400;
 kbAltY      = $1500;  kbAltU      = $1600;  kbAltI      = $1700;
 kbAltO      = $1800;  kbAltP      = $1900;  kbCtrlEnter = $1C0A;
 kbEnter     = $1C0D;  kbAltA      = $1E00;  kbAltS      = $1F00;
 kbAltD      = $2000;  kbAltF      = $2100;  kbAltG      = $2200;
 kbAltH      = $2300;  kbAltJ      = $2400;  kbAltK      = $2500;
 kbAltL      = $2600;  kbAltZ      = $2C00;  kbAltX      = $2D00;
 kbAltC      = $2E00;  kbAltV      = $2F00;  kbAltB      = $3000;
 kbAltN      = $3100;  kbAltM      = $3200;  kbF1        = $3B00;
 kbF2        = $3C00;  kbF3        = $3D00;  kbF4        = $3E00;
 kbF5        = $3F00;  kbF6        = $4000;  kbF7        = $4100;
 kbF8        = $4200;  kbF9        = $4300;  kbF10       = $4400;
 kbHome      = $4700;  kbUp        = $4800;  kbPgUp      = $4900;
 kbGrayMinus = $4A2D;  kbLeft      = $4B00;  kbRight     = $4D00;
 kbGrayPlus  = $4E2B;  kbEnd       = $4F00;  kbDown      = $5000;
 kbPgDn      = $5100;  kbIns       = $5200;  kbDel       = $5300;
 kbShiftF1   = $5400;  kbShiftF2   = $5500;  kbShiftF3   = $5600;
 kbShiftF4   = $5700;  kbShiftF5   = $5800;  kbShiftF6   = $5900;
 kbShiftF7   = $5A00;  kbShiftF8   = $5B00;  kbShiftF9   = $5C00;
 kbShiftF10  = $5D00;  kbCtrlF1    = $5E00;  kbCtrlF2    = $5F00;
 kbCtrlF3    = $6000;  kbCtrlF4    = $6100;  kbCtrlF5    = $6200;
 kbCtrlF6    = $6300;  kbCtrlF7    = $6400;  kbCtrlF8    = $6500;
 kbCtrlF9    = $6600;  kbCtrlF10   = $6700;  kbAltF1     = $6800;
 kbAltF2     = $6900;  kbAltF3     = $6A00;  kbAltF4     = $6B00;
 kbAltF5     = $6C00;  kbAltF6     = $6D00;  kbAltF7     = $6E00;
 kbAltF8     = $6F00;  kbAltF9     = $7000;  kbAltF10    = $7100;
 kbCtrlPrtSc = $7200;  kbCtrlLeft  = $7300;  kbCtrlRight = $7400;
 kbCtrlEnd   = $7500;  kbCtrlPgDn  = $7600;  kbCtrlHome  = $7700;
 kbAlt1      = $7800;  kbAlt2      = $7900;  kbAlt3      = $7A00;
 kbAlt4      = $7B00;  kbAlt5      = $7C00;  kbAlt6      = $7D00;
 kbAlt7      = $7E00;  kbAlt8      = $7F00;  kbAlt9      = $8000;
 kbAlt0      = $8100;  kbAltMinus  = $8200;  kbAltEqual  = $8300;
 kbCtrlPgUp  = $8400;  kbAltBack   = $0800;  kbNoKey     = $0000;

 kbRightShift = $0001; {Prav˜ shift je stisknut}
 kbLeftShift  = $0002; {Lev˜ shift je stisknut}
 kbCtrlShift  = $0004; {Ctrl a shift jsou stisknuty}
 kbAltShift   = $0008; {Alt a shift jsou stisknuty}
 kbScrollState= $0010; {Scroll lock nastaven}
 kbNumState   = $0020; {Num lock nastaven}
 kbCapsState  = $0040; {Caps lock nastaven}
 kbInsState   = $0080; {Insert mode nastaven}
 kbShifts     = kbRightShift or kbLeftShift;

procedure PrintChar(C:Char);
 { Pomoc¡ slu‘eb DOSu vytiskne jeden znak na standardn¡ za©¡zen¡. }

procedure Print(S:String);
 { Pomoc¡ slu‘eb DOSu vytiskne ©etˆzec na standardn¡ za©¡zen¡. }

procedure CursorXY(X,Y:Byte);
 { Pomoc¡ slu‘eb BIOSu um¡st¡ kurzor na dan‚ m¡sto na obrazovce.
   Lev˜ horn¡ roh m  sou©adnice [0;0]. }

function InKey:Char;
 { Pomoc¡ slu‘eb DOSu na‡te jeden znak z kl vesnice (‡ek  na nˆj) }

function InStr:String;
 { P©e‡te ©etˆzec ze standartn¡ho za©¡zen¡. }

function GetKey:Word;
 { Pomoc¡ slu‘eb BIOSu p©e‡te £pln˜ k¢d zm ‡knut‚ kl vesy.
   (‡ek  na nˆj) }

function IfKey:Word;
 { Pomoc¡ slu‘eb BIOSu p©e‡te £pln˜ k¢d zm ‡knut‚ kl vesy.
   (ne‡ek  na nˆj - nen¡-li, vrac¡ 0) }

function PutKey(Key:Word):Byte;
 { Pomoc¡ slu‘eb BIOSu vlo‘¡ £pln˜ k¢d kl vesy do bufferu.
   (simuluje stisk kl vesy.) Pokud je v˜sledek = 1, byl buffer pln˜. }

procedure ClearBuffer;
 { Rychle a jednodu¨e vypr zdn¡ buffer kl vesnice. }

function DosInput(MaxLen:Byte):String;
 { Pomoc¡ slu‘eb DOSu p©e‡te ©etˆzec znak– o maxim ln¡ d‚lce MaxLen. }

function MakeDir(S:PathStr):Boolean;

procedure SetMemTop(MemTop: Pointer);

var
 XEof:Boolean;
 { Dojde-li p©i ‡ten¡ ze standartn¡ho za©¡zen¡ k na‡ten¡ znaku ^Z,
   je tato promˆnn  nastavena na True. }
 ShiftMask:Byte absolute 0:$0417;

implementation

procedure SetMemTop(MemTop: Pointer); assembler;
asm
	MOV	BX,MemTop.Word[0]
	ADD	BX,15
	MOV	CL,4
	SHR	BX,CL
	ADD	BX,MemTop.Word[2]
	MOV	AX,PrefixSeg
	SUB	BX,AX
	MOV	ES,AX
	MOV	AH,4AH
	INT	21H
end;

function DosInput(MaxLen:Byte):String;
 var
  Rec:record
       Max:Byte; S:String;
      end;
  begin
   with Rec do
   begin
    Max:=MaxLen;
   end;
   asm
    PUSH DS
    MOV AX,SS
    MOV DS,AX
    MOV AH,$0A
    LEA DX,Rec
    INT $21
    POP DS
   end;
   DosInput:=Rec.S;
  end;

procedure PrintChar(C:Char); assembler;
  asm
   MOV DL,SS:C;
   MOV AH,02
   INT $21
  end;

procedure Print(S:String);
 var
  I:Byte;
 begin
  for I:=1 to Byte(S[0]) do PrintChar(S[I]);
 end;

procedure CursorXY(X,Y:Byte); assembler;
 asm
  MOV AH,2
  XOR BH,BH
  MOV DH,Y
  MOV DL,X
  INT $10
 end;

function InKey:Char; assembler;
 asm
  MOV AH,01
  INT $21
 end;

function GetKey:Word; assembler;
 asm
  MOV AH,0
  INT $16
 end;

function IfKey:Word; assembler;
 asm
  MOV AH,1
  INT $16
  JNZ @Konec
  XOR AX,AX
@Konec:
 end;

function PutKey(Key:Word):Byte; assembler;
 asm
  MOV AH,5
  MOV CX,Key
  INT $16
 end;

procedure ClearBuffer;
 begin
  MemW[0:$041A]:=MemW[0:$041C];
 end;

function InStr:String;
 var
  S:String;
 begin
  S[0]:=#255;
  repeat
   Inc(S[0]);
   S[Byte(S[0])+1]:=InKey;
  until S[Byte(S[0])+1] in [#13,#26];
  XEof:=S[Byte(S[0])+1]=#26;
  InStr:=S;
 end;

function MakeDir(S:PathStr):Boolean;
 var
  I,N:Byte;
  SR:SearchRec;
 begin
  N:=Byte(S[0]);
  if (S[N]<>'\')and(N>0) then begin Inc(N); S[N]:='\'; end;
  S:=S+'.';
  for I:=2 to N do
   if S[I]='\' then
   begin
    S[0]:=Char(I-1);
    {$I-}
    MkDir(S);
    {$I+}
    if IOResult<>0 then;
   end;
   FindFirst(S,Directory,SR);
   MakeDir:=DosError=0;
 end;

begin
 XEof:=False;
end.