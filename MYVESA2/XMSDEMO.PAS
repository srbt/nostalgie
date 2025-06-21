uses XMSApi, Prevody;
var
 Handle:Word;
 P1,P2:TXMSPointer;
 A:String;
 I:LongInt;
begin
 WriteLn(XMSPresent);
 WriteLn(Long_Hex(Bcd_Dec(Hi(XMSVersion)),2),'.',Long_Hex(Bcd_Dec(Lo(XMSVersion)),2));
 WriteLn(XMSMemAvail*Kilo);
 WriteLn(XMSMaxAvail*Kilo);
 Handle:=XMSGetMem(1);
 WriteLn(Handle,XMSMemAvail*Kilo:10);
 Ptr_XMSPtr(@A,P1);
 XMSPtr(Handle,0,P2);
 A:='No nazdar !';
 XMSMove(P1,P2,SizeOf(A));
 A:='';
 XMSMove(P2,P1,SizeOf(A));
 WriteLn('"',A,'" ',Long_Hex(XMSErr,2));
 XMSFreeMem(Handle);
 WriteLn(XMSMemAvail*Kilo:10);
 WriteLn(XMSErr);
 WriteLn('MAX');
 Handle:=XMSGetMem(60000);
 WriteLn(Handle,':',Long_Hex(XMSErr,2));
 A:='NNNN';
 Ptr_XMSPtr(@A[1],P1);
 for I:=1 to 15000*1000 do
 begin
  XMSPtr(Handle,I*4,P2);
  XMSMove(P1,P2,SizeOf(I));
 end;
 WriteLn(Long_Hex(XMSErr,2));
 ReadLn;
 XMSFreeMem(Handle);
end.