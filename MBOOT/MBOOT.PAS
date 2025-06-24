uses Bios_IO, Header, ErrMsg, Prevody, Dos_IO, Dos;

{$I MBOOT.INH}
{$L BootSys.LNK}
{$L MBUndo.LNK}
{$L SySign.OBJ}
{$I PartBack.INC}

const
 SuportSys=[1,4,6,7,$0B];
 CurrentVersion=1;

procedure BootSys; external;
procedure MBUndoExe; external;
procedure SySign; external;

procedure Error(S:String);
 begin
  WriteLn(S);
  WriteLn(' Program ukoncen fatalni chybou.');
  Halt(1);
 end;

procedure WritePart(X,I:Byte; var P:TPartition);
 var
  S:String;
  BSec:TBootSector;
 begin
  case P.Boot of
      $80:S:='Ano ';
        0:S:='Ne  ';
     else S:='Chyb';
  end;
  Write(I:2,'':4+X,S,' ',Long_Hex(P.Sys,2));
  S:=GetErrMsg(P.Sys,@SySign);
  if S='' then S:='Neznamy';
  Write(' ',LRound(S,8),Long_Com(P.Size*512,13),'':2);
  if P.Sys in SuportSys then
  begin
   HdAbsRead(128,P.BegHead,Hi(P.BegCX),Lo(P.BegCX),1,BSec);
   if BiosResult<>0 then Write('Chyba: ',GetErrMsg(Lo(BiosResult),@Bios_IO_Err))
   else with BSec do Write(VolumeId,' ',OemId,' ',FSId,' ',SecPerClust*BytPerSec:5);
  end else if P.Sys=5 then Write('Rozsirujici tabulka rozdeleni disku')
      else Write('Neznama struktura zavadece');
  WriteLn;
 end;

var
 Part:TPartitionTable;
 I:Byte;
 C:Char;

procedure WriteMBR;
 var
  F:File of TPartitionTable;
 begin
  Write(^J' Zapisuji novy ovladac ... ');
{  Assign(F,'NEW2.MBR');
  ReWrite(F);
  Write(F,Part);
  Close(F); }
  HdAbsWrite(128,0,0,1,1,Part);
  if BiosResult<>0 then Error(GetErrMsg(Lo(BiosResult),@Bios_IO_Err));
  WriteLn('OK'^M^J^J'Program uspesne ukoncen.');
 end;

procedure PackCurrentTime(var Time:LongInt);
 var
  T:DateTime;
  S:Word;
 begin
  with T do begin GetDate(Year,Month,Day,S); GetTime(Hour,Min,Sec,S); end;  PackTime(T,Time);
 end;

