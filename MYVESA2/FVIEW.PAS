unit FView;

interface

uses MyVesa, Prevody, Dos_IO;


type
 PFileBuff=^TFileBuff;
 TFileBuff=array [0..4095] of Char;
 PFileView=^TFileView;
 TFileView=object(TTextView)
            Buff:PFileBuff;
            Poz:Word;
            Len:Word;
            constructor Init(AC,AL:Byte; FName:String);
            procedure Run(var W:Word); virtual;
            procedure Draw; virtual;
            destructor Done; virtual;
           end;

implementation

constructor TFileView.Init(AC,AL:Byte; FName:String);
 var
  F:File; FM:Integer;
 begin
  TTextView.Init(AC,AL);
  Assign(F,FName);
  FM:=FileMode; FileMode:=0;
  {$I-} Reset(F,1); {$I+} FileMode:=FM;
  Buff:=nil; Poz:=0; Len:=0;
  if IOResult<>0 then Exit;
  Len:=WMin(FileSize(F),65535);
  GetMem(Buff,Len);
  BlockRead(F,Buff^,Len);
  Close(F);
 end;

procedure TFileView.Run(var W:Word);
 procedure LineUp;
  begin
   if Poz>0 then
           begin
            Dec(Poz);
            while (Buff^[Poz-1]<>^J)and(Poz>0) do Dec(Poz);
           end;
  end;
 procedure LineDown;
  begin
   if (Poz<Len)and(Buff<>nil) then
           begin
            repeat
             Inc(Poz);
            until (Buff^[Poz]=^J)or(Poz=Len);
            if Poz<Len then Inc(Poz);
           end;
  end;

 var
  I:Byte;

 procedure PageUp;
  var I:Byte;
  begin
   for I:=1 to Lines do LineUp;
  end;
 begin
  case W of
      kbEnter,
      kbEsc:ModalResult:=W;
      kbUp:LineUp;
      kbDown:LineDown;
      kbPGUp:PageUp;
      kbPgDn:for I:=1 to Lines do LineDown;
      kbHome:Poz:=0;
      kbEnd:begin Poz:=Len; PageUp; end;
           else TTextView.Run(W); Exit;
  end;
  W:=kbNoKey;
  Draw;
 end;

procedure TFileView.Draw;
 var
  Curr:Word;
  X,Y:Byte;
  C:^Char;
 begin
  ClrScr;
  if Buff<>nil then
  begin
   X:=1; Y:=1; Curr:=Poz; C:=@Buff^[Curr];
   while (Curr<Len)and(Y<=Lines) do
   begin
    case C^ of
         ^H:if X>1 then Dec(X);
         ^M:X:=1;
         ^J:Inc(Y);
         else PutCharXY(X,Y,C^); Inc(X);
    end;
    Inc(C); Inc(Curr);
   end;
  end;
  TTextView.Draw;
 end;

destructor TFileView.Done;
 begin
  if Buff<>nil then FreeMem(Buff,Len);
  TTextView.Done;
 end;
end.