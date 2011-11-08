unit workerthread;

{$mode delphi}

interface

uses
    VSocket, Classes, CommonData,
             {$IFDEF UNIX}sockets{$ENDIF}
             {$IFDEF Windows}winsock{$ENDIF};

type
    TRequestHeader = packed record
        RequestCode: Byte;
        TablespaceID: Byte;
        KeyLength: DWORD;
        ValueLength: DWORD;
    end;

    TResponseHeader = packed record
        ResponseCode: Byte;
        DataLength: DWORD;
    end;

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
     DisposeSocket;
var
  request: TRequestHeader;

  Key, Value: AnsiString;
begin
  Key := '';
  Value := '';
  while not self.Terminated do
  begin
    self.socket := VSocket.Accept(1000);
    if self.socket = nil then continue;

    request.RequestCode := self.socket.RecvByte(4000);
    if self.socket.LastError > 0 then goto DisposeSocket;

    request.TablespaceID := self.socket.RecvByte(4000);
    if self.socket.LastError > 0 then goto DisposeSocket;


    request.KeyLength := ntohl(self.socket.RecvInteger(4000));
    if self.socket.LastError > 0 then goto DisposeSocket;

    request.ValueLength := ntohl(self.socket.RecvInteger(4000));
    if self.socket.LastError > 0 then goto DisposeSocket;

    Key := self.socket.RecvBufferStr(request.KeyLength, 4000);
    if self.socket.LastError > 0 then goto DisposeSocket;

    if request.ValueLength > 0 then
    begin
        Value := self.socket.RecvBufferStr(request.ValueLength, 4000);
        if self.socket.LastError > 0 then goto DisposeSocket;
    end;

    if request.RequestCode = 0 then
    begin
         Value := tablespace[request.TablespaceID].Read(Key);
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
    if request.RequestCode = 1 then
    begin
         tablespace[request.TablespaceID].Assign(Key, Value);
         self.socket.SendByte(0);
         self.socket.SendInteger(0);
    end else
    if request.RequestCode = 2 then
    begin
         tablespace[request.TablespaceID].Assign(Key, '');
    end;

DisposeSocket:
    if self.socket.LastError > 0 then writeln(self.socket.GetErrorDesc(self.socket.lasterror));
    self.socket.Destroy();
  end;
end;

constructor TWorkerThread.Create(id: Cardinal);
begin
  self.socket := nil;
  self.id := id;

  inherited Create(True);
end;

end.

