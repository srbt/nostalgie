{$A+,B-,D-,E+,F-,G+,I+,L-,N+,O-,R-,S-,V+,X-}
{$M 16384,0,655360}
unit StringCS;

interface

type
 PSortVec=^TSortVec;
 TSortVec=record
           Name:array [1..10] of Char;
           Table:array [0..255] of Char;
          end;

 PSortTbl=^TSortTbl;
 TSortTbl=record
           Count:Byte;
           SortVec:array [1..20] of TSortVec;
          end;

 TKey    = record
            OldCode:Word;
            NewCode:Byte;
           end;
 PKeyVec = ^TKeyVec;
 TKeyVec = record
            Size :Byte;
            Key  :array [1..255] of TKey;
           end;
 PShiftVec = ^TShiftVec;
 TShiftVec = record
              Size :Byte;
              Key  :array [1..6] of Word;
             end;
 TKeyboard = record
              Shift :PShiftVec;
              Keys  :array [0..6] of PKeyVec;
             end;
 PPrintFont=^TPrintFont;
 TPrintFont=array [Char] of array [0..15] of set of 0..7;
 TPrinter=Text;

function GetSortInfo:Word; { Horni byte = pocet tabulek, dolni = cislo aktualni tabulky }
procedure SetSortTable(Number:Byte); { Nastaveni cisla komparacni tabulky }
function GetSortName(Number:Byte):String; { Vraci jmeno komparacni tabulky 0=aktualni }
procedure LoadSort(Sort:Pointer); { Nastaveni sady komparacnich tabulek }
procedure KamenictiSOR;           { Tabulka pro kod Kamenickych }
function LoadSORFile(FName:String):Pointer;
function CompStr(Source,Dest:String):Integer; { Kompar. retezcu v kodu tridici tabulky }

function GetUpperInfo:Word; { Horni byte = pocet tabulek, dolni = cislo aktualni tabulky }
procedure SetUpperTable(Number:Byte); { Nastaveni cisla prevodni tabulky }
function GetUpperName(Number:Byte):String; { Vraci jmeno prevodni tabulky 0=aktualni }
procedure LoadUpper(Sort:Pointer); { Nastaveni sady komparacnich tabulek }
procedure KamenictiUPC;           { Tabulka pro kod Kamenickych }
function LoadUPCFile(FName:String):Pointer;
function Upper(Source:String):String; { Kompar. retezcu v kodu tridici tabulky }
function UpCase(C:Char):Char;     { Nahrada funkce UpCase z jednotky System }

procedure LoadFont(Num:Byte; Font:Pointer; Size:Byte); { Nastaveni EGA/VGA fontu }
procedure LoadCharsFont(Num:Byte; Odkud, Kolik: Integer; Font:Pointer);
procedure ResetFont(Num:Byte);              { Nastaveni EGA/VGA fontu z ROM }
procedure KamenictiFNT;                     { EGA/VGA fonty kodu Kamenickych }
function LoadFNTFile(Num:Byte; FName:String):Boolean;
procedure SaveFont(Font:Pointer);

function LoadKBD(Kbd: Pointer):Boolean;            { Nastaveni narodni klavesnice }
function SwitchKbd(Kbd: Pointer):Boolean;          { Nahrazeni stavajici narodni klavesnice jinou }
procedure ResetKBD;                         { Nastaveni standartni klavesnice }
procedure KamenictiKBD;                     { Klavesnice pro kod Kamenickych }
procedure IBMKBD;                           { Standardni klavesnice }
function LoadKBDFile(FName:String):Pointer;

procedure PrintLn(var F:TPrinter;S:String);
procedure SetPrintFont(P:Pointer; Mode:Byte);

implementation

uses Dos;

