unit VesaApps;

interface

uses MyVesa, BMPLib, Dos_IO, Prevody, VesaInpu;

type
 PViewRec=^TViewRec;
 TViewRec=record
           View:PVesaView;
           Next:PViewRec;
           Prev:PViewRec;
          end;

 PDesktop=^TDesktop;
 TDesktop=object(TVesaView)
           Menu:PVesaView;
           FocusView:PViewRec;
           SelectedView:PViewRec;
           DeskView:PBMPStream;
           SystemTop:TTextView;
           Counter:Word;
           MaxCounter:Word;
           constructor Init(BMPName:String);
           procedure Draw; virtual;
           procedure Run(var W:Word); virtual;
           procedure Insert(View:PVesaView);
           procedure Delete(View:PVesaView);
           procedure SelectView(View:PViewRec);
           procedure RedrawView(View:PVesaView);
           procedure SelectNext;
           procedure SelectPrev;
           procedure MakeFocus(View:PVesaView);
           procedure MainLoop;
           procedure HandleMessage;
           procedure Execute(View:PVesaView);
           destructor Done; virtual;
          end;

const
 AutoselectFocus:Boolean=True;
 AutofocusSelected:Boolean=True;
var
 Desktop:PDesktop;
 VInput :PInputQueue;

procedure InitVesaAppsQueue(Q:PInputQueue);

implementation

procedure InitVesaAppsQueue(Q:PInputQueue);
 begin
  VInput:=New(PKeyboardQueue,Init(Q));
 end;

constructor TDesktop.Init(BMPName:String);
 begin
  TVesaView.Init;
  Size.X:=GetMaxX; Size.Y:=GetMaxY;
  Menu:=nil;
  FocusView:=nil;
  SelectedView:=nil;
  if BMPName<>'' then
  begin
   New(DeskView,Init(BMPName));
   if DeskView^.BMPError<>0 then begin Dispose(DeskView,Done); DeskView:=nil; end
                            else DeskView^.LoadAll;
  end else DeskView:=nil;
  SystemTop.Init(7,1);
  SystemTop.MoveTo(0,-2);
  Counter:=0;
  MaxCounter:=0;
 end;

procedure TDesktop.Draw; 
 var
  X,Y:Word;
  Tmp:PViewRec;
 begin
  if DeskView=nil then ClearVesa
  else
   for X:=0 to Size.X div DeskView^.Size.X do
    for Y:=0 to Size.Y div DeskView^.Size.Y do
    begin
     DeskView^.MoveTo(X*DeskView^.Size.X,Y*DeskView^.Size.Y);
     if ViewIsIn(DeskView) then DeskView^.Draw;
    end;
  if Menu<>nil then Menu^.DrawAll;
  if FocusView<>nil then
  begin
   Tmp:=FocusView;
   repeat
    Tmp:=Tmp^.Next;
    if ViewIsIn(Tmp^.View) then Tmp^.View^.DrawAll;
   until Tmp=FocusView;
  end;
 end;

procedure TDesktop.RedrawView(View:PVesaView);
 var
  Tmp:PViewRec;
  Wn,Wx:TPoint;
 begin
  if View=nil then Exit;
  if FocusView=nil then begin View^.DrawAll; Exit; end;
  Tmp:=FocusView^.Prev;
  while (Tmp^.View<>View)and(Tmp<>FocusView) do Tmp:=Tmp^.Prev;
  Wn:=WindMin; Wx:=WindMax;
  WindMin:=View^.Origin; WindMax:=WindMin; Inc(WindMax.X,View^.Size.X-1);Inc(WindMax.Y,View^.Size.Y-1);
  View^.DrawAll;
  while Tmp<>FocusView do
  begin
   Tmp:=Tmp^.Next;
   if ViewIsIn(Tmp^.View) then
    Tmp^.View^.DrawAll;
  end;
  WindMin:=Wn; WindMax:=Wx;
 end;

procedure TDesktop.SelectView(View:PViewRec);
 begin
  if SelectedView<>nil then SelectedView^.View^.Select(False);
  SelectedView:=View;
  if SelectedView<>nil then SelectedView^.View^.Select(True);
  if AutofocusSelected and (FocusView<>SelectedView) then MakeFocus(SelectedView^.View);
 end;

procedure TDesktop.SelectPrev;
 var Tmp:PViewRec;
 begin
  if SelectedView=nil then Exit;
  Tmp:=SelectedView^.Prev;
  while (Tmp<>nil)and(Tmp<>SelectedView)and
        ((Tmp^.View^.Options and opSelectable=0)or
         (Tmp^.View^.Options and opHidden<>0)) do Tmp:=Tmp^.Prev;
  if AutofocusSelected then FocusView:=Tmp;
  if (Tmp<>nil)and
     (Tmp^.View^.Options and opSelectable<>0)and
     (Tmp^.View^.Options and opHidden=0) then SelectView(Tmp);
 end;

procedure TDesktop.SelectNext;
 var Tmp:PViewRec;
 begin
  if SelectedView=nil then Exit;
  Tmp:=SelectedView^.Next;
  while (Tmp<>nil)and(Tmp<>SelectedView)and
        ((Tmp^.View^.Options and opSelectable=0)or
         (Tmp^.View^.Options and opHidden<>0)) do Tmp:=Tmp^.Next;
  if (Tmp<>nil)and
     (Tmp^.View^.Options and opSelectable<>0)and
     (Tmp^.View^.Options and opHidden=0) then SelectView(Tmp);
 end;

