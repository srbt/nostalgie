uses Crt, Obraz, Dos_IO, Prevody, Header;
type
 PSortVec=^TSortVec;
 TSortVec=record
           Name:array [1..10] of Char;
           Table:array [0..255] of Char;
          end;
 TSortTbl=record
           Count:Byte;
           Vectors:array [1..20] of TSortVec;
          end;
 TMode=(Sort,UpTbl);

procedure ReCalc(var Tbl:TSortTbl);
 var
  Vec:TSortVec;
  X,Y:Byte;
 begin
  for Y:=1 to Tbl.Count do
  begin
   for X:=0 to 255 do Vec.Table[Byte(Tbl.Vectors[Y].Table[X])]:=Char(X);
   Move(Vec.Table,Tbl.Vectors[Y].Table,SizeOf(Vec));
  end;
 end;

const
 Title:array [TMode] of String[30] = (' Generator tridicich tabulek ',
                                      ' Generator tabulek prevodu VP ');
 Ext:array [TMode] of Array [1..3] of Char=('SOR','UPC');
 W_B=Blue shl 4 or White;
 Y_B=Blue shl 4 or Yellow;
 B_W=(White shl 4 or Blue) and not $80;

var
 Mode:TMode;
 FName:String;
 SortTbl:TSortTbl;
 CurrPoz:Byte;
 CurrVec:Byte;
 F:File;
 OldExitProc:Pointer;
 Cr:CrtRec;
 Scr:array [1..4000] of Byte;
 Saved:Boolean;

procedure NewExitProc; far;
 const
  ErrMsg:array [1..1] of String[80]=('Chybny format souboru !');
 begin
  ExitProc:=OldExitProc;
  WOpen(1,1,80,25,Scr,false);
  SetCrt(Cr);
  WriteLn;
  if ExitCode<>0 then if ExitCode=255 then WriteLn('Preruseno uzivatelem.') else
  begin
   WriteLn(ErrMsg[ExitCode]);
   Close(F);
  end;
 end;