const
 UpperTbl:PSortTbl=@KamenictiUPC;
 CurrUpper:PSortVec=@PSortTbl(@KamenictiUPC)^.SortVec[1];
 CurrUpperNum:Byte=1;
 SortTbl:PSortTbl=@KamenictiSOR;
 CurrSort:PSortVec=@PSortTbl(@KamenictiSOR)^.SortVec[1];
 CurrSortNum:Byte=1;
 PrintFont:PPrintFont=nil;
 PrintMode:Byte=0;
 ModeChars:array [0..3] of String[2]=('K','L','*'#4,'*'#6);

procedure SetPrintFont(P:Pointer; Mode:Byte);
 begin
  PrintFont:=P;
  PrintMode:=Mode;
 end;

procedure PrintLn(var F:TPrinter;S:String);
 var I,J,K,L,T:Byte;
 procedure PrintStr(C:String);
  var I:Byte;
  begin
   for I:=1 to Byte(C[0]) do Write(F,C[I]);
  end;
 begin
  for L:=0 to 1 do
  begin
   PrintStr(^['0'^[+ModeChars[PrintMode]+Char(Lo(Byte(S[0])*8))+Char(Hi(Byte(S[0])*8)));
   for I:=1 to Byte(S[0]) do
    for J:=7 downto 0 do
    begin
     T:=0;
     for K:=0 to 7 do T:=T or (Byte(J in PrintFont^[S[I]][7-K+8*L]) shl K);
     PrintStr(Char(T));
    end;
   PrintStr(^M^J);
  end;
  PrintStr(^['2');
 end;

function GetSortInfo:Word; assembler;
 asm
  LES SI,SortTbl
  MOV AH,BYTE [ES:SI]
  MOV AL,CurrSortNum
 end;

procedure SetSortTable(Number:Byte);
 begin
  if (SortTbl<>nil)and(Number<=SortTbl^.Count)and(Number>0) then
  begin CurrSort:=@SortTbl^.SortVec[Number]; CurrSortNum:=Number; end
  else begin CurrSort:=nil; CurrSortNum:=0; end;
 end;

function GetSortName(Number:Byte):String;
 begin
  if (SortTbl<>nil)and(Number<=SortTbl^.Count) then
   if Number=0 then GetSortName:=CurrSort^.Name
               else GetSortName:=SortTbl^.SortVec[Number].Name
               else GetSortName:='';
 end;

procedure LoadSort(Sort:Pointer);
 begin
  SortTbl:=Sort;
  SetSortTable(1);
 end;

procedure KamenictiSOR; external;
{$L KAMENSOR.OBJ}

function LoadSORFile(FName:String):Pointer;
 var
  F:File;
  P:Pointer;
 begin
  if FName='KAMENICTI' then begin LoadSORFile:=@KamenictiSOR; exit; end;
  LoadSORFile:=nil;
  Assign(F,FName);
  {$I-} Reset(F,1); {$I+}
  if IOResult<>0 then Exit;
  if MaxAvail<FileSize(F) then begin Close(F); Exit; end;
  GetMem(P,FileSize(F));
  BlockRead(F,P^,FileSize(F));
  Close(F);
  LoadSORFile:=P;
 end;

function CompStr(Source,Dest:String):Integer; assembler;
 asm
  PUSH DS
  LDS SI,Source
  LES DI,Dest
  LODSB
  CMP AL,[ES:DI]
  JLE @Delka
  MOV AL,[ES:DI]
@Delka:
  INC DI
  XOR CX,CX
  MOV CL,AL
  REPE CMPSB
  JZ @Rovno1
  MOV DX,ES
  MOV AX,DS
  POP DS
  LES BX,CurrSort
  MOV CX,ES
  OR CX,CX
  JNZ @Comp
  OR BX,BX
  JNZ @Comp
  MOV ES,DX
  PUSH DS
  MOV DS,AX
  MOV AL,Byte [DS:SI-1]
  CMP AL,Byte [ES:DI-1]
  JB @Vetsi
  MOV AX,-1
  JMP @Konec
@Comp:
  ADD BX,10
  PUSH DS
  MOV DS,AX
  PUSH BX
  ADD BL,Byte [DS:SI-1]
  ADC BH,0
  MOV AL,[ES:BX]
  POP BX
  PUSH ES
  MOV ES,DX
  ADD BL,Byte [ES:DI-1]
  ADC BH,0
  POP ES
  CMP [ES:BX],AL
  JB @Vetsi
  MOV AX,-1
  JMP @Konec
@Vetsi:
  MOV AX,1
  JMP @Konec
@Rovno1:
  LDS SI,Source
  LES DI,Dest
  LODSB
  CMP AL,[ES:DI]
  JAE @Vetsi_rovno
  MOV AX,-1
  JMP @Konec
@Vetsi_rovno:
  JZ @Rovno
  MOV AX,1
  JMP @Konec
@Rovno:
  XOR AX,AX
@Konec:
  POP DS
 end;

function GetUpperInfo:Word; assembler;
 asm
  LES SI,UpperTbl
  MOV AH,BYTE [ES:SI]
  MOV AL,CurrUpperNum
 end;

procedure SetUpperTable(Number:Byte);
 begin
  if (UpperTbl<>nil)and(Number<=UpperTbl^.Count)and(Number>0) then
  begin CurrUpper:=@UpperTbl^.SortVec[Number]; CurrUpperNum:=Number; end
  else begin CurrUpper:=nil; CurrUpperNum:=0; end;
 end;

function GetUpperName(Number:Byte):String;
 begin
  if (UpperTbl<>nil)and(Number<=UpperTbl^.Count) then
   if Number=0 then GetUpperName:=CurrUpper^.Name
               else GetUpperName:=UpperTbl^.SortVec[Number].Name
               else GetUpperName:='';
 end;

procedure LoadUpper(Sort:Pointer);
 begin
  UpperTbl:=Sort;
  SetUpperTable(1);
 end;

procedure KamenictiUPC; external;
{$L KAMENUPC.OBJ}

function LoadUPCFile(FName:String):Pointer;
 var
  F:File;
  P:Pointer;
 begin
  if FName='KAMENICTI' then begin LoadUPCFile:=@KamenictiUPC; exit; end;
  LoadUPCFile:=nil;
  Assign(F,FName);
  {$I-} Reset(F,1); {$I+}
  if IOResult<>0 then Exit;
  if MaxAvail<FileSize(F) then begin Close(F); Exit; end;
  GetMem(P,FileSize(F));
  BlockRead(F,P^,FileSize(F));
  Close(F);
  LoadUPCFile:=P;
 end;

function UpCase(C:Char):Char;
 begin
  if (UpperTbl<>nil)and(CurrUpper<>nil) then UpCase:=CurrUpper^.Table[Byte(C)]
                                        else UpCase:=System.UpCase(C);
 end;

function Upper(Source:String):String;
 var
  S:String;
 begin
  if Source='' then Upper:='' else
  begin
   if (UpperTbl<>nil) then
    for S[0]:=#1 to Source[0] do S[Byte(S[0])]:=CurrUpper^.Table[Byte(Source[Byte(S[0])])]
    else for S[0]:=#1 to Source[0] do S[Byte(S[0])]:=System.UpCase(Source[Byte(S[0])]);
   Upper:=S;
  end;
 end;

procedure LoadFont(Num:Byte; Font:Pointer; Size:Byte);
 begin
  asm
   PUSH BP
   MOV AX,$1100
   MOV CX,256
   MOV DX,0
   MOV BH,Size
   MOV BL,SS:Num
   LES BP,SS:Font
   INT $10
   POP BP
  end;
 end;

procedure LoadCharsFont(Num:Byte; Odkud, Kolik: Integer; Font:Pointer);
 begin
  asm
   PUSH BP
   MOV AX,$1100
   MOV CX,SS:Kolik
   MOV DX,SS:Odkud
   MOV BH,16
   MOV BL,SS:Num
   LES BP,SS:Font
   INT $10
   POP BP
  end;
 end;

procedure ResetFont(Num:Byte);
 begin
  asm
   MOV AX,$1104
   MOV BL,SS:Num
   INT $10
  end;
 end;

procedure KamenictiFNT; external;
{$L KAMENFNT.OBJ}

function LoadFNTFile(Num:Byte; FName:String):Boolean;
 var
  F:File;
  A:Pointer;
  Len:Word;
  M:Byte;
 begin
  LoadFNTFile:=False;
  Assign(F,FName);
  M:=FileMode; FileMode:=0;
  {$I-} Reset(F,1); {$I+}
  FileMode:=M;
  if (IOResult<>0) then Exit;
  Len:=FileSize(F);
  if Len and $FF<>0 then begin Close(F); Exit end;
  GetMem(A,Len);
  {$I-} BlockRead(F,A^,Len);
  Close(F); {$I+}
  if (IOResult=0) then LoadFont(Num,A,Len shr 8);
  FreeMem(A,Len);
  LoadFNTFile:=True;
 end;

type THead=array [1..11] of Char;
var
  KbdIntVec : Procedure;
  Tail      : Word absolute $0:$41C;
  Head      : Word absolute $0:$41A;
  OldTail   : Byte;
  Znak      : ^Word;
  Rezim     : 0..6;
  I         : Byte;
  KeyBoard  : TKeyBoard;

{$F+}
procedure Keyclick; interrupt;
begin
  OldTail:=Tail;
  inline ($9C); { PUSHF -- Push flags }
  KbdIntVec;
  if OldTail<>Tail then
  begin
   if Tail>30 then Znak:=Ptr($40,Tail-2)
              else Znak:=Ptr($40,60);
   if Rezim=0 then
   begin
    I:=1;
    while (I<=KeyBoard.Shift^.Size)and(KeyBoard.Shift^.Key[I]<>Znak^) do Inc(I);
    if (KeyBoard.Shift^.Key[I]=Znak^)and(I<=KeyBoard.Shift^.Size) then
    begin
     if Tail>30 then Dec(Tail,2) else Tail:=60;
     Rezim:=I;
     Exit;
    end;
   end;
   I:=1;
   with KeyBoard.Keys[Rezim]^ do
   begin
    while (I<=Size) and (Key[I].OldCode < Znak^) do Inc(I);
    if Key[I].OldCode=Znak^ then {Byte(}Znak^{)}:=Key[I].NewCode;
   end;
   Rezim:=0;
  end;
end;
{$F-}

function IncPtr(var Point:Pointer; V:Integer):Pointer;
 begin
  Inc(LongInt(Point),V);
  IncPtr:=Point;
 end;

function LoadKbd(Kbd: Pointer):Boolean;
 var I:Byte;
 begin
  ResetKbd;
  if THead(Kbd^)<>'ARNAY KBD.'#26 then begin LoadKbd:=false; Exit; end;
  LoadKbd:=true;
  with KeyBoard do
  begin
   Shift:=IncPtr(Kbd,21);
   Keys[0]:=IncPtr(Kbd,Shift^.Size*2+1);
   for I:=1 to Shift^.Size do Keys[I]:=IncPtr(Kbd,Keys[I-1]^.Size*3+1);
  end;
  Rezim:=0;
  GetIntVec($9,@KbdIntVec);
  SetIntVec($9,@KeyClick);
 end;

function SwitchKbd(Kbd: Pointer):Boolean;
 var I:Byte;
 begin
  if (THead(Kbd^)<>'ARNAY KBD.'#26)or(@KbdIntVec=nil) then begin SwitchKbd:=false; Exit; end;
  asm
   cli
  end;
  SwitchKbd:=true;
  with KeyBoard do
  begin
   Shift:=IncPtr(Kbd,21);
   Keys[0]:=IncPtr(Kbd,Shift^.Size*2+1);
   for I:=1 to Shift^.Size do Keys[I]:=IncPtr(Kbd,Keys[I-1]^.Size*3+1);
  end;
  Rezim:=0;
  asm
   sti
  end;
 end;

procedure ResetKbd;
 begin
  if @KbdIntVec<>nil then
  begin
   SetIntVec($9,@KbdIntVec);
   @KbdIntVec:=nil;
  end;
 end;

procedure KamenictiKBD; external;
{$L KAMENKBD.OBJ}

procedure IBMKBD; external;
{$L IBMKBD.OBJ}

function LoadKBDFile(FName:String):Pointer;
 var
  F:File;
  P:Pointer;
 begin
  if FName='KAMENICTI' then begin LoadKBDFile:=@KamenictiKBD; exit; end;
  LoadKBDFile:=nil;
  Assign(F,FName);
  {$I-} Reset(F,1); {$I+}
  if IOResult<>0 then Exit;
  if MaxAvail<FileSize(F) then begin Close(F); Exit; end;
  GetMem(P,FileSize(F));
  BlockRead(F,P^,FileSize(F));
  Close(F);
  LoadKBDFile:=P;
 end;

procedure SaveFont(Font:Pointer); assembler;
 asm
  PUSH DS
  LES DI, Font
  MOV AX,$A000
  MOV DS,AX
  XOR SI,SI
  CLI
  MOV DX,$3C4
  MOV AX,$0402;
  OUT DX,AX
  MOV AX,$0704;
  OUT DX,AX
  MOV DX,$3CE
  MOV AX,$0204;
  OUT DX,AX
  MOV AX,$0005;
  OUT DX,AX
  MOV AX,$0406;
  OUT DX,AX
@Smycka:
  MOV CX,16
  REP MOVSB
  ADD SI,16
  CMP SI,8192
  JNZ @Smycka
  MOV DX,$3C4
  MOV AX,$0302;
  OUT DX,AX
  MOV AX,$0304;
  OUT DX,AX
  MOV DX,$3CE
  MOV AX,$0004;
  OUT DX,AX
  MOV AX,$1005;
  OUT DX,AX
  XOR AX,AX
  MOV DS,AX
  MOV DX,$3CE
  MOV SI,$0449
  LODSB
  CMP AL,7
  JNZ @Barva
  MOV AX,$0A06
  JMP @NeBarva
@Barva:
  MOV AX,$0E06
@NeBarva:
  OUT DX,AX
  POP DS
  STI
 end;

var
 OldExitProc:Pointer;

procedure NewExitProc; far;
 begin
  ResetKbd;
  ExitProc:=OldExitProc;
 end;

begin
 @KbdIntVec:=nil;
 if LoadKbd(@IBMKBD) then
 begin
  OldExitProc:=ExitProc;
  ExitProc:=@NewExitProc;
 end;
end.