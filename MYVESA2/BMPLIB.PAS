unit BmpLib;

interface

uses MyVesa, XMSApi, Prevody, Dos_IO;
type
 TBMPFHeader=record
              Typ:array [1..2] of Char;
              FSize:LongInt;
              Reserved:LongInt;
              OffBits:LongInt;
              hSize:LongInt;
              Width,Height:LongInt;
              Planes:Word;
              Bits:Word;
              Compress:LongInt;
              SizeImage,XPelsPerMetr,YPelsPerMetr,ClrUsed,
              ClrImportant:LongInt;
             end;

type
 PBMPStream=^TBMPStream;
 TBMPStream=object(TVesaView)
             FIn:File;
             Header:TBMPFHeader;
             FLSize:Word;
             XMSPtr:TXMSPointer;
             XMSFull:Boolean;
             FBuff:PFBuff;
             BMPError:Integer;
             Palette:P8BitPalette;
             constructor Init(Name:String);
             procedure Draw; virtual;
             procedure DrawAll; virtual;
             procedure LoadAll;
             procedure ReadLine;
             procedure ResetStream;
             destructor Done; virtual;
             procedure Run(var W:Word); virtual;
            end;

const
 UseXMS:Boolean=True;
 BMPLibErrorCon:PTextView=nil;

implementation

procedure WriteError(Msg:String);
 begin
  if BMPLibErrorCon<>nil then
  with BMPLibErrorCon^ do begin ClrScr; WriteXY(1,1,Msg); Draw; end;
 end;

constructor TBMPStream.Init(Name:String);
 var
  OFM:Word;
 begin
  TVesaView.Init;
  Palette:=nil;
  BMPError:=1;
  Assign(FIn,Name);
  FillChar(XMSPtr,SizeOf(XMSPtr),0);
  OFM:=FileMode;
  {$I-} FileMode:=0; Reset(FIn,1); FileMode:=OFM;
  if IOResult<>0 then begin WriteError('Vstupni soubor nelze otevrit !'); Exit; end;
  BlockRead(FIn,Header,SizeOf(Header)); {$I+}
  if IOResult<>0 then begin WriteError('Nelze nacist hlavicku bitmapy !'); Exit; end;
  with Header do
  begin
   if (Typ<>'BM')or(IOResult<>0) then WriteError('Vstupni soubor neni ve formatu BMP !') else
   if Planes<>1 then WriteError('Obraz ma vice jak jednu bitovou rovinu !') else
   if (Bits<>24)and(Bits<>8)and(Bits<>1) then WriteError('Umim zpracovavat pouze 24,8 a 1-bitove obrazy !') else
   if Width>21000 then WriteError('Umim zpracovavat pouze obrazy do sire 21000 bodu !') else
   if Compress<>0 then WriteError('Umim zpracovavat pouze nekomprimovane obrazy') else
   begin
    if Bits=1 then
    begin
     GetMem(Palette,SizeOf(Palette^[0])*2);
     {$I-} BlockRead(FIn,Palette^,SizeOf(Palette^[0])*2); {$I+}
     if IOResult<>0 then
     begin FreeMem(Palette,SizeOf(Palette^[0])*2); WriteError('Nelze nacist palety barev !'); Exit; end;
    end else
    if Bits=8 then
    begin
     New(Palette);
     {$I-} BlockRead(FIn,Palette^,SizeOf(Palette^)); {$I+}
     if IOResult<>0 then
     begin Dispose(Palette); WriteError('Nelze nacist palety barev !'); Exit; end;
    end;
    BMPError:=0;
    FLSize:=(Width*3+3) and not 3;
    FillChar(Origin,SizeOf(Origin),0);
    FillChar(Delta,SizeOf(Delta),0);
    Size.X:=Min(Width,GetMaxX+1);
    Size.Y:=Min(Height,GetMaxY+1);
    XMSFull:=False;
    if UseXMS then
    begin
     if Header.Bits=1 then XMSPtr.Handle:=XMSGetMem((((Header.Width+7) div 8+3) and not 3*Height) div 1024+1)
                      else XMSPtr.Handle:=XMSGetMem((FLSize*Height) div 1024+1);
     if XMSErr<>xmOk then XMSPtr.Handle:=0;
    end;
   end;
  end;
  if BMPError<>0 then Close(FIn);
 end;

