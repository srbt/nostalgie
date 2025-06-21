{$A+,B-,D+,E+,F-,G+,I+,L+,N+,O-,R-,S+,V+,X-}
{$M 16384,0,655360}
unit MyVesa;
{$DEFINE OldDraw}
interface

uses Prevody;

const
 MaxFrameSize = 8;
 opSelFrame   = 1;
 opSelectable = 2;
 opHidden     = 4;
 opModal      = 8;
 opDialog     = opModal or opSelectable;

type
 PString=^String;

 PFrameType=^TFrameType;
 TFrameType=record
             FrameSize:Byte;
             Left,Up,Right,Down:array [1..MaxFrameSize] of Byte;
            end;
 PFrames=^TFrames;
 TFrames=record
          FrameCount:Byte;
          Frame:array [0..10] of TFrameType;
         end;

type
 PVesaModeInfo=^TVesaModeInfo;
 TVesaModeInfo=record
            ModeAttrib: Word;
            WindowAttrib: array [1..2] of Byte;
            Granularity: Word;
            WindowSize: Word;
            WindowSegment: array [1..2] of Word;
            PositionProc: pointer;
            BytesPerLine: Word;
            Width: Word;
            Height: Word;
            CharWidth: Byte;
            CharHeight: Byte;
            Planes: Byte;
            Bits: Byte;
            Banks: Byte;
            Model: Byte;
            BankSize: Byte;
            Reserved: array[0..226] of Byte
          end;

 PAsciz=^TAsciz;
 TAsciz=array [0..65534] of Char;
 PModeList=^TModeList;
 TModeList=array [0..256] of Word;

 PVesaInfo=^TVesaInfo;
 TVesaInfo=record
            Sign:array [1..4] of Char;
            Version:Word;
            Oem:PAsciz;
            Options:array [1..4] of Byte;
            Modes:PModeList;
            Reserved: array[0..237] of Byte;
           end;

 PRGBPixel=^TRGBPixel;
 TRGBPixel=record
            B,G,R:Byte;
           end;

 TRGBQuad=record
            Pixel:TRgbPixel;
            Quad:Byte;
          end;

 P8BitPalette=^T8BitPalette;
 T8BitPalette=array [0..255] of TRGBQuad;

 PFBuff=^TFBuff;
 TFBuff=array[0..4095] of TRGBPixel;
 TPoint=record
         case Byte of
              0:(X,Y:Integer);
              1:(All:Longint);
        end;
 PFont=^TFont;
 TFont=array [0..256*16-1] of Byte;
 PFontDef=^TFontDef;
 TFontDef=record
           Lines:Byte;
           Font:PFont;
          end;
 PWord=^Word;
 PTextBuff=PWord;
 TTextBuff=Word;
 PPalette=^TPalette;
 TPalette=array [0..15] of TRGBPixel;

 PVesaView=^TVesaView;
 TVesaView=object
            Owner:PVesaView;
            Origin,Size:TPoint;
            Delta:TPoint;
            SolidFillColor:TRGBPixel;
            Options:Word;
            Selected:Boolean;
            ModalResult:Word;
            constructor Init;
            procedure Draw; virtual;
            procedure DrawAll; virtual;
            procedure DrawRect(X,Y,X1,Y1:Word);
            procedure SetRange(X,Y,X1,Y1:Integer); virtual;
            procedure SetSize(X1,Y1:Integer); virtual;
            procedure Center;
            procedure MoveTo(X,Y:Integer);
            procedure MoveRel(X,Y:Integer);
            procedure Run(var W:Word); virtual;
            procedure SetData(var Data; Len:Word); virtual;
            procedure GetData(var Data; Len:Word); virtual;
            function Valid(var W:Word):Boolean; virtual;
            procedure Idle; virtual;
            destructor Done; virtual;
            procedure Select(Sel:Boolean); virtual;
           end;

 PTextView=^TTextView;
 TTextView=object(TVesaView)
            TextBuff:PTextBuff;
            Lines,Columns:Byte;
            Frame:PFrameType;
            FontDef:PFontDef;
            Palette:PPalette;
            Cursor:TPoint;
            TextAttr,XTextAttr,Border:Byte;
            constructor Init(AC,AL:Byte);
            procedure ReSize(AC,AL:Byte); virtual;
            procedure Draw; virtual;
            destructor Done; virtual;
            procedure ClrScr; virtual;
            procedure ClrLine(Y:Byte); virtual;
            procedure ClrEol(X,Y:Byte); virtual;
            procedure WriteXY(X,Y:Byte; S1:String);
            procedure WriteXYC(X,Y:Byte; S1:String);
            procedure ScrollUp;
            function CLineLen(var S1:String):Byte;
            procedure PutCharXY(X,Y:Byte; Ch:Char);
            procedure SetDefaultFrame(F:Byte);
           end;

const
 vsOk=0;
 vsNoInitGraph=-1;
 vsInvalidMode=-10;
 vsLastMode=$FFFF;

const
{ Foreground and background color constants }

  Black         = 0;
  Blue          = 1;
  Green         = 2;
  Cyan          = 3;
  Red           = 4;
  Magenta       = 5;
  Brown         = 6;
  LightGray     = 7;

{ Foreground color constants }

  DarkGray      = 8;
  LightBlue     = 9;
  LightGreen    = 10;
  LightCyan     = 11;
  LightRed      = 12;
  LightMagenta  = 13;
  Yellow        = 14;
  White         = 15;


