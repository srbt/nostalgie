uses Config, Prevody;
const
 MaxFrameSize=8;

type
 PFrameType=^TFrameType;
 TFrameType=record
             FrameSize:Byte;
             Left,Up,Right,Down:array [1..MaxFrameSize] of Byte;
            end;
 PFrames=^TFrames;
 TFrames=record
          FrameCount:Byte;
          Frame:array [0..36] of TFrameType;
         end;

var
 Frames:TFrames;
 F:File;
 I,J:Byte;
 S:String;
 Id:String[1];

procedure Compile;
 begin
  Id:='0';
  while GetConfig('RAM'+Id)<>'' do
  begin
   S:=GetConfig('RAM'+Id);
   with Frames do
    with Frame[FrameCount] do
    begin
     FrameSize:=GetInt(S);
     if FrameSize>MaxFrameSize then WriteLn(' Ramecek c.',I,' je prilis siroky !');
     S:=GetConfig('RAM'+Id+'L');
     for I:=1 to FrameSize do Left[I]:=GetInt(S);
     S:=GetConfig('RAM'+Id+'R');
     for I:=1 to FrameSize do Right[I]:=GetInt(S);
     S:=GetConfig('RAM'+Id+'U');
     for I:=1 to FrameSize do Up[I]:=GetInt(S);
     S:=GetConfig('RAM'+Id+'D');
     for I:=1 to FrameSize do Down[I]:=GetInt(S);
     Write('.');
     Inc(FrameCount);
     if FrameCount>36 then
     begin
      WriteLn('Maximalni pocet ramecku je 36 !'); Exit;
     end;
    end;
    if Id[1]='9' then Id:='A' else Inc(Id[1]);
   end;
  WriteLn(' OK');
 end;

begin
 FillChar(Frames,SizeOf(Frames),0);
 InitConfig('FRAMES',ParamStr(1));
 S:=GetConfig('FILENAME');
 if S='' then
 begin
  WriteLn('Definice ramecku nenalezena.');
  Exit;
 end;
 S:=AddExt(S,'FRA');
 Write('Vytvarim soubor ',S,'... ');
 Assign(F,S);
 ReWrite(F,1);
 WriteLn('OK');
 Write('Prevadim data');
 Compile;
 Write('Zapisuji ',Frames.FrameCount*SizeOf(TFrameType)+1,' bajtu...');
 BlockWrite(F,Frames,Frames.FrameCount*SizeOf(TFrameType)+1);
 Close(F);
 WriteLn(' OK');
end.