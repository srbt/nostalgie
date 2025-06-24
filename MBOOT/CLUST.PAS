uses Prevody;
var
 I:Byte;
begin
 WriteLn(^J' Sec/Clust  Byte/Clust  Max. disk size ');
 for I:=0 to 6 do
  WriteLn((1 shl I):6,Word(1 shl I)*512:12,Long_Com(LongInt($FFF5)*(1 shl I)*512,20));
end.