var
 VesaResult:Integer;
 LastMode:Byte;
 GetMaxX,XSize,GetMaxY,YSize,GetGraphMode,Granular,BpL,
 WinSize,WinSeg,CurrWindow:Word;
 BitCol,BitPlanes,BytCol:Byte;
 PutLineRGB:procedure (X,Y,Len:Word; var Buffer);
 PutPixelRGB:procedure (X,Y:Word; var Buffer);
 XORPutPixelRGB:procedure (X,Y:Word; var Buffer);
 WindMin,WindMax:TPoint;

procedure GetVesaInfo(var Info:TVesaInfo);
procedure GetVesaModeInfo(Mode:Word;var Info:TVesaModeInfo);
procedure InitVesaGraph(XRes,YRes:Word; ABitCol:Byte);
procedure CloseVesaGraph;
procedure SetVesaMode(Mode:Word);
procedure PutLine(X,Y,Len:Word; var Buffer);
procedure PutLineRGB32(X,Y,Len:Word; var Buffer);
procedure PutLineRGB16(X,Y,Len:Word; var Buffer);
procedure PutLineRGB15(X,Y,Len:Word; var Buffer);
procedure PutLineRGB8(X,Y,Len:Word; var Buffer);
procedure PutLineRGBNull(X,Y,Len:Word; var Buffer);
procedure PutPixelRGB32(X,Y:Word; var Buffer);
procedure PutPixelRGB16(X,Y:Word; var Buffer);
procedure PutPixelRGB15(X,Y:Word; var Buffer);
procedure PutPixelRGBNull(X,Y:Word; var Buffer);
procedure XORPutPixelRGB32(X,Y:Word; var Buffer);
procedure XORPutPixelRGB16(X,Y:Word; var Buffer);
procedure XORPutPixelRGB15(X,Y:Word; var Buffer);

procedure ClipOff;
procedure SetVesaWindow(W:Word);
procedure FillRGB(var Co; Count:Word; var Cim:TRGBPixel; Delta:Byte);
procedure FillRGBPixel(Col:LongInt;var Ground:TRGBPixel);
function RGBPixel_Long(var Pix:TRGBPixel):LongInt;
function IsTransparent(var Pix:TRGBPixel):Boolean;
procedure ClearVesa;
function NewStr(S:String):PString;
procedure DisposeStr(var S:PString);
function Isin(Origin1, Size1, Origin2, Size2:TPoint):Boolean;
function ViewIsIn(View:PVesaView):Boolean;
procedure SwapBytes(var B1,B2:Byte);

procedure KamenictiFNT;
procedure Kamenicti14FNT;
procedure MyVesaFrame;

const
 KamenFnt16:TFontDef=(Lines:16; Font:@KamenictiFNT);
 KamenFnt14:TFontDef=(Lines:14; Font:@Kamenicti14FNT);
 DefaultFntDef:PFontDef=@KamenFnt16;
 DefaultFrameDef:PFrames=@MyVesaFrame;
 DefaultFrameNum:Byte=1;

implementation

procedure KamenictiFNT; external;
{$L KamenFNT.OBJ}

procedure Kamenicti14FNT; external;
{$L MJKF14.OBJ}

procedure EgaPalDef; external;
{$L EgaPal.OBJ}

procedure MyVesaFrame; external;
{$L MYVESAFR.OBJ}

function NewStr(S:String):PString;
 var
  P:PString;
 begin
  if S='' then NewStr:=nil
          else begin GetMem(P,Byte(S[0])+1); Move(S,P^,Byte(S[0])+1); NewStr:=P; end;
 end;

procedure DisposeStr(var S:PString);
 begin
  if S<>nil then begin FreeMem(S,Byte(S^[0])+1); S:=nil; end;
 end;

function Isin(Origin1, Size1, Origin2, Size2:TPoint):Boolean;
 begin
  IsIn:=not((Origin1.X+Size1.X<Origin2.X) or
            (Origin1.Y+Size1.Y<Origin2.Y) or
            (Origin1.X>Origin2.X+Size2.X) or
            (Origin1.Y>Origin2.Y+Size2.Y));

 end;

function ViewIsIn(View:PVesaView):Boolean;
 begin
  with View^ do
  ViewIsIn:=(View<>nil)and not((Origin.X>WindMax.X) or
                               (Origin.Y>WindMax.Y) or
                               (Origin.X+Size.X<WindMin.X) or
                               (Origin.Y+Size.Y<WindMin.Y));
 end;

procedure FillRGBPixel(Col:LongInt;var Ground:TRGBPixel); assembler;
 asm
  LES DI,Ground
  MOV AX,word ptr [Col]
  CLD
  STOSW
  MOV AX,word ptr [Col+2]
  STOSB
 end;

function RGBPixel_Long(var Pix:TRGBPixel):LongInt; assembler;
 asm
  LES DI,Pix
  MOV AX,[ES:DI]
  INC DI
  INC DI
  MOV DL,[ES:DI]
  XOR DH,DH
 end;

function IsTransparent(var Pix:TRGBPixel):Boolean; assembler;
 asm
  LES DI,Pix
  CMP byte ptr [ES:DI],1
  JNZ @NoOk
  INC DI
  MOV AX,[ES:DI]
  OR AX,AX
  JZ @Ok
@NoOk:
  XOR AL,AL
  JMP @Konec
@Ok:
  MOV AL,1
@Konec:
 end;

constructor TTextView.Init(AC,AL:Byte);
 begin
  Selected:=False;
  Owner:=nil;
  FontDef:=DefaultFntDef;
  SetDefaultFrame(DefaultFrameNum);
  SetRange(0,0,0,0);
  Palette:=@EgaPalDef;
  TextBuff:=nil;
  TextAttr:=7;
  XTextAttr:=$70;
  Border:=1;
  Cursor.X:=0; Cursor.Y:=0;
  ReSize(AC,AL);
  Options:=opSelFrame;
 end;

