uses Config;

var
 I:Word;
 L:LongInt;
begin
 L:=MemAvail;
 InitConfig(ParamStr(1),ParamStr(2));
 WriteLn(ConfigCount,' : ',L-MemAvail);
 for I:=0 to ConfigCount do WriteLn('<',ConfigStr(I),'>');
 WriteLn(GetConfig('KLAVESNICE'));
 DoneConfig;
end.