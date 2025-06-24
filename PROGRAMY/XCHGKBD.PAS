{$A+,B-,D+,E+,F-,G-,I+,L+,N+,O-,R-,S+,V+,X+}
{$M 2048,0,0}
uses StringCS, Dos;
const
  AltF1=59; AltF2=60; AltF3=61; AltF4=62; AltF5=63;
  AltF6=64; AltF7=65; AltF8=66; AltF9=67; AltF10=68;
  AltKbdTbl : array [59..68] of Pointer
              = (nil,nil,nil,nil,nil,nil,nil,nil,nil,nil);
const
 Count:Word=30*1000 div 55;
 Signature:record
            Firm, Product:array [1..8] of Char;
            Descr:Byte;
           end = (Firm:'ARNAY   ';Product:'XCHGKBD ';Descr:0);

var
  KbdIntVec : Procedure;
  ShiftFlag : Byte absolute 0:$0417;
{$F+}
procedure Keyclick; interrupt;
 begin
  if (Port[$60]>=59)and(Port[$60]<=68)
     and((ShiftFlag and 15)=14)and(AltKbdTbl[Port[$60]]<>nil) then
  begin
   SwitchKbd(AltKbdTbl[Port[$60]]);
   asm
    IN AL,$61
    MOV AH,AL
    OR AL,$80
    OUT $61,AL
    XCHG AL,AH
    OUT $61,AL
    MOV AL,$20
    OUT $20,AL
   end;
  end else
  if (Port[$60] = 82)and(Mem[$0:$0417] and 15=12) then
    asm
     IN AL,$61
     MOV AH,AL
     OR AL,$80
     OUT $61,AL
     XCHG AL,AH
     OUT $61,AL
     MOV AL,$20
     OUT $20,AL
     MOV AH,$62
     INT $21
     MOV ES,BX
     MOV AH,$49
     INT $21
     INT $2E
  end else
  begin
   inline ($9C);
   KbdIntVec;
  end;
end;
{$F-}

procedure IBMKbd; external;
{$L IBMKbd.OBJ }
procedure Ramec1Kbd; external;
{$L Ramec1Kb.OBJ }
procedure Math1Kbd; external;
{$L Math1Kbd.OBJ }
procedure Latin2Kbd; external;
{$L Latin2Kb.OBJ }

begin
  { Vlo‘ p©eru¨ovac¡ proceduru do ©etˆzce
    ovlada‡– kl vesnice }
  WriteLn('Universal country utilities (XCHGKBD)  Version 1.0  ARNAY Software');
  AltKbdTbl[AltF1]:=@IbmKbd;
  AltKbdTbl[AltF2]:=@KamenictiKbd;
  AltKbdTbl[AltF3]:=@Ramec1Kbd;
  AltKbdTbl[AltF4]:=@Math1Kbd;
  AltKbdTbl[AltF5]:=@Latin2Kbd;
  LoadKbd(@IbmKbd);
  GetIntVec($9,@KbdIntVec);
  SetIntVec($9,Addr(Keyclick));
{  Exec(GetEnv('COMSPEC'),'');
  SetIntVec($9,@KbdIntVec);
  ResetKbd;}
  WriteLn(^M^J'Ctrl+Alt+LShift+'^M^J' F1 = IBM, F2 = Kamenicti, F3 = RAMEC, F4 = MATH, F5 = Latin2');
  WriteLn('Ovladac narodni klavesnice uspesne instalovan.');
  Keep(0);
end.

