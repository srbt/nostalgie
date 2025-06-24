uses Prevody, Header;
type
 TKey    = record
            OldCode:Word;
            NewCode:Byte;
           end;
 TKeyVec = record
            Size :Byte;
            Key  :array [1..255] of TKey;
           end;
 TShiftVec = record
              Size :Byte;
              Key  :array [1..6] of Word;
             end;
 TKeyboard = record
              Head:array [1..11] of Char;
              Name:array [1..10] of Char;
              Shift :TShiftVec;
              Keys  :array [0..6] of TKeyVec;
             end;

function GetKey:Word; assembler;
 asm
  MOV AH,0
  INT $16
 end;

var
 Kbd:TKeyBoard;
 J,I:Byte;
 CurrVec:TKeyVec;
 FName: String;

const
 LW=^['[0m';
 HW=^['[1m';
 Clr=^['[2J';
 YN=' ['+HW+'A'+LW+'/'+HW+'N'+LW+'] ? ';

procedure GotoXY(X,Y:Byte);
 begin
  Write(^['[',Y-1,';',X-1,'H');
 end;

procedure InitScr;
 begin
  WriteLn(LW,Clr,'             Generovani driveru pro narodni klavesnici    (',HW,FName,LW,')');
  WriteLn('             컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�');
  WriteLn;
  WriteLn;
 end;

procedure MainScr;
 var I:Byte;
 begin
  InitScr;
  WriteLn(' Znakove sady:  ',HW,0,LW,' -> ',HW,'Standart','  ',HW,Kbd.Keys[0].Size:3,LW,' zn.');
  for I:=1 to Kbd.Shift.Size do with Kbd.Shift do
  WriteLn('                ',HW,I,LW,' -> ',HW,Long_Hex(Key[I],4),LW,'(',HW,Char(Key[I]),LW,')',LW,
          '   ',HW,Kbd.Keys[I].Size:3,LW,' zn.');
  GotoXY(1,22);
  Write('--------------------------------------------------------------------------------');
  WriteLn(' ',HW,'N',LW,'ova sada  ',HW,'E',LW,'ditace sady  ',HW,'R',LW,'useni sady  ',HW,'U',LW,'lozeni klavesnice  ',
        HW,'K',LW,'onec programu');
  Write(^J' >');
 end;

procedure Sort;
 var
  Key:TKey;
  I,J:Byte;
 begin
  for I:=1 to CurrVec.Size-1 do
   for J:=I+1 to CurrVec.Size do
    if CurrVec.Key[J].OldCode<CurrVec.Key[I].OldCode then
    begin
     Key:=CurrVec.Key[J];
     CurrVec.Key[J]:=CurrVec.Key[I];
     CurrVec.Key[I]:=Key;
    end;
 end;

function LoadKbd:Boolean;
 var
  F:File;
  I:Byte;
 begin
  LoadKbd:=False;
  Assign(F,FName);
  {$I-} Reset(F,1); {$I+}
  if IOResult<>0 then Exit;
  BlockRead(F,Kbd.Head,SizeOf(Kbd.Head));
  if Kbd.Head<>'ARNAY KBD.'#26 then Exit;
  BlockRead(F,Kbd.Name,SizeOf(Kbd.Name));
  BlockRead(F,Kbd.Shift.Size,1);
  if Kbd.Shift.Size>6 then Exit;
  BlockRead(F,Kbd.Shift.Key,Kbd.Shift.Size*2);
  for I:=0 to Kbd.Shift.Size do
  begin
   BlockRead(F,Kbd.Keys[I].Size,1);
   BlockRead(F,Kbd.Keys[I].Key,Kbd.Keys[I].Size*SizeOf(TKey));
  end;
  LoadKbd:=True;
 end;

function Volba:Boolean;
 var
  I:Char;
 begin
  repeat
   I:=UpCase(Char(GetKey));
  until I in ['A','N'];
  Write(HW,I,LW);
  Volba:=I='A';
 end;

procedure NovaSada;
 var
  I:Word;
 begin
  with Kbd.Shift do
   if Size=6 then
   begin
    Write(HW,^M' Prilis mnoho sad !'^J^M,LW,' Press any key ...');
    I:=GetKey;
    Exit;
   end else
   begin
    Inc(Size);
    Write(LW,^M' Premykac ',Size,'. sady = ');
    Key[Size]:=GetKey;
    Kbd.Keys[Size].Size:=0;
    WriteLn(HW,Long_Hex(Key[Size],4),LW,'(',HW,Char(Key[Size]),LW,')');
    Write(' Opravdu pridat tuto sadu',YN);
    if not Volba then Dec(Size);
   end;
 end;

procedure RuseniSady;
  var
  I:Word;
 begin
  with Kbd.Shift do
   begin
    Write(LW,^M' Cislo rusene sady: ',HW);
    repeat I:=Byte(GetKey)-48; until I in [0..Size];
    WriteLn(I,LW);
    Write(' Opravdu smazat tuto sadu',YN);
    if Volba then if I=0 then Kbd.Keys[0].Size:=0
    else begin
     Move(Key[I+1],Key[I],(Size-I)*2);
     Move(Kbd.Keys[I+1],Kbd.Keys[I],(Size-I)*SizeOf(Kbd.Keys[I]));
     Dec(Size);
    end;
   end;
 end;

procedure EditaceSady;
 var
  CurrSada: Word;

 procedure DrawEdit;
  var
   I:Byte;
  begin
   InitScr;
   Write(' Editace ',HW,CurrSada,LW,'.sady -> ',HW);
   if CurrSada=0 then WriteLn('Standart','  ',HW,CurrVec.Size:3,LW,' zn.') else
   WriteLn(Long_Hex(Kbd.Shift.Key[CurrSada],4),LW,'(',HW,Char(Kbd.Shift.Key[CurrSada]),LW,')',LW,
          '   ',HW,CurrVec.Size:3,LW,' zn.');
   WriteLn;
   with CurrVec do
   for I:=1 to Size do with Key[I] do
    Write(' ',Long_Hex(OldCode,4),'(',HW,Char(OldCode),LW,') = "',HW,Char(NewCode),LW,'"',NewCode:3,'   ');
   GotoXY(1,22);
   Write('--------------------------------------------------------------------------------');
   WriteLn(' ',HW,'N',LW,'ova klavesa  ',HW,'R',LW,'useni klavesy  N',HW,'a',LW,'cteni sady  ',HW,'U',LW,'lozeni sady  ',
           HW,'K',LW,'onec editace');
   Write(^J' >>');
  end;

 procedure NovaKlavesa;
  var
   I:Byte;
   Code:Word;
  begin
   with CurrVec do
   begin
    Write(^M,' Novy znak -> klavesa = ');
    Code:=GetKey;
    I:=1;
    while (I<Size) and (Key[I].OldCode<>Code) do Inc(I);
    if Key[I].OldCode=Code then
    begin
     Write(^M,HW,' Tato klavesa jiz je prirazena !',LW,' (zkus jinou)',^J,^M,' Press any key ...');
     Code:=GetKey;
     Exit;
    end;
    Inc(Size);
    Key[Size].OldCode:=Code;
    Write(HW,Long_Hex(Key[Size].OldCode,4),LW,'(',HW,Char(Key[Size].OldCode),LW,') novy kod = ',HW);
    Key[Size].NewCode:=Byte(GetKey);
    Write(Char(Key[Size].NewCode));
    if Key[Size].NewCode=92 then ReadLn(Key[Size].NewCode);
   end;
  end;

 procedure RuseniKlavesy;
  var
   Code:Word;
   I:Byte;
  begin
   with CurrVec do
   begin
    if Size=0 then
    begin
     Write(^M,HW,' Malo klaves na ruseni !',LW,^J,^M,' Press any key ...');
     Code:=GetKey;
     Exit;
    end;
    Write(^M,'  Kod rusene klavesy: ');
    Code:=GetKey;
    Write(HW,Long_Hex(Code,4),LW,'(',HW,Char(Code),LW,')');
    I:=1;
    while (I<Size) and (Key[I].OldCode<>Code) do Inc(I);
    if Key[I].OldCode<>Code then
    begin
     Write(^M,HW,' Tato klavesa nebyla nalezena !',LW,' (zkus jinou)',^J,^M,' Press any key ...');
     Code:=GetKey;
     Exit;
    end;
    WriteLn;
    Write(' Opravdu smazat tuto klavesu',YN);
    if Volba then
    begin
     Move(Key[I+1],Key[I],(Size-I)*SizeOf(TKey));
     Dec(Size);
    end;
   end;
  end;

 var
  Ch:Char;
 begin
  with Kbd.Shift do
   begin
    Write(LW,^M' Cislo editovane sady: ',HW);
    repeat CurrSada:=Byte(GetKey)-48; until CurrSada in [0..Size];
    WriteLn(CurrSada,LW);
   end;
  CurrVec:=Kbd.Keys[CurrSada];
  repeat
   DrawEdit;
   Ch:=UpCase(Char(GetKey));
   Write(HW,Ch,LW);
   case Ch of
        'N':NovaKlavesa;
        'R':RuseniKlavesy;
        'A':CurrVec:=Kbd.Keys[CurrSada];
        'U':begin
             Sort;
             Kbd.Keys[CurrSada]:=CurrVec;
            end;
        'K':;
        else Write(^G);
   end;
  until Ch='K';
 end;

procedure UlozeniKBD;
 var
  F:File;
  I:Byte;
 begin
  Assign(F,FName);
  {$I-} Reset(F,1); {$I+}
  if IOResult=0 then
  begin
   Close(F);
   Assign(F,Copy(FName,1,Pos('.',FName))+'BAK');
   {$I-} Erase(F); {$I+}
   if IOresult=0 then ;
   Assign(F,FName);
   Rename(F,Copy(FName,1,Pos('.',FName))+'BAK');
  end;
  Assign(F,FName);
  ReWrite(F,1);
  BlockWrite(F,Kbd.Head[1],SizeOf(Kbd.Head));
  BlockWrite(F,Kbd.Name,SizeOf(Kbd.Name));
  BlockWrite(F,Kbd.Shift,Kbd.Shift.Size*2+1);
  for I:=0 to Kbd.Shift.Size do
  BlockWrite(F,Kbd.Keys[I],Kbd.Keys[I].Size*SizeOf(TKey)+1);
  Close(F);
 end;

var
 Ch:Char;

const
 cHelpTxt='Syntaxe MKKBD [filespec[.KBD]'^M^J' Program vytvari definicni soubor pro narodni klavesnici.'^Z;
 sHelpTxt:array [1..Length(cHelpTxt)] of Char = cHelpTxt;

begin
 Head:='Universal country utilities (MKKBD)  Version 1.0  ARNAY Software';
 HelpTXT:=@sHelpTxt;
 WriteHead(heHalt);
 if ParamCount=1 then FName:=ParamStr(1)
 else begin Write(LW,' File name [.KBD]: ',HW); ReadLn(FName); end;
 FName:=Upper(FName);
 if Pos('.',FName)=0 then FName:=FName+'.KBD';
 if not LoadKbd then
 begin
  FillChar(Kbd,SizeOf(Kbd),0);
  Kbd.Head:='ARNAY KBD.'#26;
 end;
 repeat
  MainScr;
  Ch:=UpCase(Char(GetKey));
  Write(HW,Ch,LW);
  case Ch of
       'N':NovaSada;
       'E':EditaceSady;
       'R':RuseniSady;
       'U':UlozeniKBD;
       'K':;
       else Write(^G);
  end;
 until Ch='K';
 Write(^M,' Ulozit klavesnici',YN);
 if Volba then UlozeniKBD;
 Write(Clr);
end.

var
 F : file;
 C : Char;
begin
 FillChar(Kbd,SizeOf(Kbd),0);
 Kbd.Head:='ARNAY KBD.'#26;
 CurrSize:=0;
 DrawScr;
 Write(' Pocet sad ? ');
 ReadLn(Kbd.Shift.Size);
 DrawScr;
 for I:=1 to Kbd.Shift.Size do
 begin
  Write(I:2,'. premykac = ');
  Kbd.Shift.Key[I]:=GetKey;
  DrawScr;
 end;
 for I:=0 to Kbd.Shift.Size do
 begin
  CurrSize:=0;
  repeat
   DrawScr;
   Inc(CurrSize);
   Write(CurrSize:3,'. znak',I:2,'. sady -> klavesa = ');
   CurrVec[CurrSize].OldCode:=GetKey;
   if CurrVec[CurrSize].OldCode<>$011B then
   begin
    Write(Long_Hex(CurrVec[CurrSize].OldCode,4),'(',Char(CurrVec[CurrSize].OldCode),') novy kod = ');
    CurrVec[CurrSize].NewCode:=Byte(ReadKey);
    Write(Char(CurrVec[CurrSize].NewCode));
    if CurrVec[CurrSize].NewCode=92 then ReadLn(CurrVec[CurrSize].NewCode);
   end else
   begin
    WriteLn;
    Write(' Novou sadu nebo mazani [N/M] ? ');
    repeat C:=UpCase(ReadKey); until C in ['N','M'];
    if (C='M')and(CurrSize>0) then
    begin
     WriteLn(C);
     Write(' Poradove cislo mazane klavesy: ');
     ReadLn(Byte(C));
     Dec(CurrSize);
     if C<>#0 then
     begin
      Move(CurrVec[Byte(C)+1],CurrVec[Byte(C)],(CurrSize-Byte(C))*SizeOf(TKey));
      Dec(CurrSize);
     end;
    end;
   end;
  until CurrVec[CurrSize].OldCode=$011B;
  Dec(CurrSize);
  GetMem(Kbd.Keys[I],CurrSize*SizeOf(TKey)+1);
  Kbd.Keys[I]^.Size:=CurrSize;
  if CurrSize>0 then Sort;
  Move(CurrVec,Kbd.Keys[I]^.Key,CurrSize*SizeOf(TKey));
 end;
 DrawScr;
 Write(' Updating file ...');
 Assign(F,ParamStr(1));
 ReWrite(F,1);
 BlockWrite(F,Kbd.Head[1],SizeOf(Kbd.Head));
 BlockWrite(F,Kbd.Shift,Kbd.Shift.Size*2+1);
 for I:=0 to Kbd.Shift.Size do
 BlockWrite(F,Kbd.Keys[I]^,Kbd.Keys[I]^.Size*SizeOf(TKey)+1);
 WriteLn;
 WriteLn(' Writing ',Long_Hex(FileSize(F),5),' bytes.');
 Close(F);
end.