procedure TDesktop.Run(var W:Word);
 var Tmp:PViewRec;
 begin
  Inc(Counter);
{  if Counter>MaxCounter then MaxCounter:=Counter;
  SystemTop.WriteXY(1,1,Long_Str(Counter,3)+':'+Long_Str(MaxCounter,3));
  SystemTop.Draw;}
  if Byte(W) in [1,2] then
  begin
   if FocusView<>nil then
   begin
    Tmp:=FocusView;
    repeat
     if (Tmp^.View^.Valid(W)) then Tmp^.View^.Run(W);
     Tmp:=Tmp^.Next;
    until (Tmp=FocusView)or(FocusView=nil);
   end;
  end else
  begin
   if (SelectedView^.View^.Options and opModal)=0 then
   begin
    if Menu<>nil then Menu^.Run(W);
    case Word(W) of
         kbTab:begin SelectNext; Dec(Counter); Exit; end;
    kbShiftTab:begin SelectPrev; Dec(Counter); Exit; end;
    end;
   end;
   if SelectedView<>nil then
    if SelectedView^.View^.Valid(W) then SelectedView^.View^.Run(W);
  end;
  Dec(Counter);
 end;

procedure TDesktop.MainLoop;
 var W:Word;
 begin
{  Draw;}
  ModalResult:=0;
  repeat
   W:=VInput^.GetEvent;
{   if W<>0 then
    WriteLn(Long_Hex(W,4));}
   Run(W);
  until ModalResult<>0;
 end;

procedure TDesktop.HandleMessage;
 var W:Word;
 begin
   W:=VInput^.GetEvent;
   Run(W);
 end;

procedure TDesktop.Insert(View:PVesaView);
 var Tmp:PViewRec;
 begin
  if View=nil then Exit;
  View^.Owner:=@Self;
  New(Tmp);
  Tmp^.View:=View;
  if FocusView=nil then
  begin
   FocusView:=Tmp; Tmp^.Next:=Tmp; Tmp^.Prev:=Tmp;
  end else
  begin
   Tmp^.Prev:=FocusView; Tmp^.Next:=FocusView^.Next; FocusView^.Next:=Tmp;
   Tmp^.Next^.Prev:=Tmp;
  end;
  if (View^.Options and opSelectable)<>0 then SelectView(Tmp);
  RedrawView(View);
{  with View^ do Desktop^.DrawRect(Origin.X,Origin.Y,Origin.X+Size.X-1,Origin.Y+Size.Y-1);}
 end;

procedure TDesktop.Delete(View:PVesaView);
 var Tmp:PViewRec;
 begin
  if (SelectedView<>nil)and(SelectedView^.View=View) then SelectedView:=nil;
  if FocusView<>nil then
  begin
   if FocusView^.View=View then
    if FocusView^.Next=FocusView then FocusView:=nil else
    begin
     FocusView^.Prev^.Next:=FocusView^.Next;
     FocusView^.Next^.Prev:=FocusView^.Prev;
     Tmp:=FocusView;
     FocusView:=FocusView^.Prev;
     Dispose(Tmp);
    end else
   begin
    Tmp:=FocusView;
    while (Tmp^.View<>View)and(Tmp^.Next<>FocusView) do Tmp:=Tmp^.Next;
    if Tmp^.View=View then
    begin
     Tmp^.Prev^.Next:=Tmp^.Next;
     Tmp^.Next^.Prev:=Tmp^.Prev;
     Dispose(Tmp);
    end;
   end;
   if FocusView<>nil then
   begin
    Tmp:=FocusView;
    while (Tmp^.View^.Options and opSelectable=0)and(Tmp^.Next<>FocusView) do Tmp:=Tmp^.Next;
    if Tmp^.View^.Options and opSelectable<>0 then SelectView(Tmp);
   end;
  end;
  View^.Owner:=nil;
  with View^ do Desktop^.DrawRect(Origin.X,Origin.Y,Origin.X+Size.X-1,Origin.Y+Size.Y-1);
 end;

procedure TDesktop.MakeFocus(View:PVesaView);
 var Tmp:PViewRec;
 begin
  Tmp:=FocusView^.Next;
  while (Tmp<>FocusView)and(Tmp^.View<>View) do Tmp:=Tmp^.Next;
  if Tmp<>FocusView then
  begin
   Tmp^.Prev^.Next:=Tmp^.Next; Tmp^.Next^.Prev:=Tmp^.Prev;
   Tmp^.Prev:=FocusView; Tmp^.Next:=FocusView^.Next;
   FocusView^.Next:=Tmp; Tmp^.Next^.Prev:=Tmp;
   FocusView:=Tmp;
  end;
  if AutoSelectFocus and (Tmp^.View^.Options and opSelectable<>0) then SelectView(Tmp);
 end;

procedure TDesktop.Execute(View:PVesaView);
 var
  OldOpt:Word;
 begin
  if View=nil then Exit;
  OldOpt:=View^.Options;
  View^.Options:=View^.Options or opDialog;
  ModalResult:=0;
  View^.ModalResult:=0;
  Insert(View);
  repeat
   HandleMessage;
  until (View^.ModalResult<>0)or(ModalResult<>0);
  Delete(View);
  View^.Options:=OldOpt;
 end;

destructor TDesktop.Done;
 var
  Tmp,Tmp2:PViewRec;
 begin
  SystemTop.Done;
  if DeskView<>nil then Dispose(DeskView,Done);
  if FocusView<>nil then
  begin
   Tmp:=FocusView; Tmp^.Prev^.Next:=nil;
   repeat
    Tmp2:=Tmp;
    Tmp:=Tmp^.Next;
    Dispose(Tmp2^.View,Done);
    Dispose(Tmp2);
   until Tmp=nil;
  end;
 end;

end.