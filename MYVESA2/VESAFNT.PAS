uses MyVesa, VesaDraw, Prevody;
var
 PF:TVesaBGIFont;
 PD:TVesaDraw;
 Txt:TTextView;
 I:Word;
 T1:LongInt;
 T2:LongInt absolute 0:$46C;
begin
 InitVesaGraph(640,480,16);
 if VesaResult<>vsOk then Halt(1);
 Txt.Init(30,5);
 Txt.MoveTo(0,100);
 PD.Init;
 PD.MoveTo(50,50);
 PF.Init('L:\TP\BGI\Goth.CHR');
 PF.SetTextHeight(40);
 PF.OutText(@PD,'Ahoj krokod˜le !');
 PD.XPoz:=0; PD.YPoz:=PF.TextHeight('H');
 PD.RawLineTo(GetMaxX,PD.YPoz);
 PD.XPoz:=310; PD.YPoz:=310;
 PD.RawEllipse(300,300);
 T1:=T2;
 PD.XPoz:=20;
{ for I:=1 to 10000 do}
 begin
  PF.OutText(@PD,'Ahoj krokod˜le !');
 end;
 T1:=T2-T1;
 Txt.WriteXY(1,1,'Top = '+Long_Str(PF.Header^.Top,2)+'  Bottom = '+Long_Str(ShortInt(PF.Header^.Bottom),2));
 Txt.WriteXY(1,2,'Base = '+Long_Str(PF.Header^.Base,2));
 Txt.WriteXY(1,3,'Time = '+Long_Str(T1,5));
 Txt.Draw;
 ReadLn;
 PF.Done;
 PD.Done;
 CloseVesaGraph;
end.