procedure TTextView.ReSize(AC,AL:Byte);
 var
  Tmp,T1,T2:PTextBuff;
  OC,OL:Byte;
  I,J:Byte;
 begin
  Tmp:=TextBuff;
  GetMem(TextBuff,(AC*AL) shl 1);
  OC:=Columns; OL:=Lines;
  Columns:=AC; Lines:=AL;
  SetSize((AC shl 3)+2*Frame^.FrameSize,(AL*FontDef^.Lines)+2*Frame^.FrameSize);
  ClrScr;
  if Tmp<>nil then
  begin
   J:=Min(AC,OC) shl 1;
   T1:=Tmp; T2:=TextBuff;
   for I:=1 to OL do
   begin
    Move(T1^,T2^,J);
    Inc(T1,OC); Inc(T2,AC);
   end;
   FreeMem(Tmp,(OC*OL) shl 1);
  end;
  if Cursor.X>AC then Cursor.X:=AC;
  if Cursor.Y>AL then Cursor.Y:=AL;
 end;

procedure TTextView.WriteXY(X,Y:Byte; S1:String);
 var
  I:Byte;
  C:PWord;
  W:Word;
  Ch:^Char;
 begin
  if (Y>Lines) or (X>Columns) then Exit;
  Dec(Y); Dec(X);
  C:=TextBuff; Inc(LongInt(C),(X+Y*Columns) shl 1);
  I:=Min(Byte(S1[0]),Columns-X); W:=TextAttr shl 8; Ch:=@S1[1];
  while I>0 do
  begin
   C^:=W or Byte(Ch^); Inc(C); Inc(Ch); Dec(I);
  end;
 end;

procedure TTextView.ScrollUp;
 var Tmp:PTextBuff;
 begin
  Tmp:=TextBuff;
  Inc(Tmp,Columns);
  Move(Tmp^,TextBuff^,((Lines-1)*Columns) shl 1);
  ClrLine(Lines);
 end;

function TTextView.CLineLen(var S1:String):Byte; assembler;
 asm
  PUSH DS
  LDS SI,S1
  LODSB
  MOV CL,AL
  XOR CH,CH
  XOR DL,DL
  JCXZ @Konec
@Smycka:
  LODSB
  CMP AL,'~'
  JNZ @NoVlnka
  LODSB
  DEC CL
  JZ @Konec
@NoVlnka:
  INC DL
  LOOP @Smycka
@Konec:
  MOV AL,DL
  POP DS
 end;

procedure TTextView.WriteXYC(X,Y:Byte; S1:String);
 type
  WordRec = record
             Lo, Hi: Byte;
            end;
 var
  I:Byte;
  J:Integer;
  C:PWord;
  W:Word;
  Ch:^Char;
  XTA:Byte;
 begin
  if (Y>Lines) or (X>Columns) then Exit;
  Dec(Y); Dec(X);
  C:=TextBuff; Inc(LongInt(C),(X+Y*Columns) shl 1);
  I:=Min(CLineLen(S1),Columns-X); W:=TextAttr shl 8; Ch:=@S1[1];
  J:=Byte(S1[0]);
  while I>0 do
  begin
   if Ch^='~' then
   begin
    Inc(Ch); Dec(J);
    if Ch^<>'~' then begin WordRec(W).Hi:=XTextAttr; XTextAttr:=TextAttr; TextAttr:=WordRec(W).Hi end;
   end;
   C^:=W or Byte(Ch^); Inc(C); Inc(Ch); Dec(I); Dec(J);
  end;
  while J>0 do
  begin
   if Ch^='~' then
   begin
    Inc(Ch); Dec(J);
    if (Ch^<>'~')or(J<=0) then begin WordRec(W).Hi:=XTextAttr; XTextAttr:=TextAttr; TextAttr:=WordRec(W).Hi end;
   end;
   Inc(Ch); Dec(J);
  end;
 end;

procedure TTextView.PutCharXY(X,Y:Byte; Ch:Char);
 var
  C:PWord;
 begin
  if (Y>Lines) or (X>Columns) then Exit;
  Dec(Y); Dec(X);
  C:=TextBuff; Inc(LongInt(C),(X+Y*Columns) shl 1);
  C^:=(TextAttr shl 8) or Byte(Ch);
 end;

destructor TTextView.Done;
 begin
  if TextBuff<>nil then FreeMem(TextBuff,(Columns*Lines) shl 1);
 end;

procedure FillWord(var Co; Kolik,Cim:Word); assembler;
 asm
  LES DI,Co
  MOV CX,Kolik
  MOV AX,Cim
  CLD
  REP STOSW
 end;

procedure TTextView.ClrScr;
 begin
  FillWord(TextBuff^,(Columns*Lines),(TextAttr shl 8) or 32);
 end;

procedure TTextView.ClrLine(Y:Byte);
 var B:PTextBuff;
 begin
  B:=TextBuff;
  Inc(B,Columns*(Y-1));
  FillWord(B^,Columns,(TextAttr shl 8) or 32);
 end;

procedure TTextView.ClrEol(X,Y:Byte);
 var B:PTextBuff;
 begin
  Dec(X);
  B:=TextBuff;
  Inc(B,Columns*(Y-1)+X);
  FillWord(B^,Columns-X,(TextAttr shl 8) or 32);
 end;

procedure FillRGB(var Co; Count:Word; var Cim:TRGBPixel; Delta:Byte); assembler;
 asm
  CLD
  PUSH DS
  LDS SI,Cim
  LODSB
  MOV DL,AL
  LODSW
  POP DS
  MOV CL,Delta
  CMP CL,255
  JZ @Vynuluj
  ADD AL,CL
  ADD AH,CL
  ADD DL,CL
  JMP @Bez
