unit prevody;

interface
{$IFDEF Linux}
 uses Linux;
 {$ASMMODE intel}
 {$DEFINE LUnsuported}
{$ELSE}
{$ENDIF}
 const PrevodyErr:Integer=0;
{$IFDEF Linux}
 const BackSlash='/';
{$ELSE}
 const BackSlash='\';
{$ENDIF}
 const kilo:longint=1024;
 const Cislice=['0'..'9'];
 const VPismena=['A'..'Z'];
 const MPismena=['a'..'z'];
 const CommentChars=['''','#',';','*'];
 const DosChars=Cislice+VPismena+['\','.',':','!','_'];
 const TrueChars=['A','Y','J','1','+','T','a','y','j','t'];
 const FalseChars=['N','0','-','F','n','f'];
 const Dny:array [0..6] of String[2]=('Ne','Po','Ut','St','Ct','Pa','So');
 const AlignNumber:Char='0';
 const Separator:Char=',';
 const LongDate:Boolean=True;
 const Real_StrPrecision:Integer=8;
 type Str80=String[80];
 function Bcd_Dec(value:byte):byte;
 function Dec_Bcd(value:byte):byte;
 function Long_Bin(Value:Longint; Len:Byte):String;
 function Bin_Long(S:String):Longint;
 function byte_str(value,kolik:byte):string;
 function long_com(value:longint;len:byte):string;
 function long_hex(value:longint;len:byte):string;
 function long_oct(value:longint;len:byte):string;
 function long_str(co:longint;mist:byte):string;
 function space(kolik:byte;co:char):string;
 function upper(s:string):string;
 function lower(s:string):string;
 function SubStr(S:String;B,E:Byte):String;
 function RTrim(S:String):String;
 function LTrim(S:String):String;
 function Trim(S:String):String;
 function DelChar(S:String; C:Char):String;
 function ReplaceChar(S:String; Old,ANew:Char):String;
 function RepStr(Pat:String;Len:Byte):String;
 function Str_Long(S:String):Longint;
 function Str_Real(S:String):Real;
 function Real_Str(R:Real):String;
 function Dir_Str(S:String;Len:Byte):String;
 function Prefix(S,Mask:String):Boolean;
 function ReplaceStr(S1,OldStr,NewStr:String):String;
 function PromptStr(S:String):String;
 function AddExt(FName:String;Ext:String):String;
 function ReplaceExt(FName:String;Ext:String):String;
 function TimeStr:String;
 function DateStr:String;
 function Min(X, Y: Integer): Integer;
 function Max(X, Y: Integer): Integer;
 function WMin(X, Y: Word): Word;
 function WMax(X, Y: Word): Word;
 {$IFNDEF LUnsuported}
 procedure ChangeB(var Source,Dest; Size:Word);
 procedure ChangeW(var Source,Dest; Size:Word);
 function CompareB(var Source,Dest; Size:Word):Integer;
 {$ENDIF}
 function GetReal(var S:String):Real;
 function GetInt(var S:String):LongInt;
 function GetStr(var S:String):String;
 function GetStr2(var S:String;C:Char):String;
 function LastPos(C:Char;S:String):Byte;
 function GetCurrDir:String;
 function GetCurrDisk:Char;
 function AddBackSlash(S:String):String;
 function RoundUp(R:Real):LongInt;
 function PStr_Str(P:Pointer):String;
 function ZString(S:String):String;
 procedure Str_ASCIZ(S:String;var Dest);
 function LRound(S:String;Len:Byte):String;
 function RRound(S:String;Len:Byte):String;
 function DayOfWeek(Year,Month,Day:Integer):Integer;
 function RemoveApostrofs(S:String):String;
 function Str_Boolean(S:String; Default:Boolean):Boolean;

implementation

function bcd_dec(value:byte):byte;
 var
  x:byte;
 begin
  x:=10*(value shr 4);
  inc(x,value and $0f);
  bcd_dec:=x;
 end;

function Dec_Bcd(value:byte):byte;
 var X:Byte;
 begin
  X:=(Value div 10) shl 4;
  Inc(X,Value mod 10);
  Dec_Bcd:=X;
 end;

function Long_Bin(Value:Longint; Len:Byte):String;
 var S:String;
 begin
  S[0]:=Char(Len);
  FillChar(S[1],Len,AlignNumber);
  while (Value<>0) and (Len>0) do
  begin
   S[Len]:=Char((Value and 1)+48);
   Value:=Value shr 1;
   Dec(Len);
  end;
  while Value<>0 do
  begin
   S:=Char((Value and 1)+48)+S;
   Value:=Value shr 1;
  end;
  Long_Bin:=S;
 end;

function Bin_Long(S:String):Longint;
 var
  Value:Longint;
  I:Byte;
 begin
  Value:=0;
  for I:=1 to Byte(S[0]) do
  begin
   Value:=Value shl 1;
   if (S[I]<>'1')and(S[I]<>'0') then begin PrevodyErr:=I; Exit; end;
   Inc(Value,Byte(S[I])-48);
  end;
  Bin_Long:=Value;
 end;

function byte_str(value,kolik:byte):string;
 var
  ret:string;
 begin
  str(value:kolik,ret);
  while pos(' ',ret)>0 do ret[pos(' ',ret)]:='0';
  byte_str:=ret;
 end;

function long_com(value:longint;len:byte):string;
 var
  ret:string;
 begin
  str(value,ret);
  if value>999 then insert(Separator,ret,length(ret)-2) else ret:=' '+ret;
  if value>999999 then insert(Separator,ret,length(ret)-6) else ret:=' '+ret;
  Long_Com:=Space(len-length(ret),' ')+ret;
 end;

function long_hex(Value:longint;Len:byte):string;
 var 
  S:String;
  N:Byte;
 begin
  S[0]:=Char(Len);
  FillChar(S[1],Len,AlignNumber);
  while (Value<>0) and (Len>0) do
  begin
   N:=Value and $F;
   if N<10 then S[Len]:=Char(N+48) else S[Len]:=Char(N+55);
   Value:=Value shr 4;
   Dec(Len);
  end;
  while Value<>0 do
  begin
   N:=Value and $F;
   if n < 10 then S:=Char(N+48)+S else S:=Char(N+55)+S;
   Value:=Value shr 4;
  end;
  Long_Hex:=S;
 end;

function long_oct(Value:longint;Len:byte):string;
 var S:String;
 begin
  S[0]:=Char(Len);
  FillChar(S[1],Len,AlignNumber);
  while (Value<>0) and (Len>0) do
  begin
   S[Len]:=Char((Value and 7)+48);
   Value:=Value shr 3;
   Dec(Len);
  end;
  while Value<>0 do
  begin
   S:=Char((Value and 7)+48)+S;
   Value:=Value shr 3;
  end;
  Long_Oct:=S;
 end;

function long_str(co:longint;mist:byte):string;
 var s:string;
 begin
  str(co:mist,s);
  long_str:=s;
 end;

function space(kolik:byte;co:char):string;
 var
  s:string;
 begin
  fillchar(s[1],kolik,co);
  byte(s[0]):=kolik;
  space:=s;
 end;

function upper(s:string):string;
{$IFDEF Linux}
 begin
  Upper:=UpCase(S);
 end;
{$ELSE}
 var s1:string;
 begin
 asm
     lea si,s[0]
     lea di,s1[0]
     mov al,0
     mov ah,ss:[si]
     mov ss:[di],ah
@@1: cmp al,ah
     je @konec
     inc al
     inc si
     inc di
     mov bl,ss:[si]
     cmp bl,97
     jl @kopiruj
     cmp bl,122
     ja @kopiruj
     sub bl,32
@kopiruj:
     mov ss:[di],bl

     jmp @@1
@konec:
 end;
 upper:=s1;
 end;
{$ENDIF}

function lower(s:string):string;
{$IFDEF Linux}
 begin
  Lower:=LowerCase(S);
 end;
{$ELSE}
var s1:string;
begin
 asm
     lea si,s[0]
     lea di,s1[0]
     mov al,0
     mov ah,ss:[si]
     mov ss:[di],ah
@@1: cmp al,ah
     je @konec
     inc al
     inc si
     inc di
     mov bl,ss:[si]
     cmp bl,65
     jl @kopiruj
     cmp bl,90
     ja @kopiruj
     add bl,32
@kopiruj:
     mov ss:[di],bl

     jmp @@1
@konec:
 end;
 lower:=s1;
end;
{$ENDIF}

function SubStr(S:String;B,E:Byte):String;
 begin
  SubStr:=Copy(S,B,E-B+1);
 end;

function RTrim(S:String):String;
 begin
  while S[Byte(S[0])]=' ' do Dec(S[0]);
  RTrim:=S;
 end;

function LTrim(S:String):String;
 var I:Byte;
 begin
  I:=1;
  while (S[I]=' ')and(I<Byte(S[0])) do Inc(I);
  Delete(S,1,I-1);
  LTrim:=S;
 end;

function Trim(S:String):String;
 begin
  Trim:=LTrim(RTrim(S));
 end;

function DelChar(S:String; C:Char):String;
 begin
  while Pos(C,S)>0 do Delete(S,Pos(C,S),1);
  DelChar:=S;
 end;

function ReplaceChar(S:String; Old,ANew:Char):String;
 begin
  while Pos(Old,S)>0 do S[Pos(Old,S)]:=ANew;
  ReplaceChar:=S;
 end;

function RepStr(Pat:String;Len:Byte):String;
 var
  S:String;
 begin
  S:='';
  while Byte(S[0])<=Len do S:=S+Pat;
  RepStr:=S;
 end;

function Str_Long(S:String):Longint;
 var
  J:LongInt;
 begin
  if (S[1]<>'$')and(UpCase(S[Byte(S[0])])='B') then Str_Long:=Bin_Long(Copy(S,1,Byte(S[0])-1))
  else begin
   if Copy(S,1,2)='0x' then S:='$'+Copy(S,3,255) else
   if UpCase(S[Byte(S[0])])='H' then begin Dec(S[0]); S:='$'+S; end;
   Val(S,J,PrevodyErr);
   Str_Long:=J;
  end;
 end;

function Str_Real(S:String):Real;
 var
  J:Real;
  L:LongInt;
 begin
  if (S[1]<>'$')and(UpCase(S[Byte(S[0])])='B') then Str_Real:=Bin_Long(Copy(S,1,Byte(S[0])-1))
  else begin
   if Copy(S,1,2)='0x' then S:='$'+Copy(S,3,255) else
   if UpCase(S[Byte(S[0])])='H' then begin Dec(S[0]); S:='$'+S; end;
   if S[1]='$' then begin Val(S,L,PrevodyErr); Str_Real:=L; end
               else begin Val(S,J,PrevodyErr); Str_Real:=J; end;
  end;
 end;

function Real_Str(R:Real):String;
 var S:String;
 begin
  Str(R:0:Real_StrPrecision,S);
  while S[Byte(S[0])]='0' do Dec(S[0]);
  if S[Byte(S[0])]='.' then Dec(S[0]);
  Real_Str:=S;
 end;

function Dir_Str(S:String;Len:Byte):String;
begin
 if Byte(S[0])>Len then
 begin
  Delete(S,Pos(':',S)+1,Byte(S[0])-Len+3);
  Insert('...',S,Pos(':',S)+1);
 end;
 Dir_Str:=S;
end;

function Prefix(S,Mask:String):Boolean;
 var
  MN, N:String[8];
  ME, E:String[3];
  I:Byte;
 begin
  MN:=Copy(Mask,1,Pos('.',Mask+'.')-1)+#0#0#0#0#0#0#0#0;
  if Pos('*',MN)>0 then Insert('????????',MN,Pos('*',MN));
  Delete(Mask,1,Pos('.',Mask+'.'));
  N:=Copy(S,1,Pos('.',S+'.')-1)+#0#0#0#0#0#0#0#0;
  Delete(S,1,Pos('.',S+'.'));
  ME:=Mask+#0#0#0;
  if Pos('*',ME)>0 then Insert('???',ME,Pos('*',ME));
  E:=S+#0#0#0;
  S:=N+E;
  Mask:=MN+ME;
  Prefix:=True;
  for I:=1 to 11 do if (Mask[I]<>'?')and(Mask[I]<>S[I]) then Prefix:=False;
 end;

function ReplaceStr(S1,OldStr,NewStr:String):String;
 var I:Byte;
 begin
  I:=Pos(OldStr,S1);
  while I>0 do
  begin
   Delete(S1,I,Byte(OldStr[0]));
   Insert(NewStr,S1,I);
   I:=Pos(OldStr,S1);
  end;
  ReplaceStr:=S1;
 end;

function TimeStr:String;
{$IFDEF Linux}
 var
  H,M,S,Se:Word;
 begin
 GetTime(H,M,S);
 Se:=0;
{$ELSE}
 var
  H,M,S,Se:Byte;
 begin
  asm
   MOV AH,$2C
   INT $21
   MOV SS:H,CH
   MOV SS:M,CL
   MOV SS:S,DH
   MOV SS:Se,DL
  end;
{$ENDIF}
  if LongDate then
   TimeStr:=Byte_Str(H,2)+':'+Byte_Str(M,2)+':'+Byte_Str(S,2)+','+Byte_Str(Se,2)
  else
   TimeStr:=Byte_Str(H,2)+':'+Byte_Str(M,2)+':'+Byte_Str(S,2);
 end;

function DayOfWeek(Year,Month,Day:Integer):Integer;
var
  century, yr, dw: Integer;
begin
  if Month < 3 then
  begin
    Inc(Month, 10);
    Dec(Year);
  end
  else
     Dec(Month, 2);
  century := Year div 100;
  yr := year mod 100;
  dw := (((26 * month - 2) div 10) + day + yr + (yr div 4) +
    (century div 4) - (2 * century)) mod 7;
  if dw < 0 then DayOfWeek := dw + 7
  else DayOfWeek := dw;
end;

function DateStr:String;
 {$IFDEF Linux}
 var
  D,M,Dt:Word;
  R:Word;
 begin
  GetDate(R,M,D);
  Dt:=DayOfWeek(R,M,D);
 {$ELSE}
 var
  D,M,Dt:Byte;
  R:Word;
 begin
  asm
   MOV AH,$2A
   INT $21
   MOV SS:R,CX
   MOV SS:M,DH
   MOV SS:D,DL
   MOV SS:Dt,AL
  end;
{$ENDIF}
  if LongDate then
   DateStr:=Dny[Dt]+'  '+Byte_Str(D,2)+'.'+Byte_Str(M,2)+'.'+Long_Str(R,4)
  else
   DateStr:=Byte_Str(D,2)+'.'+Byte_Str(M,2)+'.'+Byte_Str(R mod 100,2);
 end;

function GetCurrDir:String;
 var S:String;
 begin
 {$IFDEF Linux}
  GetDir(0,S);
 {$ELSE}
  asm
   PUSH DS
   MOV AX,SS
   MOV DS,AX
   LEA SI,S[1]
   XOR DL,DL
   MOV AH,$47
   INT $21
   POP DS
  end;
  S[0]:=#255;
  Byte(S[0]):=Pos(#0,S)-1;
 {$ENDIF}
  GetCurrDir:=S;
 end;

{$IFDEF Linux} 
function GetCurrDisk:Char;
 begin
  GetCurrDisk:=BackSlash;
 end;
{$ELSE}
function GetCurrDisk:Char; assembler;
 asm
  MOV AH,$19
  INT $21
  ADD AL,'A'
 end;
{$ENDIF}

function PromptStr(S:String):String;
 begin
  PromptStr:=ReplaceStr(
              ReplaceStr(
               ReplaceStr(
                ReplaceStr(
                 ReplaceStr(
                  ReplaceStr(
                   ReplaceStr(
                    ReplaceStr(
                     ReplaceStr(
                      ReplaceStr(
                       ReplaceStr(
                        ReplaceStr(S,
{$IFDEF Linux}
                        '$p',GetCurrDir),
{$ELSE}
                        '$p',GetCurrDisk+':\'+GetCurrDir),
{$ENDIF}
                       '$_',^M^J),
                      '$g','>'),
                     '$l','<'),
                    '$b','|'),
                   '$q','='),
                  '$h',#8),
                 '$d',DateStr),
                '$t',TimeStr),
               '$e',^[),
              '$s',';'),
             '$$','$');
 end;

function AddExt(FName:String;Ext:String):String;
 begin
  if LastPos('.',FName)<=LastPos(BackSlash,FName) then FName:=FName+'.'+Ext;
  AddExt:=FName;
 end;

function Min(X, Y: Integer): Integer; assembler;
asm
	MOV	AX,X
	CMP	AX,Y
	JLE	@@1
	MOV	AX,Y
@@1:
end;

function Max(X, Y: Integer): Integer; assembler;
asm
	MOV	AX,X
	CMP	AX,Y
	JGE	@@1
	MOV	AX,Y
@@1:
end;

function WMin(X, Y: Word): Word; assembler;
asm
	MOV	AX,X
	CMP	AX,Y
	JBE	@@1
	MOV	AX,Y
@@1:
end;

function WMax(X, Y: Word): Word; assembler;
asm
	MOV	AX,X
	CMP	AX,Y
	JAE	@@1
	MOV	AX,Y
@@1:
end;

{$IFNDEF LUnsuported}
procedure ChangeB(var Source,Dest; Size:Word); assembler;
 asm
  PUSH DS
  LDS SI,Source
  LES DI,Dest
  MOV CX,Size
@Smycka:
  MOV AH,[ES:DI]
  LODSB
  MOV [DS:SI-1],AH
  STOSB
  DEC CX
  JNZ @Smycka
  POP DS
 end;

procedure ChangeW(var Source,Dest; Size:Word); assembler;
 asm
  PUSH DS
  LDS SI,Source
  LES DI,Dest
  MOV CX,Size
  SHR CX,1
@Smycka:
  MOV DX,[ES:DI]
  LODSW
  MOV [DS:SI-2],DX
  STOSW
  DEC CX
  JNZ @Smycka
  POP DS
 end;

function CompareB(var Source,Dest; Size:Word):Integer; assembler;
 asm
  PUSH DS
  LDS SI,Source
  LES DI,Dest
  MOV CX,Size
  REPE CMPSB
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
{$ENDIF}

function GetInt(var S:String):LongInt;
 var I:Byte;
 begin
  I:=Pos(Separator,S+Separator);
  GetInt:=Str_Long(Trim(Copy(S,1,I-1)));
  Delete(S,1,I);
 end;

function GetReal(var S:String):Real;
 var
  I:Byte;
  R:Real;
  J:Integer;
 begin
  I:=Pos(Separator,S+Separator);
  Val(Trim(Copy(S,1,I-1)),R,J);
  PrevodyErr:=J;
  GetReal:=R;
  Delete(S,1,I);
 end;

function RemoveApostrofs(S:String):String;
 begin
  if (S[1]='''')and(S[0]>#1)and(S[Byte(S[0])]='''') then
  begin
   Dec(S[0]); Delete(S,1,1);
  end;
  RemoveApostrofs:=S;
 end;

function GetStr(var S:String):String;
 var
  I:Byte;
 begin
  I:=Pos(Separator,S+Separator);
  GetStr:=RemoveApostrofs(Trim(Copy(S,1,I-1)));
  Delete(S,1,I);
 end;

function GetStr2(var S:String;C:Char):String;
 var
  I:Byte;
 begin
  I:=Pos(C,S+C);
  GetStr2:=RemoveApostrofs(Trim(Copy(S,1,I-1)));
  Delete(S,1,I);
 end;

{$IFDEF Linux}
function LastPos(C:Char;S:String):Byte;
 var
  I:Byte;
 begin
  I:=Byte(S[0]);
  while (I>0)and(S[I]<>C) do Dec(I);
  LastPos:=I;
 end;
{$ELSE}
function LastPos(C:Char;S:String):Byte; assembler;
 asm
  LES DI,S
  XOR CX,CX
  MOV CL,[ES:DI]
  ADD DI,CX
  INC CX
  MOV AL,C
  STD
  REPNE SCASB
  CLD
  MOV AX,CX
 end;
{$ENDIF}

function AddBackSlash(S:String):String;
 begin
  if (S[Byte(S[0])]<>BackSlash)
{$IFDEF Linux}
     and(S[Byte(S[0])]<>':')
{$ENDIF}
     and(S[0]<>#0) then AddBackSlash:=S+BackSlash
                   else AddBackSlash:=S;
 end;

function RoundUp(R:Real):LongInt;
 begin
  if Frac(R)>0 then RoundUp:=Trunc(R)+1 else RoundUp:=Trunc(R);
 end;

function ReplaceExt(FName:String;Ext:String):String;
 begin
  if LastPos('.',FName)>LastPos(BackSlash,FName) then ReplaceExt:=Copy(FName,1,LastPos('.',FName))+Ext
                                                 else ReplaceExt:=FName+'.'+Ext;
 end;

function PStr_Str(P:Pointer):String;
 type PString=^String;
 begin
  if P=nil then PStr_Str:='' else PStr_Str:=PString(P)^;
 end;

function ZString(S:String):String;
 begin
  if Pos(#0,S)>0 then ZString:=Copy(S,1,Pos(#0,S)-1) else ZString:=S;
 end;

procedure Str_ASCIZ(S:String;var Dest);
 begin
  S[Byte(S[0])+1]:=#0;
  Move(S[1],Dest,Byte(S[0])+1);
 end;

function LRound(S:String;Len:Byte):String;
 begin
  if S[0]>Char(Len) then S[0]:=Char(Len);
  LRound:=S+Space(Len-Byte(S[0]),' ');
 end;

function RRound(S:String;Len:Byte):String;
 begin
  if S[0]>Char(Len) then S[0]:=Char(Len);
  RRound:=Space(Len-Byte(S[0]),' ')+S;
 end;

function Str_Boolean(S:String; Default:Boolean):Boolean;
 begin
  Str_Boolean:=Default;
  if S='' then Exit;
  if Default then Str_Boolean:=not (S[1] in FalseChars)
             else Str_Boolean:=(S[1] in TrueChars);
 end;

end.