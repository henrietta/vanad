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
procedure ReadTable(tabid: Integer);
var
  d: Longword;
  b: Byte;
  f: File;
  Temp: Integer;
  k, v: ansiString;
begin
  AssignFile(f, Configuration.GetS('FS', 'TableHierarchy')+'/'+IntToStr(tabid));
  Reset(f, 1);
  while not Eof(f) do
  begin
      BlockRead(f, b, 1, Temp);                      d := b shr 24;
      BlockRead(f, b, 1, Temp);                      d := d + (b shr 16);
      BlockRead(f, b, 1, Temp);                      d := d + (b shr 8);
      BlockRead(f, b, 1, Temp);                      d := d + b;

      SetLength(k, d);
      BlockRead(f, k[1], d, Temp);

      BlockRead(f, b, 1, Temp);                      d := b shr 24;
      BlockRead(f, b, 1, Temp);                      d := d + (b shr 16);
      BlockRead(f, b, 1, Temp);                      d := d + (b shr 8);
      BlockRead(f, b, 1, Temp);                      d := d + b;

      SetLength(v, d);
      BlockRead(f, v[1], d, Temp);

      tablespace[tabid].Assign(k, v);
  end;

  Close(f);

end;

procedure WritebackTable(tabid: Integer);
var
  d: Longword;
  b: Byte;
  f: File;
  iter: TAVLTreeIterator;
  Temp: Integer;
begin
  AssignFile(f, Configuration.GetS('FS', 'TableHierarchy')+'/'+IntToStr(tabid));
  Rewrite(f, 1);
  Writeln(tabid);
  iter := TAVLTreeIterator.Create(tablespace[tabid]);

  while not iter.Done do
  begin
      d := Length(iter.Node.Key);
      b := d shr 24;                   BlockWrite(f, b, 1, Temp);
      b := (d shr 16) and $FF;         BlockWrite(f, b, 1, Temp);
      b := (d shr 8) and $FF;          BlockWrite(f, b, 1, Temp);
      b := d and $FF;                  BlockWrite(f, b, 1, Temp);

      BlockWrite(f, iter.Node.Key[1], d, Temp);      // Magic :)

      d := Length(iter.Node.Value);
      b := d shr 24;                   BlockWrite(f, b, 1, Temp);
      b := (d shr 16) and $FF;         BlockWrite(f, b, 1, Temp);
      b := (d shr 8) and $FF;          BlockWrite(f, b, 1, Temp);
      b := d and $FF;                  BlockWrite(f, b, 1, Temp);

      BlockWrite(f, iter.Node.Value[1], d, Temp);

      iter.Next();
  end;

  Close(f);
end;

var
  i, j: Cardinal;
  b: Byte;
  Terminating: Boolean = false;

  WorkerThreads: array of TWorkerThread;

  FFile: THandle;
begin
     Writeln('Vanad v0.1');
     Writeln('(c) by Henrietta 2011');
     Configuration.Initialize;


     SocketOpTimeout := Configuration.GetI('Operation', 'SocketOperationTimeout');

     Writeln('Replaying datafiles...');
     for i := 0 to 255 do
     begin
         tablespace[i] := TExAVLTree.Create();

         if FileExists(Configuration.GetS('FS', 'TableHierarchy')+'/'+IntToStr(i)) then
            ReadTable(i);
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
         WorkerThreads[i].Start();


     Writeln('Operating');
     Readln;

     Writeln('Terminating threads');
     for i := 0 to j-1 do
         WorkerThreads[i].Terminate();

     for i := 0 to j-1 do
     begin
          WorkerThreads[i].WaitFor();
          WorkerThreads[i].Destroy();
     end;

     Writeln('Shutting down socket');
     VSocket.Finalize;

     Writeln('Writing tables to disk');
     for i := 0 to 255 do WritebackTable(i);

     Writeln('Done');
     Configuration.Finalize();
     readln;
end.

