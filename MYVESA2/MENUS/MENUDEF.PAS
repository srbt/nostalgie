uses Prevody;
type TMenuHead=array[1..8] of Char;
const
 Head:TMenuHead='AsMnuF.'#26;
 Numbers:array ['0'..'9'] of Word=($8100,$7800,$7900,$7A00,$7B00,$7C00,$7D00,$7E00,$7F00,$8000);
 Chars:array ['A'..'Z'] of Word=
       ($1E00,$3000,$2E00,$2000,$1200,$2100,$2200,$2300,$1700,$2400,$2500,
        $2600,$3200,$3100,$1800,$1900,$1000,$1300,$1F00,$1400,$1600,$2F00,
        $1100,$2D00,$1500,$2C00);
 ASpace=$0200;

type
 TKeyItem=record
           S:String[12];
           K:Word;
          end;
type
 PMenuBoxDef=^TMenuBoxDef;
 PMenuItem=^TMenuItem;
 TMenuItem=record
            Key:Word;
            Next:PMenuBoxDef;
            S:String[25];
           end;

 TMenuBoxDef=record
              XSize,YSize:Byte;
              Item:array [1..25] of TMenuItem;
             end;

 PMenuBarItem=^TMenuBarItem;
 TMenuBarItem=record
               HotKey:Word;
               XPoz:Byte;
               Next:PMenuBoxDef;
               S:String[25];
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

var
 F:Text;
 Def:TMenuBarDef;
 S:String;
 GXPoz:Byte;
 Keys:array [1..200] of TKeyItem;
 KeyCount:Byte;
 I:Byte;
 C:Char;
 S2:String;
 UsedKeys:TMenuUsedKeys;

procedure AddToBox(Poz:Byte; var S1:String; Next:PMenuBoxDef);
 begin
  FillChar(Next^,SizeOf(Next^),0);
  with Next^ do
  begin
   while (S1[Poz]=' ') do
   begin
    Inc(YSize);
    with Item[YSize] do
    begin
     if S1[Poz+1]='=' then
     begin
      Key:=$FFFF; S:='Í';
     end else
     if S1[Poz+1]='-' then
     begin
      Key:=$FFFF; S:='Ä';
     end else
     begin
      S2:=S1;
      S:=Trim(GetStr(S2))+'|';
      S2:=Trim(S2);
      if S2[1]<>'$' then S:=S+S2;
      XSize:=Max(XSize,Byte(S[0])+1);
      S2:=Upper(S2);
      if S2[1]='^' then
      begin
       Key:=Byte(S2[2])and 31;
       if S2[0]>#2 then if S2[3]='^' then Key:=Key or ((Byte(S2[4])and 31) shl 8)
                                     else Key:=Key or ((Byte(S2[3])and 31) shl 8)
                   else UsedKeys.Key[UsedKeys.Count]:=Key;
      end else
      if S2[1]='$' then Key:=Str_Long(S2) else
      begin
       I:=1; while (I<=KeyCount)and(S2<>Keys[I].S) do Inc(I);
       Key:=Keys[I].K;
       if Key<>0 then
       begin
        Inc(UsedKeys.Count);
        UsedKeys.Key[UsedKeys.Count]:=Key;
       end;
      end;
     end;
     if Eof(F) then Exit;
     ReadLn(F,S1);
     if S1[Poz+1]=' ' then
     begin
      S:=S+^P;
      XSize:=Max(XSize,Byte(S[0])+1);
      New(Next);
      AddToBox(Poz+1,S1,Next);
     end;
    end;
   end;
  end;
 end;

procedure AddToBar(var S1:String);
 begin
  with Def do
  begin
   Inc(ItemCount);
   New(Item[ItemCount]);
   with Item[ItemCount]^ do
   begin
    XPoz:=GXPoz;
    S:=S1;
    Inc(GXPoz,Byte(S[0]));
    C:=UpCase(S[Pos('~',S)+1]);
    case C of
       '0'..'9':HotKey:=Numbers[C];
       'A'..'Z':HotKey:=Chars[C];
            'ð':HotKey:=ASpace;
    end;
    ReadLn(F,S1);
    New(Next);
    AddToBox(1,S1,Next);
   end;
  end;
 end;

procedure Save;
 var
  FOut:File;
 procedure WriteMenuBox(N:PMenuBoxDef);
  var
   J:Byte;
  begin
   if N=nil then Exit;
   BlockWrite(FOut,N^,2+4*N^.YSize);
   for J:=1 to N^.YSize do
   begin
    BlockWrite(FOut,N^.Item[J],7+Byte(N^.Item[J].S[0]));
    WriteMenuBox(N^.Item[J].Next);
   end;
  end;
 begin
  Assign(FOut,ParamStr(2));
  ReWrite(FOut,1);
  BlockWrite(FOut,Def,4*Def.ItemCount+10);
  for I:=1 to Def.ItemCount do 
  begin
   BlockWrite(FOut,Def.Item[I]^,8+Byte(Def.Item[I]^.S[0]));
   WriteMenuBox(Def.Item[I]^.Next);
  end;
  BlockWrite(FOut,UsedKeys,UsedKeys.Count*2+2);
  Close(FOut);
 end;

begin
 WriteLn('Kompilator menu systemu VesaMenu');
 if ParamCount<2 then
 begin
  WriteLn(' Syntaxe MENUDEF <soubor_definic> <soubor_menu>');
  WriteLn(' Program vyzaduje soubor MENUDEF.KEY !');
  Halt(1);
 end;
 Write('Prekladam ... ');
 FillChar(Keys,SizeOf(Keys),0);
 Assign(F,'MENUDEF.KEY');
 Reset(F);
 KeyCount:=0;
 while not Eof(F) do
 begin
  ReadLn(F,S);
  Inc(KeyCount);
  Keys[KeyCount].S:=Upper(Copy(S,1,Pos('=',S)-1));
  Keys[KeyCount].K:=Str_Long(Copy(S,Pos('=',S)+1,50));
 end;
 Close(F);
 GXPoz:=2;
 FillChar(Def,SizeOf(Def),0);
 FillChar(UsedKeys,SizeOf(UsedKeys),0);
 Def.Head:=Head;
 Assign(F,ParamStr(1));
 Reset(F);
 ReadLn(F,S);
 while not Eof(F) do
 begin
  AddToBar(S);
 end;
 Close(F);
 Save;
 WriteLn('OK');
end.