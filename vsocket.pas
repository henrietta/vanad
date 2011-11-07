unit VSocket;
{    does all server socketry   }

{$mode delphi}

interface

uses
  Classes, SysUtils, blcksock, synsock, Configuration;

const
  INVALID_SOCKET = synsock.INVALID_SOCKET;
                 // don't assume it's any particular value

type
    TVSocket = TTCPBlockSocket;

procedure Initialize;
procedure Finalize;
function Accept(timeout: Cardinal): TVSocket;

implementation
var
   serverSocket: TTCPBlockSocket;

function Accept(timeout: Cardinal): TVSocket;
begin
  if serverSocket.CanRead(timeout) then
  begin
    result := TTCPBlockSocket.Create();
    result.Socket := serverSocket.Accept();
    result.GetSins();
    Exit;
  end;
  result := nil;
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

