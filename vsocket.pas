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
   mutex: TMultiReadExclusiveWriteSynchronizer;

function Accept(timeout: Cardinal): TVSocket;
var
   s: TSocket;
begin
  mutex.BeginWrite();    // this will lock, so stopping the service
                         // can take up to <worker threads> seconds

                         // works for me, so far
  if serverSocket.CanRead(timeout) then
  begin
        result := TTCPBlockSocket.Create();
        result.socket := serverSocket.Accept();
        mutex.EndWrite();

        result.GetSins();
        Exit;
  end;
  mutex.EndWrite();
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
  mutex := TMultiReadExclusiveWriteSynchronizer.Create();

  serverSocket := TTCPBlockSocket.Create();
  serverSocket.CreateSocket();
  serverSocket.EnableReuse(True);
  serverSocket.Bind(Configuration.GetS('TCP', 'ListeningInterface'),
                    Configuration.GetS('TCP', 'ListeningPort'));
  serverSocket.SocksTimeout := 1;
  serverSocket.Listen();
end;

end.

