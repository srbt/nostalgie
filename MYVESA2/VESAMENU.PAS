unit VesaMenu;

interface

uses MyVesa, Dos_IO, Prevody, VesaApps, VesaInpu;

type TMenuHead=array[1..8] of Char;
const
 Head:TMenuHead='AsMnuF.'#26;
 MenuFrameType:Byte=7;
 MenuSave:Boolean=False;
 MenuQueue:PInputQueue=nil;

type
 PMenuBoxDef=^TMenuBoxDef;
 PMenuItem=^TMenuItem;
 TMenuItem=record
            Key:Word;
            Next:PMenuBoxDef;
            S:String;
           end;

 TMenuBoxDef=record
              XSize,YSize:Byte;
              Item:array [1..25] of PMenuItem;
             end;

 PMenuBarItem=^TMenuBarItem;
 TMenuBarItem=record
               HotKey:Word;
               XPoz:Byte;
               Next:PMenuBoxDef;
               S:String;
              end;

 PMenuBarDef=^TMenuBarDef;
 TMenuBarDef=record
              Head:TMenuHead;
              Loaded:Boolean;
              ItemCount:Byte;
              Item:array [1..25] of PMenuBarItem;
             end;

 PMenuUsedKeys=^TMenuUsedKeys;
 TMenuUsedKeys=record
                Count:Word;
                Key:array [1..1024] of Word;
               end;
type
 PVesaMenuAbs=^TVesaMenuAbs;
 TVesaMenuAbs=object(TTextView)
               HotKeyAttr:Byte;
               Poz:ShortInt;
               function ScanUsedKey(W:Word):Boolean; virtual;
               procedure GoLeft(I:Integer); virtual;
              end;

 PVesaMenuBox=^TVesaMenuBox;
 TVesaMenuBox=object(TVesaMenuAbs)
               Def:PMenuBoxDef;
               Parent:PVesaMenuAbs;
               constructor Init(ADef:PMenuBoxDef; AParent:PVesaMenuAbs);
               procedure Draw; virtual;
               procedure Run(var W:Word); virtual;
               function ScanUsedKey(W:Word):Boolean; virtual;
               procedure GoLeft(I:Integer); virtual;
              end;

 PVesaMenuBar=^TVesaMenuBar;
 TVesaMenuBar=object(TVesaMenuAbs)
               Def:PMenuBarDef;
               UsedKeys:PMenuUsedKeys;
               State:Word;
               constructor Init(ADef:PMenuBarDef; XSize:Byte);
               function LoadMenu(ADef:PMenuBarDef):PMenuBarDef;
               procedure Run(var W:Word); virtual;
               procedure Draw; virtual;
               procedure Select(Sel:Boolean); virtual;
               function ScanUsedKey(W:Word):Boolean; virtual;
               procedure GoLeft(I:Integer); virtual;
              end;

function InitMenuQueue(Next:PInputQueue):PInputQueue;
function NewMenuBoxDef(S:String):PMenuBoxDef;
procedure DisposeMenuBoxDef(var P:PMenuBoxDef);
function ExecMenuBox(X,Y:Word; S:String):Word;

implementation

function ExecMenuBox(X,Y:Word; S:String):Word;
 var
  P2:PVesaMenuBox;
 begin
  New(P2,Init(NewMenuBoxDef(S),nil));
  P2^.MoveTo(X,Y);
  Desktop^.Execute(P2);
  if P2^.ModalResult=kbEsc then ExecMenuBox:=0
                           else ExecMenuBox:=P2^.ModalResult;
  DisposeMenuBoxDef(P2^.Def);
  Dispose(P2,Done);
 end;

