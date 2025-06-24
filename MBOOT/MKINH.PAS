uses Objects, Header, Dos;
var
 Lines:array [1..50] of String;
 B,C,Line,L:Byte;
 Size:Word;
 {$I MKINH.INH}
begin
 Assign(Output,'CON');
 ReWrite(Output);
 Head:='Universal compiler utilities (MKINH)  Version 1.0  ARNAY Software';
 HelpTxt:=@cHelpTxt;
 WriteHead(heHalt);
 Assign(Output,'');
 ReWrite(Output);
 C:=0;
 Line:=1;
 Size:=0;
 while not Eof do
 begin
  if Line<50 then
  begin ReadLn(Lines[Line]); Inc(Size,Byte(Lines[Line][0])+1); Inc(Line); end
  else begin WriteLn('Prilis dlouhy text !');Halt(1); end;
 end;
 WriteLn('const cHelpTxt:array [1..',Size,'] of Char = (');
 Write('   ');
 for L:=1 to Line-1 do
 begin
  for B:=1 to Byte(Lines[L][0]) do
  begin
   if Lines[L][B]<#30 then Write('#',Byte(Lines[L][B]),',')
                         else Write('''',Lines[L][B],''',');
   Inc(C,4);
   if C>75 then begin C:=0; Write(^M^J'   '); end;
  end;
  if L<Line-1 then Write('^M,'); Inc(C,3);
 end;
 WriteLn('^Z);');
end.