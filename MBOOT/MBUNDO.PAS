uses Bios_IO, Dos_IO, ErrMsg, Dos;

const
 Compatible=[1];

{$I PartBack.INC}

procedure Error(S:String);
 begin
  WriteLn(S);
  WriteLn(' Program ukoncen fatalni chybou.');
  Halt(1);
 end;

var
 C:Char;
 Part:TPartBackup;
 F:file of TPartBackup;
 I:Byte;
 T:DateTime;
begin
 Assign(F,'A:\MBUNDO.MBR');
 {$I-} Reset(F); {$I+}
 if IOResult<>0 then Error(' Soubor zaloh [A:\MBUNDO.MBR] nenalezen !!!');
 WriteLn('Zaloha obsahuje tyto zaznamy: ');
 for I:=1 to FileSize(F) do
 begin
  Write(I:3,'. ');
  Read(F,Part);
  if not(Part.Ver in Compatible) then WriteLn('Nekompatibilni zaznam')
  else begin
   UnpackTime(Part.Time,T);
   with T do Write(Day:2,'.',Month:2,'.',Year:2,'  ');
   WriteLn(Part.Desc);
  end;
 end;
 Write(^J'Cislo obnovovaneho zaznamu: ');
 ReadLn(I);
 if (I<1)or(I>FileSize(F)) then
 begin
  WriteLn('Zadane cislo je mimo rozsah platnych zaznamu, program je');
  WriteLn('ukoncen aniz provedl jakoukoliv cinnost !!!');
  Halt(1);
 end;
 Seek(F,I-1);
 Read(F,Part);
 Close(F);
 WriteLn('Vybrany zaznam: ',Part.Desc);
 if not(Part.Ver in Compatible) then
 begin
  WriteLn(^J'Zaznam pravdepodobne neni kompatibilni, pouzijte jej pouze v');
  WriteLn('nejnutnejsim pripade.');
 end;
 Write(^J'Opravdu obnovit zvoleny zaznam [A/N] ? ');
 repeat C:=UpCase(Char(GetKey)); until Pos(C,'AN'^[^C)>0;
 WriteLn(C);
 if C='A' then
 begin
  Write(^J'Obnovuji zaznam ... ');
  with Part do HdAbsWrite(Drive,Head,Track,Sector,1,Buff);
  if BiosResult<>0 then Error(GetErrMsg(Lo(BiosResult),@Bios_IO_Err))
  else WriteLn('OK');
 end;
end.