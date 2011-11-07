unit workerthread;

{$mode delphi}

interface

uses
    VSocket, Classes;

type
    TWorkerThread = class(TThread)
      private
        socket: TVSocket;
        id: Cardinal;
      protected
        procedure Execute(); override;
      public
        constructor Create(id: Cardinal);
    end;

implementation
procedure TWorkerThread.Execute();
begin
  while not self.Terminated do
  begin
    self.socket := VSocket.Accept(1000);
    if self.socket = nil then continue;



  end;
end;

constructor TWorkerThread.Create(id: Cardinal);
begin
  self.socket := nil;
  self.id := id;

  inherited Create(True);
end;

end.