@Vynuluj:
  XOR AX,AX
  XOR DL,DL
@Bez:
  LES DI,Co
  MOV CX,Count
@Smycka:
  MOV [ES:DI],DL
  INC DI
  STOSW
  LOOP @Smycka
 end;

procedure TTextView.SetDefaultFrame(F:Byte);
 var
  Delt:Integer;
 begin
  if F<=DefaultFrameDef^.FrameCount then
  begin
   Delt:=DefaultFrameDef^.Frame[F].FrameSize-Frame^.FrameSize;
   SetSize(Size.X+Delt,Size.Y+Delt);
   Frame:=@DefaultFrameDef^.Frame[F];
  end;
 end;

{$IFDEF OldDraw}
procedure TTextView.Draw;
 var
  ForeGround,BackGround:TRGBPixel;
  Buff:PFBuff;
  BigY,X,Y,K,B:Word;
  LSize,BSize,YPoz,XPoz:Word;
  C,Poz:PWord;
  Bor:Byte;
  Font:PFont;
  LFont:Byte;
 begin
  if Options and opHidden = opHidden then Exit;
  LSize:=Size.X*SizeOf(TRGBpixel);
  GetMem(Buff,LSize);
  YPoz:=Origin.Y;
  BSize:=Min(Columns shl 3+(Frame^.FrameSize shl 1),Size.X);
   Bor:=Border and 7;
  if Selected and (Options and opSelFrame >0) then {Bor:=Bor or 8;} Bor:=Yellow;
  with Frame^ do
  for Y:=1 to FrameSize do
  begin
   for X:=1 to FrameSize do FillRGB(Buff^[X-1],1,Palette^[Bor],Left[X]);
   for X:=1 to FrameSize do FillRGB(Buff^[BSize-FrameSize+X-1],1,Palette^[Bor],Right[X]);
   FillRGB(Buff^[Y],BSize-2*Y,Palette^[Bor],Up[Y]);
   PutLineRGB(Origin.X,YPoz,BSize,Buff^);
   Inc(YPoz);
  end;
  Poz:=TextBuff;
  Font:=FontDef^.Font;
  LFont:=FontDef^.Lines;
  for BigY:=1 to Lines do
  begin
   C:=Poz;
   for Y:=0 to LFont-1 do
   begin
    XPoz:=Frame^.FrameSize; Poz:=C;
    for X:=1 to Columns do
     begin
      B:=Font^[Byte(Poz^)*LFont+Y];
      ForeGround:=Palette^[(Poz^ shr 8) and $F];
      BackGround:=Palette^[(Poz^ shr 12) and $F];
      Inc(LongInt(Poz),2);
      if (Cursor.X=X)and(Cursor.Y=BigY)and(Y>LFont-2) then
      for K:=0 to 7 do
      begin
       if XPoz<=BSize then
       if B and (128 shr K) = 0 then Buff^[XPoz]:=ForeGround
                                else Buff^[XPoz]:=BackGround;
       Inc(XPoz);
      end else
      for K:=0 to 7 do
      begin
       if XPoz<=BSize then
       if B and (128 shr K) <> 0 then Buff^[XPoz]:=ForeGround
                                 else Buff^[XPoz]:=BackGround;
       Inc(XPoz);
      end;
     end;
    PutLineRGB(Origin.X,YPoz,BSize,Buff^);
    Inc(YPoz);
   end;
  end;
  with Frame^ do
  for Y:=FrameSize downto 1 do
  begin
   for X:=1 to Y do FillRGB(Buff^[X-1],1,Palette^[Bor],Left[X]);
   for X:=1 to Y do FillRGB(Buff^[BSize-FrameSize+X-1],1,Palette^[Bor],Right[X]);
   FillRGB(Buff^[Y],BSize-2*Y,Palette^[Bor],Down[FrameSize-Y+1]);
   PutLineRGB(Origin.X,YPoz,BSize,Buff^);
   Inc(YPoz);
  end;
  FreeMem(Buff,LSize);
 end;

{$ELSE}
procedure TTextView.Draw;
 type
  PDD=^TDD;
  TDD=record
       ForeGround,BackGround:TRgbPixel;
       BigY,X:Word;
       Y,K,B:Word;
       YPoz,XPoz:Word;
       C,Poz:PWord;
       Font:PFont;
       Palette:TPalette;
       LFont:Word;
       Bor:Word;
       Cursor:TPoint;
       OriginX:Word;
       Lines,Columns:Word;
       Frame:TFrameType;
       Size:TPoint;
       Buff:Word;
      end;
 var
  LSize:Word;
  DD:PDD;
 begin
  LSize:=Size.X*SizeOf(TRGBPixel)+SizeOf(TDD)+16;
  GetMem(DD,LSize);
  DD^.OriginX:=Origin.X;
  DD^.YPoz:=Origin.Y;
  DD^.Font:=FontDef^.Font;
  DD^.LFont:=FontDef^.Lines;
  DD^.Poz:=TextBuff;
  DD^.Lines:=Lines;
  DD^.Columns:=Columns;
  if Frame=nil then DD^.Frame.FrameSize:=0
               else DD^.Frame:=Frame^;
  DD^.Size:=Size;
  DD^.Cursor:=Cursor;
  DD^.Palette:=Palette^;
  if Selected and (Options and opSelFrame > 0) then DD^.Bor:=Border and 7 or 8
                                               else DD^.Bor:=Border and 7;
  asm
   JMP @AfterProc
@FillFrame:
   MOV CL,[TDD.Frame.FrameSize]
   XOR CH,CH
