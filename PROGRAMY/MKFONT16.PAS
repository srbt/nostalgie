uses App, Views, Objects, MSGBox, StdDlg, Drivers,
     Prevody, Menus, Graph, Dos, Crt, Header;
const
 cmSave=1000;
 cmNew=cmSave+1;
 cmLoad=cmNew+1;
 cmPreview=cmLoad+1;
 cmExport=cmPreview+1;

type
 TSet_Char=set of 0..7;
 TCurrChar=array [1..16] of TSet_Char;
 TCurrFont=array [Byte] of TCurrChar;
 PMkFont=^TMkFont;
 TMkFont=object(TWindow)
          CurrChar:Byte;
          Sel:TPoint;
          Len:TPoint;
          procedure HandleEvent(var Event:TEvent); virtual;
          procedure Draw; virtual;
         end;

 PMkApp=^TMkApp;
 TMkApp=object(TApplication)
         FontWin:PMkFont;
         constructor Init;
         destructor Done; virtual;
         procedure InitStatusLine; virtual;
         procedure InitMenuBar; virtual;
         procedure HandleEvent(var Event:TEvent); virtual;
         procedure NewFont;
         procedure SaveFont;
         procedure LoadFont(S:String);
         procedure Export;
         procedure Preview;
         function NewTitle(S:String):PString;
         function GetFileName(Sav:Boolean):String;
        end;
var
 Font:TCurrFont;
 Saved:Boolean;
 FileName:PString;
 SFlag:Byte absolute 0:$0417;
 Clipb:TCurrChar;

procedure TMkFont.HandleEvent(var Event:TEvent);
 const kbSpace=$3920;
 var
  MPos:TPoint;
 begin
  TWindow.HandleEvent(Event);
  with Event do
   case What of
        evKeyBoard:case KeyCode of
                         kbUp:if SFlag and 3<>0 then
                               begin
                                if Len.Y>2 then Dec(Len.Y);
                               end else if Sel.Y>1 then Dec(Sel.Y);
                       kbDown:if SFlag and 3<>0 then
                               begin
                                if Len.Y<16 then Inc(Len.Y);
                               end else if Sel.Y<Len.Y then Inc(Sel.Y);
                       kbLeft:if SFlag and 3<>0 then
                               begin
                                if Len.X>2 then Dec(Len.X);
                               end else if Sel.X>1 then Dec(Sel.X);
                      kbRight:if SFlag and 3<>0 then
                               begin
                                if Len.X<8 then Inc(Len.X);
                               end else if Sel.X<Len.X then Inc(Sel.X);
                       kbHome:begin Sel.X:=1; Sel.Y:=1; end;
                       kbEnd:Sel:=Len;
                      kbEnter,
                      kbSpace:begin
                               Saved:=False;
                               if (8-Sel.X) in Font[CurrChar][Sel.Y] then
                                Font[CurrChar][Sel.Y]:=Font[CurrChar][Sel.Y]-[8-Sel.X] else
                                Font[CurrChar][Sel.Y]:=Font[CurrChar][Sel.Y]+[8-Sel.X];
                              end;
                      kbPgUp:Dec(CurrChar);
                      kbPgDn:Inc(CurrChar);
                      else
                       if CharCode<>#0 then CurrChar:=Byte(CharCode)
                       else Exit
                   end;
        evMouseDown:begin
                     MakeLocal(Event.Where,MPos);
                     if MPos.X in [3..18] then Sel.X:=(MPos.X-1) div 2;
                     if MPos.Y in [2..17] then Sel.Y:=MPos.Y-1;
                     if Double then
                     begin
                      Saved:=False;
                      if (8-Sel.X) in Font[CurrChar][Sel.Y] then
                       Font[CurrChar][Sel.Y]:=Font[CurrChar][Sel.Y]-[8-Sel.X] else
                       Font[CurrChar][Sel.Y]:=Font[CurrChar][Sel.Y]+[8-Sel.X];
                     end;
                    end;
   else
    Exit
   end;
  DrawView;
  ClearEvent(Event);
 end;

