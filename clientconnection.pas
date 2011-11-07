unit ClientConnection;

{$mode delphi}

interface

uses
  Classes, VSocket;

type
  TClientConnection = class(TThread)
  private
    socket: TSocket;
  public
    constructor Create(sock: TSocket);
    procedure Execute;
  end;

var
  connections: Cardinal = 0;        // amount of connections now

implementation
procedure TClientConnection.Execute();
begin

end;

constructor TClientConnection.Create(sock: TSocket);
begin
     self.socket := sock;
     inherited Create(False);

     asm
        {$IFDEF CPU32}
                mov eax, 1
                lock xadd connections, eax
        {$ELSE}
                 Got no idea how to do it
        {$ENDIF}
     end;
end;

end.


