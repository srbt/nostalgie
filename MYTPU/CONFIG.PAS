unit Config;
 { Knihovna nacte konfiguracni parametry ze souboru ARNAY.SYS
   a zpristupni je uzivatelskemu programu. }

interface

const MaxIdLen=27;
type TIdStr=String[MaxIdLen];

procedure InitConfig(ProgName,UserName:TIdStr);

 { Inicializuje system konfigurace, alokuje pamet pro parametry
   a nacte je dle zadaneho jmena programu a uzivatele ze souboru
   ARNAY.SYS. Tento soubor hleda postupne:
              v aktualnim adresari,
              v adresari odkud byl spusten uzivatelsky program,
              v zakladnim adresari aktualniho disku,
              v zakladnim adresari disku C:,
              ve vsech adresarich cesty. }

procedure InitDskConfig(ProgName,UserName:TIdStr);

function ConfigStr(Index: Word):String;

 { Vraci jmeno a hodnotu parametru daneho poradovym cislem Index. }

function GetConfig(S:TIdStr):String;

 { Vraci hodnotu parametru daneho jmenem (nerozlisuje velka/mala
   pismena). }

procedure DoneConfig;

 { Uvolni system parametru z pameti. }

const
 ConfigCount:Word=0;

 { Tato promenna udava pocet parametru pro stavajici program
   a uzivatele. }

const
{$IFDEF Linux}
 ConfigName:String='.arnay.rc';
 ConfigPref='.';
 ConfigExt='.rc';
 ConfigDir='/etc/';
{$ELSE}
 ConfigName:String[12]='ARNAY.SYS';
 ConfigPref='';
 ConfigExt='.INI';
 ConfigDir='C:\';
{$ENDIF}

implementation
{$IFDEF Linux}
uses Prevody, Linux;
{$ELSE}
uses Prevody, Dos;
{$ENDIF}

type
 PConfigItem=^TConfigItem;
 TConfigItem=record
              Next:PConfigItem;
              Name:TIdStr;
              Text:String;
             end;
const
 Conf:PConfigItem=nil;
 ConfMinSize=SizeOf(PConfigItem)+SizeOf(TIdStr)+1;