function NewMenuBoxDef(S:String):PMenuBoxDef;
 var
  Cnt,Len,I,J:Integer;
  K:Word;
  S2,HK:String[80];
  MD:PMenuBoxDef;
 begin
  Cnt:=1; Len:=0; J:=1;
  for I:=1 to Length(S) do
   if S[I]=',' then
   begin
    Inc(Cnt); Len:=Max(I-J,Len); J:=I+1;
   end;
  Len:=Max(I-J+1,Len);
  GetMem(MD,2+4*Cnt);
  MD^.XSize:=Len; MD^.YSize:=Cnt; HK:='';
  for I:=1 to Cnt do
  begin
   S2:=GetStr(S);
   K:=$FFFF;
   case S2[1] of
        '-':S2[1]:='Ä'; 
        '=':S2[1]:='Í';
         else
          K:=I;
          J:=Pos('~',S2);
          if J=0 then
          begin
           J:=1;
           while Pos(UpCase(S2[J]),HK)>0 do Inc(J);
           if J>Length(S2) then J:=1;
           Insert('~',S2,J);Insert('~',S2,J+2);
          end;
          HK:=HK+UpCase(S2[J+1]);
          S2:=S2+'|';
   end;
   GetMem(MD^.Item[I],2+4+1+Length(S2));
   with MD^.Item[I]^ do
   begin
    Key:=K; S:=S2; Next:=nil;
   end;
  end;
  NewMenuBoxDef:=MD;
 end;

procedure DisposeMenuBoxDef(var P:PMenuBoxDef);
 var I:Integer;
 begin
  for I:=1 to P^.YSize do
  begin
   if P^.Item[I]^.Next<>nil then DisposeMenuBoxDef(P^.Item[I]^.Next);
   FreeMem(P^.Item[I],2+4+Length(P^.Item[I]^.S));
  end;
  FreeMem(P,2+4*P^.YSize); P:=nil;
 end;

function InitMenuQueue(Next:PInputQueue):PInputQueue;
 begin
  New(MenuQueue,Init(Next));
  InitMenuQueue:=MenuQueue;
 end;

function TVesaMenuAbs.ScanUsedKey(W:Word):Boolean;
 begin
 end;

function TVesaMenuBox.ScanUsedKey(W:Word):Boolean;
 begin
  if Parent<>nil then ScanUsedKey:=PVesaMenuAbs(Parent)^.ScanUsedKey(W)
                 else ScanUsedKey:=False;
 end;

procedure TVesaMenuAbs.GoLeft(I:Integer);
 begin
 end;

procedure TVesaMenuBox.GoLeft(I:Integer);
 begin
  if I=-1 then
  begin
   Desktop^.Delete(@Self);
   Desktop^.MakeFocus(Parent);
   if Parent<>nil then Parent^.GoLeft(-1);
   Dispose(PVesaMenuBox(@Self),Done);
  end;
 end;

procedure TVesaMenuBar.GoLeft(I:Integer);
 var
  SubMnu:PVesaMenuBox;
  X:Integer;
 begin
  Dec(Poz,I);
  if Poz<1 then Poz:=Def^.ItemCount else
  if Poz>Def^.ItemCount then Poz:=1;
  with Def^.Item[Poz]^ do
  begin
   New(SubMnu,Init(Next,@Self));
   X:=XPoz-2;
   if X+Next^.XSize>=Columns then X:=Columns-Next^.XSize;
   if X<0 then X:=0;
  end;
  SubMnu^.MoveTo(Origin.X+X*8,Origin.Y+Size.Y);
  Desktop^.Insert(SubMnu);
 end;

function TVesaMenuBar.ScanUsedKey(W:Word):Boolean;
 var I:Word;
 begin
  I:=1;
  ScanUsedKey:=False;
  while (I<=UsedKeys^.Count)and(UsedKeys^.Key[I]<>W) do Inc(I);
  ScanUsedKey:=I<=UsedKeys^.Count;
 end;

constructor TVesaMenuBox.Init(ADef:PMenuBoxDef; AParent:PVesaMenuAbs);
 begin
  TTextView.Init(ADef^.XSize,ADef^.YSize);
  Parent:=AParent;
  Def:=ADef;
  TextAttr:=$70;
  Border:=$07;
  XTextAttr:=$74;
  HotKeyAttr:=$20;
  SetDefaultFrame(MenuFrameType);
  Options:=opSelectable or opModal;
  Poz:=1;
 end;

