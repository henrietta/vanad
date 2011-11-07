program vanad;
{
        Basic idea:
                   - SELECTs are to be fast
                   - UPDATEs are to be fast
                   - INSERTs don't have to be fast
                   - DELETEs are done once in a year
}

uses
{$IFDEF UNIX}{$IFDEF UseCThreads}
cthreads,
{$ENDIF}{$ENDIF}
Classes,  AVLTree, exavltree, SysUtils, Configuration, Sockets, VSocket,
workerthread, CommonData;


{$R *.res}

var
  i, j: Cardinal;
  Terminating: Boolean = false;

  WorkerThreads: array of TWorkerThread;
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

     Writeln('Setting up socket...');
     VSocket.Initialize;

     Writeln('Spawning workers...');
     j := Configuration.GetI('Operation', 'WorkerThreads');
     Writeln(j);
     SetLength(WorkerThreads, j);
     for i := 0 to j-1 do
         WorkerThreads[i] := TWorkerThread.Create(i);

     Writeln('Launching...');
     for i := 0 to j-1 do
         WorkerThreads[i].Resume();

     Readln;

     Writeln('Kill''em...');
     for i := 0 to j-1 do
         WorkerThreads[i].Terminate();

     for i := 0 to j-1 do
     begin
          WorkerThreads[i].WaitFor();
          WorkerThreads[i].Destroy();
     end;

     Writeln('Terminating');

     VSocket.Finalize;


     readln;
end.

