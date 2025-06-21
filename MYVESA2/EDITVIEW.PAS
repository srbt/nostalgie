unit EditView;

interface

uses MyVesa, Dos_IO, Prevody, VesaApps;

type
 PEditView=^TEditView;
 TEditView=object(TTextView)
            S:String;
            Poz:Byte;
            YPoz,XPoz:Byte;
            Start:Boolean;
            constructor Init(AC,AL:Byte);
            procedure SetData(var Data; Len:Word); virtual;
            procedure GetData(var Data; Len:Word); virtual;
            procedure Run(var W:Word); virtual;
           end;

 PPasswordView=^TPasswordView;
 TPasswordView=object(TEditView)
                procedure Draw; virtual;
               end;

 PMessageBox=^TMessageBox;
 TMessageBox=object(TTextView)
              AllowedChars:String;
              constructor Init(S,C:String);
              procedure Run(var W:Word); virtual;
             end;

function MessageBox(S,C:String):Char;
function InputBox(Title:String;var S:String):Boolean;
function PasswdInputBox(Title:String;var S:String):Boolean;

implementation


constructor TEditView.Init(AC,AL:Byte);
 begin
  TTextView.Init(AC,AL);
  YPoz:=1; XPoz:=1; S:='';
 end;

procedure TEditView.SetData(var Data; Len:Word);
 begin
  Move(Data,S[1],Len); S[0]:=Char(Len);
  while (S[Byte(S[0])]<=#32)and(S>'') do Dec(S[0]);
  ClrEol(XPoz,YPoz);
  WriteXY(XPoz,YPoz,S);
  Cursor.X:=Byte(S[0])+XPoz; Cursor.Y:=YPoz;
  Start:=True;
 end;

procedure TEditView.GetData(var Data; Len:Word);
 begin
  Move(S[1],Data,Min(Byte(S[0]),Len));
 end;

procedure TEditView.Run(var W:Word);
 begin
  with Cursor do
  begin
   case W of
      kbHome:X:=XPoz;
      kbEnd:X:=Byte(S[0])+XPoz;
      kbLeft:if X>1 then Dec(X);
      kbRight:if X<Min(Byte(S[0]),Columns-1)+XPoz then Inc(X);
      kbDel:Delete(S,X,1);
      kbBack:if X>XPoz then
             begin
              Delete(S,X-XPoz,1);
              Dec(X);
             end;
      kbEnter,
      kbEsc:ModalResult:=W;
      else if (Byte(W)>=32)and(Byte(S[0])<Columns) then
            begin
             if Start=True then begin S:=''; X:=XPoz; end;
             Insert(Char(W),S,X-XPoz+1);
             if X+XPoz<=Columns then Inc(X);
            end else if Char(W)=^Y then begin S:=''; X:=XPoz; end else Exit;
   end;
  end;
  if W<>0 then Start:=False;
  ClrEol(XPoz,YPoz);
  WriteXY(XPoz,YPoz,S);
  Draw;
 end;

procedure TPasswordView.Draw;
 var
  S1:String;
 begin
  S1:=S; FillChar(S1[1],Byte(S1[0]),'*');
  WriteXY(XPoz,YPoz,S1);
  TEditView.Draw;
 end;

constructor TMessageBox.Init(S,C:String);
 var
  Y,J,K,L:Word;
 begin
  S:=S+^M; K:=4; L:=4;
  J:=2; Y:=1; while Y<=Byte(S[0]) do
  begin
   if S[Y]=^M then begin Inc(J); L:=Max(L,K); K:=4; end;
   Inc(Y); Inc(K);
  end;
  TTextView.Init(L,J);
  Border:=$7; TextAttr:=$70; XTextAttr:=$7E;
  ClrScr; Center;
  Y:=2;
  while S<>'' do
  begin
   J:=Pos(^M,S); WriteXYC(3,Y,Copy(S,1,J-1));
   Delete(S,1,J);
   Inc(Y);
  end;
  AllowedChars:=C;
 end;

procedure TMessageBox.Run(var W:Word);
 begin
  if Pos(Char(W),AllowedChars)>0 then ModalResult:=W;
 end;

function MessageBox(S,C:String):Char;
 var
  Txt:TMessageBox;
 begin
  Txt.Init(S,C);
  Desktop^.Execute(@Txt);
  MessageBox:=Char(Txt.ModalResult);
  Txt.Done;
 end;

function InputBox(Title:String;var S:String):Boolean;
 var
  T:TEditView;
 begin
  T.Init(40,2);
  T.Center; T.TextAttr:=$70; T.Border:=7; T.ClrScr;
  T.WriteXY(1,1,Title);
  T.YPoz:=2;
  T.SetData(S[1],Byte(S[0]));
  Desktop^.Execute(@T);
  if T.ModalResult<>kbEsc then begin S:=T.S; InputBox:=True; end
                          else InputBox:=False;
  T.Done;
 end;

function PasswdInputBox(Title:String;var S:String):Boolean;
 var
  T:TPasswordView;
 begin
  T.Init(40,2);
  T.Center; T.TextAttr:=$70; T.Border:=7; T.ClrScr;
  T.WriteXY(1,1,Title);
  T.YPoz:=2;
  T.SetData(S[1],Byte(S[0]));
  Desktop^.Execute(@T);
  if T.ModalResult<>kbEsc then begin S:=T.S; PasswdInputBox:=True; end
                          else PasswdInputBox:=False;
  T.Done;
 end;

end.