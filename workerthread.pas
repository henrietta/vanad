unit workerthread;

{$mode delphi}

interface

uses
    VSocket, Classes, CommonData,
             {$IFDEF UNIX}sockets{$ENDIF}
             {$IFDEF Windows}winsock{$ENDIF};

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
label
     DisposeSocket, NothingDetected, ReadyForAnotherGo;
var
  RequestCode: Byte;
  TablespaceID: Byte;

  KeyLength, ValueLength: Cardinal;

  Key, Value: AnsiString;
begin
  while not self.Terminated do
  begin

    while True do
    begin
        self.socket := VSocket.Accept(1000);
        if self.socket = nil then goto NothingDetected;

    ReadyForAnotherGo:

        RequestCode := self.socket.RecvByte(SocketOpTimeout);
        if self.socket.LastError > 0 then goto DisposeSocket;

        TablespaceID := self.socket.RecvByte(SocketOpTimeout);
        if self.socket.LastError > 0 then goto DisposeSocket;

        KeyLength := ntohl(self.socket.RecvInteger(SocketOpTimeout));
        if self.socket.LastError > 0 then goto DisposeSocket;

        ValueLength := ntohl(self.socket.RecvInteger(SocketOpTimeout));
        if self.socket.LastError > 0 then goto DisposeSocket;

        Key := self.socket.RecvBufferStr(KeyLength, SocketOpTimeout);
        if self.socket.LastError > 0 then goto DisposeSocket;

        if ValueLength > 0 then
        begin
            Value := self.socket.RecvBufferStr(ValueLength, SocketOpTimeout);
            if self.socket.LastError > 0 then goto DisposeSocket;
        end;

        if RequestCode = 0 then
        begin
             Value := tablespace[TablespaceID].Read(Key);
             if Value = '' then
             begin
                  self.socket.SendByte(1);
                  self.socket.SendInteger(0);
             end else
             begin
                  self.socket.SendByte(0);
                  self.socket.SendInteger(htonl(length(Value)));
                  self.socket.SendString(Value);
             end;
        end else
        if RequestCode = 1 then
        begin
             tablespace[TablespaceID].Assign(Key, Value);
             self.socket.SendByte(0);
             self.socket.SendInteger(0);
        end else
        if RequestCode = 2 then
        begin
             tablespace[TablespaceID].Assign(Key, '');
             self.socket.SendByte(0);
             self.socket.SendInteger(0);
        end;

        if (RequestCode and $80) > 0 then
           break
        else
            goto ReadyForAnotherGo;
    end;

DisposeSocket:
    self.socket.Destroy();
NothingDetected:
  end;
end;

constructor TWorkerThread.Create(id: Cardinal);
begin
  self.socket := nil;
  self.id := id;

  inherited Create(True);
end;

end.

