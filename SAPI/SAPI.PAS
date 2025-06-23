uses Objects, Views, App, Drivers, Prevody, MsgBox, Crt, Obraz, Menus,
     SapiCon, HelpCon, Dialogs, StdDlg, Dos, Async;

const
 Copyright:String[72]=#13#3'SAPI BASIC EMULATOR'#13#13#3'Version 1.0'#13#13#3'Copyright (c) 1993 by'#13#13#3'A R N A Y';
 Header:String[28]='* SAPI BASIC  V T.1 (C) 1991';
type
 PBreakP = ^TBreakP;
 TBreakP = record
            Num:Word;
            Next:PBreakP;
           end;

 PScrList=^TScrList;
 TScrList=object(TCollection)
           procedure FreeItem(Item:Pointer);virtual;
          end;

 PScreen=^TScreen;
 TScreen=object(TScroller)
          LF:Boolean;
          procedure Draw; virtual;
          procedure Print(S:String;L:Boolean);
          procedure Cls;
          procedure Tab(S:String);
          procedure Ready;
         end;

 PList=^TList;
 TList=object(TListViewer)
        ProgramName:PString;
        procedure LoadFile(S:String);
        procedure Inp(S:String);
        procedure Let(S:String);
        procedure Wait(S:String);
        procedure Call(S:String);
        function Go(var I:Integer):Boolean;
        function SearchLine(var I:Integer):Boolean;
        function GetPalette:PPalette; virtual;
        function GetText(Item: Integer; MaxLen: Integer): String; virtual;
        procedure SelectItem(Item: Integer); virtual;
        procedure LogIn(Co:Byte; Kolik:Integer);
       end;

 PWatch=^TWatch;
 TWatch=object(TWindow)
         procedure Draw; virtual;
        end;

 PSapi=^TSapi;
 TSapi=object(TApplication)
        EditorName:PString;
        BreakP:PBreakP;
        FindStr:String[60];
        OutPort,
        InPort:Byte;
        Len:Integer;
        WaitSet:Real;
        Mask:Byte;
        Vars:array [1..26] of Integer;
        Pole:array [0..500] of Integer;
        Ports:set of 1..32;
        AnalOut:array [1..3] of Integer;
        AnalIn:array [1..32] of Integer;
        AnalStr:array [1..32] of String[30];
        CallStack:array [0..14] of Integer;
        CallLine:array [0..14] of String[80];
        StepLine,
        Calls:Integer;
        Hard:Boolean;
        List:PStringCollection;
        ScrList:PScrList;
        WScreen:PScreen;
        WList:PList;
        WWatch:PWatch;
        constructor Init;
        destructor Done; virtual;
        procedure InitMenuBar; virtual;
        procedure InitStatusLine; virtual;
        procedure HandleEvent(var Event:TEvent); virtual;
        procedure ToSapi;
        procedure FromSapi;
        procedure InitScr;
        procedure InitWatch;
        procedure InitList;
        procedure ResetSapi;
        procedure Clear;
        procedure WriteFile(S:String);
        procedure PutChar(C:Char);
        procedure PutStr(S:String);
        function GetChar(var C:Char):Boolean;
        function GetStr(var S:String):Boolean;
        function IsBreakP(I:Integer):Boolean;
       end;

 PMyStLine=^TMyStLine;
 TMyStLine=object(TStatusLine)
            function Hint(AhelpCtx:Word):String; virtual;
           end;

 PAnalDial=^TAnalDial;
 TAnalDial=object( TDialog)
            procedure HandleEvent(var Event:TEvent); virtual;
           end;

 PConDlg=^TConDlg;
 TConDlg=object( TDialog)
          Value:Integer;
          procedure HandleEvent(var Event:TEvent); virtual;
         end;

 PWLabel=^TWLabel;
 TWLabel=object(TView)
          procedure Draw; virtual;
         end;
var
 InPorts  : array [0..3] of Word absolute $0:$0400;
 OutPorts : array [0..3] of Word absolute $0:$0408;
 Tim      : LongInt absolute $0:$046C;
 Sec      : LongInt;
 Log      : Text;

function Compute(S:String):Integer;
 function GetPar(S:String;var Poz:Byte):Integer;
  var
   V:Integer;
   Sign:Boolean;
  begin
   V:=0;
   Inc(Poz);
   if S[Poz] in ['-','+'] then
   begin
    Sign:=S[Poz]='-';
    Inc(Poz);
   end else Sign:=false;
   while (Poz<=Byte(S[0]))and (S[Poz] in Cislice) do
   begin
    V:=V*10+Byte(S[Poz])-48;
    Inc(Poz);
   end;
   if Sign then GetPar:=-V else GetPar:=V;
  end;

 function Get1Par(var S:String;var Poz:Byte):Integer;
  var
   I:Byte;
   K,J:Integer;
  begin
   I:=Poz-1;
   while (I>0) and (S[I] in Cislice) do Dec(I);
   if (I>0) and (S[I]='-') then Dec(I);
   Inc(I);
   Val(Copy(S,I,Poz-I),J,K);
   Delete(S,I,Poz-I);
   Get1Par:=J;
   Poz:=I;
  end;

 function Get2Par(var S:String; Poz:Byte):Integer;
  var
   I:Byte;
   K,J:Integer;
  begin
   I:=Poz+1;
   if S[I]='-' then Inc(I);
   while (I<=Byte(S[0])) and (S[I] in Cislice) do Inc(I);
   Inc(Poz);
   Val(Copy(S,Poz,I-Poz),J,K);
   Delete(S,Poz,I-Poz);
   Get2Par:=J;
  end;

 var
  Count, I:Byte;
  S1:String;
  V,J:Integer;
 begin
  while Pos('(',S)>0 do
  begin
   I:=Pos('(',S);
   Count:=1;
   while Count>0 do
   begin
    Inc(I);
    case S[I] of
         '(':Inc(Count);
         ')':Dec(Count);
    end;
   end;
    Count:=Pos('(',S);
    Insert(Long_Str(Compute(Copy(S,Count+1,I-Count-1)),0),S,I+1);
    Delete(S,Count,I-Count+1);
  end;

  for I:=Byte(S[0]) downto 1 do
  case S[I] of
   'A'..'Z':begin
             S1:=Long_Str(PSapi(Application)^.Vars[Byte(S[I])-64],0);
             Delete(S,I,1);
             Insert(S1,S,I);
            end;
   '@':begin
        Count:=I;
        S1:=Long_Str(PSapi(Application)^.Pole[GetPar(S,Count)],0);
        Delete(S,I,Count-I);
        Insert(S1,S,I);
       end;
    #1:begin
        Count:=I;
        S1:=Long_Str(Random(GetPar(S,Count))+1,0);
        Delete(S,I,Count-I);
        Insert(S1,S,I);
       end;
    #2:begin
        Count:=I;
        S1:=Long_Str(Abs(GetPar(S,Count)),0);
        Delete(S,I,Count-I);
        Insert(S1,S,I);
       end;
    #3:;
    #4:begin
        S1:='';
        repeat
         repeat
          J:=InputBox('Funkce In Char','Znak nebo jeho ASCII kod (\000 nebo \$00):',S1,4);
         until (J=cmOk)and(S1<>'');
         S1:=Upper(S1);
         if S1[1]='\' then Val(Copy(S1,2,3),V,J) else V:=Byte(S1[1]);
        until V in [8,13,32..95];
        S1:=Long_Str(V,0);
        Delete(S,I,1);
        Insert(S1,S,I);
       end;
    #5:;
    #6:begin
        Count:=I;
        S1:=Long_Str(PSapi(Application)^.AnalOut[GetPar(S,Count)-131],0);
        Delete(S,I,Count-I);
        Insert(S1,S,I);
       end;
    #7:;
    #8:begin
        S1:=Long_Str(PSapi(Application)^.Len,0);
        Delete(S,I,1);
        Insert(S1,S,I);
       end;
    #9:begin
        S1:='32000';
        Delete(S,I,1);
        Insert(S1,S,I);
       end;
   #10:begin
        S1:='1002';
        Delete(S,I,1);
        Insert(S1,S,I);
       end;
  end;
  I:=1;
  while I<=Byte(S[0]) do if S[I] in ['*','/'] then
  begin
   Count:=I;
   case S[I] of
        '*':S1:=Long_Str(Get1Par(S,Count)*Get2Par(S,I),0);
        '/':S1:=Long_Str(Get1Par(S,Count) div Get2Par(S,I),0);
   end;
   Insert(S1,S,Count+1);
   Delete(S,Count,1);
   I:=Count;
  end else Inc(I);

  I:=1;
  while I<=Byte(S[0]) do if S[I] in ['+','-'] then
  begin
   Count:=I;
   case S[I] of
        '+':S1:=Long_Str(Get1Par(S,Count)+Get2Par(S,I),0);
        '-':S1:=Long_Str(Get1Par(S,Count)-Get2Par(S,I),0);
   end;
   Insert(S1,S,Count+1);
   Delete(S,Count,1);
   I:=Count+1;
  end else Inc(I);

  I:=1;
  while I<=Byte(S[0]) do if S[I] in ['<','>','=','#'] then
  begin
   Count:=I;
   case S[I] of
        '<':if S[I+1]='=' then
            begin
             Inc(I);
             S1:=Long_Str(Byte(Get1Par(S,Count)<=Get2Par(S,I)),0);
            end else S1:=Long_Str(Byte(Get1Par(S,Count)<Get2Par(S,I)),0);
        '>':if S[I+1]='=' then
            begin
             Inc(I);
             S1:=Long_Str(Byte(Get1Par(S,Count)>Get2Par(S,I)),0);
            end else S1:=Long_Str(Byte(Get1Par(S,Count)>Get2Par(S,I)),0);
        '=':S1:=Long_Str(Byte(Get1Par(S,Count)=Get2Par(S,I)),0);
        '#':S1:=Long_Str(Byte(Get1Par(S,Count)<>Get2Par(S,I)),0);
   end;
   Insert(S1,S,Count+1);
   Delete(S,Count,1);
   I:=Count+1;
  end else Inc(I);
  Val(S,V,J);
  Compute:=V;
 end;