procedure TVesaMenuBox.Draw;
 var
  I:Byte;
  OT,OX:Byte;
  S2:String[20];
 begin
  ClrScr;
  for I:=1 to Def^.YSize do with Def^.Item[I]^ do
  if Def^.Item[I]^.Key<>$FFFF then
  begin
   WriteXYC(2,I,Copy(S,1,Pos('|',S)-1));
   S2:=Copy(S,Pos('|',S)+1,20);
   WriteXYC(Columns-Byte(S2[0]),I,S2);
  end else WriteXYC(1,I,Space(Columns,S[1]));
  begin
   OT:=TextAttr; OX:=XTextAttr;
   TextAttr:=HotKeyAttr or TextAttr and $0F;
   XTextAttr:=HotKeyAttr or XTextAttr and $0F;
   with Def^.Item[Poz]^ do
    WriteXYC(1,Poz,' '+ReplaceStr(S,'|',Space(Columns-Byte(S[0])+1,' '))+' ');
   TextAttr:=OT; XTextAttr:=OX;
  end;
  TTextView.Draw;
 end;

procedure TVesaMenuBox.Run(var W:Word);
 procedure ExecSubMenu;
  var
   SubMnu:PVesaMenuBox;
  begin
   with Def^.Item[Poz]^ do
   begin
    New(SubMnu,Init(Next,@Self));
   end;
   SubMnu^.MoveTo(Origin.X+8,Origin.Y+Poz*FontDef^.Lines+1);
   Desktop^.Insert(SubMnu);
  end;

 function ScanHot(var S:String):Boolean;
  begin
   ScanHot:=UpCase(Char(W))=UpCase(S[Pos('~',S)+1]);
  end;

 procedure Leave;
  begin
   Desktop^.Delete(@Self);
{   Desktop^.MakeFocus(Parent); }
   case W of
    kbLeft:Parent^.GoLeft(1);
    kbRight:Parent^.GoLeft(-1);
   end;
   Dispose(PVesaMenuBox(@Self),Done);
  end;

 var I:Byte;
 begin
   if ScanUsedKey(W) then Exit;
   case W of
        kbUp:begin
                repeat
                 if Poz>1 then Dec(Poz) else Poz:=Def^.YSize;
                until Def^.Item[Poz]^.Key<>$FFFF;
                Desktop^.RedrawView(@Self);
               end;
       kbDown:begin
                repeat
                 if Poz<Def^.YSize then Inc(Poz) else Poz:=1;
                until Def^.Item[Poz]^.Key<>$FFFF;
                Desktop^.RedrawView(@Self);
               end;
       kbLeft:if Parent<>nil then Leave;
       kbEsc:if Parent<>nil then Leave else ModalResult:=kbEsc;
       kbEnter,
       kbRight:begin
                if Def^.Item[Poz]^.Next<>nil then ExecSubMenu else
                begin
                 if W=kbEnter then
                 begin
                  W:=Def^.Item[Poz]^.Key;
                  ModalResult:=W;
                  MenuQueue^.PutEvent(W);
                  W:=0;
                 end else if Parent<>nil then Leave;
                end;
               end;
       else
        if Char(W)>#2 then
        begin
         I:=Poz;
         repeat
          if I<Def^.YSize then Inc(I) else I:=1;
         until ScanHot(Def^.Item[I]^.S) or (I=Poz);
         Poz:=I;
         Desktop^.RedrawView(@Self);
        end;
   end;
 end;

constructor TVesaMenuBar.Init(ADef:PMenuBarDef; XSize:Byte);
 begin
  TTextView.Init(XSize,1);
  Def:=LoadMenu(ADef);
  TextAttr:=$70;
  Border:=$07;
  XTextAttr:=$74;
  HotKeyAttr:=$20;
  SetDefaultFrame(MenuFrameType);
  Options:=opModal;
  Poz:=1;
  State:=0;
 end;