procedure TBmpStream.ReadLine;
 type Ta=array [0..800] of Byte;
 var BuffPtr:TXMSPointer; I:Word; A:^Ta; BufSize:Word;
 begin
  if Header.Bits=1 then
  begin
  {$I-}
   BufSize:=((Header.Width+7) div 8+3) and not 3;
   GetMem(A,BufSize);
   if not XMSFull then
   begin
    BlockRead(FIn,A^,BufSize); {$I+}
    if IOResult<>0 then WriteError('BlockRead: Error !');
    if XMSPtr.Handle=0 then Exit;
    Ptr_XMSPtr(A,BuffPtr);
    XMSMove(BuffPtr,XMSPtr,BufSize);
    for I:=0 to Header.Width-1 do
     if A^[I div 8] and (128 shr (I mod 8))=0 then FBuff^[I]:=Palette^[0].Pixel
                                              else FBuff^[I]:=Palette^[1].Pixel;
   end else
   begin
    Ptr_XMSPtr(A,BuffPtr);
    XMSMove(XMSPtr,BuffPtr,BufSize);
    for I:=0 to Header.Width-1 do
     if A^[I div 8] and (128 shr (I mod 8))=0 then FBuff^[I]:=Palette^[0].Pixel
                                              else FBuff^[I]:=Palette^[1].Pixel;
   end;
   Inc(XMSPtr.Offset,BufSize);
   FreeMem(A,BufSize);
  end else
  begin
   if not XMSFull then
   begin
    {$I-}
    if Header.Bits=8 then
    begin
     BufSize:=(Header.Width+3) and not 3;
     GetMem(A,BufSize);
     BlockRead(FIn,A^,BufSize);
     for I:=0 to Header.Width-1 do FBuff^[I]:=Palette^[A^[I]].Pixel;
     FreeMem(A,BufSize);
    end else BlockRead(FIn,FBuff^,FLSize); {$I+}
    if IOResult<>0 then WriteError('BlockRead: Error !');
    if XMSPtr.Handle=0 then Exit;
    Ptr_XMSPtr(FBuff,BuffPtr);
    XMSMove(BuffPtr,XMSPtr,FLSize);
   end else
   begin
    Ptr_XMSPtr(FBuff,BuffPtr);
    XMSMove(XMSPtr,BuffPtr,FLSize);
   end;
   Inc(XMSPtr.Offset,FLSize);
  end;
 end;

procedure TBmpStream.ResetStream;
 begin
  XMSPtr.Offset:=0;
  if (XMSPtr.Handle=0)or not XMSFull then Seek(FIn,Header.OffBits)
 end;

destructor TBmpStream.Done;
 begin
  if BMPError=0 then
  begin
   if (Header.Bits=1) and (Palette<>nil) then
    FreeMem(Palette,SizeOf(Palette^[0])*2) else
   if Palette<>nil then Dispose(Palette);
   if XMSPtr.Handle<>0 then XMSFreeMem(XMSPtr.Handle);
   Close(FIn);
  end;
 end;

procedure TBmpStream.Draw;
 var
  Y:Word;
  YSize,LSize:Word;
 begin
  GetMem(FBuff,Max(FLSize,Size.X * 3));
  with Header do if BMPError=0 then
  begin
   ResetStream;
   if not IsTransparent(SolidFillColor) then LSize:=Size.X
                                        else LSize:=Min(Size.X,Width);
   { FillChar(FBuff^,LSize*3,0); }
   FillRGB(FBuff^,LSize,SolidFillColor,0);
   YSize:=Min(Size.Y-1,Height-1)+Origin.Y;
   if not IsTransparent(SolidFillColor) then
    for Y:=YSize to Size.Y-1+Origin.Y do PutLineRGB(Origin.X,Y,LSize,FBuff^);
   for Y:=1 to Delta.Y do ReadLine;
   for Y:=YSize downto Origin.Y do
   begin
    ReadLine;
    PutLineRGB(Origin.X,Y,LSize,FBuff^[Delta.X]);
   end;
  end;
  FreeMem(FBuff,Max(FLSize,Size.X * 3));
 end;

