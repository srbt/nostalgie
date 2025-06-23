{$A+,B-,D-,E+,F-,G+,I+,L-,N+,O-,R-,S-,V+,X-}
{$M 16384,0,655360}
unit obraz;
interface
uses Crt, Prevody, TMouse, StringCs;

type tvideo=record
             adrvideo:word;
             color,text:boolean;
             maxx,maxy:word;
             colors:byte;
            end;

type CrtRec=record
             WMax,WMin:Word;
             CSize:Word;
             CX,CY:Byte;
             VMode:Byte;
             Color:Byte;
            end;
type WordRec=record
              Lo,Hi:Char;
             end;

type
  vyctrezim=(autokon,transvp,skryt,ton);
  rezimset=set of vyctrezim;
  charset=set of char;
  TJustify=(tjRight,tjLeft,tjCenter);

type InputRec=record
               PosInStr:Byte;
               BufLen:Byte;
               MinBufLen:Byte;
               OverWrite:Boolean;
               CharFill:Char;
               ReadMode:RezimSet;
               RightChars:CharSet;
               EndChars:CharSet;
               ControlChars:CharSet;
               ReadResult:Word;
               Change:Boolean;
              end;

var
 XTextAttr:Byte;
 Idle:Procedure;
 Help:Procedure;
 CursorSize:Word;
 CurrInput:InputRec;