procedure TMkFont.Draw;
 const Fill:array [Boolean] of String[2] = ('  ','°°');
 var
  X,Y:Byte;
 begin
  DeskTop^.Lock;
  TWindow.Draw;
  WriteStr(2,1,'ÚÂÄÂÄÂÄÂÄÂÄÂÄÂÄÂÄ¿',1);
  WriteStr(Sel.X*2+1,1,'ÂÄ',2);
  for Y:=1 to 16 do
  begin
   WriteStr(2,Y+1,'Ã',1+Byte(Sel.Y=Y));
   WriteStr(19,Y+1,'´',1+Byte(Sel.Y=Y));
   for X:=1 to 8 do WriteStr(X*2+1,Y+1,Fill[(8-X) in Font[CurrChar][Y]],
                             2+Byte((Sel.X=X)and(Sel.Y=Y))*2);
  end;
  WriteStr(2,18,'ÀÁÄÁÄÁÄÁÄÁÄÁÄÁÄÁÄÙ',1);
  WriteStr(Sel.X*2+1,18,'ÁÄ',2);
  if Len.Y<16 then WriteStr(19,Len.Y+1,'´',6);
  if Len.X<8 then WriteStr(Len.X*2+1,18,'Á',6);
  if not Saved then WriteStr(3,19,'',2);
  WriteStr(7,19,'"'+Char(CurrChar)+'"=('+Long_Str(CurrChar,3)+')',2);
  DeskTop^.UnLock;
 end;

constructor TMkApp.Init;
 var R:TRect;
 begin
  TApplication.Init;
  Saved:=True;
  R.Assign(0,0,22,20);
  FileName:=NewStr('NONAME.FNT');
  FontWin:=New(PMkFont, Init(R,FileName^,0));
  FontWin^.Flags:=wfMove;
  FontWin^.Options:=ofCentered or FontWin^.Options;
  FontWin^.CurrChar:=65;
  FontWin^.Sel.X:=1;
  FontWin^.Sel.Y:=1;
  FontWin^.Len.X:=8;
  FontWin^.Len.Y:=16;
  DisableCommands([cmPaste]);
  Desktop^.Insert(FontWin);
  if ParamCount>0 then LoadFont(AddExt(ParamStr(1),'FNT')) else NewFont;
  FontWin^.Frame^.DrawView;
  FontWin^.DrawView;
 end;

destructor TMkApp.Done;
 begin
  NewFont;
  TApplication.Done;
 end;

procedure TMkApp.InitStatusLine;
 var
  R:TRect;
 begin
  GetExtent(R);
  R.A.Y:=R.B.Y-1;
  StatusLine:=New(PStatusLine, Init(R, NewStatusDef(0,$FFFF,
                                       NewStatusKey('~F2~ Save',kbF2,cmSave,
                                       NewStatusKey('~F3~ Load',kbF3,cmLoad,
                                       NewStatusKey('~F4~ New',kbF4,cmNew,
                                       NewStatusKey('~F5~ Copy',kbF5,cmCopy,
                                       NewStatusKey('~F6~ Paste',kbF6,cmPaste,
                                       NewStatusKey('~F7~ Export',kbF7,cmExport,
                                       NewStatusKey('~Ctrl-PrtSc~ Preview',kbCtrlPrtSc,cmPreview,
                                       NewStatusKey('~Alt-X~ Exit',kbAltX,cmQuit,
                                       nil)))))))),
                                      nil)));
 end;

procedure TMkApp.InitMenuBar;
 var R:TRect;
 begin
  GetExtent(R);
  R.B.Y:=R.A.Y+1;
  MenuBar:=New(PMenuBar,Init(R,NewMenu(NewItem('E~x~it','',kbAltX,cmQuit,hcNoContext,nil))));
 end;

procedure TMkApp.HandleEvent(var Event:TEvent);
 begin
  TApplication.HandleEvent(Event);
  if Event.What=evCommand then
   case Event.Command of
        cmSave:SaveFont;
        cmLoad:LoadFont('');
        cmNew :NewFont;
        cmPreview:Preview;
        cmCopy:begin
                Clipb:=Font[FontWin^.CurrChar];
                EnableCommands([cmPaste]);
               end;
        cmPaste:Font[FontWin^.CurrChar]:=Clipb;
        cmExport:Export;
        else Exit;
   end else Exit;
  FontWin^.Frame^.DrawView;
  FontWin^.DrawView;
  ClearEvent(Event);
 end;

procedure TMkApp.NewFont;
 var I:Integer;
 begin
  if not Saved then
  begin
   I:=MessageBox(#3'Znakova sada nebyla ulozena.  Ulozit ?',nil,
                  mfYesNoCancel or mfConfirmation);
   case I of
       cmCancel:Exit;
       cmYes:SaveFont;
   end;
  end;
  FillChar(Font, SizeOf(Font), 0);
  if FontWin^.Title<>nil then DisposeStr(FontWin^.Title);
  FontWin^.Title:=NewStr('NONAME.FNT');
  FileName:=NewStr('NONAME.FNT');
  FontWin^.DrawView;
 end;

function TMkApp.GetFileName(Sav:Boolean):String;
 const Name:array [Boolean] of String[20] = ('Load','Save');
 var
  D:PFileDialog;
  I:Integer;
  S:String;
 begin
  D:=New(PFileDialog,
     Init('*.FNT',Name[Sav]+' font file','Jmeno souboru:',fdOpenButton+2*Byte(Sav),100));
  I:=Desktop^.ExecView(D);
  if I=cmCancel then GetFileName:='' else
  begin
   D^.GetData(S);
   GetFileName:=S;
  end;
  Dispose(D, Done);
 end;