function Ask(S:String;Q:String):Byte;
 var
  I:Byte;
  C:Char;
 begin
  TextAttr:=W_B;
  XTextAttr:=Y_B;
  S:=' '+S+' ['; for I:=1 to Byte(Q[0]) do S:=S+'~'+Q[I]+'~/'; S:=S+'~Esc~] ? ';
  WriteXYC(1,25,S); ClrEol;
  repeat C:=UpCase(ReadKey); until Pos(C,^[+Q)>0;
  Ask:=Pos(C,^[+Q)-1;
  Write(^M); ClrEol;
 end;

 procedure WriteCharXY(X,Y:Byte; C:Char);
  begin
   if C in [^M,^J,^@,^G,^H] then WriteXY(X,Y,'^'+Char(Byte(C)+64)) else WriteXY(X,Y,' '+C);
  end;

procedure WriteTbl;
 procedure WriteChar(X:Byte; C:Char);
  begin
    WriteCharXY((X mod 32)*2+8,(X div 32) * 2 + 3,C);
  end;

 const SavedSign:array [Boolean] of Char = (#15,#205);
 var X:Byte;
 begin
  if CurrVec>SortTbl.Count then
  begin Inc(SortTbl.Count);
   { if Mode=Sort then } for X:=0 to 255 do SortTbl.Vectors[SortTbl.Count].Table[X]:=Char(X);
   { else for X:=0 to 255 do SortTbl.Vectors[SortTbl.Count].Table[X]:=UpCase(Char(X)); }
   SortTbl.Vectors[SortTbl.Count].Name:='Beze jmena';
  end;
  TextAttr:=W_B;
  WriteXYJ(40,2,tjCenter,' '+SortTbl.Vectors[CurrVec].Name+' ');
  for X:=0 to 255 do WriteChar(X,SortTbl.Vectors[CurrVec].Table[X]);
  TextAttr:=B_W;
  WriteChar(CurrPoz,SortTbl.Vectors[CurrVec].Table[CurrPoz]);
  TextAttr:=W_B;
  WriteXY(9,18,SavedSign[Saved]);
  WriteXY(10,21,'Cislo sady: '); Write(CurrVec:2,'/',SortTbl.Count);
  WriteXY(38,21,'Aktualni znak: "'); WriteCharXY(54,21,SortTbl.Vectors[CurrVec].Table[CurrPoz]);
  Write('" (',Byte(SortTbl.Vectors[CurrVec].Table[CurrPoz]),')        ');
 end;

procedure Save;
 var Err:Integer;
 begin
  repeat
   GotoXY(2,25);
   Write('Jmeno souboru [.',Ext[Mode],']: '); TextAttr:=Y_B; ClrEol;
   Cursor(True);
   FName:=AddExt(ReadStr(FName,0),Ext[Mode]); TextAttr:=W_B;
   Cursor(False);
   WriteXYC(2,25,'~F1~ Pomoc  ~F2~ Ulozit  ~F3~ Znovu nacist  ~PgUp/PgDn~ Dalsi/Predchozi  ~Esc~ Konec');
   if (CurrInput.ReadResult=27)or(FName='') then Exit;
   Assign(F,FName);
   {$I-} ReWrite(F,1); {$I+}
   Err:=IOResult;
  until Err=0;
  if Mode=Sort then ReCalc(SortTbl);
  BlockWrite(F,SortTbl,SortTbl.Count*266+1);
  if Mode=Sort then ReCalc(SortTbl);
  Close(F);
  WriteXYJ(78,24,tjRight,'[ '+Dir_Str(FName,34)+' ]');
  Saved:=True;
 end;

procedure Load;
 var Err:Integer;
 begin
  if not Saved then
   if Ask('Soubor nebyl ulozen. Opravdu nacist novy','AN')<>1 then
   begin
    WriteXYC(2,25,'~F1~ Pomoc  ~F2~ Ulozit  ~F3~ Znovu nacist  ~PgUp/PgDn~ Dalsi/Predchozi  ~Esc~ Konec');
    Exit;
   end;
  GotoXY(2,25);
  Write('Jmeno souboru [.',Ext[Mode],']: '); TextAttr:=Y_B; ClrEol;
  Cursor(True);
  FName:=AddExt(ReadStr(FName,0),Ext[Mode]); TextAttr:=W_B;
  Cursor(False);
  WriteXYC(2,25,'~F1~ Pomoc  ~F2~ Ulozit  ~F3~ Znovu nacist  ~PgUp/PgDn~ Dalsi/Predchozi  ~Esc~ Konec');
  if (CurrInput.ReadResult=27)or(FName='') then Exit;
  Assign(F,FName);
  {$I-} ReSet(F,1); {$I+}
  if IOResult=0 then
  begin
   if FileSize(F)>SizeOf(SortTbl) then BlockRead(F,SortTbl,SizeOf(SortTbl))
                                  else BlockRead(F,SortTbl,FileSize(F));
   Close(F); if Mode=Sort then ReCalc(SortTbl); end
   else SortTbl.Count:=0;
  if CurrVec>SortTbl.Count then CurrVec:=SortTbl.Count;
  if CurrVec=0 then CurrVec:=1;
  WriteXYJ(78,24,tjRight,'[ '+Dir_Str(FName,34)+' ]');
  Saved:=True;
 end;

function ChangeName:Boolean;
 var
  S:String;
  CInput:InputRec;
 begin
  CInput:=CurrInput;
  CurrInput.ReadMode:=[Ton];
  CurrInput.BufLen:=10;
  CurrInput.ControlChars:=[#$48,#$50]; TextAttr:=B_W;
  Cursor(True);
  GotoXY(35,2); S:=ReadStr(SortTbl.Vectors[CurrVec].Name,0);
  Cursor(False);
  ChangeName:=CurrInput.ReadResult=$4800;
  if (Lo(CurrInput.ReadResult)<>27)and CurrInput.Change then
  begin
   Saved:=False;
   S:=S+'          ';
   Move(S[1],SortTbl.Vectors[CurrVec].Name,10);
  end;
  CurrInput:=CInput;
 end;

procedure EditSort;
 procedure Help;
  var
   A:array [1..50*18] of Word;
   Cr:CrtRec;
  begin
   GetCrt(Cr);
   WOpen(15,7,65,20,A,True);
   Okno(15,7,65,20,Cyan, White,True,' Napoveda ');
   WriteXY(27,14,' Stisknete <Enter> ... ');
   Window(16,8,64,21);
   TextColor(Black);
   WriteLn;
   WriteXYL(1,1,48,
            'Tato cast programu MKSORT slouzi k vytvareni definic tabulek trideni dle narodnich abeced pro programy uzivajici'+
            ' knihovnu StringCS. Pomoci klavesy <Enter> si zvolte pismeno tabulky a sipkami jej zaradte na jeho misto v dle '+
            'abecedniho poradku.');
   WriteLn;
   WriteLn(' F2   - Ulozeni editovane tabulky na disk.');
   WriteLn(' F3   - Nacteni editovane tabulky z disku.');
   WriteLn(' PgDn - Nasledujici tabulka prevodu (soubor muze          obsahovat maximalne 20 tabulek).');
   WriteLn(' PgUp - Predchozi tabulka.');
   WriteLn(' Esc  - Konec programu.');
   while ReadKey<>^M do;
   SetCrt(Cr);
   WOpen(15,7,65,20,A,False);
  end;
 var
  Chnap:Boolean;
  C:Char;
 begin
  Chnap:=False;
  Cursor(False);
  repeat
   WriteTbl;
   if Chnap then Write(^H^H^H^H^H^H^H'Drzen');
   WriteXY(68,18,'<'+Long_Str(CurrPoz,3)+'>');
   C:=ReadKey;
   case C of
        ^M:Chnap:=not Chnap;
        ^[:;
        #0:case ReadKey of
                #$4D:begin
                      Inc(CurrPoz);
                      if Chnap then
                      begin
                       ChangeB(SortTbl.Vectors[CurrVec].Table[CurrPoz],SortTbl.Vectors[CurrVec].Table[CurrPoz-1],1);
                       Saved:=False;
                      end;
                     end;
                #$4B:begin
                      if Chnap then
                      begin
                       ChangeB(SortTbl.Vectors[CurrVec].Table[CurrPoz],SortTbl.Vectors[CurrVec].Table[CurrPoz-1],1);
                       Saved:=False;
                      end;
                      Dec(CurrPoz);
                     end;
                #$48:begin if CurrPoz<32 then
                      begin if ChangeName then Dec(CurrPoz,32);
                      end else Dec(CurrPoz,32); Chnap:=False; end;
                #$50:begin Inc(CurrPoz,32); Chnap:=False; end;
                #$49:if CurrVec>1 then Dec(CurrVec) else CurrVec:=SortTbl.Count;
                #$51:if CurrVec<SortTbl.Count then Inc(CurrVec) else if CurrVec=20 then CurrVec:=1 else
                     begin
                      Cursor(True);
                      if Ask('Inicializovat novou sadu ','AN'#$51)=1 then Inc(CurrVec) else CurrVec:=1;
                      Cursor(False);
                      WriteXYC(2,25,'~F1~ Pomoc  ~F2~ Ulozit  ~F3~ Znovu nacist  ~PgUp/PgDn~ Dalsi/Predchozi  ~Esc~ Konec');
                      end;
                #$3B:Help;
                #$3C:Save;
                #$3D:Load;
           else Write(^G);
           end;
        else Write(^G);
   end;
  until C=^[;
 end;

procedure EditUpc;
 procedure Help;
  var
   A:array [1..50*18] of Word;
   Cr:CrtRec;
  begin
   GetCrt(Cr);
   WOpen(15,7,65,20,A,True);
   Okno(15,7,65,20,Cyan, White,True,' Napoveda ');
   WriteXY(27,14,' Stisknete <Enter> ... ');
   Window(16,8,64,21);
   TextColor(Black);
   WriteLn;
   WriteXYL(1,1,48,
             'Tato cast programu MKSORT slouzi k vytvareni definic tabulek prevodu na velka pismena pro programy vyuzivajici '+
             'knihovnu StringCS. Pomoci sipek si zvolite pismeno tabulky a prepisete jej jeho obdobou ve velkych pismenech.');
   WriteLn(^J);
   WriteLn(' F2   - Ulozeni editovane tabulky na disk.');
   WriteLn(' F3   - Nacteni editovane tabulky z disku.');
   WriteLn(' PgDn - Nasledujici tabulka prevodu (soubor muze          obsahovat maximalne 20 tabulek).');
   WriteLn(' PgUp - Predchozi tabulka.');
   WriteLn(' Esc  - Konec programu.');
   while ReadKey<>^M do;
   SetCrt(Cr);
   WOpen(15,7,65,20,A,False);
  end;

 var
  C:Char;
 begin
  Cursor(False);
  repeat
   WriteTbl; WriteCharXY(65,18,Char(CurrPoz));
   WriteXY(68,18,'<'+Long_Str(CurrPoz,3)+'>');
   C:=ReadKey;
   case C of
   ^M,^I,^[:;
        #0:case ReadKey of
                #$4D:Inc(CurrPoz);
                #$4B:Dec(CurrPoz);
                #$48:if CurrPoz<32 then
                     begin if ChangeName then Dec(CurrPoz,32);
                     end else Dec(CurrPoz,32);
                #$50:Inc(CurrPoz,32);
                #$49:if CurrVec>1 then Dec(CurrVec) else CurrVec:=SortTbl.Count;
                #$51:if CurrVec<SortTbl.Count then Inc(CurrVec) else if CurrVec=20 then CurrVec:=1 else
                     begin
                      Cursor(True);
                      if Ask('Inicializovat novou sadu ','AN'#$51)=1 then Inc(CurrVec) else CurrVec:=1;
                      Cursor(False);
                      WriteXYC(2,25,'~F1~ Pomoc  ~F2~ Ulozit  ~F3~ Znovu nacist  ~PgUp/PgDn~ Dalsi/Predchozi  ~Esc~ Konec');
                      end;
                #$3B:Help;
                #$3C:Save;
                #$3D:Load;
           else Write(^G);
           end;
        else SortTbl.Vectors[CurrVec].Table[CurrPoz]:=C; Saved:=False;
   end;
  until C=^[;
 end;

const
 cHelpTxt='Syntaxe MKSORT [filespec[.SOR|.UPC]'^M^J' Program vytvari tabulky pro narodni trideni a prevody'^M+
         ' retezcu na velka pismena.'^Z;
 sHelpTxt:array [1..Length(cHelpTxt)] of Char = cHelpTxt;

begin
 Head:='Universal country utilities (MKSORT)  Version 1.0  ARNAY Software';
 HelpTXT:=@sHelpTxt;
 WriteHead(heHalt);
 WOpen(1,1,80,25,Scr,True);
 GetCrt(Cr);
 OldExitProc:=ExitProc;
 ExitProc:=@NewExitProc;
 Okno(1,1,80,24,Blue,White,False,'');
 Params^:=Upper(Params^);
 XTextAttr:=Y_B;
 if (ParamCount>0) and (Pos('.SOR'#1,ParamStr(1)+#1)>0) then Mode:=Sort else
  if (ParamCount>0) and (Pos('.UPC'#1,ParamStr(1)+#1)>0) then Mode:=UpTbl else
 case Ask('Editace tabulky velkych pismen nebo trideni','PT') of
      0:Halt(255);
      1:Mode:=UpTbl;
      2:Mode:=Sort;
 end;
 CurrInput.BufLen:=40;
 CurrInput.ReadMode:=[Ton,TransVP];
 if ParamCount>0 then FName:=ParamStr(1) else
 begin
  Write(' Jmeno souboru [.',Ext[Mode],']: '); TextAttr:=Y_B;
  FName:=ReadStr('',0);
  if (CurrInput.ReadResult=27)or(FName='') then Halt(255);
 end;
 FName:=AddExt(Upper(FName),Ext[Mode]);
 Assign(F,FName);
 {$I-} Reset(F,1); {$I+}
 if IOResult=0 then
 begin
  if FileSize(F)>SizeOf(SortTbl) then Halt(1);
  {$I-} BlockRead(F,SortTbl,FileSize(F)); {$I+}
  if IOResult<>0 then Halt(1);
  Close(F);
  if Mode=Sort then ReCalc(SortTbl);
 end else FillChar(SortTbl,SizeOf(SortTbl),0);
 Okno(1,1,80,24,Blue,White,False,Title[Mode]);
 WriteXYJ(78,24,tjRight,'[ '+Dir_Str(FName,34)+' ]');
 Okno(6,2,74,18,Blue,White,True,'');
 Okno(6,19,74,23,Blue,White,False,'');
 Window(1,1,80,25);
 CurrVec:=1; CurrPoz:=0; Saved:=True;
 repeat
  WriteXYC(1,25,' ~F1~ Pomoc  ~F2~ Ulozit  ~F3~ Znovu nacist  ~PgUp/PgDn~ Dalsi/Predchozi  ~Esc~ Konec');
  ClrEol;
  if Mode=Sort then EditSort else EditUpc;
  if not Saved then
   case Ask('Soubor nebyl ulozen. Ulozit nyni','AN') of
        1:Save;
        2:Saved:=True;
   end;
 until Saved;
end.