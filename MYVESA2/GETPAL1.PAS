uses Obraz;
type
  RGBRec = record
    R, G, B : Byte;
  end;

procedure GetRGBPalette(ColorNum:Integer; var RGB:RGBRec); assembler;
 asm
  MOV AX,$1015
  MOV BX,ColorNum
  INT 10h
  LES DI,RGB
  MOV AL,DH
  STOSB
  MOV AL,CH
  STOSB
  MOV AL,CL
  STOSB
 end;

var
 I,J:Byte;
 RGB:RGBRec;
 F:File of RGBRec;
 A:array [1..4096] of Byte;
 Cr:CrtRec;
begin
 WriteLn('Scanning colors ...');
 WOpen(1,1,80,25,A,True);
 GetCrt(Cr);
 ASM
  MOV AX,13h
  INT 10h
 end;
 Assign(F,'EGAPAL.DEF');
 ReWrite(F);
 for I:=0 to 15 do
 begin
  GetRGBPalette(I,RGB);
  with RGB do
  begin
   R:=R shl 2;
   G:=G shl 2;
   B:=B shl 2;
   J:=R; R:=B; B:=J;
  end;
  Write(F,RGB);
 end;
{ asm MOV AX,03; INT 10h; end;}
 Close(F);
 SetCrt(Cr);
 WOpen(1,1,80,25,A,False);
 WriteLn('Palette saved as EGAPAL.DEF.');
end.