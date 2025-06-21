unit VesaDraw;

interface

uses MyVesa;

const
 LastVesaDrawItem=15;
 White=$FFFFFFFF;
 Black=$00000000;
 DefaultColor=White;
type
 PVesaDrawItems=^TVesaDrawItems;
 PVesaDrawItem=^TVesaDrawItem;

 TVesaDrawItem=record
                case Typ:Byte of
                     1,                             {MoveTo}
                     2,                             {LineTo}
                     5:(X,Y:Integer);               {Ellipse}
                     3:(Col:TRGBPixel);             {SetColor}
                     4:(Next:PVesaDrawItems);       {Continue}
               end;

 TVesaDrawItems=array [0..LastVesaDrawItem] of TVesaDrawItem;

 PVesaDraw=^TVesaDraw;
 TVesaDraw=object(TVesaView)
            Items:PVesaDrawItems;
            XPoz,YPoz:Integer;
            Color:TRGBPixel;
            constructor Init;
            function GetFreeItem:PVesaDrawItem;
            procedure RawLineTo(X2,Y2:Integer);
            procedure RawPutPixel(X2,Y2:Integer);
            procedure XORRawLineTo(X,Y:Integer);
            procedure RawEllipse(XRad,YRad:Integer);
            procedure GotoXY(X1,Y1:Integer);
            procedure LineTo(X1,Y1:Integer);
            procedure SetColorRGB(Col1:LongInt);
            procedure Ellipse(X1,Y1:Integer);
            procedure Draw; virtual;
            procedure DrawAll; virtual;
            procedure RawClearDevice;
            destructor Done; virtual;
           end;

 PVesaFont=^TVesaFont;
 TVesaFont=object
            Height:Byte;
            procedure SetTextHeight(ASize:Byte);
            procedure OutText(Draw:PVesaDraw; S:String); virtual;
            function TextWidth(S:String):Word; virtual;
            function TextHeight(S:String):Word; virtual;
            destructor Done; virtual;
           end;

 PBGIFontHeader=^TBGIFontHeader;
 TBGIFontHeader=record
                 Sign:Char;
                 Count:Word;
                 Reserved:Byte;
                 First:Char;
                 Offs:Word;
                 ScanFlag:Byte;
                 Top, Base, Bottom:ShortInt;
                 Undefined:array [1..5] of Byte;
                 CharOffs:array [#0..#255] of Word;
                end;

 PCharWidth=^TCharWidth;
 TCharWidth=array [#0..#255] of Byte;

 PVesaBGIFont=^TVesaBGIFont;
 TVesaBGIFont=object(TVesaFont)
            HeadSize:Word;
            Header:PBGIFontHeader;
            CharWidth:PCharWidth;
            constructor Init(FName:String);
            procedure OutText(Draw:PVesaDraw; S:String); virtual;
            function TextWidth(S:String):Word; virtual;
            function TextHeight(S:String):Word; virtual;
            destructor Done; virtual;
           end;

implementation

var
 SinTab:array [1..80] of Integer;

constructor TVesaBGIFont.Init(FName:String);
 var F:File; OFM:Integer;
 begin
  Assign(F,FName);
  {$I-} OFM:=FileMode; FileMode:=0; Reset(F,1); FileMode:=OFM; {$I+}
  if IOResult<>0 then
  begin Header:=nil; Exit; end;
  HeadSize:=FileSize(F)-$80;
  GetMem(Header,HeadSize);
  Seek(F,$80);
  BlockRead(F,Header^,HeadSize);
  Close(F);
  CharWidth:=@Header^.CharOffs;
  Inc(LongInt(CharWidth),Header^.Count shl 1);
  SetTextHeight(Header^.Top-Header^.Bottom);
 end;

procedure TVesaBGIFont.OutText(Draw:PVesaDraw; S:String);

 function ToShort(A:Byte):ShortInt; assembler;
  asm
   MOV AL,A
   AND AL,$7F
   MOV AH,AL
   SHL AH,1
   AND AH,$80
   OR AL,AH
  end;

 type
  PCharDef=^TCharDef;
  TCharDef=record
            case Boolean of
             False:(X,Y:Byte);
             True:(W:Word);
           end;
 var
  OXPoz,OYPoz, XP:Integer;
  PC:PCharDef;
  I:Byte;
  C:Char;
  H:Byte;
 begin
  if Header=nil then Exit;
  OXPoz:=Draw^.XPoz;
  OYPoz:=Draw^.YPoz;
  with Header^, Draw^ do
  begin
   H:=Top-Bottom;
   for I:=1 to Byte(S[0]) do
   begin
    XP:=XPoz;
    Dec(S[I],Byte(First));
    PC:=@Header^;
    Inc(LongInt(PC),Offs+CharOffs[S[I]]);
    while (PC^.W and $8080)<>0 do
    begin
     with PC^ do
     case (W and $8080) of
          $0080:begin XPoz:=XP+ToShort(X)*Height div H; YPoz:=OYPoz+(Top-ToShort(Y))*Height div H; end;
          $8080:RawLineTo(XP+ToShort(X)*Height div H,OYPoz+(Top-ToShort(Y))*Height div H);
     end;
     Inc(PC);
    end;
    XPoz:=XP+CharWidth^[S[I]]*Height div H;
   end;
   XPoz:=OXPoz;
   YPoz:=OYPoz;
  end;
 end;

function TVesaBGIFont.TextWidth(S:String):Word;
 var
  X:Byte;
  XP:LongInt;
  H:Byte;
 begin
  XP:=0;
  H:=Header^.Top-Header^.Bottom;
  for X:=1 to Byte(S[0]) do Inc(XP,CharWidth^[Char(Byte(S[X])-Byte(Header^.First))]);
  TextWidth:=XP*Height div H;
 end;

function TVesaBGIFont.TextHeight(S:String):Word;
 begin
  TextHeight:=Height;
 end;

destructor TVesaBGIFont.Done;
 begin
  if Header<>nil then FreeMem(Header,HeadSize);
  TVesaFont.Done;
 end;

procedure TVesaFont.OutText(Draw:PVesaDraw; S:String);
 begin
 end;

function TVesaFont.TextWidth(S:String):Word;
 begin
  TextWidth:=0;
 end;

procedure TVesaFont.SetTextHeight(ASize:Byte);
 begin
  Height:=ASize;
 end;

function TVesaFont.TextHeight(S:String):Word;
 begin
  TextHeight:=0;
 end;

destructor TVesaFont.Done;
 begin
 end;

constructor TVesaDraw.Init;
 begin
  TVesaView.Init;
  XPoz:=0; YPoz:=0; FillRGBPixel(DefaultColor,Color); Items:=nil;
 end;

 function Sgn(X:Integer):Integer; assembler;
  asm
   MOV AX,X
   CMP AX,0
   JZ @Konec
   JG @Vetsi
   MOV AX,-1
   JMP @Konec
  @Vetsi:
   MOV AX,1
  @Konec:
  end;


{procedure TVesaDraw.RawLineTo(X,Y:Integer);
 var
  M,N,I,S,D1x,D1y,D2x,D2y,A,B:Integer;
 begin
  A:=XPoz; B:=YPoz;
  Dec(X,A); Dec(Y,B);
  Inc(A,Origin.X); Inc(B,Origin.Y);
  D1X:=Sgn(X); D1Y:=Sgn(Y);
  D2X:=D1X;    D2Y:=0;
  M:=Abs(X);   N:=Abs(Y);
  if M<=N then
  begin
   D2X:=0; D2Y:=D1Y;
   N:=M;   M:=Abs(Y);
  end;
  S:=M shr 1;
  for I:=1 to M do
  begin
   PutPixelRGB(A,B,Color);
   Inc(S,N);
   if S<M then begin Inc(A,D2X); Inc(B,D2Y); end
          else begin Dec(S,M); Inc(A,D1X); Inc(B,D1Y); end;
  end;
  Dec(A,Origin.X); Dec(B,Origin.Y);
  XPoz:=A; YPoz:=B;
 end;}

procedure TVesaDraw.RawLineTo(X2,Y2:Integer);
 var P,Dx,Dy,AIncr,BIncr,XIncr,YIncr,MX,MY,X1,Y1,X,Y:Integer;

 procedure SwapInt(var I1,I2:Integer); assembler;
  asm
   MOV BX,DS
   LDS SI,I1
   MOV DI,word ptr I2
   MOV AX,[SI]
   XCHG AX,[DI]
   MOV [SI],AX
   MOV DS,BX
  end;

 begin
  X1:=XPoz+Origin.X; Y1:=YPoz+Origin.Y;
  XPoz:=X2; YPoz:=Y2;
  Inc(X2,Origin.X); Inc(Y2,Origin.Y);
  if Abs(X2-X1)<Abs(Y2-Y1) then
  begin
   if Y1>Y2 then
   begin
    SwapInt(X1,X2);
    SwapInt(Y1,Y2);
   end;
   if X2>X1 then XIncr:=1 else XIncr:=-1;
   DY:=Y2-Y1; DX:=abs(X2-X1);
   P:=2*DX-DY;
   AIncr:= 2*(DX-DY); BIncr:=2*DX;
   X:=X1; Y:=Y1;
   PutPixelRGB(X,Y,Color);
   for Y:=Y1+1 to Y2 do
   begin
    if P>=0 then begin Inc(X,XIncr); Inc(P,AIncr); end
            else Inc(P,BIncr);
    PutPixelRGB(X,Y,Color);
   end;
  end else
  begin
   if X1>X2 then
   begin
    SwapInt(X1,X2);
    SwapInt(Y1,Y2);
   end;
   if Y2>Y1 then YIncr:=1 else YIncr:=-1;
   DX:=X2-X1; DY:=abs(Y2-Y1);
   P:=2*DY-DX;
   AIncr:=2*(DY-DX); BIncr:=2*DY;
   X:=X1; Y:=Y1;
   PutPixelRGB(X,Y,Color);
   for X:=X1+1 to X2 do
   begin
    if P>=0 then begin Inc(Y,YIncr); Inc(P,AIncr); end
            else Inc(P,BIncr);
    PutPixelRGB(X,Y,Color);
   end;
  end;
 end;

procedure TVesaDraw.RawPutPixel(X2,Y2:Integer);
 begin
   XPoz:=X2; YPoz:=Y2;
   PutPixelRGB(Origin.X+X2,Origin.Y+Y2,Color);
 end;

procedure TVesaDraw.XORRawLineTo(X,Y:Integer);
 var
  M,N,I,S,D1x,D1y,D2x,D2y,A,B:Integer;
 begin
  A:=XPoz; B:=YPoz;
  Dec(X,A); Dec(Y,B);
  Inc(A,Origin.X); Inc(B,Origin.Y);
  D1X:=Sgn(X); D1Y:=Sgn(Y);
  D2X:=D1X;    D2Y:=0;
  M:=Abs(X);   N:=Abs(Y);
  if M<=N then
  begin
   D2X:=0; D2Y:=D1Y;
   N:=M;   M:=Abs(Y);
  end;
  S:=M shr 1;
  for I:=1 to M do
  begin
   XORPutPixelRGB(A,B,Color);
   Inc(S,N);
   if S<M then begin Inc(A,D2X); Inc(B,D2Y); end
          else begin Dec(S,M); Inc(A,D1X); Inc(B,D1Y); end;
  end;
  Dec(A,Origin.X); Dec(B,Origin.Y);
  XPoz:=A; YPoz:=B;
 end;

procedure TVesaDraw.RawEllipse(XRad,YRad:Integer);
 var
  OX,OY:Integer;
  I:Byte;
 begin
  OX:=XPoz; OY:=YPoz;
  Inc(XPoz,XRad);
  for I:=1 to 64 do
   RawLineTo(((LongInt(SinTab[I+16])*XRad) shr 15)+OX,((LongInt(SinTab[I])*YRad) shr 15)+OY);
  XPoz:=OX; YPoz:=OY;
 end;

procedure TVesaDraw.Draw;

 procedure DrawItems(Items:PVesaDrawItems);
  var
   I:Byte;
  begin
   if Items=nil then Exit;
   for I:=0 to LastVesaDrawItem do
   begin
    with PVesaDrawItem(Items)^ do
    case Typ of
         0:Exit;
         1:begin XPoz:=X; YPoz:=Y; end;
         2:RawLineTo(X,Y);
         3:Color:=Col;
         4:DrawItems(Next);
         5:RawEllipse(X,Y);
    end;
    Inc(PVesaDrawItem(Items));
   end;
  end;

 begin
  DrawItems(Items);
 end;

procedure TVesaDraw.DrawAll;
 begin
  Draw;
 end;

function TVesaDraw.GetFreeItem:PVesaDrawItem;
 var
  Tmp,Tmp2:PVesaDrawItems;
  I:Byte;
 begin
  if Items=nil then
  begin
   New(Items); FillChar(Items^,SizeOf(Items^),0);
   GetFreeItem:=PVesaDrawItem(Items); Exit;
  end;
  Tmp:=Items;
  while (Tmp^[LastVesaDrawItem].Typ=4) do Tmp:=Tmp^[LastVesaDrawItem].Next;
  I:=LastVesaDrawItem;
  while Tmp^[I].Typ=0 do Dec(I);
  Inc(I);
  if I>LastVesaDrawItem then
  begin
   New(Tmp2); FillChar(Tmp2^,SizeOf(Tmp2^),0); Tmp2^[0]:=Tmp^[LastVesaDrawItem];
   with Tmp^[LastVesaDrawItem] do begin Typ:=4; Next:=Tmp2; end; Tmp:=Tmp2; I:=1;
  end;
  Inc(PVesaDrawItem(Tmp),I);
  GetFreeItem:=PVesaDrawItem(Tmp);
 end;

procedure TVesaDraw.GotoXY(X1,Y1:Integer);
 var
  P:PVesaDrawItem;
 begin
  P:=GetFreeItem;
  with P^ do begin Typ:=1; X:=X1; Y:=Y1; end;
 end;

procedure TVesaDraw.LineTo(X1,Y1:Integer);
 var
  P:PVesaDrawItem;
 begin
  P:=GetFreeItem;
  with P^ do begin Typ:=2; X:=X1; Y:=Y1; end;
 end;

procedure TVesaDraw.Ellipse(X1,Y1:Integer);
 var
  P:PVesaDrawItem;
 begin
  P:=GetFreeItem;
  with P^ do begin Typ:=5; X:=X1; Y:=Y1; end;
 end;

procedure TVesaDraw.SetColorRGB(Col1:LongInt);
 var
  P:PVesaDrawItem;
 begin
  P:=GetFreeItem;
  with P^ do begin Typ:=3; FillRGBPixel(Col1,Col); end;
 end;

destructor TVesaDraw.Done;
 begin
 end;

procedure TVesaDraw.RawClearDevice;
 var
  Buf:PFBuff;
  Y:Word;
 begin
  GetMem(Buf,Size.X*3);
  FillChar(Buf^,Size.X*3,$00);
  for Y:=0 to Size.Y-1 do PutLineRGB(Origin.X,Origin.Y+Y,Size.X-1,Buf^);
  FreeMem(Buf,Size.X*3);
 end;

var
 X:Byte;
begin
  for X:=1 to 80 do SinTab[X]:=Round(Sin(X/64*2*PI)*MaxInt);
end.