procedure TMkApp.SaveFont;
 var
  F:File of TCurrFont;
  S:String;
 begin
  if FileName^='NONAME.FNT' then
  begin
   S:=GetFileName(True);
   if S='' then Exit;
   DisposeStr(FileName);
   FileName:=NewStr(S);
  end;
  Assign(F,FileName^);
  {$I-};
  Reset(F);
  {$I+};
  if IOResult=0 then
   if MessageBox('Soubor '+FileName^+' existuje ! Prepsat ?',
       nil,mfYesNoCancel or mfConfirmation)<>cmYes then
       begin Close(F); Exit; end;
  Rewrite(F);
  Write(F,Font);
  Close(F);
  if FontWin^.Title<>nil then DisposeStr(FontWin^.Title);
  FontWin^.Title:=NewTitle(FileName^);
  Saved:=True;
 end;

procedure TMkApp.LoadFont(S:String);
 var
  F:File of TCurrFont;
 begin
  NewFont;
  if S='' then S:=GetFileName(False);
  if S='' then Exit;
  DisposeStr(FileName);
  FileName:=NewStr(S);
  Assign(F,S);
  {$I-} Reset(F); {$I+}
  if IOResult<>0 then
  begin
   if MessageBox('Soubor '+FileName^+' nenalezen !',nil,mfCancelButton)=0 then;
   Exit;
  end;
  Read(F,Font);
  Close(F);
  if FontWin^.Title<>nil then DisposeStr(FontWin^.Title);
  FontWin^.Title:=NewTitle(FileName^);
  Saved:=True;
 end;

procedure TMkApp.Preview;
 var
  X,Y:Byte;
  I,
  grDriver,
  grMode,
  ErrCode:Integer;
  PathBGI:String;
 begin
  HideMouse;
  grDriver:=VGA;
  grMode:=VGAMed;
  PathBGI:=GetEnv('BGIPATH');
  if PathBGI='' then PathBGI:='L:\TP\BGI';
  InitGraph(grDriver, grMode, PathBGI);
  if GraphResult<>grOk then
  begin
   grDriver:=HercMono;
   grMode:=HercMonoHi;
   InitGraph(grDriver, grMode, PathBGI);
   ErrCode:=GraphResult;
   if ErrCode<>grOk then
   begin
    grMode:=MessageBox(GraphErrorMsg(ErrCode),nil,mfCancelButton);
    ShowMouse;
    Exit;
   end;
  end;
  Bar(0,0,32*8+1,129);
  for I:=0 to 255 do
   for Y:=0 to FontWin^.Len.Y-1 do
    for X:=0 to FontWin^.Len.X-1 do
     PutPixel((I mod 32)*FontWin^.Len.X+FontWin^.Len.X-X,(I div 32)*FontWin^.Len.Y+Y+1,
              ((I and 1)+9)*Byte(X in Font[I][Y+1]));
  OutTextXY(20,150,'Press <ENTER> for continue ...');
  while ReadKey<>^M do;
  CloseGraph;
  ShowMouse;
  ReDraw;
 end;

function TMkApp.NewTitle(S:String):PString;
 begin
 while Pos('\',S)>0 do System.Delete(S,1,1);
 NewTitle:=NewStr(S);
 end;

procedure TMkApp.Export;
 var
  Exp:Text;
  I,J:Byte;
 begin
  Assign(Exp,Copy(FileName^,1,Pos('.',FileName^+'.')-1)+'.EXP');
  ReWrite(Exp);
  WriteLn(Exp,'   { Soubor EGA/VGA fontu 8*16 ve formatu PAS}');
  for I:=0 to 255 do
  begin
   Write(Exp,I:3,':=');
   for J:=1 to 16 do Write(Exp,'#',Byte(Font[I][J]));
   WriteLn(Exp,';');
  end;
  Close(Exp);
 end;

var
 MkApp:TMkApp;

const
 cHelpTxt='Syntaxe MKFONT16 [filespec[.FNT]'^M^J' Program vytvari typy pisma pro narodni abecedy'+
         ' o rozmerech 8x16 bodu.'^Z;
 sHelpTxt:array [1..Length(cHelpTxt)] of Char = cHelpTxt;

begin
 Head:='Universal country utilities (MKFONT16)  Version 1.0  ARNAY Software';
 HelpTXT:=@sHelpTxt;
 WriteHead(heHalt);
 MkApp.Init;
 MkApp.Run;
 MkApp.Done;
end.