@ForX1:
   MOV DL,[BX]
   CMP DL,255
   JZ @Vynuluj
   MOV AX,word ptr [TDD.ForeGround]
   MOV DH,byte ptr [TDD.ForeGround+2]
   ADD AL,DL
   ADD AH,DL
   ADD DH,DL
   JMP @Filled
@Vynuluj:
   XOR AX,AX
   XOR DH,DH
@Filled:
   STOSW
   MOV [DI],DH
   INC DI
   INC BX
   LOOP @ForX1
   RETN
@AfterProc:
   LDS SI,DD
   OR SI,SI
   JZ @SIOk
   MOV AX,DS
   INC AX
   MOV DS,AX
   XOR SI,SI
@SIOk:
   MOV AX,[TDD.Columns]
   SHL AX,3
   MOV DL,[TDD.Frame.FrameSize]
   SHL DL,1
   XOR DH,DH
   ADD AX,DX
   CMP AX,[TDD.Size.X]
   JNB @SizeXOk
   MOV [TDD.Size.X],AX
@SizeXOk:
   MOV [TDD.Y],0
   MOV DI,TDD.Palette
   MOV AX,[TDD.Bor]
   ADD DI,AX
   SHL AX,1
   ADD DI,AX
   MOV DL,[DI]
   MOV byte ptr [TDD.Foreground],DL
   INC DI
   MOV DX,[DI]
   MOV word ptr [TDD.ForeGround+1],DX
@ForY1:              { TDD.ForeGround = Palette^[Bor] }
   MOV DX,DS
   MOV ES,DX
   MOV BX,TDD.Frame.Left
   MOV DI,TDD.Buff
   CALL near ptr @FillFrame

   MOV BX,TDD.Frame.Right
   MOV DI,[TDD.Size.X]
   MOV DL,[TDD.Frame.FrameSize]
   XOR DH,DH
   SUB DI,DX
   MOV DX,DI
   SHL DX,1
   ADD DI,DX
   ADD DI,TDD.Buff
   CALL near ptr @FillFrame

   MOV BX,[TDD.Y]
   INC BX
   MOV DL,byte ptr [BX+TDD.Frame.Up]
   MOV DI,BX
   SHL DI,1
   ADD DI,BX
   ADD DI,TDD.Buff
   MOV CX,[TDD.Size.X]
   SHL BX,1
   SUB CX,BX

   CMP DL,255
   JZ @Vynuluj1
   MOV AX,word ptr [TDD.ForeGround]
   MOV DH,byte ptr [TDD.ForeGround+2]
   ADD AL,DL
   ADD AH,DL
   ADD DH,DL
   JMP @Vynulovano
@Vynuluj1:
   XOR AX,AX
   XOR DH,DH
@Vynulovano:
   CLD
@HorniLinka:
   STOSW
   MOV [DI],DH
   INC DI
   LOOP @HorniLinka
   PUSH DS
   PUSH [TDD.OriginX]
   PUSH [TDD.YPoz]
   PUSH [TDD.Size.X]
   MOV AX,TDD.Buff
   PUSH DS
   PUSH AX
   MOV AX,seg @Data
   MOV DS,AX
   CALL dword ptr [DS:PutLineRGB]
   POP DS
   INC [TDD.YPoz]
   MOV AX,[TDD.Y]
   INC AX
   MOV [TDD.Y],AX
   CMP AL,[TDD.Frame.FrameSize]
   JB @ForY1

   MOV [TDD.BigY],1
@ForBigY:



   MOV AX,[TDD.BigY]
   INC AX
   MOV [TDD.BigY],AX
   CMP AX,[TDD.Lines]
   JNA @ForBigY

   MOV AX,seg @Data
   MOV DS,AX
  end;
  FreeMem(DD,LSize);
 end;
{$ENDIF}

constructor TVesaView.Init;
 begin
  Owner:=nil;
  FillRGBPixel(0,SolidFillColor);
  FillChar(Size,SizeOf(Size),0);
  FillChar(Origin,SizeOf(Origin),0);
  FillChar(Delta,SizeOf(Delta),0);
  ModalResult:=0;
  Selected:=False;
 end;

procedure TVesaView.DrawRect(X,Y,X1,Y1:Word);
 var
  Wx,Wn:TPoint;
 begin
  if (Origin.X<=X)and(Origin.Y<=Y)and
     (Origin.X+Size.X>X1)and(Origin.Y+Size.Y>Y1) then
  begin
   Wx:=WindMax; Wn:=WindMin;
   WindMin.X:=X; WindMin.Y:=Y;
   WindMax.X:=X1; WindMax.Y:=Y1;
   Draw;
   WindMax:=WX; WindMin:=Wn;
  end else
  if Owner<>nil then Owner^.DrawRect(X,Y,X1,Y1) else Draw;
 end;

procedure TVesaView.Select(Sel:Boolean);
 begin
  Selected:=Sel;
  Draw;
 end;

procedure TVesaView.Draw;
 begin
 end;

procedure TVesaView.DrawAll;
 begin
  Draw;
 end;

procedure TVesaView.Run;
 begin
 end;

procedure TVesaView.Idle; 
 begin
 end;

function TVesaView.Valid(var W:Word):Boolean;
 begin
  Valid:=True;
 end;

procedure TVesaView.SetData(var Data; Len:Word);
 begin
 end;

procedure TVesaView.GetData(var Data; Len:Word);
 begin
 end;

destructor TVesaView.Done;
 begin
 end;

procedure TVesaView.SetRange(X,Y,X1,Y1:Integer);
 begin
  Origin.X:=X;
  Origin.Y:=Y;
  Size.X:=X1-X+1;
  Size.Y:=Y1-Y+1;
 end;

