unit VesaInpu;

interface
uses MyVesa, Dos_IO;

const
 viQueueLen = 32;
type
 PInputQueue=^TInputQueue;
 TInputQueue=object
              Id:Word;
              Next:PInputQueue;
              Q:array [1..viQueueLen] of Word;
              Head,Tail:Word;
              constructor Init(ANext:PInputQueue);
              procedure PutEvent(W:Word); virtual;
              function GetEvent:Word; virtual;
              destructor Done; virtual;
             end;
 PKeyboardQueue=^TKeyboardQueue;
 TKeyboardQueue=object(TInputQueue)
                 function GetEvent:Word; virtual;
                end;

var
 EventSource:Word;
implementation

constructor TInputQueue.Init(ANext:PInputQueue);
 begin
  Id:=0;
  Head:=0; Tail:=0;
  Next:=ANext;
 end;

destructor TInputQueue.Done;
 begin
 end;

procedure TInputQueue.PutEvent(W:Word);
 begin
  Inc(Head); if Head>viQueueLen then Head:=1;
  Q[Head]:=W;
 end;

function TInputQueue.GetEvent:Word;
 begin
  EventSource:=Id;
  if Tail=Head then
  begin
   if Next=nil then GetEvent:=0 else GetEvent:=Next^.GetEvent;
  end else
  begin
   Inc(Tail); if Tail>viQueueLen then Tail:=1;
   GetEvent:=Q[Tail];
  end;
 end;

function TKeyboardQueue.GetEvent:Word;
 begin
  EventSource:=Id;
  if Tail<>Head then GetEvent:=TInputQueue.GetEvent else
  if IFKey<>0 then GetEvent:=GetKey else
  if Next=nil then GetEvent:=0 else GetEvent:=Next^.GetEvent;
 end;

end.