procedure TVesaMenuBar.Draw;
 var
  I:Byte;
  OT,OX:Byte;
 begin
  ClrScr;
  for I:=1 to Def^.ItemCount do with Def^.Item[I]^ do WriteXYC(XPoz,1,S);
  if State>0 then
  begin
   OT:=TextAttr; OX:=XTextAttr;
   TextAttr:=HotKeyAttr or TextAttr and $0F;
   XTextAttr:=HotKeyAttr or XTextAttr and $0F;
   with Def^.Item[Poz]^ do WriteXYC(XPoz-1,1,' '+S+' ');
   TextAttr:=OT; XTextAttr:=OX;
  end;
  TTextView.Draw;
 end;

procedure TVesaMenuBar.Run(var W:Word);
 function ScanHot(var S:String):Boolean;
  begin
   ScanHot:=UpCase(Char(W))=UpCase(S[Pos('~',S)+1]);
  end;
 var
  I:Byte;
 begin
  if not Selected then
  begin
   if W=kbF10 then
   begin
    Options:=Options or opSelectable;
    Desktop^.MakeFocus(@Self);
   end else
   begin
    I:=1;
    while (I<=Def^.ItemCount)and(Def^.Item[I]^.HotKey<>W) do Inc(I);
    if I<=Def^.ItemCount then
    begin
     Poz:=I;
     Options:=Options or opSelectable;
     Desktop^.MakeFocus(@Self);
     GoLeft(0);
    end;
   end;
  end else
  case W of
       kbLeft:GoLeft(1);
       kbRight:GoLeft(-1);
       kbEnter:GoLeft(0);
       kbEsc:begin
              State:=0;
              Options:=Options and not opSelectable;
{              Desktop^.DrawView(View);}
              Desktop^.SelectPrev;
             end;
       else
        if Char(W)>#2 then
        begin
         I:=Poz;
         repeat
          if I<Def^.ItemCount then Inc(I) else I:=1;
         until ScanHot(Def^.Item[I]^.S) or (I=Poz);
         Poz:=I;
         Desktop^.RedrawView(@Self);
        end;
  end;
 end;

procedure TVesaMenuBar.Select(Sel:Boolean);
 begin
  if Sel then State:=1;
  TTextView.Select(Sel);
 end;

procedure IncPtr(var P:Pointer; Delta:Word); assembler;
 asm
  LES DI,P
  MOV AX,Delta
  ADD [ES:DI],AX
 end;

function TVesaMenuBar.LoadMenu(ADef:PMenuBarDef):PMenuBarDef;
 var
  I:Byte;
  P:Pointer;
  It:Pointer;
 procedure GetMenuBox;
  var
   J:Word;
   It:PMenuBoxDef;
  begin
   It:=P;
   IncPtr(P,2+It^.YSize*4);
   for J:=1 to It^.YSize do
   begin
    It^.Item[J]:=P;
    IncPtr(P,7+Byte(It^.Item[J]^.S[0]));
    if It^.Item[J]^.Next<>nil then
    begin
     It^.Item[J]^.Next:=P;
     GetMenuBox;
    end;
   end;
  end;

 procedure GetMenuBarItem;
  begin
   It:=P;
   IncPtr(P,8+Byte(PMenuBarItem(It)^.S[0]));
   if PMenuBarItem(It)^.Next<>nil then
   begin
    PMenuBarItem(It)^.Next:=P;
    GetMenuBox;
   end;
  end;
 begin
  if ADef^.Head<>Head then begin LoadMenu:=nil; Exit; end;
  LoadMenu:=ADef;
  if ADef^.Loaded then Exit;
  ADef^.Loaded:=True;
  P:=ADef; IncPtr(P,ADef^.ItemCount*4+10);
  for I:=1 to ADef^.ItemCount do
  begin
   ADef^.Item[I]:=P;
   GetMenuBarItem;
  end;
  UsedKeys:=P;
 end;
end.