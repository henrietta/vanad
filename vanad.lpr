program vanad;
{
        Basic idea:
                   - SELECTs are to be fast
                   - UPDATEs are to be fast
                   - INSERTs don't have to be fast
                   - DELETEs are done once in a year
}

uses
  Classes, AVLTree, exavltree, SysUtils, Configuration, Sockets, VSocket,
ClientConnection;

{$R *.res}

var
  tablespace: array[0..254] of TExAVLTree;
  i: Cardinal;
  Terminating: Boolean = false;

  client: TSocket;

begin
     Writeln('Vanad v0.1');
     Writeln('(c) by Henrietta 2011');
     Configuration.Initialize;


     Writeln('Replaying datafiles...');
     for i := 0 to 254 do
     begin
         tablespace[i] := TExAVLTree.Create();

         if FileExists(Configuration.GetS('FS', 'TableHierarchy')+'/'+IntToStr(i)) then
         begin
              writeln('Would replay ', i, ' but don''t want to');
         end;
     end;

     Configuration.Finalize;

     Writeln('Listening...');
     VSocket.Initialize;

     while true do
     begin
          client := VSocket.Accept(1000);
          if client <> INVALID_SOCKET then TClientConnection.Create(client);
          if Terminating then break;
     end;

     Writeln('Terminating');

     VSocket.Finalize;


     readln;
end.

