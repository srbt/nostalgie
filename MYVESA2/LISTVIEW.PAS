unit ListView;

interface

uses MyVesa;

type
 PListView=^TListView;
 TListView=object(TTextView)
            LineCount:LongInt;
            CurrLine:LongInt;
            TopLine:LongInt;
            constructor Init(AX,AY:Byte);
            procedure DrawAll; virtual;
            procedure Run(var W:Word); virtual;
            function CheckLine(Index:LongInt):Boolean; virtual;
            procedure GetLine(Index:LongInt; var Line:String); virtual;
           end;

implementation

constructor TListView.Init(AX,AY:Byte);
 begin
  TTextView.Init(AX,AY);
  LineCount:=0;
  CurrLine:=0;
  TopLine:=0;
 end;

procedure TListView.DrawAll;
 var
  Y:Byte;
  Line:String;
  CL:LongInt;
  TA:Byte;
 begin
  if TopLine<0 then TopLine:=0;
  ClrScr;
  CL:=TopLine;
  for Y:=1 to Lines do
  begin
   while (CL<LineCount) and not CheckLine(CL) do Inc(CL);
   if (CL<LineCount) then
   begin
    GetLine(CL,Line);
    if CL=CurrLine then
    begin
     TA:=TextAttr; TextAttr:=XTextAttr;
     ClrLine(Y);
    end;
    WriteXY(1,Y,Line);
    if CL=CurrLine then TextAttr:=TA;
    Inc(CL);
   end;
  end;
  TTextView.DrawAll;
 end;

procedure TListView.Run(var W:Word);
 begin
 end;

function TListView.CheckLine(Index:LongInt):Boolean;
 begin
  CheckLine:=True;
 end;

procedure TListView.GetLine(Index:LongInt; var Line:String);
 begin
  Str(Index:6,Line);
 end;

end.