function Vypocti(S:String):Integer;
 procedure Nahrad(var S:String; F:String; Code:Char);
  var
   I:Byte;
  begin
   while Pos(F,S)>0 do
   begin
    I:=Pos(F,S);
    S[I]:=Code;
    Delete(S,I+1,Byte(F[0])-1);
   end;
  end;

 const F: array [1..10] of String[10] =('RND','ABS','HEX','INCHAR','PEEK',
                                        'IN','INM','LEN','TOP','SIZE');
 var Count, I:Byte;
     S1:String[10];

 function GetHexPar(S:String;var Poz:Byte):Integer;
  var
   S1:String[10];
   V:Longint;
   I:Integer;
  begin
   S1:=Copy(S,Poz+2,Pos(')',Copy(S,Poz+2,50))-1);
   Poz:=Poz+Byte(S1[0])+3;
   Val('$'+S1,V,I);
   GetHexPar:=Integer(V);
  end;

 begin
  S:=Upper(S);
  while Pos('''',S)>0 do
  begin
   I:=Pos('''',S);
   Insert(Long_Str(Byte(S[I+1]),0),S,I);
   I:=Pos('''',S);
   Delete(S,I,Pos('''',Copy(S,I+1,80)+'''')+1);
  end;
  while Pos(' ',S)>0 do Delete(S,Pos(' ',S),1);
  for I:=1 to 10 do Nahrad(S,F[I],Char(I));
  while Pos(#3,S)>0 do
  begin
   I:=Pos(#3,S);
   Count:=I;
   S1:=Long_Str(GetHexPar(S,Count),0);
   Delete(S,I,Count-I);
   Insert(S1,S,I);
  end;
  Vypocti:=Compute(S);
 end;

function TMyStLine.Hint(AHelpCtx:Word):String;
 begin
  if (AHelpCtx>1000)and(AHelpCtx<=1000+HelpCount) then
   Hint:=HelpMsg[AHelpCtx-1000] else Hint:='';
 end;

procedure TScrList.FreeItem(Item:Pointer);
 begin
  if Item<>nil then DisposeStr(Item);
 end;

function TList.SearchLine(var I:Integer):Boolean;
 var
  L:PStringCollection;
  S:PString;
  B:Boolean;
 begin
  L:=PSapi(Application)^.List;
  S:=NewStr(ReplaceChar(Long_Str(I,5),' ','0'));
  B:=L^.Search(S,I);
  SearchLine:=(I<L^.Count)and(Copy(PString(L^.At(I))^,1,5)=S^);
 end;

procedure TList.LoadFile(S:String);
 var
  F:Text;
  S1:String;
  I:Integer;

 procedure Vloz;
  begin
   S1:=Upper(Trim(S1));
   if (S1>'')and(S1[1] in Cislice) then
   begin
    I:=1;
    while (S1[I] in Cislice)and(I<=Byte(S1[0])) do Inc(I);
    if Copy(S1,I,1)<>' ' then Insert(' ',S1,I);
    while Pos(' ',S1)<6 do S1:='0'+S1;
    PSapi(Application)^.List^.Insert(NewStr(S1));
   end;
  end;

 begin
  if not ExFile(S) then
  begin
   I:=MessageBox(^C+'Nemohu otevrit soubor '+S+' !',nil,mfCancelButton);
   Exit;
  end;
  if ProgramName<>nil then DisposeStr(ProgramName);
  Assign(F,S);
  Reset(F);
  ReadLn(F,S1);
  if Upper(S1)<>Header then
  begin
   I:=MessageBox(^C+'Soubor '+S+' neobsahuje hlavicku'#13+
                    '"* SAPI BASIC  V T.1 (C) 1991" !',nil,mfCancelButton);
   Close(F);
   Exit;
  end;
  ReadLn(F,S1);
  if Copy(S1,1,1)='*' then ProgramName:=NewStr(Upper(Trim(Copy(S1,2,60))))
   else Vloz;
  while not Eof(F) do
  begin
   ReadLn(F,S1);
   Vloz;
  end;
  Close(F);
  SetRange(PSapi(Application)^.List^.Count);
  DrawView;
 end;

procedure TList.Inp(S:String);
 const U='"';
 var
  S1:String;
  K,J,I:Byte;
  V:Integer;
  Vypsat:Boolean;
 begin
  Vypsat:=True;
  I:=1;
  S:=Upper(Trim(S));
  with PSapi(Application)^.WScreen^ do
  while I<=Byte(S[0]) do
  begin
   case S[I] of
           U:begin
              J:=I+1;
              while S[J]<>U do Inc(J);
              Print(SubStr(S,I,J)+',',PSapi(Application)^.Hard);
              I:=J;
              Vypsat:=False;
             end;
         ',':Vypsat:=True;
         '@':begin
              J:=Pos('(',Copy(S,I,50))+1;
              K:=1;
              while K>0 do
              begin
               case S[J+I] of
                    '(':Inc(K);
                    ')':Dec(K);
               end;
               Inc(J);
              end;
              if Vypsat then Print(U+Copy(S,I,J)+U+',',PSapi(Application)^.Hard);
              Print('":",',PSapi(Application)^.Hard);
              S1:='';
              repeat
               K:=InputBox('Prikaz Input','Vlozte hodnotu promenne '+Copy(S,I,J)+': ',S1,15);
              until (K=cmOk)and(S1<>'');
              S1:=Upper(S1);
              Print(U+S1+U,PSapi(Application)^.Hard);
              V:=Vypocti(S1);
              K:=Vypocti(SubStr(Copy(S,I,J),Pos('(',Copy(S,I,J))+1,J-1));
              PSapi(Application)^.Pole[K]:=V;
             end;
    'A'..'Z':begin
              if Vypsat then Print(U+S[I]+U+',',PSapi(Application)^.Hard);
              Print('":",',PSapi(Application)^.Hard);
              S1:='';
              repeat
               K:=InputBox('Prikaz Input','Vlozte hodnotu promenne '+S[I]+': ',S1,15);
              until (K=cmOk)and(S1<>'');
              S1:=Upper(S1);
              Print(U+S1+U,PSapi(Application)^.Hard);
              V:=Vypocti(S1);
              PSapi(Application)^.Vars[Byte(S[I])-64]:=V;
             end;
   end;
   Inc(I);
  end;
 end;

procedure TList.Let(S:String);
 var
  I:Integer;
  S1,S2:String;
 begin
  S:=Upper(S);
  while Pos(' ',S)>0 do Delete(S,Pos(' ',S),1);
  S2:=S+',';
  while S2<>'' do
  begin
   S:=Copy(S2,1,Pos(',',S2)-1);
   Delete(S2,1,Pos(',',S2));
   if S[1]='@' then
   begin
    S1:=Copy(S,1,Pos('=',S)-1);
    I:=Byte(S1[0]);
    while (S1[I]<>')') and (I>0) do Dec(I);
    I:=Vypocti(SubStr(S,Pos('(',S),I));
    PSapi(Application)^.Pole[I]:=Vypocti(Copy(S,Pos('=',S)+1,60));
   end else
   PSapi(Application)^.Vars[Byte(S[1])-64]:=Vypocti(Copy(S,Pos('=',S)+1,60));
  end;
 end;

procedure TList.Wait(S:String);
 var I:Word;
 begin
  I:=Word(Vypocti(S));
  Delay(Round(I*PSapi(Application)^.WaitSet*100));
 end;

procedure TList.Call(S:String);
 var
  I:Integer;
  J:Byte;
 begin
  I:=Vypocti(S);
  with PSapi(Application)^ do
  begin
   case I of
      0,25:PSapi(Application)^.ResetSapi;
       $4d:PSapi(Application)^.WScreen^.Ready;
       $70:begin
            PSapi(Application)^.WScreen^.Print('">",',False);
            PSapi(Application)^.StepLine:=0;
           end;
      4100,
      4190:begin
            for J:=1 to 32 do AnalIn[J]:=Vypocti(AnalStr[J]);
            Move(AnalIn,Pole,SizeOf(AnalIn));
           end;
      4110:begin
            Ports:=Ports+[Vars[11]];
            LogIn(Vars[11],1);
            WWatch^.DrawView;
            Wait('T*10');
           end;
      4120:begin
            Ports:=Ports-[Vars[11]];
            LogIn(Vars[11],0);
            WWatch^.DrawView;
            Wait('T*10');
           end;
      4130:begin Ports:=Ports+[Vars[11]]; LogIn(Vars[11],1); end;
      4140:begin Ports:=Ports-[Vars[11]]; LogIn(Vars[11],0); end;
      4150:begin
            Ports:=Ports+[Vars[11]];
            LogIn(Vars[11],1);
            WWatch^.DrawView;
            Wait('T*10');
            Ports:=Ports-[Vars[11]];
            LogIn(Vars[11],0);
           end;
      4160:Wait('T*10');
      4180:begin
            FillChar(Ports,SizeOf(Ports),0);
            FillChar(AnalOut,SizeOf(Analout),0);
            LogIn($FF,0);
           end;
      4642:;                                    {Doplnit soucet programu !!!}
      else
       I:=MessageBox(^C+'Nedefinovane volani CALL '+S+' ('+Long_Str(I,0)+')',nil,mfCancelButton);
   end;
  end;
 end;

function TList.Go(var I:Integer):Boolean;
 const
  C: array[1..28] of String[15]=
                    ('NEXT','LET','CLS','CLEAR','HARD','DISPL','IF','GOTO',
                     'GOSUB','RETURN','REM','FOR','INPUT','PRINT',
                     'LPRINT','END','STOP','CALL','OUTCHAR','OUT','O$',
                     'I$','WAIT','POKE','MASK','TAB','BYTE','WORD');

 var
  L:PStringCollection;
 function GetCommand(var S:String):Byte;
  var
   I,J:Byte;
   T:Boolean;
  begin
   I:=0;
   T:=False;
   repeat
    J:=1;
    Inc(I);
    while (S[J]=C[I][J]) and (S[J]<>'.') do Inc(J);
    T:=(J=Byte(C[I][0])+1)or(S[J]='.');
   until T or (I=28);
    if not T and (Pos('=',S)>0)and(S[1] in ['@'..'Z']) then I:=29 else
     if T then Delete(S,1,J-1+Byte(S[J]='.')) else
     begin
      I:=MessageBox(#3'Neznamy prikaz !'#13#3+S,nil,mfCancelButton);
      I:=0;
     end;
   GetCommand:=I;
  end;

 function PushLine(I:Integer;S:String):Boolean;
  begin
   with PSapi(Application)^ do if Calls<15 then
   begin
    CallStack[Calls]:=I;
    CallLine[Calls]:=S;
    Inc(Calls);
    PushLine:=True;
   end else PushLine:=False;
  end;

 function PopLine(var I:Integer;var S:String):Boolean;
  begin
   with PSapi(Application)^ do if Calls>0 then
   begin
    Dec(Calls);
    I:=CallStack[Calls];
    S:=CallLine[Calls];
    PopLine:=True;
   end else PopLine:=False;
  end;

 function ForLine(S,Line:String):Boolean;
  begin
   ForLine:=False;
   if not PushLine(I,S+#1+Line) then Exit;
   S:=Trim(S);
   if (S>'')and(S[1] in ['A'..'Z']) then
   begin
    PSapi(Application)^.Vars[Byte(S[1])-64]:=Vypocti(SubStr(S,Pos('=',S)+1,Pos('TO',S)-1));
    ForLine:=True;
   end;
  end;

 function NextLine(S:String;var Line:String):Boolean;
  var
   J,D:Integer;
   S1,S2:String;
   V:^Integer;
   V1:Integer;
  begin
   D:=1;
   NextLine:=False;
   if not PopLine(J,S1) then Exit;
   if not PushLine(J,S1) then Exit;
   if Pos(#1,S1)=0 then Exit;
   S2:=Copy(S1,Pos(#1,S1)+1,60);
   S1:=Trim(Copy(S1,1,Pos(#1,S1)-1));
   if Pos('STEP',S1)>0 then
   begin
    D:=Vypocti(Trim(Copy(S1,Pos('STEP',S1)+4,60)));
    Delete(S1,Pos('STEP',S1),60);
   end;
   V1:=Vypocti(Trim(Copy(S1,Pos('TO',S1)+2,60)));
   V:=Addr(PSapi(Application)^.Vars[Byte(S1[1])-64]);
   if ((V^<V1)and(D<0))or((V^>V1)and(D>0))or(D=0) then Exit;
   NextLine:=True;
   if ((D>0)and(V^+D>V1))or((D<0)and(V^+D<V1)) then
     begin Dec(PSapi(Application)^.Calls); Exit; end;
   Inc(V^,D);
   I:=J;
   Line:=S2;
  end;

 var
  Line,
  Comm:String;
  Uvoz:Boolean;
  J:Integer;
  
 begin
  Go:=False;
  L:=PSapi(Application)^.List;
  if not (I<L^.Count) then Exit;
   if I=-1 then Exit;
   FocusItem(I);
   Line:=Copy(PString(L^.At(I))^,7,80);
   while Line<>'' do
   begin
    if I=-1 then Exit;
    if KeyPressed then
     if ReadKey=#0 then
      if ReadKey=#$43 then
      begin
       J:=MessageBox(#3'Program zastaven uzivatelem !'#13#3'Pokracovat dale ?',nil,
                     mfYesButton or mfNoButton or mfConfirmation);
       if J=cmNo then Exit;
      end;
    StatusLine^.Update;
    Uvoz:=False;
    J:=1;
    while (J<=Byte(Line[0]))and not((Line[J]=':')and not Uvoz) do
    begin
     if Line[J]='"' then Uvoz:=not Uvoz;
     Inc(J);
    end;
    if ((Line[J]=':')and not Uvoz) then Dec(J);
    Comm:=Trim(Copy(Line,1,J));
    Delete(Line,1,J+1);
    case GetCommand(Comm) of
          1:if not NextLine(Comm,Line) then
            begin
             J:=MessageBox(#3'Prikaz NEXT'+Comm+' !'#13#3'Program zastaven !',nil,mfCancelButton);
             Exit;
            end;
          2:Let(Comm);
          3:PSapi(Application)^.WScreen^.Cls;
          4:PSapi(Application)^.Clear;
          5:PSapi(Application)^.Hard:=True;
          6:PSapi(Application)^.Hard:=False;
          7:begin
             Comm:=Trim(Comm);
             Uvoz:=false;
             J:=1;
             while (J<=Byte(Comm[0])) and ((Comm[J]<>' ') or Uvoz) do
             begin
              if Comm[J]='''' then Uvoz:=not Uvoz;
              Inc(J)
             end;
             if J=Byte(Comm[0]) then
             begin
              J:=MessageBox(#3'Prikaz "IF '+Comm+'",'#13#3'Program zastaven !',nil,mfCancelButton);
              Exit;
             end;
             if Vypocti(Copy(Comm,1,J-1))<>0 then Line:=Copy(Comm,J+1,60)+':'+Line
             else Line:='';
            end;
          8:begin
             J:=Vypocti(Comm);
             if SearchLine(J) then
             begin
              I:=J-1;
              Line:='';
             end else
             begin
              J:=MessageBox(#3'Prikaz "GOTO'+Comm+'",'#13#3'Radek '+Long_Str(Vypocti(Comm),0)
                                    +' nenalezen !'#13#3'Program zastaven !',nil,mfCancelButton);
              Exit;
             end;
            end;
          9:begin
             J:=Vypocti(Comm);
             if SearchLine(J) then
             begin
              if not PushLine(I,Line) then
              begin
               J:=MessageBox(#3'Prikaz "GOSUB '+Comm+'",'#13#3'Prilis mnoho vnorenych podprogramu !'+
                               #13#3'Program zastaven !',nil,mfCancelButton);
              Exit;
              end;
              I:=J-1;
              Line:='';
             end else
             begin
              J:=MessageBox(#3'Prikaz "GOSUB '+Comm+'",'#13#3'Radek '+Long_Str(Vypocti(Comm),0)
                                    +' nenalezen !'#13#3'Program zastaven !',nil,mfCancelButton);
              Exit;
             end;
            end;
         10:begin
             if not PopLine(J,Line) then
             begin
              J:=MessageBox(#3'Prikaz "RETURN",'#13#3'Volani GOSUB nenalezeno !'+
                               #13#3'Program zastaven !',nil,mfCancelButton);
              Exit;
             end;
             I:=J;
            end;
         11:;
         12:if not ForLine(Comm,Line) then
            begin
             J:=MessageBox(#3'Chyba v prikazu FOR'+Comm+' !'#13#3'Program zastaven !',nil,mfCancelButton);
             Exit;
            end;
         13:Inp(Comm);
         14:PSapi(Application)^.WScreen^.Print(Comm,PSapi(Application)^.Hard);
         15:PSapi(Application)^.WScreen^.Print(Comm,True);
         16:begin
             PSapi(Application)^.WScreen^.Ready;
             J:=MessageBox(#3'Program zastaven prikazem END !',nil,mfCancelButton);
             Exit;
            end;
         17:begin
             PSapi(Application)^.WScreen^.Print('',PSapi(Application)^.Hard);
             PSapi(Application)^.WScreen^.Print('"* '+Copy(PString(L^.At(I))^,7,80)+'"',
                                                PSapi(Application)^.Hard);
             PSapi(Application)^.WScreen^.Ready;
             J:=MessageBox(#3'Program zastaven prikazem STOP !',nil,mfCancelButton);
             Exit;
            end;
         18:Call(Comm);
         19:PSapi(Application)^.WScreen^.Print('"'+Char(Vypocti(Comm))+'"',PSapi(Application)^.Hard);
         20:begin
             J:=Vypocti(Trim(Copy(Comm,1,Pos(',',Comm)-1)));
             if not(J IN [132..134]) then
             J:=MessageBox(#3'Neznam OUT'+Comm+','#13#3'Program zastaven !',nil,mfCancelButton)
             else
             begin
              PSapi(Application)^.AnalOut[J-131]:=Vypocti(Trim(Copy(Comm,Pos(',',Comm)+1,60)));
              LogIn(J,PSapi(Application)^.AnalOut[J-131]);
             end;
            end;
         23:Wait(Comm);
         26:PSapi(Application)^.WScreen^.Tab(Comm);
         27:PSapi(Application)^.WScreen^.Print('"'+Long_Hex(Byte(Vypocti(Comm)),2)+'",',PSapi(Application)^.Hard);
         28:PSapi(Application)^.WScreen^.Print('"'+Long_Hex(Word(Vypocti(Comm)),4)+'",',PSapi(Application)^.Hard);
         29:Let(Comm);
         else
          J:=MessageBox(#3'Tento prikaz neni definovan !'#13#3'Doplneni konzultujte s programatorem !'#13#3+
                          'Program zastaven !',
                        nil,mfCancelButton);
          Exit;
     end;
    PSapi(Application)^.WWatch^.DrawView;
   end;
   if I=-1 then Exit;
   Inc(I);
   FocusItem(I);
   if PSapi(Application)^.IsBreakP(I) then
   begin
    J:=MessageBox(#3'Program zastaven breakpointem !',nil,mfCancelButton);
    Exit;
   end;
   Go:=True;
 end;

procedure TList.LogIn(Co:Byte; Kolik:Integer);
 var H, M, S, Sc:Word;
 begin
  if Sec=0 then
  begin
   Write(Log,'* ');
   if ProgramName<>nil then Write(Log,ProgramName^);
   GetTime( H, M, S, Sc);
   WriteLn(Log,' ', H,':',M,':',S,',',Sc);
   Sec:=Tim;
  end;
  WriteLn(Log, (Tim-Sec)*55,';',Co,';',Kolik);
 end;

const CList: TPalette= #2#1#3#7#6;

function TList.GetPalette:PPalette;
 begin
  GetPalette:=@CList;
 end;

function TList.GetText(Item: Integer; MaxLen: Integer): String;
 var
  PL:PStringCollection;
 begin
  with PSapi(Application)^.List^ do
  if (Count<=Item)or(At(Item)=nil) then GetText:='' else
    if PSapi(Application)^.IsBreakP(Item) then
     GetText:='>'+Copy(PString(At(Item))^,HScrollBar^.Value,MaxLen)
     else GetText:=' '+Copy(PString(At(Item))^,HScrollBar^.Value,MaxLen)
 end;

procedure TList.SelectItem(Item: Integer);
 begin
  PSapi(Application)^.StepLine:=Item;
  PSapi(Application)^.WWatch^.DrawView;
 end;

procedure TScreen.Draw;
 var
  D:array [1..MaxViewWidth*2] of Byte;
  I,Y:Byte;
  S:String;
  Cols:array[0..7] of Byte;
 begin
  Cols[0]:=GetColor(1);
  Cols[2]:=GetColor(2);
  Cols[1]:=Cols[0]+128;
  Cols[3]:=Cols[0];
  Cols[4]:=Cols[0]+1;
  Cols[5]:=Cols[1]+1;
  Cols[6]:=Cols[2]+1;
  Cols[7]:=Cols[3]+1;
  with PSapi(Application)^ do
  for Y:=0 to Size.Y-1 do
  begin
   if (Y+Delta.Y<ScrList^.Count) and (ScrList^.At(Y+Delta.Y)<>nil) then
    S:=PString(ScrList^.At(Y+Delta.Y))^ else S:='';
   MoveChar(D,' ',Cols[0],Size.X);
   I:=1;
   while (I<=Byte(S[0])) and (I<=Size.X*2) do
   begin
    D[I+1]:=Cols[Byte(S[I])];
    D[I]:=Byte(S[I+1]);
    Inc(I,2);
   end;
   TScreen.WriteLine(0,Y,Size.X,1,D);
  end;
 end;

procedure TScreen.Print(S:String;L:Boolean);
 var
  O:PCollection;
  I,T,J:Byte;
  S1:String;
  S2:String;
  Att:Byte;
 begin
  O:=PSapi(Application)^.ScrList;
  if S='' then begin Print('" "',False); Exit; end;
  T:=8;
  I:=1;
  Att:=0;
  S1:='';
  while I<=Byte(S[0]) do
  begin
   case S[I] of
        '"':begin
             while S[I+1]<>'"' do
             begin
              S1:=S1+Char(Att+4*Byte(L))+S[I+1];
              if Att and 3=3 then S1:=S1+Char(3+4*Byte(L))+'ú';
              Inc(I);
             end;
             Inc(I);
            end;
        '#':begin
             T:=0;
             while S[I+1] in ['0'..'9'] do
             begin
              T:=T*10+Byte(S[I+1])-48;
              Inc(I);
             end;
            end;
        '*':begin
             Att:=0;
             while S[I+1] in ['0'..'9'] do
             begin
              Att:=Att*10+Byte(S[I+1])-48;
              Inc(I);
             end;
             Att:=Att and 3;
            end;
        ',',' ':;
        else
           if I<=Byte(S[0]) then
            begin
             if S[I]=',' then Inc(I);
             while S[I+1]=' ' do Inc(I);
             if not (S[I] in ['*','#','"']) then
             begin
              S2:=Long_Str(Vypocti(Copy(S,I,Pos(',',Copy(S,I+1,80)+','))),T);
              Inc(I,Pos(',',Copy(S,I+1,80)+','));
              for J:=1 to Byte(S2[0]) do
              begin
               S1:=S1+Char(Att+4*Byte(L))+S2[J];
               if Att and 3=3 then S1:=S1+Char(3+4*Byte(L))+'ú';
              end;
             end;
            end;
   end;
   Inc(I);
  end;
  if not LF then
  begin
   S1:=PString(O^.At(O^.Count-1))^+S1;
   DisposeStr(PString(O^.At(O^.Count-1)));
   O^.AtDelete(O^.Count-1);
  end;
  while S1<>'' do
  begin
   O^.Insert(NewStr(Copy(S1,1,80)));
   Delete(S1,1,80);
  end;
  while (O^.Count>=MaxCollectionSize-100)or(MemAvail<32000) do
  begin
   O^.AtFree(0);
   VScrollBar^.SetValue(Delta.Y-1);
  end;
  LF:=(S[Byte(S[0])]<>',')or (PString(O^.At(O^.Count-1))^[0]>#79);
  if O^.Count+Byte(LF)-25=delta.y then
  begin
   SetLimit(0,O^.Count+Byte(LF));
   VScrollBar^.SetValue(O^.Count+Byte(LF));
  end;
  DrawView;
  if LF then SetCursor(0,O^.Count-Delta.Y)
   else SetCursor(Byte(PString(O^.At(O^.Count-1))^[0]) div 2,O^.Count-1-Delta.Y);
 end;

procedure TScreen.Cls;
 var
  S:String[80];
  I:Byte;
 begin
  S:='';
  for i:=1 to 40 do S:=S+#0#196;
  PSapi(Application)^.ScrList^.Insert(NewStr(S));
  SetLimit(0,PSapi(Application)^.ScrList^.Count+24);
  ScrollTo(0,PSapi(Application)^.ScrList^.Count+24);
  LF:=True;
  SetCursor(0,PSapi(Application)^.ScrList^.Count-Delta.Y);
  DrawView;
 end;

procedure TScreen.Tab(S:String);
 begin
  Print('"'+Space(Vypocti(S),' ')+'",',False);
 end;

procedure TScreen.Ready;
 begin
  Print('',PSapi(Application)^.Hard);
  Print('"READY"',PSapi(Application)^.Hard);
  Print('">",',PSapi(Application)^.Hard);
  PSapi(Application)^.StepLine:=-1;
  PSapi(Application)^.WList^.Focusitem(0);
  Sec:=0;
 end;

procedure TWatch.Draw;
 var
  I:Byte;
 begin
  DeskTop^.Lock;
  TWindow.Draw;
  with PSapi(Application)^ do
  begin
   TWatch.WriteStr(2,1,'Variables',2);
   for I:=1 to 26 do
   begin
    TWatch.WriteStr(2,I+1,Char(I+64)+' =',2);
    TWatch.WriteStr(5,I+1,Long_Str(Vars[I],6),1);
   end;
   TWatch.WriteStr(19,1,'@(*)',2);
   for I:=0 to 15 do
   begin
    TWatch.WriteStr(13,I+2,Long_Str(I,2)+' =',2);
    TWatch.WriteStr(17,I+2,Long_Str(Pole[I],6),1);
    TWatch.WriteStr(25,I+2,Long_Str(I+16,2)+' =',2);
    TWatch.WriteStr(29,I+2,Long_Str(Pole[I+16],6),1);
   end;
   TWatch.WriteStr(19,19,'Ports',2);
   for I:=1 to 8 do
   begin
    TWatch.WriteStr(9+I*3,21,Long_Str(I,2),1+Byte(I in Ports));
    TWatch.WriteStr(9+I*3,23,Long_Str(I+8,2),1+Byte(I+8 in Ports));
    TWatch.WriteStr(9+I*3,25,Long_Str(I+16,2),1+Byte(I+16 in Ports));
    TWatch.WriteStr(9+I*3,27,Long_Str(I+24,2),1+Byte(I+24 in Ports));
   end;
   TWatch.WriteStr(2,29,'Analog OUT',2);
   for I:=1 to 3 do
   begin
    TWatch.WriteStr(2,29+I*2,Long_Str(I+131,3)+' =',2);
    TWatch.WriteStr(7,29+I*2,Long_Str(AnalOut[I],5),1);
   end;
   TWatch.WriteStr(2,38,'Call''s',2);
   TWatch.WriteStr(2,40,Long_Str(Calls,6),1);
   TWatch.WriteStr(2,42,'Step line',2);
   TWatch.WriteStr(2,44,Long_Str(StepLine,6),1);
   TWatch.WriteStr(19,29,'Analog IN',2);
   for I:=1 to 16 do
   begin
    TWatch.WriteStr(13,I+29,Long_Str(I,2)+' =',2);
    TWatch.WriteStr(17,I+29,Long_Str(AnalIn[I],6),1);
    TWatch.WriteStr(25,I+29,Long_Str(I+16,2)+' =',2);
    TWatch.WriteStr(29,I+29,Long_Str(AnalIn[I+16],6),1);
   end;
  end;
  DeskTop^.UnLock;
 end;

constructor TSapi.Init;
 var
  F:File;
  I:Word;
  Rec:record
     EditName:String[60];
     Lpt,
     Com:Word;
     Wait:Integer;
    end;
 begin
  TApplication.Init;
  Assign(F,Copy(ParamStr(0),1,Pos('.',ParamStr(0)+'.'))+'CFG');
  {$I-}
  Reset(F,SizeOf(Rec));
  {$I+}
  I:=IOResult+1;
  if I=1 then BlockRead(F, Rec, 1,I);
  if I=1 then Close(F);
  if I<>1 then
  begin
   Rec.EditName:='TURBO';
   Rec.LPT:=0;
   Rec.COM:=1;
   Rec.Wait:=100;
  end;
  EditorName:=NewStr(Rec.EditName);
  OutPort:=Rec.Lpt;
  InPort:=Rec.Com;
  WaitSet:=Rec.Wait/100;
  List:=New(PStringCollection, Init(1,1));
  ScrList:=New(PScrList, Init(1,1));
  SetScreenMode(smCO80+smFont8x8);
  Assign(Log,Copy(ParamStr(0),1,Pos('.',ParamStr(0)))+'LOG');
  {$I-}
  Append(Log);
  {$I+}
  if IOResult<>0 then Rewrite(Log);
  Sec:=0;
  InitScr;
  InitWatch;
  InitList;
  ResetSapi;
  StepLine:=0;
 end;

destructor TSapi.Done;
 begin
  Close(Log);
  if List<>nil then Dispose(List,Done);
  if ScrList<>nil then Dispose(ScrList,Done);
  if EditorName<>nil then DisposeStr(EditorName);
  TApplication.Done;
 end;

procedure TSapi.InitMenuBar;
 var
  R:TRect;
 begin
  GetExtent(R);
  R.B.Y:=R.A.Y+1;
  MenuBar:=New(PMenuBar, Init(R,NewMenu(
                                NewItem('~ð~','',kbAltSpace,cmCopyr,hcCopyr,
                                NewSubMenu('~F~ile',hcFile,NewMenu(
                                 NewItem('~L~oad','F3',kbF3,cmLoad,hcLoad,
                                 NewItem('~S~ave','F2',kbF2,cmSave,hcSave,
                                 NewItem('~N~ew','',kbNoKey,cmNew,hcNew,
                                 NewLine(
                                 NewItem('~W~rite to Sapi','',kbNoKey,cmToSapi,hcWrite,
                                 NewItem('~R~ead from Sapi','',kbNoKey,cmFromSapi,hcRead,
                                 NewLine(
                                 NewItem('~G~et info','',kbNoKey,cmInfo,hcInfo,
                                 NewItem('~C~onfigure','',kbNoKey,cmConfig,hcConfig,
                                 NewLine(
                                 NewItem('E~x~it','Alt-X',kbAltX,cmQuit,hcQuit,
                                 nil)))))))))))),
                                NewSubMenu('~E~dit',hcEdit,NewMenu(
                                 NewItem('~N~ew line','Shift-Ins',kbShiftIns,cmNewLine,hcNewLine,
                                 NewItem('~D~elete line','Shift-Del',kbShiftDel,cmDelLine,hcDelLine,
                                 NewLine(
                                 NewItem('Edit ~l~ine','F4',kbF4,cmEditLine,hcEdLine,
                                 NewItem('Edit ~p~rogram','Shift-F4',kbShiftF4,cmEdit,hcEdProg,
                                 nil)))))),
                                 NewSubMenu('~S~earch',hcSearch,NewMenu(
                                  NewItem('~F~ind','Shift-F7',kbShiftF7,cmFind,hcFind,
                                  NewItem('~S~earch again','Ctrl-F7',kbCtrlF7,cmAgain,hcAgain,
                                  NewLine(
                                  NewItem('Search ~l~ine','F7',kbF7,cmSLine,hcSLine,
                                  nil))))),
                                 NewSubMenu('~R~un',hcRun,NewMenu(
                                  NewItem('~R~un','Ctrl-F9',kbCtrlF9,cmRun,hcStart,
                                  NewItem('~S~tep over','F8',kbF8,cmStep,hcStep,
                                  NewItem('~T~oggle breakpoint','Ctrl-F8',kbCtrlF8,cmBreakP,hcBreakP,
                                  NewLine(
                                  NewItem('R~e~set Sapi','Ctrl-F2',kbCtrlF2,cmReset,hcReset,
                                  nil)))))),
                                 NewSubMenu('~D~ebug',hcDebug,NewMenu(
                                  NewItem('~E~valuate...','Ctrl-F4',kbCtrlF4,cmEval,hcEval,
                                  Newitem('~M~odify...','Alt-V',kbAltV,cmModify,hcModif,
                                  NewItem('~A~nalog IN...','Alt-A',kbAltA,cmFillAnal,hcAnalog,
                                  NewItem('~T~erminal...','Alt-T',kbAltT,cmTerminal,hcTerminal,
                                  nil))))),
                                 NewSubMenu('~W~indow',hcWindow,NewMenu(
                                  NewItem('~S~ize/Move','Ctrl-F5',kbCtrlF5,cmReSize,hcSize,
                                  NewItem('~Z~oom','F5',kbF5,cmZoom,hcZoom,
                                  NewItem('~T~ile','',kbNoKey,cmTile,hcTile,
                                  NewItem('~N~ext','F6',kbF6,cmNext,hcNext,
                                  NewItem('~P~revious','Shift-F6',kbShiftF6,cmPrev,hcPrev,
                                  NewLine(
                                  NewItem('~C~lear buffer','',kbNoKey,cmClrScr,hcClear,
                                  nil)))))))),
                                 nil))))))))));
 end;

procedure TSapi.InitStatusLine;
 var R:TRect;
 begin
  GetExtent(R);
  R.A.Y:=R.B.Y-1;
  StatusLine:=New(PMyStLine, Init(R,NewStatusDef(hcDragging,hcDragging,
                                     NewStatusKey('~'#26'~ Move',kbNoKey,0,
                                     NewStatusKey('~Shift-'#26'~ Resize',kbNoKey,0,
                                     NewStatusKey('~Ù~ Done',kbNoKey,0,
                                     NewStatusKey('~Esc~ Cancel',kbNoKey,0,
                                     nil)))),
                                    NewStatusDef(hcRunning,hcRunning,
                                     NewStatusKey('~F9~ Break program',kbNoKey,0,
                                     nil),
                                    NewStatusDef(hcFile,1000+HelpCount,
                                     NewStatusKey('~Esc~ Cancel',kbNoKey,0,
                                     nil),
                                    NewStatusDef($0,$FFFF,
                                     NewStatusKey('~F2~ Save',kbF2,cmSave,
                                     NewStatusKey('~F3~ Load',kbF3,cmLoad,
                                     NewStatusKey('~F4~ Edit line',kbF4,cmEditLine,
                                     NewStatusKey('~F7~ Search',kbF7,cmSLine,
                                     NewStatusKey('~F8~ Step',kbF8,cmStep,
                                     NewStatusKey('~Ctrl-F9~ Run',kbCtrlF9,cmRun,
                                     NewStatusKey('~F10~ Menu',kbF10,cmMenu,
                                     nil))))))),
                                    nil))))));
 end;

procedure TAnalDial.HandleEvent(var Event:TEvent);
 var
  AnalStr:array  [1..32] of String[30];
  J:Byte;
 begin
  TDialog.HandleEvent(Event);
  if (Event.What=evCommand)and(Event.Command=cmCompute) then
  begin
   Getdata(AnalStr);
   for J:=1 to 32 do PSapi(Application)^.AnalIn[J]:=Vypocti(AnalStr[J]);
   PSapi(Application)^.WWatch^.DrawView;
   ClearEvent(Event);
  end;
 end;

procedure TConDlg.HandleEvent(var Event:TEvent);
 begin
  TDialog.HandleEvent(Event);
  if (Event.What=evBroadCast)and(Event.Command=cmScrollBarChanged) then
  begin
   Value:=PScrollBar(Event.InfoPtr)^.Value;
   ReDraw;
   ClearEvent(Event);
  end;
 end;

procedure TWLabel.Draw;
 begin
  WriteStr(0,0,' 0%                           100%',1);
  WriteStr(15,0,Long_Str(PConDlg(Owner)^.Value,3)+'%',19);
 end;

procedure TSapi.HandleEvent(var Event:TEvent);
 var
  I:Integer;
  R:TRect;

 procedure Info;
  const Har:array [Boolean] of String[3]=('Off','On');
  var
   D:PDialog;
   S:String[10];
   S1:String[60];
  begin
   Str(WaitSet:2:3,S);
   R.Assign(20,10,60,30);
   D:=New(PDialog, Init(R,'Information'));
   R.Assign(2,1,22,11);
   if WList^.ProgramName=nil then S1:='No name' else S1:=WList^.ProgramName^;
   D^.Insert(New(PStaticText, Init(R,#13'ÄÄÄÄÄ Program ÄÄÄÄÄ'#13#13+
                                     'Source line : '+Long_Str(List^.Count,5)+#13+
                                     'Screen line : '+Long_Str(ScrList^.Count,5)+#13+
                                     'Step line   : '+Long_Str(StepLine,5)+#13+
                                     'Stack size  : '+Long_Str(15,5)+#13+
                                     'Stack point.: '+Long_Str(Calls,5)+#13+
                                     'Wait index  : '+S)));
   R.Assign(24,1,39,11);
   D^.Insert(New(PStaticText, Init(R,#13'ÄÄÄ Memory ÄÄÄ'#13#13+
                                        'Hard  : '+Har[Hard]+#13+
                                        '@(*)  : '+Long_Str(SizeOf(Pole),6)+#13+
                                        'Free  : '+Long_Str(MemAvail,6)+#13+
                                        'EMS   : Unused')));

   R.Assign(2,13,39,15);
   D^.Insert(New(PStaticText, Init(R,'Program name: '+S1)));
   R.Assign(15,16,25,18);
   D^.Insert(New(PButton, Init(R,'~O~K',cmOk,bfNormal)));
   I:=DeskTop^.ExecView(D);
   Dispose(D,Done);
  end;

 procedure SaveFile;
  var
   S:PathStr;
   D:PFileDialog;
   I:Word;
   S1:String;
  begin
   WScreen^.Print('"SAVE"',Hard);
   D:=New(PFileDialog, Init('*.SPB', 'Ulozeni programu', '~J~meno',
           fdOpenButton or fdHelpButton, 100));
   if Desktop^.ExecView(D)<>cmCancel then
    D^.GetFileName(S) else Exit;
   Dispose(D, Done);
   if Pos('.',S)=0 then S:=S+'.SPB';
   if WList^.ProgramName<>nil then
   begin
    WScreen^.Print('"OLD NAME='+WList^.ProgramName^+'"',Hard);
    WScreen^.Print('"NEW NAME [Y/N]?"',Hard);
    I:=MessageBox('OLD NAME='+WList^.ProgramName^+#13'NEW NAME ?',nil,
        mfYesNoCancel or mfConfirmation);
    case I of
        cmCancel:Exit;
        cmYes:begin DisposeStr(WList^.ProgramName);WList^.ProgramName:=nil; end;
    end;
   end;
   if WList^.ProgramName=nil then
   begin
    S1:='';
    I:=InputBox('Save','~N~ew name: ',S1,60);
    if I=cmOk then WList^.ProgramName:=NewStr(S1);
    WScreen^.Print('"NEW NAME='+S1+'"',Hard);
   end;
   WriteFile(S);
   WScreen^.Ready;
  end;

 procedure LoadFile;
  var
   S:PathStr;
   D:PFileDialog;
   I:Word;
   S1:String;
  begin
   WScreen^.Print('"LOAD"',Hard);
   D:=New(PFileDialog, Init('*.SPB', 'Nacteni programu', '~J~meno',
           fdOpenButton or fdHelpButton, 100));
   if Desktop^.ExecView(D)<>cmCancel then
    D^.GetFileName(S) else Exit;
   Dispose(D, Done);
   if Pos('.',S)=0 then S:=S+'.SPB';
   if List<>nil then Dispose(List,Done);
   List:=New(PStringCollection, Init(1,1));
   WList^.LoadFile(S);
   if WList^.ProgramName<>nil then
     WScreen^.Print('"* '+WList^.ProgramName^+'"',Hard);
   WriteFile('INMEMORY.SPB');
   WScreen^.Ready;
  end;

procedure EditLine;
 var
  S:String;
  Line:String[10];
  I,J:Integer;
 begin
  I:=WList^.VScrollBar^.Value;
  if (I<0)or(I>=List^.Count) then Exit;
  S:=PString(List^.At(I))^;
  Line:=Copy(S,1,Pos(' ',S)-1);
  System.Delete(S,1,Pos(' ',S));
  J:=InputBox('Edit line',Line,S,55);
  if J=cmCancel then Exit;
  S:=Upper(S);
  List^.AtFree(I);
  List^.AtInsert(I,NewStr(Line+' '+S));
  WriteFile('INMEMORY.SPB');
  WList^.DrawView;
 end;

procedure InsertLine;
 var
  S:String;
  Line:String[10];
  I,J:Integer;
  Konec:Boolean;
 begin
  S:='';
  repeat
   J:=InputBox('New line','~L~ine: ',S,60);
   if J=cmCancel then Exit;
   S:=Upper(Trim(S));
   Konec:=(S>'')and(S[1] in Cislice);
   I:=1;
   while (S[I] in Cislice)and(I<=Byte(S[0])) do Inc(I);
   if Copy(S,I,1)<>' ' then System.Insert(' ',S,I);
   while Pos(' ',S)<6 do S:='0'+S;
   Line:=Copy(S,1,Pos(' ',S)-1);
   Val(Line,I,J);
   Konec:=Konec and (J=0);
   Konec:=Konec and not WList^.SearchLine(I);
  until Konec;
  List^.AtInsert(I,NewStr(S));
  WriteFile('INMEMORY.SPB');
  WList^.SetRange(List^.Count);
  WList^.DrawView;
 end;

procedure DeleteLine;
 var
  I,J:Integer;
 begin
  I:=WList^.VScrollBar^.Value;
  if (I<0)or(I>=List^.Count) then Exit;
  J:=MessageBox(#3'Opravdu mam smazat tento radek'#13+PString(List^.At(I))^,
                nil,mfYesNoCancel or mfConfirmation);
  if J<>cmYes then Exit;
  List^.AtFree(I);
  WriteFile('INMEMORY.SPB');
  WList^.SetRange(List^.Count);
  WList^.DrawView;
 end;

 procedure EditProg;
  var
   F:Text;
   S:String;
   I:Integer;
  begin
   if EditorName=nil then
   begin
    I:=MessageBox(#3'Nebyl zadan externi editor !',nil,mfCancelButton);
    Exit;
   end;
   S:=Copy(ParamStr(0),1,Pos('.',ParamStr(0))-1)+'ED.BAT';
   Assign(F,S);
   Rewrite(F);
   WriteLn(F,EditorName^,' INMEMORY.SPB');
   S:=Copy(ParamStr(0),1,Pos('.',ParamStr(0))-1)+'.BAT';
   Write(F,S);
   Close(F);
   Done;
   Halt;
  end;

 procedure SLine;
  var
   I,J:Integer;
   S:String;
  begin
   S:='';
   repeat
    I:=InputBox('Search line','Line number: ',S,6);
    if I=cmCancel then Exit;
    Val(Trim(S),I,J);
   until J=0;
   if WList^.SearchLine(I) then
   begin
    WList^.FocusItem(I);
   end else I:=MessageBox(#3'Line '+S+' not found.',nil,mfCancelButton);
  end;

 procedure FindRec;
  var
   I:Integer;
  begin
   {$V-}
   I:=InputBox('Find','Hledany ~r~etezec: ',FindStr,60);
   {$V+}
   FindStr:=Upper(FindStr);

  end;

 procedure Toggle;
  var
   B, B1:PBreakP;
   I:Word;
  begin
   I:=WList^.VScrollBar^.Value;
   B:=BreakP;
   if (B<>nil)and(B^.Num=I) then
   begin
    B:=BreakP;
    BreakP:=B^.Next;
    Dispose(B);
    WList^.DrawView;
    Exit;
   end;
   if B<>nil then while (B^.Next<>nil) and (B^.Next^.Num<>I) do B:=B^.Next;
   if (BreakP=Nil)or(B^.Next=nil) then
   begin
    if BreakP=Nil then
    begin
     New(BreakP); BreakP^.Num:=I; BreakP^.Next:=Nil;
    end else
    begin
     New(B1);
     B1^.Num:=I;
     B1^.Next:=nil;
     B^.Next:=B1;
    end
   end else
   begin
    B1:=B^.Next;
    B^.Next:=B1^.Next;
    Dispose(B1);
   end;
   WList^.DrawView;
  end;

 procedure FillAnal;
  var
   D:PAnalDial;
   L:PInputLine;
   R:TRect;
   I:Integer;
   B,J:Byte;
  begin
   R.Assign(3,3,55,40);
   D:=New(PAnalDial, Init(R,'Analog input'));
   for J:=1 to 32 do
   begin
    R.Assign(7,J+2,37,J+3);
    L:=New(PInputLine, Init(R,30));
    D^.Insert(L);
    R.Assign(2,J+2,6,J+3);
    D^.Insert(New(PLabel, Init(R,Long_Str(J,2)+':',L)));
   end;
   R.Assign(38,12,50,14);
   D^.Insert(New(PButton, Init(R,'~O~K',cmOk,bfNormal)));
   R.Assign(38,18,50,20);
   D^.Insert(New(PButton, Init(R,'~C~ompute',cmCompute,bfDefault)));
   R.Assign(38,24,50,26);
   D^.Insert(New(PButton, Init(R,'Cancel',cmCancel,bfNormal)));
   D^.SetData(AnalStr);
   repeat
    I:=DeskTop^.ExecView(D);
    if I<>cmCancel then
    begin
     D^.Getdata(AnalStr);
     for J:=1 to 32 do
     begin
      AnalStr[J]:=Upper(AnalStr[J]);
      AnalIn[J]:=Vypocti(AnalStr[J]);
     end;
     WWatch^.DrawView;
    end;
   until I<>cmCompute;
   Dispose(D,Done);
  end;

 procedure GetConfig;
 var
  Rec:record
       EditName:String[60];
       Lpt,
       Com:Word;
       Wait:Integer;
      end;
  R:TRect;
  D:PConDlg;
  Inp:PInputLine;
  I:Integer;
  Butt:PRadioButtons;
  SB:PScrollBar;
  F:File;
 begin
  if EditorName<>nil then Rec.EditName:=EditorName^;
  Rec.Lpt:=OutPort;
  Rec.Com:=InPort;
  Rec.Wait:=Round(WaitSet*100);
  R.Assign(0,0,40,20);
  D:=New(PConDlg, Init(R, 'Configure'));
  D^.Options:= D^.Options or ofCentered;
  D^.EventMask:=D^.EventMask or evBroadCast;
  R.Assign(11,3,37,4);
  Inp:=New(PInputLine, Init(R, 60));
  D^.Insert(Inp);
  R.Assign(2,3,11,4);
  D^.Insert(New(PLabel, Init(R,'~E~ditor: ',Inp)));
  R.Assign(3,7,15,9);
  Butt:=New(PRadioButtons, Init(R, NewSItem('LPT~1~',
                                   NewSItem('LPT~2~',
                                   nil))));
  D^.Insert(Butt);
  R.Assign(3,6,15,7);
  D^.Insert(New(PLabel, Init(R,'O~u~tput port ',Butt)));
  R.Assign(23,7,35,9);
  Butt:=New(PRadioButtons, Init(R, NewSItem('COM~1~',
                                   NewSItem('COM~2~',
                                   nil))));
  D^.Insert(Butt);
  R.Assign(23,6,35,7);
  D^.Insert(New(PLabel, Init(R,'~I~nput port ',Butt)));
  R.Assign(3,12,37,13);
  SB:=New(PScrollBar, Init(R));
  SB^.SetParams(Rec.Wait, 0, 100, 10, 1);
  D^.Value:=Rec.Wait;
  SB^.Options:=SB^.Options or ofSelectable;
  D^.Insert(SB);
  R.Assign(3,11,37,12);
  D^.Insert(New(PLabel, Init(R,'~W~ait state',SB)));
  R.Assign(3,13,37,14);
  D^.Insert(New(PWLabel, Init(R)));
  R.Assign(3,17,13,19);
  D^.Insert(New(PButton, Init(R, '~S~ave',cmYes, bfDefault)));
  R.Assign(15,17,25,19);
  D^.Insert(New(PButton, Init(R, '~O~K',cmOk, bfNormal)));
  R.Assign(27,17,37,19);
  D^.Insert(New(PButton, Init(R, 'Cancel',cmCancel, bfNormal)));
  D^.SetData(Rec);

  I:=DeskTop^.ExecView(D);
  D^.GetData(Rec); Rec.Wait:=D^.Value;
  if I in [cmOk,cmYes] then
  begin
   if EditorName<>nil then DisposeStr(EditorName);
   EditorName:=NewStr(Rec.EditName);
   OutPort:=Rec.Lpt;
   InPort:=Rec.Com;
   WaitSet:=Rec.Wait/100;
   if I=cmYes then
   begin
    Assign(F,Copy(ParamStr(0),1,Pos('.',ParamStr(0)+'.'))+'CFG');
    ReWrite(F,SizeOf(Rec));
    BlockWrite(F, Rec, 1);
    Close(F);
   end
  end;
  Dispose(D,Done);
 end;

 procedure Go;
  var
   Buff:array[Byte] of Char;
   BuffStart,
   BuffEnd:Byte;
   C:Char;
  begin
   BuffStart:=0;
   BuffEnd:=0;
   repeat
    while Port[InPorts[InPort]+5] and 1=1 do
    begin
     Mem[$B800:1984]:=Byte('>');
     Write(Char(Port[InPorts[InPort]]));
    end;
    if KeyPressed then
    begin
     C:=ReadKey;
     if C = #0 then
     begin if ReadKey=#$43 then Exit end
     else
     if BuffEnd+1=BuffStart then
     begin
      Sound(5000);
      Delay(1);
      NoSound;
     end else begin Buff[BuffEnd]:=C;Inc(BuffEnd) end;
    end;
    while (BuffEnd<>BuffStart) and (Port[InPorts[InPort]+5] and 1=0) and (Port[OutPorts[OutPort]+1] and 128<>0) do
    begin
     Mem[$B800:1984]:=Byte('<');
     Port[OutPorts[OutPort]]:=not Byte(Buff[BuffStart]);
     Inc(BuffStart);
     Port[OutPorts[OutPort]+2]:=1;
     Port[OutPorts[OutPort]+2]:=0;
    end;
   until False;
  end;

 procedure Terminal;
  var
   OrigMode:Integer;

  function InitCom:Boolean;
   begin
    InitCom:=False;
    if not Boolean(InPort) then
    begin
     if not SetBaud1(600) then Exit;
     if not SetPar1('N') then Exit;
     if not SetWord1(8) then Exit;
     if not SetStop1(2) then Exit;
    end else
    begin
     if not SetBaud2(600) then Exit;
     if not SetPar2('N') then Exit;
     if not SetWord2(8) then Exit;
     if not SetStop2(2) then Exit;
    end;
    Port[$2FC]:=0;
    InitCom:=True;
   end;

  begin
   TextMode(CO40);
   TextAttr:=42;
   ClrScr;
   TextColor(Yellow);
   TextBackGround(Blue);
   GotoXY(1,25); ClrEol;
   Write(' F9 '); TextColor(White); Write('Close window');
   WriteXY(28,25,'Sapi > PC');
   TextAttr:=42;
   Window(1,1,40,24);
   if InitCom then Go;
   (********************************)
   TextMode(CO80+Font8x8);
   Application^.ReDraw;
   ShowMouse;
  end;

 begin
  TApplication.HandleEvent(Event);
  if Event.What=evCommand then
  begin
   case Event.Command of
        cmConfig:GetConfig;
        cmTile:begin
                R.Assign(0,0,42,26);
                WScreen^.Owner^.Locate(R);
                R.Assign(0,26,42,47);
                WList^.Owner^.Locate(R);
                R.Assign(42,0,79,47);
                WWatch^.Locate(R);
                DrawView;
               end;
        cmCopyr:begin
                 R.Assign(20,10,60,30);
                 I:=MessageBoxRect(R,Copyright,nil,mfOkButton or mfInformation);
                end;
        cmSave:SaveFile;
        cmLoad:LoadFile;
        cmNew:begin
               if List<>nil then Dispose(List,Done);
               List:=New(PStringCollection, Init(1,1));
               if WList^.ProgramName<>nil then DisposeStr(WList^.ProgramName);
               WScreen^.Print('"NEW"',Hard);
               WScreen^.Ready;
               WList^.DrawView;
              end;
        cmToSapi:ToSapi;
        cmFromSapi:FromSapi;
        cmInfo:Info;
        cmNewLine:InsertLine;
        cmDelLine:DeleteLine;
        cmEditLine:EditLine;
        cmEdit:EditProg;
        cmFind:FindRec;
        cmSLine:SLine;
        cmRun:begin
               HelpCtx:=hcRunning;
               StatusLine^.Update;
               if StepLine=-1 then StepLine:=0;
               while WList^.Go(StepLine) do;
               HelpCtx:=hcNoContext;
              end;
        cmStep:begin
                if (StepLine=-1)or(StepLine>=List^.Count) then StepLine:=0;
                if WList^.Go(StepLine) then;
               end;
        cmReset:ResetSapi;
        cmBreakP:Toggle;
        cmFillAnal:FillAnal;
        cmTerminal:Terminal;
        cmClrScr:begin
                  ScrList^.FreeAll;
                  WScreen^.Cls;
                 end;
        else Exit;
   end;
   ClearEvent(Event);
  end;
 end;

procedure TSapi.InitScr;
 var
  I:Byte;
  W:PWindow;
  PS:PScrollBar;
  R:TRect;
 begin
  R.Assign(0,0,42,26);
  W:=New(PWindow, Init(R,'Screen',1));
  W^.Flags:=wfMove;
  PS:=W^.StandardScrollBar(sbHandleKeyboard or sbVertical);
  R.Assign(1,1,41,25);
  WScreen:=New(PScreen, Init(R, nil, PS));
  W^.Insert(WScreen);
  Desktop^.Insert(W);
  WScreen^.ShowCursor;
 end;

procedure TSapi.InitWatch;
 var
  R:TRect;
 begin
  R.Assign(42,0,79,47);
  WWatch:=New(PWatch, Init(R,'Watch',3));
  WWatch^.Flags:=wfMove;
  Desktop^.Insert(WWatch);
 end;

procedure TSapi.InitList;
 var
  W:PWindow;
  R:TRect;
  PH,PV:PScrollBar;
 begin
  R.Assign(0,26,42,47);
  W:=New(PWindow, Init(R,'List',2));
  W^.Flags:=wfMove or wfZoom or wfGrow;
  PH:=W^.StandardScrollBar(sbHorizontal or sbHandleKeyboard);
  PV:=W^.StandardScrollBar(sbVertical or sbHandleKeyboard);
  R.Assign(1,1,41,20);
  PH^.SetRange(1,40);
  WList:=New(PList, Init(R,1,PH,PV));
  WList^.GrowMode:=gfGrowHiX or gfGrowHiY;
  W^.Insert(WList);
  Desktop^.Insert(W);
  if ExFile('INMEMORY.SPB') then WList^.LoadFile('INMEMORY.SPB');
 end;

procedure TSapi.PutChar(C:Char);
  begin
   while port[ OutPorts[OutPort]+1] and 128=0 do;
   port[ OutPorts[OutPort]]:=not Byte(C);
   port[ OutPorts[OutPort]+2]:=1;
   port[ OutPorts[OutPort]+2]:=0;
  end;

procedure TSapi.PutStr(S:String);
  var I:Byte;
  begin
   for I:=1 to Byte(S[0]) do
    PutChar(S[I]);
   PutChar(#13);
  end;

procedure TSapi.ToSapi;

 procedure PutCol(Item:Pointer); far;
  var I:Byte;
  begin
   if Item<>nil then PutStr(PString(Item)^);
  end;

 begin
  PutStr('NEW');
  List^.ForEach(@PutCol);
  PutStr('SAVE');
  if WList^.ProgramName=nil then PutStr('NO NAME') else
   PutStr(WList^.ProgramName^);
  PutStr('LIST');
 end;

function TSapi.GetChar(var C:Char):Boolean;
 begin
   if Port[$2FD] and 1 =1 then
   begin
    C:=Char(Port[$2F8]);
    GetChar:=True;
   end else GetChar:=False;
 end;

function TSapi.GetStr(var S:String):Boolean;
 var
  Ch:Char;
  T1:LongInt;
 begin
  S:='';
  GetStr:=False;
  T1:=Tim;
  repeat
   if GetChar(Ch) then
   begin
    if not(Ch in[#10,#13]) then S:=S+Ch;
    T1:=Tim;
   end else if Tim-T1>=5 then Exit;
  until Ch=#10;
  GetStr:=True;
 end;

procedure TSapi.FromSapi;

 procedure Vloz(S1:String);
  var I:Byte;
  begin
   S1:=Upper(Trim(S1));
   if (S1>'')and(S1[1] in Cislice) then
   begin
    I:=1;
    while (S1[I] in Cislice)and(I<=Byte(S1[0])) do Inc(I);
    if Copy(S1,I,1)<>' ' then System.Insert(' ',S1,I);
    while Pos(' ',S1)<6 do S1:='0'+S1;
    PSapi(Application)^.List^.Insert(NewStr(S1));
   end;
  end;

 var
  S:String;
  Col:PScrList;
  I:Integer;
 begin
  if List<>nil then Dispose(List,Done);
  List:=New(PStringCollection, Init(1,1));
  Col:=New(PScrList, Init(10,5));
  if not Boolean(InPort) then
    begin
     if not SetBaud1(600) then Exit;
     if not SetPar1('N') then Exit;
     if not SetWord1(8) then Exit;
     if not SetStop1(2) then Exit;
    end else
    begin
     if not SetBaud2(600) then Exit;
     if not SetPar2('N') then Exit;
     if not SetWord2(8) then Exit;
     if not SetStop2(2) then Exit;
    end;
  port[$2fc]:=00;
  PutStr('LLIST');
  repeat
   if GetStr(S) then Col^.Insert(NewStr(S));
  until S='';
  port[$2fc]:=02;
  while Col^.Count>0 do
  begin
   Vloz(PString(Col^.At(0))^);
   Col^.AtFree(0);
   Col^.Pack;
  end;
  WList^.SetRange(List^.Count);
  WList^.DrawView;
  Dispose(Col,Done);
  if StepLine>=List^.Count then StepLine:=List^.Count-1;
  if  WList^.ProgramName=nil then S:='' else S:=WList^.ProgramName^;
  I:=InputBox('Read from SAPI','Program name: ',S,60);
  if I=cmOk then
  begin
   if WList^.ProgramName<>nil then DisposeStr(WList^.ProgramName);
   WList^.ProgramName:=NewStr(Upper(S));
  end;
  WriteFile('INMEMORY.SPB');
 end;

procedure TSapi.ResetSapi;
 begin
  Hard:=False;
  Calls:=0;
  WScreen^.Cls;
  WScreen^.Print('*3,"TECHNOMETRA  PRAHA"',False);
  WScreen^.Print('"SAPI BASIC  V T.1 (C) 1991"',False);
  WScreen^.Print('',False);
  if WList^.ProgramName<>nil then
  begin
   WScreen^.Print('"PROGRAM IN MEMORY:"',False);
   WScreen^.Print('"'+WList^.ProgramName^+'"',False);
  end;
  WScreen^.Ready;
 end;

procedure TSapi.Clear;
 begin
  FillChar(Vars,SizeOf(Vars),0);
 end;

procedure TSapi.WriteFile(S:String);
 var
  F:Text;

  procedure WriteItem(Item:Pointer); far;
   begin
    WriteLn(F,PString(Item)^);
   end;

 begin
  Assign(F,S);
  Rewrite(F);
  WriteLn(F,Header);
  if WList^.ProgramName<>nil then WriteLn(F,'* '+WList^.ProgramName^);
  List^.ForEach(@WriteItem);
  Close(F);
 end;

function TSapi.IsBreakP(I:Integer):Boolean;
 var B:PBreakP;
 begin
  B:=BreakP;
  if B=nil then begin IsBreakP:=False; Exit; end;
  if B^.Num=I then begin IsBreakP:=True; Exit; end;
  while (B^.Next<>nil) and (B^.Next^.Num<>I) do B:=B^.Next;
  IsBreakP:=B^.Next<>nil;
 end;

procedure Konec;
 var F:Text;
 begin
  Assign(F,Copy(ParamStr(0),1,Pos('.',ParamStr(0))-1)+'ED.BAT');
  ReWrite(F);
  WriteLn(F,'@ECHO Cinnost softwaroveho emulatoru MIKRO Basicu pro SAPI ukoncena !');
  Close(F);
 end;

var
 Sapi: TSapi;

begin
 Randomize;
 Sapi.Init;
 Sapi.Run;
 Sapi.Done;
 Konec;
end.