procedure TVesaView.SetSize(X1,Y1:Integer);
 begin
  Size.X:=X1;
  Size.Y:=Y1;
 end;

procedure TVesaView.Center;
 begin
  MoveTo((GetMaxX-Size.X) shr 1,(GetMaxY-Size.Y) shr 1);
 end;

procedure TVesaView.MoveTo(X,Y:Integer);
 begin
  if X=-1 then X:=(GetMaxX-Size.X) shr 1 else
  if X=-2 then X:=(GetMaxX-Size.X);
  if Y=-1 then Y:=(GetMaxY-Size.Y) shr 1 else
  if Y=-2 then Y:=(GetMaxY-Size.Y);
  Origin.X:=X;
  Origin.Y:=Y;
 end;

procedure TVesaView.MoveRel(X,Y:Integer);
 begin
  Inc(Origin.X,X);
  Inc(Origin.Y,Y);
 end;

procedure ResultBool; near; assembler;
asm
	cmp     al, 4fh                 { installed }
	mov     al, 1
	jnz     @Konec
	MOV     AL,AH                   { failed }
@Konec: XOR AH,AH
        MOV VesaResult,AX
end;

procedure GetVesaInfo(var Info:TVesaInfo); assembler;
 asm
  LES DI,Info
  MOV AX,4F00h
  INT 10h
  CALL ResultBool
 end;

procedure SetVesaMode(Mode:Word); assembler;
 asm
  XOR AX,AX
  MOV CurrWindow,AX
  MOV BX,Mode
  MOV GetGraphMode,BX
  MOV AX,4F02h
  INT 10h
  CALL ResultBool
 end;

procedure GetVesaModeInfo(Mode:Word;var Info:TVesaModeInfo); assembler;
 asm
  LES DI,Info
  MOV AX,4F01h
  MOV CX,Mode
  INT 10h
  CALL ResultBool
 end;

procedure SetRGB(I,R,G,B:Byte);
 begin
  Port[$03c8]:=I;
  Port[$03c9]:=R;
  Port[$03c9]:=G;
  Port[$03c9]:=B;
 end;

procedure InitVesaGraph(XRes,YRes:Word; ABitCol:Byte);
 var
  Info:TVesaInfo;
  MInfo:TVesaModeInfo;
  I:Integer;
 begin
  asm
   MOV AH,0Fh
   INT 10h
   MOV LastMode,AL
  end;
  GetVesaInfo(Info);
  if VesaResult<>vsOk then Exit;
  I:=0; while Info.Modes^[I]<>vsLastMode do
  begin
   GetVesaModeInfo(Info.Modes^[I],MInfo);
   with MInfo do
   if (ModeAttrib and 18 = 18)and(Width>=XRes)and(Height>=YRes)
      and(Bits>=ABitCol) then
   begin
    XSize:=Width; YSize:=Height;
    GetMaxX:=Width-1; GetMaxY:=Height-1;
    ClipOff;
    BitCol:=Bits; BitPlanes:=Planes;
    case BitCol of
         8:begin
            BytCol:=1;
            PutLineRGB:=PutLineRGB8;
{            PutPixelRGB:=PutPixelRGB8;
            XORPutPixelRGB:=XORPutPixelRGB8;}
           end;
        15:begin
            BytCol:=2;
            PutLineRGB:=PutLineRGB15;
            PutPixelRGB:=PutPixelRGB15;
            XORPutPixelRGB:=XORPutPixelRGB15;
           end;
        16:begin
            BytCol:=2;
            PutLineRGB:=PutLineRGB16;
            PutPixelRGB:=PutPixelRGB16;
            XORPutPixelRGB:=XORPutPixelRGB16;
           end;
        32:begin
            BytCol:=3;
            PutLineRGB:=PutLineRGB32;
            PutPixelRGB:=PutPixelRGB32;
            XORPutPixelRGB:=XORPutPixelRGB32;
           end;
    end;
    Granular:=Granularity*1024;
    GetGraphMode:=Info.Modes^[I];
    BpL:=BytesPerLine;
    WinSize:=WindowSize; WinSeg:=WindowSegment[1];
    SetVesaMode(GetGraphMode);
    if BitCol=8 then
     for I:=0 to 255 do SetRgb(I,I and $C0 shr 2, I and 56, I and 7 shl 3);
    Exit;
   end;
   Inc(I);
  end;
  VesaResult:=vsInvalidMode;
 end;

procedure CloseVesaGraph; assembler;
 asm
  MOV AL,LastMode
  XOR AH,AH
  INT 10h
  MOV AX,OFFSET(PutLineRGBNull)
  MOV word ptr PutLineRGB,AX
  MOV word ptr PutPixelRGB,AX
  MOV AX,SEG(PutLineRGBNull)
  MOV word ptr PutLineRGB+2,AX           { PutLineRGB:=PutLineRGBNull;}
  MOV word ptr PutPixelRGB+2,AX
 end;

procedure SetVesaWindow(W:Word); assembler;
 asm
  MOV AX,4F05h
  XOR BX,BX
  MOV DX,W
  MOV CurrWindow,DX
  INT 10h
  CALL ResultBool
 end;

