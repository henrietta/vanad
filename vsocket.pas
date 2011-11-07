unit VSocket;

{$mode delphi}

interface

uses
  Classes, SysUtils, blcksock, synsock, Configuration;

const
  INVALID_SOCKET = synsock.INVALID_SOCKET;
                 // don't assume it's any particular value

type
    TSocket = synsock.TSocket;

procedure Initialize;
procedure Finalize;
function Accept(timeout: Cardinal): TSocket;

implementation
var
   serverSocket: TTCPBlockSocket;

function Accept(timeout: Cardinal): TSocket;
begin
  if serverSocket.CanRead(timeout) then
  begin
    result := serverSocket.Accept();
    Exit;
  end;
  result := 0;
end;

procedure Finalize;
begin
  serverSocket.CloseSocket();
end;

procedure Initialize;
var
   i: Cardinal;
begin
  serverSocket := TTCPBlockSocket.Create();
  serverSocket.CreateSocket();
  serverSocket.Bind(Configuration.GetS('TCP', 'ListeningInterface'),
                    Configuration.GetS('TCP', 'ListeningPort'));
  serverSocket.Listen();
end;

end.