const
 StandartInput:InputRec=( PosInStr:0;
                          BufLen:20;
                          MinBufLen:0;
                          OverWrite:False;
                          CharFill:' ';
                          ReadMode:[Ton];
                          RightChars:[#32..#255];
                          EndChars:[^[,^M];
                          ControlChars:[];
                          ReadResult:0;
                          Change:True);

procedure writexy(x,y:byte;co:string);
procedure WriteXYL(X,Y,L:Byte; co:String);
procedure WriteC(Co:String);
procedure WriteXYC(X,Y:byte;co:String);
function CStrLen(var S: String): Integer;
procedure WriteXYJ(x,y:byte;TextJustify:TJustify;co:string);
procedure XTextColor(Color:Byte);
procedure XTextBackGround(Color:Byte);
procedure ram(x1,y1,x2,y2:byte;dual:boolean;title:string);
procedure okno(x,y,x1,y1,pozadi,pismo:byte;dual:boolean;title:string);
procedure getvideo(var videomod:tvideo);
procedure wopen(x1,y1,x2,y2:byte;var buffer;kam:boolean);
function ReadStr(S:String; InStr:Byte):String;
function ReadLnStr(S:String; InStr:Byte):String;
procedure ctiretez(var s:string;x,y:byte;var poz:byte;minlen,maxlen:byte;
                   var prepis:boolean;rezim:rezimset;pripset,
                   konset,konrid:charset;vyplzn:char;var konzn,ridzn:char;var Change:Boolean);
procedure prnscr(naz:string;dopln:boolean);
procedure cursor(stat:boolean);
function wmenu(x,y,x1,y1,maxx,maxy,pozadi,barva,bkb,kur,poz:byte;var buffer;
               title:string):byte;
function wmenu2(poz:byte;buffer:Pointer):byte;
{function Menu (X,Y,Pozadi,Pismo : byte; Pol:string; Jmeno:string;
               Dual:boolean): byte;}
function exfile(naz:string):boolean;
procedure GetCrt(var Cr:CrtRec);
procedure SetCrt(var Cr:CrtRec);
procedure ClearBox(X,Y,X1,Y1,Attr:Byte);
function GetCursorSize:Word;
procedure SetCursorSize(A:Word);
procedure BarGraph(X,Y,Size:Byte; Kolik, ZKolika:LongInt);

implementation

function CStrLen(var S: String): Integer; assembler;
asm
	LES	DI,S
	MOV	CL,ES:[DI]
	INC	DI
	XOR	CH,CH
	MOV	BX,CX
        JCXZ    @@2
	MOV	AL,'~'
        CLD
@@1:	REPNE	SCASB
	JNE	@@2
	DEC	BX
	JMP	@@1
@@2:	MOV	AX,BX
end;

function GetCursorSize:Word; assembler;
 asm
  MOV AH,03
  MOV BH,0
  INT $10
  MOV AX,CX
 end;

procedure SetCursorSize(A:Word); assembler;
 asm
  MOV CX,SS:A
  MOV AH,01
  INT $10
 end;

procedure cursor(stat:boolean);
 var
  C:Word;
 begin
  C:=GetCursorSize;
  if Stat then
  begin if Hi(C)=$20 then SetCursorSize(CursorSize) end
  else if Hi(C)<>$20 then begin CursorSize:=C; SetCursorSize($2000); end
 end;

function exfile(naz:string):boolean;
 var
  soub:file;
  exist:boolean;
 begin
  assign(soub,naz);
  {$i-}
  reset(soub);
  {$i+}
  exist:=ioresult=0;
  if exist then close(soub);
  exfile:=exist;
 end;

function wmenu(x,y,x1,y1,maxx,maxy,pozadi,barva,bkb,kur,poz:byte;var buffer;
               title:string):byte;
 type tscr=array [1..2000] of word;
 var
  wmin,wmax,i:integer;
  tat,j,xpuv,ypuv,len,ypl,yin,xpl,xin:byte;
  ret,povret:string;
  zn:char;
  scr:^tscr;
  ev:TMouseRec;

 function getitem(kol:byte):string;
  var
   item:^string;
   b:byte;
  begin
   item:=@Buffer;
   Inc(LongInt(Item),(Len+1)*(Kol-1));
{   move(mem[seg(buffer):ofs(buffer)+(len+1)*(kol-1)],item,len+1);}
   getitem:=item^;
  end;

 procedure pismenu(x,y,pozadi,kolik:byte);
  var ret:string[80];
  begin
   MHide;
   ret:=getitem(kolik);
   gotoxy(x,y);
   textbackground(pozadi);
   textcolor(barva);
   write(copy(ret,1,pos('~',ret)-1));
   textcolor(bkb);
   write(ret[pos('~',ret)+1]);
   textcolor(barva);
   write(copy(ret,pos('~',ret)+2,128));
   MShow;
  end;

 begin
  tat:=textattr;
  if MInit then ;
  xpuv:=wherex;ypuv:=wherey;
  wmin:=windmin;
  wmax:=windmax;
  len:=Byte(Buffer);
  povret:='';
  for i:=1 to maxy*maxx do
  begin
   ret:=getitem(i);
   povret:=povret+upcase(ret[pos('~',ret)+1]);
  end;
  getmem(scr,(x1-x+1)*(y1-y+1)*2);
  wopen(x,y,x1,y1,scr^,true);
  okno(x,y,x1,y1,pozadi,barva,true,title);
  MShow;
   yin:=trunc((y1-y)/maxy);
   ypl:=round((y1-y+1-(yin*(maxy-1)))/2)+1;
   xin:=trunc((x1-x-1)/(maxx+1));
   xpl:=trunc((x1-x-1-maxx*xin)/2)+2;
  for i:=1 to maxy*maxx do pismenu(xin*((i-1) div maxy)+xpl,yin*((i-1) mod maxy)+ypl,pozadi,i);
  i:=poz;
  repeat
   pismenu(xin*((i-1) div maxy)+xpl,yin*((i-1) mod maxy)+ypl,kur,i);
   textbackground(pozadi);
   textcolor(pozadi);
   cursor(false);
   zn:=#255;
   repeat
    if keypressed then zn:=upcase(readkey);
    MGetInfo(ev);
    Ev.Y:=Round(Ev.Y/200*25)+1; Ev.X:=Round(Ev.X/640*80)+1;
    if ev.Pressed=1 then zn:=#254;
    if (@Idle<>nil)and(pos(zn,povret+#0+#13+#27+#254)=0) then Idle;
   until pos(zn,povret+#0+#13+#27+#254)>0;
    pismenu(xin*((i-1) div maxy)+xpl,yin*((i-1) mod maxy)+ypl,pozadi,i);
    if zn=#254 then
    if (ev.y in [y..y1])and(ev.x in [x..x1]) then
    begin
     for j:=1 to maxx*maxy do if (ev.y+1=yin*((j-1)mod maxy)+ypl+y)and
         (ev.x+1 in [xin*((j-1) div maxy)+xpl+x..
         xin*((j-1) div maxy)+xpl+x+len])
         then begin i:=j;if DoubleClick then zn:=#13 else zn:=#254;end;
    end else zn:=#27;
    if zn=#0 then
    case readkey of
         #$3B:if @Help<>nil then Help;
         #71:i:=1;
         #72:if i>1 then i:=i-1 else i:=maxx*maxy;
         #75:if i=1 then i:=maxx*maxy else
             if i>maxy then i:=i-maxy else i:=maxy*maxx-maxy+i-1;
         #77:if i=maxx*maxy then i:=1 else
             if i<=(maxx-1)*maxy then i:=i+maxy else i:=maxy-(maxy*maxx-i)+1;
         #79:i:=maxx*maxy;
         #80:if i<maxx*maxy then i:=i+1 else i:=1;
    end;
  until (zn>#0) and (zn<#254);
  if zn<>#13 then wmenu:=pos(zn,povret) else wmenu:=i;
  MHide;
  wopen(x,y,x1,y1,scr^,false);
  freemem(scr,(x1-x+1)*(y1-y+1)*2);
  window(lo(wmin)+1,hi(wmin)+1,lo(wmax)+1,hi(wmax)+1);
  gotoxy(xpuv,ypuv);
  textattr:=tat;
  cursor(true);
 end;

function wmenu2(poz:byte;Buffer:Pointer):byte;
 type
  TMenuRec=record
            X,Y,XMax,YMax,Col,Cur,Hot:Byte;
            Title:String[30];
            Data:String[10];
           end;
 var
  Menu:^TMenuRec;
  BufStr:^String;
  S:String;
  Title,HotKey:String[80];
  Buff:Pointer;
  I,J,Sirka:Byte;
  PovChar:set of Char;
  C:Char;
  Cr:CrtRec;

 procedure DrawMenu;
  var
   I,Attr:Byte;
   HotPos:Byte;
  begin
   with Menu^ do
   begin
    BufStr:=@Data;
    GotoXY(1,1);
    for I:=1 to YMax do
    begin
     if I=Poz then TextAttr:=Cur else TextAttr:=Col;
     Attr:=TextAttr;
     HotPos:=Pos(HotKey[I],BufStr^);
     Write(Space(XMax+2,' '),^M);
     Write(' '+Copy(BufStr^,1,HotPos-1)); TextAttr:=(TextAttr and $F0) or Hot;
     Write(HotKey[I]);
     TextAttr:=Attr; WriteLn(Copy(BufStr^,HotPos+1,255));
     Inc(LongInt(BufStr),Length(BufStr^)+1);
    end;
   end;
  end;

 begin
  GetCrt(Cr); Cursor(False);
  Menu:=Buffer;
  with Menu^ do
  begin
   BufStr:=@Data; S:=BufStr^; HotKey:='';
   PovChar:=['A'..'Z','0'..'9'];
   for I:=1 to YMax do
   begin
    J:=0; while not ((UpCase(BufStr^[J]) in PovChar)or(J>Byte(BufStr^[0]))) do Inc(J);
    if J<=Byte(BufStr^[0]) then begin PovChar:=PovChar-[UpCase(BufStr^[J])]; HotKey:=HotKey+BufStr^[J]; end;
    Inc(LongInt(BufStr),Length(BufStr^)+1);
   end;
   GetMem(Buff,(YMax+3)*(XMax+5));
   WOpen(X,Y,X+XMax+3,Y+YMax+1,Buff^, True);
   Okno(X,Y,X+XMax+3,Y+YMax+1,Col,$FF,True,Title);
   Window(X+1,Y+1,80,25);
   repeat
    DrawMenu;
    C:=UpCase(ReadKey);
    case C of
        ^[:Poz:=0;
        ^M:C:=^[;
        #0:case ReadKey of
                #$48:if Poz>1 then Dec(Poz) else Poz:=YMax;
                #$50:if Poz<YMax then Inc(Poz) else Poz:=1;
                #$47:Poz:=1;
                #$4F:Poz:=YMax;
           end;
         else if Pos(C,HotKey)>0 then begin Poz:=Pos(C,HotKey); C:=^[; end;
    end;
   until C=^[;
   WOpen(X,Y,X+XMax+3,Y+YMax+1,Buff^, False);
   FreeMem(Buff,(YMax+3)*(XMax+5));
   SetCrt(Cr);
  end;
  WMenu2:=Poz;
 end;

procedure prnscr(naz:string;dopln:boolean);
 var
  vid:tvideo;
  x,y,nas:byte;
  soub:text;
 begin
  if naz='' then Assign(Soub,'PRN') else  assign(soub,naz);
  if dopln and exfile(naz) then append(soub) else rewrite(soub);
  getvideo(vid);
  nas:=1;
  for y:=1 to 25 do
  begin
   for x:=1 to 80 do
    if naz>'' then  write(soub,char(mem[vid.adrvideo:80*nas*(y-1)+(x-1)*nas]))
    else begin
     write(Soub,char(mem[vid.adrvideo:80*nas*(y-1)+(x-1)*nas]));
     delay(30);
    end;
   if naz>'' then writeln(soub)
   else begin
   write(Soub,#13);
   delay(30);
   write(Soub,#10);
   delay(30);
   end;
  end;
  close(soub);
 end;

function ReadStr(S:String; InStr:Byte):String;
 begin
  if InStr<>$FF then CurrInput.PosInStr:=InStr;
  with CurrInput do CtiRetez(S,0,0,PosInStr,MinBufLen,BufLen,OverWrite,ReadMode,RightChars,
                             EndChars,ControlChars,CharFill,WordRec(ReadResult).Lo,WordRec(ReadResult).Hi,Change);
  ReadStr:=S;
 end;

function ReadLnStr(S:String; InStr:Byte):String;
 begin
  ReadLnStr:=ReadStr(S,InStr);
  WriteLn;
 end;

procedure ctiretez(var s:string;x,y:byte;var poz:byte;minlen,maxlen:byte;
                   var prepis:boolean;rezim:rezimset;pripset,
                   konset,konrid:charset;vyplzn:char;var konzn,ridzn:char;
                   var Change:Boolean);

 procedure Pip;
  begin
   if Ton in Rezim then Write(^G);
  end;

 var
  C:Char;
  S1:String[1];
  CSize:Word;
 begin
  Change:=False;
  S1:=' ';
  CSize:=GetCursorSize;
  if Prepis then SetCursorSize($12);
  if X or Y=0 then begin X:=WhereX; Y:=WhereY end;
  if MinLen>MaxLen then begin C:=Char(MaxLen); MaxLen:=MinLen; MinLen:=Byte(C); end;
  S:=Copy(S,1,MaxLen);
  while (Poz>Byte(S[0])+1) do Dec(Poz);
  if Poz=0 then Poz:=1;
  repeat
   if Skryt in Rezim then WriteXY( X, Y, Space(Byte(S[0]),'*'))
    else WriteXY( X, Y, S);
   Write(Space(MaxLen-Byte(S[0]),VyplZn));
   GotoXY(X+Poz-1,Y);
   while not KeyPressed do if @Idle<>nil then Idle;
   if TransVp in Rezim then C:=UpCase(ReadKey) else C:=ReadKey;
   if C=#0 then
   begin
    C:=ReadKey;
    if (C=#$3B)and(@Help<>nil) then Help
    else
    case C of
         #$4B:if Poz > 1 then Dec(Poz) else Pip; {Left}
         #$4D:if Poz <= Byte(S[0]) then Inc(Poz) else Pip; {Right}
         #$47:Poz:=1;
         #$4F:Poz:=Byte(S[0])+1;
         #$53:if Poz<=Byte(S[0]) then begin Change:=True; Delete(S,Poz,1) end else Pip;
         #$52:begin
               Prepis:=not Prepis;
               if Prepis then SetCursorSize($12)
                         else SetCursorSize(CSize);
              end;
         else if C in KonRid then begin KonZn:=#0; RidZn:=C;
                                        if Byte(S[0])>=MinLen then
                                        begin SetCursorSize(CSize); Exit end else Pip end
              else Pip;
    end;
   end else
   case C of
        #$08:if Poz > 1 then begin Change:=True; Dec(Poz); Delete(S,Poz,1); end else Pip;
        #$19:begin Change:=True; S:=''; Poz:=1; end;
        else if C in KonSet then begin KonZn:=C; RidZn:=#0; if Byte(S[0])>=MinLen then
                                                 begin SetCursorSize(CSize); Exit end else Pip end
             else if (C in PripSet)and(Poz<=MaxLen) then
             begin
              Change:=true;
              if Prepis then
              begin S[Poz]:=C; if Poz>Byte(S[0]) then Inc(S[0]); Inc(Poz) end
              else
              begin
               S1[1]:=C;
               Insert(S1,S,Poz);
               S:=Copy(S,1,MaxLen);
               Inc(Poz);
              end;
             end else Pip;
   end;
  until (AutoKon in Rezim) and (Poz=MaxLen+1);
  WriteXY(X,Y,S);
  SetCursorSize(CSize);
  KonZn:=#0; RidZn:=#$4D;
 end;

procedure getvideo(var videomod:tvideo);
 var
  Mode:Byte absolute $0:$0449;
 begin
  with videomod do begin
   case Mode of
     0..6:adrvideo:=$b800;
    7..10:adrvideo:=$b000;
   11..16:adrvideo:=$a000;
   end;
   case Mode of
         0,1:begin maxx:=40;maxy:=25;colors:=16;end;
         2,3:begin maxx:=80;maxy:=25;colors:=16;end;
         4,5:begin maxx:=320;maxy:=200;colors:=4;end;
         6:begin maxx:=640;maxy:=200;colors:=2;end;
       7..$0c:begin maxx:=80;maxy:=25;colors:=3;end;
       $0d:begin maxx:=320;maxy:=200;colors:=16;end;
       $0e:begin maxx:=640;maxy:=200;colors:=16;end;
       $0f:begin maxx:=640;maxy:=350;colors:=3;end;
       $10:begin maxx:=640;maxy:=350;colors:=4;end;
   end;
   color:=Mode<>7;
   text:=Mode in [0..3,7];
  end;
 end;

procedure wopen(x1,y1,x2,y2:byte;var buffer;kam:boolean);
 var
  i:word;
  vid:tvideo;
  nas:byte;
 begin
  getvideo(vid);
  nas:=2;
  if kam then
  begin
   for i:=0 to y2-y1 do
   move(mem[vid.adrvideo:nas*80*(i+y1-1)+(x1-1)*nas],
        mem[seg(buffer):(x2-x1+1)*nas*i+ofs(buffer)],
        (x2-x1+1)*nas);
  end else
  begin
   for i:=0 to y2-y1 do
   move(mem[seg(buffer):(x2-x1+1)*nas*i+ofs(buffer)],
        mem[vid.adrvideo:nas*80*(i+y1-1)+(x1-1)*nas],
        (x2-x1+1)*nas);
  end;
 end;

procedure writexyJ(x,y:byte;TextJustify:TJustify;co:string);
 begin
  if TextJustify=tjRight then Dec(X,Byte(Co[0])-1)
   else if TextJustify=tjCenter then Dec(X,Byte(Co[0]) shr 1);
  gotoxy(x,y);
  write(co);
 end;

procedure writexy(x,y:byte;co:string);
 begin
  gotoxy(x,y);
  write(co);
 end;

procedure WriteXYL(X,Y,L:Byte; Co:String);
 var
  I:Byte;
 begin
  while Co<>'' do
   if Byte(Co[0])>L then
   begin
    I:=L+1;
    while Co[I]<>' ' do Dec(I);
    WriteXY(X,Y,Copy(Co,1,I-1));
    Delete(Co,1,I);
    Inc(Y);
   end else begin WriteXY(X,Y,Co); Co:=''; end;
 end;

procedure WriteC(Co:String);
 var T:Byte;
 begin
  while Co<>'' do
  begin
   Write(Copy(Co,1,Pos('~',Co+'~')-1));
   if Pos('~',Co)>0 then begin T:=TextAttr; TextAttr:=XTextAttr; XTextAttr:=T end;
   Delete(Co,1,Pos('~',Co+'~'));
  end;
 end;

procedure WriteXYC(X,Y:byte;co:String);
 var T:Byte;
 begin
  GotoXY(X,Y);
  WriteC(Co);
 end;

procedure ram(x1,y1,x2,y2:byte;dual:boolean;title:string);
 const
  rr1:array [0..1] of char=(#218,#201);
  rr2:array [0..1] of char=(#191,#187);
  rr3:array [0..1] of char=(#217,#188);
  rr4:array [0..1] of char=(#192,#200);
  rch:array [0..1] of char=(#196,#205);
  rcv:array [0..1] of char=(#179,#186);
 var
  b:byte absolute dual;
  i:byte;
 begin
  asm
   CLI
  end;
  writexy(x1,y1,rr1[b]);
  for i:=x1+1 to x2-1 do write(rch[b]);
  write(rr2[b]);
  writexy(x1,y2,rr4[b]);
  for i:=x1+1 to x2-1 do write(rch[b]);
  write(rr3[b]);
  for i:=y1+1 to y2-1 do begin writexy(x1,i,rcv[b]);writexy(x2,i,rcv[b]);end;
  writexy(x1+trunc((x2-x1+1-length(title))/2),y1,copy(title,1,x2-x1));
  gotoxy(x1+1,y1+1);
  asm
   STI
  end;
 end;

procedure okno(x,y,x1,y1,pozadi,pismo:byte;dual:boolean;title:string);
 begin
  window(x,y,x1,y1);
  if Pismo=$FF then TextAttr:=Pozadi else
  begin
   textbackground(pozadi);
   textcolor(pismo);
  end;
  clrscr;
  if y1< 25 then window(x,y,x1,y1+1) else window(x,y,x1+1,y1);
  ram(1,1,x1-x+1,y1-y+1,dual,title);
 end;
{
function Menu (X,Y,Pozadi,Pismo : byte; Pol:string; Jmeno:string;
               Dual:boolean): byte;

var PolLen, PolNum, PolVyb : byte;
    i,Len                  : byte;
    VideoMod               : TVideo;
    Zn                     : char;
    ev                     : tevent;

procedure TiskPol;

var i : byte;

procedure InvVideo;

begin
  textbackground(pismo);
  textcolor(pozadi);
end;

procedure NormVideo;

begin
  textbackground(pozadi);
  textcolor(pismo);
end;

begin
  hidemouse;
  Window(X+1,Y+2,X+PolLen+1,Y+PolNum+2); GotoXY(1,1);
  Len:=0; if PolVyb=Len then InvVideo; clreol;
  for i:=1 to length(Pol)-1 do
    if Pol[i]<' ' then begin writeln; inc(Len);
                             if PolVyb=Len then InvVideo else NormVideo;
                             clreol;  end
                  else write(Pol[i]);
  NormVideo;
  showmouse;
end;

begin
  initevents; showmouse;
  Len:=0; PolLen:=0; PolNum:=0;   (* urci max delku 1 polozky a pocet pol *)
  for i:=1 to length(Pol) do
     if Pol[i]<' ' then
            begin inc(PolNum); if Len>PolLen then PolLen:=Len; Len:=0; end
                   else inc(Len);
  (*sem vlozit prekopirovani video pameti *)
  Okno(X,Y,X+PolLen+2,Y+PolNum+2,Pozadi,Pismo,Dual,Jmeno);
  Cursor(false);
  PolVyb:=0;
  TiskPol;                        (* vytiskne vsechny polozky *)
  Zn:=#0;
  repeat
   if KeyPressed then
    begin
      Zn:=readkey;
      if Zn=#0 then
       begin
        Zn:=readkey;
        case Zn of
         #79,#77 : dec(PolVyb);
         #71,#75 : PolVyb:=0;
         #80     : if PolVyb<PolNum-1 then inc(PolVyb) else PolVyb:=0;
         #72     : if PolVyb>0 then dec(PolVyb) else PolVyb:=PolNum-1;
        end;
        Zn:=' ';
       end
               else
       begin
        Len:=0;
        if upcase(Zn)=upcase(Pol[1]) then begin Zn:=#13; PolVyb:=0; end
           else
            for i:=1 to length(Pol)-1 do
             begin
              if Pol[i]=#0 then inc(Len);
              if (Pol[i]=#0)and(upcase(Zn)=upcase(Pol[i+1])) then
                begin Zn:=#13; PolVyb:=Len; end;
             end;
       end;
      TiskPol;
    end;
   getmouseevent(ev);
   if (ev.what<>0)and(ev.buttons=1) then
    begin
      if (ev.where.x in [X..X+PolLen])and(ev.where.y in [Y+1..Y+PolNum])
          then PolVyb:=ev.where.y-Y-1;
      TiskPol;
    end;
   if (@Idle<>nil)and(Ev.What=0)and(Zn<>#27)and(Zn<>#13) then Idle;
  until (ev.double)or(ev.buttons=2)or(Zn=#27)or(Zn=#13);
  if (ev.buttons=1)or(Zn=#13) then Menu:=PolVyb  else Menu:=255;
  GetVideo(VideoMod);
  with VideoMod do Window(1,1,MaxX,MaxY);
  hidemouse; doneevents;
  Cursor(true);
end;}

procedure GetCrt(var Cr:CrtRec);
 begin
  with Cr do
  begin
   WMax:=WindMax;
   WMin:=WindMin;
   CSize:=GetCursorSize;
   CX:=WhereX;
   CY:=WhereY;
   Move(Mem[0:$0449],VMode,1);
   Color:=TextAttr;
  end
 end;

procedure SetCrt(var Cr:CrtRec);
 begin
  with Cr do
  begin
   if VMode<>Mem[0:$0449] then TextMode(VMode);
   WindMin:=WMin;
   WindMax:=WMax;
   SetCursorSize(CSize);
   GotoXY(CX,CY);
   TextAttr:=Color;
  end;
 end;

procedure XTextColor(Color:Byte);
 begin
  XTextAttr:=(XTextAttr and $F0) or Color;
 end;

procedure XTextBackGround(Color:Byte);
 begin
  XTextAttr:=(XTextAttr and $0F) or (Color shl 4);
 end;

procedure ClearBox(X,Y,X1,Y1,Attr:Byte);
 var
  C:CrtRec;
 begin
  GetCrt(C);
  Window(X,Y,X1,Y1);
  TextAttr:=Attr;
  ClrScr;
  SetCrt(C);
 end;

procedure BarGraph(X,Y,Size:Byte; Kolik, ZKolika:LongInt);
 begin
  WriteXY(X,Y,Space(Size,'°'));
  WriteXY(X,Y,Space(Round(Kolik/ZKolika*Size),'Û')+#8);
 end;

begin
 XTextAttr:=TextAttr;
 @Idle:=nil;
 @Help:=nil;
 CurrInput:=StandartInput;
end.