procedure TBmpStream.DrawAll;
 var
  Y,Big,Tmp,X:Word;
  LSize,YSize,XSize:Word;
  Pomer:Real;
  Buf2:PFBuff;
 begin
  GetMem(FBuff,FLSize);
  GetMem(Buf2,Size.X*3);
  with Header do if BMPError=0 then
  begin
   ResetStream;
   LSize:=Size.X; Big:=Height;
   Pomer:=Height/Size.Y;
   if Pomer<Width/Size.X then Pomer:=Width/Size.X;
   if Pomer<1 then Pomer:=1;
   YSize:=Round(Height / Pomer)-1;
   XSize:=Round(Width / Pomer)-1;
   if not IsTransparent(SolidFillColor) then
   begin
    FillRGB(Buf2^,Size.X,SolidFillColor,0);
    for Y:=YSize+1 to Size.Y do PutLineRGB(Origin.X,Y+Origin.Y,LSize,Buf2^);
   end else LSize:=XSize;
   for Y:=YSize downto 0 do
   begin
    Tmp:=Round(Y*Pomer);
    while Big>Tmp do
    begin ReadLine; Dec(Big) end;
    for X:=0 to XSize do Move(FBuff^[Round(X*Pomer)],Buf2^[X],3);
    PutLineRGB(Origin.X,Y+Origin.Y,LSize,Buf2^);
   end;
  end;
  FreeMem(Buf2,Size.X*3);
  FreeMem(FBuff,FLSize);
  XMSFull:=XMSPtr.Handle<>0;
 end;

procedure TBmpStream.LoadAll;
 var
  Y:Word;
 begin
  GetMem(FBuff,FLSize);
  with Header do if BMPError=0 then
  begin
   ResetStream;
   for Y:=1 to Height do ReadLine;
  end;
  FreeMem(FBuff,FLSize);
  XMSFull:=XMSPtr.Handle<>0;
 end;

procedure TBMPStream.Run(var W:Word);
 begin
  with Header do
  begin
   case W of
       kbLeft:if ShiftMask and kbShifts>0 then Dec(Delta.X,GetMaxX*8 div 10)
                                          else Dec(Delta.X,20);
       kbRight:if ShiftMask and kbShifts>0 then Inc(Delta.X,GetMaxX*8 div 10)
                                           else Inc(Delta.X,20);
       kbUp:if ShiftMask and kbShifts>0 then Inc(Delta.Y,GetMaxY*8 div 10)
                                        else Inc(Delta.Y,20);
       kbDown:if ShiftMask and kbShifts>0 then Dec(Delta.Y,GetMaxY*8 div 10)
                                          else Dec(Delta.Y,20);
       kbPgDn:Dec(Delta.Y,GetMaxY*8 div 10);
       kbCtrlLeft:Dec(Delta.X,GetMaxX*8 div 10);
       kbPgUp:Inc(Delta.Y,GetMaxY*8 div 10);
       kbCtrlRight:Inc(Delta.X,GetMaxX*8 div 10);
       else Exit;
   end;
   if Delta.X+Size.X>=Width then Delta.X:=Width-Size.X-1;
   if Delta.Y+Size.Y>=Height then Delta.Y:=Height-Size.Y-1;
   if Delta.X<0 then Delta.X:=0;
   if Delta.Y<0 then Delta.Y:=0;
  end;
  W:=kbNoKey;
  Draw;
 end;
end.