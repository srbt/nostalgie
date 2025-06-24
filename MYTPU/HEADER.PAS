unit Header;
 { Knihovna pro v˜pis standardn¡ hlavi‡ky a n povˆdn‚ho textu
   po parametru programu /?. }

interface
type
 PChar=^TChar;
 TChar=Char;
const
 Head:String[80]=''; { Sem lze naplnit text hlavi‡ky programu }
 HelpTxt:PChar=nil;  { Text n povˆdy vypsan‚ po parametru /? }

var
 Params:^String;    { P©¡kazov  © dka programu }

const
 heHalt=0;
 heCont=1;
 { Konstanty ur‡uj¡c¡ chov n¡ procedury WriteHead, pokud
   byl v p©¡kazov‚ © dce uveden parametr /? }

procedure WriteHead(Ex:Byte);
 { Vyp¡¨e hlavi‡ku, p©¡padnˆ n povˆdn˜ text a v z vislosti
   na parametru buƒ zkon‡¡ (heHalt) nebo pokra‡uje d l (heCont) }

implementation

procedure WriteHead(Ex:Byte);
 begin
  if Head<>'' then WriteLn(Head);
  if (Pos('/?',Params^)>0)and(HelpTxt<>nil) then
  begin
   WriteLn;
   while HelpTxt^<>^Z do
   begin
    Write(HelpTxt^);
    if HelpTxt^=^M then Write(^J);
    Inc(HelpTxt);
   end;
   WriteLn;
   if Ex=heHalt then Halt;
  end;
 end;

begin
 Params:=Ptr(PrefixSeg,$80);
end.