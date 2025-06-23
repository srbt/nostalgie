{ Udelat:
  Ukonceni programu na Ctrl-Alt-Del,
  Alt-X - pouze prechod do zamknuti/cekani na prihlaseni
  }
{
  Pri zmene fokusu preskupovat okna tak, aby se po ukonceni modalniho
  dostalo na vrch to, ktere modalni okno vyvolalo
  }
uses MyVesa, VesaApps, Prevody, VesaMenu, EditView, Dos_IO;
 procedure NewMenu(FName:String);
 const
  MenuSize:Word=0;
  Buff:Pointer=nil;
 var
  F:File;
 begin
  Assign(F,FName);
  Reset(F,1);
  with PVesaMenuBar(Desktop^.Menu)^ do
  begin
   if MenuSize<>0 then FreeMem(Buff,MenuSize);
   MenuSize:=FileSize(F);
   GetMem(Buff,MenuSize);
   BlockRead(F,Buff^,MenuSize);
   Close(F);
   Def:=LoadMenu(Buff);
   Draw;
  end;
 end;

type
    PMyD=^TMyD;
    TMyD=object(TDesktop)
          procedure Run(var W:Word); virtual;
         end;
 PWindowList=^TWindowList;
 TWindowList=object(TTextView)
              procedure Run(var W:Word); virtual;
             end;

procedure TWindowList.Run(var W:Word);
 begin
  case W of
     kbEnter,kbEsc:ModalResult:=W;
  end;
 end;

procedure TMyD.Run(var W:Word);
 procedure WindowList;
  var
   P:PWindowList;
   V:PViewRec;
   Count:Word;
  begin
   V:=Desktop^.FocusView;
   if V=nil then Exit;
   V:=V^.Next; Count:=1;
   while V<>Desktop^.FocusView do begin Inc(Count); V:=V^.Next; end;
   New(P,Init(18,Count));
   Count:=1;
   repeat
    V:=V^.Next;
    P^.TextAttr:=PTextView(V^.View)^.TextAttr;
    P^.WriteXY(1,Count,'('+Long_Str(V^.View^.Origin.X,3)+
                       ','+Long_Str(V^.View^.Origin.Y,3)+
                      ')('+Long_Str(V^.View^.Origin.X+V^.View^.Size.X-1,3)+
                       ','+Long_Str(V^.View^.Origin.Y+V^.View^.Size.Y-1,3)+')');
    Inc(Count);
   until V=Desktop^.FocusView;
   Desktop^.Execute(P);
   Dispose(P,Done);
  end;
 begin
  TDesktop.Run(W);
  case W of
    kbAltX:ModalResult:=W;
    kbCtrlF3:WindowList;
  end;
 end;

var
 P:array [1..10] of PTextView;
 I:Word;
 S:String;
 X,Y:Word;
begin
 InitVesaGraph(800,600,16);
 InitVesaAppsQueue(InitMenuQueue(nil));
 Desktop:=New(PMyD,Init('W_005.BMP')); {W_005.BMP}
 Desktop^.Menu:=New(PVesaMenuBar,Init(nil,800 div 8 - 2));
 NewMenu('Manual.MNO');
 Desktop^.Insert(Desktop^.Menu);
 for I:=1 to 10 do
 begin
  P[I]:=New(PTextView,Init(10,10));
  P[I]^.MoveTo(I*20,I*20);
  P[I]^.Options:=opSelectable or opSelFrame;
  Desktop^.Insert(P[I]);
 end;
 Desktop^.Draw;
 if MessageBox('Pokusny ~text~: Blabla bla bla blaaa !'^M'Stisknete Enter !',^M^[)=^M then Write(^G);
 S:='text k zadani';
 if InputBox('Zadejte neco: ',S) then P[1]^.WriteXY(1,1,S);
 Desktop^.MainLoop;
 Dispose(Desktop,Done);
 S:='ABCDEFGHIJKLMNO';
 for Y:=0 to GetMaxY do
  for X:=0 to GetMaxX-10 do
   PutLineRGB(X,Y,5,S[1]);
 CloseVesaGraph;
end.