procedure PutLine(X,Y,Len:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,GetMaxY
  JA @Konec
  MOV CX,XSize
  SUB CX,X
  JNA @Konec
{  DEC CX}
  CMP CX,Len
  JNA @XOK
  MOV CX,Len
@XOk:
  MUL XSize
  ADD AX,X
  ADC DX,0
  MOV BL,BytCol
  DEC BL
  JZ @EndRot
@Rot:
  SHL CX,1
  SHL AX,1
  RCL DX,1
  DEC BL
  JNZ @Rot
@EndRot:
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
@WindowSet:
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  MOVSB
  OR DI,DI
  JNZ @NoNewWin
  DEC CX
  JZ @SetCurrW
  INC AX
  JMP @WindowSet
@NoNewWin:
  LOOP @EndWinSet
@SetCurrW:
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;

procedure PutLineRGB32(X,Y,Len:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV AX,X
  CMP AX,WindMax.X
  JA @Konec
  MOV CX,Len
  MOV BX,AX
  SUB AX,WindMin.X
  JNB @MinXOk
  ADD CX,AX
  JLE @Konec
  NEG AX
  MOV DX,AX
  SHL AX,1
  ADD AX,DX
  ADD word ptr Buffer,AX
  MOV BX,WindMin.X
@MinXOk:
  MOV AX,BX
  ADD AX,CX
  SUB AX,WindMax.X
  JS @MaxXOk
  SUB CX,AX
  INC CX
  JS @Konec
@MaxXOk:
  MOV AX,Y

  MUL XSize
  ADD AX,BX
  ADC DX,0
  SHL AX,1 {!}
  RCL DX,1
  SHL AX,1
  RCL DX,1
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
@WindowSet:
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  MOVSW
  MOVSB
  INC DI
  OR DI,DI
  JNZ @NoNewWin
  DEC CX
  JZ @SetCurrW
  INC AX
  JMP @WindowSet
@NoNewWin:
  LOOP @EndWinSet
@SetCurrW:
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;

procedure PutLineRGB16(X,Y,Len:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV AX,X
  CMP AX,WindMax.X
  JA @Konec
  MOV CX,Len
  MOV BX,AX
  SUB AX,WindMin.X
  JNB @MinXOk
  ADD CX,AX
  JLE @Konec
  NEG AX
  MOV DX,AX
  SHL AX,1
  ADD AX,DX
  ADD word ptr Buffer,AX
  MOV BX,WindMin.X
@MinXOk:
  MOV AX,BX
  ADD AX,CX
  SUB AX,WindMax.X
  JS @MaxXOk
  SUB CX,AX
  INC CX
  JS @Konec
@MaxXOk:
  MOV AX,Y

  MUL XSize
  ADD AX,BX
  ADC DX,0
  SHL AX,1 {!}
  RCL DX,1
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
@WindowSet:
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  PUSH AX
  LODSW         {!!!!!}
  MOV DX,AX
  SHR AL,3
  XOR DL,DL
  XOR AH,AH
  AND DH,not 7
  SHR DX,5
  OR AX,DX
  STOSB
  LODSB
  AND AL,not 7
{  SHR AL,1}
  OR AL,AH
  STOSB
  POP AX
  OR DI,DI
  JNZ @NoNewWin
  DEC CX
  JZ @SetCurrW
  INC AX
  JMP @WindowSet
@NoNewWin:
  LOOP @EndWinSet
@SetCurrW:
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;

procedure PutLineRGB15(X,Y,Len:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV AX,X
  CMP AX,WindMax.X
  JA @Konec
  MOV CX,Len
  MOV BX,AX
  SUB AX,WindMin.X
  JNB @MinXOk
  ADD CX,AX
  JLE @Konec
  NEG AX
  MOV DX,AX
  SHL AX,1
  ADD AX,DX
  ADD word ptr Buffer,AX
  MOV BX,WindMin.X
@MinXOk:
  MOV AX,BX
  ADD AX,CX
  SUB AX,WindMax.X
  JS @MaxXOk
  SUB CX,AX
  INC CX
  JS @Konec
@MaxXOk:
  MOV AX,Y

  MUL XSize
  ADD AX,BX
  ADC DX,0
  SHL AX,1 {!}
  RCL DX,1
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
@WindowSet:
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  PUSH AX
  LODSW         {!!!!!}
  MOV DX,AX
  SHR AL,3
  XOR DL,DL
  XOR AH,AH
  AND DH,not 7
  SHR DX,6
  OR AX,DX
  STOSB
  LODSB
  AND AL,not 7
  SHR AL,1
  OR AL,AH
  STOSB
  POP AX
  OR DI,DI
  JNZ @NoNewWin
  DEC CX
  JZ @SetCurrW
  INC AX
  JMP @WindowSet
@NoNewWin:
  LOOP @EndWinSet
@SetCurrW:
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;

procedure PutLineRGB8(X,Y,Len:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV AX,X
  CMP AX,WindMax.X
  JA @Konec
  MOV CX,Len
  MOV BX,AX
  SUB AX,WindMin.X
  JNB @MinXOk
  ADD CX,AX
  JLE @Konec
  NEG AX
  MOV DX,AX
  SHL AX,1
  ADD AX,DX
  ADD word ptr Buffer,AX
  MOV BX,WindMin.X
@MinXOk:
  MOV AX,BX
  ADD AX,CX
  SUB AX,WindMax.X
  JS @MaxXOk
  SUB CX,AX
  INC CX
  JS @Konec
@MaxXOk:
  MOV AX,Y

  MUL XSize
  ADD AX,BX
  ADC DX,0
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
@WindowSet:
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  PUSH AX
  LODSW         {!!!!!}
  MOV DX,AX
  LODSB
  AND AL,0C0h
  AND DX,0E0E0h
  SHR DH,2
  ROL DL,3
  OR AL,DH
  OR AL,DL
  STOSB
  POP AX
  OR DI,DI
  JNZ @NoNewWin
  DEC CX
  JZ @SetCurrW
  INC AX
  JMP @WindowSet
@NoNewWin:
  LOOP @EndWinSet
@SetCurrW:
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;

procedure PutLineRGBNull(X,Y,Len:Word; var Buffer);
 begin
  VesaResult:=vsNoInitGraph;
 end;

procedure PutPixelRGBNull(X,Y:Word; var Buffer);
 begin
  VesaResult:=vsNoInitGraph;
 end;

procedure PutPixelRGB32(X,Y:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV CX,X
  CMP CX,WindMax.X
  JA @Konec
  CMP CX,WindMin.X
  JB @Konec
  MUL XSize
  ADD AX,CX
  ADC DX,0
  SHL AX,1 {!}
  RCL DX,1
  SHL AX,1
  RCL DX,1
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  MOVSW
  MOVSB
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;

procedure PutPixelRGB16(X,Y:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV CX,X
  CMP CX,WindMax.X
  JA @Konec
  CMP CX,WindMin.X
  JB @Konec
  MUL XSize
  ADD AX,CX
  ADC DX,0
  SHL AX,1 {!}
  RCL DX,1
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  PUSH AX
  LODSW         {!!!!!}
  MOV DX,AX
  SHR AL,3
  XOR DL,DL
  XOR AH,AH
  AND DH,not 7
  SHR DX,5
  OR AX,DX
  STOSB
  LODSB
  AND AL,not 7
{  SHR AL,1}
  OR AL,AH
  STOSB
  POP AX
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;


procedure PutPixelRGB15(X,Y:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV CX,X
  CMP CX,WindMax.X
  JA @Konec
  CMP CX,WindMin.X
  JB @Konec
  MUL XSize
  ADD AX,CX
  ADC DX,0
  SHL AX,1 {!}
  RCL DX,1
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  PUSH AX
  LODSW         {!!!!!}
  MOV DX,AX
  SHR AL,3
  XOR DL,DL
  XOR AH,AH
  AND DH,not 7
  SHR DX,6
  OR AX,DX
  STOSB
  LODSB
  AND AL,not 7
  SHR AL,1
  OR AL,AH
  STOSB
  POP AX
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;

procedure XORPutPixelRGB32(X,Y:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV CX,X
  CMP CX,WindMax.X
  JA @Konec
  CMP CX,WindMin.X
  JB @Konec
  MUL XSize
  ADD AX,CX
  ADC DX,0
  SHL AX,1 {!}
  RCL DX,1
  SHL AX,1
  RCL DX,1
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  LODSW
  XOR [ES:DI],AX
  INC DI
  INC DI
  LODSB
  XOR [ES:DI],AL
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;

procedure XORPutPixelRGB16(X,Y:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV CX,X
  CMP CX,WindMax.X
  JA @Konec
  CMP CX,WindMin.X
  JB @Konec
  MUL XSize
  ADD AX,CX
  ADC DX,0
  SHL AX,1 {!}
  RCL DX,1
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  PUSH AX
  LODSW         {!!!!!}
  MOV DX,AX
  SHR AL,3
  XOR DL,DL
  XOR AH,AH
  AND DH,not 7
  SHR DX,5
  OR AX,DX
  XOR [ES:DI],AL
  INC DI
  LODSB
  AND AL,not 7
{  SHR AL,1}
  OR AL,AH
  XOR [ES:DI],AL
  POP AX
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;


procedure XORPutPixelRGB15(X,Y:Word; var Buffer); assembler;
 asm
  CLD
  MOV AX,Y
  CMP AX,WindMax.Y
  JA @Konec
  CMP AX,WindMin.Y
  JB @Konec
  MOV CX,X
  CMP CX,WindMax.X
  JA @Konec
  CMP CX,WindMin.X
  JB @Konec
  MUL XSize
  ADD AX,CX
  ADC DX,0
  SHL AX,1 {!}
  RCL DX,1
  CMP Granular,0
  JNZ @NoKiloGranular
  XCHG AX,DX
  JMP @EndDiv
@NoKiloGranular:
  DIV Granular
@EndDiv:
  MOV DI,DX
  MOV ES,WinSeg
  CMP AX,CurrWindow
  PUSH DS
  LDS SI,Buffer
  JZ @EndWinSet
  PUSHA
  PUSH DS
  PUSH ES
  MOV DX,AX
  XOR BX,BX
  MOV AX,4F05h
  INT 10h
  POP ES
  POP DS
  POPA
@EndWinSet:
  PUSH AX
  LODSW         {!!!!!}
  MOV DX,AX
  SHR AL,3
  XOR DL,DL
  XOR AH,AH
  AND DH,not 7
  SHR DX,6
  OR AX,DX
  XOR [ES:DI],AL
  INC DI
  LODSB
  AND AL,not 7
  SHR AL,1
  OR AL,AH
  XOR [ES:DI],AL
  POP AX
  POP DS
  MOV CurrWindow,AX
@Konec:
 end;



procedure ClearVesa;
 var
  I:Word;
  Gran,WS:LongInt;
  Buff:Pointer;
 begin
  GetMem(Buff,XSize shl 3);
  FillChar(Buff^,XSize shl 3,0);
  for I:=0 to GetMaxY do PutLineRGB(0,I,XSize,Buff^);
  FreeMem(Buff,XSize shl 3);
 end;

procedure ClipOff;
 begin
  WindMin.All:=0;
  WindMax.X:=GetMaxX;
  WindMax.Y:=GetMaxY;
 end;

procedure SwapBytes(var B1,B2:Byte); assembler;
 asm
  PUSH DS
  LDS SI,B1
  LES DI,B2
  MOV AL,[SI]
  XCHG AL,[ES:DI]
  MOV [SI],AL
  POP DS
 end;

begin
 PutLineRGB:=PutLineRGBNull;
 PutPixelRGB:=PutPixelRGBNull;
 XORPutPixelRGB:=PutPixelRGBNull;
end.