procedure MakeBackup;
 var
  F:File;
  FB:File of TPartBackup;
  PB:TPartBackup;
  W:^Word;
  Size,Wr:Word;
 begin
  WriteLn(' Pred zapisem noveho zavadece je vhodne zalohovat puvodni verzi na disketu.');
  WriteLn(' Do mechaniky A: vlozte prosim disketu (min. 20 KB volneho mista),');
  Write(' a stisknete <Enter> ... ');
  repeat C:=Char(GetKey); if (C=^[)or(C=^C) then Error(' Bez zalohy nelze instalovat.'); until C=^M;
  WriteLn(^M^J^J' Zalohuji puvodni zavadec ... ');
  Assign(FB,'A:\MBUNDO.MBR');
  {$I-} Reset(FB);
  if IOResult<>0 then ReWrite(FB); {$I+}
  if IOResult<>0 then Error(' Nelze vytvorit zalozni soubory.');
  WR:=0;
  for Size:=1 to FileSize(FB) do
  begin Read(FB,PB); Wr:=Max(Wr,PB.Ver); end;
  PB.Ver:=CurrentVersion;
  PackCurrentTime(PB.Time);
  with PB do begin Drive:=128; Head:=0; Track:=0; Sector:=1; Buff:=Part; end;
  Write(^J' Poznamka k zaloze: '); PB.Desc:=DosInput(SizeOf(PB.Desc));
  {$I-} Write(FB,PB);
  if IOResult<>0 then Error(' Nelze vytvorit zalozni soubory.');
  Close(FB); {$I+}
  if WR<=CurrentVersion then
  begin
   Assign(F,'A:\MBUNDO.EXE');
   {$I-} Rewrite(F,1); {$I+}
   if IOResult<>0 then Error(' Nelze vytvorit zalozni soubory.');
   W:=@MBUndoExe;
   Size:=W^;
   Inc(W);
   BlockWrite(F,W^,Size,Wr);
   Close(F);
   if Size<>Wr then Error(' Nelze vytvorit zalozni soubory.');
  end;
  WriteLn;
 end;

procedure InstallBM;
 var
  PartCount:Byte;
  I:Byte;
  S:String;
  W:^Word;
  MsgOfs,OldMsgOfs:Word;
  MaxLen:^Byte;
  C:Char;
 begin
  MakeBackup;
  PartCount:=1;
  while (Part.Partition[PartCount].Sys in SuportSys)and(PartCount<5) do Inc(PartCount);
  Dec(PartCount);
  Write(^J' Pocet moznosti v menu [',PartCount,']: ');
  ReadLn(S);
  if S<>'' then PartCount:=Str_Long(S);
  if PartCount=0 then Error(' Zadan nulovy pocet polozek menu.');
  if PartCount>4 then Error(' Polozky menu mohou byt max. 4.');
  for I:=1 to PartCount do if Part.Partition[I].Sys=5 then
  begin
   WritePart(0,I,Part.Partition[I]);
   WriteLn(' Tato diskova oblast je nevhodneho typu. Mohu ji prevest na korektni typ,');
   Write(  ' ale dojde ke ztrate vsech dat na ni ulozenych. Prevest oblast [A/N] ? ');
   repeat C:=UpCase(Char(GetKey)); until Pos(C,^C^['AN')>0;
   if C='A' then
   begin
    if Part.Partition[I].Size>20740 then Part.Partition[I].Sys:=6
                                    else Part.Partition[I].Sys:=1;
   end else if C<>'N' then Exit;
  end;
  W:=@BootSys; Inc(LongInt(W),W^);
  MsgOfs:=W^;
  MaxLen:=@Part.BootCode;
  Inc(MsgOfs);
  Inc(MaxLen,MsgOfs);
  W:=@BootSys;
  Inc(W);
  Inc(MsgOfs);
  Move(W^,Part.BootCode,MsgOfs);
  Part.BootCode[MsgOfs-1]:=PartCount;
  Inc(MsgOfs);
  OldMsgOfs:=MsgOfs;
  for I:=1 to PartCount do
  begin
   Write(^J' Text pro ',I,'. polozku [max. 20 znaku]: ');
   S:=DosInput(21)+^M^J'  ';
   MaxLen^:=Max(MaxLen^,Byte(S[0]));
   Insert('F'+Char(I+48)+' ... ',S,1);
   Move(S[1],Part.BootCode[MsgOfs],Byte(S[0])); Inc(MsgOfs,Byte(S[0]));
  end;
  S:=^J'>'#0;
  Inc(MaxLen^,6);
  Move(S[1],Part.BootCode[MsgOfs],Byte(S[0]));
  Write(^J^J' Startovaci menu bude vypadat asi takto: '^M^J^J'  ');
  while Part.BootCode[OldMsgOfs]<>0 do
  begin Write(Char(Part.BootCode[OldMsgOfs])); Inc(OldMsgOfs); end;
  Write(^M^J^J' Ulozit do zavadece [A/N] ? ');
  repeat C:=UpCase(Char(GetKey)); until Pos(C,'AN'^[^C)>0;
  WriteLn(C);
  if C='A' then WriteMBR;
 end;

procedure EditMBR;
 type
  PTree=^TTree;
  TTree=record
         Prev:PTree;
         Part:array [1..4] of TPartition;
         Next:array [1..4] of PTree;
        end;
 var
  Root:PTree;
  Buff:TPartitionTable;
  X,Y:Byte;

 procedure ParsePart(Prev,Tmp:PTree);
  var
   I:Byte;
  begin
   FillChar(Tmp^,SizeOf(Tmp^),0);
   Tmp^.Prev:=Prev;
   Move(Buff.Partition,Tmp^.Part,SizeOf(Tmp^.Part));
   for I:=1 to 4 do if Tmp^.Part[I].Sys=5 then
   begin
    HdAbsRead(128,Tmp^.Part[I].BegHead,Hi(Tmp^.Part[I].BegCX),Lo(Tmp^.Part[I].BegCX),1,Buff);
    New(Tmp^.Next[I]);
    ParsePart(Tmp,Tmp^.Next[I]);
   end;
  end;

 procedure DrawPart(Tmp:PTree);
  var
   I:Byte;
  begin
   I:=0;
   repeat
    Inc(I); Inc(Y);
    WritePart(X,Y,Tmp^.Part[I]);
    if Tmp^.Part[I].Sys=5 then
    begin
     Inc(X);DrawPart(Tmp^.Next[I]);Dec(X);
    end;
   until (I=4);
  end;

 begin
  HdAbsRead(128,0,0,1,1,Buff);
  New(Root);
  ParsePart(nil,Root);
  X:=0;Y:=0;
  WriteLn('Cis.  Akt. System     Velikost [Byt] Svazek      Vyrobce  FS Id    Clust.');
  DrawPart(Root);
 end;

begin
 Head:='Universal boot utilities (MBOOT)  Version 1.0  ARNAY Software';
 HelpTxt:=@cHelpTxt;
 WriteHead(heHalt);
 repeat
  Write(^J' Nacitam tabulku rozdeleni ... ');
  HdAbsRead(128,0,0,1,1,Part);
  if BiosResult<>0 then Error(GetErrMsg(Lo(BiosResult),@Bios_IO_Err))
  else WriteLn('OK');
  WriteLn(' Tabulka rozdeleni:');
  WriteLn(' Signatura: ',Long_Hex(Part.Sign,4));
  if Part.Sign<>PartitionSign then Error('Chybna signatura - z tohoto disku nelze zavest system !');
  WriteLn('Cis.  Akt. System     Velikost [Byt] Svazek      Vyrobce  FS Id    Clust.');
  for I:=1 to 4 do WritePart(0,I,Part.Partition[I]);
  Write(^J' Instalovat multiboot, Editovat tabulku rozdeleni disku nebo Konec [I/E/K] ? ');
  repeat C:=UpCase(Char(GetKey)); until Pos(C,'IEK'^[^C)>0;
  if C=^[ then WriteLn('Esc') else WriteLn(C);
  case C of
      'I':InstallBM;
      'E':EditMBR;
      else C:='K';
  end;
 until (C='K');
end.