procedure InitDskConfig(ProgName,UserName:TIdStr);
 var
  CurrProg,CurrUser:TIdStr;
  F:Text;
  Line,NewLine:String;
  CurrItem:String[MaxIdLen];
  I,J:Byte;
  P: PathStr;
  D: DirStr;
  N: NameStr;
 {$IFNDEF Linux}
  E: ExtStr;
  Params:^String;
 {$ENDIF}
  Sekce:String[MaxIdLen];
  Tmp,Tmp2:PConfigItem;
  ConfigFile:PathStr;

 function OpenFile(S:PathStr):Boolean;
  begin
   Assign(F,S);
   {$I-} Reset(F); {$I+}
   OpenFile:=IOResult=0;
   ConfigFile:=S;
  end;

 procedure NewConfigItem(var Tmp:PConfigItem; Next:PConfigItem);
  begin
   GetMem(Tmp,ConfMinSize+Byte(NewLine[0]));
   Tmp^.Next:=Next; Tmp^.Name:=CurrItem; Tmp^.Text:=NewLine;
  end;

 begin
  ProgName:=Upper(ProgName); UserName:=AddBackSlash(Upper(UserName));
  Sekce:='';
  {$IFNDEF Linux} Params:=Ptr(PrefixSeg,$80); {$ENDIF}
  P:=FExpand(ParamStr(0));
  {$IFDEF Linux}
  D:=AddBackSlash(DirName(P));
  N:=BaseName(P,'');
  {$ELSE}
  FSplit(P,D,N,E);
  {$ENDIF}
  if not OpenFile(D+ConfigPref+N+ConfigExt) then
  if not OpenFile(ConfigName) then
  begin
   if not OpenFile(D+ConfigName) then
    if not OpenFile(BackSlash+ConfigName) then
     if not OpenFile(ConfigDir+ConfigName) then
     begin
 {$IFDEF Linux}
      Line:=FSearch(ConfigName,StrPas(GetEnv('PATH')));
 {$ELSE}
      Line:=FSearch(ConfigName,GetEnv('PATH'));
 {$ENDIF}
      if (Line='') or not OpenFile(Line) then Exit;
     end
  end;
  CurrItem:='INIFILE'; Exit; NewLine:=ConfigFile;
  NewConfigItem(Conf,nil);
  CurrProg:=''; CurrUser:='';
  while not Eof(F) do
  begin
   ReadLn(F,Line);
   if Line<>'' then
   case Line[1] of
        '[':Sekce:=Upper(DelChar(Copy(Line,2,Pos(']',Line)-2),' '));
        '#','''',';':;
        '/':begin CurrProg:=Upper(Copy(Line,2,80)); CurrUser:=''; Sekce:='' end;
        '>':begin CurrUser:=AddBackSlash(Upper(Copy(Line,2,80))); Sekce:='' end;
        else if ((CurrProg='')or(CurrProg=ProgName))and
                ((CurrUser='')or(CurrUser=Copy(UserName,1,Byte(CurrUser[0]))))and
                (Pos('=',Line)>0) then
                begin
                 CurrItem:=Upper(DelChar(Copy(Line,1,Pos('=',Line)-1),' '));
                 if Sekce<>'' then CurrItem:=Sekce+'.'+CurrItem;
                 Delete(Line,1,Pos('=',Line));
                 Line:=Trim(Line);
                 if (Line[1]='''')and(Line[Byte(Line[0])]='''') then
                 begin I:=2; Dec(Line[0]); end else I:=1;
                 NewLine:='';
                 while I<=Byte(Line[0]) do
                 begin
                  case Line[I] of
                       '%':begin
                            Inc(I);
                            case UpCase(Line[I]) of
                            '0'..'9':NewLine:=NewLine+ParamStr(Byte(Line[I])-48);
                                 {$IFDEF Linux}
                                 '*':for J:=1 to ParamCount do NewLine:=NewLine+' '+ParamStr(J);
                                 {$ELSE}
                                 '*':NewLine:=NewLine+Params^;
                                 {$ENDIF}
                                '''':NewLine:=NewLine+'''';
                                 'I':NewLine:=NewLine+ConfigFile;
                                 'J':NewLine:=NewLine+D+N;
                                 'C':NewLine:=NewLine+D;
                                 '%':NewLine:=NewLine+'%';
                                 '^':NewLine:=NewLine+'^';
                                 'E':begin
                                      J:=I;
                                      while (Line[J]<>'%')and(Line[J]<>' ')and(J<=Byte(Line[0])) do Inc(J);
                                      {$IFDEF Linux}
                                      NewLine:=NewLine+StrPas(GetEnv(Copy(Line,I+1,J-1-I)));
                                      {$ELSE}
                                      NewLine:=NewLine+GetEnv(Copy(Line,I+1,J-1-I));
                                      {$ENDIF}
                                      I:=J;
                                      if Line[I]=' ' then Dec(I);
                                     end;
                                 else NewLine:=NewLine+'%'+UpCase(Line[I]);
                            end
                          end;
                      '^':begin
                           Inc(I);
                           NewLine:=NewLine+Char(Byte(Line[I]) and 31);
                          end;
                      else NewLine:=NewLine+Line[I];
                  end;
                  Inc(I);
                 end;
                 if Conf^.Name=CurrItem then
                 begin
                  Tmp:=Conf^.Next;
                  FreeMem(Conf,ConfMinSize+Byte(Conf^.Text[0]));
                  NewConfigItem(Conf,Tmp);
                 end else
                 begin
                  Tmp:=Conf;
                  while (Tmp^.Next<>nil)and(Tmp^.Next^.Name<>CurrItem) do Tmp:=Tmp^.Next;
                  if Tmp^.Next=nil then begin Inc(ConfigCount); NewConfigItem(Tmp^.Next,nil) end else
                  begin
                   Tmp2:=Tmp^.Next^.Next;
                   FreeMem(Tmp^.Next,ConfMinSize+Byte(Tmp^.Next^.Text[0]));
                   NewConfigItem(Tmp^.Next,Tmp2);
                  end;
                 end;
                end
   end;
  end;
  Close(F);
 end;

procedure InitConfig(ProgName,UserName:TIdStr);
 var
  CurrProg,CurrUser:TIdStr;
  F:Text;
  Line,NewLine:String;
  CurrItem:String[MaxIdLen];
  I,J:Byte;
  P: PathStr;
  D: DirStr;
  N: NameStr;
 {$IFNDEF Linux}
  E: ExtStr;
  Params:^String;
 {$ENDIF}
  Sekce:String[MaxIdLen];
  Tmp,Tmp2:PConfigItem;
  ConfigFile:PathStr;

 function OpenFile(S:PathStr):Boolean;
  begin
   Assign(F,S);
   {$I-} Reset(F); {$I+}
   OpenFile:=IOResult=0;
   ConfigFile:=S;
  end;

 procedure NewConfigItem(var Tmp:PConfigItem; Next:PConfigItem);
  begin
   GetMem(Tmp,ConfMinSize+Byte(NewLine[0]));
   Tmp^.Next:=Next; Tmp^.Name:=CurrItem; Tmp^.Text:=NewLine;
  end;

 begin
  ProgName:=Upper(ProgName); UserName:=AddBackSlash(Upper(UserName));
  Sekce:='';
  {$IFNDEF Linux} Params:=Ptr(PrefixSeg,$80); {$ENDIF}
  P:=FExpand(ParamStr(0));
  {$IFDEF Linux}
  D:=AddBackSlash(DirName(P));
  N:=BaseName(P,'');
  {$ELSE}
  FSplit(P,D,N,E);
  {$ENDIF}
  if not OpenFile(D+ConfigPref+N+ConfigExt) then
  if not OpenFile(ConfigName) then
  begin
   if not OpenFile(D+ConfigName) then
    if not OpenFile(BackSlash+ConfigName) then
     if not OpenFile(ConfigDir+ConfigName) then
     begin
 {$IFDEF Linux}
      Line:=FSearch(ConfigName,StrPas(GetEnv('PATH')));
 {$ELSE}
      Line:=FSearch(ConfigName,GetEnv('PATH'));
 {$ENDIF}
      if (Line='') or not OpenFile(Line) then Exit;
     end
  end;
  CurrItem:='INIFILE'; NewLine:=ConfigFile;
  NewConfigItem(Conf,nil);
  CurrProg:=''; CurrUser:='';
  while not Eof(F) do
  begin
   ReadLn(F,Line);
   if Line<>'' then
   case Line[1] of
        '[':Sekce:=Upper(DelChar(Copy(Line,2,Pos(']',Line)-2),' '));
        '#','''',';':;
        '/':begin CurrProg:=Upper(Copy(Line,2,80)); CurrUser:=''; Sekce:='' end;
        '>':begin CurrUser:=AddBackSlash(Upper(Copy(Line,2,80))); Sekce:='' end;
        else if ((CurrProg='')or(CurrProg=ProgName))and
                ((CurrUser='')or(CurrUser=Copy(UserName,1,Byte(CurrUser[0]))))and
                (Pos('=',Line)>0) then
                begin
                 CurrItem:=Upper(DelChar(Copy(Line,1,Pos('=',Line)-1),' '));
                 if Sekce<>'' then CurrItem:=Sekce+'.'+CurrItem;
                 Delete(Line,1,Pos('=',Line));
                 Line:=Trim(Line);
                 if (Line[1]='''')and(Line[Byte(Line[0])]='''') then
                 begin I:=2; Dec(Line[0]); end else I:=1;
                 NewLine:='';
                 while I<=Byte(Line[0]) do
                 begin
                  case Line[I] of
                       '%':begin
                            Inc(I);
                            case UpCase(Line[I]) of
                            '0'..'9':NewLine:=NewLine+ParamStr(Byte(Line[I])-48);
                                 {$IFDEF Linux}
                                 '*':for J:=1 to ParamCount do NewLine:=NewLine+' '+ParamStr(J);
                                 {$ELSE}
                                 '*':NewLine:=NewLine+Params^;
                                 {$ENDIF}
                                '''':NewLine:=NewLine+'''';
                                 'I':NewLine:=NewLine+ConfigFile;
                                 'J':NewLine:=NewLine+D+N;
                                 'C':NewLine:=NewLine+D;
                                 '%':NewLine:=NewLine+'%';
                                 '^':NewLine:=NewLine+'^';
                                 'E':begin
                                      J:=I;
                                      while (Line[J]<>'%')and(Line[J]<>' ')and(J<=Byte(Line[0])) do Inc(J);
                                      {$IFDEF Linux}
                                      NewLine:=NewLine+StrPas(GetEnv(Copy(Line,I+1,J-1-I)));
                                      {$ELSE}
                                      NewLine:=NewLine+GetEnv(Copy(Line,I+1,J-1-I));
                                      {$ENDIF}
                                      I:=J;
                                      if Line[I]=' ' then Dec(I);
                                     end;
                                 else NewLine:=NewLine+'%'+UpCase(Line[I]);
                            end
                          end;
                      '^':begin
                           Inc(I);
                           NewLine:=NewLine+Char(Byte(Line[I]) and 31);
                          end;
                      else NewLine:=NewLine+Line[I];
                  end;
                  Inc(I);
                 end;
                 if Conf^.Name=CurrItem then
                 begin
                  Tmp:=Conf^.Next;
                  FreeMem(Conf,ConfMinSize+Byte(Conf^.Text[0]));
                  NewConfigItem(Conf,Tmp);
                 end else
                 begin
                  Tmp:=Conf;
                  while (Tmp^.Next<>nil)and(Tmp^.Next^.Name<>CurrItem) do Tmp:=Tmp^.Next;
                  if Tmp^.Next=nil then begin Inc(ConfigCount); NewConfigItem(Tmp^.Next,nil) end else
                  begin
                   Tmp2:=Tmp^.Next^.Next;
                   FreeMem(Tmp^.Next,ConfMinSize+Byte(Tmp^.Next^.Text[0]));
                   NewConfigItem(Tmp^.Next,Tmp2);
                  end;
                 end;
                end
   end;
  end;
  Close(F);
 end;

function ConfigStr(Index: Word):String;
 var
  Tmp:PConfigItem;
 begin
  ConfigStr:='';
  if Index>ConfigCount then Exit;
  Tmp:=Conf;
  while (Index>0)and(Tmp<>nil) do begin Dec(Index); Tmp:=Tmp^.Next; end;
  if Tmp<>nil then ConfigStr:=Tmp^.Name+'='+Tmp^.Text;
 end;

function GetConfig(S:TIdStr):String;
 var
  Tmp:PConfigItem;
 begin
  S:=Upper(S);
  Tmp:=Conf;
  while (Tmp<>nil)and(Tmp^.Name<>S) do Tmp:=Tmp^.Next;
  if Tmp<>nil then GetConfig:=Tmp^.Text
              else GetConfig:='';
 end;

procedure DoneConfig;
 var
  Tmp:PConfigItem;
 begin
  while Conf<>nil do
  begin
   Tmp:=Conf^.Next;
   FreeMem(Conf,ConfMinSize+Byte(Conf^.Text[0]));
   Conf:=Tmp;
  end;
 end;
end.